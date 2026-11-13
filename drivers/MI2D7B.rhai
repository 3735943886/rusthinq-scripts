// LG MiniWash MI2D7B (미니워시, deviceType 201): device -> IL driver. Port of kshexe/rethink's
// MI2D7B.ts (https://github.com/kshexe/rethink, commit 8fa8bd4), a fork of upstream rethink
// whose frames were captured against a real unit (2026-09-09..11-09). An AABB appliance,
// class 0x20, written with the F0 E5 settings write the fork shares across its KR laundry:
// `f0 e5 00 02 01 ff <n> [<key> <value>]*n`.
//
// From the appliance:
//   <20> 00 e5 00             write ack: ignored
//   <20> e6 .. (57 bytes)     the echo after a power write; [46] 0 off, 2 on (both directions
//                             captured). This is the only power read-back.
//   <20> 72 00 <code>         notification: 0 and 0xc8 both preceded the cloud's
//                             washing_is_complete (two samples); published as an event
//   <20> 3e <u16 delta> <u16 total> <n>   energy report, ~15 min apart (two samples): the
//                             total is the appliance's own cycle counter
//   enveloped EC/EB, 48-byte records: [14] remaining minutes (three samples of one cycle,
//                             tracking the panel to within a minute). The fork reads it as
//                             record[13] of records starting one byte later than
//                             aabb_common::enveloped_status; same byte.
//
// Writes: power key 0x02 (on captured; off byte-identical to RD20_S's captured off), operation
// key 0x03: 2 pause, 3 resume (captured on this unit), 1 start (the FX___S / MI2U7B enum,
// not captured on this model - labelled unverified, as in the fork). No course can be
// selected: its codes are unknown, so start only resumes the course set on the panel.
//
// Divergences from the fork: power is not published from a write (the echo confirms it);
// power off clears remaining_time instead of publishing 0; nothing is published on connect
// (the fork zeroes the countdown at construction). The fork's hour/day/month totals, kept on
// disk by calendar, are not ported: a script has no wall clock and no storage that outlives a
// reconnect.
// The fork sends the family's status query (f0 ed 12 11 01 00 00 01 04 00) once on connect,
// which elicits the enveloped record; so does this driver.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn rec_len() { 48 }

fn notifications() { #{ "0": "washing_is_complete", "200": "washing_is_complete" } }

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "washer", class: "mini_washer", label: "MiniWash", vendor: "LG",
                      model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", role: "on", rw: true, label: "Power" },
        remaining_time: #{ type: "number", class: "duration", unit: "min", label: "Remaining time" },
        start: #{ type: "trigger", label: "Start (unverified)" },
        pause: #{ type: "trigger", label: "Pause" },
        resume: #{ type: "trigger", label: "Resume" },
        notification: #{ type: "text", category: "diagnostic", label: "Notification" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Cycle energy" }
    } })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn start(ctx) {
    ctx.send_raw(aabb_wrap(hex_decode("f0ed1211010000010400")));
}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let r = c::enveloped_status(data, 0x20, rec_len());
    if r != () {
        il::publish_property(ctx, "available", "true");
        il::publish_property(ctx, "remaining_time", r[14].to_string());
        return;
    }
    let b = c::inner(data, 0x20);
    if b == () { return; }
    if b.len() == 4 && b[1] == 0x00 && b[2] == 0xe5 && b[3] == 0x00 { return; }
    if b[1] == 0x72 {
        if b.len() > 3 && b[2] == 0 {
            let name = t::name(notifications(), b[3]);
            if name != () { il::publish_event(ctx, "notification", json_stringify(#{ event_type: name })); }
        }
        return;
    }
    if b[1] == 0x3e {
        if b.len() == 7 {
            il::publish_property(ctx, "energy", (b[4] * 256 + b[5]).to_string());
        }
        return;
    }
    if b[1] == 0xe6 && b.len() == 57 {
        il::publish_property(ctx, "available", "true");
        let on = b[46] != 0;
        il::publish_property(ctx, "power", if on { "true" } else { "false" });
        if !on { il::publish_absent(ctx, "remaining_time"); }
    }
}

fn settings_write(ctx, key, value) {
    ctx.send_raw(aabb_wrap([0xf0, 0xe5, 0x00, 0x02, 0x01, 0xff, 0x01, key, value]));
}

fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value == () { return; }
    switch prop {
        "power" => settings_write(ctx, 0x02, if c::to_bool(value) { 1 } else { 0 }),
        "start" => settings_write(ctx, 0x03, 1),
        "pause" => settings_write(ctx, 0x03, 2),
        "resume" => settings_write(ctx, 0x03, 3),
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}
