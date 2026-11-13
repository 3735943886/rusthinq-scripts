import "aabb_test" as a;
import "runtime_test" as runtime;

// Tests of RD20_S.rhai (dryer), ported from kshexe/rethink's tests/cloud/devices/RD20_S.test.ts
// (commit 8fa8bd4). Every frame below is a real capture from the fork's unit (2026-09-09..22);
// the expected writes are the fork's captured frames. Names in comments are the fork's tests.

fn ack() { "aa083000e50092bb" }
fn bundled_status() {
    "aa3f30e6000201ff0102000000000000000000000000000000010000000000000000002000008007000000000000000000000000000000000000000000f9bb"
}
fn state_99() {
    "aaff300a007600d9e5000100ec006400000200002c00000000640064070e00020001041c000000000041800700000000000000000000000000000000000000000000000200002c00000000630064070e00020003041c00000000004180070000000000000000000000000000000000000000002863bb"
}
fn state_74() {
    "aaff300a007600dc80000100ec006400000200002c00000000490064070e00030145041c000000000041800700000000000000000000000000000000000000000000000200002c000000004a0064070e0003014f041c0000000000418007000000000000000000000000000000000000000000ab92bb"
}
fn state_58_to_11() {
    "aaff300a007600de41000100ec006400000200002c000000003a0064070e000301ff041c000000000041800700000000000000000000000000000000000000000000000200002c000000000b0064070e00040214041c00000000004180070000000000000000000000000000000000000000005dc7bb"
}
fn running_18() {
    "aaff300a00760072e4000100ec006400000200002c000000001300820710000404f9041c000000000041800700000000000000000000000000000000000000000000000200002c00000000120082071000040501041c00000000004180070000000000000000000000000000000000000000000675bb"
}
fn cooling_5() {
    "aaff300a00760073fa000100ec006400000200002c0000000006008211070005056d041c000000000061800700000000000000000000000000000000000000000000000200002c0000000005008211070005056f041c0000000000618007000000000000000000000000000000000000000000889fbb"
}
fn complete_1() {
    "aaff300a007600744b000100ec006400000200002c00000000010082081100050577041c000000000041800700000000000000000000000000000000000000000000000200002c00000000010082040800070578041c00000020000180070000000000000000000000000000000000000000005b57bb"
}
fn energy_0() {
    "aaff300a007600d72a000100ec0064000000000000000000000000000100000000000000000000000000800700000000000000000000000000000000000000000000000200000400000000af00af07010002000000040000000000418007000000000000000000000000000000000000000000e155bb"
}
fn energy_1() {
    "aaff300a007600d749000100ec006400000200000400000000af00af0701000200000004000000000041800700000000000000000000000000000000000000000000000200000400000000ae00af070100020001000400000000004180070000000000000000000000000000000000000000005e59bb"
}
fn drum_light_off() {
    "aaff300a00760044c2000100ec00640003020000070000000064001e010000000000000700000020000480070000000000000000000000000000000000000000000003020000070000000064001e010000000000000700000000000480070000000000000000000000000000000000000000008958bb"
}
fn drum_light_on() {
    "aaff300a00760044d3000100ec00640003020000070000000064001e010000000000000700000000000480070000000000000000000000000000000000000000000003020000070000000064001e010000000000000700000020000480070000000000000000000000000000000000000000009578bb"
}
fn ironing_on() {
    "aaff300a007600458b000100ec00640003020000070000000064001e010000000000000700000000000480070000000000000000000000000000000000000000000003020000070000000064001e010000000000040700000040000480070000000000000000000000000000000000000000005326bb"
}
fn ironing_off() {
    "aaff300a0076004599000100ec00640003020000070000000064001e010000000000040700000040000480070000000000000000000000000000000000000000000003020000070000000064001e01000000000004070000000000048007000000000000000000000000000000000000000000bfe3bb"
}
fn wrinkle_on() {
    "aaff300a00760045d3000100ec00640003020000070004740064001e010000000000000700000000000c80070000000000000000000000000000000000000000000003020000070004740064001e010000000000000700000008000c80070000000000000000000000000000000000000000008416bb"
}
fn wrinkle_off() {
    "aaff300a00760045d8000100ec00640003020000070004740064001e010000000000000700000008000c80070000000000000000000000000000000000000000000003020000070004740064001e010000000000000700000000000c80070000000000000000000000000000000000000000008dcabb"
}
fn lock_on() {
    "aaff300a00760044f1000100ec00640003020000070000000064001e010000000000000700000020000480070000000000000000000000000000000000000000000003020000070000000064001e010000000000000700000020001480070000000000000000000000000000000000000000007444bb"
}
fn lock_off() {
    "aaff300a0076004501000100ec00640003020000070000000064001e010000000000000700000020001480070000000000000000000000000000000000000000000003020000070000000064001e01000000000000070000002000048007000000000000000000000000000000000000000000d5debb"
}
fn reservation_3h() {
    "aaff300a00760045be000100ec00640003020000070000000064001e010000000000040700000000000480070000000000000000000000000000000000000000000003020000070000b40064001e010000000000040700000000000c80070000000000000000000000000000000000000000005081bb"
}
fn reservation_off() {
    "aaff300a00760045e0000100ec00640003020000070004740064001e010000000000000700000000000c80070000000000000000000000000000000000000000000003020000070000000064001e010000000000000700000000000480070000000000000000000000000000000000000000008a08bb"
}
fn volume_medium() {
    "aaff300a0076004510000100ec00640003020000070000000064001e010000000000010700000020000480070000000000000000000000000000000000000000000003020000070000000064001e010000000000020700000020000480070000000000000000000000000000000000000000008a31bb"
}

// A captured frame with body byte `i` (the fork's buf index) replaced; framing rebuilt.
fn patched(frame, i, v) {
    let b = aabb_unwrap(hex_decode(frame));
    b[i] = v;
    // Rewrapped as a short frame; the long form's spare checksum byte stays on the body, which
    // keeps the fork's 114-byte length.
    a::framed(b)
}

fn test_the_descriptor() {
    let d = device();
    d.start();
    let desc = runtime::descriptor(d);
    expect_eq(desc.kind, "dryer");
    expect_eq(desc.props.drum_light_auto.rw, true);
    expect_eq(desc.props.energy.series, "counter");
    expect_eq(desc.props.status.options, ["off", "complete", "running", "cooling"]);
    expect_eq(d.script_error(), ());
}

fn test_start_sends_the_query_and_no_defaults() {
    let d = device();
    d.start();
    expect_eq(hex_encode_upper(d.sent()[0]), "AA0EF0ED1211010000010400EBBB");
    expect_eq(d.property("remaining_time"), ());
    expect_eq(d.property("energy"), ());
}

// "power write reproduces the captured frame byte for byte"
fn test_power_writes() {
    let d = device();
    d.set("power", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa0df0e5000201ff010201c7bb");
    d.set("power", "false");
    expect_eq(hex_encode(d.sent()[1]), "aa0df0e5000201ff010200c4bb");
    expect_eq(d.property("power"), ()); // not optimistic
}

// "drum_light_auto write reproduces the captured frame byte for byte (ON only)"
fn test_drum_light_auto_write() {
    let d = device();
    d.set("drum_light_auto", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa0df0e5000201ff011b01febb");
    d.set("drum_light_auto", "false");
    expect_eq(a::inner_hex(d, 1), "f0e5000201ff011b00");
}

fn test_a_read_only_write_is_rejected() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("child_lock", "true");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "rejected");
}

// "the ack frame is accepted and publishes nothing"
fn test_the_ack() {
    let d = device();
    d.feed(ack());
    expect_eq(d.property("power"), ());
    expect_eq(d.script_error(), ());
}

// "the bundled status frame does not get misread as power state": 59 bytes, not the echo.
fn test_the_bundled_frame_is_not_a_power_echo() {
    let d = device();
    d.feed(bundled_status());
    expect_eq(d.property("power"), ());
    expect_eq(d.script_error(), ());
}

// The 58-byte power echo (constructed from the 59-byte frame's head; the fork has no capture).
fn test_the_power_echo() {
    let d = device();
    d.feed(state_99());
    let b = aabb_unwrap(hex_decode(bundled_status())).extract(0, 58);
    b[33] = 1;
    d.feed(a::framed(b));
    expect_eq(d.property("power"), "true");
    b[33] = 0;
    d.feed(a::framed(b));
    expect_eq(d.property("power"), "false");
    expect_eq(d.property("remaining_time"), "");
}

// "the 114-byte status frame publishes remaining_minutes, matching the official integration"
fn test_remaining_time_from_the_current_record() {
    let d = device();
    d.feed(state_99());
    expect_eq(d.property("remaining_time"), "99");
    d.feed(state_74());
    expect_eq(d.property("remaining_time"), "74");
    d.feed(state_58_to_11());
    expect_eq(d.property("remaining_time"), "11");
    expect_eq(d.property("available"), "true");
}

// "the status byte publishes running/cooling/complete, matching two independent real cycles"
fn test_running_cooling_complete() {
    let d = device();
    d.feed(running_18());
    expect_eq(d.property("status"), "running");
    d.feed(cooling_5());
    expect_eq(d.property("status"), "cooling");
    d.feed(complete_1());
    expect_eq(d.property("status"), "complete");
}

// "status 0x00 publishes power_off" / "an unrecognised status value ..." (absent here)
fn test_off_and_unknown_states() {
    let d = device();
    d.feed(patched(running_18(), 89, 0x00));
    expect_eq(d.property("status"), "off");
    d.feed(patched(running_18(), 89, 0x99));
    expect_eq(d.property("status"), "");
    expect_eq(d.script_error(), ());
}

// "a real +1Wh step between two consecutive status frames publishes an energy delta"
fn test_an_energy_step() {
    let d = device();
    d.start();
    d.feed(energy_0());
    expect_eq(d.property("energy"), "0");
    d.feed(energy_1());
    expect_eq(d.property("energy"), "1");
    expect_eq(d.property("energy_hour"), ());
}

// "a large jump in the energy byte (cycle-boundary reset) is discarded, not counted"
fn test_an_energy_jump_restarts_the_cycle() {
    let d = device();
    d.feed(energy_0());
    d.feed(patched(energy_1(), 81, 200));
    expect_eq(d.property("energy"), "200");
}

// "notification code 0 publishes drying_is_complete"
fn test_drying_is_complete() {
    let d = device();
    d.feed("aa09307200000000bb");
    expect_eq(json_parse(d.event("notification")).event_type, "drying_is_complete");
}

// "notification codes 0xc9/0xc8 publish remote_control, not drying_is_complete"
fn test_remote_control_notifications() {
    let d = device();
    d.feed("aa09307200c9004bbb");
    expect_eq(d.property("remote_control"), "true");
    expect_eq(d.event("notification"), ());
    d.feed("aa09307200c80048bb");
    expect_eq(d.property("remote_control"), "false");
    expect_eq(d.event("notification"), ());
}

// "course id reads sub=0x30/opcode=0x7f byte[2]" / "an unnamed course id ..." (absent here)
fn test_course() {
    let d = device();
    d.feed("aa07307f0336bb");
    expect_eq(d.property("course"), "normal");
    d.feed("aa07307f0431bb");
    expect_eq(d.property("course"), "ai_course");
    d.feed("aa07307f0530bb");
    expect_eq(d.property("course"), "");
}

// "drum_light reads buf[87] 0x20, confirmed by a real on/off reversal" (and the two siblings)
fn test_feature_flags() {
    let d = device();
    d.feed(drum_light_off());
    expect_eq(d.property("drum_light"), "false");
    d.feed(drum_light_on());
    expect_eq(d.property("drum_light"), "true");
    d.feed(ironing_on());
    expect_eq(d.property("ironing_alert"), "true");
    d.feed(ironing_off());
    expect_eq(d.property("ironing_alert"), "false");
    d.feed(wrinkle_on());
    expect_eq(d.property("wrinkle_care"), "true");
    d.feed(wrinkle_off());
    expect_eq(d.property("wrinkle_care"), "false");
}

// "child_lock reads buf[89] (STATUS_OFFSET) bit 0x10, confirmed by a real on/off reversal"
fn test_button_lock() {
    let d = device();
    d.feed(lock_on());
    expect_eq(d.property("child_lock"), "true");
    d.feed(lock_off());
    expect_eq(d.property("child_lock"), "false");
}

// "reservation_minutes reads buf[70..71] as 16-bit minutes, confirmed by a real arm/cancel"
fn test_reservation() {
    let d = device();
    d.feed(reservation_3h());
    expect_eq(d.property("reserve_time"), "180");
    d.feed(reservation_off());
    expect_eq(d.property("reserve_time"), "0");
}

// "buzzer reads buf[82] while idle" / "buzzer is not published while a real cycle is running"
fn test_buzzer() {
    let d = device();
    d.feed(volume_medium());
    expect_eq(d.property("buzzer"), "medium");
    let e = device();
    e.feed(running_18());
    expect_eq(e.property("buzzer"), ());
    e.feed(patched(volume_medium(), 82, 9));
    expect_eq(e.property("buzzer"), "");
}

// The drum light auto-on read-back, buf[104] 0x08 (one on-transition captured by the fork).
fn test_drum_light_auto_read_back() {
    let d = device();
    d.feed(volume_medium());
    expect_eq(d.property("drum_light_auto"), "false");
    d.feed(patched(volume_medium(), 104, 0x08));
    expect_eq(d.property("drum_light_auto"), "true");
}

fn test_the_eb_record_is_ignored() {
    let d = device();
    let b = aabb_unwrap(hex_decode(state_99()));
    let eb = a::bytes([0x30, 0x0a, 0x00, 0x44, 0x00, 0x01, 0xe5, 0x00, 0x01, 0x00, 0xeb, 0x00, 0x32]);
    eb += b.extract(63, 50);
    d.feed(a::framed(eb));
    expect_eq(d.property("remaining_time"), ());
    expect_eq(d.script_error(), ());
}

fn test_reconnect_publishes_no_defaults() {
    let d = device();
    d.start();
    d.feed(state_99());
    d.drop_device();
    d.start();
    expect_eq(d.property("remaining_time"), "99");
}
