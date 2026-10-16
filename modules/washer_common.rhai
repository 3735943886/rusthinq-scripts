// The LG EU front-load washers of the "B" generation (F_V8_Y___W.B_2QEUK and relatives). Port
// of upstream rethink's washer_common.ts and its drivers (commit 0e57069). A driver inherits
// all of this with `import "washer_common";` and overrides `features()` (and `acked()`) where
// its model differs; F_V8_Y___W.B_2QEUK is the default.
//
// Status is a 0x20 0xEC frame of two 37-byte records (previous, current), 80 bytes in all; only
// the current record counts. Some models put 0x26 in the record header for the same layout, so
// only the class and the total length are checked, as upstream does. Current record offsets:
//   43 state      44/45 remaining, 46/47 initial time (h, min)   48 course   49 error
//   50 soil       51 spin       52 temperature    53 rinses (2+ = extra rinse)
//   54 drying mode   55 delay end (h)   57 options (0x01 TurboWash, 0x08 Eco Hybrid,
//   0x40 pre-wash, 0x80 steam)   58 locks (0x02 remote start, 0x40 door, 0x80 child lock)
//   64 cycle counter   71/72 cycle energy (Wh)   73 detergent, 74 softener dose
// Commands: F0 2A 01 00 power on, F0 24 01 01 00 power off, F0 24 04 01 00 pause,
// F0 24 05 01 00 start.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

// What the model reports beyond the common fields. Override in the model's driver.
fn features() { ["soil", "reserve_time", "extra_rinse", "options", "child_lock"] }

// Whether the appliance repeats unacked frames and so needs the cloud's acks.
fn acked() { false }

// Code 10 is unassigned, as are 13 and 17 in states(): a gap reads back as unknown.
fn errors() {
    #{ "0": "OK", "1": "Door lock error (DE2)", "2": "Door open error (DE1)",
       "3": "Water supply error (IE)", "4": "Water drain error (OE)", "5": "Out of balance error (UE)",
       "6": "Overfill error (FE)", "7": "Water level sensor error (PE)",
       "8": "Temperature sensor error (TE)", "9": "Locked motor error (LE)", "11": "Unknown error (dHE)",
       "12": "Power fail error (PF)", "13": "Unknown error (FF)", "14": "Unknown error (DCE)",
       "15": "Unknown error (AE)", "16": "EEPROM error", "17": "Unknown error (PS)",
       "18": "Door sensor error (DE4)", "19": "Vibration sensor error (VS)", "20": "Unknown error (LE8)",
       "21": "Unknown error (LE9)", "22": "Unknown error (ED1)", "23": "Unknown error (ED2)",
       "24": "Unknown error (ED3)", "25": "Unknown error (ED4)", "26": "Unknown error (ED5)" }
}

fn states() {
    #{ "0": "off", "1": "ready", "2": "paused", "3": "delayed", "4": "measuring", "5": "pre_wash",
       "6": "washing", "7": "rinsing", "8": "spinning", "9": "drying", "10": "end", "11": "cooling",
       "12": "rinse_hold", "14": "refreshing", "15": "steam_softening", "16": "demo", "18": "error",
       "19": "auto_door_open_pause" }
}

// Wool and Rinse + Spin each answer under two codes. Some models' course tables differ.
fn courses() {
    #{ "1": "cotton", "2": "ease_care", "4": "eco_40_60", "5": "duvet", "7": "mix", "8": "sportswear",
       "9": "night_wash", "11": "gentle_care", "12": "quick_14", "13": "steam_refresh",
       "14": "rinse_spin", "100": "rinse_spin", "18": "drum_clean", "19": "wash_dry",
       "23": "spin_drain", "24": "drying", "27": "wool", "75": "wool", "32": "delicate",
       "34": "quick_30", "36": "direct_wear", "45": "allergy_care", "44": "baby_steam_care",
       "49": "turbo_wash_39", "50": "turbo_wash_59", "51": "baby_clothes", "52": "children_clothing",
       "53": "school_uniform", "54": "swimwear", "55": "rainy_season_care",
       "56": "lightly_soiled_refresh", "57": "denim", "58": "bedding", "59": "sweat_stains",
       "62": "single_garments", "64": "overnight", "66": "fast_wash_dry", "69": "turbo_drying",
       "70": "drying_shirts", "72": "sanitary", "73": "small_load", "74": "delicate_dresses",
       "77": "cold_wash", "102": "powder_residue", "107": "cuffs_collars", "108": "juice_food_stains",
       "110": "saving_time", "111": "reducing_wrinkles" }
}

fn temps() {
    #{ "0": "none", "1": "cold", "2": "20", "3": "30", "4": "40", "5": "50", "6": "60", "7": "95" }
}

fn spins() {
    #{ "0": "none", "1": "no_spin", "2": "400", "3": "600", "4": "700", "5": "800", "6": "900",
       "7": "1000", "8": "1100", "9": "1200", "10": "1400", "11": "1600", "255": "max" }
}

fn drying_modes() {
    #{ "0": "off", "2": "auto", "3": "30_min", "4": "60_min", "5": "90_min", "6": "120_min",
       "7": "150_min", "10": "iron", "11": "delicate", "12": "eco" }
}

fn doses() { #{ "0": "off", "1": "low", "2": "medium", "3": "high" } }

fn soil_levels() { #{ "0": "none", "1": "turbo_wash", "2": "time_save", "3": "normal", "4": "intensive" } }

fn rinses() {
    #{ "0": "none", "1": "normal", "2": "rinse_plus", "3": "rinse_plus_plus", "4": "normal_hold",
       "5": "rinse_plus_hold" }
}

// The downloaded courses, consistent across models. Upstream leaves the codes it has only seen
// in a scan of the cloud unnamed, and so does this.
fn smart_courses() {
    #{ "0": "none", "52": "kids_wear", "53": "school_uniform", "54": "swimming_wear",
       "55": "rainy_season", "56": "gym_clothes", "57": "jeans", "58": "blanket", "59": "sweat_stain",
       "62": "single_garment", "63": "colour_protection", "64": "noise_minimize", "71": "baby_care",
       "72": "hygiene", "73": "small_load", "74": "lingerie", "75": "wool", "76": "skin_care",
       "77": "cold_wash", "100": "rinse_spin", "101": "lightly_soiled_items",
       "102": "minimize_detergent_residue", "103": "one_hour_wash", "107": "sleeve_hems_collars",
       "108": "juice_food_stains", "111": "minimize_wrinkles", "113": "quick_tub_clean", "121": "drain",
       "122": "spin", "132": "silent_wash", "134": "microplastic_care" }
}

fn options() { #{ turbo_wash: 0x01, pre_wash: 0x40, steam: 0x80 } }

fn descriptor(ctx) {
    let f = features();
    let props = #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", rw: true, class: "running", label: "Powered on" },
        start: #{ type: "trigger", requires: "remote_start" },
        pause: #{ type: "trigger" },
        status: #{ type: "select", options: t::options(states()) },
        error: #{ type: "binary", class: "problem", category: "diagnostic" },
        error_message: #{ type: "text", category: "diagnostic" },
        course: #{ type: "select", options: t::options(courses()) },
        spin: #{ type: "select", options: t::options(spins()) },
        temp: #{ type: "select", label: "Water temperature", options: t::options(temps()) },
        cycles: #{ type: "number", series: "counter", category: "diagnostic", label: "Cycle count" },
        remote_start: #{ type: "binary", category: "diagnostic", label: "Remote start armed at the panel" },
        door_lock: #{ type: "binary", category: "diagnostic" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Cycle energy" },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle length" },
        remaining_time: #{ type: "number", class: "duration", unit: "min" }
    };
    if f.contains("soil") {
        props.soil = #{ type: "select", label: "Soil level", options: t::options(soil_levels()) };
    }
    if f.contains("reserve_time") {
        props.reserve_time = #{ type: "number", class: "duration", unit: "h", label: "Delay end" };
    }
    if f.contains("extra_rinse") { props.extra_rinse = #{ type: "binary" }; }
    if f.contains("options") { for o in options().keys() { props[o] = #{ type: "binary" }; } }
    if f.contains("eco_hybrid") { props.eco_hybrid = #{ type: "binary" }; }
    if f.contains("child_lock") { props.child_lock = #{ type: "binary", category: "diagnostic" }; }
    if f.contains("doses") {
        props.detergent = #{ type: "select", label: "Detergent dose", options: t::options(doses()) };
        props.softener = #{ type: "select", label: "Softener dose", options: t::options(doses()) };
    }
    if f.contains("drying_mode") {
        props.drying_mode = #{ type: "select", options: t::options(drying_modes()) };
    }
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn start(ctx) { ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x11, 0x21, 0x01, 0x00, 0x00, 0x00, 0x18, 0x00])); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    if acked() { c::ack(ctx, data); }
    let b = c::inner(data, 0x20);
    if b == () || b.len() != 80 { return; }
    let f = features();
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if b[43] > 0 { "true" } else { "false" });
    c::pub_name(ctx, "status", t::name(states(), b[43]));
    il::publish_property(ctx, "error", if b[49] != 0 { "true" } else { "false" });
    il::publish_property(ctx, "error_message", t::name(errors(), b[49]) ?? "Unknown error (" + b[49] + ")");
    c::pub_name(ctx, "course", t::name(courses(), b[48]));
    c::pub_name(ctx, "spin", t::name(spins(), b[51]));
    c::pub_name(ctx, "temp", t::name(temps(), b[52]));
    il::publish_property(ctx, "cycles", b[64].to_string());
    il::publish_property(ctx, "remote_start", c::bit(b[58], 0x02));
    il::publish_property(ctx, "door_lock", c::bit(b[58], 0x40));
    il::publish_property(ctx, "energy", (b[71] * 256 + b[72]).to_string());
    il::publish_property(ctx, "initial_time", (b[46] * 60 + b[47]).to_string());
    il::publish_property(ctx, "remaining_time", (b[44] * 60 + b[45]).to_string());

    if f.contains("soil") { c::pub_name(ctx, "soil", t::name(soil_levels(), b[50])); }
    if f.contains("reserve_time") { il::publish_property(ctx, "reserve_time", b[55].to_string()); }
    // 0 or 1 is the normal rinse count; 2 and up is one or more extra rinses (Rinse+)
    if f.contains("extra_rinse") { il::publish_property(ctx, "extra_rinse", if b[53] >= 2 { "true" } else { "false" }); }
    if f.contains("options") { for o in options().keys() { il::publish_property(ctx, o, c::bit(b[57], options()[o])); } }
    if f.contains("eco_hybrid") { il::publish_property(ctx, "eco_hybrid", c::bit(b[57], 0x08)); }
    if f.contains("child_lock") { il::publish_property(ctx, "child_lock", c::bit(b[58], 0x80)); }
    if f.contains("doses") {
        c::pub_name(ctx, "detergent", t::name(doses(), b[73]));
        c::pub_name(ctx, "softener", t::name(doses(), b[74]));
    }
    if f.contains("drying_mode") { c::pub_name(ctx, "drying_mode", t::name(drying_modes(), b[54])); }
}

fn set_property(ctx, prop, value) {
    let msg = switch prop {
        "power" => if c::to_bool(value) { [0xf0, 0x2a, 0x01, 0x00] } else { [0xf0, 0x24, 0x01, 0x01, 0x00] },
        "pause" => [0xf0, 0x24, 0x04, 0x01, 0x00],
        "start" => [0xf0, 0x24, 0x05, 0x01, 0x00],
        _ => { c::reject(ctx, prop, "unknown or read-only property"); return; }
    };
    ctx.send_raw(aabb_wrap(msg));
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
