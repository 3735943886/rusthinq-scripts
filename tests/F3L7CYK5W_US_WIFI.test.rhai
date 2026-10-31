import "runtime_test" as runtime;

// Tests of F3L7CYK5W_US_WIFI (washer_f3l_common), ported from upstream rethink's test suite
// (commit 0e57069; live captures correlated against the LG cloud's decoded state). Expected values
// are what upstream's driver publishes, in IL names; a code upstream leaves unknown ("None") is a
// no-selection or not-applicable code, published here as "none".

fn dial_speed_wash() { "aa3a20ec001805010101010a0003050403000000000000000000332e0000001805000f000f0b0001050601000000000000000000332e000713bb" }
fn dial_downloaded() { "aa3a20ec001805000f000f0b0001050601000000000000000000332e0007001805002d002d0c0003050402000000000000000000332e0f00f9bb" }
fn dial_tub_clean() { "aa3a20ec001805002d002d0c0003050402000000000000000000332e0f00001805011d011d010000030002000000040000000000332e0000e0bb" }
fn dial_normal() { "aa3a20ec00180502150215050005050402000000000000000000332e000000180501030103060003040402000000000000000000332e00001fbb" }
fn cold_wash_on() { "aa3a20ec00180501210121060003030702000000000000000000332e000000180501170117060003030202000000001000000000332e0000c0bb" }
fn extra_rinse_2() { "aa3a20ec001805010e010e060003030412000000400000000000332e000000180501190119060003030422000000400000000000332e000047bb" }
fn child_lock_on() { "aa3a20ec00180501030103060003040402000000000000000000332e000000180501030103060003040402000000010000000000332e000076bb" }
fn steam_on() { "aa3a20ec00180501030103060003040402000000000000000000332e0000001805021c021c060000040002000000040000000000332e000006bb" }
fn pre_wash_on() { "aa3a20ec00180501030103060003040402000000000000000000332e000000180501120112060003040402000000080000000000332e00001dbb" }
fn delay_2h() { "aa3a20ec00180501030103060003040402000000000000000000332e000000180501030103060003040402000200020000000000332e000073bb" }
fn rinse_spin_on() { "aa3a20ec00180501000100040003030402000000000000000100332e0007001805000c000c040000030001000000200000000100332e00071bbb" }
fn rinsing() { "aa3a20ec001805000c000c040000030001000000200000000100332e000700181e000c000c040000030001000000208000000105332e00074fbb" }
fn add_garments() { "aa3a20ec00181e000c000c040000030001000000208002000005332e0007001815000c000c04000003000100000020001200001e332e00070fbb" }
fn paused() { "aa3a20ec001815000c000c04000003000100000020001200001e332e0007001806000c000c040000030001000000200010000015332e0007b5bb" }
fn run_complete() { "aa3a20ec0018280001000c040000030000000000208002000e1e332e000700183c00010000fe0000000000000000000000000e28332e000031bb" }
fn eb_off() { "aa2020eb00180000010000fe0000000000000000000000000005332b00001abb" }
fn selecting() { "aa3a20ec00180000010000fe0000000000000000000000000005332b000000180501030103060003040402000000008000000000332b0000d5bb" }
fn sensing() { "aa3a20ec00180501030103060003040402000000008000000000332b000000181401030103060003040402000000008000000005332b000065bb" }
fn door_closes() { "aa3a20ec00181401030103060003040402000000008000000005332b000000181401030103060003040402000000008002000005332b000013bb" }
fn washing_start() { "aa3a20ec00181401030103060003040402000000008002000005332b000000181701140114060003040402000000008002000014332b0004d5bb" }
fn washing_minute_later() { "aa3a20ec00181701140114060003040402000000008002000014332b000400181701130114060003040402000000008002000114332b0004edbb" }
fn washing_to_rinsing() { "aa3a20ec001817003a0114060003040402000000008002002414332b000400181e00390114060000040402000000008002002617332b000407bb" }
fn spinning() { "aa3a20ec00181e00150114060000040401000000008002003f17332b00040018280014011406000004000000000000800200411e332b00041abb" }
fn cycle_complete() { "aa3a20ec0018280001011406000004000000000000800200671e332b000400183c00010000fe0000000000000000000000006c28332c0000aabb" }
fn off() { "aa3a20ec00183c00010000fe0000000000000000000000006c28332c000000180000010000fe0000000000000000000000006c3c332c000001bb" }
fn second_run_washing() { "aa3a20ec00181401030103060003040402000000008002000005332d0000001817003a003a060003040402000000008002000014332d000398bb" }
fn e2_stale_replay() { "aa2020e203181401030103060003040402000000008000006c05332b000030bb" }

fn fed(frames) { let d = device(); for f in frames { d.feed(f); } d }

// 0xEB single-record frames decode with the same offsets as 0xEC
fn test_a_single_record_frame() {
    // 0xFE is the no-selection sentinel
    expect_props(fed([eb_off()]), #{ power: "false", status: "off", course: "none", remaining_time: "0",
                                     tub_clean_count: "43" });
}

// the course table is this model's own, not the sibling's
fn test_the_course_table_is_this_models_own() {
    expect_eq(fed([dial_normal()]).property("course"), "normal"); // the sibling says heavy duty
    expect_eq(fed([dial_speed_wash()]).property("course"), "speed_wash");
    expect_eq(fed([dial_downloaded()]).property("course"), "downloaded");
    expect_eq(fed([dial_tub_clean()]).property("course"), "tub_clean");
}

// while selecting, remaining and initial time agree
fn test_while_selecting_the_times_agree() {
    expect_props(fed([selecting()]), #{ power: "true", status: "standby", course: "normal", soil: "normal",
        spin: "high", temp: "warm", remaining_time: "63", initial_time: "63" });
}

// Sensing is a real distinct phase on this model
fn test_sensing_is_a_phase() {
    expect_props(fed([selecting(), sensing()]), #{ status: "detecting", remaining_time: "63" });
}

// rec[11] packs rinse count and extra-rinse count in separate nibbles
fn test_rinses_and_extra_rinses_share_a_byte() {
    expect_props(fed([dial_normal()]), #{ rinse_count: "2", extra_rinse_count: "0", extra_rinse: "false" });
    expect_props(fed([extra_rinse_2()]), #{ extra_rinse: "true", extra_rinse_count: "2", rinse_count: "2" });
}

// the rec[15] option bits each isolate cleanly
fn test_the_option_bits() {
    expect_props(fed([child_lock_on()]), #{ child_lock: "true", steam: "false", pre_wash: "false", delay_wash: "false" });
    expect_eq(fed([steam_on()]).property("steam"), "true");
    expect_eq(fed([pre_wash_on()]).property("pre_wash"), "true");
    expect_props(fed([rinse_spin_on()]), #{ rinse_spin: "true", child_lock: "false", extra_rinse: "false" });
}

// cold wash sits in the other bitfield and forces the temperature index
fn test_cold_wash() {
    expect_props(fed([cold_wash_on()]), #{ cold_wash: "true", temp: "cold", child_lock: "false" });
}

// delay wash exposes its reserve clock
fn test_delay_wash() {
    expect_props(fed([delay_2h()]), #{ delay_wash: "true", reserve_time: "120" });
}

// door position is never published: rec[17] is the latch, not a door sensor
fn test_no_door_position_is_published() {
    let open = fed([sensing()]);
    expect_eq(open.property("door"), ());
    expect_eq(open.property("door_lock"), "true");
    let shut = fed([sensing(), door_closes()]); // rec[17] changes between these
    expect_eq(shut.property("door"), ());
    expect_eq(shut.property("door_lock"), "true");
    expect(!runtime::descriptor({ let d = device(); d.start(); d }).props.contains("door"), "no door");
}

// initial time pins when the cycle starts while remaining time counts down
fn test_the_initial_time_pins_at_the_start() {
    expect_props(fed([sensing(), washing_start()]), #{ status: "washing", remaining_time: "80", initial_time: "80" });
    expect_props(fed([sensing(), washing_start(), washing_minute_later()]), #{ remaining_time: "79", initial_time: "80" });
    // the pinned value is per run, not a constant
    expect_props(fed([second_run_washing()]), #{ remaining_time: "58", initial_time: "58" });
}

// Add Garments unlocks the door mid-cycle and Pause follows it
fn test_add_garments_unlocks_the_door() {
    expect_props(fed([rinse_spin_on(), rinsing()]), #{ status: "rinsing", door_lock: "true", load_level: "7" });
    expect_props(fed([rinse_spin_on(), rinsing(), add_garments()]), #{ status: "filling", door_lock: "false" });
    expect_props(fed([rinse_spin_on(), rinsing(), add_garments(), paused()]), #{ status: "paused", door_lock: "false" });
}

// a real run: Washing -> Rinsing -> Spinning, settings drop out as they stop applying
fn test_settings_drop_out_as_they_stop_applying() {
    // soil goes to 0 once washing ends, temperature once spinning starts
    expect_props(fed([washing_start(), washing_to_rinsing()]), #{ status: "rinsing", soil: "none", temp: "warm", initial_time: "80" });
    expect_props(fed([washing_start(), washing_to_rinsing(), spinning()]), #{ status: "spinning", temp: "none", door_lock: "true" });
}

// completing a cycle unlocks the door and increments the tub-clean counter
fn test_completing_a_cycle() {
    expect_eq(fed([washing_start(), spinning()]).property("tub_clean_count"), "43");
    // still powered on; no stale minute of remaining time
    expect_props(fed([washing_start(), spinning(), cycle_complete()]), #{ status: "end", power: "true",
        tub_clean_count: "44", door_lock: "false", remaining_time: "0", initial_time: "0" });
}

// the Rinse+Spin run also lands on Complete
fn test_a_rinse_spin_run_completes() {
    expect_props(fed([rinsing(), run_complete()]), #{ status: "end", course: "none", tub_clean_count: "46" });
}

// powering off clears the selection
fn test_power_off_clears_the_selection() {
    expect_props(fed([washing_start(), spinning(), cycle_complete(), off()]), #{ status: "off", power: "false",
        course: "none", remaining_time: "0" });
}

// 0xE2 post-cycle replay frames are ignored, not treated as status
fn test_post_cycle_replays_are_ignored() {
    expect_props(fed([washing_start(), spinning(), cycle_complete(), e2_stale_replay()]),
                 #{ status: "end", tub_clean_count: "44", remaining_time: "0" });
}

// start() requests a status snapshot, so a reconnect does not leave HA blank
fn test_start_asks_for_the_status() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 1);
    expect_eq(hex_encode(d.sent()[0]), "aa0ef0ed1121010000001800b5bb");
}

// frames that are not status frames publish nothing
fn test_other_frames_publish_nothing() {
    for junk in ["aa0720d800fcbb", "aa09207200c9005bbb", "aa0a20ec001805010cbb"] {
        let d = device();
        d.feed(junk);
        expect_eq(d.property("available"), (), junk);
    }
}
