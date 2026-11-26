import "runtime_test" as runtime;
import "aabb_test" as a;

// Tests of 2ROFL1DBN3K_U.rhai (fridge, read-only). Every frame is a real capture from one
// unit (2026-11-25, rusthinqctl capture --cloud); the LG cloud reported fridge 3 C,
// freezer -18 C and express freeze off at the time, and atLeastOneDoorOpen OPEN then CLOSE
// at the two EC frames.

fn eb() { "AA6610EB0205040102FFFF00010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF2E0101FF00FFFFFFFFFFFFFFFFFF01FF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FFFFFFFFFFFFFFFFFFFFFFFF000000FFFFFFFF0005FFFFFFFF640000FF00FFBCBB" }
fn ec_open() { "AAC610EC0205040102FFFF00010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF2E0101FF00FFFFFFFFFFFFFFFFFF01FF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FFFFFFFFFFFFFFFFFFFFFFFF000000FFFFFFFF0005FFFFFFFF640000FF00FF0205040102FFFF01010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF2E0101FF00FFFFFFFFFFFFFFFFFF01FF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FFFFFFFFFFFFFFFFFFFFFFFF000000FFFFFFFF0005FFFFFFFF640000FF00FF7CBB" }
fn ec_close() { "AAC610EC0205040102FFFF01010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF2E0101FF00FFFFFFFFFFFFFFFFFF01FF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FFFFFFFFFFFFFFFFFFFFFFFF000000FFFFFFFF0005FFFFFFFF640000FF00FF0205040102FFFF00010001FFFFFFFFFFFF00FFFFFFFFFFFFFFFF2E0101FF00FFFFFFFFFFFFFFFFFF01FF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0078FFFFFFFFFFFFFFFFFFFFFFFF000000FFFFFFFF0005FFFFFFFF640000FF00FF7CBB" }

fn test_start_is_silent() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 0);
    expect_eq(d.timers().len(), 0);
    expect_eq(d.property("energy"), ());
    expect_eq(d.script_error(), ());
}

// The captured reply to this captured 10 18 frame.
fn test_device_frames_are_acknowledged() {
    let d = device();
    d.feed("AA0A101800E0011781BB");
    let clips = d.clips();
    expect_eq(clips.len(), 1);
    expect_eq(clips[0].cmd, "ack");
    expect_eq(clips[0].data, "AA08F0001804EBBB");
    expect_eq(d.script_error(), ());
}

fn test_the_96_byte_eb_record_becomes_il_properties() {
    let d = device();
    d.feed(eb());
    expect_props(d, #{
        available: "true",
        fridge_setpoint: "3",
        freezer_setpoint: "-18",
        express_freeze: "false",
        door: "false"
    });
    expect_eq(d.script_error(), ());
}

fn test_the_ec_publishes_the_current_record() {
    let d = device();
    d.feed(ec_open());
    expect_eq(d.property("door"), "true");
    d.feed(ec_close());
    expect_eq(d.property("door"), "false");
    expect_props(d, #{ fridge_setpoint: "3", freezer_setpoint: "-18", express_freeze: "false" });
    expect_eq(d.script_error(), ());
}

fn test_energy_is_the_running_total() {
    let d = device();
    d.start();
    expect_eq(runtime::descriptor(d).props.energy.series, "counter");
    d.feed("AA0B103E000D029656ABBB");
    expect_eq(d.property("energy"), "662");
    expect_eq(d.script_error(), ());
}

fn test_writes_are_rejected_and_nothing_is_sent() {
    let d = device();
    d.start();
    expect_eq(runtime::descriptor(d).props.fridge_setpoint.rw, false);
    for p in ["fridge_setpoint", "freezer_setpoint", "express_freeze"] {
        d.set(p, if p == "express_freeze" { "true" } else { "4" });
    }
    expect_eq(d.sent().len(), 0);
    expect(d.event("reject") != (), "a reject event is published");
    expect_eq(d.script_error(), ());
}
