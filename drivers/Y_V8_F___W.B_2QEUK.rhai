// LG washer-dryer Y_V8_F___W.B_2QEUK (W4WR70E61): device -> IL driver. Port of upstream
// rethink's driver (commit 0e57069). Status is the 39-byte record of Y_V8_Y___W.B32QEUK in the
// same envelope, read at upstream's offsets for this model: 13 drying mode, remote start in
// bit 0x40 of 17 and the door lock in bit 0x40 of 21 (where Y_V8_Y has its 0x02 and 0x40 of 17;
// upstream established these on this model's own frames). A separate 79-byte frame with 0x02
// at 8 carries the wash counter at 19. Commands as washer_common.
import "aabb_common" as c;
import "table_common" as t;
import "washer_common" as w;
import "il_common" as il;

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer-dryer", vendor: "LG",
                      model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", rw: true, class: "running", label: "Powered on" },
        start: #{ type: "trigger", requires: "remote_start" },
        pause: #{ type: "trigger" },
        status: #{ type: "select", options: t::options(w::states()) },
        error: #{ type: "binary", class: "problem", category: "diagnostic" },
        error_message: #{ type: "text", category: "diagnostic" },
        course: #{ type: "select", options: t::options(w::courses()) },
        spin: #{ type: "select", options: t::options(w::spins()) },
        temp: #{ type: "select", label: "Water temperature", options: t::options(w::temps()) },
        drying_mode: #{ type: "select", options: t::options(w::drying_modes()) },
        cycles: #{ type: "number", series: "counter", category: "diagnostic", label: "Cycle count" },
        remote_start: #{ type: "binary", category: "diagnostic", label: "Remote start armed at the panel" },
        door_lock: #{ type: "binary", category: "diagnostic" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Cycle energy" },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle length" },
        remaining_time: #{ type: "number", class: "duration", unit: "min" }
    } })
}

fn start(ctx) { w::start(ctx); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let b = c::inner(data, 0x20);
    if b != () && b.len() == 79 && b[8] == 0x02 {
        il::publish_property(ctx, "cycles", b[19].to_string());
        return;
    }
    let s = c::enveloped_status(data, 0x20, 39);
    if s == () { return; }
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if s[2] > 0 { "true" } else { "false" });
    c::pub_name(ctx, "status", t::name(w::states(), s[2]));
    il::publish_property(ctx, "error", if s[8] != 0 { "true" } else { "false" });
    il::publish_property(ctx, "error_message", t::name(w::errors(), s[8]) ?? "Unknown error (" + s[8] + ")");
    c::pub_name(ctx, "course", t::name(w::courses(), s[7]));
    c::pub_name(ctx, "spin", t::name(w::spins(), s[10]));
    c::pub_name(ctx, "temp", t::name(w::temps(), s[11]));
    c::pub_name(ctx, "drying_mode", t::name(w::drying_modes(), s[13]));
    il::publish_property(ctx, "remote_start", c::bit(s[17], 0x40));
    il::publish_property(ctx, "door_lock", c::bit(s[21], 0x40));
    il::publish_property(ctx, "initial_time", (s[5] * 60 + s[6]).to_string());
    il::publish_property(ctx, "remaining_time", (s[3] * 60 + s[4]).to_string());
    il::publish_property(ctx, "energy", (s[30] * 256 + s[31]).to_string());
}

fn set_property(ctx, prop, value) { w::set_property(ctx, prop, value); }

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
