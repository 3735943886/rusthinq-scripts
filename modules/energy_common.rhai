// Sum every received Wh delta; no deduplication or persistent storage.
import "il_common" as il;

fn total(ctx) {
    let value = ctx.state_get("energy_total_wh");
    if value == () { 0 } else { value }
}

fn publish(ctx) { il::publish_property(ctx, "energy", total(ctx).to_string()); }

fn add(ctx, delta) {
    ctx.state_set("energy_total_wh", total(ctx) + delta);
    publish(ctx);
}

// --- Windowed buckets (hour/day/month) fed by deduplicated reports, plus
// the running total above. State is the driver's in-memory state: it
// survives a script reload, but NOT a device reconnect or a daemon
// restart (the worker is retired and respawned with empty state). Two
// consequences are handled here:
//   - start_publish republishes only when bucket state actually survived,
//     so a cold start does not overwrite retained values with zeros.
//   - The dedupe key lives in the same state, so a report retransmitted
//     across a reconnect can still be counted twice. The devices' own
//     running total would fix that, but on the units these drivers were
//     ported from it resets unpredictably, so it stays untrusted (as in
//     the TS drivers) and the residual risk is documented, not hidden.
fn bucket(ctx, key) {
    let v = ctx.state_get(key);
    if v == () { 0 } else { v }
}

fn publish_all(ctx) {
    publish(ctx);
    il::publish_property(ctx, "energy_hour", bucket(ctx, "energy_hour_wh").to_string());
    il::publish_property(ctx, "energy_day", bucket(ctx, "energy_day_wh").to_string());
    il::publish_property(ctx, "energy_month", bucket(ctx, "energy_month_wh").to_string());
}

fn start_publish(ctx) {
    if ctx.state_get("energy_day_wh") != () { publish_all(ctx); }
}

// One report: (delta, dev_total, tick) identifies it; retransmissions of
// the same report are dropped. Returns true when the report was new.
fn report(ctx, delta, dev_total, tick) {
    let key = delta.to_string() + ":" + dev_total.to_string() + ":" + tick.to_string();
    if ctx.state_get("energy_last_report") == key { return false; }
    ctx.state_set("energy_last_report", key);
    ctx.state_set("energy_total_wh", total(ctx) + delta);
    ctx.state_set("energy_hour_wh", bucket(ctx, "energy_hour_wh") + delta);
    ctx.state_set("energy_day_wh", bucket(ctx, "energy_day_wh") + delta);
    ctx.state_set("energy_month_wh", bucket(ctx, "energy_month_wh") + delta);
    publish_all(ctx);
    true
}

// One rollover timer firing: reset that bucket and re-arm. Returns true
// when `name` was an energy rollover timer.
fn roll(ctx, name) {
    switch name {
        "energy_hour_roll" => { ctx.state_set("energy_hour_wh", 0); ctx.set_timer("energy_hour_roll", 3600000); }
        "energy_day_roll" => { ctx.state_set("energy_day_wh", 0); ctx.set_timer("energy_day_roll", 86400000); }
        "energy_month_roll" => { ctx.state_set("energy_month_wh", 0); ctx.set_timer("energy_month_roll", 2592000000); }
        _ => { return false; }
    }
    publish_all(ctx);
    true
}
