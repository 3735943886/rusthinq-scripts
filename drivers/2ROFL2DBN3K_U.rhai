// LG refrigerator 2ROFL2DBN3K_U: device -> IL driver. Port of the owner's rethink
// TypeScript driver (fridge_2rofl2dbn3k.ts), whose offsets and write template were
// measured on the owner's own unit (2026-11-03). An AABB appliance; it pushes a 10 EC
// burst on connect and on change, so `start` deliberately sends nothing (the TS driver
// sends no query either). Inner frames (class 0x10, then):
//   0xEB  one 90-byte status record
//   0xEC  the previous record then the current one, stacked
//   0x3E  energy report, 7 bytes: [3] per-interval Wh delta, [4..5] running total,
//         [6] tick. The running total is `energy`, a counter that resets at no fixed time
//         (a consumer's utility meter handles the reset); a retransmitted report carries
//         the same total. The TS driver's KST hour/day/month buckets are not kept: period
//         totals are the consumer's utility meter (writing-a-driver.md, Energy).
//   0x0A  periodic snapshot, not decoded (as in the TS driver)
//
// Status record offsets (verified live against the official integration's values):
//   1 fridge setpoint wire -> 8 - raw (raw 1..7 only), 2 freezer setpoint wire ->
//   -14 - raw (raw 1..9 only), 3 express freeze (2 on, else off), 7 any door open
//   (exactly 1 is open), 8 unit (must be 1 = Celsius; any other value drops the frame
//   rather than mis-scale it, as in the TS driver).
// Writes are F0 17 + the 118-byte app record (fridge_common::app, byte-identical to
// the TS driver's captured F017 skeleton - verified byte for byte). Temperature
// writes also set [8] = 1 (the zone selector the app sends alongside); the express
// freeze write does NOT carry the selector, exactly as captured on this unit.

import "aabb_common" as c;
import "fridge_common" as f;
import "il_common" as il;

fn descriptor(ctx) {
    let props = f::props("C");
    props += #{
        express_freeze: #{ type: "binary", rw: true, label: "Express freeze" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Energy" }
    };
    json_stringify(#{ il: 0, kind: "fridge", label: "Refrigerator", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

// Silent on purpose (see the header).
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
    let s = f::record(data, 90);
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

fn set_property(ctx, prop, value) {
    switch prop {
        "fridge_setpoint" => {
            let base = f::app(118);
            base[1] = 8 - c::to_number(value).to_int();
            base[8] = 1; // zone selector, sent alongside temperature writes
            f::send(ctx, base);
        }
        "freezer_setpoint" => {
            let base = f::app(118);
            base[2] = -14 - c::to_number(value).to_int();
            base[8] = 1;
            f::send(ctx, base);
        }
        "express_freeze" => {
            let base = f::app(118);
            base[3] = if c::to_bool(value) { 2 } else { 1 }; // no [8] selector here
            f::send(ctx, base);
        }
        _ => { c::reject(ctx, prop, "unknown or read-only property"); }
    }
}

fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
