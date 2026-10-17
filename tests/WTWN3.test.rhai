import "runtime_test" as runtime;

// Tests of WTWN3 (washer_t1_common), ported from upstream rethink's test suite (commit 0e57069).
// The Mix cycle and the tub clean frame are real captures from an F4J7TN1W; the option and
// downloaded-course frames are synthetic, from the modelJson bit layout. Expected values are what
// upstream's driver publishes for the same input, in IL names: door_lock is true while locked
// (upstream publishes it inverted, for Home Assistant's lock class), and upstream's "wash" is the
// soil level, with the EU washers' codes.

fn sample_washing_mix_1h33() { "06012101210700030704020000000040000001030039006400000400" }
fn sample_rinsing_mix_0h47() { "07002f01210700030700020000000040000001060039006400000400" }
fn sample_spinning_mix_0h11() { "08000b01210700000700000000000040000001070039006400000400" }
fn sample_end_mix() { "0a000001210700000000000000000000000001080039006400000400" }
fn sample_off_idle() { "000000012107000000000000000000000000020a0039006400000400" }
fn sample_measuring_tub_clean_locked() { "04 01 0e 01 0e 12 00 03 01 06 01 00 00 00 00 40 00 00 01 01 00 29 00 4b 00 00 02 00" }
fn sample_ready_cotton_options() { "01 02 0a 02 0a 01 00 03 09 04 01 00 03 00 c1 82 00 00 00 00 00 39 00 64 00 00 04 00" }
fn sample_error_de1_smart_jeans() { "12 01 0e 01 0e 03 02 03 07 02 01 00 00 00 00 00 00 00 00 00 39 39 00 64 00 00 04 00" }

fn sent(d, n) { let body = d.clips()[n].Body; body.remove("CmdWId"); body }

fn test_the_descriptor_lists_the_model_features() {
    let d = device_t1();
    d.start();
    let props = runtime::descriptor(d).props;
    for p in ["soil", "rinse", "reserve_time", "turbo_wash", "crease_care", "medic_rinse", "pre_wash",
              "steam", "child_lock", "standby", "tub_clean_count"] {
        expect(props.contains(p), p);
    }
    expect(!props.contains("drying_mode"), "no dryer");
    expect(props.course.options.contains("tub_clean"), "WTWN3 courses");
}

// washing state decodes course, options and times from a real capture
fn test_washing_from_a_real_capture() {
    let d = device_t1();
    d.feed(sample_washing_mix_1h33());
    expect_props(d, #{ power: "true", status: "washing", course: "mix", soil: "normal", spin: "1000",
                       temp: "40", rinse: "rinse_plus", remaining_time: "93", initial_time: "93",
                       reserve_time: "0", error: "false", error_message: "OK", door_lock: "true",
                       child_lock: "false", remote_start: "false", tub_clean_count: "57",
                       standby: "false" });
}

// tub clean start: Measuring with the door locked, from a live frame
fn test_tub_clean_start_from_a_live_frame() {
    let d = device_t1();
    d.feed(sample_measuring_tub_clean_locked());
    expect_props(d, #{ power: "true", status: "measuring", course: "tub_clean", soil: "normal",
                       spin: "no_spin", temp: "60", rinse: "normal", remaining_time: "74",
                       initial_time: "74", door_lock: "true", child_lock: "false",
                       tub_clean_count: "41" });
}

// rinse and spin phases follow the state byte
fn test_rinse_and_spin_follow_the_state() {
    let d = device_t1();
    d.feed(sample_rinsing_mix_0h47());
    // the temperature is cleared once washing is over
    expect_props(d, #{ status: "rinsing", remaining_time: "47", temp: "none" });
    d.feed(sample_spinning_mix_0h11());
    expect_props(d, #{ status: "spinning", remaining_time: "11", spin: "1000" });
}

// end state keeps power on, door unlocked
fn test_end() {
    let d = device_t1();
    d.feed(sample_end_mix());
    expect_props(d, #{ power: "true", status: "end", remaining_time: "0", door_lock: "false" });
}

// idle state publishes power=OFF and "Off" status
fn test_idle() {
    let d = device_t1();
    d.feed(sample_off_idle());
    // the last course stays visible on the panel
    expect_props(d, #{ power: "false", status: "off", course: "mix", tub_clean_count: "57" });
}

// option bits, delay start and locks decode
fn test_option_bits_delay_start_and_locks() {
    let d = device_t1();
    d.feed(sample_ready_cotton_options());
    expect_props(d, #{ status: "ready", course: "cotton", spin: "1200", temp: "40",
                       remaining_time: "130", reserve_time: "180", turbo_wash: "true",
                       pre_wash: "true", steam: "true", crease_care: "false", medic_rinse: "false",
                       remote_start: "true", child_lock: "true", door_lock: "false" });
}

// downloaded course overrides the base course; error publishes message
fn test_a_downloaded_course_overrides_the_base_course() {
    let d = device_t1();
    d.feed(sample_error_de1_smart_jeans());
    expect_props(d, #{ status: "error", error: "true", error_message: "Door open error (DE1)",
                       course: "jeans" });
}

// ignores frames that are not 28 bytes
fn test_other_lengths_are_ignored() {
    let d = device_t1();
    d.feed("0102");
    expect_eq(d.property("power"), ());
}

// power switch and buttons send ThinQ1 Control commands
fn test_power_and_buttons_send_control_commands() {
    let d = device_t1();
    d.start();
    d.set("power", "false");
    d.set("pause", "");
    d.set("start", "");
    expect_eq(d.clips().len(), 4);
    expect_eq(sent(d, 0), #{ Cmd: "Mon", CmdOpt: "Start" });
    expect_eq(sent(d, 1), #{ Cmd: "Control", CmdOpt: "Power", Value: "Off", Format: "B64", Data: "" });
    expect_eq(sent(d, 2), #{ Cmd: "Control", CmdOpt: "Operation", Value: "Stop", Format: "B64", Data: "" });
    expect_eq(sent(d, 3), #{ Cmd: "Control", CmdOpt: "Operation", Value: "Start", Format: "B64", Data: "" });
}
