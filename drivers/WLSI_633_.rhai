// LG slide-in induction range LSIS6338FE (modelId WLSI_633_): port of upstream rethink's
// WLSI_633_.ts (commit 0e57069). Read only.
//
// Status is a 0x40 EB frame of one 115-byte block or EC of two (previous, current); block offsets:
//  0 clock format (0 24-hour, 1 12-hour)   1 auto conversion   2 temperature unit (0 F, 1 C)
//  3 temperature adjustment (signed, in the appliance's unit)   5 preheating alarm light
//  6 / 9 oven / cooktop beeper volume (0 mute, 1 low, 2 high)   10 auto remote   11 bit 0 control lock
// 14 oven state   15 cook mode (bit 7: started remotely)   16-18 time left (s, min, h)
// 19-20 the length the cycle was given (min, h)   21-22 / 23-24 target / cavity temperature (big
// endian, bit 15 a Celsius flag)   27 bit 2 door open, bit 0 door locked   28-30 kitchen timer (s,
// min, h)   31 bit 0 remote start armed   32 broil level   60/63/66/69/72 the elements front left,
// front right, rear left, rear right and rear center (0 off, 3 locked out, anything else heating).
//
// Temperatures are published in Fahrenheit whatever the unit; the adjustment converts as a
// difference. A temperature of 0 is the appliance not reporting one, and a code the tables do not
// name is not guessed at: both are published absent.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn states() { #{ "0": "idle", "1": "preheating", "2": "cooking", "3": "done", "4": "cooling", "9": "cleaning" } }

fn modes() {
    #{ "0": "off", "1": "bake", "3": "convection_bake", "4": "convection_roast", "7": "broil", "8": "warm",
       "9": "proof", "10": "frozen_meal", "15": "self_clean", "16": "air_fry", "18": "air_sous_vide" }
}

fn broil_levels() { #{ "0": "off", "1": "low", "3": "high" } }
fn clock_formats() { #{ "0": "24_hour", "1": "12_hour" } }
fn units() { #{ "0": "fahrenheit", "1": "celsius" } }
fn volumes() { #{ "0": "mute", "1": "low", "2": "high" } }

fn elements() {
    [["cooktop_front_left", "Front left element", 60], ["cooktop_front_right", "Front right element", 63],
     ["cooktop_rear_left", "Rear left element", 66], ["cooktop_rear_right", "Rear right element", 69],
     ["cooktop_rear_center", "Rear center element", 72]]
}

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        oven_status: #{ type: "select", options: ["idle", "preheating", "cooking", "done", "cooling", "cleaning"] },
        oven_mode: #{ type: "select", options: ["off", "bake", "convection_bake", "convection_roast", "broil", "warm",
                                                 "proof", "frozen_meal", "self_clean", "air_fry", "air_sous_vide"] },
        broil_level: #{ type: "select", options: ["off", "low", "high"] },
        oven_target_temperature: #{ type: "number", class: "temperature", unit: "°F" },
        oven_temperature: #{ type: "number", class: "temperature", series: "gauge", unit: "°F" },
        remote_start: #{ type: "binary", category: "diagnostic" },
        remote_started: #{ type: "binary", category: "diagnostic", label: "Started remotely" },
        oven_door: #{ type: "binary", class: "door" },
        oven_door_lock: #{ type: "binary", label: "Oven door locked" },
        clock_format: #{ type: "select", category: "diagnostic", options: ["24_hour", "12_hour"] },
        auto_remote: #{ type: "binary", category: "diagnostic" },
        // a difference, not a temperature, so no temperature class
        temperature_adjustment: #{ type: "number", category: "diagnostic", unit: "°F" },
        temperature_unit: #{ type: "select", category: "diagnostic", options: ["fahrenheit", "celsius"] },
        auto_conversion: #{ type: "binary", category: "diagnostic" },
        preheating_alarm_light: #{ type: "binary", category: "diagnostic" },
        oven_beeper_volume: #{ type: "select", category: "diagnostic", options: ["mute", "low", "high"] },
        cooktop_beeper_volume: #{ type: "select", category: "diagnostic", options: ["mute", "low", "high"] },
        control_lock: #{ type: "binary" },
        cook_time: #{ type: "number", class: "duration", unit: "s" },
        remaining_time: #{ type: "number", class: "duration", unit: "s" },
        timer: #{ type: "number", class: "duration", unit: "s", label: "Kitchen timer" }
    };
    for e in elements() { props[e[0]] = #{ type: "binary", label: e[1] }; }
    json_stringify(#{ il: 0, kind: "oven", label: "Range", vendor: "LG", model: ctx.model_id(), props: props })
}

fn start(ctx) {
    ctx.send_raw(aabb_wrap(hex_decode("f0ed114101000000181a1017181c272e2f33505356595c00000000000000000000000000")));
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn publish_name(ctx, prop, name) {
    if name == () { il::publish_absent(ctx, prop); } else { il::publish_property(ctx, prop, name); }
}

fn flag(ctx, prop, on) { il::publish_property(ctx, prop, if on { "true" } else { "false" }); }

// A big-endian temperature in Fahrenheit, with the Celsius flag masked off; absent for 0.
fn publish_temperature(ctx, prop, hi, lo, celsius) {
    let v = ((hi & 0x7f) * 256 + lo).to_int();
    if v == 0 { il::publish_absent(ctx, prop); return; }
    il::publish_property(ctx, prop, if celsius { (v * 1.8 + 32.0).round().to_int() } else { v }.to_string());
}

fn on_data(ctx, data) {
    let b = c::inner(data, 0x40);
    let o = c::common_status_offset(b, 115);
    if o == () { return; }
    let r = b.extract(o, 115);
    il::publish_property(ctx, "available", "true");
    let celsius = r[2] == 1;
    publish_name(ctx, "oven_status", t::name(states(), r[14]));
    publish_name(ctx, "oven_mode", t::name(modes(), r[15] & 0x7f));
    publish_name(ctx, "broil_level", t::name(broil_levels(), r[32]));
    publish_temperature(ctx, "oven_target_temperature", r[21], r[22], celsius);
    publish_temperature(ctx, "oven_temperature", r[23], r[24], celsius);
    flag(ctx, "remote_start", (r[31] & 0x01) != 0);
    flag(ctx, "remote_started", (r[15] & 0x80) != 0);
    flag(ctx, "oven_door", (r[27] & 0x04) != 0);
    flag(ctx, "oven_door_lock", (r[27] & 0x01) != 0);
    il::publish_property(ctx, "timer", (r[30] * 3600 + r[29] * 60 + r[28]).to_string());
    il::publish_property(ctx, "remaining_time", (r[18] * 3600 + r[17] * 60 + r[16]).to_string());
    il::publish_property(ctx, "cook_time", (r[20] * 3600 + r[19] * 60).to_string());
    flag(ctx, "control_lock", (r[11] & 0x01) != 0);
    flag(ctx, "preheating_alarm_light", r[5] != 0);
    publish_name(ctx, "clock_format", t::name(clock_formats(), r[0]));
    flag(ctx, "auto_conversion", r[1] != 0);
    flag(ctx, "auto_remote", r[10] != 0);
    let adjust = if r[3] >= 128 { r[3] - 256 } else { r[3] };
    il::publish_property(ctx, "temperature_adjustment",
                         if celsius { (adjust * 1.8).round().to_int() } else { adjust }.to_string());
    publish_name(ctx, "temperature_unit", t::name(units(), r[2]));
    publish_name(ctx, "oven_beeper_volume", t::name(volumes(), r[6]));
    publish_name(ctx, "cooktop_beeper_volume", t::name(volumes(), r[9]));
    for e in elements() {
        let s = r[e[2]];
        flag(ctx, e[0], s != 0 && s != 3);
    }
}

fn on_set_property(ctx, prop, value) { il::validate(ctx, prop, value); }
