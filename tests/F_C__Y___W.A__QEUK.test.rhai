import "runtime_test" as runtime;

// Tests of F_C__Y___W.A__QEUK, ported from upstream rethink's test suite (commit 0e57069;
// captures from an F4WV709P1, except sample_delayed_ec, which upstream calls synthetic).
// Expected values and writes are what upstream's driver publishes and sends for the same input,
// in IL names; door_lock and child_lock are true while locked (upstream publishes them
// inverted, for Home Assistant's lock class).

fn sample_washing_ec() { "AA4220EC001C06012C02010100030A0601000000004000000306000A003400000500001C06012B02010100030A0601000000004000000306000A003400000500FEBB" }
fn sample_steam_on_ec() { "AA4220EC001C01033B033B0100030A0401000000000000000301002D003400000400001C01032803280100030A0601000000800000000401002D0034000004002ABB" }
fn sample_wrinkle_care_on_ec() { "AA4220EC001C060126012B0100030A04010000000060000001060024003400000400001C060125012B0100030A04010000000060000001060024003400000400D8BB" }
fn sample_child_lock_on_ec() { "AA4220EC001C060109010C0100030A04010000000040000001060023003400000400001C060109010C0100030A040100000000C000000106002300340000040001BB" }
fn sample_remote_start_on_ec() { "AA4220EC001C01003B003B3200030904010000000100000001010027003400000000001C01011501150700030704010000000000000002010027003400000300B9BB" }
fn sample_delayed_ec() { "AA4220EC001C03004800480100000A04010004000000000006030009003400000500001C03004700480100000A040100040000000000060300090034000005009BBB" }
fn sample_spinning_ec() { "AA4220EC001C08000302010100000A0000000000004000000608000A003400000500001C08000202010100000A0000000000004000000608000A003400000500D6BB" }
fn sample_end_ec() { "AA4220EC001C0A0000020101000000000000000000400000060A000A003400000500001C0A0000020101000000000000000000000000060A000A00340000050067BB" }
fn sample_off_ec() { "AA4220EC001C000000020101000000000000000000000000030A000A003400000500001C0000000201010000000000000000000000000300000A0034000005009BBB" }
fn sample_e2_ignored() { "AA2420E2091C04032603260100030A0601000000400000000604000A003400000500B8BB" }
fn sample_washing_eb() { "AA2420EB001C06003200480100000A0601000000000000000606000A003400000500C4BB" }
fn sample_door_unlocked() { "AA0720D800FCBB" }
fn sample_door_locked() { "AA0720D80BE1BB" }
fn sample_door_locked_0x30() { "AA0720D8308CBB" }
fn sample_error_ec() { "AA4220EC001C04031503150100030A06010007000000000001040032003400000400001C12031503150101030A060100070000000000041200320034000004009BBB" }

fn last(d) { let s = d.sent(); hex_encode_upper(s[s.len() - 1]) }

// config exposes expected components on construction
fn test_the_descriptor_lists_the_components() {
    let d = device();
    d.start();
    let props = runtime::descriptor(d).props;
    for p in ["power", "start", "pause", "status", "error", "error_message", "course", "temp", "spin",
              "remote_start", "door_lock", "steam", "wrinkle_care", "child_lock", "active", "cycles",
              "initial_time", "remaining_time", "reserve_time"] {
        expect(props.contains(p), p);
    }
    expect(props.status.options.contains("washing") && props.status.options.contains("error"), "states");
}

// delayed-start state decodes status, course, spin, temp, times and delay
fn test_delayed() {
    let d = device();
    d.feed(sample_delayed_ec());
    expect_props(d, #{ power: "true", status: "delayed", course: "cotton", spin: "1400", temp: "40", remaining_time: "71", initial_time: "72", reserve_time: "240", remote_start: "false", active: "false", door_lock: "true", cycles: "9" });
}

// washing state decodes status, course, spin, temp, times (real capture)
fn test_washing() {
    let d = device();
    d.feed(sample_washing_ec());
    expect_props(d, #{ power: "true", status: "washing", course: "cotton", spin: "1400", temp: "60", remaining_time: "103", initial_time: "121", reserve_time: "0", remote_start: "false", steam: "false", wrinkle_care: "false", active: "true", child_lock: "false", door_lock: "true", cycles: "10", error: "false", error_message: "OK" });
}

// spinning state decodes status and remaining time
fn test_spinning() {
    let d = device();
    d.feed(sample_spinning_ec());
    expect_props(d, #{ status: "spinning", remaining_time: "2", spin: "1400" });
}

// end state: status=End, power still ON, spin/temp/course cleared
fn test_end() {
    let d = device();
    d.feed(sample_end_ec());
    expect_props(d, #{ status: "end", power: "true", remaining_time: "0", spin: "none", temp: "none", door_lock: "true", cycles: "10" });
    expect_eq(d.property("course"), ());
}

// steam=ON (real capture, Ready state)
fn test_steam_on() {
    let d = device();
    d.feed(sample_steam_on_ec());
    expect_props(d, #{ steam: "true", status: "standby", temp: "60", spin: "1400", remaining_time: "220", wrinkle_care: "false" });
}

// steam toggles correctly across ON→OFF sequence
fn test_steam_toggles() {
    let d = device();
    d.feed(sample_steam_on_ec());
    expect_props(d, #{ steam: "true" });
    d.feed(sample_washing_ec());
    expect_props(d, #{ steam: "false" });
}

// wrinkle_care=ON when rec[17] bit5 is set (real capture)
fn test_wrinkle_care_on() {
    let d = device();
    d.feed(sample_wrinkle_care_on_ec());
    expect_props(d, #{ wrinkle_care: "true", steam: "false", status: "washing", temp: "40", spin: "1400", active: "true" });
}

// wrinkle_care toggles correctly across ON→OFF sequence
fn test_wrinkle_care_toggles() {
    let d = device();
    d.feed(sample_wrinkle_care_on_ec());
    expect_props(d, #{ wrinkle_care: "true" });
    d.feed(sample_washing_ec());
    expect_props(d, #{ wrinkle_care: "false" });
}

// child_lock=OFF (Locked) when rec[17] bit7 is set (engaged, real capture)
fn test_child_lock_on() {
    let d = device();
    d.feed(sample_child_lock_on_ec());
    expect_props(d, #{ child_lock: "true", status: "washing", temp: "40", spin: "1400", remaining_time: "69", active: "true" });
}

// child_lock toggles correctly when engaged/disengaged
fn test_child_lock_toggles() {
    let d = device();
    d.feed(sample_child_lock_on_ec());
    expect_props(d, #{ child_lock: "true" });
    d.feed(sample_washing_ec());
    expect_props(d, #{ child_lock: "false" });
}

// remote_start=ON when rec[7] bit1 is set (real capture, Ready state)
fn test_remote_start_on() {
    let d = device();
    d.feed(sample_remote_start_on_ec());
    expect_props(d, #{ remote_start: "true", status: "standby", course: "cotton", spin: "1000", temp: "40", remaining_time: "81", initial_time: "81", steam: "false", wrinkle_care: "false", active: "false" });
}

// remote_start toggles correctly across ON→OFF sequence
fn test_remote_start_toggles() {
    let d = device();
    d.feed(sample_remote_start_on_ec());
    expect_props(d, #{ remote_start: "true" });
    d.feed(sample_delayed_ec());
    expect_props(d, #{ remote_start: "false" });
}

// off state: power=OFF, status=Off (real capture)
fn test_off() {
    let d = device();
    d.feed(sample_off_ec());
    expect_props(d, #{ power: "false", status: "off", active: "false", door_lock: "false" });
}

// 0xEB compact packet is parsed identically to 0xEC current record
fn test_eb_record() {
    let d = device();
    d.feed(sample_washing_eb());
    expect_props(d, #{ status: "washing", remaining_time: "50", spin: "1400", temp: "60", cycles: "10" });
}

// 0xE2 end-of-cycle alert packet is silently ignored; so are frames without AA..BB or of
// another length
fn test_other_frames_change_nothing() {
    let d = device();
    d.feed(sample_washing_ec());
    let before = d.property("status") + d.property("remaining_time") + d.property("door_lock");
    for x in [sample_e2_ignored(), "001122", "AA0820EC010203040506BB"] {
        d.feed(x);
        expect_eq(d.property("status") + d.property("remaining_time") + d.property("door_lock"), before);
    }
}

// door_lock=OFF (Locked) derived from 0xEC for active/delayed states even without 0xD8
fn test_door_lock_follows_the_state_without_d8() {
    let d = device();
    d.feed(sample_delayed_ec());
    expect_props(d, #{ door_lock: "true" });
    d.feed(sample_washing_ec());
    expect_props(d, #{ door_lock: "true" });
    d.feed(sample_off_ec());
    expect_props(d, #{ door_lock: "false" });
}

// 0xD8 door_lock=ON (Unlocked) is ignored during active wash (status-derived OFF prevails)
fn test_d8_is_ignored_during_a_wash() {
    let d = device();
    d.feed(sample_washing_ec());
    expect_props(d, #{ door_lock: "true" });
    d.feed(sample_door_unlocked());
    expect_props(d, #{ door_lock: "true" });
}

// 0xD8 overrides door_lock during Ready/startup phase
fn test_d8_sets_the_lock_before_a_cycle() {
    let d = device();
    d.feed(sample_door_locked());
    expect_props(d, #{ door_lock: "true" });
    d.feed(sample_door_unlocked());
    expect_props(d, #{ door_lock: "false" });
}

// 0xD8 buf[2]=0x30 (cycle-start lock) publishes door_lock=OFF (real capture)
fn test_d8_cycle_start_lock() {
    let d = device();
    d.feed(sample_door_locked_0x30());
    expect_props(d, #{ door_lock: "true" });
}

// door_lock toggles correctly across lock/unlock sequence
fn test_d8_toggles() {
    let d = device();
    d.feed(sample_door_unlocked());
    expect_props(d, #{ door_lock: "false" });
    d.feed(sample_door_locked());
    expect_props(d, #{ door_lock: "true" });
    d.feed(sample_door_unlocked());
    expect_props(d, #{ door_lock: "false" });
}

// error=ON, error_message=DE2 when rec[8]=0x01 (dE2 door lock error, real capture)
fn test_error() {
    let d = device();
    d.feed(sample_error_ec());
    expect_props(d, #{ error: "true", error_message: "Door lock error (DE2)", status: "error", cycles: "50" });
}

// error clears when machine recovers from error state
fn test_error_clears() {
    let d = device();
    d.feed(sample_error_ec());
    expect_props(d, #{ error: "true" });
    d.feed(sample_washing_ec());
    expect_props(d, #{ error: "false", error_message: "OK" });
}

// start() sends the F0ED initialisation packet; HA write power=ON / power=OFF / pause button
fn test_query_power_and_pause() {
    let d = device();
    d.start();
    expect_eq(last(d), "AA0EF0ED1121010000001800B5BB");
    d.set("power", "true");
    expect_eq(last(d), "AA08F02A010098BB");
    d.set("power", "false");
    expect_eq(last(d), "AA09F0240101009CBB");
    d.set("pause", "");
    expect_eq(last(d), "AA09F02404010099BB");
}

// HA write start button. Upstream sends it whatever the panel says; here it waits for remote start.
fn test_start_needs_remote_start() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("start", "");
    expect_eq(d.sent().len(), n);
    d.feed(sample_remote_start_on_ec());
    d.set("start", "");
    expect_eq(last(d), "AA09F02405010098BB");
}

// HA write to unknown property emits no packet
fn test_unknown_and_read_only_writes_are_rejected() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("does-not-exist", "whatever");
    d.set("status", "off");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "rejects are published");
}

// 0xD8 and 0xE2 are acked; bare 0xEB/0xEC status is not (upstream commit 8465439)
fn test_acks_other_frames_but_not_status() {
    let d = device();
    d.feed(sample_door_unlocked());
    d.feed(sample_e2_ignored());
    d.feed(sample_washing_eb());
    d.feed(sample_washing_ec());
    expect_eq(d.clips().map(|c| c.data),
              [hex_encode_upper(aabb_wrap([0xf0, 0x00, 0xd8, 0x04])), hex_encode_upper(aabb_wrap([0xf0, 0x00, 0xe2, 0x04]))]);
}
