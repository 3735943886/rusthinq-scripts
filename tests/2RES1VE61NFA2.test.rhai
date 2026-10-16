import "runtime_test" as runtime;

// Tests of 2RES1VE61NFA2.rhai (fridge), ported from upstream rethink's test suite (commit
// 0e57069; real captures from issue #9). Expected writes are the exact frames upstream's
// driver sends for the same command.

fn initial() { "AA2110EB0202040107000000010001FFFFFF00FF0001FFFFFFFFFFFFFF020085BB" }
fn door_open_express_cool_on() {
    "AA3C10EC0201040102000001010001FFFFFF00FF0100FFFFFFFFFFFFFF02060202040102000001010001FFFFFF00FF0100FFFFFFFFFFFFFF0206ACBB"
}
fn quiescent() {
    "AA3C10EC0202040102000000010001FFFFFF00FF0000FFFFFFFFFFFFFF02010202040102000000010001FFFFFF00FF0000FFFFFFFFFFFFFF0202B8BB"
}

fn last(d) { let s = d.sent(); hex_encode_upper(s[s.len() - 1]) }

fn ready() {
    let d = device();
    d.start();
    d.feed(initial());
    d
}

fn test_start_sends_the_status_query() {
    let d = device();
    d.start();
    expect_eq(last(d), "AA0EF0ED1211010000010400EBBB");
}

fn test_initial_status() {
    let d = ready();
    expect_props(d, #{ available: "true", fridge_setpoint: "6", freezer_setpoint: "-18",
                       door: "false", express_cool: "false", express_freeze: "false" });
    let desc = runtime::descriptor(d);
    expect_eq(desc.props.fridge_setpoint.unit, "°C");
    expect_eq(desc.props.fridge_setpoint.min, 1);
    expect_eq(desc.props.fridge_setpoint.max, 7);
    expect_eq(desc.props.freezer_setpoint.min, -23);
    expect_eq(desc.props.freezer_setpoint.max, -15);
}

fn test_ec_delta_door_open_and_express_cool_on() {
    let d = device();
    d.feed(door_open_express_cool_on());
    expect_props(d, #{ door: "true", express_cool: "true", express_freeze: "false" });
}

fn test_ec_delta_back_to_quiescent() {
    let d = device();
    d.feed(quiescent());
    expect_props(d, #{ door: "false", express_cool: "false", express_freeze: "false" });
}

fn test_other_frames_are_ignored() {
    let d = device();
    d.feed("001122");
    d.feed("AA08109901020304BB");
    expect_eq(d.property("door"), ());
}

fn test_writes_match_upstream() {
    let d = ready();
    for w in [
        ["fridge_setpoint", "4", "AA21F017FF04FFFFFFFFFFFF01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBBB"],
        ["fridge_setpoint", "1", "AA21F017FF07FFFFFFFFFFFF01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF94BB"],
        ["fridge_setpoint", "7", "AA21F017FF01FFFFFFFFFFFF01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEEBB"],
        ["freezer_setpoint", "-20", "AA21F017FFFF06FFFFFFFFFF01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF95BB"],
        ["express_cool", "true", "AA21F017FFFFFFFFFFFFFFFF01FFFFFFFFFFFFFF01FFFFFFFFFFFFFFFFFFFFEEBB"],
        ["express_cool", "false", "AA21F017FFFFFFFFFFFFFFFF01FFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFEFBB"],
        ["express_freeze", "true", "AA21F017FFFFFF02FFFFFFFF01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE9BB"],
        ["express_freeze", "false", "AA21F017FFFFFF01FFFFFFFF01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEEBB"],
    ] {
        d.set(w[0], w[1]);
        expect_eq(last(d), w[2]);
    }
}

// The initial capture with the unit byte set to 0 (°F) and the checksum recomputed; the
// expected values and writes are upstream's for the same frame.
fn test_fahrenheit_republishes_the_descriptor_and_converts_both_ways() {
    let d = device();
    d.start();
    d.feed("AA2110EB0202040107000000000001FFFFFF00FF0001FFFFFFFFFFFFFF02009ABB");
    expect_props(d, #{ fridge_setpoint: "42", freezer_setpoint: "2" });
    let desc = runtime::descriptor(d);
    expect_eq(desc.props.fridge_setpoint.unit, "°F");
    expect_eq(desc.props.fridge_setpoint.min, 33);
    expect_eq(desc.props.freezer_setpoint.max, 5);
    d.set("fridge_setpoint", "38");
    expect_eq(last(d), "AA21F017FF06FFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEABB");
    d.set("freezer_setpoint", "0");
    expect_eq(last(d), "AA21F017FFFF06FFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEABB");
}

fn test_bad_writes_are_rejected_and_nothing_is_sent() {
    let d = ready();
    let n = d.sent().len();
    d.set("does_not_exist", "1");
    d.set("fridge_setpoint", "8");
    d.set("freezer_setpoint", "-24");
    d.set("door", "true");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "rejects are published");
}

fn test_dropping_marks_it_unavailable() {
    let d = ready();
    d.drop_device();
    expect_props(d, #{ available: "false" });
}
