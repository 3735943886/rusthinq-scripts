import "aabb_test" as a;

// Tests of D121110.rhai (dishwasher), ported from the owner's rethink TS driver.
// The EB frame and the EC frame are real captures from the owner's unit
// (testdata/frames/D121110.txt, 2026-11-04): state Standby/Off, initial time
// 2:41 (161 min), remaining 0:01, door open. The running-state frame is
// CONSTRUCTED to the TS driver's documented layout (its running-state decode
// follows the family skeleton and is unverified on this unit - see the TS
// driver's provenance note (c)).

fn eb() { "AA2032EB001804000002290000000100001200000000000000000000000014BB" }
fn ec() { "AA3A32EC00180400000229000000010000120000000000000000000000000018000000022900000001000012000000000000000000000000E7BB" }
fn identity() { "AA373231020153414133383638373131380000254D00008000000000000253414133383636393731340000ACFFFFFC000000000000B4BB" }

fn test_the_live_eb_becomes_il_properties() {
    let d = device();
    d.feed(eb());
    expect_props(d, #{
        available: "true",
        power: "false",
        status: "Standby",
        process: "Idle",
        course: "NONE",
        initial_time: "161",
        remaining_time: "1",
        delay_start_time: "0",
        door: "true",
        child_lock: "false",
        rinse_refill: "false",
        salt_refill: "false",
        extra_dry: "false",
        high_temp: "false",
        rinse_level: "0",
        softening_level: "0"
    });
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

fn test_the_live_ec_publishes_the_current_record() {
    let d = device();
    d.feed(ec());
    // The second record reads state 0 (Off); everything else matches the EB.
    expect_props(d, #{
        status: "Off",
        power: "false",
        initial_time: "161",
        remaining_time: "1",
        door: "true"
    });
    expect_eq(d.script_error(), ());
}

fn test_the_identity_frame_is_ignored() {
    let d = device();
    d.feed(identity());
    expect(d.property("status") == (), "nothing was published");
    expect_eq(d.script_error(), ());
}

fn test_a_constructed_running_record() {
    let d = device();
    // state Running, process Washing, initial 1:30, course 5, remaining 0:45,
    // flags1 all four bits, options extra-dry + high-temp, levels 3 / 2.
    d.feed(a::framed(hex_decode("32eb0018020200011e0500002d00000f0c0302000000000000000000")));
    expect_props(d, #{
        power: "true",
        status: "Running",
        process: "Washing",
        course: "NORMAL-ECO",
        initial_time: "90",
        remaining_time: "45",
        child_lock: "true",
        door: "true",
        rinse_refill: "true",
        salt_refill: "true",
        extra_dry: "true",
        high_temp: "true",
        rinse_level: "3",
        softening_level: "2"
    });
    expect_eq(d.script_error(), ());
}

fn test_the_course_is_gated_on_running() {
    let d = device();
    // Same constructed record with state Ready (1): the course byte (5) and the
    // option bits must not surface.
    d.feed(a::framed(hex_decode("32eb0018010200011e0500002d00000f0c0302000000000000000000")));
    expect_props(d, #{
        status: "Ready",
        course: "NONE",
        extra_dry: "false",
        high_temp: "false"
    });
    expect_eq(d.script_error(), ());
}

fn test_power_writes_are_the_f026_frames() {
    let d = device();
    d.set("power", "true");
    expect_eq(a::inner_hex(d, 0), "f02616");
    expect_eq(d.property("power"), "true"); // optimistic (the H01 pattern)
    d.set("power", "false");
    expect_eq(a::inner_hex(d, 1), "f02612");
    expect_eq(d.property("power"), "false");
    expect_eq(d.script_error(), ());
}

fn test_a_read_only_property_is_rejected() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("status", "Running");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "a reject event is published");
}

fn test_start_sends_nothing() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}
