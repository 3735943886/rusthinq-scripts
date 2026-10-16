// LG refrigerator 2REF11EIDG__4 (LRFXC2606S): device -> IL driver. Port of upstream rethink's
// driver (commit 0e57069). 68-byte status records; fridge_common decodes the shared fields
// (express freeze is "Ice Plus" here), plus
//   14 sabbath mode, 17 smart learner (0 off, 1 on)
//   35 fresh air filter, 36 water filter life in percent; writing 100 resets it
// 0x10C5 is a usage report sent every 15 minutes: a sequence byte, a record count, then 6-byte
// records <id> <recent u16> <?> <total u16>. Record 0x21 is water dispensed in mL.
// Every frame is acked as the LG cloud does. Writes go over the LG app's F0 17 record, with the
// unit only for the setpoints.
import "aabb_common" as c;
import "fridge_common" as f;
import "il_common" as il;

fn record_len() { 68 }

fn descriptor(ctx) {
    let props = f::props(f::unit(ctx));
    props += #{
        ice_plus: #{ type: "binary", rw: true, label: "Ice Plus" },
        sabbath_mode: #{ type: "binary", rw: true, label: "Sabbath mode" },
        smart_learner: #{ type: "binary", rw: true, label: "Smart learner" },
        fresh_air_filter: #{ type: "number", unit: "%", category: "diagnostic", label: "Fresh air filter life" },
        water_filter: #{ type: "number", unit: "%", category: "diagnostic", label: "Water filter life" },
        fresh_air_filter_reset: #{ type: "trigger", category: "diagnostic", label: "Reset fresh air filter" },
        water_filter_reset: #{ type: "trigger", category: "diagnostic", label: "Reset water filter" },
        water_dispensed: #{ type: "number", class: "volume", unit: "L", series: "counter",
                            label: "Water dispensed" }
    };
    json_stringify(#{ il: 0, kind: "fridge", label: "Refrigerator", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn start(ctx) { f::query(ctx); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let body = c::inner(data, 0x10);
    if body != () && body[1] == 0xc5 && body.len() >= 4 { return usage(ctx, body); }
    let s = f::record(data, record_len());
    if s == () { return; }
    if f::publish(ctx, s) { il::publish_il(ctx, descriptor(ctx)); }
    il::publish_property(ctx, "ice_plus", f::express_freeze(s));
    il::publish_property(ctx, "sabbath_mode", c::on_off(s[14]));
    il::publish_property(ctx, "smart_learner", c::on_off(s[17]));
    il::publish_property(ctx, "fresh_air_filter", s[35].to_string());
    il::publish_property(ctx, "water_filter", s[36].to_string());
}

fn usage(ctx, body) {
    for i in 0..body[3] {
        let o = 4 + i * 6;
        if o + 6 > body.len() { return; }
        if body[o] == 0x21 {
            il::publish_property(ctx, "water_dispensed", ((body[o + 4] * 256 + body[o + 5]) / 1000.0).to_string());
        }
    }
}

fn set_property(ctx, prop, value) {
    let base = if prop.ends_with("_setpoint") { f::with_unit(ctx, f::app(118)) } else { f::app(118) };
    let on = if c::to_bool(value) { 1 } else { 0 };
    switch prop {
        "ice_plus" => { f::set(ctx, base, "express_freeze", value); }
        "sabbath_mode" => f::write(ctx, base, 14, on),
        "smart_learner" => f::write(ctx, base, 17, on),
        "fresh_air_filter_reset" => f::write(ctx, base, 35, 100),
        "water_filter_reset" => f::write(ctx, base, 36, 100),
        _ => { if !f::set(ctx, base, prop, value) { c::reject(ctx, prop, "unknown or read-only property"); } }
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
