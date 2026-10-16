// Shared by the LG AABB dishwashers: `import "dishwasher_common" as w;`. Port of upstream
// rethink's dishwasher_common.ts. Status records are `<flag> <length> <payload>` in class 0x32
// EB/EC frames, and these payload offsets are common to every model:
//   0 state (states())          1 process (processes())          5 course (per model)
//   3/4 initial, 7/8 remaining, 9/10 delay start time (hours, minutes)
//   11 flags1 (0x02 door)       12 options (0x04 extra dry, 0x08 high temp)
//   13 rinse aid level, 14 salt level, 15 flags2, 16 flags3, 20 downloaded course
// Other bits of the flag and option bytes are model-specific. Models with remote control take
// F0 26 commands; a remote start carries options staged beforehand in target_* properties.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

// The status query LG's cloud sends on connect.
fn query(ctx) {
    ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x11, 0x21, 0x01, 0x00, 0x00, 0x00, 0x18, 0x00]));
}

// The payload of the current `len`-byte record, or `()` unless its length byte is `body_len`.
fn payload(data, len, body_len) {
    let body = c::inner(data, 0x32);
    let o = c::common_status_offset(body, len);
    if o == () || body[o + 1] != body_len { return (); }
    body.extract(o + 2, len - 2)
}

// Not every model uses every code; an unused one is harmless.
fn states() {
    #{ "0": "off", "1": "ready", "2": "running", "3": "paused", "4": "standby", "5": "finished",
       "6": "power_failed" }
}

fn processes() {
    #{ "0": "none", "1": "reserved", "2": "washing", "3": "rinsing", "4": "drying", "5": "finished",
       "6": "night_dry", "7": "cancelled", "99": "cancelled" }
}

fn minutes(p, o) { p[o] * 60 + p[o + 1] }

// False when the initial or remaining time is not a valid hours/minutes pair.
fn sane(p) { p[3] <= 99 && p[4] <= 59 && p[7] <= 99 && p[8] <= 59 }

fn props(courses) {
    #{
        available: #{ type: "binary", role: "available" },
        status: #{ type: "select", options: t::options(states()) },
        process: #{ type: "select", label: "Cycle phase", options: t::options(processes()) },
        course: #{ type: "select", label: "Cycle", options: courses },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        door: #{ type: "binary", class: "door", label: "Door open" }
    }
}

// Publishes availability, state, process, remaining time and door of payload `p`.
fn publish(ctx, p) {
    il::publish_property(ctx, "available", "true");
    c::pub_name(ctx, "status", t::name(states(), p[0]));
    c::pub_name(ctx, "process", t::name(processes(), p[1]));
    il::publish_property(ctx, "remaining_time", minutes(p, 7).to_string());
    il::publish_property(ctx, "door", c::bit(p[11], 0x02));
}

// 0x3E statistics: delta Wh, accumulated Wh, sequence. Returns true when `data` was one.
fn energy(ctx, data) {
    let body = c::inner(data, 0x32);
    if body == () || body[1] != 0x3e || body.len() != 7 { return false; }
    il::publish_property(ctx, "energy", (body[4] * 256 + body[5]).to_string());
    true
}

fn command(ctx, bytes) {
    let msg = [0xf0, 0x26];
    msg += bytes;
    ctx.send_raw(aabb_wrap(msg));
}

// The F0 26 actions. Returns false for any other property.
fn control(ctx, prop) {
    switch prop {
        "cancel" => command(ctx, [0x11]),
        "power_off" => command(ctx, [0x12]),
        "pause" => command(ctx, [0x13]),
        "resume" => command(ctx, [0x14]),
        _ => { return false; }
    }
    true
}

// A staged remote-start option, published as it is set: the appliance does not report it.
fn target(ctx, prop, fallback) {
    let v = ctx.state_get(prop);
    if v == () { fallback } else { v }
}

fn set_target(ctx, prop, value) {
    ctx.state_set(prop, value);
    il::publish_property(ctx, prop, value);
}

// F0 26 10 <course> <delay hours> 00 <opt3> <opt4> 00, the staged course and delay.
fn start_course(ctx, course, opt3, opt4) {
    command(ctx, [0x10, course, target(ctx, "target_delay", "0").parse_int(), 0x00, opt3, opt4, 0x00]);
}

fn opt(ctx, prop, bit) { if target(ctx, prop, "false") == "true" { bit } else { 0 } }

// Descriptor properties of the remote-control models, beyond their own settings and targets.
fn control_props(target_courses) {
    #{
        remote_start: #{ type: "binary", label: "Remote start armed" },
        pause: #{ type: "trigger" },
        resume: #{ type: "trigger" },
        cancel: #{ type: "trigger" },
        start_course: #{ type: "trigger", requires: "remote_start" },
        target_course: #{ type: "select", rw: true, options: target_courses, label: "Course to start" },
        target_delay: #{ type: "number", rw: true, unit: "h", min: 0, max: 12, step: 1, label: "Delay to start" },
        target_high_temp: #{ type: "binary", rw: true, label: "Start with high temp" },
        target_extra_dry: #{ type: "binary", rw: true, label: "Start with extra dry" },
        energy: #{ type: "number", class: "energy", unit: "Wh", series: "counter" }
    }
}
