// LG water purifier 1WPU4CIGCR__2 (cold / hot / purified / sterilised water): device -> IL
// driver. An AABB (`AA len .. checksum BB`) appliance that reports on its own; nothing is
// asked for. Frames are discriminated by inner byte 1 (inner byte 0 is 0x12):
//   0xEC  status: two stacked 26-byte records, the previous state then the current one
//   0x1F  last dispensing report, six 16-bit big-endian volumes in millilitres
//
// The record offsets are the model description's own field indexes, checked against the real
// cloud's snapshot of the same moment. A 255 is the model's IGNORE: a feature this unit does
// not have (sound, energy saving, clean mode) and, in the other direction, "leave this field
// as it is" -- which is what makes writing one setting possible: the write frame is the
// record written back, 0xff everywhere but the field being changed.
//
// It is not read-only, though the cloud's own config says so; the five writable settings
// below each changed and came back in the next status frame. The four sterilisation-schedule
// bytes are writable too but deliberately not offered: a time-only write moves the weekly run
// to another weekday.
//
// Not published: fields that only ever read IGNORE, the unidentified bytes (7, 9, 21, 23,
// 24), and unidentified dispensing slots 3/4. ThinQ's app shows
// energy monitoring: 0xAF reports approximately 15-minute Wh deltas, summed in memory.

import "aabb_common" as c;
import "il_common" as il;
import "energy_common" as energy;

fn record_len() { 26 }

fn descriptor(ctx) {
    json_stringify(#{
        il: 0,
        kind: "dispenser",
        class: "water_purifier",
        label: "Water purifier",
        vendor: "LG",
        model: ctx.model_id(),
        props: #{
            available: #{ type: "binary", role: "available" },
            energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Energy since driver restart" },
            status: #{ type: "select", category: "diagnostic", options: ["failed", "not_working", "normal"] },
            tap_uv: #{ type: "select", label: "Tap UV lamp",
                       options: ["standby", "cleaning", "cleaning_manual"] },
            water_selection: #{ type: "select", label: "Water selected",
                                options: ["hot", "normal", "cold", "clean"] },
            hot_water_last_temperature: #{ type: "number", class: "temperature", series: "gauge", unit: "°C", label: "Last hot water temperature setting" },
            water_amount: #{ type: "select", label: "Amount selected",
                             options: ["120ml", "250ml", "500ml", "continuous"] },
            default_water: #{ type: "select", category: "config", rw: true,
                              options: ["last_used", "normal", "cold"] },
            default_amount: #{ type: "select", category: "config", rw: true, options: ["120ml", "250ml", "500ml"] },
            auto_care: #{ type: "binary", category: "config", rw: true },
            button_sound: #{ type: "binary", category: "config", rw: true },
            not_use_notice: #{ type: "binary", category: "config", rw: true, label: "Unused-water notice" },
            self_clean_next: #{ type: "text", category: "diagnostic", label: "Next self-clean, UTC (MM-DD HH:MM)" },
            hot_water_last_dispensed: #{ type: "number", class: "volume", series: "gauge", unit: "mL", label: "Hot water last dispensed" },
            normal_water_last_dispensed: #{ type: "number", class: "volume", series: "gauge", unit: "mL", label: "Purified water last dispensed" },
            cold_water_last_dispensed: #{ type: "number", class: "volume", series: "gauge", unit: "mL", label: "Cold water last dispensed" },
            clean_water_last_dispensed: #{ type: "number", class: "volume", series: "gauge", unit: "mL", label: "Clean water last dispensed" }
        }
    })
}

// (Rhai functions cannot see top-level constants, so the tables are functions.)
fn status_name(v) {
    switch v { 0 => "failed", 1 => "not_working", 2 => "normal", _ => () }
}
fn tap_uv_name(v) {
    switch v { 0 => "standby", 1 => "cleaning", 2 => "cleaning_manual", _ => () }
}
fn water_name(v) {
    switch v { 1 => "hot", 2 => "normal", 3 => "cold", 4 => "clean", _ => () }
}
fn amount_name(v) {
    switch v { 1 => "120ml", 2 => "250ml", 3 => "500ml", 4 => "continuous", _ => () }
}
fn default_water_name(v) {
    switch v { 1 => "last_used", 2 => "normal", 3 => "cold", _ => () }
}
fn default_water_wire(name) {
    switch name { "last_used" => 1, "normal" => 2, "cold" => 3, _ => () }
}
// The default may not be "continuous": that is the button held down, not a quantity.
fn default_amount_wire(name) {
    switch name { "120ml" => 1, "250ml" => 2, "500ml" => 3, _ => () }
}

// ---- host hooks -------------------------------------------------------------------

fn publish_config(ctx) {
    il::publish_il(ctx, descriptor(ctx));
    energy::publish(ctx);
}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let inner = c::inner(data, 0x12);
    if inner == () { return; }

    // Observed subtypes 0x0D and 0x0E both contribute to app hourly Wh.
    if inner[1] == 0xaf && inner.len() == 5
        && (inner[2] == 0x0d || inner[2] == 0x0e) {
        energy::add(ctx, inner[3] * 256 + inner[4]);
        return;
    }

    let current = c::common_status_offset(inner, record_len());
    if current != () {
        status(ctx, inner, current);
    } else if inner[1] == 0x1f && inner.len() == 2 + 6 * 2 {
        dispensing(ctx, inner);
    }
}

fn status(ctx, r, o) {
    il::publish_property(ctx, "available", "true");
    c::pub_name(ctx, "status", status_name(r[o + 0]));
    c::pub_name(ctx, "tap_uv", tap_uv_name(r[o + 1]));
    c::pub_name(ctx, "water_selection", water_name(r[o + 2]));
    c::pub_name(ctx, "water_amount", amount_name(r[o + 3]));
    // Selection setting, not measured water temperature. Keep it across non-hot selections.
    if r[o + 2] == 1 {
        let code = r[o + 6];
        let temperature = switch code { 1 => 40, 2 => 75, 3 => 85, _ => () };
        if temperature != () {
            il::publish_property(ctx, "hot_water_last_temperature", temperature.to_string());
        }
    }
    c::pub_name(ctx, "default_water", default_water_name(r[o + 10]));
    c::pub_name(ctx, "default_amount", amount_name(r[o + 11]));
    il::publish_property(ctx, "auto_care", c::on_off(r[o + 20]));
    il::publish_property(ctx, "button_sound", c::on_off(r[o + 12]));
    il::publish_property(ctx, "not_use_notice", c::on_off(r[o + 8]));

    // The next self-clean, as month / day / hour / minute with no year, in UTC. Converting
    // to local time needs a timezone and a calendar, which is a consumer's business.
    let month = r[o + 15];
    let day = r[o + 16];
    if month >= 1 && month <= 12 && day >= 1 && day <= 31 {
        il::publish_property(ctx, "self_clean_next",
            c::pad2(month) + "-" + c::pad2(day) + " " + c::pad2(r[o + 17]) + ":" + c::pad2(r[o + 18]));
    }
}

// Six BE volumes: live-verified normal/hot/cold at slots 0/1/2, clean at 5.
// Slots 3/4 remain unidentified. Reports replace values, not daily totals.
fn dispensing(ctx, r) {
    let names = ["normal_water_last_dispensed", "hot_water_last_dispensed", "cold_water_last_dispensed", "clean_water_last_dispensed"];
    let slots = [0, 1, 2, 5];
    for i in 0..names.len() {
        let slot = slots[i];
        let v = r[2 + slot * 2] * 256 + r[3 + slot * 2];
        il::publish_property(ctx, names[i], v.to_string());
    }
}

// One setting travels at a time; the rest of the record says "leave it". Nothing is
// published from a write: the appliance sends a status frame about a second later, so the
// property follows what the appliance says and a declined setting simply stays where it was.
fn set_field(ctx, offset, value) {
    let inner = [0xf0, 0x17];
    for i in 0..record_len() { inner.push(if i == offset { value } else { 0xff }); }
    ctx.send_raw(aabb_wrap(inner));
}

fn set_property(ctx, prop, value) {
    switch prop {
        "default_water" => {
            let w = default_water_wire(value);
            if w == () { c::reject(ctx, prop, "unknown water"); return; }
            set_field(ctx, 10, w);
        }
        "default_amount" => {
            let w = default_amount_wire(value);
            if w == () { c::reject(ctx, prop, "unknown amount"); return; }
            set_field(ctx, 11, w);
        }
        "auto_care" => { set_field(ctx, 20, if c::to_bool(value) { 1 } else { 0 }); }
        "button_sound" => { set_field(ctx, 12, if c::to_bool(value) { 1 } else { 0 }); }
        "not_use_notice" => { set_field(ctx, 8, if c::to_bool(value) { 1 } else { 0 }); }
        _ => { c::reject(ctx, prop, "unknown or read-only property"); }
    }
}

// il_common uses host validation on 0.1 and script-side validation on 0.2.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
