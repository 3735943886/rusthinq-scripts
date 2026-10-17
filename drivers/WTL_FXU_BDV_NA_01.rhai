// LG WashTower WTL_FXU_BDV_NA_01 (WKEX200HBA), a washer and a dryer in one appliance: port of
// upstream rethink's WTL_FXU_BDV_NA_01.ts (commit 0e57069). Properties are washer_*, dryer_* and
// the shared display theme. Option names are LG's own cloud identifiers, lowercased, as upstream's.
//
// Frames carry class 0x36 and a 13-byte header (`36 0a 00 <type> ..`) and end with one extra byte;
// the type at offset 3 selects: 0xD0 status (two 95-byte blocks, previous and current), 0x71 a
// resync (one block), 0x42 the washer's door (48 bytes, 5: 0 open) and 0x4E the dryer's (60
// bytes, 16: non-zero open). Block offsets:
//   washer 3 soil   4 temperature   5 rinse   6 spin   7 course   9 soak   11 water level
//     12 load item   13/14 delay, 15/16 remaining, 17/18 initial time (min), 19/20 energy (all
//     big-endian)   21 error   23 state (0 off)   26 load level   29 rinse count   31 buzzer
//     39 (0x80 add garment, 0x20 child lock, 0x10 remote start)   40 (0x01 door lock)
//     42 (0x04 remote maintain)   43 laundry texture
//   shared 48 display theme
//   dryer 54 dry level   56 temperature   57 time dry   58 course   60/61 delay, 62/63 remaining,
//     64/65 initial time   66 state   68 error   72 buzzer   75 duct clogging
//     79 (0x40 remote start, 0x10 child lock)   80 (0x02 remote maintain)
// Writes (F0 E5 00 02 01 <unit> 01 <field> <value>, unit 0x33 washer, 0x34 dryer): power (02),
// buzzer (13), the display theme (51, sent for the washer unit); remote maintain is F0 24 10 01 <on>
// <unit>. The buzzers, the theme and remote maintain apply only while their unit is powered.
// Upstream assumes both doors shut at start; nothing establishes that, so a door is absent until
// its own frame says.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn washer_unit() { 0x33 }
fn dryer_unit() { 0x34 }

fn washer_courses() {
    #{ "0": "not_selected", "1": "course_3in2_ref", "2": "add_prewash", "3": "aircleaning",
       "4": "allergy_spasteam", "5": "allergycare", "6": "ansimcold", "7": "baby_steamcare",
       "8": "babycare", "9": "bedding", "10": "boil", "11": "bright_white", "12": "bulky",
       "14": "casual", "15": "cold_care", "16": "cold_clean", "17": "coldwash", "18": "colorcare",
       "19": "cottoneco", "20": "cupboard_dry", "21": "darkwash", "22": "delicates",
       "23": "directwear", "24": "double_rinse", "25": "drain_spin", "26": "dryonly", "27": "duvet",
       "28": "duvetcleaning", "29": "easycare", "30": "favorite", "31": "gentlecare",
       "32": "halfload", "33": "handwash", "34": "handwash_wool", "35": "heavyduty",
       "36": "intensive60", "37": "iron_dry", "38": "jean", "39": "kids_wears", "40": "jumbowash",
       "41": "lingerie", "42": "lowtemp_dry", "43": "mix", "44": "hygiene_40", "45": "sanitary_60",
       "46": "normal", "47": "overnight", "48": "perm_press", "49": "power_clean", "50": "pre_wash",
       "51": "quick_deo", "52": "quick30", "53": "quiet", "54": "refresh", "55": "rinse_spin",
       "56": "rinseonly", "57": "rugged", "58": "safety", "59": "safety_normal", "60": "sanitary",
       "61": "sanitary_oxi", "62": "saving_water", "63": "schooling", "64": "shoes", "65": "silent",
       "66": "silentwash", "67": "skincare", "68": "small_load", "69": "smartsave", "70": "soak",
       "71": "spa_ref", "72": "speed_dry", "73": "speed_tub_clean", "74": "speedwash",
       "75": "speed14", "76": "speedboil", "77": "speedwash_dry", "78": "spin_only",
       "79": "sports_wears", "80": "staincare", "81": "steam_cotton", "82": "strong_dry",
       "83": "time_dry", "84": "towels", "85": "tub_clean", "86": "tub_dry", "87": "turbowash",
       "88": "washdry", "89": "washonly", "90": "white", "91": "windspin120", "92": "windspin60",
       "93": "windspin90", "94": "wool", "95": "single_shirts" }
}

fn washer_temps() {
    #{ "0": "no_temp", "1": "temp_20", "2": "temp_30", "3": "temp_40", "4": "temp_50",
       "5": "temp_60", "6": "temp_95", "7": "temp_tap_cold", "8": "temp_cold", "9": "temp_warm",
       "10": "temp_hot", "11": "temp_extra_hot", "12": "temp_cold_hot", "13": "fl27_temp_tapcold",
       "14": "not_applicable", "15": "fl27_temp_ecowarm", "16": "fl27_temp_warm" }
}

fn washer_soils() {
    #{ "0": "no_soilwash", "1": "soilwash_light", "2": "soilwash_light_normal",
       "3": "soilwash_normal", "4": "soilwash_normal_heavy", "5": "soilwash_heavy",
       "6": "soilwash_prewash", "7": "soilwash_soaking", "8": "soilwash_turbo_wash" }
}

fn washer_rinses() {
    #{ "0": "no_rinse", "1": "rinse_1", "2": "rinse_2", "3": "rinse_3", "4": "rinse_4",
       "5": "rinse_5", "6": "rinse_6", "7": "rinse_7", "8": "rinse_8", "9": "rinse_1_safe",
       "10": "rinse_2_safe", "11": "rinse_3_safe", "12": "rinse_4_safe", "13": "rinse_5_safe",
       "14": "not_applicable", "15": "rinse_plus", "16": "rinse_plus2" }
}

fn washer_spins() {
    #{ "0": "no_spin", "1": "spin_400", "2": "spin_600", "3": "spin_700", "4": "spin_800",
       "5": "spin_900", "6": "spin_1000", "7": "spin_1100", "8": "spin_1200", "9": "spin_1400",
       "10": "spin_1600", "11": "spin_max", "12": "spin_drain_only", "13": "spin_low",
       "14": "not_applicable", "15": "spin_high", "16": "spin_extra_high" }
}

fn washer_soaks() {
    #{ "0": "no_soak", "1": "soak_30", "2": "soak_45", "3": "soak_60", "4": "soak_120",
       "5": "soak_180", "6": "soak_240" }
}

fn washer_water_levels() {
    #{ "0": "no_waterlevel", "1": "waterlevel_2", "2": "waterlevel_3", "3": "waterlevel_4",
       "4": "waterlevel_5", "5": "waterlevel_6", "6": "waterlevel_7", "7": "waterlevel_8",
       "8": "waterlevel_9", "9": "waterlevel_10" }
}

fn washer_load_items() {
    #{ "0": "no_loaditem", "1": "loaditem_1", "2": "loaditem_2", "3": "loaditem_3" }
}

fn washer_load_levels() {
    #{ "0": "load_auto_detect", "1": "load_level_1", "2": "load_level_2", "3": "load_level_3",
       "4": "load_level_4", "5": "load_level_5", "6": "load_level_6", "7": "load_level_7",
       "8": "load_level_8" }
}

fn washer_rinse_counts() {
    #{ "0": "no_rinse", "1": "rinse_1", "2": "rinse_2", "3": "rinse_3", "4": "rinse_4",
       "5": "rinse_5", "6": "rinse_6", "7": "rinse_7", "8": "rinse_8" }
}

fn buzzers() {
    #{ "0": "off", "1": "low", "2": "medium", "3": "high", "4": "very_high" }
}

fn dryer_temps() {
    #{ "0": "no_temp", "1": "temp_ultralow", "2": "temp_low", "3": "temp_medium",
       "4": "temp_mediumhigh", "5": "temp_high" }
}

fn dryer_time_dries() {
    #{ "0": "no_timedry", "1": "timedry_20", "2": "timedry_30", "3": "timedry_40", "4": "timedry_50",
       "5": "timedry_60", "6": "timedry_70", "7": "timedry_80" }
}

fn washer_states() {
    #{ "0": "poweroff", "1": "initial", "2": "pause", "3": "detecting", "4": "display_load",
       "5": "add_drain", "6": "detergent_amount", "7": "reserved", "8": "soak", "9": "prewash",
       "11": "running", "12": "rinsing", "13": "rinsehold", "14": "spinning", "15": "drying",
       "16": "end", "17": "cooldown", "18": "coolfan", "20": "steam_softener", "21": "refreshing",
       "22": "error", "23": "error_auto_off", "24": "shoes_module", "25": "doing_diagnosis",
       "26": "doing_firm_update", "27": "frozen_prevent_initial", "28": "frozen_prevent_pause",
       "29": "frozen_prevent_running", "30": "service", "31": "test", "32": "autotest",
       "33": "firmware_update", "34": "audible_diagnosis", "35": "auto_dt_open_pause",
       "36": "confirm_start_for_control", "37": "clothing_recognition", "38": "detergent_input",
       "39": "softener_input", "40": "pollution_detecting", "41": "tub_cleaning",
       "42": "end_remote_maintain_on", "43": "steam", "47": "laundrycare",
       "48": "ezdispense_cleaning", "49": "end_waiting" }
}

fn washer_errors() {
    #{ "0": "none", "1": "error_pump", "2": "error_ie", "3": "error_oe", "4": "error_ue",
       "5": "error_fe", "6": "error_ae", "7": "error_pe", "8": "error_te", "9": "error_le",
       "10": "error_ce", "11": "error_dhe", "12": "error_pfe", "13": "error_ff", "14": "error_dce",
       "15": "error_ee", "16": "error_loe", "17": "error_le1", "18": "error_e3", "19": "error_ps",
       "20": "error_de1" }
}

fn dryer_errors() {
    #{ "0": "none", "1": "error_te1", "2": "error_te2", "3": "error_te3", "4": "error_te4",
       "5": "error_te5", "6": "error_te6", "7": "error_ce1", "8": "error_ce2", "9": "error_he1",
       "10": "error_e1", "11": "error_e3", "12": "error_e4", "13": "error_e5",
       "14": "error_drainmotor", "15": "error_emptywater", "16": "error_door",
       "17": "error_filterclogging", "18": "error_nofilter", "19": "error_eeprom", "20": "error_f1" }
}

fn dryer_states() {
    #{ "0": "poweroff", "1": "initial", "2": "running", "3": "pause", "4": "end", "5": "error",
       "6": "audible_diagnosis", "7": "drying", "8": "cooling", "9": "wrinklecare", "10": "reserved",
       "11": "delayload", "12": "spinreerve", "13": "autotest", "14": "detecting", "15": "steam",
       "16": "clothing_recognition", "17": "condenser_clean", "18": "beddingbrushing",
       "19": "dry_refreshing", "20": "allergycare", "21": "condensercare",
       "22": "end_remote_maintain_on", "23": "dryready", "24": "laundrycare",
       "25": "dehumidification", "26": "dehumidification_end", "27": "end_waiting",
       "28": "drum_care", "31": "ai_load_check" }
}

fn dryer_dry_levels() {
    #{ "0": "not_selected", "1": "damp", "2": "less", "3": "normal", "4": "more", "5": "very" }
}

fn dryer_duct_cloggings() {
    #{ "0": "none", "1": "level_1", "2": "level_2" }
}

fn dryer_courses() {
    #{ "0": "not_selected", "1": "refresh", "2": "towels", "3": "jean", "4": "bedding",
       "5": "easycare", "6": "mixfabric", "7": "normal", "8": "sportwear", "9": "quickdry",
       "10": "delicates", "11": "wool", "12": "rackdry", "13": "coolair", "14": "warmair",
       "15": "beddingbrush", "16": "allergycare", "17": "power", "18": "condensercare",
       "19": "tubclean", "20": "paddingrefresh", "21": "timedry", "22": "waterrepellent",
       "23": "babywear", "24": "smallload", "25": "cottonplus", "26": "permpress", "27": "pet_care",
       "28": "shirt1ea", "29": "heavyduty", "30": "ultradelicates", "31": "kidwear",
       "32": "lowtempdry", "33": "jumbodry", "34": "speeddry", "35": "airdry", "36": "spotcleaning",
       "37": "steamfresh", "38": "steamsanitary", "39": "freshenup", "40": "ftfresh",
       "41": "mistfresh", "42": "superdry", "43": "lowtempdryplus", "44": "ai_course",
       "45": "silent", "46": "clothcare", "47": "wrinklefree", "48": "lightbedding",
       "49": "gymclothes", "50": "rainyday", "51": "easyiron", "52": "duvet_cover",
       "53": "blanketrefresh", "54": "overnightdry", "55": "halfloaddry", "56": "fullloaddry",
       "57": "dehumidification", "58": "turbodry" }
}

fn lcd_themes() {
    #{ "0": "default", "1": "winter_1", "2": "winter_2", "3": "winter_3", "4": "spring_1",
       "5": "spring_2", "6": "summer_1", "7": "summer_2", "8": "fall_1", "9": "halloween",
       "10": "new_years", "11": "christmas", "12": "none" }
}

fn sel(table) { #{ type: "select", options: t::options(table) } }
fn duration() { #{ type: "number", class: "duration", unit: "min" } }
fn diag(p) { p.category = "diagnostic"; p }

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        washer_power: #{ type: "binary", rw: true, class: "running", label: "Washer powered on" },
        washer_state: sel(washer_states()),
        washer_course: sel(washer_courses()),
        washer_soil_wash: sel(washer_soils()),
        washer_temp: sel(washer_temps()),
        washer_rinse: sel(washer_rinses()),
        washer_spin: sel(washer_spins()),
        washer_soak: sel(washer_soaks()),
        washer_water_level: sel(washer_water_levels()),
        washer_load_item: sel(washer_load_items()),
        washer_load_level: sel(washer_load_levels()),
        washer_rinse_count: sel(washer_rinse_counts()),
        washer_laundry_texture: #{ type: "number", category: "diagnostic" },
        washer_reserve_time: duration(),
        washer_remaining_time: duration(),
        washer_initial_time: duration(),
        washer_energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh" },
        washer_error: diag(sel(washer_errors())),
        washer_buzzer: #{ type: "select", rw: true, requires: "washer_power", category: "config", options: t::options(buzzers()) },
        washer_door: #{ type: "binary", class: "door", label: "Washer door open" },
        washer_door_lock: diag(#{ type: "binary" }),
        washer_add_garment: #{ type: "binary" },
        washer_child_lock: diag(#{ type: "binary" }),
        washer_remote_start: diag(#{ type: "binary" }),
        washer_remote_maintain: #{ type: "binary", rw: true, requires: "washer_power" },
        dryer_power: #{ type: "binary", rw: true, class: "running", label: "Dryer powered on" },
        dryer_state: sel(dryer_states()),
        dryer_course: sel(dryer_courses()),
        dryer_dry_level: sel(dryer_dry_levels()),
        dryer_temp: sel(dryer_temps()),
        dryer_time_dry: sel(dryer_time_dries()),
        dryer_reserve_time: duration(),
        dryer_remaining_time: duration(),
        dryer_initial_time: duration(),
        dryer_error: diag(sel(dryer_errors())),
        dryer_buzzer: #{ type: "select", rw: true, requires: "dryer_power", category: "config", options: t::options(buzzers()) },
        dryer_door: #{ type: "binary", class: "door", label: "Dryer door open" },
        dryer_duct_clogging: diag(sel(dryer_duct_cloggings())),
        dryer_child_lock: diag(#{ type: "binary" }),
        dryer_remote_start: diag(#{ type: "binary" }),
        dryer_remote_maintain: #{ type: "binary", rw: true, requires: "dryer_power" },
        init_lcd: #{ type: "select", rw: true, requires: "washer_power", category: "config", label: "Display theme",
                     options: t::options(lcd_themes()) }
    };
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "WashTower", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn start(ctx) { ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x11, 0x21, 0x01, 0x00, 0x00, 0x00, 0x18, 0x00])); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn u16be(b, o) { (b[o] * 256 + b[o + 1]).to_string() }

fn on_data(ctx, data) {
    let b = aabb_unwrap(data);
    if b == () || b.len() < 14 { return; }
    let body = b.extract(13, b.len() - 14);
    switch b[3] {
        0x42 => { if body.len() == 48 { il::publish_property(ctx, "washer_door", if body[5] != 0 { "false" } else { "true" }); } }
        0x4e => { if body.len() == 60 { il::publish_property(ctx, "dryer_door", if body[16] != 0 { "true" } else { "false" }); } }
        0x71 => { if body.len() == 95 { block(ctx, body); } }
        0xd0 => { if body.len() == 190 { block(ctx, body.extract(95, 95)); } }
        _ => {}
    }
}

fn block(ctx, k) {
    il::publish_property(ctx, "available", "true");
    c::pub_name(ctx, "washer_soil_wash", t::name(washer_soils(), k[3]));
    c::pub_name(ctx, "washer_temp", t::name(washer_temps(), k[4]));
    c::pub_name(ctx, "washer_rinse", t::name(washer_rinses(), k[5]));
    c::pub_name(ctx, "washer_spin", t::name(washer_spins(), k[6]));
    c::pub_name(ctx, "washer_course", t::name(washer_courses(), k[7]));
    c::pub_name(ctx, "washer_soak", t::name(washer_soaks(), k[9]));
    c::pub_name(ctx, "washer_water_level", t::name(washer_water_levels(), k[11]));
    c::pub_name(ctx, "washer_load_item", t::name(washer_load_items(), k[12]));
    il::publish_property(ctx, "washer_reserve_time", u16be(k, 13));
    il::publish_property(ctx, "washer_remaining_time", u16be(k, 15));
    il::publish_property(ctx, "washer_initial_time", u16be(k, 17));
    il::publish_property(ctx, "washer_energy", u16be(k, 19));
    c::pub_name(ctx, "washer_load_level", t::name(washer_load_levels(), k[26]));
    c::pub_name(ctx, "washer_rinse_count", t::name(washer_rinse_counts(), k[29]));
    il::publish_property(ctx, "washer_laundry_texture", k[43].to_string());
    c::pub_name(ctx, "init_lcd", t::name(lcd_themes(), k[48]));
    il::publish_property(ctx, "washer_power", if k[23] != 0 { "true" } else { "false" });
    c::pub_name(ctx, "washer_state", t::name(washer_states(), k[23]));
    c::pub_name(ctx, "washer_error", t::name(washer_errors(), k[21]));
    c::pub_name(ctx, "washer_buzzer", t::name(buzzers(), k[31]));
    il::publish_property(ctx, "washer_add_garment", c::bit(k[39], 0x80));
    il::publish_property(ctx, "washer_child_lock", c::bit(k[39], 0x20));
    il::publish_property(ctx, "washer_remote_start", c::bit(k[39], 0x10));
    il::publish_property(ctx, "washer_door_lock", c::bit(k[40], 0x01));
    il::publish_property(ctx, "washer_remote_maintain", c::bit(k[42], 0x04));

    c::pub_name(ctx, "dryer_dry_level", t::name(dryer_dry_levels(), k[54]));
    c::pub_name(ctx, "dryer_temp", t::name(dryer_temps(), k[56]));
    c::pub_name(ctx, "dryer_time_dry", t::name(dryer_time_dries(), k[57]));
    c::pub_name(ctx, "dryer_course", t::name(dryer_courses(), k[58]));
    il::publish_property(ctx, "dryer_reserve_time", u16be(k, 60));
    il::publish_property(ctx, "dryer_remaining_time", u16be(k, 62));
    il::publish_property(ctx, "dryer_initial_time", u16be(k, 64));
    il::publish_property(ctx, "dryer_power", if k[66] != 0 { "true" } else { "false" });
    c::pub_name(ctx, "dryer_state", t::name(dryer_states(), k[66]));
    c::pub_name(ctx, "dryer_error", t::name(dryer_errors(), k[68]));
    c::pub_name(ctx, "dryer_buzzer", t::name(buzzers(), k[72]));
    c::pub_name(ctx, "dryer_duct_clogging", t::name(dryer_duct_cloggings(), k[75]));
    il::publish_property(ctx, "dryer_remote_start", c::bit(k[79], 0x40));
    il::publish_property(ctx, "dryer_child_lock", c::bit(k[79], 0x10));
    il::publish_property(ctx, "dryer_remote_maintain", c::bit(k[80], 0x02));
}

fn field(ctx, unit, f, v) { ctx.send_raw(aabb_wrap([0xf0, 0xe5, 0x00, 0x02, 0x01, unit, 0x01, f, v])); }

fn set_property(ctx, prop, value) {
    switch prop {
        "washer_power" => field(ctx, washer_unit(), 0x02, if c::to_bool(value) { 1 } else { 0 }),
        "dryer_power" => field(ctx, dryer_unit(), 0x02, if c::to_bool(value) { 1 } else { 0 }),
        "washer_buzzer" => field(ctx, washer_unit(), 0x13, t::code(buzzers(), value)),
        "dryer_buzzer" => field(ctx, dryer_unit(), 0x13, t::code(buzzers(), value)),
        "init_lcd" => field(ctx, washer_unit(), 0x51, t::code(lcd_themes(), value)),
        "washer_remote_maintain" => ctx.send_raw(aabb_wrap([0xf0, 0x24, 0x10, 0x01, if c::to_bool(value) { 1 } else { 0 }, washer_unit()])),
        "dryer_remote_maintain" => ctx.send_raw(aabb_wrap([0xf0, 0x24, 0x10, 0x01, if c::to_bool(value) { 1 } else { 0 }, dryer_unit()])),
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
