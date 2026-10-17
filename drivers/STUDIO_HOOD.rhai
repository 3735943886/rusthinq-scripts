// LG range hood STUDIO_HOOD: port of upstream rethink's STUDIO_HOOD.ts (commit 0e57069), reverse
// engineered there from live traffic while cycling the light and the fan.
//
// Status is a 0x43 EB frame of one 12-byte block (the reply to start()'s query) or EC of two
// (previous, current); block offsets: 1 fan speed (0-5), 5 light level (0-2). `43 00 43 00` is the
// hood's ack of a command, without state. A command carries the whole wanted state:
// F0 43 22 05 <fan on> <fan speed> <light on> <light level> 00, so the driver keeps the last
// reported speed and level to send the control it does not change. The fan is the device's
// composite, the light a group of its own.
import "aabb_common" as c;
import "il_common" as il;

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "fan", label: "Range hood", vendor: "LG", model: ctx.model_id(),
                      groups: #{ light: #{ kind: "light", label: "Light" } }, props: #{
        available: #{ type: "binary", role: "available" },
        fan_power: #{ type: "binary", rw: true, role: "on", label: "Fan" },
        fan_speed: #{ type: "number", rw: true, min: 0, max: 5, step: 1 },
        light_power: #{ type: "binary", rw: true, role: "on", group: "light", label: "Light" },
        light_level: #{ type: "number", rw: true, min: 0, max: 2, step: 1, group: "light" }
    } })
}

fn start(ctx) {
    ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x11, 0x41, 0x01, 0x00, 0x00, 0x00, 0x18, 0x04, 0x03, 0x04, 0x00, 0x00]));
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let b = c::inner(data, 0x43);
    if b == () { return; }
    let o = c::common_status_offset(b, 12);
    if o == () { return; }
    let fan = b[o + 1].to_int();
    let light = b[o + 5].to_int();
    ctx.state_set("fan", fan);
    ctx.state_set("light", light);
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "fan_power", if fan > 0 { "true" } else { "false" });
    il::publish_property(ctx, "fan_speed", fan.to_string());
    il::publish_property(ctx, "light_power", if light > 0 { "true" } else { "false" });
    il::publish_property(ctx, "light_level", light.to_string());
}

fn command(ctx, fan, light) {
    ctx.state_set("fan", fan);
    ctx.state_set("light", light);
    ctx.send_raw(aabb_wrap([0xf0, 0x43, 0x22, 0x05, if fan > 0 { 1 } else { 0 }, fan,
                            if light > 0 { 1 } else { 0 }, light, 0x00]));
}

fn set_property(ctx, prop, value) {
    let fan = ctx.state_get("fan") ?? 0;
    let light = ctx.state_get("light") ?? 0;
    switch prop {
        // switched on without a speed or level, the last one or 1
        "fan_power" => command(ctx, if c::to_bool(value) { if fan > 0 { fan } else { 1 } } else { 0 }, light),
        "fan_speed" => command(ctx, c::to_number(value).round().to_int(), light),
        "light_power" => command(ctx, fan, if c::to_bool(value) { if light > 0 { light } else { 1 } } else { 0 }),
        "light_level" => command(ctx, fan, c::to_number(value).round().to_int()),
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
