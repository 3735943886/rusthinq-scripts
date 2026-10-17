// LG Styler ST_B_E4H01Y_APL (S5BBP): port of upstream rethink's ST_B_E4H01Y_APL.ts (commit
// 0e57069), whose layout was recovered by injecting single-byte-changed frames into LG's cloud and
// reading its decode back, and whose writes reproduce frames LG's own converter sent.
//
// READ. A 0x31 frame (long AA FF framing) of a 13-byte header, then one or two 40-byte records
// (previous, current) and one more byte; header bytes 11/12 (big-endian) count the record bytes,
// which must agree with the length, and only the last record counts. Record offsets:
//   2 state   3/4 remaining, 5/6 initial time (h, min)   7 course   8 error   9 previous state
//   14/15 reservation delay (h, min)   16 (0x01 child lock, 0x02 night dry, 0x08 remote start)
//   22 smart course   26 downloaded course   30 buzzer   31 (0x04 remote maintain)
//   32 end melody   34 (0x01 keep last course, 0x02 / 0x04 / 0x08 smart care fine dust /
//   humidity / night)   35/36 night care start, 37/38 end (h, min)   39 tank clean alerts
// A state, error or course code LG does not define is absent; an unknown buzzer or melody keeps
// the last value.
//
// WRITE. Settings are `f0 24 <type> <len> [<sub>] <value..>`: 01 power, 04 pause, 10 remote
// maintain, 13 a setting by sub id (01 end melody, 03 buzzer, 04/05/06 smart care, 07/08 the
// night-care start / end as hour, minute, 09 keep last course). A course starts with `f0 26` and
// the course id, `01 00 04 00 00 00 00 00` and the course's modelJSON defaults (below), and
// resumes with `f0 26`, the id and 44 zero bytes. Choosing a course is local: course_select only
// remembers it, start_course runs it, as LG's own app does.
//
// The appliance reports slowly, so a write is shown at once (upstream's echo) and corrected by the
// next state frame; not while it is off, not a course while an error stands, and not a night-care
// time while night care is off, all of which the appliance refuses. Power off is shown at once
// regardless: switched off, it sends no frame that could.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn states() {
    #{ "0": "power_off", "1": "standby", "2": "styling", "3": "pause", "4": "course_complete",
       "58": "course_complete", "59": "course_complete", "5": "check_appliance",
       "6": "smart_diagnosing", "7": "storing", "8": "reserved", "9": "power_save_running",
       "50": "steam_preparing", "51": "refreshing", "52": "refreshing", "53": "refreshing",
       "54": "drying", "55": "drying", "56": "drying", "57": "sterilizing" }
}

fn errors() {
    #{ "0": "normal", "23": "normal", "1": "te1", "2": "te2", "3": "te3", "4": "te4", "5": "te5",
       "6": "e1", "7": "e2", "8": "water_refill", "9": "e4", "10": "le2", "11": "ae", "18": "le",
       "25": "water_drain", "26": "door_open", "31": "check_door_closed", "32": "e6", "33": "ps",
       "34": "no_filter" }
}

fn courses() {
    #{ "0": "none", "1": "styling_standard", "3": "styling_quick", "5": "styling_intensive",
       "6": "wool_knit", "7": "suit_coat", "11": "sterilize_standard", "15": "auto_dry",
       "17": "timed_dry_30", "18": "timed_dry_60", "19": "timed_dry_90", "20": "timed_dry_120",
       "23": "room_dehumidify_120", "24": "room_dehumidify_240", "28": "padding_care",
       "30": "fine_dust", "31": "virus", "32": "jeans_care", "33": "fur_leather_care",
       "36": "suit_uniform_sterilize", "37": "silk", "38": "cashmere" }
}

fn smart_courses() {
    #{ "0": "none", "1": "panel_course", "61": "suit_uniform_sterilize", "62": "scarf_care",
       "66": "pants_care", "67": "quiet_care", "68": "coat_warm", "69": "static_removal",
       "71": "old_clothes_care", "73": "blanket_warm", "75": "dress_shirt_dry",
       "76": "snow_rain_dry", "78": "fur_leather_care", "93": "jeans_care",
       "94": "baby_clothes_sterilize", "95": "doll_sterilize", "96": "wool_knit_dry",
       "97": "rainy_season_laundry_dry", "98": "uniform_care", "99": "padding_care",
       "100": "thin_padding_dry", "101": "thick_padding_dry", "112": "yoga_pilates_care",
       "113": "yoga_pilates_dry", "114": "swimwear_dry", "115": "functional",
       "119": "bedding_sterilize" }
}

fn buzzers() {
    #{ "0": "mute", "1": "small", "2": "normal", "3": "large", "4": "very_large" }
}

fn melodies() {
    #{ "0": "default_sound", "1": "vivaldi_winter", "2": "bach_minuet", "3": "home_sweet_home",
       "4": "breeze", "5": "old_macdonald", "6": "verdi_brindisi", "7": "bubble",
       "8": "beethoven_symphony_no_5_5", "9": "arirang", "10": "pachelbel_canon",
       "11": "beethoven_choral" }
}

fn course_params() {
    #{
        "1": "02645a00000005005a05b45a01b4001ab40000000000000000000000000000000000000000",
        "3": "82645a00000003005a00000001b4000eb40000000000000000000000000000000000000000",
        "5": "02645a00000007005a05c85a01c80031b40000000000000000000000000000000000000000",
        "6": "82000000000004000000000001000014780000000000000000000000000000000000000000",
        "7": "82645a00000004005a04b45a01b40017780000000000000000000000000000000000000000",
        "11": "0200002d000006000008000003000023780000000000000000000000000000000000000000",
        "15": "0000000000000000000000000000005a780000000000000000000000000000000000000000",
        "17": "8000000000000000000000000000001e780000000000000000000000000000000000000000",
        "18": "8000000000000000000000000000003c780000000000000000000000000000000000000000",
        "19": "8000000000000000000000000000005a780000000000000000000000000000000000000000",
        "20": "8000000000000000000000000000003c780000000000000000000000000000000000000000",
        "23": "80000000000000000000000000000078000000000000000000000000000000000000000000",
        "24": "800000000000000000000000000000f0000000000000000000000000000000000000000000",
        "28": "82005a00000005005a05b45a01b4002eb40000000000000000000000000000000000000000",
        "30": "82000000000000000000000005c80000000000000000000003005a02c85a01c80028c80000",
        "31": "8200002d000007000008000003000043000000000000000000000000000000000000000000",
        "32": "8200002d000006000008000003000028000000000000000000000000000000000000000000",
        "33": "8000000000000000000000000000001e780000000000000000000000000000000000000000",
        "36": "8200002d00000600000800000300002b780000000000000000000000000000000000000000",
        "37": "8200002d00000600000800000300002b780000000000000000000000000000000000000000",
        "38": "8200002d00000600000800000300002b780000000000000000000000000000000000000000"
    }
}

// The courses this unit can be told to run: those with a block above, as course_select offers them.
fn runnable() {
    let out = [];
    for id in [1, 3, 5, 6, 7, 11, 15, 17, 18, 19, 20, 23, 24, 28, 30, 31, 32, 33, 36, 37, 38] {
        out.push(t::name(courses(), id));
    }
    out
}

fn sel(table) { #{ type: "select", options: t::options(table) } }

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "clothing_care", label: "Styler", vendor: "LG", model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", rw: true, role: "on" },
        status: sel(states()),
        previous_status: #{ type: "select", category: "diagnostic", options: t::options(states()) },
        course: sel(courses()),
        course_select: #{ type: "select", rw: true, label: "Course to start", options: runnable() },
        start_course: #{ type: "trigger" },
        pause_course: #{ type: "trigger" },
        resume_course: #{ type: "trigger" },
        smart_course: sel(smart_courses()),
        download_course: #{ type: "select", category: "diagnostic", options: t::options(smart_courses()) },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        initial_time: #{ type: "number", class: "duration", unit: "min" },
        reserve_time: #{ type: "number", class: "duration", unit: "min", label: "Reservation delay" },
        error: #{ type: "binary", class: "problem", category: "diagnostic" },
        error_message: #{ type: "select", category: "diagnostic", options: t::options(errors()) },
        child_lock: #{ type: "binary", category: "diagnostic" },
        night_dry: #{ type: "binary" },
        remote_start: #{ type: "binary", category: "diagnostic" },
        remote_maintain: #{ type: "binary", rw: true, category: "config", label: "Remote control allowed" },
        buzzer: #{ type: "select", rw: true, category: "config", label: "Alert sound", options: t::options(buzzers()) },
        end_melody: #{ type: "select", rw: true, category: "config", options: t::options(melodies()) },
        keep_last_course: #{ type: "binary", rw: true, category: "config" },
        smart_care_finedust: #{ type: "binary", rw: true, category: "config" },
        smart_care_humidity: #{ type: "binary", rw: true, category: "config" },
        smart_care_nightcare: #{ type: "binary", rw: true, category: "config" },
        night_care_start: #{ type: "text", rw: true, category: "config", label: "Night-care start (HH:MM, on the half hour)" },
        night_care_end: #{ type: "text", rw: true, category: "config", label: "Night-care end (HH:MM, on the half hour)" },
        tcl_count: #{ type: "number", category: "diagnostic", label: "Sterilize-tank clean alerts" }
    } })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn pad2(n) { if n < 10 { "0" + n } else { n.to_string() } }

fn named_or_absent(ctx, prop, name) {
    if name == () { il::publish_absent(ctx, prop); } else { il::publish_property(ctx, prop, name); }
}

fn on_data(ctx, data) {
    let b = aabb_unwrap(data);
    if b == () || b.len() < 54 || b[0] != 0x31 { return; }
    let payload = b.len() - 14;
    if payload % 40 != 0 || b[11] * 256 + b[12] != payload { return; }
    let r = b.extract(b.len() - 41, 40);
    let powered = r[2] != 0;
    let problem = r[8] != 0 && r[8] != 23;
    ctx.state_set("powered", powered);
    ctx.state_set("night_care", (r[34] & 0x08) != 0);
    ctx.state_set("problem", problem);
    il::publish_property(ctx, "available", "true");
    named_or_absent(ctx, "status", t::name(states(), r[2]));
    il::publish_property(ctx, "power", if powered { "true" } else { "false" });
    named_or_absent(ctx, "previous_status", t::name(states(), r[9]));
    named_or_absent(ctx, "error_message", t::name(errors(), r[8]));
    il::publish_property(ctx, "error", if problem { "true" } else { "false" });
    named_or_absent(ctx, "course", t::name(courses(), r[7]));
    named_or_absent(ctx, "smart_course", t::name(smart_courses(), r[22]));
    // a course the appliance is running takes over the selection (idle it reads none)
    if course_params().contains(r[7].to_string()) {
        ctx.state_set("selected", r[7]);
        il::publish_property(ctx, "course_select", t::name(courses(), r[7]));
    }
    il::publish_property(ctx, "remaining_time", (r[3] * 60 + r[4]).to_string());
    il::publish_property(ctx, "initial_time", (r[5] * 60 + r[6]).to_string());
    il::publish_property(ctx, "reserve_time", (r[14] * 60 + r[15]).to_string());
    il::publish_property(ctx, "child_lock", c::bit(r[16], 0x01));
    il::publish_property(ctx, "night_dry", c::bit(r[16], 0x02));
    il::publish_property(ctx, "remote_start", c::bit(r[16], 0x08));
    il::publish_property(ctx, "remote_maintain", c::bit(r[31], 0x04));
    c::pub_name(ctx, "buzzer", t::name(buzzers(), r[30]));
    c::pub_name(ctx, "end_melody", t::name(melodies(), r[32]));
    il::publish_property(ctx, "keep_last_course", c::bit(r[34], 0x01));
    il::publish_property(ctx, "smart_care_finedust", c::bit(r[34], 0x02));
    il::publish_property(ctx, "smart_care_humidity", c::bit(r[34], 0x04));
    il::publish_property(ctx, "smart_care_nightcare", c::bit(r[34], 0x08));
    il::publish_property(ctx, "night_care_start", pad2(r[35]) + ":" + pad2(r[36]));
    il::publish_property(ctx, "night_care_end", pad2(r[37]) + ":" + pad2(r[38]));
    named_or_absent(ctx, "download_course", t::name(smart_courses(), r[26]));
    il::publish_property(ctx, "tcl_count", r[39].to_string());
}

// ---- writes -----------------------------------------------------------------------

fn control(ctx, kind, value) { ctx.send_raw(aabb_wrap([0xf0, 0x24, kind, 0x01, value])); }
fn up_center(ctx, sub, values) {
    let m = [0xf0, 0x24, 0x13, values.len(), sub];
    m += values;
    ctx.send_raw(aabb_wrap(m));
}

// Shown at once unless the appliance is known to refuse it (see the header).
fn echo(ctx, prop, value) {
    if ctx.state_get("powered") != true { return; }
    if prop == "course" && ctx.state_get("problem") != false { return; }
    if ctx.state_get("night_care") == false && (prop == "night_care_start" || prop == "night_care_end") { return; }
    il::publish_property(ctx, prop, value);
}

fn selected(ctx) { ctx.state_get("selected") ?? 1 }

// HH:MM on the whole or half hour, as LG's own schema and the appliance take it; () otherwise.
fn half_hour(text) {
    let s = text;
    s.trim();
    if s.len() != 5 || s.sub_string(2, 1) != ":" { return (); }
    let h = (); let m = ();
    try { h = s.sub_string(0, 2).parse_int(); m = s.sub_string(3, 2).parse_int(); } catch {}
    if h == () || m == () || !"0123456789".contains(s.sub_string(0, 1)) || !"0123456789".contains(s.sub_string(1, 1)) { return (); }
    if h > 23 || (s.sub_string(3, 2) != "00" && s.sub_string(3, 2) != "30") { return (); }
    [h, m, s]
}

fn flag_setting(ctx, sub, prop, value) {
    let on = c::to_bool(value);
    up_center(ctx, sub, [if on { 1 } else { 0 }]);
    echo(ctx, prop, if on { "true" } else { "false" });
}

fn set_property(ctx, prop, value) {
    switch prop {
        "power" => {
            let on = c::to_bool(value);
            control(ctx, 0x01, if on { 1 } else { 0 });
            if !on { ctx.state_set("powered", false); }
            il::publish_property(ctx, "power", if on { "true" } else { "false" });
        }
        "remote_maintain" => {
            let on = c::to_bool(value);
            control(ctx, 0x10, if on { 1 } else { 0 });
            echo(ctx, prop, if on { "true" } else { "false" });
        }
        "keep_last_course" => flag_setting(ctx, 0x09, prop, value),
        "smart_care_finedust" => flag_setting(ctx, 0x04, prop, value),
        "smart_care_humidity" => flag_setting(ctx, 0x05, prop, value),
        "smart_care_nightcare" => flag_setting(ctx, 0x06, prop, value),
        "buzzer" => { up_center(ctx, 0x03, [t::code(buzzers(), value)]); echo(ctx, prop, value); }
        "end_melody" => { up_center(ctx, 0x01, [t::code(melodies(), value)]); echo(ctx, prop, value); }
        "course_select" => {
            ctx.state_set("selected", t::code(courses(), value));
            il::publish_property(ctx, "course_select", value); // nothing goes to the appliance
        }
        "start_course" => {
            let id = selected(ctx);
            let m = [0xf0, 0x26, id, 0x01, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00];
            for x in hex_decode(course_params()[id.to_string()]) { m.push(x.to_int()); } // a Blob yields u8
            ctx.send_raw(aabb_wrap(m));
            echo(ctx, "course", t::name(courses(), id));
        }
        "pause_course" => control(ctx, 0x04, 0),
        "resume_course" => {
            let m = blob(47, 0);
            m[0] = 0xf0; m[1] = 0x26; m[2] = selected(ctx);
            ctx.send_raw(aabb_wrap(m));
        }
        "night_care_start" | "night_care_end" => {
            let tm = half_hour(value);
            if tm == () { c::reject(ctx, prop, "not HH:MM on the whole or half hour"); return; }
            up_center(ctx, if prop == "night_care_start" { 0x07 } else { 0x08 }, [tm[0], tm[1]]);
            echo(ctx, prop, tm[2]);
        }
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
