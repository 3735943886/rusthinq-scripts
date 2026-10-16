// The "monitoring record" flavour of the AABB protocol, shared by the Korean washer / dryer /
// styler family (F24VDD, RH14_N_KR, Pd0F_F, S3BF_POD_DN4): `import "monitoring_common" as m;`.
//
// The appliance reports its whole state as one fixed-length payload in a record header:
//
//   0xEC  [dev][EC] [00][len][payload: previous state] [00][len][payload: current state]
//   0xEB  [dev][EB] [00][len][payload: current state]      right after (re)connecting
//   0xE2  [dev][E2] [03][len][payload: current state]      sent when a cycle begins
//
// and takes commands as
//
//   f0 24 <type> 01 00      short control: type 1 = power off, type 4 = pause
//   f0 26 <payload>         start a course, or resume a paused one (same frame, initial bit cleared)
//
// answered about a second later with a four-byte frame `[dev] 00 <command> <status>`, status 0
// taken and 0xff refused. A zero says the frame arrived and was well formed, not that the
// appliance understood it. The appliance obeys none of this unless "remote start" is armed on
// its own panel.

import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn control_power_off() { 0x01 }
fn control_pause() { 0x04 }

// The offset of the current record's payload in the inner body, or `()` when `data` is not a
// record of this device. Both header bytes are checked, so a model whose payload length
// changes under a firmware update reports nothing rather than fields read off wrong offsets.
// Returns `#{ body, p }`: read a field as `body[p + OFFSET]`.
fn record(data, dev, payload_len) {
    let body = c::inner(data, dev);
    if body == () { return (); }

    let record_len = payload_len + 2;
    let start = 0;
    let header = 0x00;
    if body[1] == 0xec {
        if body.len() != 2 + 2 * record_len { return (); }
        start = 2 + record_len;
    } else if body[1] == 0xeb || body[1] == 0xe2 {
        if body.len() != 2 + record_len { return (); }
        start = 2;
        if body[1] == 0xe2 { header = 0x03; }
    } else {
        return ();
    }
    if body[start] != header || body[start + 1] != payload_len { return (); }
    #{ body: body, p: start + 2 }
}

// `#{ command, refused }` if `data` is an acknowledgement from this device, else `()`.
fn ack(data, dev) {
    let body = c::inner(data, dev);
    if body == () || body.len() != 4 || body[1] != 0x00 { return (); }
    #{ command: body[2], refused: body[3] != 0 }
}

// Report a refusal against the property whose command it answers. An accepted command
// publishes nothing: the appliance changes state, or it does not, and the record says which.
fn on_ack(ctx, ack) {
    if ack.refused {
        let prop = ctx.state_get("last_cmd");
        c::reject(ctx, if prop == () { "command" } else { prop }, "refused by the appliance");
    }
}

// ---- what every model shares ------------------------------------------------------
//
// Payload offsets common to the family: 0 state (0 = off), 1/2 remaining, 3/4 initial and
// 12/13 reserve time (hours, minutes), 5 course on the dial, 6 error code. Each driver decodes
// the rest, including where its remote-start bit lives.

// Descriptor properties every model has; the driver mixes in its own.
fn props(states, courses, startable) {
    let startable_names = [];
    for v in startable { startable_names.push(t::name(courses, v)); }
    #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", class: "running", label: "Powered on" },
        status: #{ type: "select", options: t::options(states) },
        // "course" is where the dial sits; "course_select" is what Start will ask for. They
        // agree until one is changed here, and turning the dial brings them back together.
        course: #{ type: "select", label: "Course (dial)", options: t::options(courses) },
        course_select: #{ type: "select", rw: true, label: "Course for Start",
                          options: startable_names },
        start: #{ type: "trigger", requires: "remote_start" },
        pause: #{ type: "trigger", requires: "remote_start" },
        power_off: #{ type: "trigger", requires: "remote_start" },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        initial_time: #{ type: "number", class: "duration", category: "diagnostic", unit: "min", label: "Cycle length" },
        reserve_time: #{ type: "number", class: "duration", unit: "min", label: "Reserved finish time" },
        error: #{ type: "binary", class: "problem", category: "diagnostic" },
        error_message: #{ type: "text", category: "diagnostic" },
        remote_start: #{ type: "binary", category: "diagnostic", label: "Remote start armed at the panel" }
    }
}

fn minutes(b, o) { (b[o] * 60 + b[o + 1]).to_string() }

// Publishes the shared fields of record `r` and remembers its state for a later Start.
fn publish(ctx, r, states, courses, startable, errors) {
    let b = r.body;
    let p = r.p;
    il::publish_property(ctx, "available", "true");
    let state = b[p];
    let off = state == 0;
    ctx.state_set("state", state);

    let chosen = follow(ctx, b[p + 5], startable);
    if chosen != () { il::publish_property(ctx, "course_select", t::name(courses, chosen)); }

    il::publish_property(ctx, "power", if off { "false" } else { "true" });
    c::pub_name(ctx, "status", t::name(states, state));
    c::pub_name(ctx, "course", t::name(courses, b[p + 5]));

    // Zeroed while off: the appliance keeps the last cycle's figures in these bytes, which would
    // otherwise read as a countdown frozen mid-cycle.
    il::publish_property(ctx, "remaining_time", if off { "0" } else { minutes(b, p + 1) });
    il::publish_property(ctx, "initial_time", if off { "0" } else { minutes(b, p + 3) });
    il::publish_property(ctx, "reserve_time", if off { "0" } else { minutes(b, p + 12) });

    let error = b[p + 6];
    il::publish_property(ctx, "error", if error != 0 { "true" } else { "false" });
    il::publish_property(ctx, "error_message", t::name(errors, error) ?? "Unknown error (" + error + ")");
}

// Handles course_select, pause and power_off; false for any other property. `what` names the
// appliance in a rejection ("washer").
fn control(ctx, prop, value, courses, startable, what) {
    switch prop {
        "course_select" => {
            let code = t::code(courses, value);
            if code == () || !select(ctx, code, startable) {
                c::reject(ctx, prop, "not a course this " + what + " can start");
            } else {
                il::publish_property(ctx, "course_select", value);
            }
        }
        "pause" => short_control(ctx, control_pause(), prop),
        "power_off" => short_control(ctx, control_power_off(), prop),
        _ => { return false; }
    }
    true
}

fn short_control(ctx, kind, prop) {
    ctx.state_set("last_cmd", prop);
    ctx.send_raw(aabb_wrap([0xf0, 0x24, kind, 0x01, 0x00]));
}

fn course_control(ctx, payload, prop) {
    ctx.state_set("last_cmd", prop);
    let inner = [0xf0, 0x26];
    for b in payload { inner.push(b); }
    ctx.send_raw(aabb_wrap(inner));
}

// ---- the course a Start will ask for -----------------------------------------------
//
// The appliance has no notion of a pending course: its record reports where the dial sits,
// and that only moves when someone turns it. A start command has to name one anyway, so the
// driver keeps a selection of its own, seeded from the appliance and changed by a write.
// It FOLLOWS the dial rather than mirroring it (mirroring would undo a chosen course at the
// next report, which repeats the same dial position): it changes when the appliance's own
// course changes. It only ever holds a course the driver can start, and power-off (which
// zeroes the course byte) is ignored by the same rule, so the choice survives a power cycle.

// Returns the new selection if `course` changed it, else `()`.
fn follow(ctx, course, startable) {
    if ctx.state_get("reported") == course { return (); }
    ctx.state_set("reported", course);
    if startable.contains(course) {
        ctx.state_set("selected", course);
        return course;
    }
    ()
}

fn select(ctx, code, startable) {
    if startable.contains(code) { ctx.state_set("selected", code); return true; }
    false
}

fn selected(ctx) {
    let s = ctx.state_get("selected");
    if s == () { 0 } else { s }
}
