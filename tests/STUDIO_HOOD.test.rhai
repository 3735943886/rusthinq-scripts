import "runtime_test" as runtime;

// Tests of STUDIO_HOOD, ported from upstream rethink's test suite (commit 0e57069; live captures).
// Expected values are what upstream's driver publishes, in IL names (ON/OFF as true/false).

fn sample_ack() { "AA08430043006DBB" }
fn sample_delta_off_to_light1() { "AA1E43EC00000000000000000000000701000000000100000000000752BB" }
fn sample_delta_light1_to_light2() { "AA1E43EC0100000000010000000000070100000000020000000000075FBB" }
fn sample_delta_light2_to_off() { "AA1E43EC0100000000020000000000070000000000000000000000075DBB" }
fn sample_delta_off_to_fan1() { "AA1E43EC0000000000000000000000070101040000000000000000075EBB" }
fn sample_delta_fan3_reset_by_light_cmd() { "AA1E43EC01030400000000000000000701000000000200000000000745BB" }
fn sample_initial_status_fan1_light1() { "AA1243EB010104000001000000000007ADBB" }

fn fed(frames) { let d = device(); d.start(); for f in frames { d.feed(f); } d }
// The command just sent: [fan on, fan speed, light on, light level] after F0 43 22 05.
fn last_command(d) { let p = d.sent()[d.sent().len() - 1]; [p[6], p[7], p[8], p[9]] }

// config published on device creation with fan and light components
fn test_the_descriptor_has_a_fan_and_a_light() {
    let desc = runtime::descriptor(fed([]));
    expect_eq(desc.kind, "fan");
    expect_eq(desc.props.fan_power.role, "on");
    expect_eq(desc.props.fan_speed.max, 5);
    expect_eq(desc.groups.light.kind, "light");
    expect_eq(desc.props.light_power.group, "light");
    expect_eq(desc.props.light_level.max, 2);
}

// light turned on to level 1
fn test_light_on_to_level_1() {
    expect_props(fed([sample_delta_off_to_light1()]), #{ light_power: "true", light_level: "1", fan_power: "false", fan_speed: "0" });
}

// light level 1 -> 2
fn test_light_level_1_to_2() { expect_props(fed([sample_delta_light1_to_light2()]), #{ light_power: "true", light_level: "2" }); }

// light turned off
fn test_light_off() { expect_props(fed([sample_delta_light2_to_off()]), #{ light_power: "false", light_level: "0" }); }

// fan turned on to speed 1
fn test_fan_on_to_speed_1() {
    expect_props(fed([sample_delta_off_to_fan1()]), #{ fan_power: "true", fan_speed: "1", light_power: "false" });
}

// a light-only command resets a running fan to off (device requires full combined state)
fn test_a_light_command_resets_the_fan() {
    expect_props(fed([sample_delta_fan3_reset_by_light_cmd()]), #{ fan_power: "false", fan_speed: "0", light_power: "true", light_level: "2" });
}

// generic command ack frames are ignored (no property changes)
fn test_the_command_ack_is_ignored() {
    let d = fed([sample_delta_off_to_fan1()]);
    d.feed(sample_ack());
    expect_props(d, #{ fan_power: "true", fan_speed: "1", light_power: "false", light_level: "0" });
}

// 43 EB initial status (reply to start() query) decodes correctly
fn test_the_initial_status() {
    expect_props(fed([sample_initial_status_fan1_light1()]), #{ fan_power: "true", fan_speed: "1", light_power: "true", light_level: "1" });
}

// start() sends the status query packet on the wire
fn test_start_asks_for_the_status() {
    let d = fed([]);
    expect_eq(d.sent().len(), 1);
    expect_eq(hex_encode_upper(d.sent()[0]), "AA12F0ED1141010000001804030400005ABB");
}

// frames not matching the AA..BB envelope are ignored
fn test_a_non_aabb_frame_is_ignored() { expect_eq(fed(["001122"]).property("fan_power"), ()); }

// frames with unrecognised inner shape are ignored
fn test_another_inner_shape_is_ignored() { expect_eq(fed(["AA08109901020304BB"]).property("fan_power"), ()); }

// HA write fan_power=ON defaults to speed 1 and preserves light state
fn test_fan_on_defaults_to_speed_1() {
    let d = fed([sample_delta_off_to_light1()]);
    d.set("fan_power", "true");
    let p = d.sent()[d.sent().len() - 1];
    expect_eq([p[2], p[3]], [0xf0, 0x43]);
    expect_eq(last_command(d), [1, 1, 1, 1]);
}

// HA write fan_speed=3 (raw device speed, not a percentage) preserves light state
fn test_fan_speed_3_keeps_the_light() {
    let d = fed([sample_delta_light1_to_light2()]);
    d.set("fan_speed", "3");
    expect_eq(last_command(d), [1, 3, 1, 2]);
}

// HA write fan_power=OFF zeroes only the fan fields, preserving light
fn test_fan_off_keeps_the_light() {
    let d = fed([sample_delta_off_to_fan1(), sample_delta_light1_to_light2()]);
    d.set("fan_power", "false");
    expect_eq(last_command(d), [0, 0, 1, 2]);
}

// HA write light_power=ON defaults to level 1 and preserves fan state
fn test_light_on_defaults_to_level_1() {
    let d = fed([sample_delta_off_to_fan1()]);
    d.set("light_power", "true");
    expect_eq(last_command(d), [1, 1, 1, 1]);
}

// HA write light_level=2 preserves fan state
fn test_light_level_2_keeps_the_fan() {
    let d = fed([sample_delta_off_to_fan1()]);
    d.set("light_level", "2");
    expect_eq(last_command(d), [1, 1, 1, 2]);
}

// HA write to unknown property emits no packet
fn test_an_unknown_property_sends_nothing() {
    let d = fed([sample_delta_off_to_light1()]);
    let n = d.sent().len();
    d.set("nonsense", "whatever");
    d.set("fan_speed", "6"); // (IL) beyond the range
    expect_eq(d.sent().len(), n);
}
