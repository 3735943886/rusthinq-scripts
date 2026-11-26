// LG refrigerator 2ROFL1DBN3K_U (KR, firmware clip_ble_v2.9.244): device -> IL driver,
// READ-ONLY. The status record has the layout of 2ROFL2DBN3K_U.rhai but is 96 bytes long
// instead of 90: 10 EB carries one record (frame 102 bytes), 10 EC the previous record then
// the current one (frame 198 bytes). With record(data, 90) nothing decodes on this unit.
// Captured on one unit (2026-11-25, rusthinqctl capture --cloud) and compared with the LG
// cloud reports of the same moments:
//   [1] fridge setpoint wire -> 8 - raw (5 -> 3 C), [2] freezer -> -14 - raw (4 -> -18 C),
//   [3] express freeze (2 on, else off; 1 = off matched), [7] any door open (0/1, matched
//   refState.atLeastOneDoorOpen OPEN/CLOSE within a second), [8] unit (1 = Celsius; any
//   other value drops the frame, as in 2ROFL2DBN3K_U).
//   10 3E energy report: 7-byte body, [4..5] running total in Wh, as on 2ROFL2DBN3K_U.
//   10 0A, 10 C5, 10 18 and 10 00 frames are acknowledged but not decoded.
// Not verified: every write. 2ROFL2DBN3K_U writes F0 17 + a 118-byte app record; no write has
// been captured on this model, so all properties are read-only and nothing is ever sent.

import "aabb_common" as c;
import "fridge_common" as f;
import "il_common" as il;

fn descriptor(ctx) {
    let props = f::props("C");
    // Read-only: no write has been captured on this model (see the header).
    props.fridge_setpoint.rw = false;
    props.freezer_setpoint.rw = false;
    props += #{
        express_freeze: #{ type: "binary", label: "Express freeze" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Energy" }
    };
    json_stringify(#{ il: 0, kind: "fridge", label: "Refrigerator", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

// Silent on purpose: the unit pushes 10 EB on connect and 10 EC on change.
fn start(ctx) { }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let inner = c::inner(data, 0x10);
    if inner == () { return; }
    if inner[1] == 0x3e {
        if inner.len() == 7 { il::publish_property(ctx, "energy", (inner[4] * 256 + inner[5]).to_string()); }
        return;
    }
    let s = f::record(data, 96);
    if s == () { return; }
    status(ctx, s);
}

fn status(ctx, s) {
    // Anything but 1 at [8] is not the Celsius encoding this driver was verified
    // against; drop the frame rather than mis-scale it (the TS driver's rule).
    if s[8] != 1 { return; }
    il::publish_property(ctx, "available", "true");
    if s[1] >= 1 && s[1] <= 7 {
        il::publish_property(ctx, "fridge_setpoint", (8 - s[1]).to_string());
    }
    if s[2] >= 1 && s[2] <= 9 {
        il::publish_property(ctx, "freezer_setpoint", (-14 - s[2]).to_string());
    }
    il::publish_property(ctx, "express_freeze", f::express_freeze(s));
    il::publish_property(ctx, "door", c::on_off(s[7]));
}

fn on_set_property(ctx, prop, value) {
    // Every property is read-only, so il::validate publishes the reject; nothing is sent.
    let value = il::validate(ctx, prop, value);
    if value != () { c::reject(ctx, prop, "read-only on this model"); }
}
