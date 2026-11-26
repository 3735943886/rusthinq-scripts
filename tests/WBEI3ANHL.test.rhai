import "runtime_test" as runtime;
import "aabb_test" as a;

// Tests of WBEI3ANHL.rhai (induction cooktop, read-only). Every frame is a real capture from
// one unit (2026-11-25, rusthinqctl capture --cloud): the EB arrived on connect with every
// burner off; the two ECs arrived when the LG cloud reported PowerLevel_1_2 = 3 (left front)
// and PowerLevel_3_2 = 1 (right front).

fn eb_idle() { "AA6842EBB10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001060000000000000501000000000000000101000000FFFF00FF000000006F3C05FF0000000000000000000000000000000000FEBB" }
fn ec_lf3() { "AACA42ECB00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001060000000000000501000000000000000101000000FFFF00FF000000006F3C05FF0000000000000000000000000000000000B00000030000000100000100000000000000000000000000000000000000000000000000000000000000000000000001060000000000000501000000000000000101000000FFFF00FF000000006F3C05FF000000000000000000000000000000000028BB" }
fn ec_rf1() { "AACA42ECB00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001060000000000000501000000000000000101000000FFFF00FF000000006F3C05FF0000000000000000000000000000000000B00000000000000000000000010000000100000100000000000000000000000000000000000000000000000000000001060000000000000501000000000000000101000000FFFF00FF000000006F3C05FF00000000000000000000000000000000002EBB" }

fn test_the_idle_eb_becomes_il_properties() {
    let d = device();
    d.feed(eb_idle());
    expect_props(d, #{
        available: "true", cooking: "false",
        lf: "false", lf_power_level: "0",
        rf: "false", rf_power_level: "0",
        lr: "false", lr_power_level: "0"
    });
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// A captured 42 B1 frame and the captured reply to it.
fn test_device_frames_are_acknowledged() {
    let d = device();
    d.feed("AA0842B10101F2BB");
    let clips = d.clips();
    expect_eq(clips.len(), 1);
    expect_eq(clips[0].cmd, "ack");
    expect_eq(clips[0].data, "AA08F000B10402BB");
    expect_eq(d.script_error(), ());
}

fn test_the_ec_uses_the_current_record_left_front() {
    let d = device();
    d.feed(ec_lf3());
    expect_props(d, #{ cooking: "true", lf: "true", lf_power_level: "3", rf: "false", lr: "false" });
    expect_eq(d.script_error(), ());
}

fn test_the_ec_uses_the_current_record_right_front() {
    let d = device();
    d.feed(ec_rf1());
    expect_props(d, #{ cooking: "true", lf: "false", rf: "true", rf_power_level: "1", lr: "false" });
    expect_eq(d.script_error(), ());
}

fn test_a_fresh_start_publishes_nothing() {
    let d = device();
    d.start();
    expect(d.property("cooking") == (), "nothing is published before a record");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

fn test_a_reconnect_does_not_overwrite_reported_values() {
    let d = device();
    d.feed(ec_lf3());
    d.drop_device();
    expect_eq(d.property("available"), "false");
    let sent = d.sent().len();
    d.start();
    expect_props(d, #{ cooking: "true", lf: "true", lf_power_level: "3" });
    expect_eq(d.sent().len(), sent);
    expect_eq(d.script_error(), ());
}

fn test_writes_are_rejected_and_nothing_is_sent() {
    let d = device();
    d.start();
    d.set("lf", "true");
    expect_eq(d.sent().len(), 0);
    expect(d.event("reject") != (), "a reject event is published");
    expect_eq(d.script_error(), ());
}
