// LG refrigerator 2REF21EBNSX_3 (냉장고): device -> IL driver. Port of kshexe/rethink's
// 2REF21EBNSX_3.ts (https://github.com/kshexe/rethink, commit 8fa8bd4), a fork of upstream
// rethink whose frames were captured against a real unit (2026-09-09..10-06), each control swept
// through its range in the app and diffed. An AABB appliance of the fridge_common family
// (class 0x10, EB / EC 18-byte records, F0 17 writes over the LG app's record).
//
// Record: [1] fridge setpoint, raw = °C (1, 4, 7 captured; NOT fridge_common's 8 - x, which this
//   model's own captures contradict), [2] freezer setpoint, raw = -14 - °C (fridge_common's),
//   [3] express mode (1 off, 2 on; the unit has one tier), [7] any door open (1 open; 0 and 2
//   closed), [17] Smart Care+ master switch.
// Other frames:
//   a8 <compartment> <state>   door event: 1 fridge, 2 freezer section (two doors each, one
//                              signal per section; four isolated captures); 1 open
//   18 01 <temp> <hum16>       ambient °C and humidity in 0.1 % (~15 min; checked against a
//                              room sensor)
//   af <?> <counter16> 04 04   a counter that rises 1 per Wh (checked against the app's daily
//                              total) and resets at no fixed time: `energy`. The fork's
//                              hour/day/month totals, kept on disk by calendar, are not ported
//                              (a consumer's utility meter)
//   00 17 00 ack, cf (250-byte dump): ignored
// The section doors come only from door events; a record with [7] closed sets both closed.
//
// Writes, captured: F0 17 + the app's 41-byte record with one field set: [1] fridge, [2] freezer
// (each with [8] = 1, the unit byte fridge_common adds), [3] express mode, [17] Smart Care+;
// turning Smart Care+ off is two writes, [17] = 0 then [4] = 6, as the app sends them.
// Divergences from the fork: nothing is published from a write (the fork is optimistic; the EC
// push follows each write), and an out-of-range setpoint is refused rather than clamped.
import "aabb_common" as c;
import "fridge_common" as f;
import "il_common" as il;

fn rec_len() { 18 }
fn write_len() { 41 }

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        fridge_setpoint: f::setpoint("C", 1, 7, 33, 43, "Fridge temperature"),
        freezer_setpoint: f::setpoint("C", -23, -15, -7, 5, "Freezer temperature"),
        express_mode: #{ type: "binary", rw: true, label: "Express freeze" },
        smart_care: #{ type: "binary", rw: true, label: "Smart Care+" },
        fridge_door: #{ type: "binary", class: "door", label: "Fridge door open" },
        freezer_door: #{ type: "binary", class: "door", label: "Freezer door open" },
        ambient_temperature: #{ type: "number", class: "temperature", unit: "°C", label: "Ambient temperature" },
        ambient_humidity: #{ type: "number", class: "humidity", unit: "%", label: "Ambient humidity" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Energy" }
    };
    json_stringify(#{ il: 0, kind: "fridge", label: "Refrigerator", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn start(ctx) {
    f::query(ctx);
}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let s = f::record(data, rec_len());
    if s != () { return record(ctx, s); }
    let b = c::inner(data, 0x10);
    if b == () { return; }
    if b.len() == 4 && b[1] == 0xa8 {
        let open = if b[3] == 1 { "true" } else { "false" };
        if b[2] == 1 { il::publish_property(ctx, "fridge_door", open); }
        else if b[2] == 2 { il::publish_property(ctx, "freezer_door", open); }
        return;
    }
    if b.len() == 6 && b[1] == 0x18 {
        il::publish_property(ctx, "ambient_temperature", b[3].to_string());
        il::publish_property(ctx, "ambient_humidity", ((b[4] * 256 + b[5]) / 10.0).to_string());
        return;
    }
    if b.len() == 7 && b[1] == 0xaf { il::publish_property(ctx, "energy", (b[3] * 256 + b[4]).to_string()); }
}

fn record(ctx, s) {
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "fridge_setpoint", s[1].to_string());
    il::publish_property(ctx, "freezer_setpoint", f::freezer_temp("C", s[2]).to_string());
    il::publish_property(ctx, "express_mode", f::express_freeze(s));
    il::publish_property(ctx, "smart_care", c::on_off(s[17]));
    if s[7] != 1 {
        il::publish_property(ctx, "fridge_door", "false");
        il::publish_property(ctx, "freezer_door", "false");
    }
}

fn write(ctx, offset, value, unit) {
    let r = f::app(write_len());
    r[offset] = value;
    if unit { r = f::with_unit(ctx, r); }
    f::send(ctx, r);
}

fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value == () { return; }
    switch prop {
        "fridge_setpoint" => write(ctx, 1, c::to_number(value).to_int(), true),
        "freezer_setpoint" => write(ctx, 2, f::freezer_temp("C", c::to_number(value).to_int()), true),
        "express_mode" => write(ctx, 3, if c::to_bool(value) { 2 } else { 1 }, false),
        "smart_care" => {
            let on = c::to_bool(value);
            write(ctx, 17, if on { 1 } else { 0 }, false);
            if !on { write(ctx, 4, 6, false); }
        }
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}
