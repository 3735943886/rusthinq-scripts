// rusthinq 0.1 owns IL publication, state tracking and command validation.
// Driver initialization is admitted by the host only for an online device.
// Restore connection availability even before a fresh state frame arrives.
fn publish_il(ctx, text) {
    ctx.publish_il(text);
    // All bundled drivers declare the binary available property.
    ctx.publish_property("available", "true");
}
fn publish_property(ctx, prop, value) { ctx.publish_property(prop, value); }
fn publish_event(ctx, suffix, payload) { ctx.publish_event(suffix, payload); }

// The host validates and canonicalizes commands before invoking on_set_property.
fn validate(ctx, prop, value) { value }

fn reject(ctx, prop, code, reason) {
    publish_event(ctx, "reject",
        json_stringify(#{prop: prop, code: code, reason: reason}));
    ()
}
