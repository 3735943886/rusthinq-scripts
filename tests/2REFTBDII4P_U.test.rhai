import "runtime_test" as runtime;

// Tests of 2REFTBDII4P_U.rhai (fridge), ported from upstream rethink's test suite (commit
// 0e57069; real captures bridged to the LG cloud). Expected values and writes are what upstream's driver
// publishes and sends for the same input.

fn sample_door_open() { "AA8E10EC0207040102FF0200010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF620101FF000001FFFFFFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000207040102FF0201010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF620101FF000001FFFFFFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF0000EABB" }
fn sample_door_closed() { "AA8E10EC0207040102FF0201010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF620101FF000001FFFFFFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000207040102FF0200010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF620101FF000001FFFFFFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF0000EABB" }
fn sample_express_on() { "AA8E10EC0207040102FF0200010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF620101FF000001FFFFFFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000207040202FF0200010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF620101FF000001FFFFFFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF0000EABB" }
fn sample_fridge_2c() { "AA8E10EC0207040102FF0200010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF620101FF000001FFFFFFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000206040102FF0200010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF620101FF000001FFFFFFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF0000E8BB" }
fn sample_freezer_minus_17c() { "AA8E10EC0207040102FF0200010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF620101FF000001FFFFFFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000207030102FF0200010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF620101FF000001FFFFFFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF0000E8BB" }
fn sample_ice_full() { "AA8E10EC0207040102FF0200010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF620101FF000001FFFFFFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF00000207040102FF0200010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF620101FF000002FFFFFFFFFFFFFF01FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FF0000EABB" }

fn last(d) { let s = d.sent(); hex_encode_upper(s[s.len() - 1]) }

fn test_sample_door_open() {
    let d = device();
    d.feed(sample_door_open());
    expect_props(d, #{ fridge_setpoint: "1", freezer_setpoint: "-18", express_freeze: "false", fresh_air_filter_status: "good", water_filter_status: "good", water_filter_months: "2", door: "true", fridge_temperature_status: "well_maintained", freezer_temperature_status: "well_maintained", ice_maker_status: "making_ice" });
}

fn test_sample_door_closed() {
    let d = device();
    d.feed(sample_door_closed());
    expect_props(d, #{ fridge_setpoint: "1", freezer_setpoint: "-18", express_freeze: "false", fresh_air_filter_status: "good", water_filter_status: "good", water_filter_months: "2", door: "false", fridge_temperature_status: "well_maintained", freezer_temperature_status: "well_maintained", ice_maker_status: "making_ice" });
}

fn test_sample_express_on() {
    let d = device();
    d.feed(sample_express_on());
    expect_props(d, #{ fridge_setpoint: "1", freezer_setpoint: "-18", express_freeze: "true", fresh_air_filter_status: "good", water_filter_status: "good", water_filter_months: "2", door: "false", fridge_temperature_status: "well_maintained", freezer_temperature_status: "well_maintained", ice_maker_status: "making_ice" });
}

fn test_sample_fridge_2c() {
    let d = device();
    d.feed(sample_fridge_2c());
    expect_props(d, #{ fridge_setpoint: "2", freezer_setpoint: "-18", express_freeze: "false", fresh_air_filter_status: "good", water_filter_status: "good", water_filter_months: "2", door: "false", fridge_temperature_status: "well_maintained", freezer_temperature_status: "well_maintained", ice_maker_status: "making_ice" });
}

fn test_sample_freezer_minus_17c() {
    let d = device();
    d.feed(sample_freezer_minus_17c());
    expect_props(d, #{ fridge_setpoint: "1", freezer_setpoint: "-17", express_freeze: "false", fresh_air_filter_status: "good", water_filter_status: "good", water_filter_months: "2", door: "false", fridge_temperature_status: "well_maintained", freezer_temperature_status: "well_maintained", ice_maker_status: "making_ice" });
}

fn test_sample_ice_full() {
    let d = device();
    d.feed(sample_ice_full());
    expect_props(d, #{ fridge_setpoint: "1", freezer_setpoint: "-18", express_freeze: "false", fresh_air_filter_status: "good", water_filter_status: "good", water_filter_months: "2", door: "false", fridge_temperature_status: "well_maintained", freezer_temperature_status: "well_maintained", ice_maker_status: "full" });
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
    d.feed(sample_door_closed());
    for w in [
        ["fridge_setpoint", "2", "AA7CF017FF06FFFFFFFFFFFF01FFFFFFFFFFFFFFFFFFFFFFFF000000FFFF00FFFFFFFF00FFFFFFFFFFFFFFFFFF00FFFFFF1EFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0AFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA4BB"],
        ["freezer_setpoint", "-17", "AA7CF017FFFF03FFFFFFFFFF01FFFFFFFFFFFFFFFFFFFFFFFF000000FFFF00FFFFFFFF00FFFFFFFFFFFFFFFFFF00FFFFFF1EFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0AFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBBBB"],
        ["express_freeze", "true", "AA7CF017FFFFFF02FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000FFFF00FFFFFFFF00FFFFFFFFFFFFFFFFFF00FFFFFF1EFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0AFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBEBB"],
        ["express_freeze", "false", "AA7CF017FFFFFF01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000FFFF00FFFFFFFF00FFFFFFFFFFFFFFFFFF00FFFFFF1EFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0AFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFBB"],
    ] {
        d.set(w[0], w[1]);
        expect_eq(last(d), w[2]);
    }
}

fn test_unknown_and_read_only_writes_are_rejected() {
    let d = device();
    d.start();
    d.feed(sample_door_closed());
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

fn test_status_options_are_distinct_and_in_wire_order() {
    let d = device();
    d.start();
    let desc = runtime::descriptor(d);
    expect_eq(desc.props.fresh_air_filter_status.options, ["good", "replace"]);
    expect_eq(desc.props.fridge_temperature_status.options,
              ["off", "well_maintained", "very_high", "high", "low", "stabilizing", "sensor_error", "uncertain"]);
}
