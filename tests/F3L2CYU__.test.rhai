import "runtime_test" as runtime;

// Tests of F3L2CYU__ (washer_f3l_common), ported from upstream rethink's test suite (commit
// 0e57069; live captures correlated against the LG cloud's decoded state). Expected values are
// what upstream's driver publishes, in IL names; a code upstream leaves unknown ("None") is a
// no-selection or not-applicable code, published here as "none". door is true while open.

fn eb_reconnect_idle() { "aa2020eb001805000000000000000000000000000000000000003318000068bb" }
fn normal_idle() { "aa3a20ec0018050000000000000000000000000000000000000033170000001805002e002e07000304040100000080000000000033170000f8bb" }
fn course_towels() { "aa3a20ec001805002900290a000303020200000000000000000033170007001805010101010b0003050403000000000000000000331700001cbb" }
fn course_speedwash() { "aa3a20ec001805010101010b000305040300000000000000000033170000001805000f000f0c0001050601000000000000000000331700074fbb" }
fn course_rinse_spin() { "aa3a20ec001805000f000f0c000105060100000000000000000033170007001805000b000b0d0000040000000000000000000000331700077fbb" }
fn course_small_load() { "aa3a20ec001805000b000b0d000004000000000000000000000033170007001805002d002d0e000304040200000000000000000033170f0025bb" }
fn course_tub_clean() { "aa3a20ec001805002d002d0e000304040200000000000000000033170f00001805011d011d01000003000200000004000000000033170000ddbb" }
fn soil_normal_heavy() { "aa3a20ec001805002e002e070003040401000000800000000000331700000018050033003307000404040100000080000000010033170000fdbb" }
fn spin_extra_high() { "aa3a20ec001805002e002e07000304040100000080000000010033170000001805003a003a07000305040100000080000000010033170000e2bb" }
fn temp_hot() { "aa3a20ec001805002e002e07000304040100000080000000010033170000001805002e002e07000304060100000080000000010033170000f5bb" }
fn cold_wash_on() { "aa3a20ec001805002e002e0700030404010000008000000001003317000000180501060106070003040201000000801000000100331700000bbb" }
fn extra_rinse_on_1() { "aa3a20ec001805002e002e0700030404010000008000000001003317000000180500330033070003040411000000c0000000010033170000adbb" }
fn pre_wash_on() { "aa3a20ec001805002e002e0700030404010000008000000001003317000000180501010101070003040401000000880000000100331700001bbb" }
fn steam_on() { "aa3a20ec001805002e002e07000304040100000080000000010033170000001805020b020b070000040001000000840000000100331700000cbb" }
fn selecting_to_washing() { "aa3a20ec001805000f000f0c000105060100000000800200020033170007001817000f000f0c00010506010000000080020000053317000702bb" }
fn washing() { "aa3a20ec001817000f000f0c000105060100000000800200000533170007001817000e000f0c0001050601000000008002000005331700073ebb" }
fn rinsing() { "aa3a20ec001817000d000f0c00010506010000000080020012053317000700181e000c000f0c000005060100000000800200231733170007e1bb" }
fn rinsing_locked_closed() { "aa3a20ec00181e000c000f0c00000506010000000080020023173317000700181e000b000f0c00000506010000000080020024173317000789bb" }
fn spinning() { "aa3a20ec00181e000a000f0c0000050601000000008002002506331700070018280009000f0c000005000000000000800200261e3317000780bb" }
fn complete() { "aa3a20ec0018280001000f0c000005000000000000800200391e3317000700183c00010000fe000000000000000000000000402833180000d4bb" }
fn pause_unlocks() { "aa3a20ec00181e000b000f0c000005060100000000800200241733170007001806000b000f0c000005060100000000000200251e3317000719bb" }
fn door_opens_while_paused() { "aa3a20ec001806000b000f0c000005060100000000000200251e33170007001806000b000f0c000005060100000000000000251e33170007efbb" }
fn resume_relocks() { "aa3a20ec00181e000b000f0c000005060100000000000000251e3317000700181e000b000f0c0000050601000000008000002506331700076dbb" }
fn door_closes_again() { "aa3a20ec00181e000b000f0c00000506010000000080000025063317000700181e000b000f0c000005060100000000800200250633170007efbb" }
fn delay_1h_armed_still_selecting() { "aa3a20ec001805000f000f0c000105060100000000000000400033180007001805000f000f0c000105060100010002000000400033180007eabb" }
fn turbo_on_still_selecting() { "aa3a20ec001805000f000f0c000105060100010002000000400033180007001805000f000f0c00010506010001008200000040003318000717bb" }
fn delay_pending_locks_door() { "aa3a20ec001805000f000f0c00010506010001008200000040003318000700180a000f000f0c00010506010001008280000040053318000719bb" }
fn delay_door_closes() { "aa3a20ec00180a000f000f0c00010506010001008280000040053318000700180a000f000f0c000105060100010082800200000533180007cdbb" }
fn app_pause() { "aa3a20ec00180a000f000f0c000105060100003a82800200000533180007001806000f000f0c000105060100003a82800200000a3318000798bb" }
fn app_resume_3h() { "aa3a20ec001806000f000f0c000105060100003a82800200000a3318000700180a000f000f0c000105060100030082800200000633180007c2bb" }
fn reserve_ticks() { "aa3a20ec00180a000f000f0c00010506010003008280020000063318000700180a000f000f0c000105060100023b82800200000633180007cfbb" }
fn app_poweroff() { "aa3a20ec00180a000f000f0c000105060100023a8280020000063318000700180000010000fe000000000000000000000200000a331800001abb" }

fn fed(frames) { let d = device(); for f in frames { d.feed(f); } d }

// 0xEB single-record frames decode with the same offsets as 0xEC, seen right after reconnect
fn test_a_single_record_frame_after_reconnect() {
    expect_props(fed([eb_reconnect_idle()]), #{ power: "true", status: "selecting", course: "none", door: "true" });
}

// idle, Selecting on Normal: course/soil/spin/temp settle to their defaults
fn test_selecting_normal_settles_to_its_defaults() {
    // TurboWash is forced on for Normal; this capture was taken with the door open
    expect_props(fed([normal_idle()]), #{ power: "true", status: "selecting", course: "normal",
        remaining_time: "46", soil: "normal", spin: "high", temp: "warm", turbo_wash: "true",
        door: "true", door_lock: "false" });
}

// the course/dial-position byte (offset 6) identifies each program
fn test_the_course_byte_identifies_each_program() {
    let d = device();
    for pair in [[course_towels(), "towels"], [course_speedwash(), "speed_wash"],
                 [course_rinse_spin(), "rinse_spin"], [course_small_load(), "small_load"],
                 [course_tub_clean(), "tub_clean"]] {
        d.feed(pair[0]);
        expect_eq(d.property("course"), pair[1]);
    }
}

// single-variable settings toggles decode soil/spin/temp/cold-wash/extra-rinse/pre-wash/steam
fn test_single_settings_toggles() {
    let d = device();
    d.feed(soil_normal_heavy()); expect_eq(d.property("soil"), "normal_heavy");
    d.feed(spin_extra_high()); expect_eq(d.property("spin"), "extra_high");
    d.feed(temp_hot()); expect_eq(d.property("temp"), "hot");
    d.feed(cold_wash_on()); expect_props(d, #{ cold_wash: "true", temp: "cold" }); // forces the temp too
    d.feed(extra_rinse_on_1()); expect_props(d, #{ extra_rinse: "true", extra_rinse_count: "1" });
    d.feed(pre_wash_on()); expect_eq(d.property("pre_wash"), "true");
    d.feed(steam_on()); expect_eq(d.property("steam"), "true");
}

// a full Speed Wash run: remote start, phase transitions, and the remaining-time countdown
fn test_a_speed_wash_run() {
    let d = device();
    d.feed(selecting_to_washing()); expect_props(d, #{ status: "washing", remaining_time: "15" });
    d.feed(washing()); expect_props(d, #{ status: "washing", remaining_time: "14" });
    d.feed(rinsing()); expect_props(d, #{ status: "rinsing", remaining_time: "12" });
    d.feed(spinning()); expect_props(d, #{ status: "spinning", remaining_time: "9" });
    // the Complete frame's course byte is 0xFE, the no-selection sentinel
    d.feed(complete()); expect_props(d, #{ status: "complete", course: "none" });
}

// pause unlocks the door, opening/closing the door is independent of the lock, and resume relocks
fn test_the_door_and_its_lock_are_independent() {
    let d = device();
    d.feed(rinsing_locked_closed()); expect_props(d, #{ door_lock: "true", door: "false" });
    d.feed(pause_unlocks()); expect_props(d, #{ status: "paused", door_lock: "false", door: "false" });
    d.feed(door_opens_while_paused()); expect_props(d, #{ door: "true", door_lock: "false" });
    d.feed(resume_relocks()); expect_props(d, #{ status: "rinsing", door_lock: "true" });
    d.feed(door_closes_again()); expect_props(d, #{ door: "false", door_lock: "true" });
}

// Delay Wash: arming, Turbo Wash, the Delay-pending phase, reserve-time countdown, remote
// pause/resume, and remote power-off
fn test_delay_wash() {
    let d = device();
    d.feed(delay_1h_armed_still_selecting());
    expect_props(d, #{ status: "selecting", delay_wash: "true", reserve_time: "60" });
    d.feed(turbo_on_still_selecting()); expect_eq(d.property("turbo_wash"), "true");
    // the door locks as soon as the delay is armed
    d.feed(delay_pending_locks_door()); expect_props(d, #{ status: "delay_wash", door_lock: "true" });
    d.feed(delay_door_closes()); expect_eq(d.property("door"), "false");
    d.feed(app_pause()); expect_eq(d.property("status"), "paused");
    d.feed(app_resume_3h()); expect_props(d, #{ status: "delay_wash", reserve_time: "180" });
    d.feed(reserve_ticks()); expect_eq(d.property("reserve_time"), "179"); // 3:00 -> 2:59
    d.feed(app_poweroff());
    expect_props(d, #{ power: "false", status: "off", remaining_time: "0", reserve_time: "0", course: "none" });
}

// unknown frame type and non-envelope frames are ignored
fn test_other_frames_are_ignored() {
    let d = fed([normal_idle()]);
    for junk in ["aa0720d81795bb", "aa09207200000010bb", "001122"] { d.feed(junk); }
    expect_eq(d.property("status"), "selecting");
}

fn test_every_property_is_read_only() {
    let d = device();
    d.start();
    d.set("power", "false");
    expect_eq(d.sent().len(), 0);
    expect(d.event("reject") != (), "reject");
    expect(runtime::descriptor(d).props.status.options.contains("running"), "unmapped phases read as running");
}
