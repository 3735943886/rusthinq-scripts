// LG front-load washer FX25 (modelId FX___N, protocolVer 7): device -> IL driver. Port of
// SdrgonLee/rethink's FX___N.ts (https://github.com/SdrgonLee/rethink, commit 4c074bd), a fork
// of upstream rethink. Its offsets come from labelled power, door and full-cycle captures checked
// against the FX___N model JSON; power on/off was validated on a real FX25
// (docs/FX25_POWER_CONTROL_VALIDATION.md there), and every other write reproduces a frame the
// official ThinQ app sent, captured there.
//
// Frames (class 0x20, most in long AA FF framing):
//   enveloped 0x55 resync (EB, one 67-byte block) / 0x98 update (EC, previous + current);
//     aabb_common::enveloped_status takes the current block
//   E6 compact snapshot: 20 E6 .. 01 FF 01 .. 00 + one block (76 bytes)
//   E6 settings echo:    20 E6 .. 01 FF 08 1E .. 20 .. 21 .. 1F .. 35 .. 3E .. 43 .. 7F .. ..
//     + one block (90 bytes), answering a cycle-settings write
//   enveloped 0x18 door event: body[18] 1 open, 2 shut
//   3E energy report (7 bytes): [2..3] Wh this 15-minute interval, [4..5] Wh this cycle (the
//     appliance's own counter), [6] interval sequence, 1-based
// Block offsets: 1 soil, 2 water temperature, 3 rinses, 4 spin, 5 course, 11..12 delay-end
// reservation, 13..14 remaining, 15..16 initial time (minutes, big-endian), 19 error, 21 state
// (0 off), 28 washes since the last tub clean, 34 (0x20 TurboWash), 36 (0x80 crease care),
// 37 (0x20 child lock, 0x10 remote start), 38 (0x01 door lock).
// A powered-off block carries sentinels and stale settings, so it publishes the times as 0 and
// the reservation as off but leaves the cycle settings standing.
//
// Writes, all F0 E5 00 02 01 FF + a captured app payload:
//   power 01 02 <0|1>; course 01 0A <code>; remote start 01 03 01; laundry care 01 57 01
//   cycle settings 08 1E soil 20 rinse 21 spin 1F temp 35 turbo 3E 00 43 00 7F <reserve BE16>:
// one frame carries all six settings, so a change is merged into the last powered-on block's
// values (and any change still waiting for the appliance's echo). Settings and course are
// accepted only in the initial state, remote start only there with remote start enabled, laundry
// care only at the end of a cycle (state 42) with remote start still enabled, as in the fork.
// Codes the app was not seen writing (soaking, 4 and 5 rinses, 95 C, ...) are read only.
//
// Energy: `energy` is the appliance's cycle counter, `average_power` the last interval's mean.
// Both read 0 when a new cycle starts. The fork's calendar-month total kept on disk is not
// ported: a script has neither a wall clock nor storage that outlives a reconnect.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn blk_len() { 67 }

fn states() {
    #{ "0": "off", "1": "initial", "2": "paused", "3": "detecting", "5": "draining",
       "6": "detecting_detergent_amount", "7": "reserved", "8": "soaking", "9": "pre_wash",
       "11": "washing", "12": "rinsing", "13": "rinse_hold", "14": "spinning", "15": "drying",
       "16": "end", "21": "fresh_care", "23": "error_auto_off", "27": "freeze_prevention_initial",
       "28": "freeze_prevention_paused", "29": "freeze_prevention_running", "34": "audible_diagnosis",
       "35": "auto_detergent_open_pause", "36": "waiting_for_control", "37": "detecting_load",
       "38": "adding_detergent", "39": "adding_softener", "40": "detecting_soil", "41": "tub_cleaning",
       "42": "end_remote_maintain_on", "43": "steam", "47": "laundry_care", "48": "ezdispense_cleaning",
       "49": "waiting_after_completion" }
}

// States of a running cycle: entering one from anything else starts a new cycle's energy.
fn cycle_states() { [3, 5, 6, 8, 9, 11, 12, 13, 14, 15, 37, 38, 39, 40, 41, 43] }
fn idle_states() { [0, 1, 16, 23, 42] }

fn courses() {
    #{ "8": "baby_care", "27": "bedding", "46": "normal", "55": "rinse_spin", "74": "quick_wash",
       "76": "speed_boil", "78": "spin_only", "85": "tub_clean", "94": "hand_wool", "114": "ai_wash",
       "136": "microplastics_care" }
}
fn soils() { #{ "0": "none", "1": "light", "3": "normal", "5": "heavy", "6": "pre_wash", "7": "soaking" } }
fn rinses() { #{ "0": "none", "1": "1", "2": "2", "3": "3", "4": "4", "5": "5" } }
fn spins() { #{ "0": "off", "1": "delicate", "2": "low", "4": "medium", "6": "high", "8": "dry_matching" } }
fn temps() { #{ "0": "none", "2": "30", "3": "40", "5": "60", "6": "95", "8": "cold" } }

// Codes never seen written by the app: readable, not writable.
fn read_only_codes() {
    #{ soil: [0, 7], rinse: [0, 4, 5], spin: [], temp: [0, 6] }
}
fn tables() { #{ soil: soils(), rinse: rinses(), spin: spins(), temp: temps() } }

fn errors() {
    #{ "0": "none", "2": "IE", "3": "OE", "4": "UE", "5": "FE", "7": "PE", "8": "TE", "9": "LE",
       "13": "FF", "20": "DE1", "21": "DE2", "23": "VS", "43": "ED1", "44": "ED2", "45": "ED3",
       "46": "ED4", "47": "ED5", "48": "TS", "51": "E1", "52": "E4" }
}

fn initial_only() { #{ prop: "status", "in": ["initial"] } }

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer", vendor: "LG",
                      model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", role: "on", rw: true, label: "Power" },
        status: #{ type: "select", options: t::options(states()) },
        course: #{ type: "select", rw: true, requires: initial_only(), options: t::options(courses()) },
        soil: #{ type: "select", rw: true, requires: initial_only(), label: "Soil level", options: t::options(soils()) },
        rinse: #{ type: "select", rw: true, requires: initial_only(), label: "Rinses", options: t::options(rinses()) },
        spin: #{ type: "select", rw: true, requires: initial_only(), options: t::options(spins()) },
        temp: #{ type: "select", rw: true, requires: initial_only(), label: "Water temperature", options: t::options(temps()) },
        turbo_wash: #{ type: "binary", rw: true, requires: initial_only() },
        reserve_time: #{ type: "number", rw: true, requires: initial_only(), class: "duration", unit: "min",
                         min: 0, max: 1140, step: 30, label: "Finish in (0 off, 180 to 1140)" },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle length" },
        start: #{ type: "trigger", requires: "remote_start", label: "Remote start" },
        laundry_care: #{ type: "trigger", requires: "remote_start", label: "Start laundry care" },
        remote_start: #{ type: "binary" },
        door: #{ type: "binary", class: "door", label: "Door open" },
        door_lock: #{ type: "binary" },
        child_lock: #{ type: "binary", category: "diagnostic" },
        crease_care: #{ type: "binary" },
        tub_clean_count: #{ type: "number", category: "diagnostic", label: "Washes since tub clean" },
        error: #{ type: "text", class: "problem", category: "diagnostic" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Cycle energy" },
        average_power: #{ type: "number", class: "power", series: "gauge", unit: "W", label: "Average power, last 15 min" }
    } })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

// The appliance resyncs on its own when it connects; nothing is sent and no default published.
fn start(ctx) { }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn be16(r, o) { r[o] * 256 + r[o + 1] }

// A reservation the app can set: 0 (off) or 3 to 19 hours in 30-minute steps.
fn settable_reserve(m) { m == 0 || (m >= 180 && m <= 1140 && m % 30 == 0) }

fn block(ctx, r) {
    let s = r[21].to_int();
    let off = s == 0;
    let active = cycle_states().contains(s);
    if active && ctx.state_get("seen") == true && ctx.state_get("in_cycle") != true {
        il::publish_property(ctx, "energy", "0");
        il::publish_property(ctx, "average_power", "0");
        ctx.state_set("energy_last", ());
    }
    if active { ctx.state_set("in_cycle", true); }
    else if idle_states().contains(s) { ctx.state_set("in_cycle", false); }
    ctx.state_set("seen", true);
    ctx.state_set("state", s);

    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if off { "false" } else { "true" });
    c::pub_name(ctx, "status", t::name(states(), s));
    il::publish_property(ctx, "remaining_time", if off { "0" } else { be16(r, 13).to_string() });
    il::publish_property(ctx, "initial_time", if off { "0" } else { be16(r, 15).to_string() });
    let err = r[19].to_int();
    il::publish_property(ctx, "error", t::name(errors(), err) ?? ("Unknown error (" + err + ")"));
    il::publish_property(ctx, "tub_clean_count", r[28].to_string());
    il::publish_property(ctx, "crease_care", c::bit(r[36], 0x80));
    il::publish_property(ctx, "child_lock", c::bit(r[37], 0x20));
    il::publish_property(ctx, "remote_start", c::bit(r[37], 0x10));
    il::publish_property(ctx, "door_lock", c::bit(r[38], 0x01));

    if off {
        il::publish_property(ctx, "reserve_time", "0");
        return;
    }
    // A powered-on block is the appliance's own word on the settings: it replaces what a
    // write was waiting for.
    let reserve = be16(r, 11);
    ctx.state_set("actual", #{ soil: r[1].to_int(), temp: r[2].to_int(), rinse: r[3].to_int(),
                               spin: r[4].to_int(), turbo: if (r[34] & 0x20) != 0 { 1 } else { 0 },
                               reserve: reserve });
    ctx.state_set("pending", #{});
    c::pub_name(ctx, "course", t::name(courses(), r[5]));
    c::pub_name(ctx, "soil", t::name(soils(), r[1]));
    c::pub_name(ctx, "temp", t::name(temps(), r[2]));
    c::pub_name(ctx, "rinse", t::name(rinses(), r[3]));
    c::pub_name(ctx, "spin", t::name(spins(), r[4]));
    il::publish_property(ctx, "turbo_wash", c::bit(r[34], 0x20));
    // A running reservation counts down (179, 178 ...); only a value the app can set is shown,
    // so the countdown does not replace the chosen "finish in" time.
    if settable_reserve(reserve) { il::publish_property(ctx, "reserve_time", reserve.to_string()); }
}

fn door_event(ctx, b) {
    if b.len() <= 18 { return; }
    if b[18] == 1 { il::publish_property(ctx, "door", "true"); }
    else if b[18] == 2 { il::publish_property(ctx, "door", "false"); }
}

fn energy_report(ctx, b) {
    let interval = be16(b, 2);
    let cycle = be16(b, 4);
    let key = cycle.to_string() + ":" + b[6].to_string();
    if ctx.state_get("energy_last") == key { return; }
    ctx.state_set("energy_last", key);
    il::publish_property(ctx, "energy", cycle.to_string());
    il::publish_property(ctx, "average_power", (interval * 4).to_string());
}

fn settings_echo(b) {
    b.len() == 23 + blk_len() && b[4] == 0x01 && b[5] == 0xff && b[6] == 0x08 && b[7] == 0x1e &&
        b[9] == 0x20 && b[11] == 0x21 && b[13] == 0x1f && b[15] == 0x35 && b[17] == 0x3e &&
        b[19] == 0x43 && b[21] == 0x7f
}

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let r = c::enveloped_status(data, 0x20, blk_len());
    if r != () { block(ctx, r); return; }
    let b = c::inner(data, 0x20);
    if b == () || b.len() < 4 { return; }
    if b[1] == 0x3e {
        if b.len() == 7 { energy_report(ctx, b); }
        return;
    }
    if b[1] == 0xe6 {
        if b.len() == 9 + blk_len() && b[4] == 0x01 && b[5] == 0xff && b[6] == 0x01 && b[8] == 0x00 {
            block(ctx, b.extract(9, blk_len()));
        } else if settings_echo(b) {
            block(ctx, b.extract(23, blk_len()));
        }
        return;
    }
    if b[1] == 0x0a && b[3] == 0x18 { door_event(ctx, b); }
}

fn send(ctx, payload) {
    let msg = [0xf0, 0xe5, 0x00, 0x02, 0x01, 0xff];
    msg += payload;
    ctx.send_raw(aabb_wrap(msg));
}

fn send_settings(ctx, prop, key, code) {
    let actual = ctx.state_get("actual");
    if actual == () { return c::reject(ctx, prop, "no powered-on state reported yet"); }
    let pending = ctx.state_get("pending") ?? #{};
    pending[key] = code;
    ctx.state_set("pending", pending);
    let v = actual;
    for k in pending.keys() { v[k] = pending[k]; }
    send(ctx, [0x08, 0x1e, v.soil, 0x20, v.rinse, 0x21, v.spin, 0x1f, v.temp, 0x35, v.turbo,
               0x3e, 0x00, 0x43, 0x00, 0x7f, (v.reserve >> 8) & 0xff, v.reserve & 0xff]);
}

fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value == () { return; }
    let s = ctx.state_get("state");
    switch prop {
        "power" => send(ctx, [0x01, 0x02, if value == "true" { 1 } else { 0 }]),
        "course" => send(ctx, [0x01, 0x0a, t::code(courses(), value)]),
        "start" => {
            if s != 1 { return c::reject(ctx, prop, "only in the initial state"); }
            send(ctx, [0x01, 0x03, 0x01]);
        }
        "laundry_care" => {
            if s != 42 { return c::reject(ctx, prop, "only at the end of a cycle"); }
            send(ctx, [0x01, 0x57, 0x01]);
        }
        "turbo_wash" => send_settings(ctx, prop, "turbo", if value == "true" { 1 } else { 0 }),
        "reserve_time" => {
            let m = value.parse_float().to_int();
            if !settable_reserve(m) { return c::reject(ctx, prop, "0, or 180 to 1140 minutes"); }
            send_settings(ctx, prop, "reserve", m);
        }
        "soil" | "rinse" | "spin" | "temp" => {
            let code = t::code(tables()[prop], value);
            if read_only_codes()[prop].contains(code) { return c::reject(ctx, prop, value + " is not settable"); }
            send_settings(ctx, prop, prop, code);
        }
        _ => c::reject(ctx, prop, "unknown property")
    }
}
