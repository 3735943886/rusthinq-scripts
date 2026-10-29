// LG heat-pump dryer RH14_N_KR ("Hisen Refresh 27inch 14kg"), deviceType 202: device -> IL
// driver. AABB frames start with 0x30 and carry a 25-byte monitoring record (see
// monitoring_common); 0x72 heartbeats are not decoded. The dryer answers every command with a
// four-byte 0x00 frame, sends 0xE2 frames that are not state (see monitoring_common), and reports two
// board serial numbers in ASCII behind 0x31 (not decoded).
//
// The offsets came from the appliance's own cloud (a frame whose payload byte i held the value
// i was injected and the cloud named each field), cross-checked against a real drying cycle:
// 02 00 18 01 23 07 00 03 02 02 ... is Running, 24 min left of a 1h35m Cotton Normal at Iron
// dry level on Eco Hybrid Normal, matching the cloud's snapshot field for field.

import "aabb_common" as c;
import "monitoring_common" as m;
import "table_common" as t;
import "il_common" as il;

fn dev() { 0x30 }
fn payload_len() { 25 }

// What each course this unit's dial has runs with: [dry level, Eco Hybrid]. A start command
// carries the settings as well as the course; these are the defaults the panel would fill in,
// from the model JSON. The wider course table exists so a sibling model reports a name, not so
// this one can start a cycle it has no program for. Confirmed on the wire for Cotton Normal:
// the app's start was 07 03 02 ..., and the record a second later reported exactly that.
fn preset(course) {
    switch course {
        2 => [0, 2], 4 => [0, 3], 5 => [3, 2], 7 => [3, 2], 8 => [0, 1], 9 => [0, 3],
        11 => [0, 2], 12 => [0, 1], 13 => [0, 0], 14 => [0, 2], 15 => [0, 3], 16 => [0, 3],
        17 => [0, 2], 18 => [0, 3], 19 => [0, 3], 20 => [0, 3], 21 => [0, 0],
        _ => ()
    }
}

fn startable() { [2, 4, 5, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21] }

// 14 bytes: course, dry level, Eco Hybrid, then zeros, with byte 10 carrying the option bits
// (0x01 remote start, 0x02 the initial bit that separates starting from resuming a paused cycle).
fn start_payload(course, resume) {
    let p = preset(course);
    if p == () { return (); }
    let out = [course, p[0], p[1], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    out[10] = 0x01 | (if resume { 0 } else { 0x02 });
    out
}

fn courses() {
    #{ "0": "none", "1": "refresh", "2": "towels", "3": "jeans", "4": "bulky_items",
       "5": "easy_care", "6": "mixed_fabrics", "7": "cotton_normal", "8": "sportswear",
       "9": "quick_dry", "10": "delicates", "11": "wool", "12": "rack_dry", "13": "cool_air",
       "14": "warm_air", "15": "bedding_brush", "16": "allergy_care", "17": "power",
       "18": "condenser_care", "19": "tub_clean", "20": "padding_refresh", "21": "time_dry",
       "22": "water_repellent", "23": "baby_wear", "24": "small_load", "25": "cotton_plus",
       "26": "perm_press", "27": "pet_care" }
}

fn states() {
    #{ "0": "off", "1": "initial", "2": "running", "3": "paused", "4": "complete", "5": "error",
       "8": "audible_diagnosis", "100": "reserved" }
}

// The step within the cycle, which the state byte alone does not distinguish: everything from
// the first moisture sensing to the anti-crease tumble at the end reports state running.
fn processes() {
    #{ "0": "sensing", "1": "steam", "2": "drying_1", "3": "drying_2", "4": "drying_3",
       "5": "cooling", "6": "anti_crease", "7": "end" }
}

fn dry_levels() {
    #{ "0": "none", "1": "damp_dry", "2": "less_dry", "3": "iron_dry", "4": "cupboard_dry",
       "5": "very_dry" }
}

fn eco_hybrids() {
    #{ "0": "none", "1": "eco", "2": "normal", "3": "turbo" }
}

fn errors() {
    #{ "0": "OK", "1": "Temperature sensor error (TE1)", "2": "Temperature sensor error (TE2)",
       "7": "Communication error (CE1)", "13": "Drain pump error", "14": "Water tank empty",
       "15": "Door error", "17": "Filter missing", "19": "Unknown error (F1)",
       "20": "Locked motor error (LE2)", "21": "Water supply error (AE)",
       "30": "Locked motor error (LE1)", "37": "Door sensor error (DE4)",
       "39": "Locked motor error (LE3)", "42": "Door lock error (DE2)" }
}

fn descriptor(ctx) {
    let props = m::props(states(), courses(), startable());
    props.mixin(#{
        process: #{ type: "select", label: "Cycle step",
                    options: ["none", "sensing", "steam", "drying_1", "drying_2", "drying_3",
                              "cooling", "anti_crease", "end"] },
        dry_level: #{ type: "select", options: t::options(dry_levels()) },
        eco_hybrid: #{ type: "select", options: t::options(eco_hybrids()) },
        // climbs during the cycle and resets to 0 at the next one
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Cycle energy" },
        steam: #{ type: "binary" },
        anti_crease: #{ type: "binary" },
        hand_iron: #{ type: "binary", label: "Easy iron" },
        damp_dry_beep: #{ type: "binary" },
        self_clean: #{ type: "binary", label: "Condenser self-clean" },
        reservation: #{ type: "binary" },
        child_lock: #{ type: "binary", category: "diagnostic" }
    });
    json_stringify(#{
        il: 0, kind: "dryer", label: "Dryer", vendor: "LG",
        model: ctx.model_id(), props: props
    })
}

// ---- host hooks -------------------------------------------------------------------

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let a = m::ack(data, dev());
    if a != () { m::on_ack(ctx, a); return; }

    let r = m::record(data, dev(), payload_len());
    if r == () { return; }
    m::publish(ctx, r, states(), courses(), startable(), errors());
    let b = r.body;
    let p = r.p;

    let process = if b[p] == 0 { () } else { t::name(processes(), b[p + 9]) };
    il::publish_property(ctx, "process", process ?? "none");
    c::pub_name(ctx, "dry_level", t::name(dry_levels(), b[p + 7]));
    c::pub_name(ctx, "eco_hybrid", t::name(eco_hybrids(), b[p + 8]));
    // rec[17:19]: energy used by the running cycle, big-endian, in Wh. The counter climbs at
    // about 12 Wh/min during a cycle, a heat pump's ~0.7 kW.
    il::publish_property(ctx, "energy", (b[p + 17] * 256 + b[p + 18]).to_string());

    let flags = b[p + 14];
    il::publish_property(ctx, "reservation", c::bit(flags, 0x01));
    il::publish_property(ctx, "anti_crease", c::bit(flags, 0x02));
    il::publish_property(ctx, "child_lock", c::bit(flags, 0x10));
    il::publish_property(ctx, "self_clean", c::bit(flags, 0x20));
    il::publish_property(ctx, "damp_dry_beep", c::bit(flags, 0x40));
    il::publish_property(ctx, "hand_iron", c::bit(flags, 0x80));
    il::publish_property(ctx, "remote_start", c::bit(b[p + 15], 0x01));
    il::publish_property(ctx, "steam", c::bit(b[p + 16], 0x08));
}

fn set_property(ctx, prop, value) {
    if m::control(ctx, prop, value, courses(), startable(), "dryer") { return; }
    if prop != "start" { c::reject(ctx, prop, "unknown or read-only property"); return; }
    let resume = ctx.state_get("state") == 3;
    let payload = start_payload(m::selected(ctx), resume);
    if payload == () { c::reject(ctx, prop, "no course selected"); return; }
    m::course_control(ctx, payload, prop);
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
