// LG refrigerator 2REF11EIDA__4: device -> IL driver. Port of upstream rethink's driver
// (commit 0e57069). 68-byte status records; fridge_common decodes the shared fields, plus
//   13 convertible drawer mode (flex())
// Writes go over the first 99 bytes of the LG app's F0 17 record, with the unit.
import "aabb_common" as c;
import "fridge_common" as f;
import "il_common" as il;

fn record_len() { 68 }

fn flex() {
    #{ "1": "chilled_wine", "2": "deli_snacks", "3": "cold_drink", "4": "meat_seafood", "5": "freezer" }
}

fn descriptor(ctx) {
    let props = f::props(f::unit(ctx));
    props += #{
        flex_setpoint: #{ type: "select", rw: true, options: c::options(flex()), label: "Convertible drawer" }
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
    c::pub_name(ctx, "flex_setpoint", c::name(flex(), s[13]));
}

fn set_property(ctx, prop, value) {
    let base = f::with_unit(ctx, f::app(99));
    if f::set(ctx, base, prop, value) { return; }
    switch prop {
        "flex_setpoint" => f::write(ctx, base, 13, c::code(flex(), value)),
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
