// Tests of IV12SNNWW.rhai (robot vacuum). Frames named *_frame() are real reports
// captured from the appliance (2026-11-05); mon_*() frames are built in the captured
// shape ({"mon":{...}} inside an AA..BB frame) to set a specific state.

fn state_frame() { hex_decode("aa00d16aa100297b226d6f6e223a7b22524f424f545f5354415445223a22484f4d494e47227d7d04bb") }
fn batt_frame() { hex_decode("aa00d16aa100207b226d6f6e223a7b22424154545f50223a223838227d7d3fbb") }
fn full_frame() { hex_decode("aa00d16aa104e57b0a09226d6f6e22203a200a097b0a09092241495f444554454354494f4e22203a202274727565222c0a090922424154544552595f4c49464522203a202266616c7365222c0a090922424154545f5022203a20223931222c0a090922425554544f4e5f4c4f434b22203a202266616c7365222c0a0909224341525045545f41564f494422203a20224155544f222c0a0909224341525045545f41564f49445f415641494c41424c4522203a20224155544f2f41564f49442f49474e4f5245222c0a090922434c45414e5f4f5244455222203a200a09095b0a09090922220a09095d2c0a090922434c45414e5f5459504522203a202253554354494f4e222c0a090922444c5f4c414e475541474522203a20224e554c4c222c0a090922444e445f494e464f22203a200a09097b0a09090922454e445f54494d4522203a202230383a3530222c0a0909092253455422203a20224f4e222c0a0909092253544152545f54494d4522203a202231393a3030220a09097d2c0a090922454646494349454e545f4348415247494e4722203a202231222c0a0909224c414e475541474522203a20226b6f2d4b52222c0a0909224c4947485422203a202274727565222c0a0909224d41494e545f4455535442414722203a202232387c323030222c0a0909224d41494e545f46494c54455222203a2022363030397c39303030222c0a0909224d41494e545f4d41494e425255534822203a2022363030397c3138303030222c0a0909224d41494e545f4d4f5022203a2022333635327c39303030222c0a0909224d41494e545f53494445425255534822203a2022363435307c3132303030222c0a0909224d4f444522203a20225a5a222c0a0909224d4f504452595f494e464f22203a200a09097b0a0909092253544152545f54494d4522203a202230222c0a0909092254494d4522203a202234220a09097d2c0a0909224d4f50574153485f494e464f22203a200a09097b0a0909092254494d4522203a20223330222c0a0909092257415348434f554e5422203a202231220a09097d2c0a0909225045545f5a4f4e4522203a202266616c7365222c0a0909225055424c49434b455922203a202274727565222c0a0909225245434c45414e22203a202266616c7365222c0a090922524f424f545f535441544522203a2022534c454550222c0a090922534d4152545f545552424f22203a202274727565222c0a09092253544154494f4e5f50414952454422203a202274727565222c0a09092253544154494f4e5f53455422203a20224155544f222c0a09092253544154494f4e5f535441544522203a20224e4f4e45222c0a09092253554354494f4e5f4c4556454c22203a20225354524f4e47222c0a090922535550504f52545f534b494c4c5322203a207b7d2c0a090922544f47474c455f5245434c45414e22203a202274727565222c0a0909225550444154452e446f776e6c6f616450726f677265737322203a202230222c0a09092256455253494f4e22203a202230322e31332e303130392e32313335342e39313635222c0a090922564f4c554d455f4c4556454c22203a20224d454449554d222c0a0909225741544552535550504c595f4c4556454c22203a20224c4f5731222c0a0909225a5a5f4449535422203a202244454550222c0a0909227061636b616765496422203a20224956455f55505f4b52220a097d0a7d0a1abb") }
fn ack_frame() { hex_decode("aa00d16aa300bc7b0a0922636f6e74726f6c526573756c7422203a200a097b0a090922636c69656e74496422203a202238656136366561373237636232663735623364626265633565656233326564626136343132636162346633363439383235333233616331663564366461376432222c0a0909226d657373616765496422203a202252434c436d4c7643494875596552344c49693338626b222c0a09092272657475726e436f646522203a202230303030220a097d0a7d0ab3bb") }
fn mon_state(raw) { blob_mon("{\"mon\":{\"ROBOT_STATE\":\"" + raw + "\"}}") }
fn blob_mon(text) {
    let b = blob(7, 0xaa);
    b[1] = 0; b[2] = 0; b[3] = 0; b[4] = 0; b[5] = 0; b[6] = 0;
    b += text.to_blob();
    b.push(0); b.push(0xbb);
    b
}

fn last_value(d) {
    let c = d.clips();
    expect(c.len() > 0, "a clip was sent");
    let m = c[c.len() - 1];
    expect_eq(m.cmd, "rkControl");
    expect_eq(m.data.Cmd, "Control");
    expect_eq(m.data.CmdOpt, "Set");
    expect_eq(m.data.clientId.len(), 64);
    expect_eq(m.data.messageId.len(), 22);
    m.data.Value
}

fn test_official_state_wording() {
    let d = device();
    d.feed(state_frame());
    expect_eq(d.property("state"), "returning_to_dock");
    expect_eq(d.property("state_raw"), "HOMING");
    d.feed(mon_state("STATION_DRY"));
    expect_eq(d.property("state"), "mop_drying");
    d.feed(mon_state("CLEAN_ZIGZAG"));
    expect_eq(d.property("state"), "quick_cleaning");
}

fn test_battery_delta() {
    let d = device();
    d.feed(batt_frame());
    expect_eq(d.property("battery"), "88");
}

fn test_full_report_reads_official_settings() {
    let d = device();
    d.feed(full_frame());
    expect_eq(d.property("battery"), "91");
    expect(["low", "medium", "high", "turbo"].contains(d.property("suction")), "suction label");
    expect_eq(d.property("ai_detection"), "true");
    expect_eq(d.script_error(), ());
}

fn test_command_ack_is_not_a_report() {
    let d = device();
    d.feed(ack_frame());
    expect_eq(d.property("available"), ());
}

fn test_error_message_uses_app_wording() {
    let d = device();
    d.feed(blob_mon("{\"mon\":{\"EMERGENCY\":\"E_ROBOT_STUCK\"}}"));
    expect_eq(d.property("error"), "true");
    expect_eq(d.property("error_message"), "Cleaning cannot continue. Check the area around the robot.");
    d.feed(blob_mon("{\"mon\":{\"EMERGENCY\":\"NONE\"}}"));
    expect_eq(d.property("error"), "false");
}

fn test_action_commands_while_standby() {
    let d = device();
    d.start();
    d.feed(mon_state("STANDBY"));
    d.set("clean_start", ""); expect_eq(last_value(d), "CLEAN_START");
    d.set("clean_stop", ""); expect_eq(last_value(d), "CLEAN_STOP");
    d.set("homing", ""); expect_eq(last_value(d), "HOMING");
    d.set("spot_clean", ""); expect_eq(last_value(d), "CLEAN_START_SPOT");
    d.set("find_robot", ""); expect_eq(last_value(d), "WHERE_IS_ROBOT");
}

fn test_station_commands_only_on_the_dock() {
    let d = device();
    d.start();
    d.feed(mon_state("CHARGING"));
    d.set("station_empty", ""); expect_eq(last_value(d), "STATION_START");
    d.set("mop_wash", ""); expect_eq(last_value(d), "MOPWASH_START");
    d.set("mop_dry", ""); expect_eq(last_value(d), "MOPDRY_START");
    let n = d.clips().len();
    d.feed(mon_state("CLEAN_ZIGZAG"));
    d.set("station_empty", "");
    expect_eq(d.clips().len(), n);
    expect(d.property("last_reject").contains("dock"), "station refusal names the dock");
    d.feed(mon_state("STATION_DRY"));
    d.set("mop_dry_stop", ""); expect_eq(last_value(d), "MOPDRY_STOP");
}

fn test_settings_use_official_wire_shapes() {
    let d = device();
    d.start();
    d.feed(mon_state("STANDBY"));
    d.set("suction", "high"); expect_eq(last_value(d).SUCTION_LEVEL, "STRONG");
    d.set("water_supply", "normal"); expect_eq(last_value(d).WATER_SUPPLY_LEVEL, "WATER_SUPPLY_LOW1");
    d.set("volume", "mute"); expect_eq(last_value(d).VOLUME_LEVEL, "VOLUME_MUTE");
    d.set("clean_type", "mop"); expect_eq(last_value(d).CLEAN_TYPE, "MOP");
    d.set("clean_distance", "deep+"); expect_eq(last_value(d).ZZ_DIST, "DEEPSLOW");
    d.set("reclean_mode", "false"); expect_eq(json_parse(last_value(d)).TOGGLE_RECLEAN, "false");
    d.set("light_mode", "true"); expect_eq(json_parse(last_value(d)).LIGHT, "true");
}

fn test_app_rules_block_controls_by_state() {
    let d = device();
    d.start();
    d.feed(mon_state("CLEAN_ZIGZAG"));
    let n = d.clips().len();
    d.set("homing", "");
    d.set("clean_type", "mop");
    expect_eq(d.clips().len(), n);
    expect_eq(d.property("last_reject"), "Cannot be set while cleaning. Try again after cleaning finishes.");
    d.set("pause", ""); expect_eq(last_value(d), "PAUSE");
    d.feed(mon_state("CHARGING"));
    let n = d.clips().len();
    d.set("spot_clean", "");
    d.set("homing", "");
    expect_eq(d.clips().len(), n);
}

fn test_unknown_state_does_not_block() {
    let d = device();
    d.start();
    d.set("homing", "");
    expect_eq(last_value(d), "HOMING");
}

fn test_unknown_option_is_rejected() {
    let d = device();
    d.start();
    d.set("suction", "max");
    d.set("suction", "none");
    expect_eq(d.clips().len(), 0);
}

fn test_reload_republishes_kept_values() {
    let d = device();
    d.feed(full_frame());
    d.feed(state_frame());
    let battery = d.property("battery");
    d.start();
    expect_eq(d.property("state"), "returning_to_dock");
    expect_eq(d.property("battery"), battery);
    expect_eq(d.clips().len(), 0);
}

// A delta carrying only fields outside the original known list was dropped
// silently: the gate must cover every key on_data reads below it.
fn test_delta_with_only_unlisted_fields_publishes() {
    let d = device();
    d.feed(blob_mon("{\"mon\":{\"SLEEP_MODE\":\"ON\"}}"));
    expect_eq(d.property("sleep_mode"), "true");
    d.feed(blob_mon("{\"mon\":{\"CARPET_AVOID\":\"AUTO\"}}"));
    expect_eq(d.property("carpet_avoid"), "AUTO");
    d.feed(blob_mon("{\"mon\":{\"MAINT_MAINBRUSH\":\"6009|18000\"}}"));
    expect_eq(d.property("maint_main_brush"), "6009");
    d.feed(blob_mon("{\"mon\":{\"LANGUAGE\":\"ko-KR\"}}"));
    expect_eq(d.property("language"), "ko-KR");
    d.feed(blob_mon("{\"mon\":{\"DND_INFO\":{\"SET\":\"ON\",\"START_TIME\":\"22:00\",\"END_TIME\":\"07:00\"}}}"));
    expect(d.property("do_not_disturb") != (), "do_not_disturb published");
    expect(d.property("do_not_disturb").contains("22:00"), "do_not_disturb carries the schedule");
    expect_eq(d.script_error(), ());
}

fn test_commands_are_sent_while_asleep() {
    let d = device();
    d.start();
    d.feed(mon_state("SLEEP"));
    d.set("clean_type", "vacuum");
    expect_eq(last_value(d), #{ CLEAN_TYPE: "SUCTION" });
    d.set("suction", "low");
    expect_eq(last_value(d), #{ SUCTION_LEVEL: "QUIET" });
}
