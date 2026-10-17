// LG ceiling-cassette indoor unit CST_570004_WW (multi-split, cooling only): device -> IL driver.
//
// A TLV (DualCool family) appliance on `climate_common`, which carries power, mode, fan,
// setpoint, room temperature, the action and its polling. This script is for this model only,
// so it carries no capability probing: the tag numbers, wire scales and feature set below are
// what this unit reports and accepts.
//
// Wire tags: 0x1f9 mode (cool 0, dry 1, fan 2, auto 3), 0x1fa fan (auto 8, very low 1, low 2,
// medium 4, high 6, power 7), 0x205 / 0x206 vertical / horizontal swing (on/off), 0x20d energy
// saving (only meaningful in cool), 0x20e auto dry (0 off, 1 10 min, 2 30 min, 3 60 min,
// 255 smart), 0x225 auto dry minutes left, 0x21a sleep timer (minutes), 0x21f display
// brightness (100 off, 150 half, 200 full), 0x221 error, 0x23f comfort energy saving, 0x2b3
// power draw (W), 0x336 humidity (tenths of a percent), 0x355 / 0x356 filter hours left /
// rated life, 0x189 or 0x6c whether the unit is actually cooling right now (when it reports
// either), 0x290 / 0x291 / 0x3d5 / 0x3d6 / 0x3d7 the wind-mode flags (exactly one set, or none).
//
// Frames from this model have byte 6 = 0xa7, which `tlv_frame_parse` accepts.

import "climate_common";
import "tlv_common" as c;
import "table_common" as t;
import "il_common" as il;

// ---- model ------------------------------------------------------------------------

fn modes() { #{ "0": "cool", "1": "dry", "2": "fan_only", "3": "auto" } }

fn fans() { #{ "8": "auto", "1": "very_low", "2": "low", "4": "medium", "6": "high", "7": "power" } }
fn fan_options() { ["auto", "very_low", "low", "medium", "high", "power"] }

fn tracks_action() { true }
fn masks_reports() { true }

fn auto_dry_modes() { #{ "0": "off", "1": "10min", "2": "30min", "3": "60min", "255": "smart" } }

fn displays() { #{ "100": "off", "150": "50%", "200": "100%" } }

fn extra_props(ctx) {
    #{
        humidity: #{ type: "number", class: "humidity", series: "gauge", role: "current_humidity", src: #{ tlv_tag: "0x336" }, unit: "%" },
        swing_vertical: #{ type: "binary", rw: true, role: "swing_vertical", src: #{ tlv_tag: "0x205" } },
        swing_horizontal: #{ type: "binary", rw: true, role: "swing_horizontal", src: #{ tlv_tag: "0x206" } },
        energy_save: #{ type: "binary", category: "config", rw: true, src: #{ tlv_tag: "0x20d" } },
        comfort_saving: #{ type: "binary", category: "config", rw: true, src: #{ tlv_tag: "0x23f" } },
        wind_mode: #{ type: "select", category: "config", rw: true,
                      options: ["off", "manner", "long_power", "study", "auto_temp"] },
        auto_dry: #{ type: "select", category: "config", rw: true, src: #{ tlv_tag: "0x20e" },
                     options: t::options(auto_dry_modes()) },
        auto_dry_remaining: #{ type: "number", class: "duration", category: "diagnostic", src: #{ tlv_tag: "0x225" }, unit: "min" },
        sleep_timer: #{ type: "number", class: "duration", rw: true, src: #{ tlv_tag: "0x21a" },
                        min: 0, max: 900, step: 1, unit: "min" },
        display: #{ type: "select", category: "config", rw: true, src: #{ tlv_tag: "0x21f" },
                    options: t::options(displays()) },
        power_draw: #{ type: "number", class: "power", series: "gauge", src: #{ tlv_tag: "0x2b3" }, unit: "W" },
        filter_remaining: #{ type: "number", series: "gauge", category: "diagnostic", src: #{ tlv_tag: "0x355" }, unit: "%" },
        filter_used: #{ type: "number", class: "duration", series: "counter", category: "diagnostic", src: #{ tlv_tag: "0x355" }, unit: "h" },
        filter_life: #{ type: "number", class: "duration", category: "diagnostic", src: #{ tlv_tag: "0x356" }, unit: "h" },
        error: #{ type: "number", category: "diagnostic", src: #{ tlv_tag: "0x221" } }
    }
}

// The five wind-mode flags, in the order the app writes them.
fn wind_flags() { [0x290, 0x291, 0x3d5, 0x3d6, 0x3d7] }

fn wind_flag(name) {
    switch name {
        "manner" => 0x3d6,
        "long_power" => 0x3d7,
        "study" => 0x291,
        "auto_temp" => 0x290,
        _ => ()
    }
}

fn wind_name(ctx) {
    if c::get(ctx, 0x3d6) != 0 { "manner" }
    else if c::get(ctx, 0x3d7) != 0 { "long_power" }
    else if c::get(ctx, 0x291) != 0 { "study" }
    else if c::get(ctx, 0x290) != 0 { "auto_temp" }
    else { "off" }
}

// ---- reads ------------------------------------------------------------------------

// Energy saving is settled after the frame, against the mode it leaves the unit in.
fn held(tag) { tag == 0x20d }

fn apply_extra(ctx, tag, v) {
    switch tag {
        0x336 => { il::publish_property(ctx, "humidity", (v / 10.0).round().to_int().to_string()); }
        0x205 => { il::publish_property(ctx, "swing_vertical", c::flag(v)); }
        0x206 => { il::publish_property(ctx, "swing_horizontal", c::flag(v)); }
        0x23f => { il::publish_property(ctx, "comfort_saving", c::flag(v)); }
        0x20e => {
            let name = t::name(auto_dry_modes(), v);
            if name != () { il::publish_property(ctx, "auto_dry", name); }
        }
        0x225 => { il::publish_property(ctx, "auto_dry_remaining", v.to_string()); }
        0x21a => { il::publish_property(ctx, "sleep_timer", v.to_string()); }
        0x21f => {
            let name = t::name(displays(), v);
            if name != () { il::publish_property(ctx, "display", name); }
        }
        0x221 => { il::publish_property(ctx, "error", v.to_string()); }
        0x2b3 => { il::publish_property(ctx, "power_draw", v.to_string()); }
        _ => {}
    }
}

fn after_values(ctx, tlvs, before) {
    let energy = ();
    for e in tlvs { if e.t == 0x20d { energy = e.v; } }
    let mode = effective_mode(ctx);
    settle_energy(ctx, energy, before != mode && mode == "cool");
    if tlvs.some(|e| e.t == 0x290 || e.t == 0x291 || e.t == 0x3d5 || e.t == 0x3d6 || e.t == 0x3d7) {
        il::publish_property(ctx, "wind_mode", wind_name(ctx));
    }
    if tlvs.some(|e| e.t == 0x355 || e.t == 0x356) { publish_filter(ctx); }
}

// Energy saving only takes effect in cool, and the unit forgets it over a power cycle. So a
// report is trusted only while running in cool; on entering cool the wanted value is written
// again (in its own frame) rather than adopting whatever the unit reports right after power up.
fn settle_energy(ctx, reported, entered_cool) {
    let want = ctx.state_get("energy_want");
    if entered_cool && want != () {
        if (reported != 0) != want { c::write(ctx, 0x20d, if want { 1 } else { 0 }, []); }
        il::publish_property(ctx, "energy_save", c::flag(if want { 1 } else { 0 }));
    } else if reported != () && effective_mode(ctx) == "cool" {
        c::put(ctx, 0x20d, reported);
        ctx.state_set("energy_want", reported != 0);
        il::publish_property(ctx, "energy_save", c::flag(reported));
    }
}

fn publish_filter(ctx) {
    let life = c::get(ctx, 0x356);
    let left = c::get(ctx, 0x355);
    if life > 0 {
        il::publish_property(ctx, "filter_remaining", (left * 100.0 / life).round().to_int().to_string());
        il::publish_property(ctx, "filter_used", (life - left).to_string());
        il::publish_property(ctx, "filter_life", life.to_string());
    }
}

// ---- writes -----------------------------------------------------------------------

fn set_extra(ctx, prop, value) {
    switch prop {
        "swing_vertical" => { c::write(ctx, 0x205, if c::to_bool(value) { 1 } else { 0 }, []); }
        "swing_horizontal" => { c::write(ctx, 0x206, if c::to_bool(value) { 1 } else { 0 }, []); }
        "comfort_saving" => { c::write(ctx, 0x23f, if c::to_bool(value) { 1 } else { 0 }, []); }
        "energy_save" => {
            let on = c::to_bool(value);
            ctx.state_set("energy_want", on);
            il::publish_property(ctx, "energy_save", c::flag(if on { 1 } else { 0 }));
            // Only takes effect while running in cool; otherwise it is written on entering cool.
            if effective_mode(ctx) == "cool" { c::write(ctx, 0x20d, if on { 1 } else { 0 }, []); }
        }
        "auto_dry" => {
            let wire = t::code(auto_dry_modes(), value);
            if wire == () { c::reject(ctx, prop, "unknown auto dry setting"); return true; }
            c::write(ctx, 0x20e, wire, []);
        }
        "display" => {
            let wire = t::code(displays(), value);
            if wire == () { c::reject(ctx, prop, "unknown brightness"); return true; }
            c::write(ctx, 0x21f, wire, []);
        }
        "sleep_timer" => {
            let n = c::to_number(value);
            if n == () { c::reject(ctx, prop, "not a number"); return true; }
            c::write(ctx, 0x21a, n.round().to_int(), []);
        }
        "wind_mode" => {
            let on = wind_flag(value);
            if on == () && value != "off" { c::reject(ctx, prop, "unknown wind mode"); return true; }
            // exactly one flag set, or none
            let tlvs = [];
            for f in wind_flags() {
                let v = if f == on { 1 } else { 0 };
                c::put(ctx, f, v);
                tlvs.push(#{ t: f, v: v });
            }
            ctx.send_raw(tlv_frame_build(c::write_header(), tlvs));
            il::publish_property(ctx, "wind_mode", value);
        }
        _ => { return false; }
    }
    true
}
