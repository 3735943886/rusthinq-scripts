import "runtime_test" as runtime;

// Tests of 2REB1GLVB1__2.rhai (fridge), ported from upstream rethink's test suite (commit
// 0e57069). Expected writes are the exact frames upstream's driver sends; the eco friendly
// ones are the commands the LG app sent.

fn initial() { "AA1710EB020504010000000201000100000000000099BB" }
fn eco_on() { "AA2810EC02070401000000020100010000000000000207040100000002010001000100000000A6BB" }
fn eco_off() { "AA2810EC02070401000000020100010001000000000207040100000002010001000000000000A6BB" }

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
    // The captured door byte is 2, which also means closed.
    expect_props(d, #{ available: "true", fridge_setpoint: "3", freezer_setpoint: "-18",
                       door: "false", express_cool: "false", express_freeze: "false",
                       eco_friendly: "false" });
    let desc = runtime::descriptor(d);
    expect_eq(desc.props.fridge_setpoint.unit, "°C");
    expect_eq(desc.props.freezer_setpoint.max, -15);
}

fn test_ec_status_decodes_eco_friendly() {
    let d = device();
    d.feed(eco_on());
    expect_props(d, #{ eco_friendly: "true", fridge_setpoint: "1" });
    d.feed(eco_off());
    expect_props(d, #{ eco_friendly: "false" });
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
        ["fridge_setpoint", "4", "AA17F017FF04FFFFFFFFFFFF01FFFFFFFFFFFFFFFFEBBB"],
        ["freezer_setpoint", "-20", "AA17F017FFFF06FFFFFFFFFF01FFFFFFFFFFFFFFFF95BB"],
        ["express_cool", "true", "AA17F017FFFFFFFFFFFFFFFF01FFFFFFFFFFFFFF01EEBB"],
        ["express_freeze", "true", "AA17F017FFFFFF02FFFFFFFF01FFFFFFFFFFFFFFFFE9BB"],
        ["eco_friendly", "true", "AA2FF017FFFFFFFFFFFFFFFFFFFFFFFF01FFFFFFFFFFFFFFFF000000FFFF00FFFFFFFF00FFFFFFFFFFFFFFFFFFEBBB"],
        ["eco_friendly", "false", "AA2FF017FFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFF000000FFFF00FFFFFFFF00FFFFFFFFFFFFFFFFFFE8BB"],
    ] {
        d.set(w[0], w[1]);
        expect_eq(last(d), w[2]);
    }
}

fn test_bad_writes_are_rejected_and_nothing_is_sent() {
    let d = ready();
    let n = d.sent().len();
    d.set("does_not_exist", "1");
    d.set("fridge_setpoint", "0");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "rejects are published");
}
