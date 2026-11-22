// Checked against rethink PR #113, 1419bf64e130f9c1268297221b62869b75ae383c (dhum_common).
// LG dehumidifier DHUM_056905_WW: device -> IL driver.
//
// Speaks the TLV protocol to the appliance and describes/reports it in the neutral IL
// (see the IL specification, a separate repository). It knows nothing about any consumer:
// values go out through `publish_property`, the descriptor through `publish_il`, and
// writes arrive at `on_set_property`. Timers are requests (`set_timer`) answered by
// `on_timer`; the host owns the clock.
//
// Wire tags: 0x1f7 power, 0x1f9 mode, 0x1fa fan (2 low, 6 high), 0x253 target humidity,
// 0x336 humidity, 0x1fd temperature (half degrees), 0x186 tank, 0x360 sterilization,
// 0x2a2 UVnano, 0x21e tank light, 0x21b off timer (minutes), 0x221 error.
//
// Changes from talktalk2580's live DHUM_056905_WW (Korea, firmware 537), 2026-11-16:
//   - On that unit 0x1fd is not a temperature (only 250 in smart/spot, 252 in jet/silent/laundry,
//     following the mode). On the maintainer's unit (24 h capture, 2026-10-09) it is one: 48..54
//     half degrees, moving while the mode stayed smart. Checked by the maintainer against a room
//     sensor nearby in Home Assistant history (November 2026): the values do not match exactly
//     (about 1-2 °C apart, in 1 °C steps), but it rises and falls with the room temperature. So it
//     is published only when it reads as a room temperature (at most 60 °C). The LG app shows no
//     temperature.
//   - That unit has no bucket light, sterilize or UVnano and never sends 0x2a2. The maintainer's
//     unit reports 0x2a2, 0x360 and 0x21e in every state frame, so those props stay.
//   - The tank also reports via 0x2b2 (1 = full) and 0x2b1 = 256 / 0x2b2 = 0 when emptied.
//   - Target humidity: the panel moves in steps of 5 (30..70).
//   - Off timer 0x21b: the panel goes 1..8 h then off; the report is minutes LEFT (59, 119 ... 479, 0).
//     Exposed in hours 0..8 (rounded up), a write sends hours * 60.
//   - The 190-byte 87 fd energy report never arrived (25 h capture, LG bridge on): energy stays empty.

import "tlv_common" as c;
import "table_common" as t;
import "il_common" as il;
import "energy_common" as energy;

// ---- model ------------------------------------------------------------------------

fn descriptor(ctx) {
    json_stringify(#{
        il: 0,
        kind: "humidifier",
        class: "dehumidifier",
        label: "Dehumidifier",
        vendor: "LG",
        model: ctx.model_id(),
        props: #{
            available: #{ type: "binary", role: "available" },
            energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Energy since driver restart" },
            power: #{ type: "binary", rw: true, role: "on", src: #{ tlv_tag: "0x1f7" } },
            mode: #{ type: "select", rw: true, role: "mode", src: #{ tlv_tag: "0x1f9" },
                     options: t::options(modes()) },
            target: #{ type: "number", rw: true, role: "target_humidity", src: #{ tlv_tag: "0x253" },
                       min: 30, max: 70, step: 5, unit: "%" },
            humidity: #{ type: "number", class: "humidity", series: "gauge", role: "current_humidity", src: #{ tlv_tag: "0x336" }, unit: "%" },
            temperature: #{ type: "number", class: "temperature", series: "gauge", role: "current_temperature", src: #{ tlv_tag: "0x1fd" },
                            unit: "°C" },
            fan: #{ type: "select", rw: true, role: "fan_speed", src: #{ tlv_tag: "0x1fa" },
                    options: ["low", "high"] },
            tank_full: #{ type: "binary", class: "problem", src: #{ tlv_tag: "0x186" } },
            tank_state: #{ type: "select", category: "diagnostic", src: #{ tlv_tag: "0x186" },
                           options: t::options(tank_states()) },
            sterilize: #{ type: "binary", rw: true, src: #{ tlv_tag: "0x360" } },
            uvnano: #{ type: "binary", rw: true, src: #{ tlv_tag: "0x2a2" } },
            bucket_light: #{ type: "binary", rw: true, src: #{ tlv_tag: "0x21e" } },
            off_timer: #{ type: "number", class: "duration", rw: true, src: #{ tlv_tag: "0x21b" },
                          // PATCH (live capture): the panel goes 1..8 hours then off; the report is the minutes left
                          // (59, 119, ... 479, then 0), so it counts down. Exposed in hours like the panel:
                          // the minutes left are rounded up, and a write sends hours * 60.
                          min: 0, max: 8, step: 1, unit: "h" },
            error: #{ type: "number", category: "diagnostic", src: #{ tlv_tag: "0x221" } }
        }
    })
}

// wire mode -> IL mode. Two numbering schemes are seen on the wire (0..5 and 17..21).
fn modes() {
    #{ "0": "smart", "17": "smart", "1": "jet", "18": "jet", "2": "silent", "19": "silent",
       "4": "spot", "20": "spot", "5": "laundry", "21": "laundry" }
}

// Modes are written with the 17..21 codes; the appliance also reports 0..5 for the same modes.
fn mode_writes() { #{ "17": "smart", "18": "jet", "19": "silent", "20": "spot", "21": "laundry" } }

// The tags whose presence makes a frame the appliance's state (not just a stray notify).
fn VALUE_TAGS() { [0x1f7, 0x1f9, 0x1fa, 0x21b, 0x21e, 0x186, 0x2b2, 0x253, 0x2a2, 0x336, 0x360] }

fn is_silent(raw) { raw == 2 || raw == 19 }

fn tank_states() {
    #{ "0": "not_full", "1": "full_stopped", "2": "full_fan_mode" }
}

// ---- helpers ----------------------------------------------------------------------

// The fan write carries a per-mode capability table: mode id, 0, the speed that mode runs at.
// Laundry is fixed at high.
fn write_fan(ctx, speed) {
    c::put(ctx, 0x1fa, speed);
    let tlvs = [#{ t: 0x1fa, v: speed }];
    for row in [[17, speed], [18, speed], [20, speed], [21, 6], [22, speed]] {
        tlvs.push(#{ t: 0x2d7, v: row[0] });
        tlvs.push(#{ t: 0x2d8, v: 0 });
        tlvs.push(#{ t: 0x2d9, v: row[1] });
    }
    ctx.send_raw(tlv_frame_build(c::write_header(), tlvs));
}

// ---- host hooks -------------------------------------------------------------------

fn start(ctx) { c::start(ctx); }

fn publish_config(ctx) {
    il::publish_il(ctx, descriptor(ctx));
    energy::publish(ctx);
}

fn on_drop(ctx) {
    il::publish_property(ctx, "available", "false");
}

fn on_timer(ctx, name) { c::on_timer(ctx, name); }

fn on_data(ctx, data) {
    // Captured FD report: 177-byte body, marker 0x15, Wh delta at body +1..4.
    // Decode the candidate four-byte little-endian field; never parse this as TLV.
    if data.len() == 190 && data[2] == 4 && data[3] == 0
        && data[4] == 0 && data[5] == 0 && data[6] == 0x87
        && data[7] == 0xfd && data[8] == 3 && data[9] == 0
        && data[10] == 177 && data[11] == 0x15 {
        let delta = data[12] + data[13] * 256
            + data[14] * 65536 + data[15] * 16777216;
        energy::add(ctx, delta);
        return;
    }

    let frame = c::receive(ctx, data, 1, VALUE_TAGS());
    if frame == () || frame.caps { return; }

    for e in frame.tlvs { apply(ctx, e.t, e.v); }

    if frame.first {
        il::publish_property(ctx, "available", "true");
        // Ask the cloud not to relay tag 1200 (the appliance's noisy periodic report).
        ctx.send_clip("setMaskingInfo", 0, "{\"blacklist_tlv\":\"1200\"}");
    }
}

// Apply one wire tag. Returns true if it was one of the tags that count as "values".
fn apply(ctx, tag, v) {
    switch tag {
        // per-mode fan capability rows repeat once per mode: not device state
        0x2d7 | 0x2d8 | 0x2d9 => { return false; }
        0x1f7 => {
            c::put(ctx, tag, v);
            il::publish_property(ctx, "power", c::flag(v));
        }
        0x1f9 => {
            let prev = ctx.state_get("t505");
            c::put(ctx, tag, v);
            let name = t::name(modes(), v);
            if name != () { il::publish_property(ctx, "mode", name); }
            // entering silent from another mode drops the fan to low
            if is_silent(v) && (prev == () || !is_silent(prev)) {
                il::publish_property(ctx, "fan", "low");
            }
        }
        0x1fa => {
            c::put(ctx, tag, v);
            if v == 2 { il::publish_property(ctx, "fan", "low"); }
            else if v == 6 { il::publish_property(ctx, "fan", "high"); }
        }
        0x253 => {
            c::put(ctx, tag, v);
            if v >= 30 && v <= 70 { il::publish_property(ctx, "target", v.to_string()); }
        }
        0x336 => { il::publish_property(ctx, "humidity", v.to_string()); }
        // Half degrees; talktalk2580's unit sends 250 / 252 here, which is not a temperature.
        0x1fd => {
            if v > 120 { return false; }
            let t = if v % 2 == 0 { (v / 2).to_string() } else { (v / 2.0).to_string() };
            il::publish_property(ctx, "temperature", t);
        }
        0x186 => {
            let name = t::name(tank_states(), v);
            if name != () {
                il::publish_property(ctx, "tank_full", c::flag(v));
                il::publish_property(ctx, "tank_state", name);
            }
        }
        // secondary tank signals seen when the tank is reinstalled / filled
        0x2b1 => { if v == 256 { il::publish_property(ctx, "tank_full", "false"); } }
        0x2b2 => { il::publish_property(ctx, "tank_full", c::flag(v)); }
        0x360 => { c::put(ctx, tag, v); il::publish_property(ctx, "sterilize", c::flag(v)); }
        0x2a2 => { c::put(ctx, tag, v); il::publish_property(ctx, "uvnano", c::flag(v)); }
        0x21e => { c::put(ctx, tag, v); il::publish_property(ctx, "bucket_light", c::flag(v)); }
        0x21b => { c::put(ctx, tag, v); il::publish_property(ctx, "off_timer", ((v + 59) / 60).to_string()); }
        0x221 => { il::publish_property(ctx, "error", v.to_string()); }
        _ => { return false; }
    }
    true
}

fn set_property(ctx, prop, value) {
    switch prop {
        "power" => {
            let on = c::to_bool(value);
            c::write(ctx, 0x1f7, if on { 1 } else { 0 }, if on { [0x1f9] } else { [] });
        }
        "mode" => {
            let wire = t::code(mode_writes(), value);
            if wire == () { c::reject(ctx, prop, "unknown mode"); return; }
            let prev = c::get(ctx, 0x1f9);
            c::put(ctx, 0x1f7, 1); // selecting a mode powers on
            if wire == 19 && !is_silent(prev) {
                c::put(ctx, 0x1fa, 2); // silent runs at low fan
                il::publish_property(ctx, "fan", "low");
            }
            c::write(ctx, 0x1f9, wire, [0x1f7]);
        }
        "target" => {
            let n = c::to_number(value);
            if n == () { c::reject(ctx, prop, "not a number"); return; }
            let t = n.round().to_int();
            if t < 30 { t = 30; }
            if t > 70 { t = 70; }
            c::put(ctx, 0x1f7, 1);
            c::write(ctx, 0x253, t, [0x1f7, 0x1f9]);
            // PATCH: a target snapped onto the value the appliance already has brings no status report,
            // which left the Home Assistant slider on the unsnapped number. Publish the snapped value here
            // (on_set_property published the unsnapped one just before, so this is a real change for HA).
            il::publish_property(ctx, "target", t.to_string());
        }
        "fan" => {
            if value == "low" { write_fan(ctx, 2); }
            else if value == "high" { write_fan(ctx, 6); }
            else { c::reject(ctx, prop, "unknown fan speed"); }
        }
        "sterilize" => { c::write(ctx, 0x360, if c::to_bool(value) { 1 } else { 0 }, [0x1f7, 0x1f9]); }
        "uvnano" => { c::write(ctx, 0x2a2, if c::to_bool(value) { 1 } else { 0 }, [0x1f7, 0x1f9]); }
        "bucket_light" => { c::write(ctx, 0x21e, if c::to_bool(value) { 1 } else { 0 }, []); }
        "off_timer" => {
            let n = c::to_number(value);
            if n == () || n < 0 { c::reject(ctx, prop, "not a non-negative number"); return; }
            c::write(ctx, 0x21b, n.round().to_int() * 60, []);
        }
        _ => { c::reject(ctx, prop, "unknown or read-only property"); }
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let v = value;
    // PATCH: the Home Assistant humidifier slider ignores the descriptor's step (ildevice_ha does not pass
    // target_humidity_step), so snap the target to the nearest 5 here instead of rejecting it as bad_step.
    if prop == "target" {
        let n = c::to_number(v);
        if n != () {
            let raw = n.round().to_int();
            let snapped = ((n / 5.0).round() * 5.0).to_int();
            // HA only redraws its slider on a state change: when the snapped value is the one it already
            // shows, first publish what the user chose, then set_property publishes the snapped value.
            if raw != snapped && raw >= 30 && raw <= 70 { il::publish_property(ctx, "target", raw.to_string()); }
            v = snapped.to_string();
        }
    }
    let v = il::validate(ctx, prop, v);
    if v != () { set_property(ctx, prop, v); }
}
