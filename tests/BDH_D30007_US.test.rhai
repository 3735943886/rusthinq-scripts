import "runtime_test" as runtime;

// Tests of BDH_D30007_US, ported from upstream rethink's test suite (commit 0e57069; live captures
// correlated against the LG cloud's decoded state). Expected values are what upstream's driver
// publishes, in IL names; its documented 0 codes ("None") read "none".

fn tub_clean() { "aaff300a0066004f45000100ec005400030200020700000000640000010000000000040700000000000481070000000000000000000000000000000300021300000000a000000100000200000413000000000000810700000000000000000000000000317ebb" }
fn time_dry() { "aaff300a0066004f48000100ec005400000300021300000000a000000100000200000413000000000000810700000000000000000000000000000002000215000000001e001e0100000200000415000000000000810700000000000000000000000000b665bb" }
fn ai_course() { "aaff300a0066004f5d000100ec005400000200020400000000c3001e010000020000040400000000000081070000000000000000000000000000000200022c0000000064001e010000000000041c00000000000481070000000000000000000000000039cabb" }
fn towels() { "aaff300a0066004f51000100ec00540000030002100000000096001e01000001000004100000000000008107000000000000000000000000000000020002020000000064001e0100000000000402000000000004810700000000000000000000000000e470bb" }
fn drying() { "aaff300a0066004e58000100ec005400000200020400000000c200c3070300020002040400000000004081070000000000000000000000000000000200020400000000c100c30703000200030404000000000040810700000000000000000000000000959ebb" }
fn dry_level_very() { "aaff300a0066004f13000100ec00540004020002070000000064000001000000000004070000002000048107000000000000000000000000000005020002070000000064000001000000000004070000002000048107000000000000000000000000004992bb" }
fn eco_hybrid_eco() { "aaff300a0066004f05000100ec005400030200020700000000640000010000000000040700000020000481070000000000000000000000000000030100020700000000640000010000000000040700000020000481070000000000000000000000000002b3bb" }
fn buzzer_off() { "aaff300a0066004f26000100ec005400030200020700000000640000010000000000040700000000000481070000000000000000000000000000030200020700000000640000010000000000000700000000000481070000000000000000000000000000b1bb" }
fn wrinkle_care_on() { "aaff300a0066004f3b000100ec00540003020002070000000064000001000000000004070000000000048107000000000000000000000000000003020002070000000064000001000000000004070000000800048107000000000000000000000000002692bb" }
fn damp_dry_signal_on() { "aaff300a0066004f20000100ec005400030200020700000000640000010000000000040700000000000481070000000000000000000000000000030200020700000000640000010000000000040700000040000481070000000000000000000000000086bfbb" }
fn remote_start_on() { "aaff300a0066004f6b000100ec00540003020002070000000064001e01000000000004070000000000048107000000000000000000000000000003020002070000000064001e0100000000000407000000000044810700000000000000000000000000a3d4bb" }
fn pauses() { "aaff300a0066004e86000100ec005400000200020400000000bf00c3070300020006040400000000004081070000000000000000000000000000000200020400000000bf00c303070002000a0404000000200000810700000000000000000000000000e6fdbb" }
fn powers_off() { "aaff300a0066004e8f000100ec005400000200020400000000bf00c303070002000a04040000002000008107000000000000000000000000000000000002000000000000000000030000000a0400000000000000810700000000000000000000000000f3b5bb" }
fn condenser_clean() { "aaff300a0066005f34000100ec0054000002000204000000001500c30703000406f70404000000000040830700000000000000000000000000000002000204000000001400c31107000506fd0404000000000060830700000000000000000000000000ed51bb" }
fn cooling() { "aaff300a0066005f7f000100ec0054000002000204000000001000c31107000507040404000000000060830700000000000000000000000000000002000204000000001000c30811000507060404000000000040830700000000000000000000000000c820bb" }
fn end_remote_maintain() { "aaff300a0066006060000100ec0054000002000204000000000100c30811000507180404000000000040830700000000000000000000000000000002000204000000000100c316080007071a0404000000200040830700000000000000000000000000c4ebbb" }
fn remote_maintain_on() { "aaff300a0066006191000100ec0054000302000207000000006400640e0100000000040700000000004481070000000000000000000000000000030200020700000000680069070e0002000a040700000000004083070000000000000000000000000000a8bb" }
fn remote_maintain_off() { "aaff300a00660060fe000100ec0054000002000204000000000100c316080007071a04040000000000408307000000000000000000000000000000000002000000000000000000160000071c0400000000000000810700000000000000000000000000b025bb" }
fn remote_start_switched_off() { "aaff300a0066007b9f000100ec0054000302000207000000006400000100000000000407000000000044810700000000000000000000000000000302000207000000006400000100000000000407000000000004810700000000000000000000000000bd50bb" }
fn hand_started_with_remote_off() { "aaff300a0066006eac000100ec0054000000000200000000000000000100000000000400000000200000810700000000000000000000000000000302000207000000006400640e010000000004070000000000448107000000000000000000000000002823bb" }
fn condenser_clean_cloud() { "aaff300a006600738c000100ec005400030200020700000000150055070e000402500407000000000040830700000000000000000000000000000302000207000000001400551107000502590407000000000060830700000000000000000000000000b6f9bb" }
fn cycle_optimization_off() { "aaff300a0066007c2e000100ec0054000301000207000000006400640100000000000407000000200004810700000000000000000000000000000302000207000000006400640100000000000407000000200004800700000000000000000000000000aaf8bb" }
fn cycle_optimization_on() { "aaff300a0066007c61000100ec0054000302000207000000006400640100000000000207000000200004800700000000000000000000000000000302000207000000006400640100000000000207000000200004810700000000000000000000000000ee33bb" }
fn app_quick_dry() { "aaff300a0066007d2d000100ec005400000000020d000000001e001e010000050000020d000000000000810700000000000000000000000000000002000217000000003c001e0100000200000217000000000000810700000000000000000000000000662cbb" }
fn app_shrinkage_relief() { "aaff300a0066007d1e000100ec0054000003000216000000003c001e010000010000021600000000000081070000000000000000000000000000020200022e000000006e001e0100000200000220000000000000810700000000000000000000000000f7e8bb" }
fn downloaded_cycle() { "aaff300a0066007d52000100ec00540000030002320000000028001e01000002000002220000000000008107000000000000000000000000000003020002ff000000006400280100000000000207000072080004810700000000000000000000000000ede3bb" }

fn fed(frames) { let d = device(); for f in frames { d.feed(f); } d }
fn course_of(f) { fed([f]).property("course") }

// the course table covers the whole dial
fn test_the_dial() {
    expect_eq(course_of(tub_clean()), "drum_care");
    expect_eq(course_of(time_dry()), "timed_dry");
    expect_eq(course_of(towels()), "towels");
    expect_eq(course_of(drying()), "bedding");
    expect_eq(course_of(dry_level_very()), "normal");
}

// cycles reachable only from the app are named from the panel, not the cloud
fn test_app_only_cycles_use_the_panel_names() {
    expect_eq(course_of(app_quick_dry()), "quick_dry"); // the cloud calls it BABYWEAR
    expect_eq(course_of(time_dry()), "timed_dry");
    expect_eq(course_of(app_shrinkage_relief()), "shrinkage_relief");
}

// a downloaded cycle is a sentinel course plus its own identifier
fn test_a_downloaded_cycle() {
    expect_props(fed([downloaded_cycle()]), #{ course: "downloaded_cycle", download_course: "wrinkle_prevention" });
    expect_eq(fed([towels()]).property("download_course"), "none");
}

// the AI dial position is read from rec[5], not the loaded-cycle byte
fn test_the_ai_position() { expect_eq(course_of(ai_course()), "ai_dry"); }

// the minute counters are big-endian, unlike the matching washer
fn test_big_endian_minutes() {
    expect_eq(fed([tub_clean()]).property("remaining_time"), "160");
    expect_props(fed([drying()]), #{ remaining_time: "193", initial_time: "195", energy: "3" });
}

// dry level and eco hybrid each read from their own byte
fn test_dry_level_and_eco_hybrid() {
    expect_props(fed([dry_level_very()]), #{ dry_level: "very_dry", eco_hybrid: "normal" });
    expect_props(fed([eco_hybrid_eco()]), #{ eco_hybrid: "eco", dry_level: "iron" });
    // a course that does not sense dryness reports the 0 sentinel
    expect_props(fed([tub_clean()]), #{ eco_hybrid: "turbo", dry_level: "none" });
}

// the buzzer volume is cloud-confirmed on this model
fn test_the_buzzer() {
    expect_eq(fed([buzzer_off()]).property("buzzer"), "off");
    expect_eq(fed([tub_clean()]).property("buzzer"), "4");
}

// wrinkle care, the drum light and the damp dry signal share rec[24] without collision
fn test_the_first_options_byte() {
    expect_props(fed([wrinkle_care_on()]), #{ wrinkle_care: "true", damp_dry_signal: "false", drum_light: "false" });
    expect_props(fed([damp_dry_signal_on()]), #{ damp_dry_signal: "true", wrinkle_care: "false", drum_light: "false" });
}

// cycle optimization is the low bit of the byte remote maintain sits in
fn test_cycle_optimization() {
    expect_props(fed([cycle_optimization_off()]), #{ cycle_optimization: "false", remote_maintain: "false" });
    expect_props(fed([cycle_optimization_on()]), #{ cycle_optimization: "true", remote_maintain: "false" });
    expect_props(fed([drying()]), #{ cycle_optimization: "true", remote_maintain: "false" });
}

// remote start is the setting, which the appliance switches on at every cycle start
fn test_remote_start_turns_itself_on() {
    expect_props(fed([remote_start_switched_off()]), #{ remote_start: "false", status: "initial", detect_load: "true" });
    expect_props(fed([remote_start_switched_off(), hand_started_with_remote_off()]),
                 #{ status: "detecting", remote_start: "true", course: "normal" });
}

// remote start and detect load share rec[26]
fn test_remote_start_and_detect_load() {
    expect_props(fed([remote_start_on()]), #{ remote_start: "true", detect_load: "true" });
    expect_props(fed([towels()]), #{ detect_load: "true", remote_start: "false" });
    expect_eq(fed([tub_clean()]).property("detect_load"), "false"); // Tub Clean weighs no load
}

// the condenser clean flag tracks the state that names it
fn test_condenser_clean() {
    expect_props(fed([condenser_clean()]), #{ status: "condenser_clean", condenser_clean: "true", remote_start: "true" });
    expect_props(fed([condenser_clean(), cooling()]), #{ status: "cooling", condenser_clean: "false", remote_start: "true" });
    expect_eq(fed([tub_clean()]).property("condenser_clean"), "false");
    expect_props(fed([condenser_clean_cloud()]), #{ status: "condenser_clean", condenser_clean: "true" });
}

// a remote-started cycle ends into the remote-maintain state, not plain End
fn test_the_remote_maintain_end() {
    // energy: what the whole 195-minute Bedding cycle used
    expect_props(fed([cooling(), end_remote_maintain()]), #{ status: "end_remote_maintain_on", power: "true",
        remaining_time: "1", energy: "1818", drum_light: "true" });
}

// remote maintain is rec[27] bit 0x02, not part of either options byte
fn test_remote_maintain() {
    expect_props(fed([remote_maintain_on()]), #{ status: "drying", remote_maintain: "true" });
    expect_props(fed([remote_maintain_off()]), #{ status: "off", remote_maintain: "false" });
    expect_eq(fed([tub_clean()]).property("remote_maintain"), "false");
}

// pausing lights the drum and keeps the state it came from
fn test_pausing() {
    expect_props(fed([pauses()]), #{ status: "paused", drum_light: "true", remaining_time: "191", power: "true" });
    expect_props(fed([pauses(), drying()]), #{ status: "drying", drum_light: "false" });
}

// powering off clears the cycle but not the energy it used
fn test_power_off_keeps_the_energy() {
    expect_props(fed([pauses(), powers_off()]), #{ power: "false", status: "off", course: "none",
        remaining_time: "0", initial_time: "0", energy: "10" });
}

// start() requests a status snapshot, so a reconnect does not leave HA blank
fn test_start_asks_for_the_status() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 1);
    expect_eq(hex_encode(d.sent()[0]), "aa12f0ed1121010000001804111200005ebb");
}

// frames that are not status records publish nothing
fn test_other_frames_publish_nothing() {
    for junk in ["aa0730d82b91bb", "aa09307200c80048bb", "aaff300a0066004f45000100ec0054000302000207",
                 "aaff200a00a2001002000100ec00900aff000e000000000000000000000100000001002e0001006400000e2004ffff2d3c000000400004300000000000000400004000000000000000f00064000400000000ffff0100000a03090e0f2e00000000000000002700270000002e0101006400000e2004ffff2d3c200000420004300000000000000400004000000000000000f00064000400000000ffff01000049b8bb"] {
        expect_eq(fed([junk]).property("available"), (), junk);
    }
}
