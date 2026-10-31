// LG refrigerator 2REF11EII__M2 (LMXS28626): port of upstream rethink's 2REF11EII__M2.ts (commit
// 2d8eaba), captured there from a US unit while changing each setting in the LG app. 9-byte status
// records, fridge_common's first nine fields:
//   1/2 fridge / freezer setpoint (codes of this model's own tables, not the family's formula)
//   3 Ice Plus (1 off, 2 on)   4 fresh air filter (2 auto, 3 power, 4 replace; 1 off is reported,
//   not settable)   5 smart grid (0 not in use, 2 seasonal, 3 peak)   6 water filter months since
//   the last reset (replace from 6; above 12 unknown)   7 any door open (1 open)   8 unit (0 °F, 1 °C)
// 10 A8 <compartment> <0 closed, 1 open> reports each compartment (1 fridge, 2 freezer); the status
// record's door flag cannot say which, so it only resets both to closed. 10 AF, 10 AB and 10 72
// frames are not decoded. Writes are F0 17 over a 41-byte prefix of the LG app's record, with the
// unit only for the setpoints. The cloud was not seen to ack this model.
import "aabb_common" as c;
import "fridge_common" as f;
import "table_common" as t;
import "il_common" as il;

// Wire code -> setpoint, from the model JSON.
fn fridge_temps(u) {
    if u == "F" {
        #{ "1": 46, "2": 45, "3": 44, "4": 43, "5": 42, "6": 41, "7": 40, "8": 39, "9": 38, "10": 37,
           "11": 36, "12": 35, "13": 34, "14": 33 }
    } else {
        #{ "1": 8, "3": 7, "5": 6, "7": 5, "9": 4, "10": 3, "12": 2, "14": 1 }
    }
}

fn freezer_temps(u) {
    if u == "F" {
        #{ "1": 8, "2": 6, "3": 5, "4": 4, "5": 3, "6": 2, "7": 1, "8": 0, "9": -1, "10": -2, "11": -3,
           "12": -4, "13": -6 }
    } else {
        #{ "1": -13, "2": -14, "3": -15, "5": -16, "7": -17, "9": -18, "11": -19, "12": -20, "13": -21 }
    }
}

fn fresh_air_modes() { #{ "2": "auto", "3": "power" } }
fn smart_grid_modes() { #{ "0": "not_in_use", "2": "seasonal_energy_saver", "3": "peak_energy_saver" } }

// "F" until a status record says otherwise.
fn unit(ctx) { ctx.state_get("unit") ?? "F" }

fn setpoint(u, table, label) {
    let values = table.values();
    values.sort();
    #{ type: "number", rw: true, class: "temperature", unit: if u == "F" { "°F" } else { "°C" },
       min: values[0], max: values[values.len() - 1], step: 1, label: label }
}

fn descriptor(ctx) {
    let u = unit(ctx);
    json_stringify(#{ il: 0, kind: "fridge", label: "Refrigerator", vendor: "LG",
                      model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        fridge_setpoint: setpoint(u, fridge_temps(u), "Fridge temperature"),
        freezer_setpoint: setpoint(u, freezer_temps(u), "Freezer temperature"),
        express_freeze: #{ type: "binary", rw: true, label: "Ice Plus" },
        fresh_air_filter: #{ type: "select", rw: true, label: "Fresh air filter mode", options: t::options(fresh_air_modes()) },
        fresh_air_filter_replace: #{ type: "binary", class: "problem", category: "diagnostic", label: "Fresh air filter needs replacing" },
        water_filter: #{ type: "binary", class: "problem", category: "diagnostic", label: "Water filter needs replacing" },
        water_filter_months: #{ type: "number", unit: "months", category: "diagnostic", label: "Water filter age" },
        smart_grid: #{ type: "select", rw: true, label: "Smart Grid", options: t::options(smart_grid_modes()) },
        fridge_door: #{ type: "binary", class: "door" },
        freezer_door: #{ type: "binary", class: "door" }
    } })
}

fn start(ctx) { f::query(ctx); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn publish_or_absent(ctx, prop, value) {
    if value == () { il::publish_absent(ctx, prop); } else { il::publish_property(ctx, prop, value.to_string()); }
}

fn on_data(ctx, data) {
    let b = c::inner(data, 0x10);
    if b != () && b[1] == 0xa8 && b.len() == 4 {
        let door = if b[2] == 1 { "fridge_door" } else if b[2] == 2 { "freezer_door" } else { return; };
        il::publish_property(ctx, door, if b[3] == 1 { "true" } else { "false" });
        return;
    }
    let s = f::record(data, 9);
    if s == () { return; }
    let u = if s[8] == 1 { "C" } else { "F" };
    if u != unit(ctx) || ctx.state_get("unit") == () {
        ctx.state_set("unit", u);
        il::publish_il(ctx, descriptor(ctx));
    }
    il::publish_property(ctx, "available", "true");
    publish_or_absent(ctx, "fridge_setpoint", fridge_temps(u)[s[1].to_string()]);
    publish_or_absent(ctx, "freezer_setpoint", freezer_temps(u)[s[2].to_string()]);
    il::publish_property(ctx, "express_freeze", f::express_freeze(s));
    c::pub_name(ctx, "fresh_air_filter", t::name(fresh_air_modes(), s[4]));
    il::publish_property(ctx, "fresh_air_filter_replace", if s[4] == 4 { "true" } else { "false" });
    publish_or_absent(ctx, "smart_grid", t::name(smart_grid_modes(), s[5]));
    let months = s[6];
    publish_or_absent(ctx, "water_filter", if months > 12 { () } else if months >= 6 { "true" } else { "false" });
    publish_or_absent(ctx, "water_filter_months", if months > 12 { () } else { months });
    if s[7] != 1 {
        il::publish_property(ctx, "fridge_door", "false");
        il::publish_property(ctx, "freezer_door", "false");
    }
}

// The wire code for setpoint `v` in `table`, or ().
fn code_of(table, v) {
    for k in table.keys() { if table[k] == v { return k.parse_int(); } }
    ()
}

fn set_property(ctx, prop, value) {
    let u = unit(ctx);
    let base = f::app(41);
    switch prop {
        "fridge_setpoint" | "freezer_setpoint" => {
            let table = if prop == "fridge_setpoint" { fridge_temps(u) } else { freezer_temps(u) };
            let code = code_of(table, c::to_number(value).to_int());
            if code == () { c::reject(ctx, prop, "no " + u + " setting for " + value); return; }
            base[8] = if u == "C" { 1 } else { 0 };
            f::write(ctx, base, if prop == "fridge_setpoint" { 1 } else { 2 }, code);
        }
        "express_freeze" => f::write(ctx, base, 3, if c::to_bool(value) { 2 } else { 1 }),
        "fresh_air_filter" => f::write(ctx, base, 4, t::code(fresh_air_modes(), value)),
        "smart_grid" => f::write(ctx, base, 5, t::code(smart_grid_modes(), value)),
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
