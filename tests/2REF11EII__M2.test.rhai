import "runtime_test" as runtime;

// Tests of 2REF11EII__M2, ported from upstream rethink's test suite (commit 2d8eaba; captures from
// a US unit set to °F, and the F0 17 commands the LG cloud sent). Expected values and writes are
// what upstream's driver publishes and sends for the same input, in IL names; a value upstream
// leaves unknown is absent (an empty retained value) or never published.

fn sample_delta_express_off() { "AA1810EC020C08020202040000020C08010202040000A8BB" }
fn sample_delta_fridge_36f() { "AA1810EC020C08010202040000020B08010202040000AEBB" }
fn cloud_cmd_express_off() { "AA2FF017FFFFFF01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000FFFF00FFFFFFFF00FFFFFFFFFFFFFFFFFFEBBB" }
fn cloud_cmd_fridge_36f() { "AA2FF017FF0BFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFF000000FFFF00FFFFFFFF00FFFFFFFFFFFFFFFFFF9CBB" }
fn sample_delta_freezer_m3f() { "AA1810EC020B08010202040000020B0B010202040000A8BB" }
fn cloud_cmd_freezer_m3f() { "AA2FF017FFFF0BFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFF000000FFFF00FFFFFFFF00FFFFFFFFFFFFFFFFFF9CBB" }
fn cloud_cmd_freezer_0f() { "AA2FF017FFFF08FFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFF000000FFFF00FFFFFFFF00FFFFFFFFFFFFFFFFFF93BB" }
fn sample_delta_fresh_air_power() { "AA1810EC020B08010202040000020B08010302040000AEBB" }
fn cloud_cmd_fresh_air_power() { "AA2FF017FFFFFFFF03FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000FFFF00FFFFFFFF00FFFFFFFFFFFFFFFFFF95BB" }
fn sample_delta_fresh_air_auto() { "AA1810EC020B08010302040000020B08010202040000AEBB" }
fn cloud_cmd_fresh_air_auto() { "AA2FF017FFFFFFFF02FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000FFFF00FFFFFFFF00FFFFFFFFFFFFFFFFFFEABB" }
fn sample_delta_smart_grid_off() { "AA1810EC020B08010202040000020B08010200040000ADBB" }
fn cloud_cmd_smart_grid_off() { "AA2FF017FFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000FFFF00FFFFFFFF00FFFFFFFFFFFFFFFFFFE8BB" }
fn sample_delta_smart_grid_peak() { "AA1810EC020C08010200040000020C08010203040000AEBB" }
fn sample_delta_smart_grid_seasonal() { "AA1810EC020B08010200040000020B08010202040000ADBB" }
fn cloud_cmd_smart_grid_seasonal() { "AA2FF017FFFFFFFFFF02FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000FFFF00FFFFFFFF00FFFFFFFFFFFFFFFFFFEABB" }
fn sample_delta_door_open() { "AA1810EC020B08010202040000020B08010202040100AEBB" }
fn sample_delta_door_closed() { "AA1810EC020B08010202040100020B08010202040000AEBB" }
fn fridge_door_open() { "AA0810A8010139BB" }
fn fridge_door_closed() { "AA0810A801003EBB" }
fn freezer_door_open() { "AA0810A8020138BB" }
fn freezer_door_closed() { "AA0810A8020039BB" }
fn sample_delta_celsius() { "AA1810EC020B08010202040000020C09010202040001A8BB" }
fn cloud_cmd_start_query() { "AA0EF0ED1211010000010400EBBB" }
fn sample_initial() { "AA0F10EB020C0801020204000086BB" }

fn fed(frames) { let d = device(); d.start(); for f in frames { d.feed(f); } d }
fn write(prop, value) {
    let d = fed([sample_delta_express_off()]);
    let n = d.sent().len();
    d.set(prop, value);
    d.sent().extract(n).map(|s| hex_encode_upper(s))
}
fn props(d) { runtime::descriptor(d).props }

// start() reproduces the query the cloud sends on reconnect
fn test_start_asks_for_the_status() {
    let d = device();
    d.start();
    expect_eq(d.sent().map(|s| hex_encode_upper(s)), [cloud_cmd_start_query()]);
}

// 10EB initial status is a single 9-byte block
fn test_the_initial_status() {
    expect_props(fed([sample_initial()]), #{ fridge_setpoint: "35", freezer_setpoint: "0", express_freeze: "false",
        fresh_air_filter: "auto", water_filter: "false", water_filter_months: "4", fresh_air_filter_replace: "false",
        smart_grid: "seasonal_energy_saver", fridge_door: "false", freezer_door: "false" });
}

// Fahrenheit config comes from the model-JSON tables, not a linear range
fn test_the_fahrenheit_descriptor() {
    let p = props(fed([sample_delta_express_off()]));
    expect_eq([p.fridge_setpoint.unit, p.fridge_setpoint.min, p.fridge_setpoint.max], ["°F", 33, 46]);
    expect_eq([p.freezer_setpoint.unit, p.freezer_setpoint.min, p.freezer_setpoint.max], ["°F", -6, 8]);
    expect_eq(p.fresh_air_filter.options, ["auto", "power"]);
    expect_eq([p.water_filter.class, p.fresh_air_filter_replace.class], ["problem", "problem"]);
    expect(!p.contains("flex_setpoint"), "no flex drawer on this model");
}

// baseline state decodes to the values the LG app showed (35°F / 0°F)
fn test_the_baseline() {
    expect_props(fed([sample_delta_express_off()]), #{ fridge_setpoint: "35", freezer_setpoint: "0",
        express_freeze: "false", fridge_door: "false", freezer_door: "false" });
}

// fridge setpoint transition 35°F -> 36°F
fn test_fridge_36f() {
    expect_eq(fed([sample_delta_express_off(), sample_delta_fridge_36f()]).property("fridge_setpoint"), "36");
}

// the status block's door-open flag doesn't say which door, so it changes nothing
fn test_the_status_door_flag() {
    let d = fed([sample_delta_door_open()]);
    expect_eq([d.property("fridge_door"), d.property("freezer_door")], [(), ()]);
    d.feed(fridge_door_open());
    d.feed(sample_delta_door_open());
    expect_eq(d.property("fridge_door"), "true");
}

// 10A8 events give per-compartment door state
fn test_compartment_doors() {
    let d = fed([freezer_door_open()]);
    expect_eq([d.property("freezer_door"), d.property("fridge_door")], ["true", ()]);
    d.feed(freezer_door_closed());
    expect_eq(d.property("freezer_door"), "false");
    d.feed(fridge_door_open());
    expect_props(d, #{ fridge_door: "true", freezer_door: "false" });
    d.feed(fridge_door_closed());
    expect_eq(d.property("fridge_door"), "false");
}

// the status block's all-closed flag resynchronises per-compartment state
fn test_the_all_closed_flag() {
    let d = fed([fridge_door_open()]);
    expect_eq(d.property("fridge_door"), "true");
    d.feed(sample_delta_door_closed());
    expect_props(d, #{ fridge_door: "false", freezer_door: "false" });
}

// switching the panel to Celsius reports the same temperatures in the other unit
fn test_switching_to_celsius() {
    let d = fed([sample_delta_express_off(), sample_delta_fridge_36f()]);
    expect_props(d, #{ fridge_setpoint: "36", freezer_setpoint: "0" });
    d.feed(sample_delta_celsius());
    let p = props(d);
    expect_eq([p.fridge_setpoint.unit, p.fridge_setpoint.min, p.fridge_setpoint.max], ["°C", 1, 8]);
    expect_eq([p.freezer_setpoint.unit, p.freezer_setpoint.min, p.freezer_setpoint.max], ["°C", -21, -13]);
    expect_props(d, #{ fridge_setpoint: "2", freezer_setpoint: "-18" });
}

// HA write fridge_setpoint=36°F reproduces the cloud command byte-for-byte
fn test_write_fridge_36f() { expect_eq(write("fridge_setpoint", "36"), [cloud_cmd_fridge_36f()]); }

// HA write express_freeze=OFF reproduces the cloud command byte-for-byte
fn test_write_express_freeze_off() { expect_eq(write("express_freeze", "false"), [cloud_cmd_express_off()]); }

// freezer setpoint transition 0°F -> -3°F (linear formula would say -5°F)
fn test_freezer_m3f() { expect_eq(fed([sample_delta_freezer_m3f()]).property("freezer_setpoint"), "-3"); }

// HA write freezer_setpoint=-3°F reproduces the cloud command byte-for-byte
fn test_write_freezer_m3f() { expect_eq(write("freezer_setpoint", "-3"), [cloud_cmd_freezer_m3f()]); }

// 10AF telemetry and 10AB diagnostics are ignored
fn test_other_frames_are_ignored() {
    expect_eq(fed(["AA0B10AF2700130B0894BB", "AA06F014E1BB"]).property("fridge_setpoint"), ());
}

// HA write freezer_setpoint=0°F reproduces the cloud command byte-for-byte
fn test_write_freezer_0f() { expect_eq(write("freezer_setpoint", "0"), [cloud_cmd_freezer_0f()]); }

// fresh air filter transition Auto -> Power
fn test_fresh_air_power() {
    expect_props(fed([sample_delta_fresh_air_power()]), #{ fresh_air_filter: "power", fresh_air_filter_replace: "false" });
}

// HA write fresh_air_filter=Power reproduces the cloud command byte-for-byte
fn test_write_fresh_air_power() { expect_eq(write("fresh_air_filter", "power"), [cloud_cmd_fresh_air_power()]); }

// the app's fresh-air "off" is really Auto
fn test_fresh_air_auto() {
    expect_eq(fed([sample_delta_fresh_air_auto()]).property("fresh_air_filter"), "auto");
    expect_eq(write("fresh_air_filter", "auto"), [cloud_cmd_fresh_air_auto()]);
}

// fresh air filter mode holds its last value through Off and Replace (synthetic: the Power
// capture with only the current record's byte 4 changed)
fn test_fresh_air_holds_through_off_and_replace() {
    let with_fresh_air = |code| { let b = hex_decode("10EC020B08010302040000020B08010302040000"); b[2 + 9 + 4] = code; hex_encode(aabb_wrap(b)) };
    let d = fed([sample_delta_fresh_air_power()]);
    expect_eq(d.property("fresh_air_filter"), "power");
    d.feed(with_fresh_air.call(4));
    expect_props(d, #{ fresh_air_filter: "power", fresh_air_filter_replace: "true" });
    d.feed(with_fresh_air.call(1));
    expect_props(d, #{ fresh_air_filter: "power", fresh_air_filter_replace: "false" });
}

// smart grid decodes the three usable modes, not the model JSON enum codes
fn test_smart_grid() {
    let d = fed([sample_delta_express_off()]);
    expect_eq(d.property("smart_grid"), "seasonal_energy_saver");
    d.feed(sample_delta_smart_grid_off());
    expect_eq(d.property("smart_grid"), "not_in_use");
    d.feed(sample_delta_smart_grid_seasonal());
    expect_eq(d.property("smart_grid"), "seasonal_energy_saver");
    d.feed(sample_delta_smart_grid_peak());
    expect_eq(d.property("smart_grid"), "peak_energy_saver");
}

// HA write smart_grid reproduces both captured cloud commands byte-for-byte
fn test_write_smart_grid() {
    expect_eq(write("smart_grid", "not_in_use"), [cloud_cmd_smart_grid_off()]);
    expect_eq(write("smart_grid", "seasonal_energy_saver"), [cloud_cmd_smart_grid_seasonal()]);
}

// fresh air filter states the appliance only reports are refused as writes
fn test_reported_fresh_air_states_are_refused() {
    expect_eq(write("fresh_air_filter", "replace_filter"), []);
    expect_eq(write("fresh_air_filter", "off"), []);
}

// a Fahrenheit freezer value with no code is refused, not approximated
fn test_a_freezer_value_without_a_code() {
    let d = fed([sample_delta_express_off()]);
    let n = d.sent().len();
    d.set("freezer_setpoint", "7"); // the °F table jumps 8 -> 6
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "reject");
}

// an unknown property is ignored
fn test_an_unknown_property() { expect_eq(write("does-not-exist", "1"), []); }
