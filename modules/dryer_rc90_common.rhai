// The LG EU heat pump dryers RC90U2_WW (RC9DN9029) and RC90V9_WW (RC91V9EV2Q), which upstream
// rethink maps to one handler: port of its RC90U2_WW.ts (commit 0e57069), read only. Each model's
// driver is `import "dryer_rc90_common";`.
//
// Status is a 0x30 EB frame of one 27-byte block or EC of two (previous, current); a block is
// 00 19 and a 25-byte record, laid out as LG's modelJson Monitoring.protocol for this model:
//   0 state   1/2 remaining, 3/4 initial time (h, min)   5 course   6 error   7 dry level
//   8 Eco Hybrid   9 phase   12/13 delay end (h, min)   14 options (0x01 delay end set,
//   0x02 anti crease, 0x10 child lock, 0x40 damp dry beep, 0x80 hand iron; 0x08 is an
//   undocumented always-on bit, not exposed)   20 downloaded course, which overrides 5 when set
// While off, course, dry level and Eco Hybrid read "none" and the times 0; the phase byte is stale
// outside a cycle and reads "none" there. Dry level 0 is a timed course: "none". start() asks for
// the status with the family-wide F0ED request.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn states() { #{ "0": "off", "1": "ready", "2": "running", "3": "paused", "4": "end", "5": "error", "100": "delayed" } }

// Codes 2, 3 and 4 are all "dry" in the spec.
fn phases() { #{ "0": "detecting", "1": "steam", "2": "drying", "3": "drying", "4": "drying", "5": "cooling", "6": "anti_crease", "7": "end" } }

// Course and downloaded course share one label space.
fn courses() {
    #{ "2": "cotton_soft", "4": "duvet", "5": "easy_care", "6": "mixed_fabric", "7": "cotton",
       "8": "sportswear", "9": "quick_dry", "10": "delicate", "11": "wool", "12": "rack_dry",
       "13": "cool_air", "14": "warm_air", "16": "allergy_care", "101": "baby_wear",
       "102": "gym_clothes", "103": "blanket", "104": "blanket_refresh", "105": "rainy_season",
       "106": "single_garments", "107": "deodorization", "108": "small_load", "109": "lingerie",
       "110": "easy_iron", "111": "super_dry", "112": "economic_dry", "113": "big_size_item",
       "114": "minimize_wrinkles", "115": "shoes_fabric_doll", "116": "full_size_load" }
}

fn dry_levels() { #{ "1": "iron", "3": "cupboard", "4": "extra" } }
fn eco_hybrids() { #{ "1": "eco", "2": "normal", "3": "time" } }

fn errors() {
    #{ "0": "OK", "1": "Temperature sensor error (tE1)", "2": "Temperature sensor error (tE2)",
       "7": "Condenser error (CE1)", "13": "Drain motor error", "14": "Empty water container",
       "15": "Door open", "17": "Filter missing", "19": "Unknown error (F1)", "20": "Motor error (LE2)",
       "21": "Unknown error (AE)", "30": "Motor error (LE1)", "37": "Door sensor error (dE4)" }
}

fn with_none(table) { let o = t::options(table); o.push("none"); o }

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "dryer", label: "Dryer", vendor: "LG", model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", class: "running", label: "Powered on" },
        status: #{ type: "select", options: t::options(states()) },
        phase: #{ type: "select", options: with_none(phases()) },
        error: #{ type: "binary", class: "problem", category: "diagnostic" },
        error_message: #{ type: "text", category: "diagnostic" },
        course: #{ type: "select", options: with_none(courses()) },
        dry_level: #{ type: "select", options: with_none(dry_levels()) },
        eco_hybrid: #{ type: "select", label: "Eco Hybrid", options: with_none(eco_hybrids()) },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        initial_time: #{ type: "number", class: "duration", unit: "min", category: "diagnostic" },
        reserve_time: #{ type: "number", class: "duration", unit: "min", label: "Delay end" },
        delay: #{ type: "binary", label: "Delay end set" },
        anti_crease: #{ type: "binary" },
        child_lock: #{ type: "binary", category: "diagnostic" },
        damp_dry_beep: #{ type: "binary" },
        hand_iron: #{ type: "binary" }
    } })
}

fn start(ctx) { ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x11, 0x21, 0x01, 0x00, 0x00, 0x00, 0x18, 0x00])); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn minutes(r, o) { (r[o] * 60 + r[o + 1]).to_string() }

fn on_data(ctx, data) {
    let b = c::inner(data, 0x30);
    if b == () { return; }
    let o = c::common_status_offset(b, 27);
    if o == () || b[o + 1] != 0x19 { return; }
    let r = b.extract(o + 2, 25);
    let off = r[0] == 0;
    let active = r[0] == 2 || r[0] == 3;
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if off { "false" } else { "true" });
    il::publish_property(ctx, "error_message", t::name(errors(), r[6]) ?? "Unknown error (" + r[6] + ")");
    il::publish_property(ctx, "error", if r[6] != 0 { "true" } else { "false" });
    c::pub_name(ctx, "status", t::name(states(), r[0]));
    il::publish_property(ctx, "phase", if active { t::name(phases(), r[9]) ?? "none" } else { "none" });
    il::publish_property(ctx, "course", if off { "none" } else { t::name(courses(), r[20]) ?? t::name(courses(), r[5]) ?? "none" });
    il::publish_property(ctx, "dry_level", if off { "none" } else { t::name(dry_levels(), r[7]) ?? "none" });
    il::publish_property(ctx, "eco_hybrid", if off { "none" } else { t::name(eco_hybrids(), r[8]) ?? "none" });
    il::publish_property(ctx, "remaining_time", if off { "0" } else { minutes(r, 1) });
    il::publish_property(ctx, "initial_time", if off { "0" } else { minutes(r, 3) });
    il::publish_property(ctx, "reserve_time", if off { "0" } else { minutes(r, 12) });
    il::publish_property(ctx, "delay", c::bit(r[14], 0x01));
    il::publish_property(ctx, "anti_crease", c::bit(r[14], 0x02));
    il::publish_property(ctx, "child_lock", c::bit(r[14], 0x10));
    il::publish_property(ctx, "damp_dry_beep", c::bit(r[14], 0x40));
    il::publish_property(ctx, "hand_iron", c::bit(r[14], 0x80));
}

fn on_set_property(ctx, prop, value) {
    il::validate(ctx, prop, value); // every property is read only: il_common publishes the reject
}
