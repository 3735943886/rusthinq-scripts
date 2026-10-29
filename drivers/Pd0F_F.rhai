// LG "2nd Mini Washer" (the pedestal drawer washer sold in Korea) Pd0F_F, deviceType 201:
// device -> IL driver. AABB frames start with 0x20 and carry a 25-byte monitoring record (see
// monitoring_common). It answers every command with a four-byte 0x00 frame and reports two
// board serial numbers in ASCII behind 0x31 (not decoded).
//
// This appliance switches its own Wi-Fi module off when it has nothing to do, so it spends most
// of its life offline and only appears on the wire while powered on or running. That is normal
// for the model, not a fault.
//
// The offsets were read out of the appliance's own cloud, not guessed: a frame whose payload
// byte i held the value i was injected and the cloud replied with its decoded state naming each
// field beside the value it had been handed; the option bits by a bit-sweep, the course codes
// by stepping rec[5] through every value and reading back the name.

import "aabb_common" as c;
import "monitoring_common" as m;
import "table_common" as t;
import "il_common" as il;

fn dev() { 0x20 }
fn payload_len() { 25 }

// The courses this unit's dial has and a start command can express, with what each runs with:
// [soil, spin, temperature, rinses, water level, water flow, soak]. A start command carries
// the whole cycle, not just a course code; these are the drawer's own panel defaults from the
// model JSON. The last three are zero on every course (this washer has no such controls).
// Confirmed on the wire: the app's Small Load start was 01 00 01 00 02 ... 05.
fn preset(course) {
    switch course {
        1 => [0, 1, 0, 2, 0, 0, 0],   // Small Load
        2 => [0, 1, 40, 3, 0, 0, 0],  // Underwear
        3 => [0, 1, 0, 2, 0, 0, 0],   // Wool
        4 => [0, 1, 90, 2, 0, 0, 0],  // Light Boil
        5 => [0, 1, 60, 4, 0, 0, 0],  // Baby Care
        6 => [0, 1, 0, 1, 0, 0, 0],   // Rinse + Spin
        7 => [0, 1, 60, 1, 0, 0, 0],  // Tub Clean
        _ => ()
    }
}

fn startable() { [1, 2, 3, 4, 5, 6, 7] }

// The start command, 15 bytes: the settings in the order the model JSON lists them, the reserve
// time and the smart-course slot, then four option bytes of which only the last has ever been
// non-zero. Resuming is the same frame with the initial bit (0x01) cleared, recorded from the
// app's own Resume button (0x04 in place of 0x05; 0x04 is remote start).
fn start_payload(course, resume) {
    let p = preset(course);
    if p == () { return (); }
    let out = [course, p[0], p[1], p[2], p[3], p[4], p[5], p[6], 0, 0, 0, 0, 0, 0, 0];
    out[14] = 0x04 | (if resume { 0 } else { 0x01 });
    out
}

fn courses() {
    #{ "0": "none", "1": "small_load", "2": "underwear", "3": "wool", "4": "light_boil",
       "5": "baby_care", "6": "rinse_spin", "7": "tub_clean", "8": "spin_only", "9": "hand_wash",
       "10": "speed_wash", "11": "active_wear", "12": "intimate", "13": "cotton_eco_full",
       "14": "cotton_eco_half", "15": "cotton_20" }
}

fn states() {
    #{ "0": "off", "1": "initial", "2": "paused", "3": "sensing", "4": "soaking", "5": "washing",
       "6": "rinsing", "7": "spinning", "8": "complete", "9": "reserved", "10": "firmware_update",
       "11": "diagnosis" }
}

// The two "cold" entries are distinct settings on this model (tap cold and the cold-wash
// option); everything else is the water temperature in degrees C.
fn temps() {
    #{ "0": "cold", "1": "cold_wash", "30": "30", "35": "35", "38": "38", "40": "40", "60": "60",
       "90": "90" }
}

fn errors() {
    #{ "0": "OK", "1": "Water supply error (IE)", "2": "Water drain error (OE)",
       "3": "Out of balance error (UE)", "4": "Door open error (DE1)",
       "5": "Water level sensor error (PE)", "8": "Door error (dO)", "9": "Locked motor error (LE)",
       "10": "Water supply error (AE)", "11": "Temperature sensor error (TE)",
       "12": "Overfill error (FE)", "16": "Door lock error (DE2)", "27": "Unknown error (FF)",
       "36": "Unknown error (E7)" }
}

fn descriptor(ctx) {
    let props = m::props(states(), courses(), startable());
    props.mixin(#{
        temp: #{ type: "select", label: "Water temperature",
                 options: t::options(temps()) },
        rinse: #{ type: "number", series: "gauge", label: "Rinse cycles" },
        spin: #{ type: "binary" },
        sterilize: #{ type: "binary" },
        warm_water: #{ type: "binary" },
        door_lock: #{ type: "binary", category: "diagnostic" },
        child_lock: #{ type: "binary", category: "diagnostic" },
        audible_diagnosis: #{ type: "binary", category: "diagnostic" }
    });
    json_stringify(#{
        il: 0, kind: "washer", class: "mini_washer", label: "Mini washer", vendor: "LG",
        model: ctx.model_id(), props: props
    })
}

// ---- host hooks -------------------------------------------------------------------

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn start(ctx) { m::start(ctx); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let a = m::ack(data, dev());
    if a != () { m::on_ack(ctx, a); return; }

    let r = m::record(data, dev(), payload_len());
    if r == () { return; }
    m::publish(ctx, r, states(), courses(), startable(), errors());
    let b = r.body;
    let p = r.p;

    c::pub_name(ctx, "temp", t::name(temps(), b[p + 9]));
    il::publish_property(ctx, "rinse", b[p + 10].to_string());
    il::publish_property(ctx, "spin", if b[p + 8] != 0 { "true" } else { "false" });

    let flags = b[p + 14];
    il::publish_property(ctx, "child_lock", c::bit(flags, 0x01));
    il::publish_property(ctx, "audible_diagnosis", c::bit(flags, 0x02));
    il::publish_property(ctx, "door_lock", c::bit(flags, 0x08));
    let opt2 = b[p + 15];
    il::publish_property(ctx, "sterilize", c::bit(opt2, 0x02));
    il::publish_property(ctx, "warm_water", c::bit(opt2, 0x10));
    il::publish_property(ctx, "remote_start", c::bit(b[p + 16], 0x04));
    // Decoded by the cloud but not published: preState (rec[19]), the smart / downloaded course
    // slots (rec[20], rec[23]), and soil / water level / water flow / soak, for which the model
    // JSON gives exactly one value each: this drawer washer has no such controls. rec[11],
    // rec[17], rec[18] are named by nobody and have only ever been zero.
}

// The drawer obeys none of this unless Remote Start is armed on its own panel, a deliberate
// piece of LG's design that a command cannot switch on. While the appliance is asleep with its
// Wi-Fi module off nothing reaches it at all.
fn set_property(ctx, prop, value) {
    if m::control(ctx, prop, value, courses(), startable(), "drawer") { return; }
    if prop != "start" { c::reject(ctx, prop, "unknown or read-only property"); return; }
    let resume = ctx.state_get("state") == 2;
    let payload = start_payload(m::selected(ctx), resume);
    if payload == () { c::reject(ctx, prop, "no course selected"); return; }
    m::course_control(ctx, payload, prop);
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
