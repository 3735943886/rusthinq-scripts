// LG refrigerator 2REFTBDII4P_U: device -> IL driver. Port of upstream rethink's driver
// (commit 0e57069). 68-byte status records; fridge_common decodes the shared fields, plus
//   4 fresh air filter (air_filter())     6 water filter age in months (water_filter())
//   27 fridge, 28 freezer temperature status (temperature_status())
//   32 ice maker (ice_maker())
// Writes go over the LG app's F0 17 record, with the unit only for the setpoints.
import "aabb_common" as c;
import "fridge_common" as f;
import "il_common" as il;

fn record_len() { 68 }

fn air_filter() { #{ "0": "good", "1": "good", "2": "good", "3": "replace", "4": "good", "5": "good", "6": "good" } }
fn water_filter() {
    let t = #{};
    for m in 0..13 { t[m.to_string()] = if m < 6 { "good" } else { "replace" }; }
    t
}
fn temperature_status() {
    #{ "0": "off", "1": "well_maintained", "2": "very_high", "3": "high", "4": "low",
       "5": "stabilizing", "14": "sensor_error", "15": "uncertain" }
}
fn ice_maker() { #{ "0": "off", "1": "making_ice", "2": "full", "3": "quiet_mode" } }

fn descriptor(ctx) {
    let props = f::props(f::unit(ctx));
    let status = c::options(temperature_status());
    props += #{
        express_freeze: #{ type: "binary", rw: true, label: "Express freeze" },
        fridge_temperature_status: #{ type: "select", options: status, category: "diagnostic",
                                      label: "Fridge temperature status" },
        freezer_temperature_status: #{ type: "select", options: status, category: "diagnostic",
                                       label: "Freezer temperature status" },
        ice_maker_status: #{ type: "select", options: c::options(ice_maker()), label: "Ice maker" },
        fresh_air_filter_status: #{ type: "select", options: c::options(air_filter()),
                                    category: "diagnostic", label: "Fresh air filter" },
        water_filter_status: #{ type: "select", options: c::options(water_filter()),
                                category: "diagnostic", label: "Water filter" },
        water_filter_months: #{ type: "number", unit: "months", category: "diagnostic",
                                label: "Water filter age" }
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
    c::pub_name(ctx, "fresh_air_filter_status", c::name(air_filter(), s[4]));
    c::pub_name(ctx, "water_filter_status", c::name(water_filter(), s[6]));
    if s[6] <= 12 { il::publish_property(ctx, "water_filter_months", s[6].to_string()); }
    c::pub_name(ctx, "fridge_temperature_status", c::name(temperature_status(), s[27]));
    c::pub_name(ctx, "freezer_temperature_status", c::name(temperature_status(), s[28]));
    c::pub_name(ctx, "ice_maker_status", c::name(ice_maker(), s[32]));
}

fn set_property(ctx, prop, value) {
    let base = if prop.ends_with("_setpoint") { f::with_unit(ctx, f::app(118)) } else { f::app(118) };
    if !f::set(ctx, base, prop, value) { c::reject(ctx, prop, "unknown or read-only property"); }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
