import "runtime_test" as runtime;

// Tests of 2REFT1DIC4P_U.rhai (fridge), ported from upstream rethink's test suite (commit
// 0e57069; real captures cross-checked against the LG cloud). Expected values and writes are what upstream's driver
// publishes and sends for the same input.

fn status_change_fridge_temp() { "AA8E10EC0205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02000101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000206050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02000101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF000052BB" }
fn status_change_freezer_temp() { "AA8E10EC0205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02000101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000205090102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02000101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00005FBB" }
fn status_change_express_freeze_on() { "AA8E10EC0205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02000101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000205050202FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02000101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF000052BB" }
fn status_change_door_open() { "AA8E10EC0205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02000101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000205050102FF0401010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02000101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF000052BB" }
fn status_change_door_close() { "AA8E10EC0205050102FF0401010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02000101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02000101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF000052BB" }
fn status_change_craft_ice_3() { "AA8E10EC0205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02060101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF01060101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF000044BB" }
fn status_change_craft_ice_6() { "AA8E10EC0205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF01060101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02060101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF000044BB" }
fn status_change_craft_ice_maker_off() { "AA8E10EC0205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF00060101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF00060101FF000001FF00FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF000058BB" }
fn status_change_craft_ice_maker_making() { "AA8E10EC0205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02060101FF000001FF00FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02060101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF000044BB" }
fn status_change_night_view_custom() { "AA8E10EC0205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02060101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02070101FF030001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF000043BB" }
fn status_change_night_view_off() { "AA8E10EC0205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF02090101FF030001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF020A0101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF000049BB" }
fn status_change_quiet_mode_custom() { "AA8E10EC0205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF020A0101FF000001FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000205050102FF0400010001FFFFFFFFFFFF00FFFFFFFFFFFFFF020B0101FF000301FF01FFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00004BBB" }

fn last(d) { let s = d.sent(); hex_encode_upper(s[s.len() - 1]) }

fn test_status_change_fridge_temp() {
    let d = device();
    d.feed(status_change_fridge_temp());
    expect_props(d, #{ door: "false", fridge_setpoint: "2", freezer_setpoint: "-19", express_freeze: "false", night_view: "off", quiet_mode: "off", craft_ice_mode: "6_balls", craft_ice_maker_status: "making_ice" });
}

fn test_status_change_freezer_temp() {
    let d = device();
    d.feed(status_change_freezer_temp());
    expect_props(d, #{ door: "false", fridge_setpoint: "3", freezer_setpoint: "-23", express_freeze: "false", night_view: "off", quiet_mode: "off", craft_ice_mode: "6_balls", craft_ice_maker_status: "making_ice" });
}

fn test_status_change_express_freeze_on() {
    let d = device();
    d.feed(status_change_express_freeze_on());
    expect_props(d, #{ door: "false", fridge_setpoint: "3", freezer_setpoint: "-19", express_freeze: "true", night_view: "off", quiet_mode: "off", craft_ice_mode: "6_balls", craft_ice_maker_status: "making_ice" });
}

fn test_status_change_door_open() {
    let d = device();
    d.feed(status_change_door_open());
    expect_props(d, #{ door: "true", fridge_setpoint: "3", freezer_setpoint: "-19", express_freeze: "false", night_view: "off", quiet_mode: "off", craft_ice_mode: "6_balls", craft_ice_maker_status: "making_ice" });
}

fn test_status_change_door_close() {
    let d = device();
    d.feed(status_change_door_close());
    expect_props(d, #{ door: "false", fridge_setpoint: "3", freezer_setpoint: "-19", express_freeze: "false", night_view: "off", quiet_mode: "off", craft_ice_mode: "6_balls", craft_ice_maker_status: "making_ice" });
}

fn test_status_change_craft_ice_3() {
    let d = device();
    d.feed(status_change_craft_ice_3());
    expect_props(d, #{ door: "false", fridge_setpoint: "3", freezer_setpoint: "-19", express_freeze: "false", night_view: "off", quiet_mode: "off", craft_ice_mode: "3_balls", craft_ice_maker_status: "making_ice" });
}

fn test_status_change_craft_ice_6() {
    let d = device();
    d.feed(status_change_craft_ice_6());
    expect_props(d, #{ door: "false", fridge_setpoint: "3", freezer_setpoint: "-19", express_freeze: "false", night_view: "off", quiet_mode: "off", craft_ice_mode: "6_balls", craft_ice_maker_status: "making_ice" });
}

fn test_status_change_craft_ice_maker_off() {
    let d = device();
    d.feed(status_change_craft_ice_maker_off());
    expect_props(d, #{ door: "false", fridge_setpoint: "3", freezer_setpoint: "-19", express_freeze: "false", night_view: "off", quiet_mode: "off", craft_ice_mode: "off", craft_ice_maker_status: "off" });
}

fn test_status_change_craft_ice_maker_making() {
    let d = device();
    d.feed(status_change_craft_ice_maker_making());
    expect_props(d, #{ door: "false", fridge_setpoint: "3", freezer_setpoint: "-19", express_freeze: "false", night_view: "off", quiet_mode: "off", craft_ice_mode: "6_balls", craft_ice_maker_status: "making_ice" });
}

fn test_status_change_night_view_custom() {
    let d = device();
    d.feed(status_change_night_view_custom());
    expect_props(d, #{ door: "false", fridge_setpoint: "3", freezer_setpoint: "-19", express_freeze: "false", night_view: "custom", quiet_mode: "off", craft_ice_mode: "6_balls", craft_ice_maker_status: "making_ice" });
}

fn test_status_change_night_view_off() {
    let d = device();
    d.feed(status_change_night_view_off());
    expect_props(d, #{ door: "false", fridge_setpoint: "3", freezer_setpoint: "-19", express_freeze: "false", night_view: "off", quiet_mode: "off", craft_ice_mode: "6_balls", craft_ice_maker_status: "making_ice" });
}

fn test_status_change_quiet_mode_custom() {
    let d = device();
    d.feed(status_change_quiet_mode_custom());
    expect_props(d, #{ door: "false", fridge_setpoint: "3", freezer_setpoint: "-19", express_freeze: "false", night_view: "off", quiet_mode: "custom", craft_ice_mode: "6_balls", craft_ice_maker_status: "making_ice" });
}

fn test_start() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 1);
    if d.sent().len() > 0 { expect_eq(last(d), "AA0EF0ED1211010000010400EBBB"); }
}

fn test_writes_match_upstream() {
    let d = device();
    d.start();
    d.feed(status_change_fridge_temp());
    for w in [
        ["fridge_setpoint", "2", "AA4AF017FF06FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBBB"],
        ["freezer_setpoint", "-23", "AA4AF017FFFF09FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF94BB"],
        ["express_freeze", "true", "AA4AF017FFFFFF02FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFBB"],
        ["express_freeze", "false", "AA4AF017FFFFFF01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFECBB"],
        ["craft_ice_mode", "off", "AA4AF017FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEDBB"],
        ["craft_ice_mode", "3_balls", "AA4AF017FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFECBB"],
        ["craft_ice_mode", "6_balls", "AA4AF017FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF02FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFBB"],
    ] {
        d.set(w[0], w[1]);
        expect_eq(last(d), w[2]);
    }
}

fn test_unknown_and_read_only_writes_are_rejected() {
    let d = device();
    d.start();
    d.feed(status_change_fridge_temp());
    let n = d.sent().len();
    d.set("does_not_exist", "1");
    d.set("door", "true");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "rejects are published");
}

fn test_other_frames_are_ignored() {
    let d = device();
    d.feed("001122");
    d.feed("AA08109901020304BB");
    expect_eq(d.property("door"), ());
}
