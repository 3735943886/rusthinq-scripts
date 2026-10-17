import "runtime_test" as runtime;

// Tests of T1789EFH_F, ported from upstream rethink's test suite (commit 0e57069; real captures from
// a WT7300CW, firmware 2.10.95, and synthetic frames upstream marks as such). Expected values are
// what upstream's driver publishes, in IL names; a phase upstream cannot name ("None") stays
// unpublished.

fn sample_eb_off() { "AA2120EB00000000000000000000000000000000000000000000000000000000BB" }
fn sample_eb_wash() { "AA2120EB000005001E0000000000000000000000000000000000000000000000BB" }
fn sample_ec_off() { "AA3C20EC00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000BB" }
fn sample_ec_idle() { "AA3C20EC0019000000011A00000000000000000000100000040800000064000019000000011A000000000000000000001000000408000000640037BB" }
fn sample_ec_heavy_duty() { "AA3C20EC0019050018011A0200050304000000000410000000050000006400001906001D011E0200000304000000000410000000050000006400FABB" }
fn sample_ec_running() { "AA3C20EC001905002B00340800030104000000000410000000030000006400001902002B0034080003010400000000041000000005000000640054BB" }
fn sample_ec_paused() { "AA3C20EC001902002B00340800030104000000000410000000050000006400001902002B00340800030104000000000010000000050000006400A9BB" }
fn sample_ec_resumed() { "AA3C20EC001902002B00340800030104000000000010000000050000006400001905002B00340800030104000000000010000000020000006400ADBB" }
fn sample_ec_spin() { "AA3C20EC00190700010019010000030000000000440000000006000000640000190800000019010000030000000000440000000107000000640099BB" }
fn sample_short_ack() { "AA0720D80EE2BB" }
fn sample_identity() { "AA372031020153414133393935353130330000D05F0000800000000000025341413339393534393033000044FC000040000000000008BB" }
fn sample_e2_settings() { "AA2120E20319030102003A010003030100000000400000000101000000640082BB" }
// Seven consecutive EC frames from a Rinse + Spin start.
fn cycle_start() {
    ["AA3C20EC00190000000000000000000000000000000000000000000000640000190100000000000000000000000000008000000000000000640038BB",
     "AA3C20EC001901000000000000000000000000000080000000000000006400001901011D003A010003030400000000402000000000000000640167BB",
     "AA3C20EC001901011D003A0100030304000000004020000000000000006401001901001C001C07000103040000000040000000000000000064006CBB",
     "AA3C20EC001901001C001C07000103040000000040000000000000000064000019010021002011000003010000000000100000000000000064008EBB",
     "AA3C20EC001901002100201100000301000000000010000000000000006400001903002100201100000301000000000010000000010000006400E8BB",
     "AA3C20EC00190300210020110000030100000000001000000001000000640000190300210020110000030100000000041000000001000000640091BB",
     "AA3C20EC001903002100201100000301000000000410000000010000006400001906001D001C110000030100000000041000000003000000640090BB"]
}

fn fed(frames) { let d = device(); for f in frames { d.feed(f); } d }

// config exposes expected components
fn test_the_descriptor() {
    let d = device();
    d.start();
    let props = runtime::descriptor(d).props;
    for p in ["power", "status", "remaining_time"] { expect(props.contains(p), p); }
    for p in ["remaining_time_min", "remaining_time_sec", "start_time", "stop_time"] { expect(!props.contains(p), p); }
    expect(props.status.options.contains("wash_main"), "wash_main");
}

// 0xEB Off frame publishes power=OFF, Off phase, 0 min remaining
fn test_eb_off() { expect_props(fed([sample_eb_off()]), #{ power: "false", status: "off", remaining_time: "0" }); }

// 0xEB Wash (main) frame publishes power=ON, Wash phase, 30 min remaining
fn test_eb_wash() { expect_props(fed([sample_eb_wash()]), #{ power: "true", status: "wash_main", remaining_time: "30" }); }

// 0xEC dual-record Off frame publishes power=OFF
fn test_ec_off() { expect_props(fed([sample_ec_off()]), #{ power: "false", status: "off", remaining_time: "0" }); }

// real idle EC publishes power=OFF, Off phase, 0 min (real capture)
fn test_idle() { expect_props(fed([sample_ec_idle()]), #{ power: "false", status: "off", remaining_time: "0" }); }

// real heavy-duty EC publishes its current record: Rinse / Drain/29 min (real capture)
fn test_heavy_duty() { expect_props(fed([sample_ec_heavy_duty()]), #{ power: "true", status: "rinse_drain", remaining_time: "29" }); }

// real pause-transition EC publishes Paused/43 min (real capture)
fn test_the_pause_transition() { expect_props(fed([sample_ec_running()]), #{ power: "true", status: "paused", remaining_time: "43" }); }

// real paused EC publishes Paused/43 min, power ON (real capture)
fn test_paused() { expect_props(fed([sample_ec_paused()]), #{ power: "true", status: "paused", remaining_time: "43" }); }

// pause -> paused -> resume reads Paused, Paused, Wash (main) with 43 min frozen (real captures)
fn test_pause_paused_resume() {
    let d = fed([sample_ec_running()]);
    expect_props(d, #{ status: "paused", remaining_time: "43" });
    d.feed(sample_ec_paused()); expect_props(d, #{ status: "paused", remaining_time: "43" });
    d.feed(sample_ec_resumed()); expect_props(d, #{ status: "wash_main", remaining_time: "43" });
}

// real spin EC publishes Spin, 0 min remaining (real capture)
fn test_spin() { expect_props(fed([sample_ec_spin()]), #{ power: "true", status: "spin", remaining_time: "0" }); }

// acks the heartbeat and settings frames the washer repeats when unacked (real captures)
fn test_the_repeated_frames_are_acked() {
    let d = fed(["AA09207200000010BB", "AA0720D8219FBB", "AA2120E2031903003B003A010003030400000000400000000201000000640046BB"]);
    let acks = [];
    for c in d.clips() { if c.cmd == "ack" { acks.push(c.data); } }
    expect_eq(acks, ["AA08F00072044DBB", "AA08F000D8042BBB", "AA08F000E204DDBB"]);
    expect_eq(d.sent().len(), 0); // acks do not go out as packets
}

// does not ack its own 0xEC status records
fn test_status_records_are_not_acked() { expect_eq(fed([sample_ec_running()]).clips().len(), 0); }

// start() asks the washer for its state with the read-only 0xF0ED request
fn test_start_asks_for_the_status() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 1);
    expect_eq(hex_encode_upper(d.sent()[0]), "AA0EF0ED1121010000001800B5BB");
}

// consecutive 0xEC frames chain: each first record repeats the previous second (real captures)
fn test_consecutive_ec_frames_chain() {
    let frames = [];
    for f in cycle_start() { frames.push(hex_decode(f)); }
    for i in 1..frames.len() { expect_eq(frames[i].extract(4, 27), frames[i - 1].extract(31, 27), "frame " + i); }
}

// a cycle start publishes each change as it happens, not one frame late (real captures)
fn test_a_cycle_start_publishes_each_change() {
    let d = device();
    let seen = [];
    for f in cycle_start() { d.feed(f); seen.push(d.property("status") + "/" + d.property("remaining_time")); }
    expect_eq(seen, ["fill_sense/0", "fill_sense/29", "fill_sense/28", "fill_sense/33", "wash_initial/33",
                     "wash_initial/33", "rinse_drain/29"]);
}

// frames with wrong device byte (not 0x20) are ignored
fn test_another_class_is_ignored() {
    expect_eq(fed(["AA2130EB00000000000000000000000000000000000000000000000000000000BB"]).property("power"), ());
}

// 0xE2 settings-echo packet is ignored
fn test_the_settings_echo_is_ignored() { expect_eq(fed([sample_e2_settings()]).property("power"), ()); }

// short idle/ack packet (0xD8) is ignored
fn test_the_short_packet_is_ignored() { expect_eq(fed([sample_short_ack()]).property("power"), ()); }

// identity/info packet (cmd 0x31) is ignored without error
fn test_the_identity_frame_is_ignored() {
    let d = fed([sample_identity()]);
    expect_eq(d.property("power"), ());
    expect_eq(d.script_error(), ());
}

// frames that are too short are ignored
fn test_a_short_frame_is_ignored() { expect_eq(fed(["AA0420EB00BB"]).property("power"), ()); }

// undecoded status value: upstream publishes "None"; here it stays unpublished
fn test_an_unknown_phase_is_left_unpublished() {
    let d = fed(["AA2120EB0000FF00000000000000000000000000000000000000000000000000BB"]);
    expect_eq(d.property("status"), ());
    expect_eq(d.property("power"), "true");
}
