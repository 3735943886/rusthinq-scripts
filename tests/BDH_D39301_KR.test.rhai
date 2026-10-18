import "runtime_test" as runtime;
// BEGIN PR VECTORS
// Regression vectors from rethink PR #117 (3b1942c1411931f5e007b0d86e8bb38e06be2018).
// Original test names are retained below. Expected TX bytes come from executing the TS driver.

// real short 0xEB captures publish only the hand-picked HA surface
fn test_pr_117_1() {
    let d = device();
    d.feed("aaff340a0044006320000100eb003200000000000000000000000000000100000000040000008f20000000070000870100000000000000000000000000000000008343bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// captured short dryer 0xEC selects the current record and publishes live controls
fn test_pr_117_2() {
    let d = device();
    d.feed("aaff340a0076008217000100ec006400000000000000000000000000010000000000040000008f200000800700008701000000000000000000000000000000000000000000000000000000000000010000000000040000008f20000082070000870100000000000000000000000000000000008320bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// dryer Course raw 2 publishes the English towels label
fn test_pr_117_3() {
    let d = device();
    d.feed("aaff340a0045000000000100eb00330000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001405bb");
    expect_props(d, #{"course": "towels", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// unknown public enum values use the exact safe fallback
fn test_pr_117_4() {
    let d = device();
    d.feed("aaff340a0045000000000100eb00330000000000fa00000000000000fa00fa00000000000000000000000000000000000000000000000000000000000000000000009db8bb");
    expect_props(d, #{"reserve_time": "0", "remaining_time": "0", "initial_time": "0", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    expect_eq(d.property("state"), "");
    expect_eq(d.property("course"), "");
    expect_eq(d.property("error"), "");
}

// all packet commands fail closed as Status unknown before the first valid state observation
fn test_pr_117_5() {
    let d = device();
    d.set("wake", "");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("power", "true");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("power", "false");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("remote_maintain", "true");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("remote_maintain", "false");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("send_course", "");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("power_off", "");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("pause", "");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// power switch uses vtCtrl power for ON, preserves state echo, and remote-gates OFF
fn test_pr_117_6() {
    let d = device();
    d.feed("aaff340a0045000000000100eb003300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055d6bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("power", "true");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "turning_on"});
    expect_eq(hex_encode(d.sent()[0]), "aa0df0e5000201ff010201c7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000b14dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "complete"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("power", "false");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "complete"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000de5dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "complete"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("power", "false");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "complete"});
    expect_eq(hex_encode(d.sent()[1]), "aa09f0240101009cbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// remoteMaintain follows the POWEROFF/INITIAL state matrix without remoteStart and remains non-optimistic
fn test_pr_117_7() {
    let d = device();
    d.feed("aaff340a0045000000000100eb003300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055d6bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("remote_maintain", "true");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa09f0241001018cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("remote_maintain", "false");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000b14dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("remote_maintain", "true");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[1]), "aa09f0241001018cbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("remote_maintain", "false");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[2]), "aa09f0241001008dbb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.feed("aa083400240000bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.feed("aaff340a0045000000000100eb00330000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000008cc1bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "drying", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("remote_maintain", "true");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "drying", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("remote_maintain", "false");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "drying", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// observed remoteMaintain keeps stop and OFF available after remoteStart drops
fn test_pr_117_8() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040020000000000000000000000000000000000000000000000b05bbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000200000000000000000000000000020000000000000000000000000000000000000000000000e2c7bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "drying", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("power_off", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "drying", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240101009cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// observed remoteMaintain keeps stop and OFF available after remoteStart drops
fn test_pr_117_9() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040020000000000000000000000000000000000000000000000b05bbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000200000000000000000000000000020000000000000000000000000000000000000000000000e2c7bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "drying", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("pause", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "drying", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa09f02404010099bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// observed remoteMaintain keeps stop and OFF available after remoteStart drops
fn test_pr_117_10() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040020000000000000000000000000000000000000000000000b05bbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000200000000000000000000000000020000000000000000000000000000000000000000000000e2c7bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "drying", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("power", "false");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "drying", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240101009cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_11() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000b14dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("send_course", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_12() {
    let d = device();
    d.feed("aaff340a0045000000000100eb00330000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000003ac6bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("send_course", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_13() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000b14dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_eco_hybrid", "off");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "off", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("send_course", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "off", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_14() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000b14dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_15() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000de5dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260703020000000000000000000000b5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_16() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000000020000000000000000000000000000000000000000000000df4bbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_17() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000200000000000000000000000040000000000000000000000000000000000000000000000000e3d1bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "drying", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "drying", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "drying", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_18() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000de5dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_eco_hybrid", "off");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "off", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "off", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// first supported telemetry initializes its official draft and later telemetry preserves a user-dirty draft
fn test_pr_117_19() {
    let d = device();
    d.feed("aaff340a0045000000000100eb003300000000000f000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000a3bcbb");
    expect_props(d, #{"course": "bedding_shake", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "bedding_shake", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "bedding_shake", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_dry_level", "standard_plus");
    expect_props(d, #{"course": "bedding_shake", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard_plus", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff340a0045000000000100eb003300000000000f000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000a3bcbb");
    expect_props(d, #{"course": "bedding_shake", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard_plus", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "bedding_shake", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard_plus", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260704020000000000000000000000b4bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// a course selected before first telemetry survives NOT_SELECTED reconciliation
fn test_pr_117_20() {
    let d = device();
    d.set("setting_course", "bedding_shake");
    expect_props(d, #{"setting_course": "bedding_shake", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "off"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000de5dbb");
    expect_props(d, #{"setting_course": "bedding_shake", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "off", "course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"setting_course": "bedding_shake", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "off", "course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260f00020000000000000000000000b0bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// a compatible dryer option selected before first telemetry is preserved in the reconciled F026 draft
fn test_pr_117_21() {
    let d = device();
    d.set("setting_dry_level", "standard_plus");
    expect_props(d, #{"setting_dry_level": "standard_plus"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff340a0045000000000100eb0033000000000007000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000b4d1bb");
    expect_props(d, #{"setting_dry_level": "standard_plus", "course": "standard", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"setting_dry_level": "standard_plus", "course": "standard", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260704020000000000000000000000b4bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// interleaved dryer telemetry still updates non-setting reservation bytes
fn test_pr_117_22() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000de5dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff340a0045000000000100eb003300000000000000001e0000000001000000000000000000000000400000000000000000000000000000000000000000000000001d15bb");
    expect_props(d, #{"course": "none", "reserve_time": "30", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "30", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f026070302000000001e000000000000abbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// course defaults/selectable and ControlValidator reject every unsafe example
fn test_pr_117_23() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000de5dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "ai_dry");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "ai_dry", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_dry_level", "standard_plus");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "ai_dry", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard_plus", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "ai_dry", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard_plus", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// course defaults/selectable and ControlValidator reject every unsafe example
fn test_pr_117_24() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000de5dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "small_quick");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "small_quick", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_eco_hybrid", "auto");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "small_quick", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "small_quick", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// course defaults/selectable and ControlValidator reject every unsafe example
fn test_pr_117_25() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000de5dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "steam_refresh");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "steam_refresh", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "off", "setting_steam": "on", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_steam", "off");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "steam_refresh", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "steam_refresh", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// course defaults/selectable and ControlValidator reject every unsafe example
fn test_pr_117_26() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000de5dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "condenser_care");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "condenser_care", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_wrinkle_care", "on");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "condenser_care", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "on", "setting_steam": "off", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "condenser_care", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "on", "setting_steam": "off", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// official positive course combinations start once and do not echo actual state
fn test_pr_117_27() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000de5dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_eco_hybrid", "speed");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_dry_level", "standard_plus");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard_plus", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_steam", "on");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "off", "setting_steam": "on", "setting_dry_level": "standard_plus", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "off", "setting_steam": "on", "setting_dry_level": "standard_plus", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260704030000000000000004000000b3bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// built-in Course stays local, send_course emits nothing, and start emits exact F026 once
fn test_pr_117_28() {
    let d = device();
    d.feed("aaff340a0045000000000100eb003300000000000000000000000000010000000000000900000900004000000000000000000000000000000000000000000000000071adbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("send_course", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260703020000000000000000000000b5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Power ON → Standard Course → Start course emits exactly the official frames in order
fn test_pr_117_29() {
    let d = device();
    d.feed("aaff340a0045000000000100eb003300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055d6bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("power", "true");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "turning_on"});
    expect_eq(hex_encode(d.sent()[0]), "aa0df0e5000201ff010201c7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("power", "true");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "turning_on"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("aa0d34e6000201ff01020083bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "command_accepted"});
    expect_eq(hex_encode(d.sent()[1]), "aa12f0ed1121010000001804111200005ebb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.feed("aa0d34e6000201ff01020083bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "power_off", "error": "no_error", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "false", "power_transition": "command_accepted"});
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000de5dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "complete"});
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "complete"});
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "complete"});
    expect_eq(hex_encode(d.sent()[2]), "aa14f0260703020000000000000000000000b5bb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// dryer fixed steam defaults pass for REFRESH, ALLERGYCARE and TUBCLEAN
fn test_pr_117_30() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000de5dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "steam_refresh");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "steam_refresh", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "off", "setting_steam": "on", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "steam_refresh", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "off", "setting_steam": "on", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f026010003000000000000000400000089bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// dryer fixed steam defaults pass for REFRESH, ALLERGYCARE and TUBCLEAN
fn test_pr_117_31() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000de5dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "steam_sterilize");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "steam_sterilize", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "off", "setting_steam": "on", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "steam_sterilize", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "off", "setting_steam": "on", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0261000030000000000000004000000bebb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// dryer fixed steam defaults pass for REFRESH, ALLERGYCARE and TUBCLEAN
fn test_pr_117_32() {
    let d = device();
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000de5dbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_eco_hybrid": "auto", "setting_wrinkle_care": "off", "setting_steam": "off", "setting_dry_level": "standard", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "tub_sterilize");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "tub_sterilize", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "off", "setting_steam": "on", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "state": "on", "error": "no_error", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "tub_sterilize", "setting_eco_hybrid": "speed", "setting_wrinkle_care": "off", "setting_steam": "on", "setting_dry_level": "off", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0261300030000000000000004000000bbbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

import "washtower_kr_test" as wt;

// Power-on success acknowledges acceptance; only telemetry confirms that the power changed.
fn test_power_acceptance_waits_for_telemetry_and_then_times_out() {
 let d=device();d.start();let r=blob(50);
 d.feed(wt::status(52,r));
 d.set("power","true");
 expect_props(d,#{power:"false",power_transition:"turning_on"});
 expect_eq(d.timers(),[["power_on_timeout",120000]]);
 d.set("power","true");expect_eq(d.sent().len(),1);
 d.feed(wt::response(52));
 expect_props(d,#{power:"false",power_transition:"command_accepted"});
 expect_eq(d.sent().len(),2);
 d.feed(wt::response(52));expect_eq(d.sent().len(),2);
 d.fire("power_on_timeout");
 expect_props(d,#{power:"false",power_transition:"timeout"});
 d.set("power","true");expect_eq(d.sent().len(),3);
 r[13]=1;d.feed(wt::status(52,r));
 expect_props(d,#{power:"true",power_transition:"complete"});
 expect_eq(d.timers(),[]);expect_eq(d.script_error(),());
}
fn test_disconnect_cancels_the_pending_power_timer() {
 let d=device();d.start();d.feed(wt::status(52,blob(50)));
 d.set("power","true");d.drop_device();
 expect_eq(d.timers(),[]);expect_eq(d.property("available"),"false");
}
