// LG humidifying air purifier fields (deviceType 404), shared by HUM_056905_WW and HUM_0C0112_WW:
// each model's driver is `import "hum_common";`.
// Tags and enums are the modelJSON labels ("targetHumidity_state_tlv_595", ...). Behavior follows a
// private rethink fork driver running on installed units; frames in the tests are live captures
// from 2026-11-10.
//
// Different production runs share a model id and differ in what they support, so the first
// capability reply (it carries 0x3e8) narrows the descriptor: mode 0x2c1/0x259/0x149, fan 0x2c2,
// hygiene dry 0x160, standby sterilization and the night/sleep/auto/anti-glare switches 0x1e5,
// display and mood light 0x2d6, air sensors and sensor mode 0x2dd, sound 0x374, off timer 0x2d3,
// and the separate humidify switch only when 0x15f is non-zero. Until that reply, writes are
// refused; after it, retained values of dropped properties and options are cleared. The target
// range is 30-70 % in steps of 5, which every captured unit declares (0x2e5/0x2e6).
//
// Writes seen accepted on the wire: power, modes 5/12/24, fan, target humidity, night, sleep and
// auto operation. Never observed accepted, and written as the modelJSON labels say: the sensor
// mode (0x337), the tank light (0x21e), modes 108/109, standby sterilization "power", and off-timer
// minutes off the 15-minute grid.
//
// Sound (0x3a0) reads raw 0 as on and raw 1 as off. The modelJSON labels say the opposite (0 off,
// 1 on); the basis is a static reading of the shipped LG app module (GPH 3501.04), whose sound
// switch shows the raw value inverted, and the LG app's label disagreeing with the old reading on
// an installed unit. Round trips were driven from Home Assistant, not the app, and the beep itself
// was not physically checked.
//
// 0x355/0x356 are LG's filter "remainTime"/"maxTime"; their unit is unconfirmed, so neither
// declares one. Over-humidity prevention (0x117) and the auto-dry switch (0x20e) are left out: no
// unit reports their state and the LG app has no control for them.
import "tlv_fields_common";
import "tlv_common" as c;
import "table_common" as t;
import "il_common" as il;

fn identity() { #{"kind": "humidifier", "label": "Humidifying air purifier"} }
fn fields() {
    #{
        "power": #{ "tag": 503, "def": #{ "type": "binary", "rw": true, "role": "on" } },
        "mode": #{
            "tag": 505,
            "def": #{ "type": "select", "rw": true, "role": "mode" },
            "table": #{ "5": "air_clean", "12": "humidify_clean", "24": "humidify", "108": "ai_humidify", "109": "cozy_humidify" },
            "power_on": true,
            "attach": [503]
        },
        "target": #{
            "tag": 595,
            "def": #{
                "type": "number",
                "rw": true,
                "min": 30,
                "max": 70,
                "step": 5,
                "unit": "%",
                "role": "target_humidity"
            }
        },
        "humidity": #{
            "tag": 822,
            "def": #{ "type": "number", "unit": "%", "role": "current_humidity", "class": "humidity" }
        },
        "fan": #{
            "tag": 506,
            "def": #{ "type": "select", "rw": true, "role": "fan_speed" },
            "table": #{ "8": "auto", "2": "low", "4": "medium", "6": "high", "7": "turbo" }
        },
        "hygiene_dry": #{
            "tag": 489,
            "def": #{ "type": "select", "rw": true },
            "table": #{ "0": "off", "1": "gentle", "2": "quiet", "3": "quick", "4": "focus", "5": "default" }
        },
        "standby_sterilize": #{
            "tag": 356,
            "def": #{ "type": "select", "rw": true },
            "table": #{ "0": "rapid", "1": "normal", "2": "silent", "3": "power" }
        },
        "display": #{
            "tag": 543,
            "def": #{ "type": "select", "rw": true },
            "table": #{ "0": "off", "8": "level_1", "9": "level_2", "10": "level_3" }
        },
        "sensor_mon": #{
            "tag": 823,
            "def": #{ "type": "select", "rw": true, "category": "config" },
            "table": #{ "0": "while_on", "1": "always" }
        },
        "mood_color": #{
            "tag": 992,
            "def": #{ "type": "select", "rw": true },
            "table": #{
                "6": "yellow",
                "8": "pure_white",
                "9": "aquarium",
                "10": "candlelight",
                "11": "sunlight",
                "12": "rose",
                "13": "mint",
                "14": "lime",
                "15": "very_peri",
                "16": "warm_white",
                "17": "cool_white",
                "18": "sapphire",
                "19": "rainbow",
                "20": "salmon_pink",
                "21": "lavender",
                "22": "orange",
                "23": "amber",
                "34": "aurora",
                "39": "bonfire",
                "40": "ripples"
            }
        },
        "temperature": #{ "tag": 509, "def": #{ "type": "number", "unit": "°C", "class": "temperature" }, "scale": 2 },
        "status": #{
            "tag": 483,
            "def": #{ "type": "select" },
            "table": #{
                "0": "normal",
                "1": "no_tank",
                "2": "low_water",
                "3": "sterilizing",
                "4": "drying",
                "5": "boiling",
                "6": "boiling_low"
            }
        },
        "off_timer": #{
            "tag": 539,
            "def": #{ "type": "number", "rw": true, "min": 0, "max": 720, "step": 1, "unit": "min", "class": "duration" }
        },
        "start_time": #{
            "tag": 858,
            "def": #{ "type": "number", "rw": true, "min": 0, "max": 2400, "step": 1, "label": "Start time (HHMM, 0 = none)" }
        },
        "stop_time": #{
            "tag": 859,
            "def": #{ "type": "number", "rw": true, "min": 0, "max": 2400, "step": 1, "label": "Stop time (HHMM, 0 = none)" }
        },
        "night_mode": #{ "tag": 265, "def": #{ "type": "binary", "rw": true }, "exact_one": true },
        "sleep_mode": #{ "tag": 484, "def": #{ "type": "binary", "rw": true }, "exact_one": true },
        "auto_strength": #{ "tag": 486, "def": #{ "type": "binary", "rw": true }, "exact_one": true },
        "humidify": #{ "tag": 487, "def": #{ "type": "binary", "rw": true }, "exact_one": true },
        "anti_glare": #{ "tag": 353, "def": #{ "type": "binary", "rw": true }, "exact_one": true },
        "mood_light": #{ "tag": 440, "def": #{ "type": "binary", "rw": true }, "exact_one": true },
        "bell_sound": #{ "tag": 928, "def": #{ "type": "binary", "rw": true }, "exact_one": true, "on": 0 },
        "watertank_light": #{ "tag": 542, "def": #{ "type": "number", "rw": true, "min": 0, "max": 200, "step": 1 } },
        "pm1": #{ "tag": 819, "def": #{ "type": "number", "unit": "µg/m³" } },
        "pm25": #{ "tag": 820, "def": #{ "type": "number", "unit": "µg/m³" } },
        "pm10": #{ "tag": 821, "def": #{ "type": "number", "unit": "µg/m³" } },
        "air_quality": #{ "tag": 576, "def": #{ "type": "number" } },
        "watertank_remain": #{ "tag": 494, "def": #{ "type": "number", "unit": "%" } },
        "watertank_time": #{ "tag": 685, "def": #{ "type": "number", "unit": "min" } },
        "water_filter": #{ "tag": 493, "def": #{ "type": "number", "unit": "%" } },
        "filter_used_time": #{ "tag": 853, "def": #{ "type": "number", "category": "diagnostic" } },
        "filter_life_time": #{ "tag": 854, "def": #{ "type": "number", "category": "diagnostic" } },
        "autodry_remain": #{ "tag": 549, "def": #{ "type": "number", "unit": "min" } },
        "error": #{ "tag": 545, "def": #{ "type": "number", "category": "diagnostic" } }
    }
}
// 1 (no tank) is reported whenever the tank is out, as it is for plain air purifying; only 2 is
// a shortage.
fn extra_props() { #{ "water_lack": #{ "type": "binary", "class": "problem" } } }
fn apply_extra(ctx, tag, value) {
    if tag == 483 && t::name(fields().status.table, value) != () {
        il::publish_property(ctx, "water_lack", if value == 2 { "true" } else { "false" });
    }
}

// The model's appliance-side start/stop reservations (start_time, stop_time), its hooks on the
// capability reply and after every values query, and its reservation write.
fn native_reservations() { false }
fn on_capabilities(ctx) {}
fn after_values_query(ctx) {}
fn write_reservation(ctx, prop, value) { c::reject(ctx, prop, "unknown property"); }

fn has_feature(caps, tag, n) {
    let mask = caps[tag.to_string()];
    mask != () && ((mask >> (n - 1)) & 1) == 1
}

// What the capability reply supports: #{ codes: #{ prop: [wire codes] }, off: [props] }.
fn supported(caps) {
    let codes = #{};
    codes.mode = [];
    if has_feature(caps, 0x2c1, 6) { codes.mode.push(5); }
    if has_feature(caps, 0x2c1, 13) { codes.mode.push(12); }
    if has_feature(caps, 0x259, 6) { codes.mode.push(24); }
    if has_feature(caps, 0x149, 20) { codes.mode.push(108); }
    if has_feature(caps, 0x149, 21) { codes.mode.push(109); }
    codes.fan = [];
    for p in [[2, 3], [4, 5], [6, 7], [7, 8], [8, 9]] { if has_feature(caps, 0x2c2, p[1]) { codes.fan.push(p[0]); } }
    codes.hygiene_dry = [];
    for p in [[0, 1], [3, 2], [2, 3], [1, 4], [4, 5]] { if has_feature(caps, 0x160, p[1]) { codes.hygiene_dry.push(p[0]); } }
    codes.standby_sterilize = if !has_feature(caps, 0x1e5, 6) { [] } else if has_feature(caps, 0x1e5, 10) { [0, 1, 2] } else { [0, 1, 2, 3] };
    codes.mood_color = [];
    if has_feature(caps, 0x3e1, 7) { codes.mood_color.push(6); }
    for w in 8..=21 { if has_feature(caps, 0x3e1, w + 3) { codes.mood_color.push(w); } }
    for p in [[22, 1], [23, 2], [39, 9], [34, 10], [40, 11]] { if has_feature(caps, 0x3be, p[1]) { codes.mood_color.push(p[0]); } }

    let off = [];
    for p in [["auto_strength", 1], ["sleep_mode", 2], ["anti_glare", 5], ["night_mode", 7]] {
        if !has_feature(caps, 0x1e5, p[1]) { off.push(p[0]); }
    }
    let humidify = caps["351"];
    if humidify == () || humidify == 0 { off.push("humidify"); }
    if !has_feature(caps, 0x2dd, 8) { off.push("sensor_mon"); }
    if !has_feature(caps, 0x2d6, 13) { off.push("display"); }
    if !has_feature(caps, 0x2d6, 22) { off += ["mood_light", "mood_color", "watertank_light"]; }
    if !has_feature(caps, 0x374, 3) { off.push("bell_sound"); }
    if !has_feature(caps, 0x2d3, 15) { off.push("off_timer"); }
    if !has_feature(caps, 0x2d3, 13) { off += ["start_time", "stop_time"]; }
    for p in [["pm1", 2], ["pm25", 3], ["pm10", 4], ["air_quality", 5], ["humidity", 6], ["temperature", 7]] {
        if !has_feature(caps, 0x2dd, p[1]) { off.push(p[0]); }
    }
    #{ codes: codes, off: off }
}

fn field_def(ctx, prop, field, definition) {
    if ["start_time", "stop_time"].contains(prop) && !native_reservations() { return (); }
    let support = ctx.state_get("hum_support");
    if support == () { return definition; }
    if support.off.contains(prop) { return (); }
    let codes = support.codes[prop];
    if codes == () || field.table == () { return definition; }
    let table = #{};
    for code in codes { let k = code.to_string(); if field.table[k] != () { table[k] = field.table[k]; } }
    if table.is_empty() { return (); }
    definition.options = t::options(table);
    definition
}

// After narrowing, clear retained values the descriptor no longer allows: properties it dropped
// (also from an earlier session) and select readings outside the remaining options.
fn clear_narrowed(ctx) {
    let doc = ctx.state_get("__il_descriptor");
    let values = ctx.state_get("__il_values");
    for prop in fields().keys() {
        let definition = doc.props[prop];
        if definition == () { il::publish_absent(ctx, prop); continue; }
        let value = if values == () { () } else { values[prop] };
        if definition.options != () && value != () && !definition.options.contains(value) { il::publish_absent(ctx, prop); }
    }
}

// HUM capabilities use 0x3e8, rather than 0x2da.
fn hum_receive_frame(ctx, data) {
    let tlvs = tlv_frame_parse(data); if tlvs == () { return (); }
    let caps = tlvs.some(|e| e.t == 0x3e8);
    if caps && !c::is_set(ctx, "caps") {
        let reply = #{};
        for e in tlvs { reply[e.t.to_string()] = e.v; }
        ctx.state_set("hum_support", supported(reply));
        ctx.state_set("caps", true); ctx.cancel_timer("caps_retry");
        on_capabilities(ctx);
        il::publish_il(ctx, descriptor(ctx));
        clear_narrowed(ctx);
        c::query(ctx, 2); after_values_query(ctx);
        ctx.set_timer("values_retry", c::retry_ms());
    }
    let first = !caps && c::is_set(ctx, "caps") && !c::is_set(ctx, "values") && tlvs.some(|e| [0x1f7, 0x1f9, 0x1fa].contains(e.t));
    if first { ctx.state_set("values", true); ctx.cancel_timer("values_retry"); ctx.set_timer("refresh", c::refresh_ms()); }
    #{ tlvs: tlvs, caps: caps, first: first }
}
fn receive_frame(ctx, data) { hum_receive_frame(ctx, data) }

fn on_timer(ctx, name) {
    let query = name == "refresh" || (name == "values_retry" && !c::is_set(ctx, "values"));
    c::on_timer(ctx, name);
    if query { after_values_query(ctx); }
}

fn write_extra(ctx, prop, value) {
    if !c::is_set(ctx, "caps") { il::reject(ctx, prop, "not_now", "capabilities not received yet"); return true; }
    // Reservations travel in the model's own protocol, never as a TLV write.
    if prop == "start_time" || prop == "stop_time" { write_reservation(ctx, prop, value); return true; }
    false
}
