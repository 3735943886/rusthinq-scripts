// LG front-load washer FX___S (FX25VSR.AKOR2, sw 2.11.246): device -> IL driver. Port of
// kshexe/rethink's FX___S.ts (https://github.com/kshexe/rethink, commit 8fa8bd4), a fork of
// upstream rethink whose offsets come from labelled live captures (2026-07-30..09-22): each
// control changed alone and named before the bytes were read, phase codes aligned against the
// LG cloud on one clock, energy checked against a smart plug. An AABB appliance, class 0x20,
// written with F0 E5 settings writes `f0 e5 00 02 01 ff <n> [<key> <value>]*n`.
//
// Frames (body = 20 <type> [<len16> when it equals the body length + 4] <payload>):
//   0a tunnel   payload[6] EC: <record 66> 00 <record 66> from payload[10], the second current;
//               EB: one record (sent on reconnect)
//   e6 reply    to a settings write: <00 02 01 ff> <n> [<key> <status>]*n 00 <record>
//   4d dial     03 02 <revision> <n> [<kind> <id>]*n: the courses on the appliance's dial, in
//               its order; kind 0 marks an extended course. The course select offers the dial
//               (plus the course selected now); before a declaration, every named course
//   3e energy   (7 bytes) the cycle Wh every ~15 min: ignored, the record carries the same
//               count every minute. The fork's hour/day/month totals fed from it, kept on disk by
//               calendar, are not ported
//   72 notify   00 <code>: 0 washing_is_complete, 0x64 error_during_washing (events)
// Record: [0] wash, [1] water temperature, [2] rinses, [3] spin (the work still to do: equal
//   to the selection only at standby, so these and steam/TurboShot are read at standby and on
//   the first record of a cycle, then held), [4] course (0xff: extended, id in [22]),
//   [10..11] reservation minutes with [38] 0x80 set, [12]/[13] remaining h/m, [14]/[15]
//   course h/m, [16..17] cycle Wh (agrees with 3e, refreshed every minute), [18] error (the
//   index of LG's error enum; published as an event when it appears), [20] phase (the index of
//   LG's state enum), [27] cycle count, [28] buzzer, [33] 0x20 TurboShot, [34] 0x10 steam,
//   [35] 0x80 crease care, [36] 0x10 remote control, 0x20 child lock, 0x40 drum light, 0x80
//   drum turning (also set while a reservation waits, so not published in phase 7), [37] door
//   lock, [39] 0x08 course auto-optimise, [46] 0x08 laundry care, 0x80 clock while off,
//   [49] 0x20 drum light auto-on.
// Writes, each a captured frame or its one-key shape: power 02, operation 03 (1 start, 2 pause,
//   3 resume; start and resume are followed by f0 24 10 01 01, as the app sends), course 0a,
//   wash 1e, temperature 1f, rinse 20, spin 21, buzzer 13, TurboShot 35, steam 3e, drum light
//   auto 1b, laundry care 57, auto-optimise 4c, clock while off 58. An extended course and the
//   reservation rewrite the cycle settings from the last record, as the app does, so they are
//   refused until a record has arrived. add_garment replays the app's "추가 세탁하기": course
//   Rinse + Spin and start in one write. start, add_garment and resume need remote control;
//   start and add_garment are refused while running or off, resume unless paused, pause unless
//   running (the fork's button availability).
// Divergences from the fork: nothing is published from a write (the e6 reply carries the record
// that confirms it); an unnamed course is `course_<id>` / `course_ext_<id>` rather than `#<id>`,
// a state or buzzer code with no name is absent rather than `unknown`, current_course is absent
// rather than `-` outside a cycle; door_lock reads true when locked (the fork inverts it for
// Home Assistant). Not ported: Korean names (a consumer's labels), the legacy course spellings
// writes still accept there, and the per-course adjustable-option hints and raw option dump.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn rec_len() { 66 }

fn states() {
    #{ "0": "power_off", "1": "initial", "2": "pause", "3": "detecting", "5": "add_drain",
       "6": "detergent_amount", "7": "reserved", "8": "soak", "9": "prewash", "11": "running",
       "12": "rinsing", "13": "rinsehold", "14": "spinning", "15": "drying", "16": "end",
       "21": "refreshing", "23": "error_auto_off", "27": "frozen_prevent_initial",
       "28": "frozen_prevent_pause", "29": "frozen_prevent_running", "34": "audible_diagnosis",
       "35": "auto_dt_open_pause", "36": "confirm_start_for_control", "37": "detecting",
       "38": "detergent_input", "39": "softener_input", "40": "detecting", "41": "running",
       "42": "end", "43": "steam", "47": "refreshing", "48": "ezdispense_cleaning", "49": "end_waiting" }
}
fn timed_phases() { [3, 37, 11, 40, 12, 14, 41, 2] }
fn active_phases() { [3, 37, 11, 40, 12, 14, 41, 47] }
fn cycle_phases() { [3, 37, 11, 40, 12, 14, 41, 47, 2] }
fn finished_phases() { [0, 1, 42, 47] }

fn courses() {
    #{ "5": "allergycare", "6": "ansimcold", "8": "babycare", "18": "colorcare", "27": "duvet",
       "46": "normal", "54": "refresh", "55": "rinse_spin", "56": "rinseonly", "65": "silent",
       "70": "soak", "74": "speedwash", "76": "speedboil", "78": "spin_only", "79": "sports_wears",
       "84": "towels", "85": "tub_clean", "89": "washonly", "94": "wool", "102": "cloth_care",
       "105": "kids_wear", "106": "rainy_day", "108": "shirt", "109": "single_garments",
       "113": "sweat_stain", "114": "ai_course", "134": "quick_tub_rinse", "135": "quick_steam_sanitize" }
}
fn ext_courses() { #{ "245": "normal_1", "246": "towels_1" } }
fn washes() { #{ "0": "none", "1": "light_soil", "3": "normal", "5": "intensive", "6": "pre_wash", "7": "soak" } }
fn temps() { #{ "0": "none", "2": "30", "3": "40", "5": "60", "8": "cold" } }
fn rinses() { #{ "0": "0", "1": "1", "2": "2", "3": "3", "4": "4", "5": "5" } }
fn spins() { #{ "0": "none", "1": "delicate", "2": "low", "4": "medium", "6": "high", "8": "dry_fit" } }
fn beeps() { #{ "0": "mute", "1": "low", "2": "medium", "3": "high", "4": "very_high" } }
fn notifications() { #{ "0": "washing_is_complete", "100": "error_during_washing" } }
fn errors() {
    #{ "2": "water_supply_error", "3": "water_drain_error", "4": "out_of_balance_error",
       "5": "overfill_error", "7": "water_level_sensor_error", "8": "temperature_sensor_error",
       "9": "locked_motor_error", "13": "ff_error", "20": "door_open_error",
       "21": "unable_to_lock_error", "23": "vs_error", "43": "ed1_error", "44": "ed2_error",
       "45": "ed3_error", "46": "ed4_error", "47": "ed5_error", "48": "ts_error", "51": "e1_error",
       "52": "e4_error" }
}
// The one-key settings: property -> key.
fn simple_keys() {
    #{ soil_wash: 0x1e, temp: 0x1f, rinse: 0x20, spin: 0x21, buzzer: 0x13, turbo_wash: 0x35,
       steam: 0x3e, drum_light_auto: 0x1b, laundry_care: 0x57, auto_optimise: 0x4c,
       clock_when_off: 0x58 }
}
fn select_tables() { #{ soil_wash: washes(), temp: temps(), rinse: rinses(), spin: spins(), buzzer: beeps() } }

fn label(course, ext) {
    if course == 0xff { t::name(ext_courses(), ext) ?? ("course_ext_" + ext) }
    else { t::name(courses(), course) ?? ("course_" + course) }
}

fn current_label(r) {
    let id = if r[4] == 0xff { r[22] } else { r[4] };
    if id == 0 { () } else { label(r[4], r[22]) }
}

fn course_options(ctx) {
    let o = ctx.state_get("course_options");
    if o != () { return o; }
    let all = t::options(courses());
    all += t::options(ext_courses());
    all
}

fn set_course_options(ctx, options) {
    if options == course_options(ctx) { return; }
    ctx.state_set("course_options", options);
    il::publish_il(ctx, descriptor(ctx));
}

fn descriptor(ctx) {
    let remote = "remote_control";
    let props = #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", role: "on", rw: true, label: "Power" },
        status: #{ type: "select", options: t::options(states()), label: "State" },
        running: #{ type: "binary", label: "Running" },
        drum_active: #{ type: "binary", label: "Drum turning" },
        course: #{ type: "select", rw: true, options: course_options(ctx), label: "Course" },
        current_course: #{ type: "select", options: course_options(ctx), label: "Course running" },
        soil_wash: #{ type: "select", rw: true, options: t::options(washes()), label: "Wash" },
        temp: #{ type: "select", rw: true, options: t::options(temps()), label: "Water temperature" },
        rinse: #{ type: "select", rw: true, options: t::options(rinses()), label: "Rinses" },
        spin: #{ type: "select", rw: true, options: t::options(spins()), label: "Spin" },
        steam: #{ type: "binary", rw: true, label: "Steam" },
        turbo_wash: #{ type: "binary", rw: true, label: "TurboShot" },
        steam_active: #{ type: "binary", label: "Cycle uses steam" },
        turbo_wash_active: #{ type: "binary", label: "Cycle uses TurboShot" },
        reserve_time: #{ type: "number", rw: true, class: "duration", unit: "min", min: 0, max: 1140,
                         step: 30, label: "Finish in (0 off, 180 to 1140)" },
        remaining_time: #{ type: "number", class: "duration", unit: "min", label: "Remaining time" },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle length" },
        rinse_remaining: #{ type: "number", label: "Rinses to go" },
        start: #{ type: "trigger", requires: remote, label: "Start" },
        pause: #{ type: "trigger", label: "Pause" },
        resume: #{ type: "trigger", requires: remote, label: "Resume" },
        add_garment: #{ type: "trigger", requires: remote, label: "Rinse + Spin now" },
        remote_control: #{ type: "binary", label: "Remote control" },
        door_lock: #{ type: "binary", label: "Door locked" },
        child_lock: #{ type: "binary", category: "diagnostic", label: "Child lock" },
        crease_care: #{ type: "binary", label: "Crease care" },
        drum_light: #{ type: "binary", label: "Drum light" },
        drum_light_auto: #{ type: "binary", rw: true, category: "config", label: "Drum light on door open" },
        laundry_care: #{ type: "binary", rw: true, category: "config", label: "Laundry care at the end" },
        auto_optimise: #{ type: "binary", rw: true, category: "config", label: "Course auto-optimisation" },
        clock_when_off: #{ type: "binary", rw: true, category: "config", label: "Clock while off" },
        buzzer: #{ type: "select", rw: true, options: t::options(beeps()), category: "config", label: "Buzzer volume" },
        cycles: #{ type: "number", category: "diagnostic", label: "Cycles" },
        notification: #{ type: "text", category: "diagnostic", label: "Notification" },
        error: #{ type: "text", class: "problem", category: "diagnostic", label: "Error" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Cycle energy" }
    };
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

// The appliance sends its record and dial on its own; nothing is sent on connect.
fn start(ctx) { }

// It drops off the network when switched off: stay available then, as in the fork, so the
// retained state reads off rather than unavailable.
fn on_drop(ctx) {
    if ctx.state_get("phase") == 0 { return; }
    il::publish_property(ctx, "available", "false");
}

fn be16(b, o) { b[o] * 256 + b[o + 1] }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let b = c::inner(data, 0x20);
    if b == () || b.len() < 4 { return; }
    let type = b[1];
    if type == 0x3e { return; }
    let p = if be16(b, 2) == b.len() + 4 { b.extract(4) } else { b.extract(2) };
    switch type {
        0x0a => {
            if p.len() < 10 { return; }
            let o = if p[6] == 0xec { rec_len() + 1 } else if p[6] == 0xeb { 0 } else { return; };
            if p.len() < 10 + o + rec_len() { return; }
            record(ctx, p.extract(10 + o, rec_len()));
        }
        0xe6 => {
            if p.len() < 5 { return; }
            let s = 5 + p[4] * 2 + 1;
            if p.len() < s + rec_len() { return; }
            record(ctx, p.extract(s, rec_len()));
        }
        0x4d => dial(ctx, p),
        0x72 => {
            if p.len() < 2 || p[0] != 0 { return; }
            let name = t::name(notifications(), p[1]);
            if name != () { il::publish_event(ctx, "notification", json_stringify(#{ event_type: name })); }
        }
    }
}

fn dial(ctx, p) {
    if p.len() < 4 || p[0] != 0x03 || p[1] != 0x02 { return; }
    let n = p[3];
    if p.len() != 4 + n * 2 { return; }
    let options = [];
    for i in 0..n {
        let l = label(if p[4 + i * 2] == 0 { 0xff } else { p[5 + i * 2] }, p[5 + i * 2]);
        if !options.contains(l) { options.push(l); }
    }
    let r = last_record(ctx);
    if r != () {
        let current = current_label(r);
        if current != () && !options.contains(current) { options.push(current); }
    }
    set_course_options(ctx, options);
}

fn last_record(ctx) {
    let r = ctx.state_get("record");
    if r == () { () } else { hex_decode(r) }
}

fn record(ctx, r) {
    let prev_phase = ctx.state_get("phase");
    let prev_error = ctx.state_get("error");
    ctx.state_set("record", hex_encode(r)); // a Blob is not a state value
    let phase = r[20].to_int();
    let flags = r[36];
    let error = r[18].to_int();
    ctx.state_set("phase", phase);
    ctx.state_set("error", error);
    il::publish_property(ctx, "available", "true");

    // A fault is announced when it appears, not on every record carrying it.
    if error != 0 && prev_error != () && error != prev_error {
        il::publish_event(ctx, "error", json_stringify(#{ event_type: t::name(errors(), error) ?? "unknown_error" }));
    }

    let course = current_label(r);
    if course != () {
        let options = course_options(ctx);
        if !options.contains(course) { options.push(course); set_course_options(ctx, options); }
        il::publish_property(ctx, "course", course);
    }
    if finished_phases().contains(phase) { il::publish_absent(ctx, "current_course"); }
    else if course != () { il::publish_property(ctx, "current_course", course); }

    il::publish_property(ctx, "remote_control", c::bit(flags, 0x10));
    il::publish_property(ctx, "child_lock", c::bit(flags, 0x20));
    il::publish_property(ctx, "door_lock", if r[37] != 0 { "true" } else { "false" });
    il::publish_property(ctx, "crease_care", c::bit(r[35], 0x80));
    il::publish_property(ctx, "drum_light", c::bit(flags, 0x40));
    il::publish_property(ctx, "drum_light_auto", c::bit(r[49], 0x20));

    // Steam and TurboShot as this cycle runs them: once seen in the cycle, held to its end.
    let in_cycle = cycle_phases().contains(phase);
    let seen_steam = in_cycle && (ctx.state_get("seen_steam") == true || (r[34] & 0x10) != 0);
    let seen_turbo = in_cycle && (ctx.state_get("seen_turbo") == true || (r[33] & 0x20) != 0);
    ctx.state_set("seen_steam", seen_steam);
    ctx.state_set("seen_turbo", seen_turbo);
    il::publish_property(ctx, "steam_active", seen_steam.to_string());
    il::publish_property(ctx, "turbo_wash_active", seen_turbo.to_string());

    il::publish_property(ctx, "laundry_care", c::bit(r[46], 0x08));
    il::publish_property(ctx, "clock_when_off", c::bit(r[46], 0x80));
    il::publish_property(ctx, "auto_optimise", c::bit(r[39], 0x08));
    let reserve = if (r[38] & 0x80) != 0 { ((be16(r, 10) + 15) / 30) * 30 } else { 0 };
    il::publish_property(ctx, "reserve_time", reserve.to_string());
    il::publish_property(ctx, "cycles", r[27].to_string());
    publish_enum(ctx, "buzzer", beeps(), r[28]);
    if phase != 0 { il::publish_property(ctx, "energy", be16(r, 16).to_string()); }
    let remaining = if timed_phases().contains(phase) { r[12] * 60 + r[13] } else { 0 };
    il::publish_property(ctx, "remaining_time", remaining.to_string());
    il::publish_property(ctx, "initial_time", (if phase == 0 { 0 } else { r[14] * 60 + r[15] }).to_string());
    il::publish_property(ctx, "rinse_remaining", r[2].to_string());

    let starting = prev_phase != () && !cycle_phases().contains(prev_phase) && in_cycle;
    if phase == 1 || starting {
        c::pub_name(ctx, "soil_wash", t::name(washes(), r[0]));
        c::pub_name(ctx, "temp", t::name(temps(), r[1]));
        c::pub_name(ctx, "rinse", t::name(rinses(), r[2]));
        c::pub_name(ctx, "spin", t::name(spins(), r[3]));
        il::publish_property(ctx, "steam", c::bit(r[34], 0x10));
        il::publish_property(ctx, "turbo_wash", c::bit(r[33], 0x20));
    }

    // Last, so an automation triggered by these sees the values above already current.
    il::publish_property(ctx, "power", if phase == 0 { "false" } else { "true" });
    publish_enum(ctx, "status", states(), phase);
    il::publish_property(ctx, "running", active_phases().contains(phase).to_string());
    il::publish_property(ctx, "drum_active", ((flags & 0x80) != 0 && phase != 7).to_string());
}

fn publish_enum(ctx, prop, table, raw) {
    let name = t::name(table, raw);
    if name == () { il::publish_absent(ctx, prop); } else { il::publish_property(ctx, prop, name); }
}

fn send(ctx, payload) {
    let msg = [0xf0, 0xe5, 0x00, 0x02, 0x01, 0xff];
    msg += payload;
    ctx.send_raw(aabb_wrap(msg));
}

fn trigger(ctx) { ctx.send_raw(aabb_wrap([0xf0, 0x24, 0x10, 0x01, 0x01])); }

// The cycle settings as the last record holds them, for the writes that resend them all.
fn settings(r) {
    [0x1e, r[0], 0x20, r[2], 0x21, r[3], 0x1f, r[1],
     0x35, if (r[33] & 0x20) != 0 { 1 } else { 0 }, 0x3e, if (r[34] & 0x10) != 0 { 1 } else { 0 }]
}

fn set_course(ctx, prop, value) {
    let code = t::code(courses(), value);
    if code == () && value.starts_with("course_") && !value.starts_with("course_ext_") {
        code = value.sub_string(7).parse_int();
    }
    if code != () { return send(ctx, [0x01, 0x0a, code]); }
    let ext = t::code(ext_courses(), value);
    if ext == () && value.starts_with("course_ext_") { ext = value.sub_string(11).parse_int(); }
    let r = last_record(ctx);
    if r == () { return c::reject(ctx, prop, "no record reported yet"); }
    let payload = [0x0a, 0x0a, 0xff, 0x0b, ext];
    payload += settings(r);
    payload += [0x43, 0x00, 0x7f, 0x00, 0x00];
    send(ctx, payload);
}

fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value == () { return; }
    let phase = ctx.state_get("phase");
    let running = phase != () && active_phases().contains(phase);
    if simple_keys().contains(prop) {
        let tables = select_tables();
        let code = if tables.contains(prop) { t::code(tables[prop], value) } else if value == "true" { 1 } else { 0 };
        return send(ctx, [0x01, simple_keys()[prop], code]);
    }
    switch prop {
        "power" => send(ctx, [0x01, 0x02, if value == "true" { 1 } else { 0 }]),
        "course" => set_course(ctx, prop, value),
        "start" | "add_garment" => {
            if running || phase == 0 { return c::reject(ctx, prop, "not while running or switched off"); }
            if prop == "start" { send(ctx, [0x01, 0x03, 0x01]); trigger(ctx); }
            else { send(ctx, [0x02, 0x0a, 0x37, 0x03, 0x01]); }
        }
        "pause" => {
            if phase != () && !running { return c::reject(ctx, prop, "only while running"); }
            send(ctx, [0x01, 0x03, 0x02]);
        }
        "resume" => {
            if phase != () && phase != 2 { return c::reject(ctx, prop, "only while paused"); }
            send(ctx, [0x01, 0x03, 0x03]);
            trigger(ctx);
        }
        "reserve_time" => {
            let m = value.parse_float().to_int();
            if m != 0 && m < 180 { return c::reject(ctx, prop, "0, or 180 to 1140 minutes"); }
            let r = last_record(ctx);
            if r == () { return c::reject(ctx, prop, "no record reported yet"); }
            let payload = [0x08];
            payload += settings(r);
            payload += [0x43, 0x00, 0x7f, (m >> 8) & 0xff, m & 0xff];
            send(ctx, payload);
        }
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}
