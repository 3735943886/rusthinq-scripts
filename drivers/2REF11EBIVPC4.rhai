// LG refrigerator 2REF11EBIVPC4 (Israeli market): device -> IL driver. Port of upstream
// rethink's driver (commit 0e57069). 43-byte status records, always Celsius; the appliance
// reports on connect, so there is no query. Offsets:
//   1 fridge setpoint, read as (13 - wire) / 2
//   2 freezer setpoint, read as -(wire + 29) / 2
//   3 express freeze, 7 door, 14 shabbat mode (0 off, 1 on)
// Writes go over the LG app's F0 17 record. As upstream, setpoints are written in the family's
// whole-degree encoding with unit byte 1, although they are read in half degrees.
import "aabb_common" as c;
import "fridge_common" as f;
import "il_common" as il;

fn record_len() { 43 }

fn half(n) { if n % 2 == 0 { (n / 2).to_string() } else { (n / 2.0).to_string() } }

fn descriptor(ctx) {
    let props = f::props("C");
    props += #{
        express_freeze: #{ type: "binary", rw: true, label: "Express freeze" },
        shabbat_mode: #{ type: "binary", rw: true, label: "Shabbat mode" }
    };
    json_stringify(#{ il: 0, kind: "fridge", label: "Refrigerator", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn start(ctx) {}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let s = f::record(data, record_len());
    if s == () { return; }
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "door", c::on_off(s[7]));
    il::publish_property(ctx, "fridge_setpoint", half(13 - s[1]));
    il::publish_property(ctx, "freezer_setpoint", half(-(s[2] + 29)));
    il::publish_property(ctx, "express_freeze", f::express_freeze(s));
    il::publish_property(ctx, "shabbat_mode", c::on_off(s[14]));
}

fn set_property(ctx, prop, value) {
    let base = if prop.ends_with("_setpoint") { f::with_unit(ctx, f::app(118)) } else { f::app(118) };
    if f::set(ctx, base, prop, value) { return; }
    switch prop {
        "shabbat_mode" => f::write(ctx, base, 14, if c::to_bool(value) { 1 } else { 0 }),
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
