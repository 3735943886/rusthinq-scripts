// LG double-oven range WFV474PGV: port of upstream rethink's WFV474PGV.ts (commit 0e57069).
//
// Status is a 0x40 EB frame of one 62-byte block or EC of two (previous, current). The block holds
// two 18-byte cavity blocks, upper at 0 and lower at 18, each: 0 state   1 mode (bit 7: started
// remotely)   2/3/4 cook time left (s, min, h)   5-6 setpoint   7-8 cavity temperature (big endian
// °F; 0 is the oven not reporting one)   15 remote start status (1 ready, other values not). Then
// 30/31/32 the kitchen timer (s, min, h) and at 36, 41, 46, 51, 56 five copies of the cooktop state.
// A state or mode the tables do not name, and a temperature of 0, are published absent.
// `40 00 <43|44> <result>` acknowledges a command; result 0x40 is the oven refusing a remote start
// to a cavity that is not armed, published as a reject of that start.
//
// Writes, each a captured shape:
//   F0 43 20 0B <operation> 00 00 00 00 <temp16> <h> <min> 00 00   remote start (upper Bake 01; lower
//                                                                  Bake 15, Convection Bake 17,
//                                                                  Convection Roast 18)
//   F0 44 <00 upper | 01 lower>                                     cancel
//   F0 43 23 06 80 80 80 <s> <min> <h>                              kitchen timer (zero stops it)
//   F0 43 21 0E <13 bytes>                                          preferences: 0/1 clock hours and
//       minutes, 2 hour format (00: a 0-23 hour), 3 auto conversion, 4 adjustment unit (00 °F),
//       5/6 upper/lower temperature adjustment (signed), 7 preheating alarm light, 8 beeper volume,
//       9 display unit; every field not set is 0x80, index 11 0xFF.
// The oven reports none of the preferences, so they are write only and never published. The remote
// start parameters are staged here and sent by the start trigger, which requires the cavity's
// remote start to be ready; they go back to their defaults on every start of the driver. There is
// no host clock in a script, so the clock is written as a value ("HH:MM", 24-hour) rather than
// synced.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn states() { #{ "0": "idle", "1": "preheating", "2": "active", "3": "complete" } }

fn modes() { #{ "0": "none", "1": "bake", "21": "bake", "7": "broil", "23": "convection_bake", "24": "convection_roast" } }

fn lower_operations() { #{ "21": "bake", "23": "convection_bake", "24": "convection_roast" } }

fn volumes() { #{ "2": "high", "1": "low", "0": "mute" } }

fn units() { #{ "0": "fahrenheit", "1": "celsius" } }

fn cavities() { [["upper", 0], ["lower", 18]] }

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        cooktop_status: #{ type: "binary", label: "Cooktop" },
        timer: #{ type: "number", class: "duration", rw: true, min: 0, max: 359999, step: 1, unit: "s",
                  label: "Kitchen timer" },
        timer_stop: #{ type: "trigger", label: "Stop / acknowledge timer" },
        clock: #{ type: "text", rw: true, category: "config", label: "Clock (HH:MM, 24-hour)" },
        beeper_volume: #{ type: "select", rw: true, category: "config", options: ["high", "low", "mute"] },
        preheat_alarm_light: #{ type: "binary", rw: true, category: "config", label: "Preheating alarm light" },
        temperature_unit: #{ type: "select", rw: true, category: "config", options: ["fahrenheit", "celsius"],
                             label: "Displayed temperature unit" },
        auto_conversion: #{ type: "binary", rw: true, category: "config" },
        lower_remote_mode: #{ type: "select", rw: true, options: ["bake", "convection_bake", "convection_roast"] }
    };
    for cv in cavities() {
        let o = cv[0] + "_oven";
        props[o + "_status"] = #{ type: "select", options: ["idle", "preheating", "active", "complete"] };
        props[o + "_mode"] = #{ type: "select", options: ["none", "bake", "broil", "convection_bake", "convection_roast"] };
        props[o + "_temperature"] = #{ type: "number", class: "temperature", unit: "°F" };
        props[o + "_set_temperature"] = #{ type: "number", class: "temperature", unit: "°F" };
        props[o + "_cook_time"] = #{ type: "number", class: "duration", unit: "s" };
        props[o + "_remote_start"] = #{ type: "binary", label: "Remote start ready" };
        // a difference, not a temperature, so no temperature class
        props[cv[0] + "_temperature_adjustment"] = #{ type: "number", rw: true, category: "config", min: -35, max: 35,
                                                     step: 1, unit: "°F" };
        props[cv[0] + "_remote_temperature"] = #{ type: "number", class: "temperature", rw: true, min: 170, max: 550,
                                                 step: 5, unit: "°F" };
        props[cv[0] + "_remote_cook_time"] = #{ type: "number", class: "duration", rw: true, min: 0, max: 1440,
                                               step: 1, unit: "min" };
        props[cv[0] + "_start"] = #{ type: "trigger", requires: o + "_remote_start",
                                     label: if cv[0] == "upper" { "Start upper bake" } else { "Start lower" } };
        props[cv[0] + "_cancel"] = #{ type: "trigger" };
    }
    json_stringify(#{ il: 0, kind: "oven", label: "Oven", vendor: "LG", model: ctx.model_id(), props: props })
}

fn stage(ctx, prop, value) {
    ctx.state_set(prop, value);
    il::publish_property(ctx, prop, value.to_string());
}

fn start(ctx) {
    for cv in cavities() {
        stage(ctx, cv[0] + "_remote_temperature", 350);
        stage(ctx, cv[0] + "_remote_cook_time", 10);
        // readiness is trusted only from live status
        il::publish_property(ctx, cv[0] + "_oven_remote_start", "false");
    }
    stage(ctx, "lower_remote_mode", "bake");
    ctx.send_raw(aabb_wrap(hex_decode("f0ed114101000000181a0207080c14191a1e262b30353a00000000000000000000000000")));
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn publish_name(ctx, prop, name) {
    if name == () { il::publish_absent(ctx, prop); } else { il::publish_property(ctx, prop, name); }
}

fn publish_temperature(ctx, prop, v) {
    if v == 0 { il::publish_absent(ctx, prop); } else { il::publish_property(ctx, prop, v.to_string()); }
}

fn on_data(ctx, data) {
    let b = c::inner(data, 0x40);
    if b == () { return; }
    if b.len() == 4 && b[1] == 0x00 && (b[2] == 0x43 || b[2] == 0x44) {
        let pending = ctx.state_get("pending");
        ctx.state_remove("pending");
        if b[3] != 0 && pending != () {
            il::reject(ctx, pending, "refused", "the oven refused the command (result 0x" + b[3].to_hex() + ")");
        }
        return;
    }
    let o = c::common_status_offset(b, 62);
    if o == () { return; }
    let r = b.extract(o, 62);
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "timer", (r[32] * 3600 + r[31] * 60 + r[30]).to_string());
    for cv in cavities() {
        let p = cv[0] + "_oven";
        let k = cv[1];
        publish_name(ctx, p + "_status", t::name(states(), r[k]));
        publish_name(ctx, p + "_mode", t::name(modes(), r[k + 1] & 0x7f));
        publish_temperature(ctx, p + "_temperature", r[k + 7] * 256 + r[k + 8]);
        publish_temperature(ctx, p + "_set_temperature", r[k + 5] * 256 + r[k + 6]);
        il::publish_property(ctx, p + "_cook_time", (r[k + 4] * 3600 + r[k + 3] * 60 + r[k + 2]).to_string());
        il::publish_property(ctx, p + "_remote_start", if r[k + 15] == 1 { "true" } else { "false" });
    }
    let cooktop = [36, 41, 46, 51, 56].some(|i| r[i] != 0);
    il::publish_property(ctx, "cooktop_status", if cooktop { "true" } else { "false" });
}

fn send(ctx, prop, bytes) {
    ctx.state_set("pending", prop);
    ctx.send_raw(aabb_wrap(bytes));
}

fn send_timer(ctx, prop, secs) {
    send(ctx, prop, [0xf0, 0x43, 0x23, 0x06, 0x80, 0x80, 0x80, secs % 60, (secs / 60) % 60, secs / 3600]);
}

// One preference write; `fields` maps payload indexes to values, every other field "no change".
fn send_preference(ctx, prop, fields) {
    let payload = [];
    for i in 0..13 { payload.push(if i == 11 { 0xff } else { 0x80 }); }
    for k in fields.keys() { payload[parse_int(k)] = fields[k]; }
    send(ctx, prop, [0xf0, 0x43, 0x21, 0x0e] + payload);
}

// "HH:MM", 24-hour, as [hours, minutes], or ().
fn parse_clock(value) {
    if value.len() != 5 || value.sub_string(2, 1) != ":" { return (); }
    let digits = value.sub_string(0, 2) + value.sub_string(3, 2);
    for ch in digits.chars() { if ch < '0' || ch > '9' { return (); } }
    let h = parse_int(value.sub_string(0, 2));
    let m = parse_int(value.sub_string(3, 2));
    if h > 23 || m > 59 { return (); }
    [h, m]
}

fn remote_start(ctx, cavity) {
    let operation = if cavity == "upper" { 0x01 } else { t::code(lower_operations(), ctx.state_get("lower_remote_mode")) };
    let temp = ctx.state_get(cavity + "_remote_temperature");
    let time = ctx.state_get(cavity + "_remote_cook_time");
    send(ctx, cavity + "_start", [0xf0, 0x43, 0x20, 0x0b, operation, 0, 0, 0, 0, temp / 256, temp % 256,
                                  time / 60, time % 60, 0, 0]);
}

fn set_property(ctx, prop, value) {
    switch prop {
        "timer" => send_timer(ctx, prop, c::to_number(value).to_int()),
        "timer_stop" => send_timer(ctx, prop, 0),
        "clock" => {
            let hm = parse_clock(value);
            if hm == () { il::reject(ctx, prop, "invalid_value", "expected HH:MM, 24-hour"); return; }
            send_preference(ctx, prop, #{ "0": hm[0], "1": hm[1], "2": 0x00 });
        }
        "beeper_volume" => send_preference(ctx, prop, #{ "8": t::code(volumes(), value) }),
        "preheat_alarm_light" => send_preference(ctx, prop, #{ "7": if c::to_bool(value) { 1 } else { 0 } }),
        "temperature_unit" => send_preference(ctx, prop, #{ "9": t::code(units(), value) }),
        "auto_conversion" => send_preference(ctx, prop, #{ "3": if c::to_bool(value) { 1 } else { 0 } }),
        "upper_temperature_adjustment" => send_preference(ctx, prop, #{ "4": 0, "5": c::to_number(value).to_int() & 0xff }),
        "lower_temperature_adjustment" => send_preference(ctx, prop, #{ "4": 0, "6": c::to_number(value).to_int() & 0xff }),
        "upper_remote_temperature" | "lower_remote_temperature" | "upper_remote_cook_time" | "lower_remote_cook_time" =>
            stage(ctx, prop, c::to_number(value).to_int()),
        "lower_remote_mode" => stage(ctx, prop, value),
        "upper_start" => remote_start(ctx, "upper"),
        "lower_start" => remote_start(ctx, "lower"),
        "upper_cancel" => send(ctx, prop, [0xf0, 0x44, 0x00]),
        "lower_cancel" => send(ctx, prop, [0xf0, 0x44, 0x01]),
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
