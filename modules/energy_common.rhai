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
