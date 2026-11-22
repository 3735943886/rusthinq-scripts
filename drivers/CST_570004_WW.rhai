// LG ceiling-cassette indoor unit CST_570004_WW (multi-split, cooling only): device -> IL driver.
// The body is cst_common, which this model's tables and features were written for.
//
// Added from a Korean user's live unit (2026-11-21), on top of cst_common:
//   - pm1 / pm2.5 / pm10 from TLV 0x333 / 0x334 / 0x335 (the same tags as AIR_910604_WW); the
//     values matched the official lg_thinq PM sensors.
//   - air_purify from TLV 0x20f: toggling it with the remote on/off/on reported 1 / 0 / 1, and
//     writing it from Home Assistant worked.
// Observed, not changed: in auto (wire mode 3) the remote shows only the -2..+2 offset, and 0x1fe
// reports it as 30/32/34/36/38 (15..19 °C, 34 = offset 0); the real reference temperature is never
// sent. display / wind_mode / power_draw / auto_dry_remaining were never reported on that unit.
import "cst_common";
import "tlv_common" as c;
import "il_common" as il;

fn extra_props(ctx) {
    let props = cst_extra_props(ctx);
    props.pm1 = #{ type: "number", class: "pm1", series: "gauge", src: #{ tlv_tag: "0x333" }, unit: "μg/m³" };
    props["pm2.5"] = #{ type: "number", class: "pm25", series: "gauge", src: #{ tlv_tag: "0x334" }, unit: "μg/m³" };
    props.pm10 = #{ type: "number", class: "pm10", series: "gauge", src: #{ tlv_tag: "0x335" }, unit: "μg/m³" };
    props.air_purify = #{ type: "binary", rw: true, src: #{ tlv_tag: "0x20f" } };
    props
}

fn apply_extra(ctx, tag, v) {
    switch tag {
        0x333 => { il::publish_property(ctx, "pm1", v.to_string()); }
        0x334 => { il::publish_property(ctx, "pm2.5", v.to_string()); }
        0x335 => { il::publish_property(ctx, "pm10", v.to_string()); }
        0x20f => { il::publish_property(ctx, "air_purify", c::flag(v)); }
        _ => { cst_apply_extra(ctx, tag, v); }
    }
}

fn set_extra(ctx, prop, value) {
    if prop == "air_purify" {
        c::write(ctx, 0x20f, if c::to_bool(value) { 1 } else { 0 }, []);
        return true;
    }
    cst_set_extra(ctx, prop, value)
}
