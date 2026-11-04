import "aabb_test" as a;

// Tests of ST_R_ETH01Y_.rhai (styler), ported from the owner's rethink TS driver.
// No styler frames exist in the workspace frame captures (the TS driver's evidence
// lives in its header: captures from 2026-09-09..18 against a real unit), so the
// status frames here are CONSTRUCTED to the TS driver's documented envelope:
// class 0x31, byte 1 = 0x0a, extended length at [2..3] = body length + 4, inner
// type at payload[6], records from payload[10], 36 bytes each (EB one, EC two -
// the current is the second). The write frames asserted below are the TS driver's
// captured byte shapes.

fn eb_on() { a::framed(hex_decode("310a0036000000000000eb000000000004000000350000010000000000000000000000000000000000000000000000000000")) }
fn ec_on() { a::framed(hex_decode("310a005a000000000000ec00000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000400000010000000000000000000000000000000000000000000000000000")) }
fn eb_short() { a::framed(hex_decode("310affff00000000eb000000000003000000120000010000000000000000000000000000000000000000000000000000")) }

fn test_start_publishes_the_default_course() {
    let d = device();
    d.start();
    expect_eq(d.property("course"), "강력 스타일링");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

fn test_an_eb_record_becomes_il_properties() {
    let d = device();
    d.feed(eb_on());
    // record [9] = 1 (on), [2] = 4 (강력 스타일링), [6] = 53 minutes.
    expect_props(d, #{
        available: "true",
        power: "true",
        active_course: "강력 스타일링",
        duration_minutes: "53"
    });
    expect_eq(d.script_error(), ());
}

fn test_an_ec_record_uses_the_second_record() {
    let d = device();
    d.feed(ec_on());
    // second record: [2] = 10 (표준 살균), [6] = 64.
    expect_props(d, #{
        power: "true",
        active_course: "표준 살균",
        duration_minutes: "64"
    });
    expect_eq(d.script_error(), ());
}

fn test_a_non_extended_envelope_also_decodes() {
    let d = device();
    d.feed(eb_short());
    // [2] = 3 (급속 스타일링), [6] = 18.
    expect_props(d, #{
        power: "true",
        active_course: "급속 스타일링",
        duration_minutes: "18"
    });
    expect_eq(d.script_error(), ());
}

fn test_an_off_record_publishes_power_only() {
    let d = device();
    d.feed(eb_on());
    // Same EB shape with [9] = 0: course/duration are not trusted while off.
    d.feed(a::framed(hex_decode("310a0036000000000000eb000000000004000000350000000000000000000000000000000000000000000000000000000000")));
    expect_eq(d.property("power"), "false");
    expect_eq(d.script_error(), ());
}

fn test_the_completion_notification_is_an_event() {
    let d = device();
    d.feed(a::framed(hex_decode("31720000")));
    expect(d.event("notification") != (), "a notification event is published");
    expect_eq(d.script_error(), ());
}

fn test_the_write_ack_is_ignored() {
    let d = device();
    d.feed(a::framed(hex_decode("3100e500")));
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

fn test_power_write_is_the_captured_f0e5_frame() {
    let d = device();
    d.set("power", "true");
    expect_eq(a::inner_hex(d, 0), "f0e5000201ff010201");
    expect_eq(d.property("power"), "true"); // optimistic, as in the TS driver
    d.set("power", "false");
    expect_eq(a::inner_hex(d, 1), "f0e5000201ff010200");
}

fn test_smart_care_writes() {
    let d = device();
    d.set("smart_care_fine_dust", "true");
    expect_eq(a::inner_hex(d, 0), "f0e5000201ff011c01");
    d.set("smart_care_humidity", "true");
    expect_eq(a::inner_hex(d, 1), "f0e5000201ff011b01");
    d.set("smart_care_night_care", "false");
    expect_eq(a::inner_hex(d, 2), "f0e5000201ff011a00");
}

fn test_course_selection_sends_nothing() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("course", "시간 건조");
    expect_eq(d.sent().len(), n);
    expect_eq(d.property("course"), "시간 건조");
}

fn test_start_sends_the_four_key_write() {
    let d = device();
    d.set("course", "시간 건조"); // code 23 = 0x17
    d.set("start", "");
    expect_eq(a::inner_hex(d, 0), "f0e5000201ff040a1723007f00000301");
    expect_eq(d.script_error(), ());
}

fn test_start_defaults_to_the_appliance_default_course() {
    let d = device();
    d.set("start", "");
    expect_eq(a::inner_hex(d, 0), "f0e5000201ff040a0423007f00000301");
}

fn test_an_unknown_course_is_rejected() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("course", "없는 코스");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "a reject event is published");
}
