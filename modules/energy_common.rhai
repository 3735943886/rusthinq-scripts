// For an appliance that reports only Wh deltas and no total of its own: sums them into the
// `energy` counter for this session (no deduplication or persistent storage; say so in the
// label). Period totals are never kept here or in a driver: they are the consumer's utility
// meter over `energy` (writing-a-driver.md, Energy).
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
