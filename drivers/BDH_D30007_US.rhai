// LG heat pump dryer BDH_D30007_US (DLHC5502V), read only: port of upstream rethink's
// BDH_D30007_US.ts (commit 0e57069), every offset confirmed live there against the LG cloud's
// decoded state. Status is an enveloped 0x30 frame (long AA FF framing) of one 42-byte record (EB)
// or two, previous and current (EC); `aabb_common::enveloped_status` takes the current one.
// Record offsets:
//   1 dry level   2 Eco Hybrid   5 course (0xFF: a downloaded cycle, named by 23)
//   9/10 remaining, 11/12 initial time (minutes, big-endian)   13 state (0 off)
//   17/18 energy used by the cycle (Wh, big-endian)   19 buzzer   23 downloaded cycle
//   24 options (0x08 wrinkle care, 0x20 drum light, 0x40 damp dry signal)
//   26 options (0x04 detect load, 0x20 condenser clean, 0x40 remote start, which the appliance
//      turns on by itself at every cycle start)   27 options (0x01 cycle optimization,
//      0x02 remote maintain)
// Course names are the panel's, not the cloud's identifiers, which disagree. Course 0 (off), dry
// level 0 and Eco Hybrid 0 (courses that do not use them) read "none", and so does download 0.
// The times read 0 while off. start() asks for the status with LG's own query.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn states() {
    #{ "0": "off", "1": "initial", "2": "running", "3": "paused", "4": "end", "5": "error",
       "6": "audible_diagnosis", "7": "drying", "8": "cooling", "9": "wrinkle_care", "10": "reserved",
       "11": "delay_load", "12": "spin_reserve", "13": "auto_test", "14": "detecting", "15": "steam",
       "16": "clothing_recognition", "17": "condenser_clean", "18": "bedding_brushing",
       "19": "dry_refreshing", "20": "allergy_care", "21": "condenser_care",
       "22": "end_remote_maintain_on", "23": "dry_ready", "24": "laundry_care", "25": "dehumidification",
       "26": "dehumidification_end", "27": "end_waiting", "28": "drum_care" }
}

fn courses() {
    #{ "0": "none", "2": "towels", "4": "bedding", "5": "perm_press", "7": "normal", "8": "activewear",
       "9": "small_load", "10": "delicates", "13": "air_dry", "15": "bedding_refresh", "16": "power_dry",
       "17": "heavy_duty", "18": "condenser_care", "19": "drum_care", "20": "down_jacket_refresh",
       "21": "timed_dry", "22": "outerwear_refresh", "23": "quick_dry", "44": "ai_dry", "45": "silent_dry",
       "46": "shrinkage_relief", "50": "rainy_days", "51": "easy_ironing", "255": "downloaded_cycle" }
}

fn download_courses() { #{ "0": "none", "114": "wrinkle_prevention", "140": "rack_dry" } }
fn dry_levels() { #{ "0": "none", "1": "damp_dry", "2": "less_dry", "3": "iron", "4": "cupboard", "5": "very_dry" } }
fn eco_hybrids() { #{ "0": "none", "1": "eco", "2": "normal", "3": "turbo" } }
fn buzzers() { #{ "0": "off", "1": "1", "2": "2", "3": "3", "4": "4" } }

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "dryer", label: "Dryer", vendor: "LG", model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", class: "running", label: "Powered on" },
        status: #{ type: "select", options: t::options(states()) },
        course: #{ type: "select", options: t::options(courses()) },
        download_course: #{ type: "select", options: t::options(download_courses()), label: "Downloaded cycle" },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        initial_time: #{ type: "number", class: "duration", unit: "min", category: "diagnostic" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Cycle energy" },
        dry_level: #{ type: "select", options: t::options(dry_levels()) },
        eco_hybrid: #{ type: "select", label: "Eco Hybrid", options: t::options(eco_hybrids()) },
        buzzer: #{ type: "select", category: "diagnostic", options: t::options(buzzers()) },
        wrinkle_care: #{ type: "binary" },
        damp_dry_signal: #{ type: "binary" },
        detect_load: #{ type: "binary" },
        cycle_optimization: #{ type: "binary" },
        remote_maintain: #{ type: "binary" },
        condenser_clean: #{ type: "binary", category: "diagnostic" },
        remote_start: #{ type: "binary", category: "diagnostic" },
        drum_light: #{ type: "binary" }
    } })
}

fn start(ctx) {
    ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x11, 0x21, 0x01, 0x00, 0x00, 0x00, 0x18, 0x04, 0x11, 0x12, 0x00, 0x00]));
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn u16be(r, o) { (r[o] * 256 + r[o + 1]).to_string() }

fn on_data(ctx, data) {
    let r = c::enveloped_status(data, 0x30, 42);
    if r == () { return; }
    let off = r[13] == 0;
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if off { "false" } else { "true" });
    c::pub_name(ctx, "status", t::name(states(), r[13]));
    c::pub_name(ctx, "course", t::name(courses(), r[5]));
    c::pub_name(ctx, "download_course", t::name(download_courses(), r[23]));
    c::pub_name(ctx, "dry_level", t::name(dry_levels(), r[1]));
    c::pub_name(ctx, "eco_hybrid", t::name(eco_hybrids(), r[2]));
    c::pub_name(ctx, "buzzer", t::name(buzzers(), r[19]));
    il::publish_property(ctx, "remaining_time", if off { "0" } else { u16be(r, 9) });
    il::publish_property(ctx, "initial_time", if off { "0" } else { u16be(r, 11) });
    il::publish_property(ctx, "energy", u16be(r, 17));
    il::publish_property(ctx, "wrinkle_care", c::bit(r[24], 0x08));
    il::publish_property(ctx, "drum_light", c::bit(r[24], 0x20));
    il::publish_property(ctx, "damp_dry_signal", c::bit(r[24], 0x40));
    il::publish_property(ctx, "detect_load", c::bit(r[26], 0x04));
    il::publish_property(ctx, "remote_start", c::bit(r[26], 0x40));
    il::publish_property(ctx, "condenser_clean", c::bit(r[26], 0x20));
    il::publish_property(ctx, "remote_maintain", c::bit(r[27], 0x02));
    il::publish_property(ctx, "cycle_optimization", c::bit(r[27], 0x01));
}

fn on_set_property(ctx, prop, value) {
    il::validate(ctx, prop, value); // every property is read only: il_common publishes the reject
}
