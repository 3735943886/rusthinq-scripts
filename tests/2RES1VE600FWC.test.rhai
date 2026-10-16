import "runtime_test" as runtime;

// Tests of 2RES1VE600FWC.rhai (fridge), ported from upstream rethink's test suite (commit
// 0e57069; real captures from issue #44 (GSB470BASZ)). Expected values and writes are what upstream's driver
// publishes and sends for the same input.

fn sample_delta_door_open() { "AA1E10EC02030501FFFFFF0001FF01FF02030501FFFFFF0101FF01FF80BB" }
fn sample_delta_door_close() { "AA1E10EC02030501FFFFFF0101FF01FF02030501FFFFFF0001FF01FF80BB" }
fn sample_delta_fridge_minus_1() { "AA1E10EC02030501FFFFFF0001FF01FF02040501FFFFFF0001FF01FF80BB" }
fn sample_delta_fridge_plus_1() { "AA1E10EC02040501FFFFFF0001FF01FF02030501FFFFFF0001FF01FF80BB" }
fn sample_delta_freezer_minus_1() { "AA1E10EC02030501FFFFFF0001FF01FF02030601FFFFFF0001FF01FF80BB" }
fn sample_delta_freezer_plus_1() { "AA1E10EC02030601FFFFFF0001FF01FF02030501FFFFFF0001FF01FF80BB" }
fn sample_delta_express_freeze_on() { "AA1E10EC02030501FFFFFF0001FF01FF02030502FFFFFF0001FF01FF80BB" }
fn sample_delta_express_freeze_off() { "AA1E10EC02030502FFFFFF0001FF01FF02030501FFFFFF0001FF01FF80BB" }

fn last(d) { let s = d.sent(); hex_encode_upper(s[s.len() - 1]) }

fn test_sample_delta_door_open() {
    let d = device();
    d.feed(sample_delta_door_open());
    expect_props(d, #{ door: "true", fridge_setpoint: "5", freezer_setpoint: "-18", express_freeze: "false" });
}

fn test_sample_delta_door_close() {
    let d = device();
    d.feed(sample_delta_door_close());
    expect_props(d, #{ door: "false", fridge_setpoint: "5", freezer_setpoint: "-18", express_freeze: "false" });
}

fn test_sample_delta_fridge_minus_1() {
    let d = device();
    d.feed(sample_delta_fridge_minus_1());
    expect_props(d, #{ door: "false", fridge_setpoint: "4", freezer_setpoint: "-18", express_freeze: "false" });
}

fn test_sample_delta_fridge_plus_1() {
    let d = device();
    d.feed(sample_delta_fridge_plus_1());
    expect_props(d, #{ door: "false", fridge_setpoint: "5", freezer_setpoint: "-18", express_freeze: "false" });
}

fn test_sample_delta_freezer_minus_1() {
    let d = device();
    d.feed(sample_delta_freezer_minus_1());
    expect_props(d, #{ door: "false", fridge_setpoint: "5", freezer_setpoint: "-19", express_freeze: "false" });
}

fn test_sample_delta_freezer_plus_1() {
    let d = device();
    d.feed(sample_delta_freezer_plus_1());
    expect_props(d, #{ door: "false", fridge_setpoint: "5", freezer_setpoint: "-18", express_freeze: "false" });
}

fn test_sample_delta_express_freeze_on() {
    let d = device();
    d.feed(sample_delta_express_freeze_on());
    expect_props(d, #{ door: "false", fridge_setpoint: "5", freezer_setpoint: "-18", express_freeze: "true" });
}

fn test_sample_delta_express_freeze_off() {
    let d = device();
    d.feed(sample_delta_express_freeze_off());
    expect_props(d, #{ door: "false", fridge_setpoint: "5", freezer_setpoint: "-18", express_freeze: "false" });
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
    d.feed(sample_delta_door_close());
    for w in [
        ["fridge_setpoint", "1", "AA12F017FF07FFFFFFFFFFFF01FFFFFF94BB"],
        ["fridge_setpoint", "7", "AA12F017FF01FFFFFFFFFFFF01FFFFFFEEBB"],
        ["freezer_setpoint", "-24", "AA12F017FFFF0BFFFFFFFFFF01FFFFFF90BB"],
        ["freezer_setpoint", "-14", "AA12F017FFFF01FFFFFFFFFF01FFFFFFEEBB"],
        ["freezer_setpoint", "-18", "AA12F017FFFF05FFFFFFFFFF01FFFFFFEABB"],
        ["express_freeze", "true", "AA12F017FFFFFF02FFFFFFFF01FFFFFFE9BB"],
        ["express_freeze", "false", "AA12F017FFFFFF01FFFFFFFF01FFFFFFEEBB"],
    ] {
        d.set(w[0], w[1]);
        expect_eq(last(d), w[2]);
    }
}

fn test_unknown_and_read_only_writes_are_rejected() {
    let d = device();
    d.start();
    d.feed(sample_delta_door_close());
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

fn test_celsius_descriptor_uses_this_models_ranges() {
    let d = device();
    d.start();
    d.feed(sample_delta_door_close());
    let desc = runtime::descriptor(d);
    expect_eq(desc.props.fridge_setpoint.unit, "°C");
    expect_eq(desc.props.freezer_setpoint.min, -24);
    expect_eq(desc.props.freezer_setpoint.max, -14);
}

// 10EB records with the unit byte set to 0 (°F), fridge wire 3 and the freezer wire value as
// named, checksums recomputed; expected values are upstream's for the same frames.
fn test_fahrenheit_freezer_table() {
    for c in [
        ["AA1210EB02030101FFFFFF0000FF01FFEFBB", "7"],
        ["AA1210EB02030201FFFFFF0000FF01FFEEBB", "6"],
        ["AA1210EB02030901FFFFFF0000FF01FF97BB", "-1"],
        ["AA1210EB02030C01FFFFFF0000FF01FF90BB", "-7"],
        ["AA1210EB02030D01FFFFFF0000FF01FF93BB", "-12"],
        ["AA1210EB02030E01FFFFFF0000FF01FF92BB", "-15"],
        ["AA1210EB02030F01FFFFFF0000FF01FF9DBB", "-17"],
    ] {
        let d = device();
        d.feed(c[0]);
        expect_props(d, #{ fridge_setpoint: "44", freezer_setpoint: c[1] });
    }
}

fn test_fahrenheit_writes_fall_to_the_step_at_or_below() {
    let d = device();
    d.start();
    d.feed("AA1210EB02030101FFFFFF0000FF01FFEFBB");
    expect_eq(runtime::descriptor(d).props.freezer_setpoint.min, -17);
    for w in [
        ["fridge_setpoint", "33", "AA12F017FF0EFFFFFFFFFFFF00FFFFFF92BB"],
        ["fridge_setpoint", "46", "AA12F017FF01FFFFFFFFFFFF00FFFFFFEFBB"],
        ["freezer_setpoint", "-17", "AA12F017FFFF0FFFFFFFFFFF00FFFFFF9DBB"],
        ["freezer_setpoint", "-16", "AA12F017FFFF0FFFFFFFFFFF00FFFFFF9DBB"],
        ["freezer_setpoint", "-15", "AA12F017FFFF0EFFFFFFFFFF00FFFFFF92BB"],
        ["freezer_setpoint", "-13", "AA12F017FFFF0EFFFFFFFFFF00FFFFFF92BB"],
        ["freezer_setpoint", "-12", "AA12F017FFFF0DFFFFFFFFFF00FFFFFF93BB"],
        ["freezer_setpoint", "-8", "AA12F017FFFF0DFFFFFFFFFF00FFFFFF93BB"],
        ["freezer_setpoint", "-7", "AA12F017FFFF0CFFFFFFFFFF00FFFFFF90BB"],
        ["freezer_setpoint", "-4", "AA12F017FFFF0CFFFFFFFFFF00FFFFFF90BB"],
        ["freezer_setpoint", "-3", "AA12F017FFFF0BFFFFFFFFFF00FFFFFF91BB"],
        ["freezer_setpoint", "0", "AA12F017FFFF08FFFFFFFFFF00FFFFFF94BB"],
        ["freezer_setpoint", "7", "AA12F017FFFF01FFFFFFFFFF00FFFFFFEFBB"],
    ] {
        d.set(w[0], w[1]);
        expect_eq(last(d), w[2]);
    }
}
