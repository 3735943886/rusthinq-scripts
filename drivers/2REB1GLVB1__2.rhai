// LG refrigerator 2REB1GLVB1__2: device -> IL driver. Port of upstream rethink's driver
// (commit 0e57069). 17-byte status records; fridge_common decodes the shared fields, plus
//   12 eco friendly (0 off, 1 on)
//   16 express cool (0 off, 1 on)
// Eco friendly is written as the LG app sends it, captured through the rethink bridge: the
// first 41 bytes of the app's record, without a unit byte.
import "aabb_common" as c;
import "fridge_common" as f;
import "il_common" as il;

fn record_len() { 17 }

fn descriptor(ctx) {
    let props = f::props(f::unit(ctx));
    props += #{
        express_freeze: #{ type: "binary", rw: true, label: "Express freeze" },
        express_cool: #{ type: "binary", rw: true, label: "Express cool" },
        eco_friendly: #{ type: "binary", rw: true, label: "Eco friendly" }
    };
    json_stringify(#{ il: 0, kind: "fridge", label: "Refrigerator", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn start(ctx) { f::query(ctx); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let s = f::record(data, record_len());
    if s == () { return; }
    if f::publish(ctx, s) { il::publish_il(ctx, descriptor(ctx)); }
    il::publish_property(ctx, "express_freeze", f::express_freeze(s));
    il::publish_property(ctx, "eco_friendly", c::on_off(s[12]));
    il::publish_property(ctx, "express_cool", c::on_off(s[16]));
}

fn set_property(ctx, prop, value) {
    let base = f::with_unit(ctx, f::ff(record_len()));
    if f::set(ctx, base, prop, value) { return; }
    let on = if c::to_bool(value) { 1 } else { 0 };
    switch prop {
        "express_cool" => f::write(ctx, base, 16, on),
        "eco_friendly" => f::write(ctx, f::app(41), 12, on),
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
