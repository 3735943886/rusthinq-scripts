import "runtime_test" as runtime;

// Tests of RV13B6BSD_D_US_WIFI (dryer_rv13_common), ported from upstream rethink's test suite
// (commit 0e57069; live captures correlated against the LG cloud's decoded state). Expected values
// are what upstream's driver publishes, in IL names; the course, dry level and temperature codes
// upstream leaves unknown are its documented "not selected" codes, published as "none".

fn eb_idle() { "aa2330eb001b0000010001000000000004000000402800065f04000000640000006bbb" }
fn off_to_initial() { "aa4030ec001b0000010001000000000004000000402800065f0400000064000000001b0100010001000000000004000000402800000000000000640000001fbb" }
fn course_normal() { "aa4030ec001b010001000100000000000400000000280000000000000064000000001b010029002903000304000400000000280000000000000064000000e9bb" }
fn course_bedding() { "aa4030ec001b010039003903000304000400000000aa0000000000000064000000001b010037003707000303000400000000a8000000000000006400000002bb" }
fn course_small_load() { "aa4030ec001b010037003707000303000400000000a80000000000000064000000001b01001e001e09000305000400000000a8000000000000006400000073bb" }
fn small_load_starts_drying() { "aa4030ec001b01001e001e09000305000400000000a80000000000000064000000001b32001e001e09000305000400000000a800000001000000640000007fbb" }
fn pause_then_antibacterial_selected() { "aa4030ec001b03001e001e09000305000400000040a80000063200000064000000001b01010a010a08000505000400000040a80000060300000064000000c3bb" }
fn heavy_duty_then_normal_energy_saver_on() { "aa4030ec001b010036003601000305000400000040a80000060300000064000000001b010039003903000304000400000040aa0000060300000064000000b6bb" }
fn starts_drying() { "aa4030ec001b010039003903000304000400000040aa0000060300000064000000001b320039003903000304000400000000aa000000010000006400000080bb" }
fn remaining_ticks_down() { "aa4030ec001b320039003903000304000400000000aa0000000100000064000000001b320038003903000304000400000000aa000004010000006400000094bb" }
fn drying_to_cooling() { "aa4030ec001b320038003903000304000400000000aa0000040100000064000000001b330001000203000304000400000000aa0000063200000064000000dfbb" }
fn cooling_to_off_blip() { "aa4030ec001b330001000303000304000400000000aa0000083200000064000000001b000001000303000304000400000000aa00000a330000006400000073bb" }
fn off_blip_to_end() { "aa4030ec001b000001000303000304000400000000aa00000a3300000064000000001b040001000303000304000400000040aa00000a000000006400000052bb" }
fn end_to_final_off() { "aa4030ec001b040001000303000304000400000040aa00000a0000000064000000001b000001000100000000000400000040a800000a04000000640000005fbb" }
fn bedding_then_heavy_duty_turbo_steam_on() { "aa4030ec001b010037003707000303000400000000a80000000000000064000000001b010036003601000305000400000000ac000000000000006400000007bb" }
fn heavy_duty_drying_turbo_steam_on() { "aa4030ec001b010036003601000305000400000000ac0000000000000064000000001b320036003601000305000400000000ac0000000100000064000000d7bb" }
fn damp_dry_signal_on() { "aa4030ec001b010036003601000305000400000040280000430300000064000000001b01003600360100030500040000004828000043030000006400000009bb" }
fn damp_dry_signal_off_normal_selected() { "aa4030ec001b030036003601000305000400000048280000113200000064000000001b01002900290300030400040000004028000011030000006400000045bb" }
fn child_lock_on() { "aa4030ec001b03010a010a080005050004000000402800000e3200000064000000001b03010a010a080005050004000000412800000e3200000064000000e6bb" }
fn app_start_command() { "aa1bf0260300000400000000410003000000000300d700000055bb" }
fn remote_starts_drying() { "aa4030ec001b010029002903000304000400000040290000240000000064000000001b3200010001030003040004d700000029000000010000006400000060bb" }
fn app_poweroff_command() { "aa09f0240101009cbb" }
fn remote_poweroff() { "aa4030ec001b3201070108030003040004d70000002900006c0100000064000000001b0001070107000000000004000000402800009932000000640000005cbb" }

// 0xEB single-record frames decode with the same offsets as 0xEC, seen right after reconnect
fn test_a_single_record_frame_after_reconnect() {
    let d = device();
    d.feed(eb_idle());
    expect_props(d, #{ power: "false", status: "off", course: "none" });
}

// Off -> Initial as dial-browsing begins
fn test_off_to_initial() {
    let d = device();
    d.feed(off_to_initial());
    expect_props(d, #{ power: "true", status: "initial" });
}

// the course byte (offset 6) identifies each program, and Initial -> Drying on Start
fn test_the_course_byte_and_starting() {
    let d = device();
    d.feed(course_normal()); expect_props(d, #{ course: "normal", dry_level: "normal", temp: "mid_high" });
    d.feed(course_bedding()); expect_props(d, #{ course: "bedding", temp: "medium" });
    d.feed(course_small_load()); expect_props(d, #{ course: "small_load", temp: "high" });
    d.feed(small_load_starts_drying()); expect_props(d, #{ status: "drying", course: "small_load" });
}

// pause, then re-selecting Antibacterial shows Dry level Very and Temp High
fn test_antibacterial_after_pause() {
    let d = device();
    d.feed(pause_then_antibacterial_selected());
    expect_props(d, #{ status: "initial", course: "antibacterial", dry_level: "very", temp: "high" });
}

// Energy Saver and Turbo Steam toggle independently of course selection
fn test_energy_saver_and_turbo_steam() {
    let d = device();
    d.feed(heavy_duty_then_normal_energy_saver_on()); expect_props(d, #{ course: "normal", energy_saver: "true" });
    d.feed(bedding_then_heavy_duty_turbo_steam_on()); expect_props(d, #{ course: "heavy_duty", turbo_steam: "true" });
    d.feed(heavy_duty_drying_turbo_steam_on()); expect_props(d, #{ status: "drying", turbo_steam: "true" });
}

// Damp Dry Signal toggles on and off
fn test_damp_dry_signal() {
    let d = device();
    d.feed(damp_dry_signal_on()); expect_eq(d.property("damp_dry_signal"), "true");
    d.feed(damp_dry_signal_off_normal_selected()); expect_props(d, #{ course: "normal", damp_dry_signal: "false" });
}

// Child Lock engages
fn test_child_lock() {
    let d = device();
    d.feed(child_lock_on());
    expect_eq(d.property("child_lock"), "true");
}

// a full run: Drying with a genuine separate initial-time estimate, Cooling, End, and final Off
fn test_a_full_run() {
    let d = device();
    d.feed(starts_drying()); expect_props(d, #{ status: "drying", remaining_time: "57", initial_time: "57" });
    // the estimate stays fixed while the remaining time counts down
    d.feed(remaining_ticks_down()); expect_props(d, #{ remaining_time: "56", initial_time: "57" });
    d.feed(drying_to_cooling()); expect_props(d, #{ status: "cooling", remaining_time: "1" });
    d.feed(cooling_to_off_blip()); expect_eq(d.property("status"), "off"); // a brief settle before End
    d.feed(off_blip_to_end()); expect_eq(d.property("status"), "end");
    d.feed(end_to_final_off());
    expect_props(d, #{ status: "off", power: "false", remaining_time: "0", initial_time: "0", course: "none" });
}

// a real remote-start round trip flips Initial -> Drying
fn test_a_remote_start_round_trip() {
    let d = device();
    d.feed(app_start_command()); // the command the LG app sent, for reference
    d.feed(remote_starts_drying());
    expect_eq(d.property("status"), "drying");
}

// a real remote-power-off round trip drops straight to Off
fn test_a_remote_power_off_round_trip() {
    let d = device();
    d.feed(app_poweroff_command());
    d.feed(remote_poweroff());
    expect_props(d, #{ status: "off", power: "false", course: "none" });
}

// unknown frame type and non-envelope frames are ignored
fn test_other_frames_are_ignored() {
    let d = device();
    d.feed(course_normal());
    for junk in ["aa09307200c9004bbb", "001122"] { d.feed(junk); }
    expect_eq(d.property("status"), "initial");
}

fn test_every_property_is_read_only() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 0); // upstream sends no status query for this model
    d.set("power", "false");
    expect(d.event("reject") != (), "reject");
}
