// The LG split air conditioners RAC_056905_WW and RAC_0B0001_WW (a European variant, deviceType
// 401, RTK_RTL8720cm, which upstream maps to the same handler): a whole driver over climate_common,
// as upstream rethink's RAC_056905_WW.ts and RAC_056905_WW_T1.ts (commit 2d8eaba). Each model's
// driver is `import "rac_common";`.
//
// Modes cool 0, dry 1, fan 2, heat 4, auto 6, and 46, which units with AC_RAC_AIRCLEAN_ONLY report
// after Air Purify is started from off and which runs as fan mode with air purify on; fan very low
// 2, low 3, medium 4, high 5, very high 6, auto 8; setpoint 18 to 30 in half degrees until the
// capabilities' per-mode limits (0x2e1 - 0x2ec) say otherwise. A mode write carries fan and
// setpoint but not power.
//
// The capability reply decides the optional features, as upstream does: 0x2cc bit 0x1 air
// purify (0x20f), 0x2 energy saving (0x20d, cool only), 0x4 auto dry (0x20e, 0x225 remaining);
// 0x2cd bits 0x1 / 0x2 jet in cool / heat (0x323 = 1 / 2), 0x4 vertical and 0x8 horizontal
// swing steps (0x321 / 0x322); 0x2d3 bit 0x1 sleep timer (0x21a, written only while on), 0x4
// or 0x10 on and off timers (0x21c / 0x21b), all in minutes; 0x2d6 bit 0x2 or 0x8000 the display
// light (0x21f), only on hardware upstream verified, by the EEPROM checksum 0x2da, which also
// says which value is on. The diagnostic sensors appear when the first state carries them:
// error 0x221, nominal capacity 0x32e (kBTU/h), EEV opening 0x330, pipe liquid / gas 0x2f9 /
// 0x2fa, outdoor heat exchanger 0x7a or 0x32c and outdoor air 0x332 (looked up in the tables
// below, index 255 - raw), fan 0x331 (x10 rpm). The power draw 0x2b3 is offered when accumMode
// 0x2d5 has a momentary bit (0x2 in/outdoor, 0x4 outdoor): with 0x4 it is watts as read, else
// upstream estimates watts as raw - 60, at least 5.
//
// The features of newer indoor units (upstream verified them on an H09S1DA, firmware 0x55703),
// each gated on the capability bit LG's model JSON names for it:
//   0x2dd 0x20 humidity 0x336   0x2ca 0x30000 AI Air 0x23e (cool, heat)   0x2cc 0x200 low heating
//   0x22d (heat)   0x34f 0x400 energy limit 0x20d (0 off or 80 / 60 / 40 %; cool; instead of energy
//   saving)   0x34f 0x100000 window detection, bit 0 of 0x3c9   0x351 bit 0x10000 Soft Air (cool,
//   fan)   0x374 0x4 beep 0x3a0 (0 on, 1 muted)   0x2f0 0x8 GoodSleep 0x12d and its operation and
//   temperature adjustments 0x12f / 0x133 (stored preferences, set any time)   0x350 0x10 makes auto
//   dry 0x20e a setting (255 on) with its fan 0x1f2 (low 2, medium 4, high 6; offered as 0x192's
//   bits say).
// Those bound to a mode take effect only while the unit runs in it: a read outside it is ignored,
// a write refused, except the energy limit, which is held and sent once the unit is cooling.
// Upstream's per-entity availability and descriptions are Home Assistant presentation, left out.
// The optional properties carry no `src` tag annotation: the host caps a script map at 256
// entries, nested ones included, and a unit with every feature would exceed it.
//
// Energy saving, the energy limit and jet are rewritten when the mode changes, air purify at each
// power up, each in its own frame, since the unit forgets them; they are read only while they
// apply.
//
// The filter is read with the private command 0x02 (`00 FF 04 00 00 00 65 FD 02 00 01 02 crc`),
// whose reply carries hours used, rated life and the date it was last reset, little-endian; units
// with mFilter (0x2f1 bit 0x1 or 0x200) are not asked. The descriptor is complete once that probe
// is answered or 5 s pass, then the values are queried again. Upstream's filter reset needs
// today's date, which a driver cannot read, so it is not offered.
import "climate_common";
import "tlv_common" as c;
import "table_common" as t;
import "il_common" as il;

// ---- model ------------------------------------------------------------------------

fn modes() { #{ "0": "cool", "1": "dry", "2": "fan_only", "4": "heat", "6": "auto", "46": "fan_only" } }
fn fans() { #{ "2": "very_low", "3": "low", "4": "medium", "5": "high", "6": "very_high", "8": "auto" } }
fn fan_options() { ["auto", "very_low", "low", "medium", "high", "very_high"] }
fn range() { [18, 30] }
fn range_tags() { [[0x2e1, 0x2e3, 0x2eb], [0x2e2, 0x2e4, 0x2ec]] }
fn mode_attach() { [0x1fa, 0x1fe] }
fn tracks_action() { true }
fn masks_reports() { true }

fn swings() { #{ "1": "1", "2": "2", "3": "3", "4": "4", "5": "5", "6": "6", "100": "on", "0": "off" } }
fn swing_options() { ["1", "2", "3", "4", "5", "6", "on", "off"] }
fn swings_h() { #{ "1": "1", "2": "2", "3": "3", "4": "4", "5": "5", "13": "1-3", "35": "3-5", "100": "on", "0": "off" } }
fn swing_h_options() { ["1", "2", "3", "4", "5", "1-3", "3-5", "on", "off"] }

// Hardware revisions upstream verified to report and accept 0x21f: EEPROM checksum -> the value
// that means on (the other one is off).
fn display_checksums() { #{ "20104": 1, "21789": 1, "19481": 1, "20312": 1, "20117": 1, "20153": 0 } }

fn energy_limits() { #{ "0": "off", "80": "80", "60": "60", "40": "40" } }
fn auto_dry_fans() { #{ "2": "low", "4": "medium", "6": "high" } }

// The newer features with a simple switch: tag, the value written for on and for off (a read of the
// off value is off, anything else on), and the modes they apply in (() for any state).
fn switches() {
    #{
        ai_air: #{ tag: 0x23e, on: 1, off: 0, modes: [0, 4] },
        low_heating: #{ tag: 0x22d, on: 1, off: 0, modes: [4] },
        beep: #{ tag: 0x3a0, on: 0, off: 1 },
        good_sleep: #{ tag: 0x12d, on: 1, off: 0 },
        good_sleep_operation: #{ tag: 0x12f, on: 1, off: 0 },
        good_sleep_temperature: #{ tag: 0x133, on: 1, off: 0 }
    }
}

// ---- features ---------------------------------------------------------------------

fn after_caps(ctx, tlvs) {
    let v = #{};
    for e in tlvs { v["t" + e.t] = e.v; }
    let cap = |tag, mask| ((v["t" + tag] ?? 0) & mask) != 0;
    let features = [];
    if cap.call(0x2cc, 0x1) { features.push("air_purify"); }
    if cap.call(0x2cc, 0x4) { features.push("auto_dry"); }
    if cap.call(0x2cc, 0x4) && cap.call(0x350, 0x10) { features.push("auto_dry_setting"); }
    if cap.call(0x2cd, 0x1) { features.push("jet_cool"); }
    if cap.call(0x2cd, 0x2) { features.push("jet_heat"); }
    if cap.call(0x2cd, 0x4) { features.push("swing_vertical"); }
    if cap.call(0x2cd, 0x8) { features.push("swing_horizontal"); }
    if cap.call(0x2d3, 0x1) { features.push("sleep_timer"); }
    if cap.call(0x2d3, 0x14) { features.push("turn_timers"); }
    let checksum = (v["t730"] ?? 0).to_string();   // 0x2da
    if cap.call(0x2d6, 0x8002) && display_checksums().contains(checksum) {
        features.push("display_light");
        ctx.state_set("display_on", display_checksums()[checksum]);
    }
    if cap.call(0x2f1, 0x201) { features.push("mfilter"); }
    if cap.call(0x2d5, 0x6) { features.push("power_draw"); }
    if cap.call(0x2d5, 0x4) { features.push("power_draw_outdoor"); }
    if cap.call(0x34f, 0x400) { features.push("energy_limit"); }
    else if cap.call(0x2cc, 0x2) { features.push("energy_save"); }
    if cap.call(0x2ca, 0x30000) { features.push("ai_air"); }
    if cap.call(0x2cc, 0x200) { features.push("low_heating"); }
    // these also need the tag itself, which first_values checks
    if cap.call(0x2dd, 0x20) { features.push("humidity?"); }
    if cap.call(0x34f, 0x100000) { features.push("window_detection?"); }
    if cap.call(0x374, 0x4) { features.push("beep?"); }
    if cap.call(0x2f0, 0x8) { features.push("good_sleep?"); }
    features.push("soft_air?");
    ctx.state_set("features", features);
    ctx.state_set("caps_tags", tlvs.map(|e| e.t));
    ctx.state_set("auto_dry_fan_mask", v["t402"] ?? 0);   // 0x192
    false
}

// A feature that needs a tag as well as its capability bit is listed as "name?" until the first
// state shows whether the unit carries the tag (in its capabilities or its values).
fn confirm_features(ctx) {
    let caps = ctx.state_get("caps_tags") ?? [];
    let carries = |tag| caps.contains(tag) || ctx.state_has("t" + tag);
    let needs = #{ "humidity?": [0x336], "window_detection?": [0x3c9], "beep?": [0x3a0],
                   "good_sleep?": [0x12d], "soft_air?": [0x351] };
    let out = [];
    for f in ctx.state_get("features") ?? [] {
        if !f.ends_with("?") { out.push(f); continue; }
        let name = f.sub_string(0, f.len() - 1);
        if carries.call(needs[f][0]) { out.push(name); }
        if name == "good_sleep" && carries.call(0x12d) {
            for extra in [["good_sleep_operation", 0x12f], ["good_sleep_temperature", 0x133]] {
                if carries.call(extra[1]) { out.push(extra[0]); }
            }
        }
    }
    ctx.state_set("features", out);
}

fn has(ctx, f) { let l = ctx.state_get("features"); l != () && l.contains(f) }
fn complete(ctx) { ctx.state_get("complete") == true }
fn jet(ctx) { has(ctx, "jet_cool") || has(ctx, "jet_heat") }

// The optional sensors: name, candidate tags, how a raw value reads (() for none).
fn sensors() {
    [["error", [0x221]], ["capacity", [0x32e]], ["eev", [0x330]], ["pipe_liquid_temp", [0x2f9]],
     ["pipe_gas_temp", [0x2fa]], ["outdoor_coil_temp", [0x7a, 0x32c]], ["outdoor_temp", [0x332]],
     ["fan_rpm", [0x331]]]
}

fn sensor_value(name, raw) {
    switch name {
        "capacity" => if raw != 0 { ((raw * 0.293 * 10.0).round() / 10.0).to_string() } else { () },
        "pipe_liquid_temp" | "pipe_gas_temp" | "outdoor_coil_temp" => lookup(pipe_temps(), raw),
        "outdoor_temp" => lookup(air_temps(), raw),
        "fan_rpm" => (raw * 10).to_string(),
        _ => raw.to_string()
    }
}

// 255 reads as -100 C, which is not plausible: no value.
fn lookup(table, raw) {
    let i = 255 - raw;
    if i < 0 || i >= table.len() { () } else { table[i].to_string() }
}

// Which tag each present sensor reads from, decided from the first state as upstream does.
fn pick_sensors(ctx) {
    let picked = #{};
    for s in sensors() {
        for tag in s[1] {
            if picked.contains(s[0]) || !ctx.state_has("t" + tag) { continue; }
            if sensor_value(s[0], c::get(ctx, tag)) != () { picked[s[0]] = tag; }
        }
    }
    ctx.state_set("sensors", picked);
}

fn sensor_of(ctx, tag) {
    let picked = ctx.state_get("sensors");
    if picked == () { return (); }
    for name in picked.keys() { if picked[name] == tag { return name; } }
    ()
}

// ---- descriptor -------------------------------------------------------------------

fn sensor_props() {
    #{
        error: #{ type: "number", category: "diagnostic" },
        capacity: #{ type: "number", class: "power", category: "diagnostic", unit: "kW", label: "Nominal capacity" },
        eev: #{ type: "number", series: "gauge", category: "diagnostic", label: "EEV opening" },
        pipe_liquid_temp: #{ type: "number", class: "temperature", series: "gauge", category: "diagnostic", unit: "°C" },
        pipe_gas_temp: #{ type: "number", class: "temperature", series: "gauge", category: "diagnostic", unit: "°C" },
        outdoor_coil_temp: #{ type: "number", class: "temperature", series: "gauge", category: "diagnostic", unit: "°C",
                              label: "Outdoor heat exchanger temperature" },
        outdoor_temp: #{ type: "number", class: "temperature", series: "gauge", category: "diagnostic", unit: "°C",
                         label: "Outdoor air temperature" },
        fan_rpm: #{ type: "number", series: "gauge", category: "diagnostic", unit: "rpm" }
    }
}

fn extra_props(ctx) {
    if !complete(ctx) { return #{}; }
    let props = #{};
    if has(ctx, "swing_vertical") {
        props.swing_vertical = #{ type: "select", rw: true, options: swing_options() };
    }
    if has(ctx, "swing_horizontal") {
        props.swing_horizontal = #{ type: "select", rw: true, options: swing_h_options() };
    }
    if has(ctx, "air_purify") {
        props.air_purify = #{ type: "binary", rw: true, category: "config" };
    }
    if jet(ctx) {
        props.jet = #{ type: "binary", rw: true, category: "config" };
    }
    if has(ctx, "sleep_timer") {
        props.sleep_timer = #{ type: "number", class: "duration", rw: true,
                               min: 0, max: 15, step: 0.25, unit: "h", requires: "power" };
    }
    if has(ctx, "turn_timers") {
        props.turn_on_timer = #{ type: "number", class: "duration", rw: true,
                                 min: 0, max: 24, step: 0.25, unit: "h" };
        props.turn_off_timer = #{ type: "number", class: "duration", rw: true,
                                  min: 0, max: 24, step: 0.25, unit: "h" };
    }
    if has(ctx, "energy_save") {
        props.energy_save = #{ type: "binary", rw: true, category: "config" };
    }
    if has(ctx, "auto_dry_setting") {
        props.auto_dry = #{ type: "binary", rw: true, category: "config" };
        props.auto_dry_remaining = #{ type: "number", category: "diagnostic", unit: "%" };
        let mask = ctx.state_get("auto_dry_fan_mask") ?? 0;
        if mask != 0 {
            let options = [];
            for k in [2, 4, 6] { if (mask & (1 << k)) != 0 { options.push(auto_dry_fans()[k.to_string()]); } }
            props.auto_dry_fan = #{ type: "select", rw: true, category: "config", options: options };
        }
    } else if has(ctx, "auto_dry") {
        props.auto_dry = #{ type: "binary", category: "diagnostic" };
        props.auto_dry_remaining = #{ type: "number", category: "diagnostic", unit: "%" };
    }
    if has(ctx, "display_light") {
        props.display_light = #{ type: "binary", rw: true, category: "config" };
    }
    if has(ctx, "power_draw") {
        props.power_draw = #{ type: "number", class: "power", series: "gauge", unit: "W" };
    }
    if has(ctx, "humidity") {
        props.humidity = #{ type: "number", class: "humidity", series: "gauge", role: "current_humidity", unit: "%" };
    }
    if has(ctx, "energy_limit") {
        props.energy_limit = #{ type: "select", rw: true, category: "config", unit: "%", label: "Active energy control", options: t::options(energy_limits()) };
    }
    if has(ctx, "soft_air") {
        props.soft_air = #{ type: "binary", rw: true, category: "config", label: "Soft Air",
                            requires: #{ prop: "mode", "in": ["cool", "fan_only"] } };
    }
    if has(ctx, "window_detection") {
        props.window_detection = #{ type: "binary", rw: true, category: "config" };
    }
    let sw = switches();
    for name in sw.keys() {
        if !has(ctx, name) { continue; }
        let def = #{ type: "binary", rw: true, category: "config" };
        if sw[name].modes != () { def.requires = #{ prop: "mode", "in": sw[name].modes.map(|m| modes()[m.to_string()]) }; }
        props[name] = def;
    }
    let picked = ctx.state_get("sensors") ?? #{};
    let defs = sensor_props();
    for name in picked.keys() { props[name] = defs[name]; }
    if (ctx.state_get("filter_life") ?? 0) > 0 {
        props.filter_used = #{ type: "number", class: "duration", series: "counter", category: "diagnostic", unit: "h" };
        props.filter_life = #{ type: "number", class: "duration", category: "diagnostic", unit: "h" };
        props.filter_reset_date = #{ type: "text", category: "diagnostic", label: "Filter usage last reset" };
    }
    props
}

// ---- reads ------------------------------------------------------------------------

fn powered(ctx) { c::get(ctx, 0x1f7) != 0 }

// The mode on the wire, 46 (purify only) counting as fan.
fn wire_mode(ctx) { let m = c::get(ctx, 0x1f9); if m == 46 { 2 } else { m } }

// Powered on and, unless `modes` is (), in one of them.
fn running_in(ctx, modes) { powered(ctx) && (modes == () || modes.contains(wire_mode(ctx))) }

// Publish `name` unless it is `()` (a code the table does not know stays unpublished).
fn pub_name(ctx, prop, name) { if name != () { il::publish_property(ctx, prop, name); } }

// Jet applies in cool (1) with jet_cool, in heat (2) with jet_heat.
fn jet_applies(ctx) {
    let mode = c::get(ctx, 0x1f9);
    powered(ctx) && ((has(ctx, "jet_cool") && mode == 0) || (has(ctx, "jet_heat") && mode == 4))
}

fn hours(minutes) { let q = (minutes / 15.0).ceiling() / 4.0; if q == q.floor() { q.to_int().to_string() } else { q.to_string() } }

fn apply_extra(ctx, tag, v) {
    if !complete(ctx) { return; }
    switch tag {
        0x321 => { if has(ctx, "swing_vertical") { pub_name(ctx, "swing_vertical", t::name(swings(), v)); } }
        0x322 => { if has(ctx, "swing_horizontal") { pub_name(ctx, "swing_horizontal", t::name(swings_h(), v)); } }
        0x20f => {
            if has(ctx, "air_purify") && powered(ctx) {
                ctx.state_set("air_purify_want", v != 0);
                il::publish_property(ctx, "air_purify", c::flag(v));
            }
        }
        0x20d => {
            if has(ctx, "energy_save") && powered(ctx) && c::get(ctx, 0x1f9) == 0 {
                ctx.state_set("energy_want", v != 0);
                il::publish_property(ctx, "energy_save", c::flag(v));
            }
            if has(ctx, "energy_limit") && running_in(ctx, [0]) {
                let name = t::name(energy_limits(), v);
                if name != () {
                    ctx.state_set("energy_limit_want", v);
                    il::publish_property(ctx, "energy_limit", name);
                }
            }
        }
        0x323 => {
            if jet(ctx) && jet_applies(ctx) {
                let mode = c::get(ctx, 0x1f9);
                let on = (mode == 0 && v == 1) || (mode == 4 && v == 2);
                ctx.state_set("jet_want", on);
                il::publish_property(ctx, "jet", if on { "true" } else { "false" });
            }
        }
        0x20e => { if has(ctx, "auto_dry") { il::publish_property(ctx, "auto_dry", c::flag(v)); } }
        0x225 => { if has(ctx, "auto_dry") { il::publish_property(ctx, "auto_dry_remaining", v.to_string()); } }
        0x1f2 => { if has(ctx, "auto_dry_setting") { pub_name(ctx, "auto_dry_fan", t::name(auto_dry_fans(), v)); } }
        0x2b3 => {
            if has(ctx, "power_draw") {
                let w = if has(ctx, "power_draw_outdoor") { v } else if v - 60 > 5 { v - 60 } else { 5 };
                il::publish_property(ctx, "power_draw", w.to_string());
            }
        }
        0x336 => { if has(ctx, "humidity") { il::publish_property(ctx, "humidity", v.to_string()); } }
        0x351 => {
            if has(ctx, "soft_air") && running_in(ctx, [0, 2]) {
                il::publish_property(ctx, "soft_air", c::flag(v & 0x10000));
            }
        }
        0x3c9 => { if has(ctx, "window_detection") { il::publish_property(ctx, "window_detection", c::flag(v & 1)); } }
        0x21a => { if has(ctx, "sleep_timer") { il::publish_property(ctx, "sleep_timer", hours(v)); } }
        0x21c => { if has(ctx, "turn_timers") { il::publish_property(ctx, "turn_on_timer", hours(v)); } }
        0x21b => { if has(ctx, "turn_timers") { il::publish_property(ctx, "turn_off_timer", hours(v)); } }
        0x21f => {
            if has(ctx, "display_light") {
                let on = ctx.state_get("display_on") ?? 1;
                il::publish_property(ctx, "display_light", if v == 1 - on { "false" } else { "true" });
            }
        }
        _ => {
            let sw = switches();
            for name in sw.keys() {
                let def = sw[name];
                if def.tag == tag && has(ctx, name) {
                    if def.modes == () || running_in(ctx, def.modes) {
                        il::publish_property(ctx, name, if v == def.off { "false" } else { "true" });
                    }
                    return;
                }
            }
            let name = sensor_of(ctx, tag);
            if name != () {
                let value = sensor_value(name, v);
                if value != () { il::publish_property(ctx, name, value); }
            }
        }
    }
}

// The unit forgets these: jet and energy saving are written again on a mode change (in that
// order, as upstream's hooks run), air purify at each power up, each in its own frame.
fn after_values(ctx, tlvs, before) {
    let mode = effective_mode(ctx);
    if before == () || before == mode { return; }
    let jet_want = ctx.state_get("jet_want");
    if jet_want != () { write_jet(ctx, jet_want); }
    let energy = ctx.state_get("energy_want");
    if energy != () && powered(ctx) && c::get(ctx, 0x1f9) == 0 {
        c::write(ctx, 0x20d, if energy { 1 } else { 0 }, []);
    }
    let limit = ctx.state_get("energy_limit_want");
    if limit != () && running_in(ctx, [0]) { c::write(ctx, 0x20d, limit, []); }
    let purify = ctx.state_get("air_purify_want");
    if before == "off" && purify != () && powered(ctx) {
        c::write(ctx, 0x20f, if purify { 1 } else { 0 }, []);
    }
}

// ---- writes -----------------------------------------------------------------------

fn write_jet(ctx, on) {
    ctx.state_set("jet_want", on);
    if !jet_applies(ctx) { return; }
    let mode = c::get(ctx, 0x1f9);
    c::write(ctx, 0x323, if !on { 0 } else if mode == 0 { 1 } else { 2 }, []);
}

fn set_extra(ctx, prop, value) {
    switch prop {
        "swing_vertical" => { c::write(ctx, 0x321, t::code(swings(), value), []); }
        "swing_horizontal" => { c::write(ctx, 0x322, t::code(swings_h(), value), []); }
        "jet" => {
            let on = c::to_bool(value);
            il::publish_property(ctx, "jet", if on { "true" } else { "false" });
            write_jet(ctx, on);
        }
        "energy_save" => {
            let on = c::to_bool(value);
            ctx.state_set("energy_want", on);
            il::publish_property(ctx, "energy_save", if on { "true" } else { "false" });
            if powered(ctx) && c::get(ctx, 0x1f9) == 0 { c::write(ctx, 0x20d, if on { 1 } else { 0 }, []); }
        }
        "air_purify" => {
            let on = c::to_bool(value);
            ctx.state_set("air_purify_want", on);
            il::publish_property(ctx, "air_purify", if on { "true" } else { "false" });
            if powered(ctx) { c::write(ctx, 0x20f, if on { 1 } else { 0 }, []); }
        }
        "sleep_timer" => {
            if !powered(ctx) { c::reject(ctx, prop, "requires power"); return true; }
            c::write(ctx, 0x21a, (c::to_number(value) * 60).round().to_int(), []);
        }
        "turn_on_timer" => { c::write(ctx, 0x21c, (c::to_number(value) * 60).round().to_int(), []); }
        "turn_off_timer" => { c::write(ctx, 0x21b, (c::to_number(value) * 60).round().to_int(), []); }
        "display_light" => {
            let on = ctx.state_get("display_on") ?? 1;
            c::write(ctx, 0x21f, if c::to_bool(value) { on } else { 1 - on }, []);
        }
        "auto_dry" => { c::write(ctx, 0x20e, if c::to_bool(value) { 255 } else { 0 }, []); }
        "auto_dry_fan" => { c::write(ctx, 0x1f2, t::code(auto_dry_fans(), value), []); }
        "energy_limit" => {
            let code = t::code(energy_limits(), value);
            ctx.state_set("energy_limit_want", code);
            il::publish_property(ctx, "energy_limit", value);
            if running_in(ctx, [0]) { c::write(ctx, 0x20d, code, []); }
        }
        "soft_air" => {
            if !running_in(ctx, [0, 2]) { c::reject(ctx, prop, "requires cooling or fan"); return true; }
            let bits = (c::get(ctx, 0x351) & (-1 ^ 0x10000)) | if c::to_bool(value) { 0x10000 } else { 0 };
            c::write(ctx, 0x351, bits, []);
        }
        "window_detection" => {
            c::write(ctx, 0x3c9, (c::get(ctx, 0x3c9) & (-1 ^ 1)) | if c::to_bool(value) { 1 } else { 0 }, []);
        }
        _ => {
            let def = switches()[prop];
            if def == () { return false; }
            if def.modes != () && !running_in(ctx, def.modes) {
                c::reject(ctx, prop, "requires the unit running in " + def.modes.map(|m| modes()[m.to_string()]));
                return true;
            }
            c::write(ctx, def.tag, if c::to_bool(value) { def.on } else { def.off }, []);
        }
    }
    true
}

// ---- filter (private command 0x02) and completing the descriptor --------------------

fn filter_query(ctx) {
    let frame = blob();
    for b in [0x00, 0xff, 0x04, 0x00, 0x00, 0x00, 0x65, 0xfd, 0x02, 0x00, 0x01, 0x02] { frame.push(b); }
    let crc = crc16(frame.extract(2));
    frame.push(crc >> 8);
    frame.push(crc & 0xff);
    ctx.send_raw(frame);
}

fn le32(b, o) { b[o] + b[o + 1] * 256 + b[o + 2] * 65536 + b[o + 3] * 16777216 }

fn pad(n, width) { let s = n.to_string(); while s.len() < width { s = "0" + s; } s }

fn publish_filter(ctx) {
    let date = ctx.state_get("filter_date");
    il::publish_property(ctx, "filter_used", ctx.state_get("filter_used").to_string());
    il::publish_property(ctx, "filter_life", ctx.state_get("filter_life").to_string());
    il::publish_property(ctx, "filter_reset_date",
        pad(date / 10000, 4) + "-" + pad((date / 100) % 100, 2) + "-" + pad(date % 100, 2));
}

// The private reply `<cmd> FF 04 00 00 00 87 FD 03 <seq> <len> <data> crc`; command replies
// (`02|03 .. 87 FD 10 00 05 FE ..`) carry nothing this driver uses.
fn own_frame(ctx, data) {
    let n = data.len();
    if n < 13 || data[2] != 0x04 || data[3] != 0 || data[4] != 0 || data[5] != 0
        || data[6] != 0x87 || data[7] != 0xfd { return false; }
    if data[1] == 0xff && data[8] == 0x03 && data[10] == n - 13 {
        let body = data.extract(11, n - 13);
        if data[0] == 0x02 && body.len() >= 13 {
            ctx.state_set("filter_used", le32(body, 1));
            ctx.state_set("filter_life", le32(body, 5));
            ctx.state_set("filter_date", le32(body, 9));
            if ctx.state_get("filter_probing") == true {
                ctx.cancel_timer("filter_probe");
                finish(ctx);
            } else if complete(ctx) && ctx.state_get("filter_life") > 0 {
                publish_filter(ctx);
            }
        }
        return true;
    }
    data[8] == 0x10
}

fn first_values(ctx) {
    confirm_features(ctx);
    pick_sensors(ctx);
    if has(ctx, "mfilter") {
        finish(ctx);
    } else {
        ctx.state_set("filter_probing", true);
        filter_query(ctx);
        ctx.set_timer("filter_probe", 5000);
    }
}

// The descriptor is complete: publish it and ask for the values it now covers.
fn finish(ctx) {
    ctx.state_set("filter_probing", false);
    ctx.state_set("complete", true);
    il::publish_il(ctx, descriptor(ctx));
    if (ctx.state_get("filter_life") ?? 0) > 0 {
        publish_filter(ctx);
        ctx.set_timer("filter_refresh", 86400000);
    }
    c::query(ctx, 2);
}

fn timer_extra(ctx, name) {
    switch name {
        // no filter reply: assume the unit has none
        "filter_probe" => { if ctx.state_get("filter_probing") == true { finish(ctx); } }
        "filter_refresh" => { filter_query(ctx); ctx.set_timer("filter_refresh", 86400000); }
        _ => { return false; }
    }
    true
}

// ---- the ThinQ1 variant ------------------------------------------------------------
// Some units (QCA4002 module, 2.6.7_RTOS_3K firmware) report this model id over ThinQ1, as upstream
// rethink's RAC_056905_WW_T1.ts handles (anszom/rethink#70). Status is a JSON document in each push
// after Mon/Start, with string fields: Operation (0 off), OpMode, TempCur, TempCfg (whole degrees),
// WindStrength, WDirVStep, WDirHStep, Jet, AirClean, coded as the TLV variant's tags. The first
// pushes have every field zeroed (TempCfg "0", impossible otherwise) and are dropped. Writes are
// Control/Set with one field; OpMode alone is ignored while the unit is off, so a mode write from
// off sends Operation 1 first.

fn descriptor(ctx) { if ctx.is_thinq2() { climate_descriptor(ctx) } else { t1_descriptor(ctx) } }
fn start(ctx) { if ctx.is_thinq2() { climate_start(ctx); } else { ctx.send_json(json_stringify(#{ Cmd: "Mon", CmdOpt: "Start" })); } }
fn on_timer(ctx, name) { if ctx.is_thinq2() { climate_on_timer(ctx, name); } }
fn on_data(ctx, data) { if ctx.is_thinq2() { climate_on_data(ctx, data); } else { t1_status(ctx, data); } }
fn set_property(ctx, prop, value) {
    if ctx.is_thinq2() { climate_set_property(ctx, prop, value); } else { t1_set(ctx, prop, value); }
}

fn t1_descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "climate", class: "air_conditioner", label: label(), vendor: "LG",
                      model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", rw: true, role: "on" },
        mode: #{ type: "select", rw: true, role: "mode", options: t::options(modes()) },
        fan: #{ type: "select", rw: true, role: "fan_speed", options: fan_options() },
        target: #{ type: "number", rw: true, role: "target_temperature", min: 18, max: 30, step: 1, unit: "°C" },
        temperature: #{ type: "number", role: "current_temperature", unit: "°C" },
        swing_vertical: #{ type: "select", rw: true, options: swing_options() },
        swing_horizontal: #{ type: "select", rw: true, options: swing_h_options() },
        jet: #{ type: "binary", rw: true, category: "config" },
        air_purify: #{ type: "binary", rw: true, category: "config" }
    } })
}

// A wire number as text: "21" stays 21, "19.5" stays 19.5.
fn t1_number(text) {
    let n = (); try { n = text.parse_float(); } catch {}
    if n == () { () } else if n == n.floor() { n.to_int().to_string() } else { n.to_string() }
}

fn t1_pub(ctx, prop, table, raw) {
    if type_of(raw) != "string" { return; }
    let code = (); try { code = raw.parse_int(); } catch {}
    if code != () { pub_name(ctx, prop, t::name(table, code)); }
}

fn t1_status(ctx, data) {
    let s = (); try { s = json_parse(bytes_utf8(data)); } catch {}
    if type_of(s) != "map" || type_of(s.Operation) != "string" || s.TempCfg == "0" { return; }
    ctx.state_set("t1_operation", s.Operation);
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if s.Operation != "0" { "true" } else { "false" });
    t1_pub(ctx, "mode", modes(), s.OpMode);
    if type_of(s.TempCur) == "string" { let v = t1_number(s.TempCur); if v != () { il::publish_property(ctx, "temperature", v); } }
    if type_of(s.TempCfg) == "string" { let v = t1_number(s.TempCfg); if v != () { il::publish_property(ctx, "target", v); } }
    t1_pub(ctx, "fan", fans(), s.WindStrength);
    t1_pub(ctx, "swing_vertical", swings(), s.WDirVStep);
    t1_pub(ctx, "swing_horizontal", swings_h(), s.WDirHStep);
    if type_of(s.Jet) == "string" { il::publish_property(ctx, "jet", if s.Jet == "1" { "true" } else { "false" }); }
    if type_of(s.AirClean) == "string" { il::publish_property(ctx, "air_purify", if s.AirClean == "1" { "true" } else { "false" }); }
}

fn t1_control(ctx, key, value) {
    let v = #{};
    v[key] = value.to_string();
    ctx.send_json(json_stringify(#{ Cmd: "Control", CmdOpt: "Set", Value: v, Format: "B64", Data: "" }));
}

fn t1_set(ctx, prop, value) {
    switch prop {
        "power" => { t1_control(ctx, "Operation", if c::to_bool(value) { 1 } else { 0 }); }
        "mode" => {
            if ctx.state_get("t1_operation") == "0" { t1_control(ctx, "Operation", 1); }
            t1_control(ctx, "OpMode", t::code(modes(), value));
        }
        "target" => { t1_control(ctx, "TempCfg", c::to_number(value).round().to_int()); }
        "fan" => { t1_control(ctx, "WindStrength", t::code(fans(), value)); }
        "swing_vertical" => { t1_control(ctx, "WDirVStep", t::code(swings(), value)); }
        "swing_horizontal" => { t1_control(ctx, "WDirHStep", t::code(swings_h(), value)); }
        "jet" => { t1_control(ctx, "Jet", if c::to_bool(value) { 1 } else { 0 }); }
        "air_purify" => { t1_control(ctx, "AirClean", if c::to_bool(value) { 1 } else { 0 }); }
        _ => { c::reject(ctx, prop, "unknown or read-only property"); }
    }
}

// ---- outdoor-unit temperature tables (upstream util/ac_tables.ts) ---------------------
// Close to the wall-controller protocol's pipe temperature mapping; index 255 (-100 C) is
// left out as a sentinel.

fn air_temps() {
    [
        300.0, 214.42, 177.12, 157.75, 144.95, 135.49, 128.04, 121.93, 116.77, 112.31, 108.38, 104.89,
        101.74, 98.88, 96.26, 93.84, 91.6, 89.51, 87.56, 85.72, 83.98, 82.34, 80.78, 79.3,
        77.89, 76.54, 75.24, 74.0, 72.81, 71.66, 70.55, 69.48, 68.45, 67.45, 66.48, 65.54,
        64.63, 63.74, 62.88, 62.04, 61.22, 60.43, 59.65, 58.89, 58.14, 57.42, 56.71, 56.01,
        55.33, 54.66, 54.01, 53.36, 52.73, 52.11, 51.5, 50.91, 50.32, 49.74, 49.17, 48.61,
        48.06, 47.51, 46.98, 46.45, 45.93, 45.41, 44.91, 44.4, 43.91, 43.42, 42.94, 42.46,
        41.99, 41.53, 41.07, 40.61, 40.16, 39.71, 39.27, 38.84, 38.4, 37.97, 37.55, 37.13,
        36.71, 36.3, 35.89, 35.48, 35.08, 34.68, 34.28, 33.89, 33.5, 33.11, 32.72, 32.34,
        31.96, 31.58, 31.21, 30.83, 30.46, 30.09, 29.73, 29.36, 29.0, 28.64, 28.28, 27.93,
        27.57, 27.22, 26.87, 26.52, 26.17, 25.82, 25.48, 25.13, 24.79, 24.45, 24.11, 23.77,
        23.43, 23.09, 22.76, 22.42, 22.09, 21.76, 21.42, 21.09, 20.76, 20.43, 20.1, 19.78,
        19.45, 19.12, 18.79, 18.47, 18.14, 17.82, 17.49, 17.16, 16.84, 16.52, 16.19, 15.87,
        15.54, 15.22, 14.9, 14.57, 14.25, 13.92, 13.6, 13.27, 12.95, 12.63, 12.3, 11.97,
        11.65, 11.32, 10.99, 10.67, 10.34, 10.01, 9.68, 9.35, 9.02, 8.69, 8.35, 8.02,
        7.69, 7.35, 7.01, 6.68, 6.34, 6.0, 5.65, 5.31, 4.97, 4.62, 4.27, 3.92,
        3.57, 3.22, 2.86, 2.5, 2.14, 1.78, 1.42, 1.05, 0.68, 0.31, -0.06, -0.44,
        -0.82, -1.2, -1.58, -1.97, -2.37, -2.76, -3.16, -3.56, -3.97, -4.38, -4.8, -5.22,
        -5.64, -6.07, -6.51, -6.95, -7.39, -7.85, -8.3, -8.77, -9.24, -9.72, -10.2, -10.7,
        -11.2, -11.71, -12.23, -12.76, -13.3, -13.85, -14.41, -14.98, -15.57, -16.17, -16.79, -17.42,
        -18.06, -18.73, -19.42, -20.12, -20.85, -21.61, -22.39, -23.2, -24.04, -24.92, -25.83, -26.8,
        -27.81, -28.88, -30.01, -31.21, -32.51, -33.9, -35.42, -37.08, -38.94, -41.03, -43.45, -46.33,
        -49.93, -54.79, -62.6
    ]
}

fn pipe_temps() {
    [
        300.0, 224.93, 184.71, 163.98, 150.32, 140.26, 132.36, 125.88, 120.42, 115.7, 111.56, 107.87,
        104.56, 101.54, 98.79, 96.24, 93.89, 91.69, 89.64, 87.71, 85.89, 84.16, 82.53, 80.98,
        79.5, 78.08, 76.73, 75.43, 74.18, 72.98, 71.82, 70.7, 69.62, 68.58, 67.57, 66.58,
        65.63, 64.71, 63.81, 62.93, 62.08, 61.24, 60.43, 59.64, 58.86, 58.11, 57.37, 56.64,
        55.93, 55.23, 54.55, 53.88, 53.23, 52.58, 51.95, 51.32, 50.71, 50.11, 49.52, 48.93,
        48.36, 47.79, 47.24, 46.69, 46.15, 45.61, 45.09, 44.57, 44.05, 43.54, 43.04, 42.55,
        42.06, 41.58, 41.1, 40.62, 40.16, 39.69, 39.24, 38.78, 38.33, 37.89, 37.45, 37.01,
        36.58, 36.15, 35.72, 35.3, 34.88, 34.47, 34.06, 33.65, 33.24, 32.84, 32.44, 32.05,
        31.65, 31.26, 30.87, 30.49, 30.1, 29.72, 29.34, 28.96, 28.59, 28.22, 27.85, 27.48,
        27.11, 26.74, 26.38, 26.02, 25.66, 25.3, 24.94, 24.59, 24.23, 23.88, 23.53, 23.18,
        22.83, 22.48, 22.13, 21.79, 21.44, 21.1, 20.75, 20.41, 20.07, 19.73, 19.39, 19.05,
        18.71, 18.37, 18.04, 17.7, 17.36, 17.03, 16.69, 16.36, 16.02, 15.69, 15.35, 15.02,
        14.68, 14.35, 14.01, 13.68, 13.35, 13.01, 12.68, 12.34, 12.01, 11.67, 11.34, 11.0,
        10.66, 10.33, 9.99, 9.65, 9.32, 8.98, 8.64, 8.3, 7.96, 7.61, 7.27, 6.93,
        6.58, 6.24, 5.89, 5.54, 5.19, 4.84, 4.49, 4.14, 3.78, 3.43, 3.07, 2.71,
        2.35, 1.98, 1.62, 1.25, 0.88, 0.51, 0.13, -0.24, -0.62, -1.0, -1.39, -1.77,
        -2.16, -2.56, -2.95, -3.35, -3.76, -4.16, -4.57, -4.99, -5.41, -5.83, -6.25, -6.69,
        -7.12, -7.56, -8.01, -8.46, -8.92, -9.38, -9.85, -10.33, -10.81, -11.3, -11.8, -12.31,
        -12.82, -13.34, -13.88, -14.42, -14.97, -15.54, -16.11, -16.7, -17.3, -17.92, -18.55, -19.19,
        -19.85, -20.54, -21.24, -21.96, -22.71, -23.48, -24.27, -25.1, -25.96, -26.86, -27.8, -28.78,
        -29.81, -30.9, -32.06, -33.29, -34.61, -36.03, -37.58, -39.27, -41.16, -43.29, -45.76, -48.69,
        -52.34, -57.28, -65.19
    ]
}
