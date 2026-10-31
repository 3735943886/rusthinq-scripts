// LG refrigerator 2RES1VE600FWC (GSB470BASZ) and its alias 2RES1VE61NFWA (GSX961MCCZ). Port of
// upstream rethink's 2RES1VE600FWC.ts (commit 0e57069). 12-byte status records; fridge_common decodes the door and unit.
// The setpoints have their own encoding and ranges here (wire values):
//   fridge   °C 8 - wire (1..7); °F 47 - wire (33..46)
//   freezer  °C -13 - wire (-24..-14); °F wire 1..15 index freezer_f(), the uneven steps the
//            LG app offers, and a written value falls to the step at or below it
import "aabb_common" as c;
import "fridge_common" as f;
import "il_common" as il;

fn record_len() { 12 }

fn freezer_f() { [7, 7, 6, 5, 4, 3, 2, 1, 0, -1, -2, -3, -7, -12, -15, -17] }

fn fridge_temp(u, x) { (if u == "F" { 47 } else { 8 }) - x }

fn freezer_from(u, x) {
    if u != "F" { return -13 - x; }
    if x < 16 { freezer_f()[x] } else { () }
}

fn freezer_to(u, t) {
    if u != "F" { return -13 - t; }
    if t < -15 { 15 } else if t < -12 { 14 } else if t < -7 { 13 } else if t < -3 { 12 } else { 8 - t }
}

fn descriptor(ctx) {
    let u = f::unit(ctx);
    let props = f::props(u);
    props += #{
        fridge_setpoint: f::setpoint(u, 1, 7, 33, 46, "Fridge temperature"),
        freezer_setpoint: f::setpoint(u, -24, -14, -17, 7, "Freezer temperature"),
        express_freeze: #{ type: "binary", rw: true, label: "Express freeze" }
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
    if f::publish_base(ctx, s) { il::publish_il(ctx, descriptor(ctx)); }
    let u = f::unit(ctx);
    il::publish_property(ctx, "fridge_setpoint", fridge_temp(u, s[1]).to_string());
    let freezer = freezer_from(u, s[2]);
    if freezer != () { il::publish_property(ctx, "freezer_setpoint", freezer.to_string()); }
    il::publish_property(ctx, "express_freeze", f::express_freeze(s));
}

fn set_property(ctx, prop, value) {
    let base = f::with_unit(ctx, f::ff(record_len()));
    let u = f::unit(ctx);
    switch prop {
        "fridge_setpoint" => f::write(ctx, base, 1, fridge_temp(u, c::to_number(value).to_int())),
        "freezer_setpoint" => f::write(ctx, base, 2, freezer_to(u, c::to_number(value).to_int())),
        _ => { if !f::set(ctx, base, prop, value) { c::reject(ctx, prop, "unknown or read-only property"); } }
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
