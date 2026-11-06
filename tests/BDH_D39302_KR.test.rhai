import "runtime_test" as runtime;

// Tests of BDH_D39302_KR.rhai (WashTower dryer), ported from the owner's rethink
// TS driver. The first two frames are this unit's own real captures
// (testdata/dryer_frames_20261104.txt, 2026-11-04): an idle EB (state power off)
// and an EC whose current record reads state on. The remaining flow frames are
// kjy8850's real captures from the sibling BDH_D39301_KR (rethink PR #117 vectors,
// same wire protocol and record layout); expected values use OUR TS driver's
// labels, which differ from the sibling Rhai driver's snake_case names for the
// same wire codes (e.g. course 2 is "Towels" here, "towels" there).

fn own_eb() { "aaff340a0044005b52000100eb003200000000000000000000000000000100000000040000008f00000004070000000a0000000000000000000000000000000000655abb" }
fn own_ec() { "aaff340a0076005bd4000100ec006400000000000000000000000000000100000000040000008f00000004070000000a000000000000000000000000000000000000000000000000000000000000010000000000040000008f00000004070000000a00000000000000000000000000000000000285bb" }

fn test_own_eb_publishes_the_idle_state() {
    let d = device();
    d.feed(own_eb());
    expect_props(d, #{
        "course": "None", "reserve_time": "0", "remaining_time": "0", "initial_time": "0",
        "state": "Power off", "error": "No error",
        "remote_start": "false", "child_lock": "false", "door_lock": "false", "remote_maintain": "false",
        "setting_course": "Standard", "setting_eco_hybrid": "Auto",
        "setting_wrinkle_care": "Off", "setting_steam": "Off", "setting_dry_level": "Standard",
        "power": "false", "power_transition": "standby"
    });
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// Device frames other than status records are acknowledged ahead of decoding (c::ack), as the
// other AABB drivers do; without it the appliance repeated each notification ~10 times
// (seen live 2026-11-05). aa0734190255bb is a real frame of this class; the ACK is the captured reply.
fn test_device_frames_are_acknowledged() {
    let d = device();
    d.feed("aa0734190255bb");
    let clips = d.clips();
    expect_eq(clips.len(), 1);
    expect_eq(clips[0].cmd, "ack");
    expect_eq(clips[0].data, "AA08F0001904EABB");
    expect_eq(d.script_error(), ());
}

fn test_own_ec_publishes_the_current_record() {
    let d = device();
    d.feed(own_ec());
    expect_props(d, #{
        "state": "On", "course": "None", "error": "No error",
        "power": "true", "power_transition": "standby"
    });
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

fn test_course_two_publishes_the_ts_label() {
    let d = device();
    // PR #117 capture: course raw 2.
    d.feed("aaff340a0045000000000100eb00330000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001405bb");
    expect_props(d, #{ "course": "Towels", "state": "Power off" });
    expect_eq(d.script_error(), ());
}

fn test_unknown_public_enums_publish_absent() {
    let d = device();
    // PR #117 capture with 0xfa in the public enum slots.
    d.feed("aaff340a0045000000000100eb00330000000000fa00000000000000fa00fa00000000000000000000000000000000000000000000000000000000000000000000009db8bb");
    expect_eq(d.property("state"), "");
    expect_eq(d.property("course"), "");
    expect_eq(d.property("error"), "");
    expect_eq(d.script_error(), ());
}

fn test_power_on_uses_the_vtctrl_frame() {
    let d = device();
    d.feed(own_eb());
    d.set("power", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa0df0e5000201ff010201c7bb");
    expect_props(d, #{ "power_transition": "turning_on" });
    expect_eq(d.script_error(), ());
}

// Power off rides the F0 E5 power channel like the official app (live capture
// 2026-11-05) and is not gated on remote start; only an already-off dryer refuses it.
fn test_power_off_uses_the_e5_channel_without_remote_gate() {
    let d = device();
    d.feed(own_ec()); // state on, but remote_start / remote_maintain both off
    let n = d.sent().len();
    d.set("power", "false");
    expect_eq(d.sent().len(), n + 1);
    expect_eq(hex_encode(d.sent()[n]), "aa0df0e5000001ff010200dabb");
    expect_eq(d.script_error(), ());
}

fn test_start_course_sends_the_f026_payload() {
    let d = device();
    // PR #117 capture: state on with remote start armed.
    d.feed("aaff340a0045000000000100eb0033000000000000000000000000000100000000000000000000000040000000000000000000000000000000000000000000000000de5dbb");
    expect_props(d, #{ "state": "On", "remote_start": "true" });
    d.set("setting_course", "Standard");
    d.set("start", "");
    // course 7, dryLevel 3, ecoHybrid 2 - the same draft codes as the TS driver.
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260703020000000000000000000000b5bb");
    expect_eq(d.script_error(), ());
}

fn test_commands_fail_closed_before_any_state() {
    let d = device();
    d.set("wake", "");
    d.set("power", "true");
    d.set("start", "");
    d.set("power_off", "");
    d.set("pause", "");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

fn test_the_descriptor_covers_the_full_ts_surface() {
    let d = device();
    d.start();
    let desc = runtime::descriptor(d);
    // 8 module properties + 9 public fields + 5 setting selects.
    expect_eq(desc.props.keys().len(), 22);
    expect_eq(desc.props.setting_course.options.len(), 10);
}
