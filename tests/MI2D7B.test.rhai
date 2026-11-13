import "aabb_test" as a;
import "runtime_test" as runtime;

// Tests of MI2D7B.rhai (MiniWash), ported from kshexe/rethink's tests/cloud/devices/MI2D7B.test.ts
// (commit 8fa8bd4). Every frame below is a real capture from the fork's unit (2026-09-09..13),
// and every expected write is the fork's captured or asserted frame, byte for byte.

fn ack() { "aa082000e500e2bb" }
// 57-byte E6 echo after a power-on write: [46] = 2.
fn power_echo_on() {
    "aa3d20e6000201ff01020000000002132e00000000000000003300000000002e01008100000000080000000000000000020020300000000000000027bb"
}
fn status_ec_28_min_left() {
    "aaff200a0072009a01000100ec006000001702136100000000000000001d00630348002e0c0b8100000000080000000000000008100100300000000000000000001702136100000000000000001c00630348002e0c0b81000000000800000000000000081001003000000000000000462bbb"
}
fn notification_00() { "aa09207200000010bb" }
fn notification_c8() { "aa09207200c80058bb" }
fn energy_156() { "aa0b203e009c009c0119bb" }
fn energy_21() { "aa0b203e00150015016bbb" }

// The power echo with [46] cleared, as after an off write (constructed: the fork confirmed
// 0 after off but its fixture is the on echo).
fn power_echo_off() {
    let b = aabb_unwrap(hex_decode(power_echo_on()));
    b[46] = 0;
    a::framed(b)
}

fn test_the_descriptor() {
    let d = device();
    d.start();
    let desc = runtime::descriptor(d);
    expect_eq(desc.kind, "washer");
    expect_eq(desc.props.power.rw, true);
    expect_eq(desc.props.remaining_time.unit, "min");
    expect_eq(desc.props.energy.series, "counter");
    expect_eq(desc.props.pause.type, "trigger");
    expect_eq(d.script_error(), ());
}

// The fork's start(): the family status query, once.
fn test_start_sends_the_status_query_and_publishes_no_default() {
    let d = device();
    d.start();
    expect_eq(hex_encode_upper(d.sent()[0]), "AA0EF0ED1211010000010400EBBB");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.property("remaining_time"), ());
    expect_eq(d.property("energy"), ());
    expect_eq(d.script_error(), ());
}

// "power write reproduces the captured frame byte for byte"
fn test_power_writes_are_the_captured_frames() {
    let d = device();
    d.start();
    d.set("power", "true");
    expect_eq(hex_encode(d.sent()[1]), "aa0df0e5000201ff010201c7bb");
    d.set("power", "false");
    expect_eq(hex_encode(d.sent()[2]), "aa0df0e5000201ff010200c4bb");
    // Nothing is published from a write: the echo confirms it.
    expect_eq(d.property("power"), ());
}

// "pause/resume write reproduce the captured frames byte for byte" and
// "start write follows the same OPERATION key ... (unverified)"
fn test_operation_writes() {
    let d = device();
    d.start();
    d.set("pause", "");
    expect_eq(hex_encode(d.sent()[1]), "aa0df0e5000201ff010302c1bb");
    d.set("resume", "");
    expect_eq(hex_encode(d.sent()[2]), "aa0df0e5000201ff010303c0bb");
    d.set("start", "");
    expect_eq(hex_encode(d.sent()[3]), "aa0df0e5000201ff010301c6bb");
}

fn test_a_bad_write_is_rejected() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("remaining_time", "5");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "read-only property rejected");
    d.set("power", "maybe");
    expect_eq(d.sent().len(), n);
}

// "the ack frame is accepted and publishes nothing"
fn test_the_ack_publishes_nothing() {
    let d = device();
    d.feed(ack());
    expect_eq(d.property("power"), ());
    expect_eq(d.clips().len(), 0);
    expect_eq(d.script_error(), ());
}

// "the bundled status frame does not get misread as power state": the echo's [46] reads on.
fn test_the_power_echo_reads_back_power() {
    let d = device();
    d.feed(power_echo_on());
    expect_eq(d.property("power"), "true");
    d.feed(status_ec_28_min_left());
    expect_eq(d.property("remaining_time"), "28");
    d.feed(power_echo_off());
    expect_eq(d.property("power"), "false");
    // "remaining_minutes zeroes on power-off": cleared here (il V-1).
    expect_eq(d.property("remaining_time"), "");
    expect_eq(d.script_error(), ());
}

// "a real query-response status frame publishes remaining_minutes"
fn test_the_status_record_publishes_remaining_time() {
    let d = device();
    d.feed(status_ec_28_min_left());
    expect_props(d, #{ available: "true", remaining_time: "28" });
    expect_eq(d.script_error(), ());
}

// "both real notification-channel codes publish washing_is_complete"
fn test_both_notification_codes_are_washing_is_complete() {
    for frame in [notification_00(), notification_c8()] {
        let d = device();
        d.feed(frame);
        expect_eq(json_parse(d.event("notification")).event_type, "washing_is_complete");
    }
}

fn test_an_unknown_notification_code_publishes_nothing() {
    let d = device();
    d.feed(a::framed(hex_decode("20720005")));
    expect_eq(d.event("notification"), ());
    expect_eq(d.script_error(), ());
}

// "a real energy report publishes the running total as energy (this cycle)"; the fork's
// calendar buckets are not ported, so nothing else is published.
fn test_energy_reports() {
    let d = device();
    d.start();
    d.feed(energy_156());
    expect_eq(d.property("energy"), "156");
    d.feed(energy_21());
    expect_eq(d.property("energy"), "21");
    expect_eq(d.property("energy_hour"), ());
    expect_eq(d.timers().len(), 0);
    expect_eq(d.script_error(), ());
}

// A reconnect starts on an empty context: nothing is published over the retained values.
fn test_reconnect_publishes_no_defaults() {
    let d = device();
    d.start();
    d.feed(status_ec_28_min_left());
    d.drop_device();
    d.start();
    expect_eq(d.property("remaining_time"), "28");
    expect_eq(d.script_error(), ());
}

fn test_device_frames_are_acknowledged() {
    let d = device();
    d.feed(notification_00());
    let clips = d.clips();
    expect_eq(clips.len(), 1);
    expect_eq(clips[0].cmd, "ack");
    expect_eq(clips[0].data, hex_encode_upper(aabb_wrap([0xf0, 0x00, 0x72, 0x04])));
}
