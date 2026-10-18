import "runtime_test" as runtime;
// BEGIN PR VECTORS
// Regression vectors from rethink PR #117 (3b1942c1411931f5e007b0d86e8bb38e06be2018).
// Original test names are retained below. Expected TX bytes come from executing the TS driver.

// real short 0xEB captures publish only the hand-picked HA surface
fn test_pr_117_1() {
    let d = device();
    d.feed("aaff330a005500bc84000100eb004300000000000000000000000000000000000002005e01009a000000001a0400000000000000410000300000000000000400006000000000000000f00000000408000000fc1cbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "false", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// course lists, heartbeat, ACK, unknown FID, bad CRC and bad length are ignored
fn test_pr_117_2() {
    let d = device();
    d.feed("aa0733c302fcbb");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa083300240000bb");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff330a005a00000000010a860048000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d8b2bb");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff330a0054000000000100eb00420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009829bb");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff330a005500bc84000100eb004300000000000000000000000000000000000002005e01009a000000001a0400000000000000410000300000000000000400006000000000000000f00000000408000000fc1dbb");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// state/remote gates reject unsafe commands without optimistic actual-state echo
fn test_pr_117_3() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bbebb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("wake", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa08f02a010098bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("power_off", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("pause", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("send_course", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// all packet commands fail closed as Status unknown before the first valid state observation
fn test_pr_117_4() {
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
    expect_eq(d.property("state"), ());
    expect_eq(d.property("course"), ());
    expect_eq(d.property("error"), ());
}

// power switch uses vtCtrl power for ON, preserves state echo, and remote-gates OFF
fn test_pr_117_5() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bbebb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("power", "true");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "turning_on"});
    expect_eq(hex_encode(d.sent()[0]), "aa0df0e5000201ff010201c7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007fcdbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "complete"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("power", "false");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "complete"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000006c5bbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "complete"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("power", "false");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "complete"});
    expect_eq(hex_encode(d.sent()[1]), "aa09f0240101009cbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// remoteMaintain follows the POWEROFF/INITIAL state matrix without remoteStart and remains non-optimistic
fn test_pr_117_6() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bbebb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("remote_maintain", "true");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa09f0241001018cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("remote_maintain", "false");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007fcdbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("remote_maintain", "true");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[1]), "aa09f0241001018cbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("remote_maintain", "false");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[2]), "aa09f0241001008dbb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.feed("aa083300240000bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.feed("aaff330a005a000000000100eb0048000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b358bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "pause", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("remote_maintain", "true");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "pause", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("remote_maintain", "false");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "pause", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// observed remoteMaintain keeps stop and OFF available after remoteStart drops
fn test_pr_117_7() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000010000004000000000000000000000000000000000000000000000000000000000000001962bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff330a005a000000000100eb0048000000000000000000000000000000000000000000020000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000c661bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "pause", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("power_off", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "pause", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240101009cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// observed remoteMaintain keeps stop and OFF available after remoteStart drops
fn test_pr_117_8() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000010000004000000000000000000000000000000000000000000000000000000000000001962bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff330a005a000000000100eb0048000000000000000000000000000000000000000000020000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000c661bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "pause", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("pause", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "pause", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa09f02404010099bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// observed remoteMaintain keeps stop and OFF available after remoteStart drops
fn test_pr_117_9() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000010000004000000000000000000000000000000000000000000000000000000000000001962bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff330a005a000000000100eb0048000000000000000000000000000000000000000000020000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000c661bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "pause", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("power", "false");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "pause", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240101009cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_10() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007fcdbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("send_course", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_11() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000002828bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("send_course", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_12() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007fcdbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_temp", "95");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "95", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("send_course", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "95", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_13() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007fcdbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_14() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000006c5bbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0262e0306030200002000002e0000000000000000000030bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_15() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000af4bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "true", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_16() {
    let d = device();
    d.feed("aaff330a005a000000000100eb0048000000000000000000000000000000000000000000020000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000a0cebb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "pause", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "pause", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "pause", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// gate matrix: send_course is unsupported and start needs INITIAL, valid draft, and actual remoteStart
fn test_pr_117_17() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000006c5bbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_temp", "95");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "95", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "95", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// an incompatible washer option selected before first telemetry stays visible and start fails closed
fn test_pr_117_18() {
    let d = device();
    d.set("setting_temp", "95");
    expect_props(d, #{"setting_temp": "95"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000006c5bbb");
    expect_props(d, #{"setting_temp": "95", "course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"setting_temp": "95", "course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// selected command draft survives interleaved telemetry until start
fn test_pr_117_19() {
    let d = device();
    d.feed("aaff330a005a000000000100eb004800000800001b0000000000000000000000000000000100000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000d31bb");
    expect_props(d, #{"course": "bedding", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "bedding", "setting_soil_wash": "standard", "setting_spin": "mid", "setting_temp": "cold_water", "setting_rinse": "3x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "bedding", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_temp", "60");
    expect_props(d, #{"course": "bedding", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "60", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff330a005a000000000100eb004800000800001b0000000000000000000000000000000100000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000d31bb");
    expect_props(d, #{"course": "bedding", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "60", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "bedding", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "60", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0262e0306050200002000002e0000000000000000000032bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// washer WMStart rejects observed nonzero reservation time
fn test_pr_117_20() {
    let d = device();
    d.feed("aaff330a005a000000000100eb0048000000000000000000000000010000000000000000010000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000d714bb");
    expect_props(d, #{"course": "none", "reserve_time": "1", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "1", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "1", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// washer WMStart rejects observed nonzero reservation time
fn test_pr_117_21() {
    let d = device();
    d.feed("aaff330a005a000000000100eb004800000000000000000000000100000000000000000001000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000035ebbb");
    expect_props(d, #{"course": "none", "reserve_time": "256", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "256", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "256", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// course defaults/selectable and ControlValidator reject every unsafe example
fn test_pr_117_22() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000006c5bbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_temp", "95");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "95", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "95", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// course defaults/selectable and ControlValidator reject every unsafe example
fn test_pr_117_23() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000006c5bbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "bedding");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "bedding", "setting_soil_wash": "standard", "setting_spin": "mid", "setting_temp": "cold_water", "setting_rinse": "3x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_spin", "max");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "bedding", "setting_soil_wash": "standard", "setting_spin": "max", "setting_temp": "cold_water", "setting_rinse": "3x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "bedding", "setting_soil_wash": "standard", "setting_spin": "max", "setting_temp": "cold_water", "setting_rinse": "3x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// course defaults/selectable and ControlValidator reject every unsafe example
fn test_pr_117_24() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000006c5bbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "tub_sterilize");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "tub_sterilize", "setting_soil_wash": "standard", "setting_spin": "mid", "setting_temp": "60", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_turbo_wash", "on");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "tub_sterilize", "setting_soil_wash": "standard", "setting_spin": "mid", "setting_temp": "60", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "tub_sterilize", "setting_soil_wash": "standard", "setting_spin": "mid", "setting_temp": "60", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// official positive course combinations start once and do not echo actual state
fn test_pr_117_25() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000006c5bbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_temp", "60");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "60", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_spin", "max");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "max", "setting_temp": "60", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_turbo_wash", "off");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "max", "setting_temp": "60", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "max", "setting_temp": "60", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "off", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0262e0308050200000000002e000000000000000000001cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// changing course atomically resets fixed defaults before start
fn test_pr_117_26() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000006c5bbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_temp", "40");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_turbo_wash", "on");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "tub_sterilize");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "tub_sterilize", "setting_soil_wash": "standard", "setting_spin": "mid", "setting_temp": "60", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "off", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "tub_sterilize", "setting_soil_wash": "standard", "setting_spin": "mid", "setting_temp": "60", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "off", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026550304050200000000005500000000000000000000c6bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// built-in Course stays local, send_course emits nothing, and start emits exact F026 once
fn test_pr_117_27() {
    let d = device();
    d.feed("aaff330a005a000000000100eb0048000000000000000000000000000000000000000009010009000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000fb99bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("send_course", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "standby"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0262e0306030200002000002e0000000000000000000030bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Power ON → Standard Course → Start course emits exactly the official frames in order
fn test_pr_117_28() {
    let d = device();
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bbebb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "standby"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("power", "true");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "turning_on"});
    expect_eq(hex_encode(d.sent()[0]), "aa0df0e5000201ff010201c7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("power", "true");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "turning_on"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("aa0d33e6000201ff01020080bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "command_accepted"});
    expect_eq(hex_encode(d.sent()[1]), "aa12f0ed1121010000001804111200005ebb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.feed("aa0d33e6000201ff01020080bb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "power_off", "door": "true", "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "false", "power_transition": "command_accepted"});
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.feed("aaff330a005a000000000100eb00480000000000000000000000000000000000000000000100000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000006c5bbb");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "complete"});
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("setting_course", "standard");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "complete"});
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course": "none", "reserve_time": "0", "remaining_time": "0", "initial_time": "0", "error": "no_error", "state": "on", "door": "true", "remote_start": "true", "child_lock": "false", "door_lock": "false", "remote_maintain": "false", "setting_course": "standard", "setting_soil_wash": "standard", "setting_spin": "high", "setting_temp": "40", "setting_rinse": "2x", "setting_fresh_care": "off", "setting_steam": "off", "setting_turbo_wash": "on", "power": "true", "power_transition": "complete"});
    expect_eq(hex_encode(d.sent()[2]), "aa1bf0262e0306030200002000002e0000000000000000000030bb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

import "washtower_kr_test" as wt;

// Power-on success acknowledges acceptance; only telemetry confirms that the power changed.
fn test_power_acceptance_waits_for_telemetry_and_then_times_out() {
 let d=device();d.start();let r=blob(67);
 d.feed(wt::status(51,r));
 d.set("power","true");
 expect_props(d,#{power:"false",power_transition:"turning_on"});
 expect_eq(d.timers(),[["power_on_timeout",120000]]);
 d.set("power","true");expect_eq(d.sent().len(),1);
 d.feed(wt::response(51));
 expect_props(d,#{power:"false",power_transition:"command_accepted"});
 expect_eq(d.sent().len(),2);
 d.feed(wt::response(51));expect_eq(d.sent().len(),2);
 d.fire("power_on_timeout");
 expect_props(d,#{power:"false",power_transition:"timeout"});
 d.set("power","true");expect_eq(d.sent().len(),3);
 r[21]=1;d.feed(wt::status(51,r));
 expect_props(d,#{power:"true",power_transition:"complete"});
 expect_eq(d.timers(),[]);expect_eq(d.script_error(),());
}
fn test_disconnect_cancels_the_pending_power_timer() {
 let d=device();d.start();d.feed(wt::status(51,blob(67)));
 d.set("power","true");d.drop_device();
 expect_eq(d.timers(),[]);expect_eq(d.property("available"),"false");
}
