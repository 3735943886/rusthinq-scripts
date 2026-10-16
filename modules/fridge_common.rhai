// Shared by the LG AABB refrigerators: `import "fridge_common" as f;`. Port of upstream
// rethink's fridge_common.ts. Status records arrive as class 0x10 EB/EC frames, and these
// offsets are common to the family (records are shorter on lower-end models):
//   1 fridge setpoint, 2 freezer setpoint (wire values, see fridge_temp/freezer_temp)
//   3 express freeze (1 off, 2 on)
//   7 any door open (1 open; 0 and 2 both closed)
//   8 display unit (0 °F, 1 °C)
// Writes are F0 17 plus a record, 0xFF ("leave unchanged") except the unit and one field.
import "aabb_common" as c;
import "il_common" as il;

// The status query the LG app sends on connect.
fn query(ctx) {
    ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x12, 0x11, 0x01, 0x00, 0x00, 0x01, 0x04, 0x00]));
}

// The current `len`-byte record of a status frame, or `()`.
fn record(data, len) {
    let body = c::inner(data, 0x10);
    let o = c::common_status_offset(body, len);
    if o == () { () } else { body.extract(o, len) }
}

// "C" until a status record says otherwise.
fn unit(ctx) {
    let u = ctx.state_get("unit");
    if u == () { "C" } else { u }
}

// Wire <-> setpoint; the same formula works both ways.
fn fridge_temp(u, x) { (if u == "F" { 44 } else { 8 }) - x }
fn freezer_temp(u, x) { (if u == "F" { 6 } else { -14 }) - x }

fn setpoint(u, min_c, max_c, min_f, max_f, label) {
    let f = u == "F";
    #{ type: "number", rw: true, class: "temperature", unit: if f { "°F" } else { "°C" },
       min: if f { min_f } else { min_c }, max: if f { max_f } else { max_c }, step: 1, label: label }
}

// Descriptor properties every model has; a driver adds its own to this map.
fn props(u) {
    #{
        available: #{ type: "binary", role: "available" },
        fridge_setpoint: setpoint(u, 1, 7, 33, 43, "Fridge temperature"),
        freezer_setpoint: setpoint(u, -23, -15, -7, 5, "Freezer temperature"),
        door: #{ type: "binary", class: "door" }
    }
}

// Publishes the shared fields of record `s`. Returns true when the unit changed, so the
// driver must republish its descriptor.
fn publish(ctx, s) {
    let u = if s[8] == 1 { "C" } else { "F" };
    let changed = u != unit(ctx);
    if changed { ctx.state_set("unit", u); }
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "fridge_setpoint", fridge_temp(u, s[1]).to_string());
    il::publish_property(ctx, "freezer_setpoint", freezer_temp(u, s[2]).to_string());
    il::publish_property(ctx, "door", c::on_off(s[7]));
    changed
}

// Sends F0 17 + `record` as is. Nothing is published: the appliance's next status record
// carries the result.
fn send(ctx, record) {
    let msg = blob(2);
    msg[0] = 0xf0;
    msg[1] = 0x17;
    msg += record;
    ctx.send_raw(aabb_wrap(msg));
}

// Sends `base` (a record blob) with the current unit and `value` at `offset`.
fn write_record(ctx, base, offset, value) {
    base[8] = if unit(ctx) == "F" { 0 } else { 1 };
    base[offset] = value;
    send(ctx, base);
}

fn write(ctx, len, offset, value) { write_record(ctx, blob(len, 0xff), offset, value); }

// Handles the setpoints and express freeze, writing over `base`. Returns false for any
// other property.
fn set_on(ctx, base, prop, value) {
    let u = unit(ctx);
    switch prop {
        "fridge_setpoint" => write_record(ctx, base, 1, fridge_temp(u, c::to_number(value).to_int())),
        "freezer_setpoint" => write_record(ctx, base, 2, freezer_temp(u, c::to_number(value).to_int())),
        "express_freeze" => write_record(ctx, base, 3, if c::to_bool(value) { 2 } else { 1 }),
        _ => { return false; }
    }
    true
}

fn set(ctx, len, prop, value) { set_on(ctx, blob(len, 0xff), prop, value) }
