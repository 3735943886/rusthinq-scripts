import "aabb_test" as a;

// Tests of WBEI3GT.rhai (induction cooktop), ported from the owner's rethink TS
// driver. The idle frame is the unit's one real capture
// (testdata/frames/WBEI3GT.txt): WiFiAccess 0x01, every other byte 0 - an off
// cooktop reads INIT/0 everywhere, the only decode the TS driver calls
// confirmed. The lit-burner and EC frames are CONSTRUCTED to the modelJSON
// protocol order (the TS driver labels every nonzero decode unverified until
// lit-burner captures exist).

fn idle() { "AA3642EB0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005BBB" }

fn test_the_live_idle_frame_becomes_il_properties() {
    let d = device();
    d.feed(idle());
    expect_props(d, #{
        available: "true",
        cooking: "false",
        flex_mode: "OFF",
        remote_start: "false",
        drawer_power_level: "0",
        lf: "false", lf_state: "INIT", lf_power_level: "0",
        lf_operation_time: "0", lf_timer_remaining: "0",
        lr: "false", rf: "false", rr: "false", center: "false",
        center_state: "INIT"
    });
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

fn test_a_constructed_lit_burner_frame() {
    let d = device();
    // WiFiAccess 0x03 (remote start bit set), flex LEFT_FLEX; LF cooking at
    // level 9, operation 0:01:30, timer remaining 0:05:00; center PAUSED at 3.
    d.feed(a::framed(hex_decode("42eb030101091e01000000050000000000000000000000000000000000000000000000000000000002030000000000000000")));
    expect_props(d, #{
        cooking: "true",
        flex_mode: "LEFT_FLEX",
        remote_start: "true",
        lf: "true",
        lf_state: "COOKING_IN_PROGRESS",
        lf_power_level: "9",
        lf_operation_time: "90",
        lf_timer_remaining: "300",
        center: "true",
        center_state: "PAUSED",
        center_power_level: "3",
        rr: "false"
    });
    expect_eq(d.script_error(), ());
}

fn test_a_constructed_ec_uses_the_second_record() {
    let d = device();
    // First record all zero; second has RF cooking at level 5.
    d.feed(a::framed(hex_decode("42ec000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001050000000000000000000000000000000000000000000000000000")));
    expect_props(d, #{
        cooking: "true",
        rf: "true",
        rf_state: "COOKING_IN_PROGRESS",
        rf_power_level: "5",
        lf: "false"
    });
    expect_eq(d.script_error(), ());
}

fn test_writes_are_rejected_and_nothing_is_sent() {
    let d = device();
    d.start();
    d.set("flex_mode", "LEFT_FLEX");
    expect_eq(d.sent().len(), 0);
    expect(d.event("reject") != (), "a reject event is published");
    expect_eq(d.script_error(), ());
}
