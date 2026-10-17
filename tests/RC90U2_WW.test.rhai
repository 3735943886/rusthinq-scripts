import "runtime_test" as runtime;

// Tests of RC90U2_WW (dryer_rc90_common), ported from upstream rethink's test suite (commit
// 0e57069; live captures from an RC9DN9029 driven from the panel). Expected values are what
// upstream's driver publishes, in IL names; what upstream clears ("None": course fields while off,
// the phase outside a cycle, dry level 0) reads "none".

fn eb_ready_cotton() { "aa2130eb001901021e00000700030102000000000804000000000000006b00f1bb" }
fn power_off() { "AA3C30EC001901021E00000700030102000000000804000000000000006B00001900000000000000000000000000000804000000010000006B0004BB" }
fn power_on_no_course() { "AA3C30EC001900000000000000000000000000000804000000010000006B00001901000000000000000000000000000804000000000000006B0071BB" }
fn course_mixed() { "AA3C30EC001901021E00000700030102000000000804000000000000006B00001901010A00000600030302000000000804000000000000006B003FBB" }
fn course_duvet() { "AA3C30EC001901010A00000600030302000000000804000000000000006B00001901023700000400000302000000000804000000000000006B002ABB" }
fn delay_end_on() { "AA3C30EC001901021E00000700030102000000000804000000000000006B00001901021E00000700030102030003000904000000000000006B00D0BB" }
fn dry_level_iron() { "AA3C30EC001901021E00000700030102000000000804000000000000006B00001901011E00000700010302000000000804000000000000006B0028BB" }
fn course_allergy_care() { "AA3C30EC001901023700000400000302000000000004000000000000006B00001901030000001000000302000000000004000000000000006B003BBB" }
fn course_downloaded_deodorization() { "AA3C30EC001901001E00000900000302000000000004000000000000006B00001901002700000100000304000000000004000000006B00006B008FBB" }
fn course_cool_air() { "AA3C30EC001901010F00000E00000102000000000004000000000000006B00001901010000000D00000005000000000004000000000000006B001DBB" }
fn start_cool_air() { "AA3C30EC001901001E00000D00000005000000000004000000000000006B00001902001E001E0D00000005000000000005000000010000006B00C0BB" }
fn start_event() { "AA09307200C9004BBB" }
fn serial_frame() { "AA3730310201534141333939333530303900007FD200008000000000000253414133393933343931320000A36700004000000000000FBB" }
fn power_event() { "AA07301900AFBB" }


fn fed(frames) { let d = device(); for f in frames { d.feed(f); } d }

// start() asks for a status snapshot with the family-wide F0ED request
fn test_start_asks_for_the_status() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 1);
    expect_eq(hex_encode(d.sent()[0]), "aa0ef0ed1121010000001800b5bb");
}

// 0xEB reply decodes Ready / Cotton / Cupboard / Eco / 2:30
fn test_the_eb_reply() {
    // the phase byte is stale while idle
    expect_props(fed([eb_ready_cotton()]), #{ power: "true", status: "ready", phase: "none", course: "cotton",
        dry_level: "cupboard", eco_hybrid: "eco", remaining_time: "150", initial_time: "0", reserve_time: "0",
        error: "false", error_message: "OK", delay: "false", anti_crease: "false", child_lock: "false",
        damp_dry_beep: "false", hand_iron: "false" });
}

// 0xEC frames use the second (current) record: power off clears the course fields
fn test_power_off_clears_the_course_fields() {
    expect_props(fed([power_off()]), #{ power: "false", status: "off", course: "none", dry_level: "none",
        eco_hybrid: "none", remaining_time: "0" });
}

// power on without a course reads Ready with unknown course
fn test_power_on_without_a_course() {
    expect_props(fed([power_on_no_course()]), #{ power: "true", status: "ready", course: "none", remaining_time: "0" });
}

// course knob: Mixed Fabric and Duvet with their defaults
fn test_the_course_knob() {
    let d = fed([course_mixed()]);
    expect_props(d, #{ course: "mixed_fabric", dry_level: "cupboard", eco_hybrid: "time", remaining_time: "70" });
    d.feed(course_duvet()); // a timed course: no dry level
    expect_props(d, #{ course: "duvet", dry_level: "none", eco_hybrid: "time", remaining_time: "175" });
}

// timed courses, a downloaded course and Cool Air decode from the knob sweep
fn test_timed_downloaded_and_cool_air_courses() {
    let d = fed([course_allergy_care()]);
    expect_props(d, #{ course: "allergy_care", dry_level: "none", eco_hybrid: "time", remaining_time: "180" });
    d.feed(course_downloaded_deodorization()); // the downloaded course overrides base course 0x01
    expect_props(d, #{ course: "deodorization", remaining_time: "39" });
    d.feed(course_cool_air());
    expect_props(d, #{ course: "cool_air", eco_hybrid: "none", phase: "none", remaining_time: "60" });
}

// Delay End sets the reserve time and the Reservation option bit
fn test_delay_end() {
    // the always-on bit 0x08 leaks into no option
    expect_props(fed([delay_end_on()]), #{ delay: "true", reserve_time: "180", course: "cotton",
        anti_crease: "false", child_lock: "false" });
}

// dry level button: Cupboard -> Iron changes the estimate
fn test_the_dry_level_button() {
    expect_props(fed([dry_level_iron()]), #{ dry_level: "iron", eco_hybrid: "time", remaining_time: "90" });
}

// Start on Cool Air: Running with the cooling phase and the full time left
fn test_starting_cool_air() {
    expect_props(fed([start_cool_air()]), #{ power: "true", status: "running", phase: "cooling",
        course: "cool_air", dry_level: "none", eco_hybrid: "none", remaining_time: "30", initial_time: "30",
        delay: "false", error: "false" });
}

// serial, power-event and start-event frames are ignored
fn test_serial_and_event_frames_are_ignored() {
    expect_eq(fed([serial_frame(), power_event(), start_event()]).property("available"), ());
}

// a 0xEC frame with a wrong length is rejected
fn test_a_wrong_length_is_rejected() {
    expect_eq(fed(["aa0830ec0019010000bb"]).property("available"), ());
}

fn test_every_property_is_read_only() {
    let d = device();
    d.start();
    d.set("power", "false");
    expect_eq(d.sent().len(), 1);
    expect(d.event("reject") != (), "reject");
}
