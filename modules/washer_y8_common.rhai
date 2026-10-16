// LG front-load washer Y_V8_Y___W.B32QEUK (FSR7A04PG), whole driver: Y_V8_Y inherits it with
// `import "washer_y8_common";`, and its ezDispense sibling Y_VB_Y___W.B32QEUK overrides the
// hooks marked below. Port of upstream rethink's driver (commit 0e57069).
//
// Status is a 39-byte record in a class 0x20 envelope (aabb_common's enveloped_status):
//    2 state   3/4 remaining, 5/6 initial time (h, min)   7 course   8 error   9 soil
//   10 spin   11 temperature   12 rinse   14/15 delayed end (h, min)   16 options (bits as
//   option_bits())   17 locks (0x02 remote start, 0x20 wrinkle care, 0x40 door, 0x80 child
//   lock)   18 AI DD (0x01)   22 downloaded course   23 washes since the last Tub Clean
//   30/31 cycle energy (Wh)
// Every frame is acked: unacked, the appliance repeats an envelope ten times and goes silent.
//
// A programme is F0 26 <course> <soil> <spin> <temp> <rinse> 00 <delay h> 00 00 <options> 03
// 00 00 <3 dispenser bytes>, run as one command: nothing can be set without starting a wash.
// So the target_* settings are staged here, each following what the appliance reports until
// it is changed, and start_course runs them and releases the choices. start resumes (F0 24 05).
import "aabb_common" as c;
import "table_common" as t;
import "washer_common" as w;
import "il_common" as il;

// ---- overridden by a model that extends this one ------------------------------------------

// The dial positions of an FSR7A04PG, confirmed by turning its dial; washer_common's shared
// table disagrees (0x3A is AI Wash here). The last five are the base courses of downloadable
// programmes with no dial position, which the course byte reports while one is selected.
fn courses() {
    #{ "0": "none", "58": "ai_wash", "1": "cotton", "2": "easy_care", "4": "eco_40_60", "5": "duvet",
       "7": "mix", "8": "sportswear", "12": "speed_14", "18": "tub_clean", "27": "wool",
       "32": "delicate", "45": "allergy_spa_steam", "49": "turbo_wash_39", "14": "rinse_spin",
       "23": "spin_only", "9": "silent_wash", "48": "quick_tub_clean", "59": "microplastic_care" }
}

fn extra_props() { #{} }

fn publish_extra(ctx, s) {}

// The programme's last three bytes: the dispenser's detergent level, softener level and type.
fn dispense(ctx) { [0, 0, 0] }

// Handles a model's own writes; false for any other property.
fn set_extra(ctx, prop, value) { false }

// ---- the washer ----------------------------------------------------------------------------

// Bits of the status record's options byte, and of the programme's. 0x08 (Eco Hybrid) and 0x20
// (rinse + spin) are not published until a unit is seen setting them.
fn option_bits() {
    #{ turbo_wash: 0x01, crease_care: 0x02, steam_softener: 0x04, medic_rinse: 0x10, pre_wash: 0x40,
       steam: 0x80 }
}

// The staged settings and the tables that name them.
fn settings() {
    #{ course: courses(), soil: w::soil_levels(), spin: w::spins(), temp: w::temps(), rinse: w::rinses() }
}

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", rw: true, class: "running", label: "Powered on" },
        start: #{ type: "trigger", requires: "remote_start", label: "Resume" },
        pause: #{ type: "trigger" },
        start_course: #{ type: "trigger", requires: "remote_start", label: "Run the target settings" },
        status: #{ type: "select", options: t::options(w::states()) },
        error: #{ type: "binary", class: "problem", category: "diagnostic" },
        error_message: #{ type: "text", category: "diagnostic" },
        course: #{ type: "select", options: t::options(courses()) },
        smart_course: #{ type: "select", label: "Downloaded course selected", options: t::options(w::smart_courses()) },
        temp: #{ type: "select", label: "Water temperature", options: t::options(w::temps()) },
        spin: #{ type: "select", options: t::options(w::spins()) },
        rinse: #{ type: "select", options: t::options(w::rinses()) },
        soil: #{ type: "select", label: "Soil level", options: t::options(w::soil_levels()) },
        cycles: #{ type: "number", series: "counter", category: "diagnostic", label: "Washes since Tub Clean" },
        remote_start: #{ type: "binary", category: "diagnostic", label: "Remote start armed at the panel" },
        door_lock: #{ type: "binary", category: "diagnostic" },
        child_lock: #{ type: "binary", category: "diagnostic" },
        wrinkle_care: #{ type: "binary" },
        ai_dd: #{ type: "binary", label: "AI DD" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Cycle energy" },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle length" },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        reserve_time: #{ type: "number", class: "duration", unit: "min", label: "Delay end" },
        // 0 is off; the appliance takes 3..19 (modelJson's reserveTimeHour)
        target_delay_end: #{ type: "number", rw: true, unit: "h", min: 0, max: 19, step: 1, label: "Delay end to run" }
    };
    let s = settings();
    for k in s.keys() {
        props["target_" + k] = #{ type: "select", rw: true, options: t::options(s[k]), label: "Target " + k };
    }
    for o in option_bits().keys() {
        props[o] = #{ type: "binary" };
        props["target_" + o] = #{ type: "binary", rw: true, label: "Target " + o };
    }
    props.mixin(extra_props());
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn start(ctx) { ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x11, 0x21, 0x01, 0x00, 0x00, 0x00, 0x18, 0x00])); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let s = c::enveloped_status(data, 0x20, 39);
    if s == () { return; }
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if s[2] > 0 { "true" } else { "false" });
    c::pub_name(ctx, "status", t::name(w::states(), s[2]));
    il::publish_property(ctx, "error", if s[8] != 0 { "true" } else { "false" });
    il::publish_property(ctx, "error_message", t::name(w::errors(), s[8]) ?? "Unknown error (" + s[8] + ")");
    c::pub_name(ctx, "course", t::name(courses(), s[7]));
    c::pub_name(ctx, "smart_course", t::name(w::smart_courses(), s[22]));
    c::pub_name(ctx, "spin", t::name(w::spins(), s[10]));
    c::pub_name(ctx, "temp", t::name(w::temps(), s[11]));
    c::pub_name(ctx, "rinse", t::name(w::rinses(), s[12]));
    c::pub_name(ctx, "soil", t::name(w::soil_levels(), s[9]));
    il::publish_property(ctx, "cycles", s[23].to_string());
    il::publish_property(ctx, "remote_start", c::bit(s[17], 0x02));
    il::publish_property(ctx, "wrinkle_care", c::bit(s[17], 0x20));
    il::publish_property(ctx, "door_lock", c::bit(s[17], 0x40));
    il::publish_property(ctx, "child_lock", c::bit(s[17], 0x80));
    il::publish_property(ctx, "ai_dd", c::bit(s[18], 0x01));
    il::publish_property(ctx, "initial_time", (s[5] * 60 + s[6]).to_string());
    il::publish_property(ctx, "remaining_time", (s[3] * 60 + s[4]).to_string());
    il::publish_property(ctx, "reserve_time", (s[14] * 60 + s[15]).to_string());
    il::publish_property(ctx, "energy", (s[30] * 256 + s[31]).to_string());
    let bits = option_bits();
    for o in bits.keys() { il::publish_property(ctx, o, c::bit(s[16], bits[o])); }
    publish_extra(ctx, s);

    ctx.state_set("reported", #{ course: s[7], soil: s[9], spin: s[10], temp: s[11], rinse: s[12],
                                 delay_end: s[14], options: s[16] });
    publish_targets(ctx);
}

// A setting's effective value: the one chosen here, else the one the appliance reports.
fn target(ctx, key) {
    let pending = ctx.state_get("pending") ?? #{};
    let reported = ctx.state_get("reported") ?? #{};
    pending[key] ?? reported[key] ?? 0
}

fn stage(ctx, key, code) {
    let pending = ctx.state_get("pending") ?? #{};
    pending[key] = code;
    ctx.state_set("pending", pending);
}

fn publish_targets(ctx) {
    let s = settings();
    for k in s.keys() { c::pub_name(ctx, "target_" + k, t::name(s[k], target(ctx, k))); }
    il::publish_property(ctx, "target_delay_end", target(ctx, "delay_end").to_string());
    let bits = option_bits();
    for o in bits.keys() { il::publish_property(ctx, "target_" + o, c::bit(target(ctx, "options"), bits[o])); }
}

fn programme(ctx) {
    let msg = [0xf0, 0x26, target(ctx, "course"), target(ctx, "soil"), target(ctx, "spin"),
               target(ctx, "temp"), target(ctx, "rinse"), 0, target(ctx, "delay_end"), 0, 0,
               target(ctx, "options"), 0x03, 0, 0];
    msg += dispense(ctx);
    msg
}

fn set_property(ctx, prop, value) {
    if set_extra(ctx, prop, value) { return; }
    let key = if prop.starts_with("target_") { prop.sub_string(7) } else { "" };
    let bits = option_bits();
    if prop == "power" {
        ctx.send_raw(aabb_wrap(if c::to_bool(value) { [0xf0, 0x2a, 0x01, 0x00] } else { [0xf0, 0x24, 0x01, 0x01, 0x00] }));
    } else if prop == "pause" {
        ctx.send_raw(aabb_wrap([0xf0, 0x24, 0x04, 0x01, 0x00]));
    } else if prop == "start" {
        ctx.send_raw(aabb_wrap([0xf0, 0x24, 0x05, 0x01, 0x00]));
    } else if prop == "start_course" {
        ctx.send_raw(aabb_wrap(programme(ctx)));
        // The appliance is the authority on what runs now; the targets follow it again.
        ctx.state_set("pending", #{});
        publish_targets(ctx);
    } else if settings().contains(key) {
        stage(ctx, key, t::code(settings()[key], value));
        publish_targets(ctx);
    } else if key == "delay_end" {
        let hours = value.parse_float().to_int();
        if hours == 1 || hours == 2 { c::reject(ctx, prop, "the appliance takes 0 or 3 to 19 hours"); return; }
        stage(ctx, key, hours);
        publish_targets(ctx);
    } else if bits.contains(key) {
        let options = target(ctx, "options");
        stage(ctx, "options", if c::to_bool(value) { options | bits[key] } else { options & (0xff ^ bits[key]) });
        publish_targets(ctx);
    } else {
        c::reject(ctx, prop, "unknown or read-only property");
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
