// LG over-the-range microwave WMVEM1825: port of upstream rethink's WMVEM1825.ts (commit 0e57069).
//
// Status is a 0x41 EB frame of one 46-byte block or EC of two (previous, current); block offsets:
// 0 state   10 power level (0-10, x10 %)   15/16/17 remaining time (h, min, s)   36 hood: low
// nibble the vent fan (0-2), bits 4-6 the cooktop light (0-2). A value outside its range is not
// published. The door is a short event, `41 B2 00 0F 07 0A 01 03 00 00 00 <0 shut | 1 open>`. A
// hood command carries both controls: F0 43 22 04 <fan on> <fan> <light on> <light> 80 80, so
// the driver keeps the last reported one to send the control it does not change. The vent fan and
// the light are groups of their own.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn states() { #{ "0": "idle", "2": "cooking", "4": "paused", "5": "done", "7": "ready_to_start" } }

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "microwave", label: "Microwave", vendor: "LG", model: ctx.model_id(),
                      groups: #{ vent: #{ kind: "fan", label: "Vent fan" }, light: #{ kind: "light", label: "Cooktop light" } },
                      props: #{
        available: #{ type: "binary", role: "available" },
        status: #{ type: "select", options: t::options(states()) },
        remaining_time: #{ type: "number", class: "duration", unit: "s" },
        power_level: #{ type: "number", unit: "%" },
        door: #{ type: "binary", class: "door", label: "Door open" },
        fan_power: #{ type: "binary", rw: true, role: "on", group: "vent", label: "Vent fan" },
        fan_speed: #{ type: "number", rw: true, min: 0, max: 2, step: 1, group: "vent" },
        light_power: #{ type: "binary", rw: true, role: "on", group: "light", label: "Cooktop light" },
        light_level: #{ type: "number", rw: true, min: 0, max: 2, step: 1, group: "light" }
    } })
}

fn start(ctx) {
    ctx.send_raw(aabb_wrap(hex_decode("f0ed114101000000181a0207080c14191a1e262b30353a00000000000000000000000000")));
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let b = c::inner(data, 0x41);
    if b == () { return; }
    if b.len() == 12 && b[1] == 0xb2 && hex_encode(b.extract(2, 9)) == "000f070a0103000000" {
        if b[11] == 0 || b[11] == 1 { il::publish_property(ctx, "door", if b[11] == 1 { "true" } else { "false" }); }
        return;
    }
    let o = c::common_status_offset(b, 46);
    if o == () { return; }
    let r = b.extract(o, 46);
    il::publish_property(ctx, "available", "true");
    c::pub_name(ctx, "status", t::name(states(), r[0]));
    il::publish_property(ctx, "remaining_time", (r[15] * 3600 + r[16] * 60 + r[17]).to_string());
    if r[10] <= 10 { il::publish_property(ctx, "power_level", (r[10] * 10).to_string()); }
    let fan = (r[36] & 0x0f).to_int();
    let light = ((r[36] >> 4) & 0x07).to_int();
    if fan <= 2 {
        ctx.state_set("fan", fan);
        il::publish_property(ctx, "fan_power", if fan > 0 { "true" } else { "false" });
        il::publish_property(ctx, "fan_speed", fan.to_string());
    }
    if light <= 2 {
        ctx.state_set("light", light);
        il::publish_property(ctx, "light_power", if light > 0 { "true" } else { "false" });
        il::publish_property(ctx, "light_level", light.to_string());
    }
}

fn command(ctx, fan, light) {
    ctx.state_set("fan", fan);
    ctx.state_set("light", light);
    ctx.send_raw(aabb_wrap([0xf0, 0x43, 0x22, 0x04, if fan > 0 { 1 } else { 0 }, fan,
                            if light > 0 { 1 } else { 0 }, light, 0x80, 0x80]));
}

fn set_property(ctx, prop, value) {
    let fan = ctx.state_get("fan") ?? 0;
    let light = ctx.state_get("light") ?? 0;
    switch prop {
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
