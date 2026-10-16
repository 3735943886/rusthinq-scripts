// LG dishwasher D140110: device -> IL driver. A read-only AABB appliance with the record layout
// of dishwasher_common (26-byte records, a 0x18 payload), reporting only through 0xEC frames.
// Beyond the shared fields: 2 error (error_name()), 11 flags (bit 0 child lock, 2 rinse aid
// refill, 3 salt refill, 4 chime).
//
// Every field below was pinned by two independent readings (the appliance during a full 1:33
// Auto cycle, and the real cloud's decoded snapshot at the same moment). Not published,
// because nothing confirmed them: byte 12 (the option flags, 0 on a cycle that used none),
// byte 15, bytes 16-22, byte 23. The other frames (0xB2, 0x31, 0xD8, 0x72, 0xBF, 0xCF) carry
// nothing 0xEC does not, or nothing that was confirmed.
//
// Read-only: the model describes a control API but no command was ever captured, so the
// encoding is unknown.

import "aabb_common" as c;
import "dishwasher_common" as w;
import "il_common" as il;

fn descriptor(ctx) {
    let props = w::props(["none", "auto", "intensive", "delicate", "turbo", "eco", "rinse",
                          "refresh", "express", "machine_clean", "download_cycle"]);
    props += #{
        error: #{ type: "select", category: "diagnostic", options: ["none", "HE", "IE", "OE", "FE", "TE", "AE", "EE", "LE", "NE", "BE", "F3"] },
        running: #{ type: "binary", class: "running" },
        child_lock: #{ type: "binary" },
        chime: #{ type: "binary", category: "diagnostic" },
        rinse_refill: #{ type: "binary", class: "problem", label: "Rinse aid low" },
        salt_refill: #{ type: "binary", class: "problem", label: "Salt low" },
        total_time: #{ type: "number", class: "duration", unit: "min" },
        reserve_time: #{ type: "number", class: "duration", unit: "min", label: "Delayed start" },
        rinse_aid_level: #{ type: "number", category: "diagnostic" },
        softening_level: #{ type: "number", category: "diagnostic", label: "Water softening level" }
    };
    json_stringify(#{ il: 0, kind: "washer", class: "dishwasher", label: "Dishwasher", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

// The model's Course table, keyed by the id it carries on the wire.
fn course_name(v) {
    switch v {
        0 => "none", 1 => "auto", 2 => "intensive", 3 => "delicate", 4 => "turbo", 5 => "eco",
        6 => "rinse", 7 => "refresh", 8 => "express", 9 => "machine_clean", 11 => "download_cycle",
        _ => ()
    }
}

// The model's error table in its own order. Only "no error" has ever been seen; the rest
// keep LG's two-letter codes, which are what the panel shows.
fn error_name(v) {
    switch v {
        0 => "none", 1 => "HE", 2 => "IE", 3 => "OE", 4 => "FE", 5 => "TE",
        6 => "AE", 7 => "EE", 8 => "LE", 9 => "NE", 10 => "BE", 11 => "F3",
        _ => ()
    }
}

// ---- host hooks -------------------------------------------------------------------

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let body = c::inner(data, 0x32);
    if body == () || body[1] != 0xec { return; }
    let p = w::payload(data, 26, 0x18);
    if p == () { return; }
    w::publish(ctx, p);
    c::pub_name(ctx, "course", course_name(p[5]));
    c::pub_name(ctx, "error", error_name(p[2]));
    il::publish_property(ctx, "running", if p[0] == 2 { "true" } else { "false" });
    il::publish_property(ctx, "child_lock", c::bit(p[11], 0x01));
    il::publish_property(ctx, "rinse_refill", c::bit(p[11], 0x04));
    il::publish_property(ctx, "salt_refill", c::bit(p[11], 0x08));
    il::publish_property(ctx, "chime", c::bit(p[11], 0x10));
    il::publish_property(ctx, "total_time", w::minutes(p, 3).to_string());
    il::publish_property(ctx, "reserve_time", w::minutes(p, 9).to_string());
    il::publish_property(ctx, "rinse_aid_level", p[13].to_string());
    il::publish_property(ctx, "softening_level", p[14].to_string());
}

fn set_property(ctx, prop, value) {
    c::reject(ctx, prop, "read-only appliance");
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
