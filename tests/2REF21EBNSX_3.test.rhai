import "aabb_test" as a;
import "runtime_test" as runtime;

// Tests of 2REF21EBNSX_3.rhai (refrigerator), ported from kshexe/rethink's
// tests/cloud/devices/2REF21EBNSX_3.test.ts (commit 8fa8bd4). The frames are real captures from
// the fork's unit (2026-09-09..10-06) except the two door-record frames, which the fork
// constructs too; the writes are the fork's captured frames.

fn ack() { "aa08100017008cbb" }
fn state_fridge_7() { "aa2a10ec020404010700ff00010001ffffffffffff01020704010700ff00010001ffffffffffff01babb" }
fn state_express_on() { "aa2a10ec020404010700ff00010001ffffffffffff01020404020700ff00010001ffffffffffff01b8bb" }
fn query_response() { "aa1810eb020404010700ff00010001ffffffffffff019ebb" }
fn smart_care_off() { "aa2a10ec020404010700ff00010001ffffffffffff01020404010200ff00010001ffffffffffff00b3bb" }
fn smart_care_on() { "aa2a10ec020404010200ff00010001ffffffffffff00020404010700ff00010001ffffffffffff01b3bb" }
fn door_open_record() { "aa2a10ec020404010700ff00010001ffffffffffff01020704010700ff01010001ffffffffffff01a5bb" }
fn door_quirk_2_record() { "aa2a10ec020404010700ff00010001ffffffffffff01020704010700ff02010001ffffffffffff01a4bb" }
fn fridge_door_open() { "aa0810a8010139bb" }
fn fridge_door_closed() { "aa0810a801003ebb" }
fn freezer_door_open() { "aa0810a8020138bb" }
fn freezer_door_closed() { "aa0810a8020039bb" }
fn counter_7() { "aa0b10af0f00070404c7bb" }
fn counter_87() { "aa0b10affa0057040498bb" }
fn ambient_30_419() { "aa0a1018011e01a3cabb" }
fn ambient_28_489() { "aa0a1018011c01e9b6bb" }

fn counter(n) { a::framed(a::bytes([0x10, 0xaf, 0xfa, (n >> 8) & 0xff, n & 0xff, 0x04, 0x04])) }

fn test_the_descriptor() {
    let d = device();
    d.start();
    let desc = runtime::descriptor(d);
    expect_eq(desc.props.fridge_setpoint.min, 1);
    expect_eq(desc.props.fridge_setpoint.max, 7);
    expect_eq(desc.props.freezer_setpoint.min, -23);
    expect_eq(desc.props.freezer_setpoint.unit, "°C");
    expect_eq(desc.props.smart_care.rw, true);
    expect_eq(d.script_error(), ());
}

// "start() sends the query frame once, byte for byte, and never again"
fn test_start_queries_once() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 1);
    expect_eq(hex_encode(d.sent()[0]), "aa0ef0ed1211010000010400ebbb");
}

// "fridge_temp write reproduces the captured frame byte for byte"
fn test_fridge_writes() {
    let cases = [
        ["7", "aa2ff017ff07ffffffffffff01ffffffffffffffffffffffff000000ffff00ffffffff00ffffffffffffffffff93bb"],
        ["1", "aa2ff017ff01ffffffffffff01ffffffffffffffffffffffff000000ffff00ffffffff00ffffffffffffffffff95bb"],
        ["4", "aa2ff017ff04ffffffffffff01ffffffffffffffffffffffff000000ffff00ffffffff00ffffffffffffffffff96bb"]
    ];
    for c in cases {
        let d = device();
        d.set("fridge_setpoint", c[0]);
        expect_eq(hex_encode(d.sent()[0]), c[1]);
        expect_eq(d.property("fridge_setpoint"), ()); // not optimistic
    }
}

// "freezer_temp write reproduces the captured frame byte for byte (raw = -14 - degC)"
fn test_freezer_writes() {
    let cases = [
        ["-23", "aa2ff017ffff09ffffffffff01ffffffffffffffffffffffff000000ffff00ffffffff00ffffffffffffffffff9dbb"],
        ["-15", "aa2ff017ffff01ffffffffff01ffffffffffffffffffffffff000000ffff00ffffffff00ffffffffffffffffff95bb"],
        ["-18", "aa2ff017ffff04ffffffffff01ffffffffffffffffffffffff000000ffff00ffffffff00ffffffffffffffffff96bb"]
    ];
    for c in cases {
        let d = device();
        d.set("freezer_setpoint", c[0]);
        expect_eq(hex_encode(d.sent()[0]), c[1]);
    }
}

// "express_mode write reproduces the captured frame byte for byte"
fn test_express_writes() {
    let d = device();
    d.set("express_mode", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa2ff017ffffff02ffffffffffffffffffffffffffffffffff000000ffff00ffffffff00ffffffffffffffffffeabb");
    d.set("express_mode", "false");
    expect_eq(hex_encode(d.sent()[1]), "aa2ff017ffffff01ffffffffffffffffffffffffffffffffff000000ffff00ffffffff00ffffffffffffffffffebbb");
}

// "setpoints are clamped to the real confirmed range": refused here (the descriptor's range).
fn test_out_of_range_setpoints_are_rejected() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("fridge_setpoint", "9");
    d.set("freezer_setpoint", "-30");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "rejected");
}

// "smart_care_v2 ON sends a single write; OFF sends the real two-frame sequence"
fn test_smart_care_writes() {
    let d = device();
    d.set("smart_care", "true");
    expect_eq(d.sent().len(), 1);
    expect_eq(hex_encode(d.sent()[0]), "aa2ff017ffffffffffffffffffffffffffffffffff01ffffff000000ffff00ffffffff00ffffffffffffffffffebbb");
    d.set("smart_care", "false");
    expect_eq(d.sent().len(), 3);
    expect_eq(hex_encode(d.sent()[1]), "aa2ff017ffffffffffffffffffffffffffffffffff00ffffff000000ffff00ffffffff00ffffffffffffffffffe8bb");
    expect_eq(hex_encode(d.sent()[2]), "aa2ff017ffffffff06ffffffffffffffffffffffffffffffff000000ffff00ffffffff00ffffffffffffffffff96bb");
}

// "the state frame publishes the real smart_care_v2 reading, both directions"
fn test_smart_care_read_back() {
    let d = device();
    d.feed(smart_care_off());
    expect_eq(d.property("smart_care"), "false");
    d.feed(smart_care_on());
    expect_eq(d.property("smart_care"), "true");
}

// "the ack frame ..." / "the periodic full status dump is recognised by shape and silently dropped"
fn test_ack_and_dump_publish_nothing() {
    let d = device();
    d.feed(ack());
    let dump = a::payload(250, [0x10, 0xcf]);
    d.feed(a::framed(dump));
    expect_eq(d.property("fridge_setpoint"), ());
    expect_eq(d.script_error(), ());
}

// "ambient temp/humidity decode reproduces the two real captures"
fn test_ambient() {
    let d = device();
    d.feed(ambient_30_419());
    expect_props(d, #{ ambient_temperature: "30", ambient_humidity: "41.9" });
    d.feed(ambient_28_489());
    expect_props(d, #{ ambient_temperature: "28", ambient_humidity: "48.9" });
}

// The fork feeds only its calendar buckets from this counter (not ported). Here the counter is
// the HA-style energy property itself: it rises with use and a drop is its own reset, which a
// consumer's utility meter handles. Both real captures, then a constructed reset.
fn test_the_energy_counter() {
    let d = device();
    d.start();
    expect_eq(runtime::descriptor(d).props.energy.series, "counter");
    d.feed(counter_7());
    expect_eq(d.property("energy"), "7");
    d.feed(counter_87()); // byte 2 differs between the two captures and is not read
    expect_eq(d.property("energy"), "87");
    d.feed(counter(3));
    expect_eq(d.property("energy"), "3");
    expect_eq(d.property("energy_hour"), ());
}

// "record[7] (anyDoorOpen) backfills both compartments to OFF once closed, but leaves an
// already-open one alone since it cannot say which door"
fn test_the_record_backfills_closed_doors() {
    let d = device();
    d.feed(state_fridge_7());
    expect_props(d, #{ fridge_door: "false", freezer_door: "false" });
    d.feed(fridge_door_open());
    d.feed(freezer_door_open());
    d.feed(door_open_record());
    expect_props(d, #{ fridge_door: "true", freezer_door: "true" });
    d.feed(door_quirk_2_record());
    expect_props(d, #{ fridge_door: "false", freezer_door: "false" });
}

// "per-compartment door events publish fridge_door_open and freezer_door_open independently"
fn test_door_events() {
    let d = device();
    d.feed(fridge_door_open());
    expect_eq(d.property("fridge_door"), "true");
    expect_eq(d.property("freezer_door"), ());
    d.feed(freezer_door_open());
    expect_props(d, #{ fridge_door: "true", freezer_door: "true" });
    d.feed(fridge_door_closed());
    expect_props(d, #{ fridge_door: "false", freezer_door: "true" });
    d.feed(freezer_door_closed());
    expect_eq(d.property("freezer_door"), "false");
}

// "the state frame publishes the real reading, from the second (current) record" and
// "... even when unrelated fields are present"
fn test_records() {
    let d = device();
    d.feed(state_fridge_7());
    expect_props(d, #{ available: "true", fridge_setpoint: "7", freezer_setpoint: "-18", express_mode: "false" });
    d.feed(state_express_on());
    expect_props(d, #{ fridge_setpoint: "4", freezer_setpoint: "-18", express_mode: "true" });
}

// "the query response (a single record, not a before/after pair) publishes the real reading"
fn test_the_query_response() {
    let d = device();
    d.feed(query_response());
    expect_props(d, #{ fridge_setpoint: "4", freezer_setpoint: "-18", express_mode: "false", smart_care: "true" });
}

fn test_reconnect_publishes_no_defaults() {
    let d = device();
    d.start();
    d.feed(query_response());
    d.drop_device();
    d.start();
    expect_eq(d.property("fridge_setpoint"), "4");
}
