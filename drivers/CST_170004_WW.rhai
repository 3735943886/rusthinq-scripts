// LG ceiling-cassette indoor unit CST_170004_WW (multi-split, cooling only, sold in Korea):
// device -> IL driver. Ported from the owner's rethink driver `cloud/devices/CST_170004_WW.ts`
// (on its `ac_common.ts`) and its test suite, up to "power on CST units with the power preset"
// and "carry the fan speed in the fan-2h preset write".
//
// The same wire scheme and tables as CST_570004_WW, so the body is cst_common (see there for the
// tags). What this model adds or does differently:
//
// - 0x205 / 0x206 (vertical / horizontal swing) are written together in one frame, the other
//   flag at its last known value, so the vanes move together as the LG app moves them.
// - 0x321 is the vertical vane position: 0 parked, 1 (top) to 6 (bottom). The continuous sweep
//   100 that other models take is refused (the unit coerced it back to 4), so it is not offered.
// - 0x2b5 is the outdoor unit's total power draw in watts; every indoor unit on it reports the
//   same value.
// - The sleep timer (0x21a) runs 1 to 7 h on this model: at most 420 minutes.
// - `preset` is a reading of mode, fan and sleep timer, and a macro over them:
//     fan_2h_off  fan_only at medium fan (both in the one mode frame), then a 120 min sleep timer
//     power       cool with power fan (7), in the one mode frame, which also powers the unit on
//     none        clears the sleep timer and leaves mode and fan as they are
//   fan_2h_off reads first (fan_only with a timer running), then power (fan 7).
// - A setpoint cannot ride the frame that ends power fan: the unit restores the setpoint it had
//   before power fan and ignores the one in the frame. So a setpoint asked for while the fan is at
//   power first sets the fan to high (where the unit goes when power fan ends) and is written once
//   the unit reports that the fan has changed.
//
// Left out: the on/off reservation relay (0x21b / 0x21c), which the unit acknowledges but never
// runs. rethink runs it by watching the cloud's writes, reporting the reservation back to the
// cloud as if the unit had, and keeping the deadlines on disk; this host has none of those, and a
// countdown kept in session state would be lost silently on a reconnect. With it go the sleep /
// turn-off timer exclusivity and the Home Assistant entity names, labels and swing attribute
// placement. Energy saving follows cst_common: it is rewritten on entering cool only when the
// unit reports a value other than the one wanted.
import "cst_common";
import "tlv_common" as c;
import "table_common" as t;
import "il_common" as il;

fn vane_positions() { #{ "0": "off", "1": "1", "2": "2", "3": "3", "4": "4", "5": "5", "6": "6" } }

fn presets() { ["none", "fan_2h_off", "power"] }

fn power_fan() { 7 }

// ---- descriptor -------------------------------------------------------------------

fn extra_props(ctx) {
    let props = cst_extra_props(ctx);
    props.sleep_timer.max = 420;
    props.vane_position = #{ type: "select", rw: true, src: #{ tlv_tag: "0x321" },
                            options: t::options(vane_positions()) };
    props.odu_power = #{ type: "number", class: "power", series: "gauge", src: #{ tlv_tag: "0x2b5" },
                         unit: "W", label: "Outdoor unit total power" };
    props.preset = #{ type: "select", rw: true, options: presets() };
    props
}

// ---- reads ------------------------------------------------------------------------

fn apply_extra(ctx, tag, v) {
    switch tag {
        0x321 => {
            let name = t::name(vane_positions(), v);
            if name != () { il::publish_property(ctx, "vane_position", name); }
        }
        0x2b5 => { il::publish_property(ctx, "odu_power", v.to_string()); }
        _ => { cst_apply_extra(ctx, tag, v); }
    }
}

fn preset_name(ctx) {
    if c::get(ctx, 0x1f9) == 2 && c::get(ctx, 0x21a) > 0 { "fan_2h_off" }
    else if c::get(ctx, 0x1fa) == power_fan() { "power" }
    else { "none" }
}

fn after_values(ctx, tlvs, before) {
    cst_after_values(ctx, tlvs, before);
    if tlvs.some(|e| e.t == 0x1f9 || e.t == 0x1fa || e.t == 0x21a) {
        il::publish_property(ctx, "preset", preset_name(ctx));
    }
    // The setpoint held while power fan ended goes out on the first report of a changed fan.
    let fan = ();
    for e in tlvs { if e.t == 0x1fa { fan = e.v; } }
    if fan != () && fan != ctx.state_get("fan_seen") {
        ctx.state_set("fan_seen", fan);
        let pending = ctx.state_get("pending_target");
        if pending != () {
            ctx.state_set("pending_target", ());
            if fan != power_fan() { climate_set_property(ctx, "target", pending); }
        }
    }
}

// ---- writes -----------------------------------------------------------------------

fn set_property(ctx, prop, value) {
    if prop == "target" && c::get(ctx, 0x1fa) == power_fan() {
        ctx.state_set("pending_target", value);
        climate_set_property(ctx, "fan", "high");
    } else {
        climate_set_property(ctx, prop, value);
    }
}

fn set_extra(ctx, prop, value) {
    switch prop {
        "swing_vertical" | "swing_horizontal" => {
            let on = if c::to_bool(value) { 1 } else { 0 };
            let tag = if prop == "swing_vertical" { 0x205 } else { 0x206 };
            c::put(ctx, tag, on);
            ctx.send_raw(tlv_frame_build(c::write_header(),
                [#{ t: 0x205, v: c::get(ctx, 0x205) }, #{ t: 0x206, v: c::get(ctx, 0x206) }]));
        }
        "vane_position" => { c::write(ctx, 0x321, t::code(vane_positions(), value), []); }
        "preset" => {
            switch value {
                "fan_2h_off" => {
                    c::put(ctx, 0x1fa, 4);
                    climate_set_property(ctx, "mode", "fan_only");
                    c::write(ctx, 0x21a, 120, []);
                }
                "power" => {
                    c::put(ctx, 0x1fa, power_fan());
                    climate_set_property(ctx, "mode", "cool");
                }
                _ => { c::write(ctx, 0x21a, 0, []); }
            }
        }
        _ => { return cst_set_extra(ctx, prop, value); }
    }
    true
}
