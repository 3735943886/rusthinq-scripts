// LG dryer RD20_S (건조기, deviceType 202): device -> IL driver. Port of kshexe/rethink's
// RD20_S.ts (https://github.com/kshexe/rethink, commit 8fa8bd4), a fork of upstream rethink
// whose frames were captured against a real unit (2026-09-09..22), each field by toggling one
// control and diffing, and checked against the official lg_thinq integration. An AABB
// appliance, class 0x30, written with the F0 E5 settings write
// `f0 e5 00 02 01 ff <n> [<key> <value>]*n`.
//
// From the appliance:
//   <30> 00 e5 00            write ack: ignored
//   <30> e6 .. (58 bytes)    the echo after a power write: [33] nonzero = on
//   <30> 7f <course>         course id: 3 normal, 4 AI course (confirmed against a real cycle)
//   <30> 72 00 <code>        0 drying_is_complete (event); 0xc9 / 0xc8 remote control on / off
//   status, 114 bytes: <30> 0a <len16> <seq16> e5 00 01 00 ec 00 64, then two 50-byte
//     records, previous and current. Of the current record:
//     [7..8]  reservation, minutes (BE)          [10] remaining minutes
//     [18]    energy counter byte, Wh            [19] buzzer volume (only while not running)
//     [24]    0x08 wrinkle care, 0x20 drum light on, 0x40 ironing alert
//     [26]    state: 0x41 running, 0x61 cooling, 0x01 complete, 0x00 off; 0x10 button lock
//     [41]    0x08 drum light auto-on setting (one on-transition captured)
//   The fork ignores the EB record its connect query elicits (a byte there it tried for power
//   did not track it); so does this driver, though it sends the same query.
//
// Energy: the counter byte steps by the Wh used. The cycle total starts at the first byte this
// session sees, adds each step of 1..50 Wh and restarts from the byte after a larger jump (a new
// cycle), as in the fork; it therefore covers this session only. The fork's hour/day/month
// totals, kept on disk by calendar, are not ported.
//
// Writes: power key 0x02, drum light auto-on key 0x1b (on captured, off assumed by the fork).
// Divergences from the fork: nothing is published from a write (the fork is optimistic; the
// echo and the status record read both back); power off clears remaining_time instead of
// publishing 0, and nothing is published on connect. A state, course or buzzer code with no
// name is absent instead of the fork's `unknown_<n>` / `#<n>`.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn states() { #{ "0": "off", "1": "complete", "65": "running", "97": "cooling" } }
fn courses() { #{ "3": "normal", "4": "ai_course" } }
fn volumes() { #{ "0": "mute", "1": "low", "2": "medium", "3": "high", "4": "very_high" } }
fn notifications() { #{ "0": "drying_is_complete" } }

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "dryer", class: "dryer", label: "Dryer", vendor: "LG",
                      model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", role: "on", rw: true, label: "Power" },
        status: #{ type: "select", options: t::options(states()), label: "State" },
        course: #{ type: "select", options: t::options(courses()), label: "Course" },
        remaining_time: #{ type: "number", class: "duration", unit: "min", label: "Remaining time" },
        reserve_time: #{ type: "number", class: "duration", unit: "min", category: "diagnostic", label: "Reservation" },
        remote_control: #{ type: "binary", label: "Remote control" },
        child_lock: #{ type: "binary", label: "Button lock" },
        drum_light: #{ type: "binary", label: "Drum light" },
        drum_light_auto: #{ type: "binary", rw: true, category: "config", label: "Drum light on door open" },
        wrinkle_care: #{ type: "binary", label: "Wrinkle care" },
        ironing_alert: #{ type: "binary", label: "Ironing alert" },
        buzzer: #{ type: "select", options: t::options(volumes()), category: "diagnostic", label: "Buzzer volume" },
        notification: #{ type: "text", category: "diagnostic", label: "Notification" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Cycle energy (this session)" }
    } })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn start(ctx) {
    ctx.send_raw(aabb_wrap(hex_decode("f0ed1211010000010400")));
}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn publish_enum(ctx, prop, table, raw) {
    let name = t::name(table, raw);
    if name == () { il::publish_absent(ctx, prop); } else { il::publish_property(ctx, prop, name); }
}

fn is_status(b) {
    b.len() == 114 && b[1] == 0x0a && b[7] == 0x00 && b[8] == 0x01 && b[9] == 0x00 && b[10] == 0xec
}

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let b = c::inner(data, 0x30);
    if b == () { return; }
    if is_status(b) { record(ctx, b.extract(63, 50)); return; }
    if b.len() == 3 && b[1] == 0x7f { publish_enum(ctx, "course", courses(), b[2]); return; }
    if b[1] == 0x72 {
        if b.len() > 3 && b[2] == 0 {
            let code = b[3];
            if code == 0xc9 || code == 0xc8 {
                il::publish_property(ctx, "remote_control", if code == 0xc9 { "true" } else { "false" });
            } else {
                let name = t::name(notifications(), code);
                if name != () { il::publish_event(ctx, "notification", json_stringify(#{ event_type: name })); }
            }
        }
        return;
    }
    if b[1] == 0xe6 && b.len() == 58 {
        let on = b[33] != 0;
        il::publish_property(ctx, "power", if on { "true" } else { "false" });
        if !on { il::publish_absent(ctx, "remaining_time"); }
    }
}

fn record(ctx, r) {
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "remaining_time", r[10].to_string());
    let state = r[26];
    publish_enum(ctx, "status", states(), state);
    energy(ctx, r[18].to_int());
    // The volume byte means something else mid-cycle: read only outside the named states.
    if t::name(states(), state) == () { publish_enum(ctx, "buzzer", volumes(), r[19]); }
    il::publish_property(ctx, "drum_light", c::bit(r[24], 0x20));
    il::publish_property(ctx, "wrinkle_care", c::bit(r[24], 0x08));
    il::publish_property(ctx, "ironing_alert", c::bit(r[24], 0x40));
    il::publish_property(ctx, "drum_light_auto", c::bit(r[41], 0x08));
    il::publish_property(ctx, "child_lock", c::bit(state, 0x10));
    il::publish_property(ctx, "reserve_time", (r[7] * 256 + r[8]).to_string());
}

fn energy(ctx, raw) {
    let last = ctx.state_get("energy_raw");
    let cycle = ctx.state_get("energy_cycle");
    if last == () {
        cycle = raw;
    } else {
        let delta = (raw - last + 256) % 256;
        if delta > 50 {
            cycle = raw;
        } else {
            cycle += delta;
        }
    }
    ctx.state_set("energy_raw", raw);
    ctx.state_set("energy_cycle", cycle);
    il::publish_property(ctx, "energy", cycle.to_string());
}

fn settings_write(ctx, key, value) {
    ctx.send_raw(aabb_wrap([0xf0, 0xe5, 0x00, 0x02, 0x01, 0xff, 0x01, key, value]));
}

fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value == () { return; }
    switch prop {
        "power" => settings_write(ctx, 0x02, if c::to_bool(value) { 1 } else { 0 }),
        "drum_light_auto" => settings_write(ctx, 0x1b, if c::to_bool(value) { 1 } else { 0 }),
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}
