// LG robot vacuum IV12SNNWW (코드제로 로보킹 AI 올인원, ThinQ device type 501, "RK" platform):
// a JSON-protocol ThinQ2 appliance. Unlike the AABB/TLV families, its state arrives as a
// JSON object whose keys are the monitoring paths of LG's model definition, and its
// controls are the model definition's ControlWifi actions ({ctrlKey, command, dataValue}).
//
// Evidence status: CONSTRUCTED, not yet captured. Everything below is built from the
// official model JSON for IV12SNNWW (Info/Value/Monitoring/ControlWifi), supplied by the
// appliance's owner on 2026-11-02, plus the ThinQ2 CLIP contract in upstream rethink
// (cloud/thinq2/clip.ts: the host hands the driver the message's data payload). No frame
// from a real IV12SNNWW has been captured yet, so:
//   - on_data accepts the plausible payload shapes (flat monitoring object, one level of
//     nesting, ROBOT_STATE as a scalar or as an object carrying EMERGENCY) and ignores
//     anything else. The first live capture must confirm which shape is real; delete the
//     shapes that do not occur.
//   - Writes are DISARMED (writes_armed() == false): the descriptor then publishes every
//     control property read-only, so nothing can be sent. The control payloads are the
//     model JSON's own ControlWifi triples, but their on-the-wire wrapping and the
//     boolean rendering ("TRUE"/"FALSE" assumed) are unverified. Capture one accepted
//     app control (bridge-forwarded, or with rusthinqctl capture) before arming.
// Map data: RT_MAP / RT_POSE / FLOORMAP / VW payloads are republished verbatim as text
// properties (diagnostic) for a downstream renderer; this driver does not decode LG's
// map encoding.
import "il_common" as il;

// Flip to true only after a captured app control confirms the write envelope.
fn writes_armed() { false }

// ---- code tables (wire text -> IL name; string codes, so table_common's integer
// tables do not apply and each enum is read through these maps directly) ---------------

fn states() {
    #{ "STANDBY": "standby", "INITAILIZING": "preparing", "MONITORING": "preparing",
       "BACKMOVING_JOY": "preparing", "BACKMOVING_INIT": "preparing",
       "WORKING": "cleaning", "RECOVERY_WORKING": "cleaning", "CLEAN_EDGE": "cleaning",
       "CLEAN_SPIRAL": "cleaning", "CLEAN_SELECT": "cleaning", "CLEAN_SPECIFIED": "cleaning",
       "CLEAN_ZIGZAG": "cleaning", "CLEAN_LEARNING": "cleaning", "CLEAN_MYSPOT": "cleaning",
       "CLEAN_SELECT_GOZONE": "cleaning",
       "PAUSE": "paused", "PAUSE_EDGE": "paused", "PAUSE_SPIRAL": "paused",
       "PAUSE_ZIGZAG": "paused", "PAUSE_SELECT": "paused", "PAUSE_LEARNING": "paused",
       "PAUSE_SELECT_GOZONE": "paused", "HOMING_PAUSE": "paused",
       "HOMING": "returning", "HOMING_LEARNING": "returning", "DOCKING": "returning",
       "RECOVERY_HOMING": "returning",
       "CHARGING": "charging", "FINISHED_CHARGING": "charged", "SLEEP": "sleep",
       "MONITORING_POSITIONING": "positioning", "REPOSITIONING": "positioning",
       "MONITORING_MOVING": "homeguard", "MONITORING_DETECTING": "homeguard",
       "SETDATE": "remote_control", "MACROSECTOR": "remote_control",
       "RESERVATION": "remote_control", "DIAGNOSIS": "diagnosis",
       "WATER_REMOVAL": "water_removal", "MYSPOT_RECORDING": "myspot_recording",
       "STATION": "station_emptying", "STATION_MOP": "station_mop_wash",
       "STATION_DRY": "station_mop_dry", "WATER_INJECTION": "water_injection" }
}

fn state_options() {
    ["standby", "preparing", "cleaning", "paused", "returning", "charging", "charged",
     "sleep", "positioning", "homeguard", "remote_control", "diagnosis", "water_removal",
     "myspot_recording", "station_emptying", "station_mop_wash", "station_mop_dry",
     "water_injection"]
}

// Emergency codes are already descriptive; published 1:1 as the error_message text.
fn clean_modes() {
    #{ "ZZ": "zigzag", "SB": "sector", "SPOT": "spot", "MACRO": "macro", "EDGE": "edge",
       "SELECT": "select_area", "MY": "my_zone", "GYRO": "gyro", "DEEP": "deep",
       "AREA": "area", "CUSTOM": "custom" }
}

fn clean_mode_wires() {
    #{ "zigzag": "ZZ", "sector": "SB", "spot": "SPOT", "macro": "MACRO", "edge": "EDGE",
       "select_area": "SELECT", "my_zone": "MY", "gyro": "GYRO", "deep": "DEEP",
       "area": "AREA", "custom": "CUSTOM" }
}

fn suction_levels() {
    #{ "NONE": "none", "QUIET": "quiet", "STANDARD": "standard", "STRONG": "strong",
       "MAX": "max" }
}

fn suction_wires() {
    #{ "none": "NONE", "quiet": "QUIET", "standard": "STANDARD", "strong": "STRONG",
       "max": "MAX" }
}

// LOW1 is the wire code whose model-JSON label is MIDDLE.
fn water_levels() {
    #{ "DRY": "dry", "LOW": "low", "LOW1": "middle", "HIGH": "high" }
}

fn water_wires() {
    #{ "dry": "DRY", "low": "LOW", "middle": "LOW1", "high": "HIGH" }
}

fn volume_levels() {
    #{ "HIGH": "high", "MEDIUM": "medium", "LOW": "low", "MUTE": "mute" }
}

fn volume_wires() {
    #{ "high": "HIGH", "medium": "MEDIUM", "low": "LOW", "mute": "MUTE" }
}

fn update_states() {
    #{ "IDLE": "idle", "DOWNLOADING": "downloading", "COMPLETE": "complete",
       "MD5_FAILED": "md5_failed", "DOWNLOAD_FAILED": "download_failed" }
}

fn station_modes() { #{ "AUTO": "auto", "MANUAL": "manual" } }
fn station_wires() { #{ "auto": "AUTO", "manual": "MANUAL" } }

fn clean_types() { #{ "ALL": "all", "SUCTION": "suction", "MOP": "mop" } }
fn clean_type_wires() { #{ "all": "ALL", "suction": "SUCTION", "mop": "MOP" } }

fn maint_wires() {
    #{ "main_brush": "MAINT_MAINBRUSH", "side_brush": "MAINT_SIDEBRUSH",
       "filter": "MAINT_FILTER", "mop": "MAINT_MOP", "dust_bag": "MAINT_DUSTBAG" }
}

// ---- descriptor ---------------------------------------------------------------------

fn descriptor(ctx) {
    let armed = writes_armed();
    let props = #{
        available: #{ type: "binary", role: "available" },
        state: #{ type: "select", role: "state", options: state_options() },
        state_raw: #{ type: "text", category: "diagnostic", label: "State (wire)" },
        error: #{ type: "binary", class: "problem", category: "diagnostic" },
        error_code: #{ type: "text", category: "diagnostic", label: "Error code (wire)" },
        error_message: #{ type: "text", category: "diagnostic", label: "Error" },
        battery: #{ type: "number", unit: "%", min: 0, max: 100 },
        clean_mode: #{ type: "select", options: ["zigzag", "sector", "spot", "macro", "edge",
                        "select_area", "my_zone", "gyro", "deep", "area", "custom"] },
        suction: #{ type: "select", label: "Suction level",
                    options: ["none", "quiet", "standard", "strong", "max"] },
        water_supply: #{ type: "select", label: "Water supply",
                         options: ["dry", "low", "middle", "high"] },
        volume: #{ type: "select", options: ["high", "medium", "low", "mute"] },
        clean_type: #{ type: "select", options: ["all", "suction", "mop"] },
        smart_turbo: #{ type: "binary" },
        sleep_mode: #{ type: "binary", category: "config" },
        button_lock: #{ type: "binary", category: "config" },
        repeat_mode: #{ type: "binary" },
        reclean_mode: #{ type: "binary" },
        light_mode: #{ type: "binary", category: "config" },
        ai_detection: #{ type: "binary", category: "config" },
        carpet_avoid: #{ type: "text", category: "config" },
        station_mode: #{ type: "select", category: "config", options: ["auto", "manual"] },
        clean_time: #{ type: "number", class: "duration", unit: "min" },
        clean_where: #{ type: "number", category: "diagnostic" },
        maint_main_brush: #{ type: "number", category: "diagnostic", label: "Main brush wear" },
        maint_side_brush: #{ type: "number", category: "diagnostic", label: "Side brush wear" },
        maint_filter: #{ type: "number", category: "diagnostic", label: "Filter wear" },
        maint_mop: #{ type: "number", category: "diagnostic", label: "Mop wear" },
        maint_dust_bag: #{ type: "number", category: "diagnostic", label: "Dust bag fill" },
        update: #{ type: "select", category: "diagnostic",
                   options: ["idle", "downloading", "complete", "md5_failed", "download_failed"] },
        update_progress: #{ type: "number", category: "diagnostic", unit: "%" },
        product_version: #{ type: "number", category: "diagnostic" },
        language: #{ type: "text", category: "diagnostic" },
        robot_event: #{ type: "text", category: "diagnostic" },
        clean_order: #{ type: "text", category: "diagnostic", label: "Clean order (JSON)" },
        reservation: #{ type: "text", category: "diagnostic", label: "Reservation (JSON)" },
        do_not_disturb: #{ type: "text", category: "diagnostic", label: "Do not disturb (JSON)" },
        rt_map: #{ type: "text", category: "diagnostic", label: "Realtime map (raw JSON)" },
        rt_pose: #{ type: "text", category: "diagnostic", label: "Realtime pose (raw JSON)" },
        floor_map: #{ type: "text", category: "diagnostic", label: "Floor map (raw JSON)" },
        virtual_wall: #{ type: "text", category: "diagnostic", label: "Virtual walls (raw JSON)" }
    };
    if armed {
        props.clean_mode.rw = true;
        props.suction.rw = true;
        props.water_supply.rw = true;
        props.volume.rw = true;
        props.clean_type.rw = true;
        props.smart_turbo.rw = true;
        props.sleep_mode.rw = true;
        props.button_lock.rw = true;
        props.repeat_mode.rw = true;
        props.light_mode.rw = true;
        props.ai_detection.rw = true;
        props.carpet_avoid.rw = true;
        props.station_mode.rw = true;
        props.clean_start = #{ type: "trigger", label: "Start cleaning" };
        props.pause = #{ type: "trigger" };
        props.clean_stop = #{ type: "trigger", label: "Stop cleaning" };
        props.homing = #{ type: "trigger", label: "Return to dock" };
        props.back_moving = #{ type: "trigger", label: "Move to start point" };
        props.spot_clean = #{ type: "trigger", label: "Start spot cleaning" };
        props.station_start = #{ type: "trigger", label: "Start station (dust emptying)" };
        props.mop_wash_start = #{ type: "trigger", label: "Start mop washing" };
        props.mop_dry_start = #{ type: "trigger", label: "Start mop drying" };
        props.mop_dry_stop = #{ type: "trigger", label: "Stop mop drying" };
        props.find_robot = #{ type: "trigger", label: "Find robot (voice)" };
        props.wake_up = #{ type: "trigger", label: "Wake up" };
        props.reset_maint = #{ type: "select", category: "diagnostic", label: "Reset maintenance counter",
                               options: ["main_brush", "side_brush", "filter", "mop", "dust_bag"] };
    }
    json_stringify(#{ il: 0, kind: "vacuum", label: "Robot vacuum", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

// The appliance pushes state on its own (monitoring); no status query is documented
// for this platform, so start sends nothing.
fn start(ctx) {}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

// ---- payload walking ------------------------------------------------------------------

// A monitoring key may sit at the top of the payload, under a CLIP-style "data"
// member, or one level down in a nested object; accept the first hit.
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

fn pub_num(ctx, s, key, prop) {
    let v = num_text(get2(s, key));
    if v != () { il::publish_property(ctx, prop, v); }
}

fn pub_bool(ctx, s, key, prop) {
    let v = bool_text(get2(s, key));
    if v != () { il::publish_property(ctx, prop, v); }
}

fn pub_enum(ctx, s, key, prop, table) {
    let raw = get2(s, key);
    if type_of(raw) != "string" { return; }
    let name = table[raw];
    if name != () { il::publish_property(ctx, prop, name); }
}

fn pub_raw(ctx, s, key, prop) {
    let v = get2(s, key);
    if v == () { return; }
    if type_of(v) == "string" { il::publish_property(ctx, prop, v); }
    else { il::publish_property(ctx, prop, json_stringify(v)); }
}

fn on_data(ctx, data) {
    let text = ""; try { text = bytes_utf8(data); } catch { return; }
    let s = (); try { s = json_parse(text); } catch { return; }
    if type_of(s) != "map" { return; }
    // Only a payload carrying the vacuum's state key is a state report; anything
    // else (acks, provisioning echoes) is not ours to publish.
    let state_holder = get2(s, "ROBOT_STATE");
    if state_holder == () { return; }
    il::publish_property(ctx, "available", "true");

    // State: ROBOT_STATE may be the scalar itself or an object carrying it
    // (the model JSON's dotted path ROBOT_STATE.EMERGENCY implies the object form
    // exists); EMERGENCY likewise may be top-level or nested beside the state.
    let state_raw = ();
    let emergency = get2(s, "EMERGENCY");
    if type_of(state_holder) == "string" { state_raw = state_holder; }
    else if type_of(state_holder) == "map" {
        if type_of(state_holder["ROBOT_STATE"]) == "string" { state_raw = state_holder["ROBOT_STATE"]; }
        if emergency == () && state_holder.contains("EMERGENCY") { emergency = state_holder["EMERGENCY"]; }
    }
    if state_raw != () {
        il::publish_property(ctx, "state_raw", state_raw);
        let name = states()[state_raw];
        if name != () { il::publish_property(ctx, "state", name); }
    }
    if type_of(emergency) == "string" {
        il::publish_property(ctx, "error_code", emergency);
        il::publish_property(ctx, "error", if emergency == "NONE" { "false" } else { "true" });
        il::publish_property(ctx, "error_message", if emergency == "NONE" { "-" } else { emergency });
    }

    pub_num(ctx, s, "BATT_P", "battery");
    pub_enum(ctx, s, "MODE", "clean_mode", clean_modes());
    pub_enum(ctx, s, "SUCTION_LEVEL", "suction", suction_levels());
    pub_enum(ctx, s, "WATERSUPPLY_LEVEL", "water_supply", water_levels());
    pub_enum(ctx, s, "VOLUME_LEVEL", "volume", volume_levels());
    pub_enum(ctx, s, "CLEAN_TYPE", "clean_type", clean_types());
    pub_enum(ctx, s, "STATION_SET", "station_mode", station_modes());
    pub_bool(ctx, s, "SMART_TURBO", "smart_turbo");
    pub_bool(ctx, s, "SLEEP_MODE", "sleep_mode");
    pub_bool(ctx, s, "BUTTON_LOCK", "button_lock");
    pub_bool(ctx, s, "REPEAT", "repeat_mode");
    pub_bool(ctx, s, "RECLEAN", "reclean_mode");
    pub_bool(ctx, s, "LIGHT", "light_mode");
    pub_bool(ctx, s, "AI_DETECTION", "ai_detection");
    pub_raw(ctx, s, "CARPET_AVOID", "carpet_avoid");
    // CleanTime's unit is minutes in the app; the wire unit is unverified.
    pub_num(ctx, s, "CLEAN_TIME", "clean_time");
    pub_num(ctx, s, "CLEAN_WHERE", "clean_where");
    pub_num(ctx, s, "MAINT_MAINBRUSH", "maint_main_brush");
    pub_num(ctx, s, "MAINT_SIDEBRUSH", "maint_side_brush");
    pub_num(ctx, s, "MAINT_FILTER", "maint_filter");
    pub_num(ctx, s, "MAINT_MOP", "maint_mop");
    pub_num(ctx, s, "MAINT_DUSTBAG", "maint_dust_bag");
    pub_num(ctx, s, "VERSION", "product_version");
    pub_raw(ctx, s, "LANGUAGE", "language");
    pub_raw(ctx, s, "ROBOT_EVENT", "robot_event");
    pub_raw(ctx, s, "CLEAN_ORDER", "clean_order");
    pub_raw(ctx, s, "CLEANING_RSV", "reservation");
    pub_raw(ctx, s, "DO_NOT_DISTURB", "do_not_disturb");
    // Map payloads pass through verbatim for a downstream renderer.
    pub_raw(ctx, s, "RT_MAP", "rt_map");
    pub_raw(ctx, s, "RT_POSE", "rt_pose");
    pub_raw(ctx, s, "FLOORMAP", "floor_map");
    pub_raw(ctx, s, "VW", "virtual_wall");

    // Firmware update: the UPDATE member is a scalar in some reports and an
    // object carrying DownloadProgress/TotalSize in others (dotted model paths).
    let upd = get2(s, "UPDATE");
    if type_of(upd) == "string" {
        let name = update_states()[upd];
        if name != () { il::publish_property(ctx, "update", name); }
    } else if type_of(upd) == "map" {
        if type_of(upd["UPDATE"]) == "string" {
            let name = update_states()[upd["UPDATE"]];
            if name != () { il::publish_property(ctx, "update", name); }
        }
        let p = num_text(upd["DownloadProgress"]);
        if p != () { il::publish_property(ctx, "update_progress", p); }
    }
}

// ---- writes (disarmed until a capture confirms the envelope) -------------------------

fn ctrl(ctx, ctrl_key, command, data_value) {
    ctx.send_json(json_stringify(#{ ctrlKey: ctrl_key, command: command, dataValue: data_value }));
}

fn ctrl_obj(ctx, obj) { ctrl(ctx, "Control", "Set", json_stringify(obj)); }

// Boolean rendering in ControlWifi templates is unverified ("TRUE"/"FALSE" assumed).
fn wire_bool(value) { if value == "true" { "TRUE" } else { "FALSE" } }

fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value == () { return; }
    if !writes_armed() {
        il::reject(ctx, prop, "writes_disarmed",
                   "control writes are disarmed in this build pending a wire capture");
        return;
    }
    switch prop {
        "clean_start" => ctrl(ctx, "Control", "Set", "CLEAN_START"),
        "pause" => ctrl(ctx, "Control", "Set", "PAUSE"),
        "clean_stop" => ctrl(ctx, "Control", "Set", "CLEAN_STOP"),
        "homing" => ctrl(ctx, "Control", "Set", "HOMING"),
        "back_moving" => ctrl(ctx, "Control", "Set", "BACKMOVING"),
        "spot_clean" => ctrl(ctx, "Control", "Set", "CLEAN_START_SPOT"),
        "station_start" => ctrl(ctx, "Control", "Set", "STATION_START"),
        "mop_wash_start" => ctrl(ctx, "Control", "Set", "MOPWASH_START"),
        "mop_dry_start" => ctrl(ctx, "Control", "Set", "MOPDRY_START"),
        "mop_dry_stop" => ctrl(ctx, "Control", "Set", "MOPDRY_STOP"),
        "find_robot" => ctrl(ctx, "Control", "Set", "WHERE_IS_ROBOT"),
        "wake_up" => ctrl(ctx, "ConfigRK", "Set", "WakeUp"),
        "clean_mode" => ctrl_obj(ctx, #{ CLEAN_MODE: "CLEAN_" + clean_mode_wires()[value] }),
        "suction" => ctrl_obj(ctx, #{ SUCTION_LEVEL: suction_wires()[value] }),
        "water_supply" => ctrl_obj(ctx, #{ WATER_SUPPLY_LEVEL: "WATER_SUPPLY_" + water_wires()[value] }),
        "volume" => ctrl_obj(ctx, #{ VOLUME_LEVEL: "VOLUME_" + volume_wires()[value] }),
        "clean_type" => ctrl_obj(ctx, #{ CLEAN_TYPE: clean_type_wires()[value] }),
        "station_mode" => ctrl_obj(ctx, #{ STATION_SET: station_wires()[value] }),
        "smart_turbo" => ctrl_obj(ctx, #{ SMART_TURBO: wire_bool(value) }),
        "button_lock" => ctrl_obj(ctx, #{ BUTTON_LOCK: wire_bool(value) }),
        "repeat_mode" => ctrl_obj(ctx, #{ REPEAT: wire_bool(value) }),
        "light_mode" => ctrl_obj(ctx, #{ LIGHT: wire_bool(value) }),
        "ai_detection" => ctrl_obj(ctx, #{ AI_DETECTION: wire_bool(value) }),
        "sleep_mode" => ctrl_obj(ctx, #{ CMD: "SLEEP_MODE", SET: wire_bool(value) }),
        "carpet_avoid" => ctrl_obj(ctx, #{ CARPET_AVOID: value }),
        "reset_maint" => ctrl_obj(ctx, #{ RESET_MAINT: maint_wires()[value] }),
        _ => il::reject(ctx, prop, "unknown_property", "unknown or read-only property")
    }
}
