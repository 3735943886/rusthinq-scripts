// LG portable air conditioner POT_056905_WW (LP1022FVSM): climate_common, as upstream rethink's
// POT_056905_WW.ts (commit 0e57069). Cool, dry and fan only; fan low 2, medium 4, high 6;
// swing on 0x322 (100 on, 0 off); setpoint 16 to 30 in whole degrees. Its frames have byte 6 =
// 0xa7. Power on carries only the mode; the climate_common defaults cover the other writes.
import "climate_common";
import "tlv_common" as c;
import "il_common" as il;

fn label() { "Portable air conditioner" }
fn target_step() { 1 }
fn power_attach() { [0x1f9] }

fn extra_props(ctx) {
    #{ swing: #{ type: "binary", rw: true, role: "swing_vertical", src: #{ tlv_tag: "0x322" } } }
}

fn apply_extra(ctx, tag, v) {
    if tag == 0x322 {
        if v == 100 { il::publish_property(ctx, "swing", "true"); }
        else if v == 0 { il::publish_property(ctx, "swing", "false"); }
    }
}

fn set_extra(ctx, prop, value) {
    if prop != "swing" { return false; }
    c::write(ctx, 0x322, if c::to_bool(value) { 100 } else { 0 }, [0x1f9, 0x1fa]);
    true
}
