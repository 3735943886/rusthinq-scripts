import "runtime_test" as runtime;

// Tests of AIR_910604_WW.rhai, against frames captured from a real appliance.

import "tlv_test" as t;

fn caps() { "000004000000a702012650b00cb07001e000b0a001d4b3200800b340b4d080b584b540b6a032f8b6e02115b700b7509fbc50c1b3c0b42001d4b441bd206004bd501fb5d010b600b648b5cdb600b648b5cfb600b648b5ceb600b6485437" }
fn values() { "000004000000a7020429647dc07e50107e887f007f807f5050868086c087008980d7c0d801d840d88087809380cd4acd08ccc890419001cd901e8840d5600e7bd5a00fa0d8e00e56d9200fa0ce80ab00c988c9c0ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eebf9" }

fn running() { t::running(device(), caps(), values()) }

fn test_the_captured_state_becomes_il_properties() {
    expect_props(running(), #{
        available: "true", power: "false", mode: "auto", fan: "auto", sterilize: "true",
        light: "false", pm1: "8", "pm2.5": "8", pm10: "10", air_quality: "1", odor: "1",
        filter_life: "93",      // 3707 of 4000 hours left
        top_filter_life: "92",  // 3670 of 4000
        sleep_timer: "0", error: "0"
    });
}

fn test_temperature_and_humidity_are_not_exposed() {
    let d = running();
    expect_eq(d.property("temperature"), ());
    expect_eq(d.property("humidity"), ());
}

fn test_power_on_restores_mode_and_fan_in_the_same_frame() {
    let d = running();
    d.set("power", "true");
    expect_eq(t::last_sent(d), [[0x1f7, 1], [0x1f9, 16], [0x1fa, 8]]);
}

fn test_power_off_sends_only_the_power_tag() {
    let d = running();
    d.set("power", "false");
    expect_eq(t::last_sent(d), [[0x1f7, 0]]);
}

fn test_a_fan_write_forces_power_on_and_carries_the_mode() {
    let d = running();
    d.set("fan", "high");
    expect_eq(t::last_sent(d), [[0x1fa, 6], [0x1f7, 1], [0x1f9, 16]]);
}

fn test_a_mode_write_forces_power_on_and_carries_the_fan() {
    let d = running();
    d.set("mode", "baby_care");
    expect_eq(t::last_sent(d), [[0x1f9, 14], [0x1f7, 1], [0x1fa, 8]]);
}

fn test_light_sterilize_and_sleep_timer_are_bare_writes() {
    let d = running();
    d.set("light", "true");
    expect_eq(t::last_sent(d), [[0x24e, 1]]);
    d.set("sterilize", "false");
    expect_eq(t::last_sent(d), [[0x360, 0]]);
    d.set("sleep_timer", "60");
    expect_eq(t::last_sent(d), [[0x21a, 60]]);
}

fn test_bad_writes_are_rejected_and_send_nothing() {
    let d = running();
    let n = d.sent().len();
    d.set("fan", "warp");
    d.set("mode", "turbo");
    d.set("sleep_timer", "9999");
    d.set("pm25", "1"); // read only
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "a reject event was published");
}

fn test_filter_life_recomputes_when_only_the_hours_left_arrive() {
    let d = running();
    // a later notify carries just the bottom filter's hours left: 3600 of 4000
    d.feed(t::notify([[0x355, 3600]]));
    expect_eq(d.property("filter_life"), "90");
}

fn test_the_descriptor_is_an_air_purifier_with_roles() {
    let d = device();
    d.start();
    let desc = runtime::descriptor(d);
    expect_eq(desc.kind, "fan");
    expect_eq(desc["class"], "air_purifier");
    expect_eq(desc.props.fan.role, "fan_speed");
    expect_eq(desc.props.mode.role, "mode");
}

fn test_the_handshake_is_the_shared_one() {
    let d = device();
    d.start();
    expect_eq(d.timers(), [["caps_retry", 15000]]);
    d.feed(caps());
    expect_eq(d.timers(), [["values_retry", 15000]]);
    d.feed(values());
    expect_eq(d.timers(), [["refresh", 900000]]);
}

fn test_il_common_refuses_what_the_descriptor_forbids_before_the_script_sees_it() {
    let d = running();
    let n = d.sent().len();
    d.set("sleep_timer", "9999"); // above the maximum of 720
    d.set("sleep_timer", "65");   // the step is 10
    d.set("fan", "warp");         // not one of the options
    d.set("pm25", "1");           // read only
    d.set("nope", "1");           // not in the descriptor at all
    expect_eq(d.sent().len(), n);
    expect(d.event("reject").contains("unknown property"), "the last refusal is for the unknown property");
}

fn test_a_stray_notification_before_the_values_does_not_end_the_retry() {
    let d = device();
    d.start();
    d.feed(caps());
    d.feed(t::notify([[0x1fa, 6]]));
    expect_eq(d.timers(), [["values_retry", 15000]]);
    expect_eq(d.property("available"), "true"); // connected, state not received yet
    d.feed(values());
    expect_eq(d.timers(), [["refresh", 900000]]);
    expect_eq(d.property("available"), "true");
}

// Availability follows the online lifecycle, independently of state reports.
fn test_reconnect_restores_availability_without_a_state_frame() {
    let d = device();
    d.start();
    expect_eq(d.script_error(), ());
    expect_eq(d.property("available"), "true");
    d.drop_device();
    expect_eq(d.property("available"), "false");
    d.start();
    expect_eq(d.property("available"), "true");
    expect_eq(d.script_error(), ());
}
// BEGIN PR VECTORS
// Regression vectors from rethink PR #172 (eb15cc6954db7d68d1a71c55280f995cf02ad5dc).
// Original test names are retained below. Expected TX bytes come from executing the TS driver.

// discovery is immediate and a delta-first connection publishes state
fn test_pr_172_1() {
    let d = device();
    d.feed("000004000000a7020425627dc17e4f7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64e6b03");
    expect_props(d, #{"power": "true", "mode": "dual_clean", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// real full frame publishes discovery and initial state
fn test_pr_172_2() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// filter counters publish raw remaining and lifetime hours
fn test_pr_172_3() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702040004d56001f478a9");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "500", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702040004d5a003e8eb81");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "500", "filter_life_time": "1000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// owner-labelled mode transitions decode without inventing unsupported modes
fn test_pr_172_4() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020455027e4d9a6b");
    expect_props(d, #{"power": "true", "mode": "circulator_clean", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020430027e4e4f9f");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020425627dc17e4f7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64e6b03");
    expect_props(d, #{"power": "true", "mode": "dual_clean", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702044e037e5010b0fc");
    expect_props(d, #{"power": "true", "mode": "auto", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// clean-booster fan high and turbo deltas decode
fn test_pr_172_5() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702046702c986b457");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "high", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702046b02c987eb44");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "power", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// main fan state uses 0x1fa independently of clean-booster fan 0x326
fn test_pr_172_6() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702047b147e82b5cdb600b642b5cfb600b642b5ceb60eb64e5078");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "low", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// circulation rotation, indicator, and sanitization round trips decode
fn test_pr_172_7() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702046d02c9c0f4fe");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702046e02c9c17f03");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020480029380e022");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "false", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204820293811d6b");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702048402d8006a6d");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "false", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702048502d8010cf8");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// sleep timer is minutes, counts down, and restores the indicator on cancel
fn test_pr_172_8() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702048605869078938038e2");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "120", "sterilize": "true", "light": "false", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702048a038690774aa4");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "119", "sterilize": "true", "light": "false", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702048b04868093817146");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// short delta frames preserve omitted state and power round trip decodes
fn test_pr_172_9() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702048c0a7dc09380ac600100ac84acd5");
    expect_props(d, #{"power": "false", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "false", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702048f0a7dc19381ac600100ac80ba8c");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each single-tag write reproduces the frame the app itself sent
fn test_pr_172_10() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("booster_fan", "mid");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(hex_encode(d.sent()[0]), "0101040000006502010104c9847dc16104");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each single-tag write reproduces the frame the app itself sent
fn test_pr_172_11() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("booster_fan", "power");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(hex_encode(d.sent()[0]), "0101040000006502010104c9877dc13854");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each single-tag write reproduces the frame the app itself sent
fn test_pr_172_12() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("circulation_rotation", "false");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(hex_encode(d.sent()[0]), "0101040000006502010102c9c0d7bf");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each single-tag write reproduces the frame the app itself sent
fn test_pr_172_13() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("circulation_rotation", "true");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(hex_encode(d.sent()[0]), "0101040000006502010102c9c1c79e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each single-tag write reproduces the frame the app itself sent
fn test_pr_172_14() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("light", "false");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(hex_encode(d.sent()[0]), "010104000000650201010293807e0f");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each single-tag write reproduces the frame the app itself sent
fn test_pr_172_15() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("light", "true");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(hex_encode(d.sent()[0]), "010104000000650201010293816e2e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each single-tag write reproduces the frame the app itself sent
fn test_pr_172_16() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("sterilize", "false");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(hex_encode(d.sent()[0]), "0101040000006502010102d8003eb1");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each single-tag write reproduces the frame the app itself sent
fn test_pr_172_17() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("sterilize", "true");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(hex_encode(d.sent()[0]), "0101040000006502010102d8012e90");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each single-tag write reproduces the frame the app itself sent
fn test_pr_172_18() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("sleep_timer", "0");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(hex_encode(d.sent()[0]), "010104000000650201010286808289");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// mode and fan writes force power on, because the unit ignores them while off
fn test_pr_172_19() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("mode", "baby_care");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020101067e4e7dc17e886551");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("mode", "circulator_clean");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(hex_encode(d.sent()[1]), "01010400000065020101067e4d7dc17e888b83");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("fan", "high");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(hex_encode(d.sent()[2]), "01010400000065020101067e867dc17e4ddd2d");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// power on restores mode and fan in one frame; power off does not
fn test_pr_172_20() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("power", "true");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020101067dc17e4e7e88602f");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("power", "false");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(hex_encode(d.sent()[1]), "01010400000065020101027dc00576");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// sensors are not writable and malformed frames change nothing
fn test_pr_172_21() {
    let d = device();
    d.feed("000004000000a7020464627dc17e4e7e887f007f807f5050868086c087008980d7c0d801d840d88087809381cd48cd08ccc890419001cd901e8840d55022d5a00fa0d8e00c75d9200fa0ce80ab00c988c9c1ca00b5d010b600b648b5cdb600b648b5cfb600b648b5ceb60eb64eafaa");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("pm25", "42");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("air_quality", "42");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("error", "42");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("filter_remaining_time", "42");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020464627dc17e4e7e88");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("00010203");
    expect_props(d, #{"power": "true", "mode": "baby_care", "fan": "auto", "sleep_timer": "0", "sterilize": "true", "light": "true", "pm10": "8", "pm25": "8", "pm1": "8", "odor": "1", "air_quality": "1", "error": "0", "filter_remaining_time": "34", "filter_life_time": "4000", "top_filter_remaining_time": "3189", "top_filter_life_time": "4000", "booster_fan": "auto", "circulation_rotation": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}
