import "aabb_test" as a;

// Tests of WMLJ32RS.rhai (combi oven), ported from the owner's rethink TS driver.
// The long frame is the unit's real captured state frame
// (testdata/frames/WMLJ32RS.txt): an idle unit - state 0, all published fields 0
// except target_time, whose [28..30] reads 0/0/3 exactly as the TS driver notes.
// The two short frames are the unit's other real captures (undecoded shapes).
// The nonzero frame is CONSTRUCTED to the documented layout to exercise the
// unknown_<n> passthrough (the TS driver's nonzero enum names are unverified:
// modelJSON gives option names, not wire numbers).

fn live() { "AA6540EB00310001DD00000000000000000001000000000000000000000011110000C300000000000353000000000000000001040B150203050609070A0D6300000019001700A900A6009D00DE0097000600A8009B000200000000000000000000000075BB" }

fn test_the_live_frame_becomes_il_properties() {
    let d = device();
    d.feed(live());
    expect_props(d, #{
        available: "true",
        oven_state: "initial",
        standby: "normal",
        control_lock: "disable",
        error: "disable",
        cook_mode: "standby",
        target_temperature: "0",
        current_temperature: "0",
        remaining_time: "0",
        target_time: "3"
    });
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

fn test_the_short_real_frames_are_ignored() {
    let d = device();
    d.feed("AA0740C302E3BB");
    d.feed("AA07F0E90AC1BB");
    expect(d.property("oven_state") == (), "nothing was published");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

fn test_a_constructed_nonzero_frame() {
    let d = device();
    // [0]=5, [1]=1, [2]=1, [3]=1, [14]=7, [16]=200, remain 1:30:15,
    // target 2:00:00, [34]=180.
    d.feed(a::framed(hex_decode("40eb00000000000005010101000000000000000000000700c80000000000000000011e0f020000000000b4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")));
    expect_props(d, #{
        oven_state: "unknown_5",
        standby: "standby",
        control_lock: "enable",
        error: "enable",
        cook_mode: "unknown_7",
        target_temperature: "200",
        current_temperature: "180",
        remaining_time: "5415",
        target_time: "7200"
    });
    expect_eq(d.script_error(), ());
}

fn test_writes_are_rejected_and_nothing_is_sent() {
    let d = device();
    d.start();
    d.set("target_temperature", "200");
    expect_eq(d.sent().len(), 0);
    expect(d.event("reject") != (), "a reject event is published");
    expect_eq(d.script_error(), ());
}
