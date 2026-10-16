// LG refrigerator 2REFT1DIC4P_U (InstaView craft ice French door): device -> IL driver. Port of
// upstream rethink's driver (commit 0e57069). 68-byte status records; fridge_common decodes
// the shared fields, plus
//   25 craft ice mode (craft_ice())          30 night view, 31 quiet mode (night_modes())
//   34 craft ice maker status (ice_maker())
// Night view and quiet mode are read only: upstream found F0 17 writes to them ignored. Writes
// are a plain 0xFF record without the unit byte, confirmed on a real unit upstream.
import "aabb_common" as c;
import "fridge_common" as f;
import "il_common" as il;

fn record_len() { 68 }

fn craft_ice() { #{ "0": "off", "1": "3_balls", "2": "6_balls" } }
fn ice_maker() { #{ "0": "off", "1": "making_ice", "2": "full", "3": "quiet_mode" } }
fn night_modes() { #{ "0": "off", "1": "every_day", "2": "sunset_to_sunrise", "3": "custom" } }

fn descriptor(ctx) {
    let props = f::props(f::unit(ctx));
    props += #{
        express_freeze: #{ type: "binary", rw: true, label: "Express freeze" },
        craft_ice_mode: #{ type: "select", rw: true, options: c::options(craft_ice()), label: "Craft ice" },
        craft_ice_maker_status: #{ type: "select", options: c::options(ice_maker()), label: "Craft ice maker" },
        night_view: #{ type: "select", options: c::options(night_modes()), label: "Night view" },
        quiet_mode: #{ type: "select", options: c::options(night_modes()), label: "Quiet mode" }
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
    c::pub_name(ctx, "craft_ice_mode", c::name(craft_ice(), s[25]));
    c::pub_name(ctx, "night_view", c::name(night_modes(), s[30]));
    c::pub_name(ctx, "quiet_mode", c::name(night_modes(), s[31]));
    c::pub_name(ctx, "craft_ice_maker_status", c::name(ice_maker(), s[34]));
}

fn set_property(ctx, prop, value) {
    let base = f::ff(record_len());
    if f::set(ctx, base, prop, value) { return; }
    switch prop {
        "craft_ice_mode" => f::write(ctx, base, 25, c::code(craft_ice(), value)),
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
