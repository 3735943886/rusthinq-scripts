// LG bottom-freezer refrigerator 2REBGLUB_2P__ (GBBSJ2CCEP, EU): port of upstream rethink's
// 2REBGLUB_2P__.ts (commit 2d8eaba), each entity confirmed there against the LG app and each
// write byte for byte against the app's own. 96-byte status records; fridge_common decodes the
// shared fields, plus (named as the LG app names them)
//   12 vacation, 16 Super Cool, 17 Smart Learner (0 off, 1 on)   95 Fresh Converter+
// The fridge also sends, by itself, every 15 minutes:
//   10 AF 00 <Wh u16>      energy used in the last 15 minutes; summed here into a running total
//                          that starts again from 0 on connect (a counter reset)
//   10 C5 <seq> <count>    6-byte records <id> <recent u16> <?> <total u16>, as on 2REF11EIDG__4:
//                          0x01 door openings, 0x11 seconds the door was open
// and once on connect 10 31 <count> <24-byte records>: <index> <11-character part number> 00 00
// <version, 2 bytes> <minor>, which the LG app shows as e.g. "68e0.0".
// Every frame is acked as the LG cloud does. Writes go over the LG app's F0 17 record, with the
// unit only for the setpoints.
import "aabb_common" as c;
import "fridge_common" as f;
import "table_common" as t;
import "il_common" as il;

fn record_len() { 96 }

fn fresh_converters() { #{ "0": "cheese", "1": "fish", "2": "meat" } }

fn descriptor(ctx) {
    let props = f::props(f::unit(ctx));
    props += #{
        express_freeze: #{ type: "binary", rw: true, label: "Express Freeze" },
        super_cool: #{ type: "binary", rw: true, label: "Super Cool" },
        smart_learner: #{ type: "binary", rw: true, label: "Smart Learner" },
        vacation: #{ type: "binary", rw: true },
        fresh_converter: #{ type: "select", rw: true, label: "Fresh Converter+", options: t::options(fresh_converters()) },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh" },
        door_openings: #{ type: "number", series: "counter" },
        door_open_time: #{ type: "number", class: "duration", series: "counter", unit: "s" },
        firmware_1: #{ type: "text", category: "diagnostic", label: "Firmware 1" },
        firmware_2: #{ type: "text", category: "diagnostic", label: "Firmware 2" }
    };
    json_stringify(#{ il: 0, kind: "fridge", label: "Refrigerator", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn start(ctx) {
    ctx.state_set("energy", 0);
    f::query(ctx);
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let s = f::record(data, record_len());
    if s != () { return status(ctx, s); }
    let b = c::inner(data, 0x10);
    if b == () { return; }
    if b[1] == 0xaf && b.len() >= 5 { energy(ctx, b[3] * 256 + b[4]); }
    else if b[1] == 0xc5 && b.len() >= 4 { usage(ctx, b); }
    else if b[1] == 0x31 && b.len() >= 3 { firmware(ctx, b); }
}

fn status(ctx, s) {
    if f::publish(ctx, s) { il::publish_il(ctx, descriptor(ctx)); }
    il::publish_property(ctx, "express_freeze", f::express_freeze(s));
    il::publish_property(ctx, "super_cool", c::on_off(s[16]));
    il::publish_property(ctx, "smart_learner", c::on_off(s[17]));
    il::publish_property(ctx, "vacation", c::on_off(s[12]));
    c::pub_name(ctx, "fresh_converter", t::name(fresh_converters(), s[95]));
}

fn energy(ctx, wh) {
    let total = (ctx.state_get("energy") ?? 0) + wh;
    ctx.state_set("energy", total);
    il::publish_property(ctx, "energy", total.to_string());
}

fn usage(ctx, b) {
    for i in 0..b[3] {
        let o = 4 + i * 6;
        if o + 6 > b.len() { return; }
        let total = (b[o + 4] * 256 + b[o + 5]).to_string();
        if b[o] == 0x01 { il::publish_property(ctx, "door_openings", total); }
        else if b[o] == 0x11 { il::publish_property(ctx, "door_open_time", total); }
    }
}

fn firmware(ctx, b) {
    for i in 0..b[2] {
        let o = 3 + i * 24;
        if o + 24 > b.len() { return; }
        if b[o] != 1 && b[o] != 2 { continue; }
        let version = hex_encode(b.extract(o + 14, 2)) + "." + b[o + 16];
        il::publish_property(ctx, "firmware_" + b[o], version + " (" + b.extract(o + 1, 11).as_string() + ")");
    }
}

fn set_property(ctx, prop, value) {
    let base = if prop.ends_with("_setpoint") { f::with_unit(ctx, f::app(118)) } else { f::app(118) };
    let on = if c::to_bool(value) { 1 } else { 0 };
    switch prop {
        "vacation" => f::write(ctx, base, 12, on),
        "super_cool" => f::write(ctx, base, 16, on),
        "smart_learner" => f::write(ctx, base, 17, on),
        "fresh_converter" => f::write(ctx, base, 95, t::code(fresh_converters(), value)),
        _ => { if !f::set(ctx, base, prop, value) { c::reject(ctx, prop, "unknown or read-only property"); } }
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
