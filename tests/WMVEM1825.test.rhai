import "runtime_test" as runtime;

// Tests of WMVEM1825, ported from upstream rethink's test suite (commit 0e57069; live captures).
// Expected values are what upstream's driver publishes, in IL names (ON/OFF as true/false); a
// state upstream cannot name ("None") stays unpublished.

fn sample_initial_off() { "AA3441EB003100015500000000000000FF030D000000000000000000000000000000C3000000004000008080808001000000F1BB" }
fn sample_cooking_10_seconds_high() { "AA6241EC073000004001000000000000FF030D000000000000000000000000000000C3000100004000008080808001000000023000004401000000000A00FF030D00000A00000A000000000000000000C700010000400001808080800100000026BB" }
fn sample_cooking_1_05_power_5() { "AA6241EC073000004001000000000000FF030D000000000000000000000000000000C3000100004000008080808001000000023000004401000000000500FF030D000105000105000000000000000000C700010000400001808080800100000033BB" }
fn sample_paused_at_57_seconds() { "AA6241EC023000004401000000000500FF030D000039000105000000000000000000C7000100004000018080808001000000043000004401000000000500FF030D000039000105000000000000000000C7000100004000018080808001000000B6BB" }
fn sample_done() { "AA6241EC023000004401000000000A00FF030D00000100000A000000000000000000C7000100004000018080808001000000053000015500000000000000FF030D000000000000000000000000000000C300000000400000808080800100000029BB" }
fn sample_door_open() { "AA0041B2000F070A01030000000197BB" }
fn sample_door_closed() { "AA0041B2000F070A01030000000094BB" }
fn sample_light_low() { "AA6241EC003000015500000000000000FF030D000000000000000000000000000000C3000000004000008080808001000000003000015500000000000000FF030D000000000000000000000000000000C30000000040100080808080010000002EBB" }
fn sample_fan_high() { "AA6241EC003000015500000000000000FF030D000000000000000000000000000000C3000000004001008080808001000000003000015500000000000000FF030D000000000000000000000000000000C30000000040020080808080010000003BBB" }
fn sample_fan_high_light_low() { "AA6241EC003000015500000000000000FF030D000000000000000000000000000000C3000000004010008080808001000000003000015500000000000000FF030D000000000000000000000000000000C3000000004012008080808001000000D8BB" }
fn cook_20s_level_5() { "aa6241ec073000004001000000000000ff030d000000000000000000000000000000c3000100004000008080808001000000023000004401000000000500ff030d000014000014000000000000000000c7000100004000018080808001000000d7bb" }

fn fed(frames) { let d = device(); d.start(); for f in frames { d.feed(f); } d }
fn last_hex(d) { hex_encode_upper(d.sent()[d.sent().len() - 1]) }

// power differs from target seconds in a captured 20-second level-5 cook
fn test_power_and_time_in_a_20_second_level_5_cook() {
    expect_props(fed([cook_20s_level_5()]), #{ status: "cooking", power_level: "50", remaining_time: "20" });
}

// config exposes microwave status and controllable hood components
fn test_the_descriptor() {
    let desc = runtime::descriptor(fed([]));
    expect_eq(desc.props.status.options, ["idle", "cooking", "paused", "done", "ready_to_start"]);
    expect_eq(desc.props.remaining_time.unit, "s");
    expect_eq(desc.props.door.class, "door");
    expect_eq(desc.groups.vent.kind, "fan");
    expect_eq(desc.props.fan_speed.max, 2);
    expect_eq(desc.groups.light.kind, "light");
    expect_eq(desc.props.light_level.max, 2);
}

// initial status reports idle with both hood controls off
fn test_the_initial_status() {
    expect_props(fed([sample_initial_off()]), #{ status: "idle", remaining_time: "0", power_level: "0", fan_power: "false",
        fan_speed: "0", light_power: "false", light_level: "0" });
}

// 10-second high-power cook reports cooking, time, and power
fn test_a_10_second_high_cook() {
    expect_props(fed([sample_cooking_10_seconds_high()]), #{ status: "cooking", remaining_time: "10", power_level: "100" });
}

// 1:05 power-level-5 cook converts time and power to HA units
fn test_a_1_05_level_5_cook() {
    expect_props(fed([sample_cooking_1_05_power_5()]), #{ status: "cooking", remaining_time: "65", power_level: "50" });
}

// pause and completion states decode from real transitions
fn test_pause_and_done() {
    let d = fed([sample_paused_at_57_seconds()]);
    expect_props(d, #{ status: "paused", remaining_time: "57" });
    d.feed(sample_done());
    expect_props(d, #{ status: "done", remaining_time: "0" });
}

// door events publish open and closed states
fn test_the_door_events() {
    let d = fed([sample_door_open()]);
    expect_eq(d.property("door"), "true");
    d.feed(sample_door_closed());
    expect_eq(d.property("door"), "false");
}

// packed hood status decodes fan and light independently
fn test_the_packed_hood_status() {
    expect_props(fed([sample_fan_high_light_low()]), #{ fan_power: "true", fan_speed: "2", light_power: "true", light_level: "1" });
}

// fan speed command preserves the reported light state
fn test_a_fan_speed_command_keeps_the_light() {
    let d = fed([sample_light_low()]);
    d.set("fan_speed", "2");
    expect_eq(last_hex(d), "AA0EF043220401020101808043BB");
}

// light level command preserves the reported fan state
fn test_a_light_level_command_keeps_the_fan() {
    let d = fed([sample_fan_high()]);
    d.set("light_level", "2");
    expect_eq(last_hex(d), "AA0EF043220401020102808042BB");
}

// turning the fan off preserves the reported light state
fn test_fan_off_keeps_the_light() {
    let d = fed([sample_fan_high_light_low()]);
    d.set("fan_power", "false");
    expect_eq(last_hex(d), "AA0EF043220400000101808046BB");
}

// invalid numeric control values are ignored
fn test_invalid_numbers_send_nothing() {
    let d = fed([]);
    let n = d.sent().len();
    d.set("fan_speed", "not-a-number");
    d.set("light_level", "not-a-number");
    expect_eq(d.sent().len(), n);
}

// start sends the captured status query
fn test_start_sends_the_captured_query() {
    let d = fed([]);
    expect_eq(hex_encode_upper(d.sent()[0]), "AA28F0ED114101000000181A0207080C14191A1E262B30353A00000000000000000000000000F3BB");
}

// unknown status: upstream publishes "None"; here it stays unpublished
fn test_an_unknown_status_is_left_unpublished() {
    let f = hex_decode(sample_initial_off());
    f[4] = 0xff;
    let d = fed([f]);
    expect_eq(d.property("status"), ());
    expect_eq(d.property("remaining_time"), "0");
}

// unrecognised frame shapes are ignored
fn test_another_frame_is_ignored() { expect_eq(fed(["AA084100430063BB"]).property("status"), ()); }
