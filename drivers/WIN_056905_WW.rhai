// LG window air conditioner WIN_056905_WW (LW1823HRSM): climate_common, as upstream rethink's
// WIN_056905_WW.ts (commit 0e57069), which has no tests or captures of its own.
//
// Modes cool 0, fan 2, heat 4; fan low 2, high 6; swing on 0x322 (100 on, 0 off); setpoint 16 to
// 30 in half degrees. Upstream writes dry as 8 but does not read 8 (its read table leaves 8 as a
// commented-out "eco", flagged FIXME), so dry is left out. A mode write powers the unit on in a
// frame of its own (power and the mode), then writes the mode with power, fan, setpoint and swing.
import "climate_common";
import "tlv_common" as c;
import "table_common" as t;
import "il_common" as il;

fn modes() { #{ "0": "cool", "2": "fan_only", "4": "heat" } }
fn fans() { #{ "2": "low", "6": "high" } }
fn label() { "Window air conditioner" }
fn power_attach() { [0x1f9] }
fn mode_attach() { [0x1f7, 0x1fa, 0x1fe, 0x322] }

fn extra_props(ctx) {
    #{ swing: #{ type: "binary", rw: true, role: "swing_vertical", src: #{ tlv_tag: "0x322" } } }
}

fn apply_extra(ctx, tag, v) {
    if tag == 0x322 {
        if v == 100 { il::publish_property(ctx, "swing", "true"); }
        else if v == 0 { il::publish_property(ctx, "swing", "false"); }
    }
}

fn set_property(ctx, prop, value) {
    if prop == "mode" {
        let wire = t::code(modes(), value);
        if wire == () { c::reject(ctx, prop, "unknown mode"); return; }
        climate_set_property(ctx, "power", "true");
    }
    climate_set_property(ctx, prop, value);
}

fn set_extra(ctx, prop, value) {
    if prop != "swing" { return false; }
    c::write(ctx, 0x322, if c::to_bool(value) { 100 } else { 0 }, [0x1f9, 0x1fa]);
    true
}
