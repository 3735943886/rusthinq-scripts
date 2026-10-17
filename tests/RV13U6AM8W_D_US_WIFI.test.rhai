import "runtime_test" as runtime;

// Tests of RV13U6AM8W_D_US_WIFI (dryer_rv13_common), ported from upstream rethink's test suite
// (commit 0e57069; real captures from a DLE7300WE, and synthetic frames upstream marks as such).
// Expected values are what upstream's driver publishes, in IL names; the cycle, dry level and
// temperature that upstream labels "Off" while off are "none" here, and a phase upstream cannot
// name ("None") stays unpublished.

fn sample_eb_off() { "AA2330EB000000000000000000000000000000000000000000000000000000000000BB" }
fn sample_eb_starting() { "AA2330EB000001003C00000000000000000000000000000000000000000000000000BB" }
fn sample_eb_drying() { "AA2330EB000032002D00000000000000000000000000000000000000000000000000BB" }
fn sample_ec_drying() { "AA4030EC0000000000000000000000000000000000000000000000000000000000000032001E00000000000000000000000000000000000000000000000003BB" }
fn sample_eb_reconnect() { "AA2330EB001B010001000100000000000100000000A8000000000000006400000046BB" }
fn sample_ec_heavy_duty() { "AA4030EC001B320036003601000305000100000000A90000000100000064000000001B320035003601000305000100000000A90000530100000064000000AFBB" }
fn sample_ec_manual_starting() { "AA4030EC001B010014001412000005010100000040A80000000000000064000000001B010014001412000001010100000040A8000000000000006400000001BB" }
fn sample_eb_paused() { "AA2330EB001B030012001412000002010100000040A8000074320000006400000061BB" }
fn sample_ec_resume() { "AA4030EC001B030012001412000002010100000040A80000743200000064000000001B320012001412000002010100000000A900007403000000640000000ABB" }
fn sample_ec_cooldown() { "AA4030EC000000000000000000000000000000000000000000000000000000000000003300010000000000000000000000000000000000000000000000006FBB" }
fn sample_ec_cooldown_truncated() { "AA4030EC001B330001010301000305000100000040A8000BFD33000000640000000BBB" }
fn sample_ec_power_off() { "AA4030EC001B320012001412000002010100000000A900007403000000640000000F001412000002010100000000A900009F0300000064000000001B00000F000F00000000000100000040A80000A13200000064000000C1BB" }
fn sample_identity() { "AA3730310201534141333839363434323600002DF000008000000000000253414133383936343331300000AEAD000040000000000020BB" }
// A live DLE7300WE, provisioned locally (Normal cycle, Med High, mid-run).
fn live_eb() { "AA2330EB001B32001E002603000304000400000000AB0002090100000064000000F7BB" }
fn live_ec() {
    ["AA4030EC001B32001E002603000304000400000000AB0002090100000064000000001B32001E002603000304000400000000AB00020A01000000640000002EBB",
     "AA4030EC001B32001E002603000304000400000000AB00020A0100000064000000001B32001D002603000304000400000000AB00020A01000000640000002EBB",
     "AA4030EC001B32001D002603000304000400000000AB00020A0100000064000000001B32001D002603000304000400000000AB00020B01000000640000002EBB"]
}
// The live end of a cycle: cooldown 1 min -> Finishing -> Off, then the reconnect snapshot.
fn live_end() {
    ["AA4030EC001B330001002C03000304000400000000AB00055B3200010064000000001B040001002C03000304000400000040AA00055B330001006400000038BB",
     "AA4030EC001B040001002C03000304000400000040AA00055B3300010064000000001B000001000100000000000400000040A800055B040001006400000041BB"]
}
fn live_off_reconnect() { "AA2330EB001B000001000100000000000400000040A800055B0400010064000000EFBB" }

fn fed(frames) { let d = device(); for f in frames { d.feed(f); } d }

// config exposes expected components
fn test_the_descriptor() {
    let d = device();
    d.start();
    let props = runtime::descriptor(d).props;
    for p in ["status", "remaining_time", "power", "drum_running", "cycle", "temp", "dry_level"] { expect(props.contains(p), p); }
    expect(!props.contains("start_time") && !props.contains("stop_time"), "no start/stop time");
    expect(props.status.options.contains("drying"), "drying");
}

// 0xEB Off frame publishes power=OFF and Off phase
fn test_off() { expect_props(fed([sample_eb_off()]), #{ power: "false", status: "off", remaining_time: "0" }); }

// 0xEB Starting frame publishes power=ON, Starting phase, 60 min remaining
fn test_starting() { expect_props(fed([sample_eb_starting()]), #{ power: "true", status: "starting", remaining_time: "60" }); }

// 0xEB Drying frame publishes Drying phase and 45 min remaining
fn test_drying() { expect_props(fed([sample_eb_drying()]), #{ power: "true", status: "drying", remaining_time: "45" }); }

// 0xEC dual-record frame uses current record only
fn test_ec_uses_the_current_record() { expect_props(fed([sample_ec_drying()]), #{ status: "drying", remaining_time: "30" }); }

// real post-reconnect 0xEB publishes Starting/1 min (real capture)
fn test_after_reconnect() { expect_props(fed([sample_eb_reconnect()]), #{ status: "starting", remaining_time: "1", power: "true" }); }

// real heavy-duty 0xEC publishes its current record: Drying/53 min (real capture)
fn test_heavy_duty() { expect_props(fed([sample_ec_heavy_duty()]), #{ status: "drying", remaining_time: "53", power: "true" }); }

// real manual-cycle 0xEC publishes Starting/20 min (real capture)
fn test_manual_starting() { expect_props(fed([sample_ec_manual_starting()]), #{ status: "starting", remaining_time: "20", power: "true" }); }

// real resume 0xEC publishes its current record: Drying/18 min (real capture)
fn test_resume() { expect_props(fed([sample_ec_resume()]), #{ status: "drying", remaining_time: "18", power: "true" }); }

// paused record publishes Paused/18 min, power ON (real capture)
fn test_paused() { expect_props(fed([sample_eb_paused()]), #{ status: "paused", remaining_time: "18", power: "true" }); }

// 0xEC Cooldown frame publishes Cooldown phase
fn test_cooldown() { expect_props(fed([sample_ec_cooldown()]), #{ status: "cooldown", remaining_time: "1", power: "true" }); }

// real heavy-duty EC (auto-sense) reports cycle, temp, dry_level (real capture)
fn test_heavy_duty_settings() { expect_props(fed([sample_ec_heavy_duty()]), #{ cycle: "heavy_duty", temp: "high", dry_level: "normal" }); }

// manual cycle reports cycle=Manual and no dry level; temp varies by heat selection (real captures)
fn test_manual_settings() {
    expect_props(fed([sample_ec_manual_starting()]), #{ cycle: "manual", dry_level: "none", temp: "ultra_low" });
    expect_props(fed([sample_ec_resume()]), #{ cycle: "manual", dry_level: "none", temp: "low" });
}

// drum_running=ON during active drying, OFF when paused (real captures)
fn test_the_drum_runs_while_drying() {
    expect_eq(fed([sample_ec_heavy_duty()]).property("drum_running"), "true");
    expect_eq(fed([sample_eb_paused()]).property("drum_running"), "false");
}

// drum_running=OFF during Starting phase before drum spins up (real capture)
fn test_the_drum_is_still_while_starting() {
    expect_eq(fed([sample_ec_manual_starting()]).property("drum_running"), "false");
}

// start() asks the dryer for its state with the read-only 0xF0ED request
fn test_start_asks_for_the_status() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 1);
    expect_eq(hex_encode_upper(d.sent()[0]), "AA0EF0ED1121010000001800B5BB");
}

// acks the identity and heartbeat frames, not its own 0xEB/0xEC status records (real captures)
fn test_identity_and_heartbeats_are_acked_status_is_not() {
    let d = device();
    d.feed(sample_identity());
    d.feed("AA09307200C9004BBB");
    d.feed(live_eb());
    for f in live_ec() { d.feed(f); }
    let acks = [];
    for c in d.clips() { if c.cmd == "ack" { acks.push(c.data); } }
    expect_eq(acks, ["AA08F000310482BB", "AA08F00072044DBB"]);
}

// consecutive 0xEC frames chain: each first record repeats the previous second (real captures)
fn test_consecutive_ec_frames_chain() {
    let recs = [];
    for f in live_ec() { recs.push(aabb_unwrap(hex_decode(f))); }
    for i in 1..recs.len() { expect_eq(recs[i].extract(2, 29), recs[i - 1].extract(31, 29)); }
}

// live snapshot then updates publish Normal / Med High / Normal and count down 30 -> 29 (real captures)
fn test_a_live_snapshot_and_its_updates() {
    let d = fed([live_eb()]);
    expect_props(d, #{ status: "drying", remaining_time: "30", cycle: "normal", temp: "mid_high",
                       dry_level: "normal", drum_running: "true" });
    let mins = [];
    for f in live_ec() { d.feed(f); mins.push(d.property("remaining_time")); }
    expect_eq(mins, ["30", "29", "29"]);
}

// end of cycle publishes Finishing then Off with 0 min left and no settings (real captures)
fn test_the_end_of_a_cycle() {
    let d = fed([live_ec()[2], live_end()[0]]);
    expect_props(d, #{ status: "finishing", remaining_time: "0", drum_running: "false" });
    d.feed(live_end()[1]);
    expect_props(d, #{ status: "off", remaining_time: "0", power: "false", cycle: "none", temp: "none", dry_level: "none" });
}

// reconnect snapshot while off publishes 0 min, not the stale 1 (real capture)
fn test_a_reconnect_snapshot_while_off() {
    expect_props(fed([live_off_reconnect()]), #{ status: "off", remaining_time: "0", cycle: "none", dry_level: "none" });
}

// no published value is "None", which Home Assistant reads as unknown (real captures)
fn test_nothing_reads_unknown() {
    let frames = [live_eb()];
    frames += live_ec();
    frames += live_end();
    frames.push(live_off_reconnect());
    let d = fed(frames);
    for p in ["status", "remaining_time", "power", "drum_running", "cycle", "temp", "dry_level"] {
        expect(d.property(p) != () && d.property(p) != "None", p);
    }
}

// frames with wrong device byte (not 0x30) are ignored
fn test_another_class_is_ignored() {
    expect_eq(fed(["AA2320EB000000000000000000000000000000000000000000000000000000000000BB"]).property("power"), ());
}

// frames that are too short are ignored
fn test_a_short_frame_is_ignored() { expect_eq(fed(["AA0430EB00BB"]).property("power"), ()); }

// real cooldown capture (truncated 35-byte EC) is ignored
fn test_a_truncated_ec_is_ignored() { expect_eq(fed([sample_ec_cooldown_truncated()]).property("power"), ()); }

// real power-off capture (89-byte three-record EC) is ignored
fn test_a_three_record_ec_is_ignored() { expect_eq(fed([sample_ec_power_off()]).property("power"), ()); }

// identity/info packet (cmd 0x31) is ignored without error
fn test_the_identity_frame_is_ignored() {
    let d = fed([sample_identity()]);
    expect_eq(d.property("power"), ());
    expect_eq(d.script_error(), ());
}

// undecoded status value: upstream publishes "None"; here it stays unpublished
fn test_an_unknown_phase_is_left_unpublished() {
    let d = fed(["AA2330EB0000FF000000000000000000000000000000000000000000000000000000BB"]);
    expect_eq(d.property("status"), ());
    expect_eq(d.property("power"), "true");
}
