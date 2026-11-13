import "runtime_test" as runtime;
import "tlv_test" as t;

// Tests of VENT_725601_WW.rhai (ventilator), ported from justicepng/rethink's
// VENT_725601_WW.ts (commit a44af31). The fork has no tests and no captures, so every frame here is
// constructed (tlv_test's 0xa7 notify envelope) from what the fork's code reads and writes. They
// check the port against the fork, not against an appliance.

// A state: on, auto, low, UVnano off, intake 22, exhaust 18, outdoor 5, controller 25.5,
// filters 28 % and 100 %, index 2.
fn state() {
    t::notify([[0x1f7, 1], [0x1f9, 0x27], [0x1fa, 2], [0x2a2, 0], [0x34c, 22], [0x34b, 18],
               [0x34a, 5], [0x1fd, 51], [0x355, 28], [0x38d, 100], [0x334, 2]])
}

fn ready() {
    let d = device();
    d.start();
    d.feed(state());
    d
}

// 40 bytes before "Z-H0151B2SR": CO2 612, indoor level 2 with PM10 30, PM2.5 18, PM1 9, outdoor
// PM10 45, PM2.5 27, PM1 14, outdoor level `out` at +16.
fn air_frame(out) {
    let b = blob();
    for x in [0, 0, 4, 0, 0, 0, 0xa7, 0xfd, 3] { b.push(x); }
    let body = [0x02, 0x64, 2, 0, 30, 0, 18, 0, 9, 0, 45, 0, 27, 0, 14, 0, out];
    while body.len() < 40 { body.push(0); }
    for x in body { b.push(x); }
    for x in [0x5a, 0x2d, 0x48, 0x30, 0x31, 0x35, 0x31, 0x42, 0x32, 0x53, 0x52] { b.push(x); }
    b.push(0); b.push(0);
    hex_encode(b)
}

fn test_the_descriptor() {
    let d = ready();
    let desc = runtime::descriptor(d);
    expect_eq(desc.kind, "fan");
    expect_eq(desc.props.mode.options, ["saving", "bypass", "auto"]);
    expect_eq(desc.props.fan.options, ["low", "high", "power"]);
    expect_eq(desc.props.fan.role, "fan_speed");
    expect_eq(desc.props.pm25["class"], "pm25");
    expect_eq(desc.props.carbon_dioxide["class"], "carbon_dioxide");
    expect_eq(desc.props.air_quality["class"], "air_quality");
    expect_eq(desc.props.air_quality.options, ["good", "moderate", "poor", "very_poor"]);
    expect_eq(d.script_error(), ());
}

fn test_a_state_becomes_il_properties() {
    expect_props(ready(), #{
        available: "true", power: "true", mode: "auto", fan: "low", uv_nano: "false",
        intake_temperature: "22", exhaust_temperature: "18", outdoor_temperature: "5",
        temperature: "25.5", pre_filter_life: "28", filter_life: "100", air_quality_index: "2"
    });
}

fn test_the_mode_and_fan_codes() {
    let d = ready();
    d.feed(t::notify([[0x1f9, 0x25], [0x1fa, 7]]));
    expect_props(d, #{ mode: "saving", fan: "power" });
    d.feed(t::notify([[0x1f9, 0x26], [0x1fa, 6]]));
    expect_props(d, #{ mode: "bypass", fan: "high" });
}

// The fork reads an unknown mode as auto and buckets fan codes by range; here they are absent.
fn test_an_unknown_code_is_absent() {
    let d = ready();
    d.feed(t::notify([[0x1f9, 0x30], [0x1fa, 4]]));
    expect_props(d, #{ mode: "", fan: "" });
}

// The fork takes any TLV frame as both handshake replies.
fn test_the_first_frame_ends_the_handshake() {
    let d = device();
    d.start();
    expect_eq(d.timers(), [["caps_retry", 15000]]);
    d.feed(t::notify([[0x1fa, 6]]));
    expect_eq(d.timers(), [["refresh", 900000]]);
    expect_eq(d.sent().len(), 2);
    expect_eq(hex_encode(d.sent()[1]), hex_encode(t::query(2)));
    d.feed(state());
    expect_eq(d.sent().len(), 2);
}

fn test_the_air_quality_frame() {
    let d = ready();
    d.feed(air_frame(3));
    expect_props(d, #{
        carbon_dioxide: "612", air_quality: "moderate", pm10: "30", pm25: "18", pm1: "9",
        outdoor_air_quality: "poor", outdoor_pm10: "45", outdoor_pm25: "27", outdoor_pm1: "14"
    });
    expect_eq(d.script_error(), ());
}

fn test_an_outdoor_level_out_of_range_skips_the_outdoor_group() {
    let d = ready();
    d.feed(air_frame(0));
    expect_eq(d.property("pm25"), "18");
    expect_eq(d.property("outdoor_pm25"), ());
}

fn test_power_writes() {
    let d = ready();
    let n = d.sent().len();
    d.set("power", "false");
    d.set("power", "true");
    expect_eq(t::sent_since(d, n), [
        [[0x1f7, 0]],
        [[0x1f7, 1], [0x1f9, 0x27], [0x1fa, 2]],
    ]);
    expect_eq(d.property("power"), "true"); // the state's, not the write's
}

fn test_power_on_without_a_state_uses_the_forks_defaults() {
    let d = device();
    d.start();
    d.set("power", "true");
    expect_eq(t::last_sent(d), [[0x1f7, 1], [0x1f9, 0x27], [0x1fa, 2]]);
}

fn test_fan_and_mode_writes() {
    let d = ready();
    let n = d.sent().len();
    d.set("fan", "high");
    d.set("mode", "saving");
    expect_eq(t::sent_since(d, n), [
        [[0x1f7, 1], [0x1fa, 6], [0x1f9, 0x27]],
        [[0x1f7, 1], [0x1f9, 0x25], [0x1fa, 6]],
    ]);
    expect_eq(d.property("fan"), "low"); // not optimistic
}

fn test_a_mode_write_while_off_is_refused() {
    let d = ready();
    d.feed(t::notify([[0x1f7, 0]]));
    let n = d.sent().len();
    d.set("mode", "bypass");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject").contains("off"), "refused because the unit is off");
}

fn test_uv_nano() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("uv_nano", "true");
    expect_eq(d.sent().len(), n); // no state yet
    d.feed(state());
    d.set("uv_nano", "true");
    expect_eq(t::last_sent(d), [[0x1f7, 1], [0x1f9, 0x27], [0x2a2, 1]]);
    expect_eq(d.property("uv_nano"), "false");
}

fn test_read_only_and_unknown_values_are_refused() {
    let d = ready();
    let n = d.sent().len();
    d.set("fan", "warp");
    d.set("mode", "ventilation"); // the fork's alias of bypass, not offered
    d.set("carbon_dioxide", "1");
    expect_eq(d.sent().len(), n);
}

fn test_reconnect_publishes_no_defaults() {
    let d = ready();
    d.drop_device();
    expect_eq(d.property("available"), "false");
    d.start();
    expect_props(d, #{ available: "true", mode: "auto", fan: "low" });
    expect_eq(d.script_error(), ());
}
