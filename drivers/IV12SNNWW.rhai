// LG robot vacuum IV12SNNWW (CordZero RoboKing AI all-in-one, ThinQ device type 501, "RK"
// platform): a JSON-protocol ThinQ2 appliance. Reports arrive as CLIP device packets
// whose AA..BB frame carries JSON - a delta under "mon" ({"mon":{"BATT_P":"88"}}) or,
// right after connecting, the full monitoring object. Controls go out as CLIP
// "rkControl" packets {Cmd:"Control", CmdOpt:"Set", Value:...}.
//
// Sources (2026-11-06):
//   - Wire captures on the real appliance (2026-11-05/06) for every control shape.
//   - The device's official app assets from the LG ThinQ service (modelJson, Korean
//     language pack, app module): labels and state names below are English renderings of the app's own (Korean) wording, and every
//     control Value follows modelJson ControlWifi, and the "allowed in which state"
//     rules follow the app's STATE_CATEGORY switch (which buttons it disables).
//
// Value shapes (captured, and matching ControlWifi): action commands are plain strings
// ("CLEAN_START"); enum settings are objects ({"SUCTION_LEVEL":"STRONG"}; water and
// volume carry their WATER_SUPPLY_ / VOLUME_ prefix); boolean settings are a JSON
// string ("{\"LIGHT\":\"false\"}"). Every control carries clientId and messageId -
// the appliance ignores a Set without them (verified live 2026-11-06).
//
// Map data (RT_MAP / RT_POSE / FLOORMAP / VW) and, while docked, most state travel in
// publishes outside CLIP; the daemon relays those to LG and this driver never sees them.
import "il_common" as il;

// ---- official wording (modelJson Value + language pack) -------------------------------

fn states() {
    #{ "STANDBY": "standby", "PAUSE": "pause", "PAUSE_EDGE": "paused",
       "PAUSE_SPIRAL": "paused", "PAUSE_ZIGZAG": "paused", "PAUSE_SELECT": "paused",
       "PAUSE_LEARNING": "pause", "PAUSE_SELECT_GOZONE": "pause", "HOMING_PAUSE": "paused",
       "BACKMOVING_JOY": "preparing", "BACKMOVING_INIT": "preparing", "MONITORING": "preparing",
       "INITAILIZING": "preparing", "RECOVERY_WORKING": "preparing",
       "CHARGING": "charging", "FINISHED_CHARGING": "charging_complete",
       "HOMING": "returning_to_dock", "HOMING_LEARNING": "returning_to_dock", "DOCKING": "returning_to_dock",
       "RECOVERY_HOMING": "returning_to_dock",
       "WORKING": "cleaning", "CLEAN_EDGE": "edge_cleaning", "CLEAN_SPIRAL": "spot_cleaning",
       "CLEAN_SELECT": "room_cleaning", "CLEAN_SPECIFIED": "zone_cleaning",
       "CLEAN_SELECT_GOZONE": "zone_cleaning", "CLEAN_ZIGZAG": "quick_cleaning",
       "CLEAN_LEARNING": "mapping", "CLEAN_MYSPOT": "area_cleaning",
       "DIAGNOSIS": "smart_diagnosis", "MONITORING_POSITIONING": "homeguard_positioning",
       "MONITORING_MOVING": "moving_to_position", "MONITORING_DETECTING": "homeguard",
       "SETDATE": "remote_control", "MACROSECTOR": "remote_control", "RESERVATION": "remote_control",
       "SLEEP": "power_saving", "WATER_REMOVAL": "draining_water", "MYSPOT_RECORDING": "area_recording",
       "STATION": "emptying_dustbin", "STATION_MOP": "mop_washing", "STATION_DRY": "mop_drying",
       "REPOSITIONING": "positioning", "WATER_INJECTION": "filling_water" }
}

fn state_options() {
    ["standby", "cleaning", "quick_cleaning", "edge_cleaning", "spot_cleaning", "room_cleaning",
     "zone_cleaning", "area_cleaning", "mapping", "pause", "paused", "preparing",
     "returning_to_dock", "charging", "charging_complete", "emptying_dustbin", "mop_washing", "mop_drying",
     "filling_water", "draining_water", "power_saving", "smart_diagnosis", "positioning",
     "remote_control", "homeguard_positioning", "moving_to_position", "homeguard", "area_recording"]
}

// The app's STATE_CATEGORY for each raw state (its getRobotStateInfo switch).
fn categories() {
    #{ "STANDBY": "standby",
       "BACKMOVING_JOY": "prepare", "BACKMOVING_INIT": "prepare", "MONITORING": "prepare",
       "INITAILIZING": "prepare", "REPOSITIONING": "prepare",
       "MONITORING_POSITIONING": "homeguard", "MONITORING_MOVING": "homeguard",
       "MONITORING_DETECTING": "homeguard",
       "RECOVERY_WORKING": "cleaning", "WORKING": "cleaning", "CLEAN_SELECT": "cleaning",
       "CLEAN_SPECIFIED": "cleaning", "CLEAN_SPIRAL": "cleaning", "CLEAN_ZIGZAG": "cleaning",
       "CLEAN_EDGE": "cleaning", "CLEAN_LEARNING": "cleaning", "CLEAN_SELECT_GOZONE": "cleaning",
       "CLEAN_MYSPOT": "cleaning", "MYSPOT_RECORDING": "cleaning",
       "PAUSE": "pause", "PAUSE_LEARNING": "pause", "PAUSE_SELECT_GOZONE": "pause",
       "PAUSE_EDGE": "pause", "PAUSE_SPIRAL": "pause", "PAUSE_ZIGZAG": "pause",
       "PAUSE_SELECT": "pause", "HOMING_PAUSE": "pause",
       "CHARGING": "charging", "FINISHED_CHARGING": "charging",
       "HOMING": "homing", "DOCKING": "homing", "RECOVERY_HOMING": "homing", "HOMING_LEARNING": "homing",
       "DIAGNOSIS": "diagnosis", "SETDATE": "remote", "MACROSECTOR": "remote", "RESERVATION": "remote",
       "SLEEP": "sleep", "WATER_REMOVAL": "water_removal", "STATION": "station",
       "STATION_MOP": "station_mop", "STATION_DRY": "station_dry", "WATER_INJECTION": "water_injection" }
}

// Which control group the app leaves enabled in each category (disabledCleaningButton,
// disabledChargeButton, disabledCleanModeButton, disabledSimpleControlButton,
// listDimmed); "error" is the app's STATE_ERROR (an emergency is active).
fn allowed() {
    #{ clean: ["standby", "cleaning", "pause", "charging", "station_dry"],
       pause: ["cleaning", "homing"],
       charge: ["standby", "pause", "homing"],
       mode: ["standby", "pause", "charging"],
       simple: ["standby", "cleaning", "pause", "charging", "homing"],
       settings: ["standby", "cleaning", "pause", "charging", "homing", "station", "station_mop",
                  "station_dry", "water_injection", "error"],
       station: ["charging"],
       dry_stop: ["station_dry"],
       find: ["standby", "cleaning", "pause", "charging", "homing", "station", "station_mop",
              "station_dry", "water_injection", "error", "prepare"] }
}

fn prop_group() {
    #{ clean_start: "clean", clean_stop: "clean", spot_clean: "clean", pause: "pause",
       homing: "charge", clean_type: "mode", clean_distance: "mode",
       suction: "simple", water_supply: "simple", smart_turbo: "simple",
       volume: "settings", light_mode: "settings", button_lock: "settings",
       reclean_mode: "settings", ai_detection: "settings",
       station_empty: "station", mop_wash: "station", mop_dry: "station",
       mop_dry_stop: "dry_stop", find_robot: "find" }
}

fn emergencies() {
    #{ "E_BUMPER_STUCK": "The bumper is pressed. Check the robot.",
       "E_WHEEL_STUCK": "The wheels have a problem and the robot cannot move. Remove debris from the wheels.",
       "E_MOP_STUCK": "There is a problem with the mop plate rotation.",
       "E_SIDEBRUSH_STUCK": "The brush has a problem and the robot cannot move. Remove debris from the side brush.",
       "E_ROLLBRUSH_STUCK": "The floor brush has a problem and the robot cannot move. Remove debris from the brush.",
       "E_ROBOT_STUCK": "Cleaning cannot continue. Check the area around the robot.",
       "E_ROBOT_LIFT": "The wheels are not touching the floor. Move the robot to a flat floor.",
       "E_WHEEL_LIFT": "The wheels are not touching the floor. Move the robot to a flat floor.",
       "E_BATTERY_LOW": "Move the robot to the dock and charge it.",
       "E_MAGNETIC_DISRUPT": "Cleaning cannot continue. Check the area around the robot.",
       "E_IRSENSOR_BLOCK": "The obstacle sensor window has a problem and the robot cannot move. Wipe the obstacle sensor window.",
       "E_WALLSENSORR_BLOCK": "The obstacle sensor window has a problem and the robot cannot move. Wipe the obstacle sensor window.",
       "E_ROBOT_TILT": "Cleaning cannot continue. Move the robot to a flat floor.",
       "E_DUSTBIN_OFF": "Cleaning cannot start without the dustbin. Install the dustbin.",
       "E_RESTRICTED_NEAR": "The robot is inside a no-go area and cannot clean. Check the robot's position.",
       "E_LASERCOVER_STUCK": "The lidar sensor cover is pressed and the robot cannot move. Check the top lidar sensor cover.",
       "E_LASERSENSOR_STUCK": "The lidar sensor has a problem and the robot cannot move. Remove any debris around the lidar sensor.",
       "E_LASERSENSOR_BLOCK": "The lidar sensor has a problem and the robot cannot move. Remove any debris around the lidar sensor.",
       "E_BATTERY_ERROR": "There is a problem with the battery.",
       "E_SUCTIONFAN_ERROR": "There is a problem with the suction motor.",
       "E_WATERPUMP_ERROR": "There is a problem with the pump motor.",
       "E_CLIFFSENSOR_BLOCK": "The cliff sensor has a problem and the robot cannot move. Wipe the cliff sensor.",
       "E_WHEEL_ERROR": "There is a problem with the wheel motor.",
       "E_SIDEBRUSH_ERROR": "There is a problem with the side brush motor.",
       "E_ROLLBRUSH_ERROR": "There is a problem with the brush motor.",
       "E_WALLSENSOR_ERROR": "There is a problem with the right wall sensor.",
       "E_3DSENSOR_ERROR": "There is a problem with the camera sensor.",
       "E_LASERSENSOR_ERROR": "There is a problem with the lidar sensor.",
       "E_CLIFFSENSOR_ERROR": "There is a problem with the cliff sensor.",
       "E_OBSTSENSOR_ERROR": "There is a problem with the obstacle sensor.",
       "E_WALLSENSOR_BLOCK": "The right wall sensor has a problem and the robot cannot move. Wipe the right wall sensor window.",
       "E_3DSENSOR_BLOCK": "The camera sensor has a problem and the robot cannot move. Wipe the camera sensor window.",
       "E_MOP_ERROR": "There is a problem with the mop plate motor.",
       "E_MOP_DETACHED": "Cleaning stopped because the mop came off. Attach the mop securely.",
       "E_TEMP_ERROR": "There is a problem with the robot's temperature.",
       "E_SYSTEM_ERROR": "There is a problem with the system." }
}

fn clean_modes() {
    #{ "ZZ": "zigzag", "SB": "deep", "SPOT": "spot", "MACRO": "all", "EDGE": "deep",
       "SELECT": "selected_area", "MY": "my_area", "GYRO": "gyro", "DEEP": "deep_clean",
       "AREA": "area", "CUSTOM": "custom" }
}

fn suction_levels() { #{ "NONE": "none", "QUIET": "low", "STANDARD": "medium", "STRONG": "high", "MAX": "turbo" } }
fn suction_wires() { #{ "low": "QUIET", "medium": "STANDARD", "high": "STRONG", "turbo": "MAX" } }
fn water_levels() { #{ "DRY": "dry", "LOW": "low", "LOW1": "normal", "HIGH": "high" } }
fn water_wires() { #{ "dry": "DRY", "low": "LOW", "normal": "LOW1", "high": "HIGH" } }
fn volume_levels() { #{ "MUTE": "mute", "LOW": "low", "MEDIUM": "normal", "HIGH": "high" } }
fn volume_wires() { #{ "mute": "MUTE", "low": "LOW", "normal": "MEDIUM", "high": "HIGH" } }
fn clean_types() { #{ "ALL": "vacuum_and_mop", "SUCTION": "vacuum", "MOP": "mop" } }
fn clean_type_wires() { #{ "vacuum_and_mop": "ALL", "vacuum": "SUCTION", "mop": "MOP" } }
fn dist_levels() { #{ "QUICK": "wide", "NORMAL": "normal", "DEEP": "narrow", "DEEPSLOW": "deep+" } }
fn dist_wires() { #{ "wide": "QUICK", "normal": "NORMAL", "narrow": "DEEP", "deep+": "DEEPSLOW" } }
fn station_modes() { #{ "AUTO": "auto", "MANUAL": "manual" } }
fn update_states() {
    #{ "IDLE": "standby", "DOWNLOADING": "downloading", "COMPLETE": "complete",
       "MD5_FAILED": "verification_failed", "DOWNLOAD_FAILED": "download_failed" }
}

// ---- descriptor ---------------------------------------------------------------------

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        state: #{ type: "select", role: "state", options: state_options(), label: "State" },
        state_raw: #{ type: "text", category: "diagnostic", label: "State (raw)" },
        error: #{ type: "binary", class: "problem", label: "Error present" },
        error_code: #{ type: "text", category: "diagnostic", label: "Error code (raw)" },
        error_message: #{ type: "text", label: "Error message" },
        last_reject: #{ type: "text", category: "diagnostic", label: "Last rejection reason" },
        battery: #{ type: "number", unit: "%", min: 0, max: 100, label: "Battery" },
        clean_mode: #{ type: "select", label: "Clean mode",
                       options: ["zigzag", "deep", "spot", "all", "selected_area", "my_area",
                                 "gyro", "deep_clean", "area", "custom"] },
        suction: #{ type: "select", label: "Suction", rw: true, options: ["low", "medium", "high", "turbo", "none"] },
        water_supply: #{ type: "select", label: "Water supply", rw: true, options: ["dry", "low", "normal", "high"] },
        volume: #{ type: "select", category: "config", label: "Volume", rw: true,
                   options: ["mute", "low", "normal", "high"] },
        clean_type: #{ type: "select", label: "Clean type", rw: true, options: ["vacuum_and_mop", "vacuum", "mop"] },
        clean_distance: #{ type: "select", label: "Clean distance", rw: true, options: ["wide", "normal", "narrow", "deep+"] },
        smart_turbo: #{ type: "binary", label: "Smart turbo", rw: true },
        sleep_mode: #{ type: "binary", category: "config", label: "Power saving mode" },
        button_lock: #{ type: "binary", category: "config", label: "Button lock", rw: true },
        reclean_mode: #{ type: "binary", category: "config", label: "Resume cleaning automatically", rw: true },
        light_mode: #{ type: "binary", category: "config", label: "Light", rw: true },
        ai_detection: #{ type: "binary", category: "config", label: "AI obstacle avoidance", rw: true },
        carpet_avoid: #{ type: "text", category: "diagnostic", label: "Carpet clean type (raw)" },
        station_mode: #{ type: "select", category: "config", label: "Auto dust emptying", options: ["auto", "manual"] },
        clean_time: #{ type: "number", class: "duration", unit: "min", label: "Clean time" },
        clean_where: #{ type: "number", category: "diagnostic", label: "Clean position" },
        maint_main_brush: #{ type: "number", category: "diagnostic", label: "Main brush wear" },
        maint_side_brush: #{ type: "number", category: "diagnostic", label: "Side brush wear" },
        maint_filter: #{ type: "number", category: "diagnostic", label: "Filter wear" },
        maint_mop: #{ type: "number", category: "diagnostic", label: "Mop wear" },
        maint_dust_bag: #{ type: "number", category: "diagnostic", label: "Dust bag wear" },
        update: #{ type: "select", category: "diagnostic", label: "Firmware update",
                   options: ["standby", "downloading", "complete", "verification_failed", "download_failed"] },
        update_progress: #{ type: "number", category: "diagnostic", unit: "%", label: "Update progress" },
        product_version: #{ type: "number", category: "diagnostic", label: "Firmware version" },
        language: #{ type: "text", category: "diagnostic", label: "Language" },
        robot_event: #{ type: "text", category: "diagnostic", label: "Robot event" },
        clean_order: #{ type: "text", category: "diagnostic", label: "Clean order (JSON)" },
        reservation: #{ type: "text", category: "diagnostic", label: "Reservation (JSON)" },
        do_not_disturb: #{ type: "text", category: "diagnostic", label: "Do not disturb (JSON)" },
        clean_start: #{ type: "trigger", label: "Start cleaning" },
        pause: #{ type: "trigger", label: "Pause cleaning" },
        clean_stop: #{ type: "trigger", label: "Stop cleaning" },
        homing: #{ type: "trigger", label: "Return to dock" },
        spot_clean: #{ type: "trigger", label: "Start spot cleaning" },
        station_empty: #{ type: "trigger", label: "Empty dustbin" },
        mop_wash: #{ type: "trigger", label: "Wash mop now" },
        mop_dry: #{ type: "trigger", label: "Dry mop now" },
        mop_dry_stop: #{ type: "trigger", label: "mop_drying_finished" },
        find_robot: #{ type: "trigger", label: "Find robot" }
    };
    json_stringify(#{ il: 0, kind: "vacuum", label: "Robot vacuum", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

// ---- kept state -----------------------------------------------------------------------

// The appliance pushes only deltas and no status query is known, so a hot reload (which
// re-announces the entities) would leave them empty until each value next changes.
// Every published value is kept in driver state and republished here; nothing is sent.
fn start(ctx) {
    let keys = ctx.state_get("kept3_keys");
    if keys == () { return; }
    for k in keys.split(",") {
        if k == "" { continue; }
        let v = ctx.state_get("kept3_" + k);
        if v != () { il::publish_property(ctx, k, v); }
    }
}

fn pubp(ctx, prop, value) {
    il::publish_property(ctx, prop, value);
    ctx.state_set("kept3_" + prop, value);
    let keys = ctx.state_get("kept3_keys");
    if keys == () { keys = ""; }
    if !("," + keys + ",").contains("," + prop + ",") {
        ctx.state_set("kept3_keys", if keys == "" { prop } else { keys + "," + prop });
    }
}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

// ---- payload walking ------------------------------------------------------------------

fn get2(s, key) {
    if type_of(s) != "map" { return (); }
    if s.contains(key) { return s[key]; }
    for v in s.values() {
        if type_of(v) == "map" && v.contains(key) { return v[key]; }
    }
    ()
}

fn num_text(v) {
    if type_of(v) == "i64" { return v.to_string(); }
    if type_of(v) == "f64" {
        if v == v.floor() { return v.to_int().to_string(); }
        return v.to_string();
    }
    if type_of(v) == "string" {
        let n = (); try { n = v.parse_float(); } catch {}
        if n != () { return num_text(n); }
    }
    ()
}

// MAINT_* values arrive as "used|total" strings; publish the used figure.
fn maint_text(v) {
    if type_of(v) == "string" && v.contains("|") { return num_text(v.split("|")[0]); }
    num_text(v)
}

fn bool_text(v) {
    if type_of(v) == "bool" { return v.to_string(); }
    if type_of(v) == "i64" { return if v != 0 { "true" } else { "false" }; }
    if type_of(v) == "string" {
        let t = v.to_lower();
        if ["true", "on", "1"].contains(t) { return "true"; }
        if ["false", "off", "0"].contains(t) { return "false"; }
    }
    ()
}

fn pub_num(ctx, s, key, prop) { let v = num_text(get2(s, key)); if v != () { pubp(ctx, prop, v); } }
fn pub_maint(ctx, s, key, prop) { let v = maint_text(get2(s, key)); if v != () { pubp(ctx, prop, v); } }
fn pub_bool(ctx, s, key, prop) { let v = bool_text(get2(s, key)); if v != () { pubp(ctx, prop, v); } }

fn pub_bool_any(ctx, s, keys, prop) {
    for key in keys {
        let v = bool_text(get2(s, key));
        if v != () { pubp(ctx, prop, v); return; }
    }
}

// Enum reports may carry the wire prefix (WATER_SUPPLY_LOW1, VOLUME_HIGH); strip it.
fn pub_enum(ctx, s, key, prop, table, prefix) {
    let raw = get2(s, key);
    if type_of(raw) != "string" { return; }
    if prefix != "" && raw.starts_with(prefix) { raw = raw.sub_string(prefix.len()); }
    let name = table[raw];
    if name != () { pubp(ctx, prop, name); }
}

fn pub_raw(ctx, s, key, prop) {
    let v = get2(s, key);
    if v == () { return; }
    if type_of(v) == "string" { pubp(ctx, prop, v); }
    else if type_of(v) == "array" {
        let w = json_stringify(#{ v: v });
        pubp(ctx, prop, w[5..w.len() - 1]);
    }
    else { pubp(ctx, prop, json_stringify(v)); }
}

fn on_data(ctx, data) {
    let start = -1;
    for i in 0..data.len() { if data[i] == 123 { start = i; break; } }
    if start < 0 { return; }
    ctx.state_set("rx_seed", crc16(data));
    let end = -1;
    let idx = data.len() - 1;
    while idx > start { if data[idx] == 125 { end = idx; break; } idx -= 1; }
    if end < 0 { return; }
    let text = ""; try { text = bytes_utf8(data.extract(start, end - start + 1)); } catch { return; }
    let s = (); try { s = json_parse(text); } catch { return; }
    if type_of(s) != "map" { return; }
    if s.contains("controlResult") { return; }
    let body = if type_of(s["mon"]) == "map" { s["mon"] } else { s };
    let known = false;
    for k in ["ROBOT_STATE", "BATT_P", "MODE", "SUCTION_LEVEL", "WATERSUPPLY_LEVEL",
              "VOLUME_LEVEL", "CLEAN_TYPE", "ZZ_DIST", "STATION_SET", "SMART_TURBO", "BUTTON_LOCK",
              "RECLEAN", "TOGGLE_RECLEAN", "LIGHT", "AI_DETECTION", "MAINT_FILTER", "UPDATE", "EMERGENCY",
              "UTC_SLEEPMODE", "SLEEP_MODE", "CARPET_AVOID", "CLEAN_TIME", "CLEAN_WHERE",
              "MAINT_MAINBRUSH", "MAINT_SIDEBRUSH", "MAINT_MOP", "MAINT_DUSTBAG", "VERSION",
              "LANGUAGE", "ROBOT_EVENT", "CLEAN_ORDER", "CLEANING_RSV", "DND_INFO"] {
        if get2(body, k) != () { known = true; break; }
    }
    if !known { return; }
    pubp(ctx, "available", "true");

    let state_holder = get2(body, "ROBOT_STATE");
    let emergency = get2(body, "EMERGENCY");
    let state_raw = ();
    if type_of(state_holder) == "string" { state_raw = state_holder; }
    else if type_of(state_holder) == "map" {
        if type_of(state_holder["ROBOT_STATE"]) == "string" { state_raw = state_holder["ROBOT_STATE"]; }
        if emergency == () && state_holder.contains("EMERGENCY") { emergency = state_holder["EMERGENCY"]; }
    }
    if state_raw != () {
        ctx.state_set("raw_state", state_raw);
        pubp(ctx, "state_raw", state_raw);
        let name = states()[state_raw];
        if name != () { pubp(ctx, "state", name); }
    }
    if type_of(emergency) == "string" {
        ctx.state_set("emergency", emergency);
        pubp(ctx, "error_code", emergency);
        pubp(ctx, "error", if emergency == "NONE" { "false" } else { "true" });
        let msg = emergencies()[emergency];
        pubp(ctx, "error_message", if emergency == "NONE" { "none" } else if msg != () { msg } else { emergency });
    }

    pub_num(ctx, body, "BATT_P", "battery");
    pub_enum(ctx, body, "MODE", "clean_mode", clean_modes(), "");
    pub_enum(ctx, body, "SUCTION_LEVEL", "suction", suction_levels(), "");
    pub_enum(ctx, body, "WATERSUPPLY_LEVEL", "water_supply", water_levels(), "WATER_SUPPLY_");
    pub_enum(ctx, body, "VOLUME_LEVEL", "volume", volume_levels(), "VOLUME_");
    pub_enum(ctx, body, "CLEAN_TYPE", "clean_type", clean_types(), "");
    pub_enum(ctx, body, "ZZ_DIST", "clean_distance", dist_levels(), "");
    pub_enum(ctx, body, "STATION_SET", "station_mode", station_modes(), "");
    pub_bool(ctx, body, "SMART_TURBO", "smart_turbo");
    pub_bool_any(ctx, body, ["UTC_SLEEPMODE", "SLEEP_MODE"], "sleep_mode");
    pub_bool(ctx, body, "BUTTON_LOCK", "button_lock");
    // The report carries both RECLEAN and TOGGLE_RECLEAN; the app's setting is
    // TOGGLE_RECLEAN (ControlWifi SetToggleReclean, cross-checked with the cloud).
    pub_bool_any(ctx, body, ["TOGGLE_RECLEAN", "RECLEAN"], "reclean_mode");
    pub_bool(ctx, body, "LIGHT", "light_mode");
    pub_bool(ctx, body, "AI_DETECTION", "ai_detection");
    pub_raw(ctx, body, "CARPET_AVOID", "carpet_avoid");
    pub_num(ctx, body, "CLEAN_TIME", "clean_time");
    pub_num(ctx, body, "CLEAN_WHERE", "clean_where");
    pub_maint(ctx, body, "MAINT_MAINBRUSH", "maint_main_brush");
    pub_maint(ctx, body, "MAINT_SIDEBRUSH", "maint_side_brush");
    pub_maint(ctx, body, "MAINT_FILTER", "maint_filter");
    pub_maint(ctx, body, "MAINT_MOP", "maint_mop");
    pub_maint(ctx, body, "MAINT_DUSTBAG", "maint_dust_bag");
    pub_num(ctx, body, "VERSION", "product_version");
    pub_raw(ctx, body, "LANGUAGE", "language");
    pub_raw(ctx, body, "ROBOT_EVENT", "robot_event");
    pub_raw(ctx, body, "CLEAN_ORDER", "clean_order");
    pub_raw(ctx, body, "CLEANING_RSV", "reservation");
    pub_raw(ctx, body, "DND_INFO", "do_not_disturb");

    let upd = get2(body, "UPDATE");
    if type_of(upd) == "string" {
        let name = update_states()[upd];
        if name != () { pubp(ctx, "update", name); }
    } else if type_of(upd) == "map" {
        if type_of(upd["UPDATE"]) == "string" {
            let name = update_states()[upd["UPDATE"]];
            if name != () { pubp(ctx, "update", name); }
        }
        let p = num_text(upd["DownloadProgress"]);
        if p != () { pubp(ctx, "update_progress", p); }
    }
}

// ---- state gating (the app's disabled-button rules) ------------------------------------

fn current_category(ctx) {
    let e = ctx.state_get("emergency");
    if e != () && e != "NONE" { return "error"; }
    let raw = ctx.state_get("raw_state");
    if raw == () { return (); }
    categories()[raw]
}

// Returns a refusal message, or () when the control is allowed. An unknown state (no
// report since attach) allows everything rather than blocking blindly.
fn refusal(ctx, prop) {
    let group = prop_group()[prop];
    if group == () { return (); }
    let cat = current_category(ctx);
    if cat == () { return (); }
    let raw = ctx.state_get("raw_state");
    // App rule: focus (spot) cleaning cannot start while charging.
    if prop == "spot_clean" && cat == "charging" { return "Spot cleaning is not available while charging."; }
    if allowed()[group].contains(cat) { return (); }
    let label = if cat == "error" { "Error" } else { states()[raw] };
    if label == () { label = raw; }
    if group == "station" { return "Only available while the robot is docked (current: " + label + ")"; }
    if group == "mode" && cat == "cleaning" { return "Cannot be set while cleaning. Try again after cleaning finishes."; }
    "Not available now (current: " + label + ")"
}

// ---- writes ---------------------------------------------------------------------------

fn client_id() { "79b237256c9129df9f43207e279b4cf240926a6f3734d960740cd2b3846f748a" }

fn message_id(ctx) {
    // No clock in the engine: a per-driver counter mixed with the CRC of the last report
    // received keeps ids unique across daemon restarts in practice.
    let n = ctx.state_get("msg_seq");
    if n == () { n = 0; }
    n += 1;
    ctx.state_set("msg_seq", n);
    let seed = ctx.state_get("rx_seed");
    if seed == () { seed = 0; }
    let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    let v = seed * 1000003 + n;
    let id = "rhq";
    for i in 0..19 {
        id += alphabet.sub_string(v % 62, 1);
        v = v / 62 + (i + 1) * 7919 + n;
    }
    id
}

fn rk_set(ctx, value) {
    ctx.send_clip("rkControl", 0, json_stringify(#{ Cmd: "Control", CmdOpt: "Set", Value: value,
                                                    clientId: client_id(), messageId: message_id(ctx) }));
}

fn rk_set_bool(ctx, key, value) {
    let inner = #{}; inner[key] = value;
    rk_set(ctx, json_stringify(inner));
}

fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value == () { return; }
    let why = refusal(ctx, prop);
    if why != () {
        il::publish_property(ctx, "last_reject", why);
        il::reject(ctx, prop, "not_now", why);
        return;
    }
    switch prop {
        "clean_start" => rk_set(ctx, "CLEAN_START"),
        "pause" => rk_set(ctx, "PAUSE"),
        "clean_stop" => rk_set(ctx, "CLEAN_STOP"),
        "homing" => rk_set(ctx, "HOMING"),
        "spot_clean" => rk_set(ctx, "CLEAN_START_SPOT"),
        "station_empty" => rk_set(ctx, "STATION_START"),
        "mop_wash" => rk_set(ctx, "MOPWASH_START"),
        "mop_dry" => rk_set(ctx, "MOPDRY_START"),
        "mop_dry_stop" => rk_set(ctx, "MOPDRY_STOP"),
        "find_robot" => rk_set(ctx, "WHERE_IS_ROBOT"),
        "suction" => {
            let wire = suction_wires()[value];
            if wire == () { il::reject(ctx, prop, "read_only", "'none' cannot be set."); return; }
            rk_set(ctx, #{ SUCTION_LEVEL: wire });
        }
        "water_supply" => rk_set(ctx, #{ WATER_SUPPLY_LEVEL: "WATER_SUPPLY_" + water_wires()[value] }),
        "volume" => rk_set(ctx, #{ VOLUME_LEVEL: "VOLUME_" + volume_wires()[value] }),
        "clean_type" => rk_set(ctx, #{ CLEAN_TYPE: clean_type_wires()[value] }),
        "clean_distance" => rk_set(ctx, #{ ZZ_DIST: dist_wires()[value] }),
        "smart_turbo" => rk_set_bool(ctx, "SMART_TURBO", value),
        "button_lock" => rk_set_bool(ctx, "BUTTON_LOCK", value),
        "reclean_mode" => rk_set_bool(ctx, "TOGGLE_RECLEAN", value),
        "light_mode" => rk_set_bool(ctx, "LIGHT", value),
        "ai_detection" => rk_set_bool(ctx, "AI_DETECTION", value),
        _ => il::reject(ctx, prop, "read_only", "read-only property")
    }
}
