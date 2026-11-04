// LG refrigerator 2ROFL2DBN3K_U: device -> IL driver. Port of the owner's rethink
// TypeScript driver (fridge_2rofl2dbn3k.ts), whose offsets and write template were
// measured on the owner's own unit (2026-11-03). An AABB appliance; it pushes a 10 EC
// burst on connect and on change, so `start` deliberately sends nothing (the TS driver
// sends no query either). Inner frames (class 0x10, then):
//   0xEB  one 90-byte status record
//   0xEC  the previous record then the current one, stacked
//   0x3E  energy report, 7 bytes: [3] per-interval Wh delta, [4..5] running total
//         (resets unpredictably - never trusted), [6] tick. Reports are retransmitted
//         several times at ~5 s spacing, so they are deduplicated on (delta,total,tick)
//         exactly as the TS driver does, and the delta accumulates into hour/day/month
//         buckets persisted in driver state. The TS buckets are KST *calendar* buckets;
//         Rhai scripts have no wall clock, so here the buckets roll over on elapsed-time
//         timers anchored at driver start (1 h / 24 h / 30 d) - the one intentional
//         divergence from the TS driver, forced by the platform.
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
        energy_hour: #{ type: "number", class: "energy", unit: "Wh", label: "Energy this hour" },
        energy_day: #{ type: "number", class: "energy", unit: "Wh", label: "Energy today" },
        energy_month: #{ type: "number", class: "energy", unit: "Wh", label: "Energy this month" }
    };
    json_stringify(#{ il: 0, kind: "fridge", label: "Refrigerator", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn start(ctx) {
    // Silent on purpose (see the header). Publish the persisted buckets and arm the
    // rollover timers.
    energy_publish(ctx);
    ctx.set_timer("energy_hour_roll", 3600000);
    ctx.set_timer("energy_day_roll", 86400000);
    ctx.set_timer("energy_month_roll", 2592000000);
}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_timer(ctx, name) {
    switch name {
        "energy_hour_roll" => { ctx.state_set("energy_hour_wh", 0); ctx.set_timer("energy_hour_roll", 3600000); }
        "energy_day_roll" => { ctx.state_set("energy_day_wh", 0); ctx.set_timer("energy_day_roll", 86400000); }
        "energy_month_roll" => { ctx.state_set("energy_month_wh", 0); ctx.set_timer("energy_month_roll", 2592000000); }
        _ => { return; }
    }
    energy_publish(ctx);
}

fn bucket(ctx, key) {
    let v = ctx.state_get(key);
    if v == () { 0 } else { v }
}

fn energy_publish(ctx) {
    il::publish_property(ctx, "energy_hour", bucket(ctx, "energy_hour_wh").to_string());
    il::publish_property(ctx, "energy_day", bucket(ctx, "energy_day_wh").to_string());
    il::publish_property(ctx, "energy_month", bucket(ctx, "energy_month_wh").to_string());
}

// One 0x3E report body ([0x10, 0x3e, 0, delta, total_hi, total_lo, tick]).
fn energy_report(ctx, body) {
    let key = body[3].to_string() + ":" + (body[4] * 256 + body[5]).to_string() + ":" + body[6].to_string();
    if ctx.state_get("energy_last_report") == key { return; }
    ctx.state_set("energy_last_report", key);
    ctx.state_set("energy_hour_wh", bucket(ctx, "energy_hour_wh") + body[3]);
    ctx.state_set("energy_day_wh", bucket(ctx, "energy_day_wh") + body[3]);
    ctx.state_set("energy_month_wh", bucket(ctx, "energy_month_wh") + body[3]);
    energy_publish(ctx);
}

fn on_data(ctx, data) {
    let inner = c::inner(data, 0x10);
    if inner == () { return; }
    if inner[1] == 0x3e {
        if inner.len() == 7 { energy_report(ctx, inner); }
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
