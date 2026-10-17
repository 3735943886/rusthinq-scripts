import "runtime_test" as runtime;

// Tests of WMVEL2137, ported from upstream rethink's test suite (commit 0e57069; captures from an
// LG MVEL2033F). Expected values are what upstream's driver publishes, in IL names (ON/OFF as
// true/false, "Not selected" as none); writes are compared byte for byte with upstream's.

fn sample_vent_turbo_lamp_high() { "AA6241EC003000015500000000000000FF030D000000000000000000000000000000C3000000005320008080808001000000003000015500000000000000FF030D000000000000000000000000000000C300000000532400808080800100000080BB" }
fn sample_vent_off_lamp_high() { "AA6241EC003000015500000000000000FF030D000000000000000000000000000000C3000000005324008080808001000000003000015500000000000000FF030D000000000000000000000000000000C300000000532000808080800100000080BB" }
fn sample_vent_low_lamp_high() { "AA6241EC003000015500000000000000FF030D000000000000000000000000000000C3000000005324008080808001000000003000015500000000000000FF030D000000000000000000000000000000C300000000532100808080800100000083BB" }
fn sample_lamp_low() { "AA6241EC003000015500000000000000FF030D000000000000000000000000000000C3000000005300008080808001000000003000015500000000000000FF030D000000000000000000000000000000C3000000005310008080808001000000F4BB" }
fn sample_cooking_full_power_5min() { "AA6241EC003000015500000000000000FF030D000000000000000000000000000000C3000000005300008080808001000000023000004401000000000A00FF030D000500000500000000000000000000C7000100005300018080808001000000C9BB" }
fn sample_cooking_4m59s() { "AA6241EC023000004401000000000A00FF030D000500000500000000000000000000C7000100005300018080808001000000023000004401000000000A00FF030D00043B000500000000000000000000C7000100005300018080808001000000B4BB" }
fn sample_paused() { "AA6241EC023000004401000000000A00FF030D00043B000500000000000000000000C7000100005300018080808001000000043000004401000000000A00FF030D00041E000500000000000000000000C700010000530001808080800100000055BB" }
fn sample_cooking_half_power_30s() { "AA6241EC073000004001000000000000FF030D000000000000000000000000000000C3000100005300008080808001000000023000004401000000000500FF030D00001E00001E000000000000000000C7000100005300018080808001000000E9BB" }
fn sample_done() { "AA6241EC023000004401000000000A00FF030D00001E00001E000000000000000000C7000100005300018080808001000000053000015500000000000000FF030D000000000000000000000000000000C300000000530000808080800100000086BB" }
fn sample_sensor_cook_settings() { "AA6241EC003000015500000000000000FF030D000000000000000000000000000000C300000000530000808080800100000007300000401800FE00000000FF030D000000000000000000000000000000E3000000005300008080808001000000EDBB" }
fn sample_auto_cook_running() { "AA6241EC07300000401F000000000000FF030D000000000000000000000000000000C300000000530000808080800100000002300000441F0D1200000A00FF030D00010A00010A000000000000000000C7000000005300018080808001000000A1BB" }
fn sample_sensor_cook_rice() { "AA6241EC07300000401800FF00000000FF030D000000000000000000000000000000E300000000530000808080800100000002300000441800FF00000000FF030D000000000000000000000000000000E3000000005300018080808001000000B4BB" }
fn sample_sensor_reheat_soup() { "AA6241EC073000004018010800000000FF030D000000000000000000000000000000E3000000005300008080808001000000023000004418010800000000FF030D000000000000000000000000000000E3000000005300018080808001000000A0BB" }
fn sample_soften_butter() { "AA6241EC07300000401F000000000000FF030D000000000000000000000000000000C300000000530000808080800100000002300000441F0D1A00000200FF030D000032000032000000000000000000C700000000530001808080800100000017BB" }
fn sample_defrost_running() { "AA6241EC07300000401500D300000000FF030D000000000000000000000000000000C300000000530000808080800100000002300000441500D400000700FF030D000A00000A00000000000000000000C700000000530001808080800100000031BB" }
fn sample_initial_status() { "AA3441EB003000015500000000000000FF030D000000000000000000000000000000C300000000532000808080800100000083BB" }
fn timer_90_minutes() { "aa6241ec003000014000000000000000ff030d000000000000000000000000000000c3000000005300008080808001000000003000015500000000000000ff030d000000000000005a00000000000000c300000000530000808080800100000083bb" }
fn cooking_90_minutes() { "aa6241ec073000004001000000000000ff030d000000000000000000000000000000c3000100005300008080808001000000023000004401000000000a00ff030d005a00011e00000000000000000000c7000100005300018080808001000000abbb" }

fn fed(frames) { let d = device(); d.start(); for f in frames { d.feed(f); } d }
fn last_hex(d) { hex_encode_upper(d.sent()[d.sent().len() - 1]) }

// config published on device creation
fn test_the_descriptor() {
    let desc = runtime::descriptor(fed([]));
    expect_eq(desc.props.status.options, ["idle", "cooking", "paused", "done", "settings"]);
    expect_eq(desc.props.remaining_time.class, "duration");
    expect_eq(desc.props.remaining_time.unit, "s");
    expect_eq(desc.props.timer.class, "duration");
    expect(desc.props.cook_item.options.contains("none"), "no dish chosen is an option");
    expect_eq(desc.props.cook_item.options.len(), 42);
    expect_eq(desc.groups.vent.kind, "fan");
    expect_eq(desc.props.fan_speed.max, 4);
    expect_eq(desc.groups.light.kind, "light");
    expect_eq(desc.props.light_level.max, 2);
}

// start() sends the status query the LG cloud uses
fn test_start_sends_the_status_query() {
    expect_eq(hex_encode_upper(fed([]).sent()[0]), "AA1CF0ED114101000000180E111718191A1A1B0000000000000091BB");
}

// vent speed and lamp level come from opposite nibbles of one byte
fn test_vent_and_lamp_nibbles() {
    let d = fed([sample_vent_turbo_lamp_high()]);
    expect_props(d, #{ fan_speed: "4", fan_power: "true", light_level: "2", light_power: "true" });
    d.feed(sample_vent_low_lamp_high());
    expect_props(d, #{ fan_speed: "1", light_level: "2" });
    d.feed(sample_vent_off_lamp_high());
    expect_props(d, #{ fan_speed: "0", fan_power: "false", light_level: "2" });
    d.feed(sample_lamp_low());
    expect_props(d, #{ fan_speed: "0", light_level: "1" });
}

// setting the vent speed sends an absolute level and leaves the lamp alone
fn test_a_vent_speed_is_absolute() {
    let d = fed([]);
    d.set("fan_speed", "1");
    expect_eq(last_hex(d), "AA0EF043220401018080808046BB");
    d.set("fan_speed", "2");
    expect_eq(last_hex(d), "AA0EF043220401028080808041BB");
}

// setting the lamp level leaves the vent alone
fn test_a_lamp_level_leaves_the_vent() {
    let d = fed([]);
    d.set("light_level", "1");
    expect_eq(last_hex(d), "AA0EF043220480800101808046BB");
}

// turning a control off sends the off command for that control only
fn test_off_touches_one_control() {
    let d = fed([]);
    d.set("light_power", "false");
    expect_eq(last_hex(d), "AA0EF043220480800000808044BB");
    d.set("fan_power", "false");
    expect_eq(last_hex(d), "AA0EF043220400008080808044BB");
}

// turning a control on restores the level it last reported
fn test_on_restores_the_last_level() {
    let d = fed([sample_vent_turbo_lamp_high()]);
    d.set("fan_power", "true");
    expect_eq(last_hex(d), "AA0EF043220401048080808043BB");
    d.set("light_power", "true");
    expect_eq(last_hex(d), "AA0EF043220480800102808041BB");
}

// out-of-range levels: upstream clamps them; under IL validation they are refused
fn test_out_of_range_levels_are_refused() {
    let d = fed([]);
    let n = d.sent().len();
    d.set("fan_speed", "9");
    d.set("light_level", "not a number");
    expect_eq(d.sent().len(), n);
}

// cooking state, mode, power level and remaining time
fn test_cooking() {
    let d = fed([sample_cooking_full_power_5min()]);
    expect_props(d, #{ status: "cooking", cook_mode: "microwave", power_level: "100", remaining_time: "300" });
    d.feed(sample_cooking_4m59s());
    expect_eq(d.property("remaining_time"), "299");
    d.feed(sample_cooking_half_power_30s());
    expect_props(d, #{ power_level: "50", remaining_time: "30", cook_time: "30" });
}

// a duration over an hour keeps counting in minutes, it does not borrow
fn test_a_90_minute_timer() { expect_eq(fed([timer_90_minutes()]).property("timer"), "5400"); }

// the cook length is kept apart from what is left of it
fn test_cook_length_and_remaining_time() {
    let d = fed([sample_cooking_full_power_5min()]);
    expect_props(d, #{ cook_time: "300", remaining_time: "300" });
    d.feed(sample_cooking_4m59s());
    expect_props(d, #{ cook_time: "300", remaining_time: "299" });
    d.feed(cooking_90_minutes());
    expect_props(d, #{ cook_time: "5400", remaining_time: "5400" });
}

// paused, done and settings states
fn test_paused_done_and_settings() {
    let d = fed([sample_paused()]);
    expect_props(d, #{ status: "paused", remaining_time: "270" });
    d.feed(sample_done());
    expect_props(d, #{ status: "done", remaining_time: "0" });
    d.feed(sample_sensor_cook_settings());
    expect_props(d, #{ status: "settings", cook_mode: "sensor_cook" });
}

// a preset run reports the auto cook mode
fn test_a_preset_run() {
    expect_props(fed([sample_auto_cook_running()]), #{ status: "cooking", cook_mode: "auto_cook", power_level: "100", remaining_time: "70" });
}

// the dish is read as one 16-bit id spanning both of its bytes
fn test_the_dish_id() {
    let d = fed([sample_sensor_cook_rice()]);
    expect_props(d, #{ cook_mode: "sensor_cook", cook_item: "rice" });
    d.feed(sample_sensor_reheat_soup());
    expect_eq(d.property("cook_item"), "reheat_soup_or_sauce");
    d.feed(sample_auto_cook_running());
    expect_eq(d.property("cook_item"), "kids_mac_and_cheese");
    d.feed(sample_soften_butter());
    expect_props(d, #{ cook_mode: "auto_cook", cook_item: "soften_butter", power_level: "20" });
    d.feed(sample_initial_status());
    expect_eq(d.property("cook_item"), "none");
}

// (beyond upstream's tests) an unlisted dish clears the last one rather than keeping it
fn test_an_unlisted_dish_is_cleared() {
    let d = fed([sample_sensor_cook_rice()]);
    let f = hex_decode(sample_initial_status());
    f[10] = 0x0f; f[11] = 0xff; // dish 4095, not in the table
    d.feed(f);
    expect_eq(d.property("cook_item"), ""); // absent, an empty retained value
}

// a defrost run reports its mode and the power level the appliance chose
fn test_a_defrost_run() {
    expect_props(fed([sample_defrost_running()]), #{ status: "cooking", cook_mode: "inverter_defrost", power_level: "70", remaining_time: "600" });
}

// the single-record 41 EB reply decodes like the 41 EC current record
fn test_the_eb_reply() {
    expect_props(fed([sample_initial_status()]), #{ status: "idle", cook_mode: "off", fan_speed: "0", light_level: "2" });
}

// frames of the wrong length or class publish nothing
fn test_wrong_frames_publish_nothing() {
    let d = fed(["AA0B413E000D000D001BBB", "AA6141EC003000015500000000000000FFBB"]);
    expect_eq(d.property("status"), ());
    expect_eq(d.property("fan_speed"), ());
}
