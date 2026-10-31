import "runtime_test" as runtime;

// Tests of F3P3CYK2_, ported from upstream rethink's test suite (commit 0e57069; real wire traffic
// from a WM4200HBA). Expected values are what upstream's driver publishes, in IL names (its
// error_state is error); the soil, temperature and course codes it leaves unknown read "none".

fn off_snapshot() { "AA3320EB002B0000000E00000000000000000000010000002D0000001069000000001E04000000000000004000000000007FBB" }
fn paused() { "AA6020EC002B0000000E0F2E0000000000000000150016000000000C2469070000011E0400000000002000100000010000002B0000000E0F2E000000000000000015001600000000020C69070000011E04000000000020004000000100001BBB" }
fn resumed_rinsing() { "AA6020EC002B0000000E0F2E000000000000000015001600000000240269070000011E0400000000002000100000010000002B0000000E0F2E0000000000000000150016000000000C2469070000011E040000000000200010000001000063BB" }
fn spinning() { "AA6020EC002B0000000E0F2E0000000000000000120016000100000C2469070000011E0400000000002000100000010000002B0000000E0F2E0000000000000000110016000200000E0C69070000001E040000000000200010000001000070BB" }
fn end_() { "AA6020EC002B0000000E0F2E0000000000000000010016002800000E0C69070000001E0400000000002000100000010000002B0000000E00000000000000000000010000002D0000100E69000000001E0400000000000000400000000000ADBB" }
fn off_after_end() { "AA6020EC002B0000000E00000000000000000000010000002D0000100E69000000001E0400000000000000400000000000002B0000000E00000000000000000000010000002D0000001069000000001E0400000000000000400000000000FDBB" }
fn e2_stale_replay() { "AA3320E2032B0000000E0F2E0000000000000000160016002D0000240169070000011E0400000000002000100000010000CFBB" }
fn dial_normal() { "AA6020EC002B00030E0E0E1600000000000000002D002D00000000010069070000021E0400000000000000400000000000002B0003100E0F2E00000000000000002E002E00000000010069000000011E0400000000200000400000010000D3BB" }
fn dial_bedding() { "AA6020EC002B0005100E1023000000000000000082008200000000010069000000011E0400000000200000400000000000002B0003100E0E0D00000000000000003C003C00000000010069070000021E040000000000000040000000000069BB" }
fn dial_sanitary() { "AA6020EC002B0003100E0E0D00000000000000003C003C00000000010069070000021E0400000000000000400000000000002B0003130E0F3C000000000000000074007400000000010069000000031E04000000000000004000000000004EBB" }
fn dial_downloaded() { "AA6020EC002B0000000E0E55000000000000000059005900000000010069000000021E0400000000001000400000000000002B0003100E0FFF00000000000000002D002D00000000010069000000021E040000000000000040000000000091BB" }
fn dial_drain_spin() { "AA6020EC002B0003100E0FFF00000000000000002D002D00000044010069000000021E0400000000000000400000000000002B0000000E0F1900000000000000000B000B00000000010069070000001E040000000000000040000000000073BB" }
fn dial_delicates() { "AA6020EC002B0003100E0E3000000000000000002A002A00000000010069000000011E0400000000200000400000000000002B00030E0E0E1600000000000000002D002D00000000010069070000021E04000000000000004000000000002BBB" }
fn rinse_spin_on() { "AA6020EC002B0003100E0F2E00000000000000002E002E00000000010069000000011E0400000000200000400000010000002B0000000E0F2E000000000000000016001600000000010069070000011E0400000000002000400000010000D5BB" }
fn rinse_spin_off() { "AA6020EC002B0000000E0F2E000000000000000016001600000000010069070000011E0400000000002000400000010000002B0003100E0F2E00000000000000002E002E00000000010069000000011E0400000000200000400000010000D5BB" }

fn fed(frames) { let d = device(); for f in frames { d.feed(f); } d }
// DIAL_NORMAL with record bytes changed (the current record starts at raw offset 50)
fn patched(changes) {
    let f = hex_decode(dial_normal());
    for c in changes { f[50 + c[0]] = c[1]; }
    f
}

// config exposes the conservative entity set
fn test_the_descriptor_is_conservative() {
    let d = device();
    d.start();
    let props = runtime::descriptor(d).props;
    for p in ["power", "status", "run_completed", "error", "error_message", "course", "remaining_time",
              "initial_time", "reserve_time", "soil", "temp", "rinse", "spin", "rinse_spin",
              "tub_clean_count", "buzzer"] { expect(props.contains(p), p); }
    expect_eq(props.power_off.type, "trigger");
    expect_eq(props.power_off.requires, "power");
    for unsafe in ["pause", "remote_start", "course_selection", "start"] { expect(!props.contains(unsafe), unsafe); }
    expect(!(props.power.rw ?? false), "no power switch");
    expect_eq(props.spin.options, ["no_spin", "low", "medium", "high", "extra_high"]);
}

// power-off button sends the command captured from the ThinQ app
fn test_power_off_sends_the_captured_command() {
    let d = device();
    d.start();
    d.feed(dial_normal()); // powered on: the button applies
    let n = d.sent().len();
    d.set("power_off", "");
    expect_eq(d.sent().len(), n + 1);
    expect_eq(hex_encode(d.sent()[n]), "aa09f0240101009cbb");
}

// (IL) while off the button does not apply, and nothing is sent
fn test_power_off_is_refused_while_off() {
    let d = device();
    d.start();
    d.feed(off_snapshot());
    let n = d.sent().len();
    d.set("power_off", "");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject").contains("requires_unmet"), "requires power");
}

// modelJSON error index publishes dE1 and a later status clears it
fn test_an_error_and_its_clearing() {
    let d = fed([patched([[20, 20]])]);
    expect_props(d, #{ error: "true", error_message: "dE1 - Door Open" });
    d.feed(dial_normal());
    expect_props(d, #{ error: "false", error_message: "-" });
}

// start sends the read-only status request captured from LG cloud
fn test_start_asks_for_the_status() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 1);
    expect_eq(hex_encode(d.sent()[0]), "aa12f0ed1121010000001804131400005abb");
}

// single-record 0xEB snapshot initializes an off washer
fn test_an_off_snapshot() {
    expect_props(fed([off_snapshot()]), #{ power: "false", status: "off", course: "none", remaining_time: "0",
        initial_time: "0", run_completed: "false" });
}

// real pause, resume, spin, end and power-off sequence decodes correctly
fn test_pause_resume_spin_end_and_power_off() {
    let d = fed([paused()]);
    expect_props(d, #{ power: "true", status: "paused", remaining_time: "21", initial_time: "22" });
    d.feed(resumed_rinsing()); expect_props(d, #{ status: "rinsing", remaining_time: "21" });
    d.feed(spinning()); expect_props(d, #{ status: "spinning", remaining_time: "17" });
    // the End record is published as is
    d.feed(end_()); expect_props(d, #{ status: "end", power: "true", remaining_time: "1", initial_time: "0", run_completed: "true" });
    d.feed(off_after_end()); expect_props(d, #{ status: "off", power: "false", run_completed: "false" });
    d.feed(dial_normal()); expect_props(d, #{ status: "standby", run_completed: "false" });
}

// 0xE2 post-cycle replay is ignored
fn test_the_post_cycle_replay_is_ignored() {
    expect_props(fed([end_(), e2_stale_replay()]), #{ status: "end", remaining_time: "1", run_completed: "true" });
}

// real course selections map to their panel names
fn test_real_course_selections() {
    for pair in [[dial_normal(), "normal"], [dial_bedding(), "bedding"], [dial_sanitary(), "sanitary"],
                 [dial_downloaded(), "downloaded"], [dial_drain_spin(), "drain_spin"], [dial_delicates(), "delicates"]] {
        expect_eq(fed([pair[0]]).property("course"), pair[1]);
    }
}

// the full captured course table maps every code
fn test_every_course_code() {
    for pair in [[0x05, "allergiene"], [0x0d, "bedding"], [0x16, "delicates"], [0x19, "drain_spin"],
                 [0x23, "heavy_duty"], [0x2e, "normal"], [0x30, "perm_press"], [0x3c, "sanitary"],
                 [0x4a, "speed_wash"], [0x4f, "sportswear"], [0x54, "towels"], [0x55, "tub_clean"],
                 [0x5a, "bright_whites"], [0xff, "downloaded"]] {
        expect_eq(fed([patched([[6, pair[0]]])]).property("course"), pair[1]);
    }
}

// Rinse+Spin is an option layered on Normal, not a separate course
fn test_rinse_spin_is_an_option() {
    expect_props(fed([rinse_spin_on()]), #{ course: "normal", rinse_spin: "true", soil: "none", temp: "none",
        rinse: "normal", spin: "high", remaining_time: "22" });
    expect_props(fed([rinse_spin_on(), rinse_spin_off()]), #{ rinse_spin: "false", course: "normal", soil: "normal", temp: "warm" });
}

// known settings and diagnostics decode from a real Normal selection
fn test_a_normal_selection() {
    expect_props(fed([dial_normal()]), #{ soil: "normal", temp: "warm", rinse: "normal", spin: "high",
        remaining_time: "46", initial_time: "46", tub_clean_count: "30", buzzer: "4" });
}

// times are big-endian 16-bit minute counts
fn test_times_are_big_endian_minutes() {
    let f = patched([[12, 0x01], [13, 0x2c], [14, 0x01], [15, 0x1e], [16, 0x01], [17, 0x2e]]);
    expect_props(fed([f]), #{ reserve_time: "300", remaining_time: "286", initial_time: "302" });
}

// wrong-length and unrelated frames publish nothing
fn test_other_frames_publish_nothing() {
    for junk in ["aa0720d800fcbb", "aa09207200c9005bbb", "aa0a20ec002b000000bb"] {
        expect_eq(fed([junk]).property("available"), (), junk);
    }
}
