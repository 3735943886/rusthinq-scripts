import "runtime_test" as runtime;

// Tests of F24VDD.rhai (washer), against a real idle frame and the start frames the LG app sent.

import "aabb_test" as a;

fn idle() { "aa4e20ec0022000000000000000000000000000000020000bf3c39180e0000000003000402022d1e0022000000000000000000000000000000020000bf3c39180e0000000003000402022d1ef9bb" }

fn status(p) { a::status(0x20, p) }

// The washer mid-wash: the record the source comments describe (17 01 21 01 2c 06 00 03 03 04
// 03 ...), Heavy Duty at heavy soil, medium spin, 60 C, three rinses, door locked, Add Garment.
fn heavy_duty_wash() {
    let p = a::payload(34, [23, 1, 33, 1, 44, 6, 0, 3, 3, 4, 3]);
    p[14] = 0x20 | 0x08;        // remote start, child lock
    p[15] = 0x02 | 0x04 | 0x40; // alarm, door lock, add garment
    p[17] = 0x01;
    p[18] = 0x2c;               // 300 Wh so far
    p[22] = 14;                 // operating course: Heavy Duty
    p
}

fn test_a_real_idle_frame_becomes_il_properties() {
    let d = device();
    d.feed(idle());
    expect_eq(d.script_error(), ());
    expect_props(d, #{
        available: "true", power: "false", status: "off", course: "none",
        op_course: "heavy_duty", download_course: "kids_wear", remaining_time: "0",
        initial_time: "0", reserve_time: "0", soil: "none", spin: "no_spin", temp: "none",
        rinse: "0", energy: "191", load_level: "0", tub_clean_count: "24", error: "false",
        error_message: "OK", alarm: "true", child_lock: "false", door_lock: "false",
        remote_start: "false", steam: "false"
    });
}

fn test_a_running_wash_matches_the_record_the_cloud_decoded() {
    let d = device();
    d.feed(status(heavy_duty_wash()));
    expect_props(d, #{
        status: "washing", course: "heavy_duty", op_course: "heavy_duty",
        remaining_time: "93",  // 1h33m left
        initial_time: "104",   // of 1h44m
        soil: "heavy", spin: "medium", temp: "60", rinse: "3", door_lock: "true",
        add_load: "true", child_lock: "true", remote_start: "true", energy: "300"
    });
}

fn test_the_dial_course_and_the_running_course_are_reported_apart() {
    let d = device();
    let p = heavy_duty_wash();
    p[5] = 14; // the dial is on "Downloaded course"
    p[22] = 5; // and the machine is running Cotton
    d.feed(status(p));
    expect_props(d, #{ course: "downloaded_course", op_course: "cotton" });
    // a dial position start cannot express is not adopted as the selection
    expect_eq(d.property("course_select"), ());
}

fn test_the_flags_decode_from_their_bits() {
    let d = device();
    let p = heavy_duty_wash();
    p[14] = 0x01 | 0x02 | 0x04 | 0x10 | 0x40;
    p[15] = 0x80;
    d.feed(status(p));
    expect_props(d, #{
        crease_care: "true", fresh_care: "true", rinse_hold: "true", steam: "true",
        favorite: "true", turbo_shot: "true", alarm: "false"
    });
}

// ---- commands, as the app sent them ------------------------------------------------

fn test_colour_care_start_as_the_app_sent_it() {
    let d = device();
    d.set("course_select", "colour_care");
    d.set("start", "");
    expect_eq(a::payload_hex(d, 0), "0a0202020300002000201000000000000000000000");
}

fn test_heavy_duty_start_as_the_app_sent_it() {
    let d = device();
    d.set("course_select", "heavy_duty");
    d.set("start", "");
    expect_eq(a::payload_hex(d, 0), "060303040300002000200e00000000000000000000");
}

fn test_steam_refresh_sets_the_steam_bit_and_the_app_agreed() {
    let d = device();
    d.set("course_select", "steam_refresh");
    d.set("start", "");
    // the course fixes steam on: the flags byte carries 0x10 beside the remote-start 0x20
    expect_eq(a::payload_hex(d, 0), "010200000000003000200100000000000000000000");
}

fn test_resuming_clears_the_initial_bit_and_changes_nothing_else() {
    let d = device();
    d.set("course_select", "heavy_duty");
    d.set("start", "");
    let paused = heavy_duty_wash();
    paused[0] = 6;
    d.feed(status(paused));
    d.set("start", "");
    let start = a::inner_of(d, 0);
    let resume = a::inner_of(d, 1);
    expect_eq(start[2 + 9].to_int(), 0x20);
    expect_eq(resume[2 + 9].to_int(), 0);
    expect_eq(start.extract(0, 2 + 9), resume.extract(0, 2 + 9));
    expect_eq(start.extract(2 + 10), resume.extract(2 + 10));
}

fn test_a_course_with_no_preset_is_not_started() {
    let d = device();
    d.set("course_select", "none");
    d.set("start", ""); // nothing valid selected
    expect_eq(d.sent().len(), 0);
    expect(d.event("reject") != (), "a reject event was published");
}

fn test_pause_and_power_off_are_the_short_controls() {
    let d = device();
    d.set("power_off", "");
    d.set("pause", "");
    expect_eq(a::inner_hex(d, 0), "f024010100");
    expect_eq(a::inner_hex(d, 1), "f024040100");
}

fn test_a_washer_that_refuses_a_power_off_says_so() {
    let d = device();
    d.set("power_off", "");
    // this washer answered 0xff to a power-off three times, each while it had nothing to power off
    d.feed(a::framed([0x20, 0x00, 0x24, 0xff]));
    let reject = d.event("reject");
    expect(reject != (), "a rejection");
    expect(reject.contains("power_off") && reject.contains("refused"), reject);
}

fn test_a_record_of_another_length_reports_nothing() {
    let d = device();
    d.feed(a::record(0x20, 0xeb, 0x00, blob(33)));
    expect_eq(d.property("status"), ());
}

fn test_dropping_the_device_marks_it_unavailable() {
    let d = device();
    d.feed(idle());
    d.drop_device();
    expect_eq(d.property("available"), "false");
}

fn test_the_descriptor_offers_captured_downloaded_courses_too() {
    let d = device();
    d.start();
    let desc = runtime::descriptor(d);
    expect_eq(desc["class"], "washing_machine");
    let options = desc.props.course_select.options;
    expect_eq(options.len(), 15);
    expect(options.contains("downloaded_course"), "captured downloads can now be started");
    expect_eq(desc.props.start.requires, "remote_start");
}

fn test_il_common_holds_start_back_until_remote_start_is_armed() {
    let d = device();
    let disarmed = heavy_duty_wash();
    disarmed[14] = disarmed[14] & 0xdf;
    d.start();
    d.feed(status(disarmed));
    d.set("power_off", "");
    expect_eq(d.sent().len(), 1); // startup status query only
    expect(d.event("reject").contains("requires remote_start"), "il_common names the requirement");
    d.feed(status(heavy_duty_wash())); // armed
    d.set("power_off", "");
    expect_eq(d.sent().len(), 2);
}

// Availability follows the online lifecycle, independently of state reports.
fn test_reconnect_restores_availability_without_a_state_frame() {
    let d = device();
    d.start();
    expect_eq(d.script_error(), ());
    expect_eq(d.property("available"), "true");
    d.drop_device();
    expect_eq(d.property("available"), "false");
    d.start();
    expect_eq(d.property("available"), "true");
    expect_eq(d.script_error(), ());
}
// BEGIN PR VECTORS
// Regression vectors from rethink PR #180 (5c0acfd8ec17f2aee451572a64d686f49d06f2fb).
// Original test names are retained below. Expected TX bytes come from executing the TS driver.

// decodes the current captured standby record
fn test_pr_180_1() {
    let d = device();
    d.feed("aa2c20eb0024050000000000000000000000000000020000010033010f000000000002022d1e00000100f5bb");
    expect_props(d, #{"power": "true", "status": "initial", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// tracks the actually downloaded course from record byte 21 for all 14 captured courses
fn test_pr_180_2() {
    let d = device();
    d.feed("aa5220ec0024000000000000000000000000000000020000070633040f000000000002022d1e0000010000240000000000000000000000000000000200000706340404000000000002022d1e00000100c5bb");
    expect_props(d, #{"smart_course_select": "small_load", "power": "false", "status": "off", "course": "none", "smart_course": "small_load", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec00240000000000000000000000000000000200000706340404000000000002022d1e000001000024000000000000000000000000000000020000000633040f000000000002022d1e00000100dcbb");
    expect_props(d, #{"smart_course_select": "cold_wash", "power": "false", "status": "off", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec00240000000000000000000000000000000200000006340404000000000002022d1e000001000024000000000000000000000000000000020000000637040e000000000002022d1e00000100d0bb");
    expect_props(d, #{"smart_course_select": "sweat_stain", "power": "false", "status": "off", "course": "none", "smart_course": "sweat_stain", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec0024000000000000000000000000000000020000000637040e000000000002022d1e0000010000240000000000000000000000000000000200000006380404000000000002022d1e00000100dcbb");
    expect_props(d, #{"smart_course_select": "single_garments", "power": "false", "status": "off", "course": "none", "smart_course": "single_garments", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec00240000000000000000000000000000000200000006380404000000000002022d1e000001000024000000000000000000000000000000020000000639040e000000000002022d1e00000100debb");
    expect_props(d, #{"smart_course_select": "kids_wear", "power": "false", "status": "off", "course": "none", "smart_course": "kids_wear", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec0024000000000000000000000000000000020000000639040e000000000002022d1e00000100002400000000000000000000000000000002000000063a040e000000000002022d1e00000100c2bb");
    expect_props(d, #{"smart_course_select": "shirt", "power": "false", "status": "off", "course": "none", "smart_course": "shirt", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec002400000000000000000000000000000002000000063a040e000000000002022d1e00000100002400000000000000000000000000000002000000063b0405000000000002022d1e00000100c5bb");
    expect_props(d, #{"smart_course_select": "school_uniform", "power": "false", "status": "off", "course": "none", "smart_course": "school_uniform", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec002400000000000000000000000000000002000000063b0405000000000002022d1e00000100002400000000000000000000000000000002000000063c0401000000000002022d1e00000100d0bb");
    expect_props(d, #{"smart_course_select": "static_reduce", "power": "false", "status": "off", "course": "none", "smart_course": "static_reduce", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec002400000000000000000000000000000002000000063c0401000000000002022d1e00000100002400000000000000000000000000000002000000063f0415000000000002022d1e00000100ccbb");
    expect_props(d, #{"smart_course_select": "spin_only", "power": "false", "status": "off", "course": "none", "smart_course": "spin_only", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec002400000000000000000000000000000002000000063f0415000000000002022d1e0000010000240000000000000000000000000000000200000006410401000000000002022d1e00000100cbbb");
    expect_props(d, #{"smart_course_select": "deodorization", "power": "false", "status": "off", "course": "none", "smart_course": "deodorization", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec00240000000000000000000000000000000200000006410401000000000002022d1e0000010000240000000000000000000000000000000200000006430408000000000002022d1e00000100c0bb");
    expect_props(d, #{"smart_course_select": "cloth_care", "power": "false", "status": "off", "course": "none", "smart_course": "cloth_care", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec00240000000000000000000000000000000200000006430408000000000002022d1e0000010000240000000000000000000000000000000200000006440405000000000002022d1e00000100c9bb");
    expect_props(d, #{"smart_course_select": "smart_rinse", "power": "false", "status": "off", "course": "none", "smart_course": "smart_rinse", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec00240000000000000000000000000000000200000706340404000000000002022d1e000001000024000000000000000000000000000000020000000633040f000000000002022d1e00000100dcbb");
    expect_props(d, #{"smart_course_select": "cold_wash", "power": "false", "status": "off", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec00240000000000000000000000000000000200000706340404000000000002022d1e000001000024000000000000000000000000000000020000000663040f000000000002022d1e00000100ecbb");
    expect_props(d, #{"smart_course_select": "cold_wash", "power": "false", "status": "off", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// an out-of-range spin code is reported as Code N, not folded into Off
fn test_pr_180_3() {
    let d = device();
    d.feed("aa2c20eb0024050000000000000000000000000000020000010033010f000000000002022d1e00000100f5bb");
    expect_props(d, #{"power": "true", "status": "initial", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa2c20eb0024050000000000000009000000000000020000010033010f000000000002022d1e00000100fcbb");
    expect_props(d, #{"power": "true", "status": "initial", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a frame with a corrupted checksum is dropped, not decoded
fn test_pr_180_4() {
    let d = device();
    d.feed("aa2c20eb0024050000000000000000000000000000020000010033010f000000000002022d1e00000100f5bb");
    expect_props(d, #{"power": "true", "status": "initial", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa2c20eb0024050000000000000009000000000000020000010033010f000000000002022d1e00000100f5bb");
    expect_props(d, #{"power": "true", "status": "initial", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// decodes the captured Child Lock button press and release
fn test_pr_180_5() {
    let d = device();
    d.feed("aa5220ec0024050000000000000000000000000000020000000033040f000000000002022d1e000001000024050000000000000000000000000008020000000033040f000000000002022d1e00000100c7bb");
    expect_props(d, #{"power": "true", "status": "initial", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "true", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec0024050000000000000000000000000008020000000033040f000000000002022d1e000001000024050000000000000000000000000000020000000033040f000000000002022d1e00000100c7bb");
    expect_props(d, #{"power": "true", "status": "initial", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa2c20eb0024050000000000000000000000000008020000000033040f000000000002022d1e00000100ffbb");
    expect_props(d, #{"power": "true", "status": "initial", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "true", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// decodes the owner-labelled TurboShot ON/OFF pair on the same reservation
fn test_pr_180_6() {
    let d = device();
    d.feed("aa5220ec0024140032003207000201040100100020c60000000533050f000000000002022d1e0000010000240a002e002e07000201040100100020c60000001433050f010000000002022d1e00000100d5bb");
    expect_props(d, #{"power": "true", "status": "reserved", "course": "cotton", "smart_course": "cold_wash", "spin": "very_low", "temp": "60", "rinse": "1", "remaining_time": "46", "initial_time": "46", "reserve_time": "960", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "true", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec00241400320032070002010401000f3920460000000633050f000000000002022d1e0000010000240a002e002e070002010401000f3920460000001433050f010000000002022d1e00000100a4bb");
    expect_props(d, #{"power": "true", "status": "reserved", "course": "cotton", "smart_course": "cold_wash", "spin": "very_low", "temp": "60", "rinse": "1", "remaining_time": "46", "initial_time": "46", "reserve_time": "957", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// decodes the owner-labelled steam ON frame, OFF on the same-settings run
fn test_pr_180_7() {
    let d = device();
    d.feed("aa5220ec00241400310031070002010001000f3530460000000633050f000000000002022d1e0000010000240a002d002d070002010001000f3530460000001433050f010000000002022d1e00000100a8bb");
    expect_props(d, #{"power": "true", "status": "reserved", "course": "cotton", "smart_course": "cold_wash", "spin": "very_low", "temp": "none", "rinse": "1", "remaining_time": "45", "initial_time": "45", "reserve_time": "953", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec00241400320032070002010401000f3920460000000633050f000000000002022d1e0000010000240a002e002e070002010401000f3920460000001433050f010000000002022d1e00000100a4bb");
    expect_props(d, #{"power": "true", "status": "reserved", "course": "cotton", "smart_course": "cold_wash", "spin": "very_low", "temp": "60", "rinse": "1", "remaining_time": "46", "initial_time": "46", "reserve_time": "957", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// decodes the user-labelled Standard course with its captured 33-minute estimate
fn test_pr_180_8() {
    let d = device();
    d.feed("aa5220ec002405012f012f06000303040300000000020000000033010f000000000002022d1e000001000024050021002107000204030200000000824000000033010f000000000002022d1e000001005ebb");
    expect_props(d, #{"power": "true", "status": "initial", "course": "cotton", "smart_course": "cold_wash", "spin": "high", "temp": "40", "rinse": "2", "remaining_time": "33", "initial_time": "33", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "true", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// maps the isolated Standard-course 40C to 60C transition (via the ThinQ app, not the panel)
fn test_pr_180_9() {
    let d = device();
    d.feed("aa5220ec002405012f012f06000303040300000000020000000033010f000000000002022d1e000001000024050021002107000204030200000000824000000033010f000000000002022d1e000001005ebb");
    expect_props(d, #{"power": "true", "status": "initial", "course": "cotton", "smart_course": "cold_wash", "spin": "high", "temp": "40", "rinse": "2", "remaining_time": "33", "initial_time": "33", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "true", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec0024050021002107000204030200000000824000000033010f000000000002022d1e000001000024050037003707000204040200000000820000000033010f000000000002022d1e00000100ccbb");
    expect_props(d, #{"power": "true", "status": "initial", "course": "cotton", "smart_course": "cold_wash", "spin": "high", "temp": "60", "rinse": "2", "remaining_time": "55", "initial_time": "55", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "true", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// decodes owner-labelled live rinse/spin/temperature status and rinse countdown
fn test_pr_180_10() {
    let d = device();
    d.feed("aa5220ec00241e000c0104070000040002000000208600007b1733010f010000000002022d1e0000010000241e000b010407000004000200000020860000841733010f010000000002022d1e000001003dbb");
    expect_props(d, #{"power": "true", "status": "rinsing", "course": "cotton", "smart_course": "cold_wash", "spin": "high", "temp": "none", "rinse": "2", "remaining_time": "11", "initial_time": "64", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "true", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa5220ec00241e000b010407000004000200000020860000841733010f010000000002022d1e0000010000241e000a010407000004000100000020860000871733010f010000000002022d1e0000010024bb");
    expect_props(d, #{"power": "true", "status": "rinsing", "course": "cotton", "smart_course": "cold_wash", "spin": "high", "temp": "none", "rinse": "1", "remaining_time": "10", "initial_time": "64", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "true", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// physical power-on changes the captured D8 heartbeat from 0 to 1
fn test_pr_180_11() {
    let d = device();
    d.feed("aa0720d800fcbb");
    expect_props(d, #{"power": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa0720d801ffbb");
    expect_props(d, #{"power": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// uses the current record in a real EB-to-EC power-off transition
fn test_pr_180_12() {
    let d = device();
    d.feed("aa5220ec0024050000000000000000000000000000020000020033010f000000000002022d1e000001000024000000000000000000000000000000020000020533010f000000000002022d1e00000100ddbb");
    expect_props(d, #{"power": "false", "status": "off", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa2c20eb0024000000000000000000000000000000020000020533010f000000000002022d1e00000100f4bb");
    expect_props(d, #{"power": "false", "status": "off", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// unknown changing tail bytes do not corrupt the grounded baseline
fn test_pr_180_13() {
    let d = device();
    d.feed("aa2c20eb0024050000000000000000000000000000020000000033310f000000000002022d1e000001009abb");
    expect_props(d, #{"power": "true", "status": "initial", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// ignores other AABB payload shapes
fn test_pr_180_14() {
    let d = device();
    d.feed("aa2c20eb0024050000000000000000000000000000020000010033010f000000000002022d1e00000100f5bb");
    expect_props(d, #{"power": "true", "status": "initial", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa083100240052bb");
    expect_props(d, #{"power": "true", "status": "initial", "course": "none", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// start sends only the captured read-only status query
fn test_pr_180_15() {
    let d = device();
    d.start();
    expect_eq(hex_encode(d.sent()[0]), "aa0ef0ed1121010000001800b5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write power_off reproduces the frame captured from a real remote power-off
fn test_pr_180_16() {
    let d = device();
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("power_off", "");
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240101009cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// remote_start heartbeat C8=OFF / C9=ON
fn test_pr_180_17() {
    let d = device();
    d.feed("aa09207200c80058bb");
    expect_props(d, #{"remote_start": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa09207200c9005bbb");
    expect_props(d, #{"remote_start": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write power=ON is refused: no ON command was ever captured
fn test_pr_180_18() {
    let d = device();
    d.set("power", "true");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write to an unknown property emits no packet
fn test_pr_180_19() {
    let d = device();
    d.set("nonsense", "true");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// decodes a real Start (rinse=1, spin=delicate, temp=60C) into Detecting
fn test_pr_180_20() {
    let d = device();
    d.feed("aa5220ec0024050021002107000204030200000020864000000033010f000000000002022d1e000001000024140032003207000201040100000020860000000533010f000000000002022d1e00000100b2bb");
    expect_props(d, #{"power": "true", "status": "sensing", "course": "cotton", "smart_course": "cold_wash", "spin": "very_low", "temp": "60", "rinse": "1", "remaining_time": "50", "initial_time": "50", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "true", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write pause reproduces the checksum-verified frame captured mid-run
fn test_pr_180_21() {
    let d = device();
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("pause", "");
    expect_eq(hex_encode(d.sent()[0]), "aa09f02404010099bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write resume with the default selection reproduces the captured Standard resume frame
fn test_pr_180_22() {
    let d = device();
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026070201040100002080000500000000000000000000dabb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write start_course with the default selection reproduces the captured Standard start frame
fn test_pr_180_23() {
    let d = device();
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026070201040100002080200500000000000000000000fabb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA smart-course selection and Start reproduce the separately captured Cold Wash commands
fn test_pr_180_24() {
    let d = device();
    d.set("smart_course_select", "cold_wash");
    expect_props(d, #{"course_select": "downloaded_course"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e0204010300000000000f330000000000000000001bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "19");
    expect_props(d, #{"course_select": "downloaded_course", "reserve_hours": "19"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "reserve_hours": "19", "smart_course": "cold_wash"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0204010313002000200f33000000000000000000ddbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// HA can select, download, and start every captured smart course
fn test_pr_180_25() {
    let d = device();
    d.set("smart_course_select", "cold_wash");
    expect_props(d, #{"course_select": "downloaded_course"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e0204010300000000000f330000000000000000001bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course": "cold_wash"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0204010300002000200f3300000000000000000020bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// HA can select, download, and start every captured smart course
fn test_pr_180_26() {
    let d = device();
    d.set("smart_course_select", "small_load");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "small_load"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e020300020000108000043400000000000000000084bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "small_load", "smart_course": "small_load"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0203000200003080200434000000000000000000adbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// HA can select, download, and start every captured smart course
fn test_pr_180_27() {
    let d = device();
    d.set("smart_course_select", "skin_care");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "skin_care"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e02040304000000800005350000000000000000009cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "skin_care", "smart_course": "skin_care"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0204030400002080200535000000000000000000a5bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// HA can select, download, and start every captured smart course
fn test_pr_180_28() {
    let d = device();
    d.set("smart_course_select", "rainy_day");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "rainy_day"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e02050302000000800005360000000000000000009cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "rainy_day", "smart_course": "rainy_day"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0205030200002080200536000000000000000000a5bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// HA can select, download, and start every captured smart course
fn test_pr_180_29() {
    let d = device();
    d.set("smart_course_select", "sweat_stain");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "sweat_stain"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e0303030300000000000e3700000000000000000006bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "sweat_stain", "smart_course": "sweat_stain"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0303030300002000200e370000000000000000002fbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// HA can select, download, and start every captured smart course
fn test_pr_180_30() {
    let d = device();
    d.set("smart_course_select", "single_garments");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "single_garments"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e020300010000108000043800000000000000000081bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "single_garments", "smart_course": "single_garments"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0203000100003080200438000000000000000000aebb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// HA can select, download, and start every captured smart course
fn test_pr_180_31() {
    let d = device();
    d.set("smart_course_select", "kids_wear");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "kids_wear"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e0303040400000000000e3900000000000000000002bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "kids_wear", "smart_course": "kids_wear"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0303040400002000200e390000000000000000002bbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// HA can select, download, and start every captured smart course
fn test_pr_180_32() {
    let d = device();
    d.set("smart_course_select", "shirt");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "shirt"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e0302040300000000000e3a00000000000000000003bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "shirt", "smart_course": "shirt"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0302040300002000200e3a00000000000000000028bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// HA can select, download, and start every captured smart course
fn test_pr_180_33() {
    let d = device();
    d.set("smart_course_select", "school_uniform");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "school_uniform"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e020303020000008000053b00000000000000000099bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "school_uniform", "smart_course": "school_uniform"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e020303020000208020053b000000000000000000a6bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// HA can select, download, and start every captured smart course
fn test_pr_180_34() {
    let d = device();
    d.set("smart_course_select", "static_reduce");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "static_reduce"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e020000000000100000013c00000000000000000004bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "static_reduce", "smart_course": "static_reduce"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e020000000000300020013c0000000000000000002dbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// HA can select, download, and start every captured smart course
fn test_pr_180_35() {
    let d = device();
    d.set("smart_course_select", "spin_only");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "spin_only"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e000300000000000000153f0000000000000000000cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "spin_only", "smart_course": "spin_only"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e000300000000200020153f000000000000000000d5bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// HA can select, download, and start every captured smart course
fn test_pr_180_36() {
    let d = device();
    d.set("smart_course_select", "deodorization");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "deodorization"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e020000000000100000014100000000000000000003bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "deodorization", "smart_course": "deodorization"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e020000000000300020014100000000000000000028bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// HA can select, download, and start every captured smart course
fn test_pr_180_37() {
    let d = device();
    d.set("smart_course_select", "cloth_care");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "cloth_care"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e020203030000000000084300000000000000000002bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "cloth_care", "smart_course": "cloth_care"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e02020303000020002008430000000000000000002bbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// HA can select, download, and start every captured smart course
fn test_pr_180_38() {
    let d = device();
    d.set("smart_course_select", "smart_rinse");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "smart_rinse"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e02040304000000800005440000000000000000008dbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "smart_rinse", "smart_course": "smart_rinse"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0204030400002080200544000000000000000000aabb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// smart-course Start with a 3-hour reservation reproduces the captured Cold Wash reserved-start frame
fn test_pr_180_39() {
    let d = device();
    d.set("smart_course_select", "cold_wash");
    expect_props(d, #{"course_select": "downloaded_course"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e0204010300000000000f330000000000000000001bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "downloaded_course", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "reserve_hours": "3", "smart_course": "cold_wash"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0204010303002000200f330000000000000000002dbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// smart-course Resume reproduces the captured Cold Wash resume frame (flag byte flipped)
fn test_pr_180_40() {
    let d = device();
    d.set("smart_course_select", "cold_wash");
    expect_props(d, #{"course_select": "downloaded_course"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e0204010300000000000f330000000000000000001bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course": "cold_wash"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0204010300002000000f3300000000000000000000bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// smart-course Resume works for every captured course, using the same start-frame-with-flag-flipped pattern
fn test_pr_180_41() {
    let d = device();
    d.set("smart_course_select", "small_load");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "small_load"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e020300020000108000043400000000000000000084bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "small_load", "smart_course": "small_load"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e02030002000030800004340000000000000000008dbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// smart-course Resume works for every captured course, using the same start-frame-with-flag-flipped pattern
fn test_pr_180_42() {
    let d = device();
    d.set("smart_course_select", "skin_care");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "skin_care"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e02040304000000800005350000000000000000009cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "skin_care", "smart_course": "skin_care"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e020403040000208000053500000000000000000085bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// smart-course Resume works for every captured course, using the same start-frame-with-flag-flipped pattern
fn test_pr_180_43() {
    let d = device();
    d.set("smart_course_select", "rainy_day");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "rainy_day"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e02050302000000800005360000000000000000009cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "rainy_day", "smart_course": "rainy_day"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e020503020000208000053600000000000000000085bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// smart-course Resume works for every captured course, using the same start-frame-with-flag-flipped pattern
fn test_pr_180_44() {
    let d = device();
    d.set("smart_course_select", "sweat_stain");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "sweat_stain"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e0303030300000000000e3700000000000000000006bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "sweat_stain", "smart_course": "sweat_stain"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0303030300002000000e370000000000000000000fbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// smart-course Resume works for every captured course, using the same start-frame-with-flag-flipped pattern
fn test_pr_180_45() {
    let d = device();
    d.set("smart_course_select", "single_garments");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "single_garments"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e020300010000108000043800000000000000000081bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "single_garments", "smart_course": "single_garments"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e02030001000030800004380000000000000000008ebb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// smart-course Resume works for every captured course, using the same start-frame-with-flag-flipped pattern
fn test_pr_180_46() {
    let d = device();
    d.set("smart_course_select", "kids_wear");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "kids_wear"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e0303040400000000000e3900000000000000000002bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "kids_wear", "smart_course": "kids_wear"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0303040400002000000e390000000000000000000bbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// smart-course Resume works for every captured course, using the same start-frame-with-flag-flipped pattern
fn test_pr_180_47() {
    let d = device();
    d.set("smart_course_select", "shirt");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "shirt"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e0302040300000000000e3a00000000000000000003bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "shirt", "smart_course": "shirt"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0302040300002000000e3a00000000000000000008bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// smart-course Resume works for every captured course, using the same start-frame-with-flag-flipped pattern
fn test_pr_180_48() {
    let d = device();
    d.set("smart_course_select", "school_uniform");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "school_uniform"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e020303020000008000053b00000000000000000099bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "school_uniform", "smart_course": "school_uniform"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e020303020000208000053b00000000000000000086bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// smart-course Resume works for every captured course, using the same start-frame-with-flag-flipped pattern
fn test_pr_180_49() {
    let d = device();
    d.set("smart_course_select", "static_reduce");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "static_reduce"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e020000000000100000013c00000000000000000004bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "static_reduce", "smart_course": "static_reduce"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e020000000000300000013c0000000000000000000dbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// smart-course Resume works for every captured course, using the same start-frame-with-flag-flipped pattern
fn test_pr_180_50() {
    let d = device();
    d.set("smart_course_select", "spin_only");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "spin_only"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e000300000000000000153f0000000000000000000cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "spin_only", "smart_course": "spin_only"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e000300000000200000153f00000000000000000035bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// smart-course Resume works for every captured course, using the same start-frame-with-flag-flipped pattern
fn test_pr_180_51() {
    let d = device();
    d.set("smart_course_select", "deodorization");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "deodorization"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e020000000000100000014100000000000000000003bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "deodorization", "smart_course": "deodorization"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e020000000000300000014100000000000000000008bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// smart-course Resume works for every captured course, using the same start-frame-with-flag-flipped pattern
fn test_pr_180_52() {
    let d = device();
    d.set("smart_course_select", "cloth_care");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "cloth_care"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e020203030000000000084300000000000000000002bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "cloth_care", "smart_course": "cloth_care"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e02020303000020000008430000000000000000000bbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// smart-course Resume works for every captured course, using the same start-frame-with-flag-flipped pattern
fn test_pr_180_53() {
    let d = device();
    d.set("smart_course_select", "smart_rinse");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "smart_rinse"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e02040304000000800005440000000000000000008dbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "smart_rinse", "smart_course": "smart_rinse"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e02040304000020800005440000000000000000008abb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// selecting a normal course after a smart course makes normal Start win again
fn test_pr_180_54() {
    let d = device();
    d.set("smart_course_select", "cold_wash");
    expect_props(d, #{"course_select": "downloaded_course"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e0204010300000000000f330000000000000000001bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "cotton");
    expect_props(d, #{"course_select": "cotton"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "cotton"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf026070201040100002080200500000000000000000000fabb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// course_select "Downloaded Course" routes Start course to the pre-selected smart course
fn test_pr_180_55() {
    let d = device();
    d.set("smart_course_select", "cold_wash");
    expect_props(d, #{"course_select": "downloaded_course"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e0204010300000000000f330000000000000000001bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "downloaded_course");
    expect_props(d, #{"course_select": "downloaded_course"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course": "cold_wash"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0204010300002000200f3300000000000000000020bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// selecting a smart course syncs course_select to "Downloaded Course"
fn test_pr_180_56() {
    let d = device();
    d.set("smart_course_select", "cold_wash");
    expect_props(d, #{"course_select": "downloaded_course"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e0204010300000000000f330000000000000000001bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Cold Wash Start with no reservation preserves the captured zero reserve byte
fn test_pr_180_57() {
    let d = device();
    d.set("smart_course_select", "cold_wash");
    expect_props(d, #{"course_select": "downloaded_course"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e0204010300000000000f330000000000000000001bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course": "cold_wash"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0204010300002000200f3300000000000000000020bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// Cold Wash Start at an intermediate reservation changes only the reserve byte
fn test_pr_180_58() {
    let d = device();
    d.set("smart_course_select", "cold_wash");
    expect_props(d, #{"course_select": "downloaded_course"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150e0204010300000000000f330000000000000000001bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "7");
    expect_props(d, #{"course_select": "downloaded_course", "reserve_hours": "7"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "reserve_hours": "7", "smart_course": "cold_wash"});
    expect_eq(hex_encode(d.sent()[1]), "aa1bf0260e0204010307002000200f3300000000000000000029bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// unknown smart-course input sends nothing and does not take over the normal course
fn test_pr_180_59() {
    let d = device();
    d.set("smart_course_select", "not_captured");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026070201040100002080200500000000000000000000fabb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write course_select then start_course reproduces the captured 19-hour Steam Refresh start
fn test_pr_180_60() {
    let d = device();
    d.set("course_select", "steam_refresh");
    expect_props(d, #{"course_select": "steam_refresh"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "19");
    expect_props(d, #{"course_select": "steam_refresh", "reserve_hours": "19"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "steam_refresh", "reserve_hours": "19"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf02601020000001300300020010000000000000000000017bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write reserve_hours then resume reproduces the captured 5-hour Steam Refresh resume
fn test_pr_180_61() {
    let d = device();
    d.set("course_select", "steam_refresh");
    expect_props(d, #{"course_select": "steam_refresh"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "5");
    expect_props(d, #{"course_select": "steam_refresh", "reserve_hours": "5"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("resume", "");
    expect_props(d, #{"course_select": "steam_refresh", "reserve_hours": "5"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf02601020000000500300000010000000000000000000041bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write course_select with an unknown course does not change the selection
fn test_pr_180_62() {
    let d = device();
    d.set("course_select", "download");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026070201040100002080200500000000000000000000fabb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write reserve_hours out of the model-declared 0 or 3-19 range is refused
fn test_pr_180_63() {
    let d = device();
    d.set("reserve_hours", "20");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026070201040100002080200500000000000000000000fabb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write reserve_hours=1 or 2 is refused: LG declares 0 or 3..19, not 1 or 2
fn test_pr_180_64() {
    let d = device();
    d.set("reserve_hours", "1");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026070201040100002080200500000000000000000000fabb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "2");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_eq(hex_encode(d.sent()[1]), "aa1bf026070201040100002080200500000000000000000000fabb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"reserve_hours": "3"});
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[2]), "aa1bf026070201040103002080200500000000000000000000e7bb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// decodes the captured Cold Wash reservation as a downloaded course
fn test_pr_180_65() {
    let d = device();
    d.feed("aa5220ec002414011401140e000204010300130020460000000533040f000000000002022d1e0000010000240a011001100e000204010300130020460000001433040f010000000002022d1e0000010077bb");
    expect_props(d, #{"course_select": "downloaded_course", "power": "true", "status": "reserved", "course": "downloaded_course", "smart_course": "cold_wash", "spin": "high", "temp": "cold", "rinse": "3", "remaining_time": "76", "initial_time": "76", "reserve_time": "1140", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// decodes a real 19-hour Steam Refresh reservation
fn test_pr_180_66() {
    let d = device();
    d.feed("aa5220ec002406002e002e07000201040100000020860000011733010f010000000002022d1e0000010000240a0014001401000200000000130030060000010633010f050000000000002d1e0000010079bb");
    expect_props(d, #{"power": "true", "status": "reserved", "course": "steam_refresh", "smart_course": "cold_wash", "spin": "no_spin", "temp": "none", "rinse": "0", "remaining_time": "20", "initial_time": "20", "reserve_time": "1140", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// decodes a real 3-hour reservation with 40C temperature after a full options change
fn test_pr_180_67() {
    let d = device();
    d.feed("aa5220ec0024140021002107000204030200030020864000020633010f000000000002022d1e0000010000240a0134013407000204030200030020c64000001433010f050000000002022d1e00000100c2bb");
    expect_props(d, #{"power": "true", "status": "reserved", "course": "cotton", "smart_course": "cold_wash", "spin": "high", "temp": "40", "rinse": "2", "remaining_time": "112", "initial_time": "112", "reserve_time": "180", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "true", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write spin_select/temperature_select/rinse_count then start_course reproduces the captured frame
fn test_pr_180_68() {
    let d = device();
    d.set("spin_select", "high");
    expect_props(d, #{"spin_select": "high"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "40");
    expect_props(d, #{"spin_select": "high", "temperature_select": "40"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "2");
    expect_props(d, #{"spin_select": "high", "temperature_select": "40", "rinse_count": "2"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"spin_select": "high", "temperature_select": "40", "rinse_count": "2", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"spin_select": "high", "temperature_select": "40", "rinse_count": "2", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026070204030203002080200500000000000000000000e0bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// spin/temperature/rinse writes are refused for a course without a captured options frame
fn test_pr_180_69() {
    let d = device();
    d.set("course_select", "steam_refresh");
    expect_props(d, #{"course_select": "steam_refresh"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "high");
    expect_props(d, #{"course_select": "steam_refresh", "spin_select": "high"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "40");
    expect_props(d, #{"course_select": "steam_refresh", "spin_select": "high", "temperature_select": "40"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "2");
    expect_props(d, #{"course_select": "steam_refresh", "spin_select": "high", "temperature_select": "40", "rinse_count": "2"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "steam_refresh", "spin_select": "high", "temperature_select": "40", "rinse_count": "2"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260102000000000030002001000000000000000000007abb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write spin_select with an unrecognised value is refused
fn test_pr_180_70() {
    let d = device();
    d.set("spin_select", "ultra_spin");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026070201040100002080200500000000000000000000fabb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write rinse_count out of the captured 0-5 range is refused
fn test_pr_180_71() {
    let d = device();
    d.set("rinse_count", "6");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026070201040100002080200500000000000000000000fabb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real 30C run (third temperature point)
fn test_pr_180_72() {
    let d = device();
    d.feed("aa5220ec002414002e002e07000202020300030020c60000000633010f000000000002022d1e0000010000240a0125012507000202020300030020c60000001433010f050000000002022d1e0000010018bb");
    expect_props(d, #{"power": "true", "status": "reserved", "course": "cotton", "smart_course": "cold_wash", "spin": "low", "temp": "30", "rinse": "3", "remaining_time": "97", "initial_time": "97", "reserve_time": "180", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "true", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write temperature_select=30 then start_course reproduces the captured 30C frame
fn test_pr_180_73() {
    let d = device();
    d.set("spin_select", "low");
    expect_props(d, #{"spin_select": "low"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "30");
    expect_props(d, #{"spin_select": "low", "temperature_select": "30"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "3");
    expect_props(d, #{"spin_select": "low", "temperature_select": "30", "rinse_count": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"spin_select": "low", "temperature_select": "30", "rinse_count": "3", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"spin_select": "low", "temperature_select": "30", "rinse_count": "3", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026070202020303002080200500000000000000000000e6bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real Cold-water run (fourth and final temperature point)
fn test_pr_180_74() {
    let d = device();
    d.feed("aa5220ec0024060125012507000202020300023920860000000a33010f050000000002022d1e000001000024140039003907000203010400030020c60000000633010f000000000002022d1e000001001bbb");
    expect_props(d, #{"power": "true", "status": "sensing", "course": "cotton", "smart_course": "cold_wash", "spin": "medium", "temp": "cold", "rinse": "4", "remaining_time": "57", "initial_time": "57", "reserve_time": "180", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "true", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write temperature_select=Cold then start_course reproduces the captured cold-water frame
fn test_pr_180_75() {
    let d = device();
    d.set("spin_select", "medium");
    expect_props(d, #{"spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "cold");
    expect_props(d, #{"spin_select": "medium", "temperature_select": "cold"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "4");
    expect_props(d, #{"spin_select": "medium", "temperature_select": "cold", "rinse_count": "4"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"spin_select": "medium", "temperature_select": "cold", "rinse_count": "4", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"spin_select": "medium", "temperature_select": "cold", "rinse_count": "4", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026070203010403002080200500000000000000000000e1bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real rinse=5/spin=Extra high run (last rinse count and spin code)
fn test_pr_180_76() {
    let d = device();
    d.feed("aa5220ec00240a0229022907000205040500030020c60000001433010f050000000002022d1e000001000024170229022907000205040500000020c60000000a33010f050000000002022d1e000001003dbb");
    expect_props(d, #{"power": "true", "status": "washing", "course": "cotton", "smart_course": "cold_wash", "spin": "extra_high", "temp": "60", "rinse": "5", "remaining_time": "161", "initial_time": "161", "reserve_time": "0", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "true", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write spin_select=Extra high, rinse_count=5 then start_course reproduces the captured frame
fn test_pr_180_77() {
    let d = device();
    d.set("spin_select", "extra_high");
    expect_props(d, #{"spin_select": "extra_high"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "60");
    expect_props(d, #{"spin_select": "extra_high"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "5");
    expect_props(d, #{"spin_select": "extra_high", "rinse_count": "5"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"spin_select": "extra_high", "rinse_count": "5", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"spin_select": "extra_high", "rinse_count": "5", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026070205040503002080200500000000000000000000efbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real rinse=0/spin=0 (both off) run
fn test_pr_180_78() {
    let d = device();
    d.feed("aa5220ec0024140010001007000200030000040020864000000633010f000000000002022d1e0000010000240a0109010907000200030000040020c64000001433010f050000000002022d1e0000010046bb");
    expect_props(d, #{"power": "true", "status": "reserved", "course": "cotton", "smart_course": "cold_wash", "spin": "no_spin", "temp": "40", "rinse": "0", "remaining_time": "69", "initial_time": "69", "reserve_time": "240", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "true", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write spin_select=None, rinse_count=0 then start_course reproduces the captured off/off frame
fn test_pr_180_79() {
    let d = device();
    d.set("spin_select", "no_spin");
    expect_props(d, #{"spin_select": "no_spin"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "40");
    expect_props(d, #{"spin_select": "no_spin", "temperature_select": "40"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "0");
    expect_props(d, #{"spin_select": "no_spin", "temperature_select": "40", "rinse_count": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "4");
    expect_props(d, #{"spin_select": "no_spin", "temperature_select": "40", "rinse_count": "0", "reserve_hours": "4"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"spin_select": "no_spin", "temperature_select": "40", "rinse_count": "0", "reserve_hours": "4"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026070200030004002080200500000000000000000000e5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real Quiet-course (course 9) run
fn test_pr_180_80() {
    let d = device();
    d.feed("aa5220ec0024060109010907000200030000033b20864000000a33010f050000000002022d1e00000100002414003b003b09000202030400030020460000000633010f000000000002022d1e0000010089bb");
    expect_props(d, #{"power": "true", "status": "sensing", "course": "quiet", "smart_course": "cold_wash", "spin": "low", "temp": "40", "rinse": "4", "remaining_time": "59", "initial_time": "59", "reserve_time": "180", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write course_select=Quiet with rinse/spin/temp reproduces the captured Quiet start frame
fn test_pr_180_81() {
    let d = device();
    d.set("course_select", "quiet");
    expect_props(d, #{"course_select": "quiet"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "low");
    expect_props(d, #{"course_select": "quiet", "spin_select": "low"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "40");
    expect_props(d, #{"course_select": "quiet", "spin_select": "low", "temperature_select": "40"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "4");
    expect_props(d, #{"course_select": "quiet", "spin_select": "low", "temperature_select": "40", "rinse_count": "4"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "quiet", "spin_select": "low", "temperature_select": "40", "rinse_count": "4", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "quiet", "spin_select": "low", "temperature_select": "40", "rinse_count": "4", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260902020304030020002007000000000000000000006cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a second real Quiet run with different rinse/spin/temp
fn test_pr_180_82() {
    let d = device();
    d.feed("aa5220ec0024060014001401000200000000000030060000001733010f050000000000002d1e000001000024140020002009000201040100030020060000000633010f000000000002022d1e00000100dcbb");
    expect_props(d, #{"power": "true", "status": "sensing", "course": "quiet", "smart_course": "cold_wash", "spin": "very_low", "temp": "60", "rinse": "1", "remaining_time": "32", "initial_time": "32", "reserve_time": "180", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write course_select=Quiet with a different rinse/spin/temp combo reproduces the second captured frame
fn test_pr_180_83() {
    let d = device();
    d.set("course_select", "quiet");
    expect_props(d, #{"course_select": "quiet"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "very_low");
    expect_props(d, #{"course_select": "quiet"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "60");
    expect_props(d, #{"course_select": "quiet"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "1");
    expect_props(d, #{"course_select": "quiet"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "quiet", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "quiet", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf02609020104010300200020070000000000000000000063bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real Speedwash (course 8) run with temperature unselectable
fn test_pr_180_84() {
    let d = device();
    d.feed("aa5220ec0024060106010609000201040100030020060000000a33010f010000000002022d1e00000100002414000f000f08000203000100030030c60000010633010f000000000002022d1e000001005abb");
    expect_props(d, #{"power": "true", "status": "sensing", "course": "speed_wash", "smart_course": "cold_wash", "spin": "medium", "temp": "none", "rinse": "1", "remaining_time": "15", "initial_time": "15", "reserve_time": "180", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "true", "steam": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write course_select=Speedwash with rinse/spin reproduces the captured Speedwash start frame
fn test_pr_180_85() {
    let d = device();
    d.set("course_select", "speed_wash");
    expect_props(d, #{"course_select": "speed_wash"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "medium");
    expect_props(d, #{"course_select": "speed_wash", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "1");
    expect_props(d, #{"course_select": "speed_wash", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "speed_wash", "spin_select": "medium", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "speed_wash", "spin_select": "medium", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf02608020300010300308020040000000000000000000095bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write temperature_select for Speedwash is ignored: temp has never been captured varying for it
fn test_pr_180_86() {
    let d = device();
    d.set("course_select", "speed_wash");
    expect_props(d, #{"course_select": "speed_wash"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "60");
    expect_props(d, #{"course_select": "speed_wash"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "medium");
    expect_props(d, #{"course_select": "speed_wash", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "1");
    expect_props(d, #{"course_select": "speed_wash", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "speed_wash", "spin_select": "medium", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "speed_wash", "spin_select": "medium", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf02608020300010300308020040000000000000000000095bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real Colorcare (course 10) run
fn test_pr_180_87() {
    let d = device();
    d.feed("aa5220ec002406000f000f08000203000100023a30860000000a33010f010000000002022d1e00000100002414010201020a000202020300030020060000010633010f000000000002022d1e0000010057bb");
    expect_props(d, #{"power": "true", "status": "sensing", "course": "colour_care", "smart_course": "cold_wash", "spin": "low", "temp": "30", "rinse": "3", "remaining_time": "62", "initial_time": "62", "reserve_time": "180", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write course_select=Colorcare with rinse/spin/temp reproduces the captured Colorcare start frame
fn test_pr_180_88() {
    let d = device();
    d.set("course_select", "colour_care");
    expect_props(d, #{"course_select": "colour_care"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "low");
    expect_props(d, #{"course_select": "colour_care", "spin_select": "low"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "30");
    expect_props(d, #{"course_select": "colour_care", "spin_select": "low", "temperature_select": "30"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "3");
    expect_props(d, #{"course_select": "colour_care", "spin_select": "low", "temperature_select": "30", "rinse_count": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "colour_care", "spin_select": "low", "temperature_select": "30", "rinse_count": "3", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "colour_care", "spin_select": "low", "temperature_select": "30", "rinse_count": "3", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260a020202030300200020100000000000000000000014bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write temperature_select=60 for Colorcare is ignored: 60C is outside its captured Cold/30/40 whitelist
fn test_pr_180_89() {
    let d = device();
    d.set("course_select", "colour_care");
    expect_props(d, #{"course_select": "colour_care"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "60");
    expect_props(d, #{"course_select": "colour_care"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "low");
    expect_props(d, #{"course_select": "colour_care", "spin_select": "low"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "3");
    expect_props(d, #{"course_select": "colour_care", "spin_select": "low", "rinse_count": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "colour_care", "spin_select": "low", "rinse_count": "3", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "colour_care", "spin_select": "low", "rinse_count": "3", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260a020202030300200020100000000000000000000014bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real Rinse+Spin (course 13) run with temperature fixed off
fn test_pr_180_90() {
    let d = device();
    d.feed("aa5220ec002406003b003b0a000202020300023b20060000000a33010f010000000002022d1e0000010000240a001300130d000003000100030020460000000633010f050000000000022d1e0000010073bb");
    expect_props(d, #{"power": "true", "status": "reserved", "course": "rinse_spin", "smart_course": "cold_wash", "spin": "medium", "temp": "none", "rinse": "1", "remaining_time": "19", "initial_time": "19", "reserve_time": "180", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write course_select=Rinse+Spin with rinse/spin reproduces the captured Rinse+Spin start frame
fn test_pr_180_91() {
    let d = device();
    d.set("course_select", "rinse_spin");
    expect_props(d, #{"course_select": "rinse_spin"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "medium");
    expect_props(d, #{"course_select": "rinse_spin", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "1");
    expect_props(d, #{"course_select": "rinse_spin", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "rinse_spin", "spin_select": "medium", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "rinse_spin", "spin_select": "medium", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260d000300010300200020110000000000000000000015bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write rinse_count=0/spin_select=None for Rinse+Spin are both ignored: this course has no off value
fn test_pr_180_92() {
    let d = device();
    d.set("course_select", "rinse_spin");
    expect_props(d, #{"course_select": "rinse_spin"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "0");
    expect_props(d, #{"course_select": "rinse_spin", "rinse_count": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "no_spin");
    expect_props(d, #{"course_select": "rinse_spin", "rinse_count": "0", "spin_select": "no_spin"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "rinse_spin", "rinse_count": "0", "spin_select": "no_spin", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "rinse_spin", "rinse_count": "0", "spin_select": "no_spin", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260d000300010300200020110000000000000000000015bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real Speedboil (course 4) run with a new 95C temperature point
fn test_pr_180_93() {
    let d = device();
    d.feed("aa5220ec002406001300130d000003000100023a20060000000a33010f050000000000022d1e000001000024140227022704000203050300030020060000000633010f000000000002022d1e000001009dbb");
    expect_props(d, #{"power": "true", "status": "sensing", "course": "economy_boil", "smart_course": "cold_wash", "spin": "medium", "temp": "95", "rinse": "3", "remaining_time": "159", "initial_time": "159", "reserve_time": "180", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write course_select=Speedboil with rinse/spin reproduces the captured Speedboil start frame
fn test_pr_180_94() {
    let d = device();
    d.set("course_select", "economy_boil");
    expect_props(d, #{"course_select": "economy_boil"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "medium");
    expect_props(d, #{"course_select": "economy_boil", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "3");
    expect_props(d, #{"course_select": "economy_boil", "spin_select": "medium", "rinse_count": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "economy_boil", "spin_select": "medium", "rinse_count": "3", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "economy_boil", "spin_select": "medium", "rinse_count": "3", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026040203050303002000200d0000000000000000000069bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write temperature_select for Speedboil is ignored: 95C cannot be changed for this course
fn test_pr_180_95() {
    let d = device();
    d.set("course_select", "economy_boil");
    expect_props(d, #{"course_select": "economy_boil"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "30");
    expect_props(d, #{"course_select": "economy_boil", "temperature_select": "30"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "medium");
    expect_props(d, #{"course_select": "economy_boil", "temperature_select": "30", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "3");
    expect_props(d, #{"course_select": "economy_boil", "temperature_select": "30", "spin_select": "medium", "rinse_count": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "economy_boil", "temperature_select": "30", "spin_select": "medium", "rinse_count": "3", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "economy_boil", "temperature_select": "30", "spin_select": "medium", "rinse_count": "3", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026040203050303002000200d0000000000000000000069bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real Babywear (course 5) run with temperature fixed off
fn test_pr_180_96() {
    let d = device();
    d.feed("aa5220ec0024060224022404000203050300000020060000001733010f010000000002022d1e000001000024140123012305000203000400040030060000000633010f000000000002022d1e0000010094bb");
    expect_props(d, #{"power": "true", "status": "sensing", "course": "baby_wear", "smart_course": "cold_wash", "spin": "medium", "temp": "none", "rinse": "4", "remaining_time": "95", "initial_time": "95", "reserve_time": "240", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write course_select=Babywear with rinse/spin reproduces the captured Babywear start frame
fn test_pr_180_97() {
    let d = device();
    d.set("course_select", "baby_wear");
    expect_props(d, #{"course_select": "baby_wear"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "medium");
    expect_props(d, #{"course_select": "baby_wear", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "4");
    expect_props(d, #{"course_select": "baby_wear", "spin_select": "medium", "rinse_count": "4"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "4");
    expect_props(d, #{"course_select": "baby_wear", "spin_select": "medium", "rinse_count": "4", "reserve_hours": "4"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "baby_wear", "spin_select": "medium", "rinse_count": "4", "reserve_hours": "4"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026050203000404003000200b000000000000000000001dbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write temperature_select for Babywear is ignored: temperature is fixed off for this course
fn test_pr_180_98() {
    let d = device();
    d.set("course_select", "baby_wear");
    expect_props(d, #{"course_select": "baby_wear"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "30");
    expect_props(d, #{"course_select": "baby_wear", "temperature_select": "30"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "medium");
    expect_props(d, #{"course_select": "baby_wear", "temperature_select": "30", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "4");
    expect_props(d, #{"course_select": "baby_wear", "temperature_select": "30", "spin_select": "medium", "rinse_count": "4"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "4");
    expect_props(d, #{"course_select": "baby_wear", "temperature_select": "30", "spin_select": "medium", "rinse_count": "4", "reserve_hours": "4"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "baby_wear", "temperature_select": "30", "spin_select": "medium", "rinse_count": "4", "reserve_hours": "4"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026050203000404003000200b000000000000000000001dbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real Allergy Care (course 2) run with temperature fixed off
fn test_pr_180_99() {
    let d = device();
    d.feed("aa5220ec0024060120012005000203000400040030060000000a33010f010000000002022d1e000001000024140123012302000203000400030030060000000633010f000000000002022d1e00000100e2bb");
    expect_props(d, #{"power": "true", "status": "sensing", "course": "allergy_care", "smart_course": "cold_wash", "spin": "medium", "temp": "none", "rinse": "4", "remaining_time": "95", "initial_time": "95", "reserve_time": "180", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write course_select=Allergy Care with rinse/spin reproduces the captured Allergy Care start frame
fn test_pr_180_100() {
    let d = device();
    d.set("course_select", "allergy_care");
    expect_props(d, #{"course_select": "allergy_care"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "medium");
    expect_props(d, #{"course_select": "allergy_care", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "4");
    expect_props(d, #{"course_select": "allergy_care", "spin_select": "medium", "rinse_count": "4"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "allergy_care", "spin_select": "medium", "rinse_count": "4", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "allergy_care", "spin_select": "medium", "rinse_count": "4", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260202030004030030002002000000000000000000006ebb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write temperature_select for Allergy Care is ignored: temperature is fixed off for this course
fn test_pr_180_101() {
    let d = device();
    d.set("course_select", "allergy_care");
    expect_props(d, #{"course_select": "allergy_care"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "30");
    expect_props(d, #{"course_select": "allergy_care", "temperature_select": "30"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "medium");
    expect_props(d, #{"course_select": "allergy_care", "temperature_select": "30", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "4");
    expect_props(d, #{"course_select": "allergy_care", "temperature_select": "30", "spin_select": "medium", "rinse_count": "4"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "allergy_care", "temperature_select": "30", "spin_select": "medium", "rinse_count": "4", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "allergy_care", "temperature_select": "30", "spin_select": "medium", "rinse_count": "4", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260202030004030030002002000000000000000000006ebb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real Heavy Duty (course 6) run
fn test_pr_180_102() {
    let d = device();
    d.feed("aa5220ec0024060120012002000203000400030030060000000a33010f010000000002022d1e00000100002414012f012f06000303040300040020060000000633010f000000000002022d1e0000010091bb");
    expect_props(d, #{"power": "true", "status": "sensing", "course": "heavy_duty", "smart_course": "cold_wash", "spin": "medium", "temp": "60", "rinse": "3", "remaining_time": "107", "initial_time": "107", "reserve_time": "240", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write course_select=Heavy Duty with rinse/spin/temp reproduces the captured Heavy Duty start frame
fn test_pr_180_103() {
    let d = device();
    d.set("course_select", "heavy_duty");
    expect_props(d, #{"course_select": "heavy_duty"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "medium");
    expect_props(d, #{"course_select": "heavy_duty", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "60");
    expect_props(d, #{"course_select": "heavy_duty", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "3");
    expect_props(d, #{"course_select": "heavy_duty", "spin_select": "medium", "rinse_count": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "4");
    expect_props(d, #{"course_select": "heavy_duty", "spin_select": "medium", "rinse_count": "3", "reserve_hours": "4"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "heavy_duty", "spin_select": "medium", "rinse_count": "3", "reserve_hours": "4"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026060303040304002000200e0000000000000000000015bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write temperature_select=Cold for Heavy Duty is ignored: outside its captured 40/60 whitelist
fn test_pr_180_104() {
    let d = device();
    d.set("course_select", "heavy_duty");
    expect_props(d, #{"course_select": "heavy_duty"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "cold");
    expect_props(d, #{"course_select": "heavy_duty", "temperature_select": "cold"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "medium");
    expect_props(d, #{"course_select": "heavy_duty", "temperature_select": "cold", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "3");
    expect_props(d, #{"course_select": "heavy_duty", "temperature_select": "cold", "spin_select": "medium", "rinse_count": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "4");
    expect_props(d, #{"course_select": "heavy_duty", "temperature_select": "cold", "spin_select": "medium", "rinse_count": "3", "reserve_hours": "4"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "heavy_duty", "temperature_select": "cold", "spin_select": "medium", "rinse_count": "3", "reserve_hours": "4"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf026060303040304002000200e0000000000000000000015bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real Functional Wear (course 3) run with restricted spin options
fn test_pr_180_105() {
    let d = device();
    d.feed("aa5220ec002406012c012c06000303040300040020060000000a33010f010000000002022d1e000001000024140109010903000201000300030030060000000633010f000000000000002d1e00000100dfbb");
    expect_props(d, #{"power": "true", "status": "sensing", "course": "functional_wear", "smart_course": "cold_wash", "spin": "very_low", "temp": "none", "rinse": "3", "remaining_time": "69", "initial_time": "69", "reserve_time": "180", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write course_select=Functional Wear with rinse/spin reproduces the captured Functional Wear start frame
fn test_pr_180_106() {
    let d = device();
    d.set("course_select", "functional_wear");
    expect_props(d, #{"course_select": "functional_wear"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "very_low");
    expect_props(d, #{"course_select": "functional_wear"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "3");
    expect_props(d, #{"course_select": "functional_wear", "rinse_count": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "functional_wear", "rinse_count": "3", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "functional_wear", "rinse_count": "3", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260302010003030030002003000000000000000000006fbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write spin_select=Medium/temperature_select for Functional Wear are both ignored: outside their whitelists
fn test_pr_180_107() {
    let d = device();
    d.set("course_select", "functional_wear");
    expect_props(d, #{"course_select": "functional_wear"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "medium");
    expect_props(d, #{"course_select": "functional_wear", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "30");
    expect_props(d, #{"course_select": "functional_wear", "spin_select": "medium", "temperature_select": "30"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "3");
    expect_props(d, #{"course_select": "functional_wear", "spin_select": "medium", "temperature_select": "30", "rinse_count": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "functional_wear", "spin_select": "medium", "temperature_select": "30", "rinse_count": "3", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "functional_wear", "spin_select": "medium", "temperature_select": "30", "rinse_count": "3", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260302010003030030002003000000000000000000006fbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real Duvet (course 11) run with restricted spin/temp options
fn test_pr_180_108() {
    let d = device();
    d.feed("aa5220ec0024060106010603000201000300030030060000000a33010f010000000000002d1e00000100002414013401340b000203010400030020060000000633010f000000000002022d1e00000100c0bb");
    expect_props(d, #{"power": "true", "status": "sensing", "course": "duvet", "smart_course": "cold_wash", "spin": "medium", "temp": "cold", "rinse": "4", "remaining_time": "112", "initial_time": "112", "reserve_time": "180", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write course_select=Duvet with rinse/spin/temp reproduces the captured Duvet start frame
fn test_pr_180_109() {
    let d = device();
    d.set("course_select", "duvet");
    expect_props(d, #{"course_select": "duvet"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "medium");
    expect_props(d, #{"course_select": "duvet", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "cold");
    expect_props(d, #{"course_select": "duvet", "spin_select": "medium", "temperature_select": "cold"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "4");
    expect_props(d, #{"course_select": "duvet", "spin_select": "medium", "temperature_select": "cold", "rinse_count": "4"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "duvet", "spin_select": "medium", "temperature_select": "cold", "rinse_count": "4", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "duvet", "spin_select": "medium", "temperature_select": "cold", "rinse_count": "4", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260b020301040300200020090000000000000000000069bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write spin_select=High/temperature_select=60 for Duvet are both ignored: outside their whitelists
fn test_pr_180_110() {
    let d = device();
    d.set("course_select", "duvet");
    expect_props(d, #{"course_select": "duvet"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "high");
    expect_props(d, #{"course_select": "duvet", "spin_select": "high"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "60");
    expect_props(d, #{"course_select": "duvet", "spin_select": "high"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "4");
    expect_props(d, #{"course_select": "duvet", "spin_select": "high", "rinse_count": "4"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "duvet", "spin_select": "high", "rinse_count": "4", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "duvet", "spin_select": "high", "rinse_count": "4", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260b020301040300200020090000000000000000000069bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real Lingerie/Wool (course 12) run with restricted spin/temp options
fn test_pr_180_111() {
    let d = device();
    d.feed("aa5220ec002406013401340b000203010400030020060000001433010f000000000002022d1e00000100002414003600360c000202010300040020060000000633010f000000000000002d1e00000100adbb");
    expect_props(d, #{"power": "true", "status": "sensing", "course": "lingerie_wool", "smart_course": "cold_wash", "spin": "low", "temp": "cold", "rinse": "3", "remaining_time": "54", "initial_time": "54", "reserve_time": "240", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write course_select=Lingerie/Wool with rinse/spin/temp reproduces the captured Lingerie/Wool start frame
fn test_pr_180_112() {
    let d = device();
    d.set("course_select", "lingerie_wool");
    expect_props(d, #{"course_select": "lingerie_wool"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "low");
    expect_props(d, #{"course_select": "lingerie_wool", "spin_select": "low"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "cold");
    expect_props(d, #{"course_select": "lingerie_wool", "spin_select": "low", "temperature_select": "cold"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "3");
    expect_props(d, #{"course_select": "lingerie_wool", "spin_select": "low", "temperature_select": "cold", "rinse_count": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "4");
    expect_props(d, #{"course_select": "lingerie_wool", "spin_select": "low", "temperature_select": "cold", "rinse_count": "3", "reserve_hours": "4"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "lingerie_wool", "spin_select": "low", "temperature_select": "cold", "rinse_count": "3", "reserve_hours": "4"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260c02020103040020002008000000000000000000006ebb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write spin_select=Medium/temperature_select=60 for Lingerie/Wool are both ignored: outside their whitelists
fn test_pr_180_113() {
    let d = device();
    d.set("course_select", "lingerie_wool");
    expect_props(d, #{"course_select": "lingerie_wool"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "medium");
    expect_props(d, #{"course_select": "lingerie_wool", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "60");
    expect_props(d, #{"course_select": "lingerie_wool", "spin_select": "medium"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "3");
    expect_props(d, #{"course_select": "lingerie_wool", "spin_select": "medium", "rinse_count": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "4");
    expect_props(d, #{"course_select": "lingerie_wool", "spin_select": "medium", "rinse_count": "3", "reserve_hours": "4"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "lingerie_wool", "spin_select": "medium", "rinse_count": "3", "reserve_hours": "4"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260c02020103040020002008000000000000000000006ebb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// decodes a real Tub Clean (course 15) run with all options fixed
fn test_pr_180_114() {
    let d = device();
    d.feed("aa5220ec002406003100310c000202010300033720060000010a33010f010000000000002d1e00000100002414020902090f000203040200030020060000020633010f000000000000002d1e000001009ebb");
    expect_props(d, #{"power": "true", "status": "sensing", "course": "tub_clean", "smart_course": "cold_wash", "spin": "medium", "temp": "60", "rinse": "2", "remaining_time": "129", "initial_time": "129", "reserve_time": "180", "error": "false", "error_message": "OK", "smart_diagnosis": "false", "child_lock": "false", "turbo_shot": "false", "steam": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// HA write course_select=Tub Clean reproduces the captured Tub Clean start frame
fn test_pr_180_115() {
    let d = device();
    d.set("course_select", "tub_clean");
    expect_props(d, #{"course_select": "tub_clean"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "tub_clean", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "tub_clean", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260f0203040203002000200a0000000000000000000017bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// HA write rinse/spin/temp for Tub Clean are all ignored: all fields fixed
fn test_pr_180_116() {
    let d = device();
    d.set("course_select", "tub_clean");
    expect_props(d, #{"course_select": "tub_clean"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("rinse_count", "5");
    expect_props(d, #{"course_select": "tub_clean", "rinse_count": "5"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("spin_select", "extra_high");
    expect_props(d, #{"course_select": "tub_clean", "rinse_count": "5", "spin_select": "extra_high"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("temperature_select", "cold");
    expect_props(d, #{"course_select": "tub_clean", "rinse_count": "5", "spin_select": "extra_high", "temperature_select": "cold"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "tub_clean", "rinse_count": "5", "spin_select": "extra_high", "temperature_select": "cold", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    // Wire comparison assumes remote permission; gating has separate negative tests.
    d.feed(a::framed([0x20,0x72,0,0xc9,0]));
    d.set("start_course", "");
    expect_props(d, #{"course_select": "tub_clean", "rinse_count": "5", "spin_select": "extra_high", "temperature_select": "cold", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa1bf0260f0203040203002000200a0000000000000000000017bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// publishes this-cycle energy (Wh) from detailed telemetry frames
fn test_pr_180_117() {
    let d = device();
    d.feed("aa0020bd000201900103011701280209000005000202000504000520c60000000400000000000050043d3e3f3a381d1d1d1c1ce8e7e6e6e7099609960996099609960aff0aff0aff0aff0aff00360036003600360036848484848498270000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fd00000000000000070000010000017a02abe3e301000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a200000000000000000000000000000000000000000000000000000000000068bb");
    expect_props(d, #{"energy": "80"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa0020cd00019001030128000202090000050000000000040005208600000004000000000000da04474849494a1d1d1d1d1dffffffffff099609960996099609960aff0aff0aff0aff0aff00360036003600360036848484848497dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003012c0300000000030000000384017a02a1ffe1040001010000ffff010f3104045a0000000c2911006917310402e7000000081708002309310402ce0000000d2107003c06310402780000000c0c05002608310403070000000c0a06001f05310402440000000b180700370e32020264000000071d05005a0d32020288000000041c0600520a320202be000000050f030028073402009c000000021508004007340200aa00000011140c002001340200d4000000091c0700450932020260000000060c01001c07310402ab0000000718050025073104034d00000004140700240702ee02ee0900000000a2000000000000000000000000000000000000000000000000000000000000fabb");
    expect_props(d, #{"energy": "218"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa0020bd0003019001030128000102090000050000000000000005000600000004000000000000dd014b460000001d1d000000ffff000000099609960000000000000aff0aff0000000000000036003600000000000084840000009895000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003012c0300000000030000000384017a028affe1040001010000ffff010f3104045a0000000c2911006917310402e7000000081708002309310402ce0000000d2107003c06310402780000000c0c05002608310403070000000c0a06001f05310402440000000b180700370e32020264000000071d05005a0d32020288000000041c0600520a320202be000000050f030028073402009c000000021508004007340200aa00000011140c002001340200d4000000091c0700450932020260000000060c01001c07310402ab0000000718050025073104034d00000004140700240702ee02ee0a00000000a20000000000000000000000000000000000000000000000000000000000004503010100040506033900000100ff014b00000000011c1c01041d1c000f03fd4b4a0000fdfd000000fd00000806070700000f000550200002640000c0425288595f011a180059bb");
    expect_props(d, #{"energy": "221"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// leaves energy untouched on frames without a validated energy layout
fn test_pr_180_118() {
    let d = device();
    d.feed("aa0020bd000201900103011701280209000005000202000504000520c60000000400000000000050043d3e3f3a381d1d1d1c1ce8e7e6e6e7099609960996099609960aff0aff0aff0aff0aff00360036003600360036848484848498270000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fd00000000000000070000010000017a02abe3e301000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a200000000000000000000000000000000000000000000000000000000000068bb");
    expect_props(d, #{"energy": "80"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa2c20e20324140106010607000204020500000020860000dd0533040f000000000002022d1e0000010006bb");
    expect_props(d, #{"energy": "80"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// Existing remote interlock also applies to the extended record and new aliases.
fn test_new_record_keeps_remote_interlock_and_common_fields() {
 let d=device();d.start();
 d.feed("aa2c20eb0024050000000000000000000000000000020000010033010f000000000002022d1e00000100f5bb");
 let doc=runtime::descriptor(d);
 for key in ["start","start_course","resume","pause","power_off"] {expect_eq(doc.props[key].requires,"remote_start");}
 expect_eq(d.property("remote_start"),"false");
 let n=d.sent().len();
 for key in ["start","start_course","resume","pause","power_off"] {d.set(key,"");}
 expect_eq(d.sent().len(),n);expect_eq(d.script_error(),());
}
fn test_valid_empty_envelope_does_not_decode_as_status() {
 let d=device();d.feed("aa00ffbb");expect_eq(d.script_error(),());
}

// Independent user capture, 2026-10-09 KST; SHA-256 in docs/pr-conflicts.md.
// All 92 monitoring + 20 diagnostic reports, in received order. PR #180's
// one-byte decoder fails all 20 diagnostics; these expectations include >255 Wh.
fn test_user_capture_preserves_full_width_energy_across_all_reports() {
 let d=device();
 d.feed("aa4e20ec00221701110224040002030503000000200600061f1439030e0100000000000402022d1e0022170110022404000203050300000020060006211439030e0100000000000402022d1e56bb");expect_eq(d.property("energy"),"1569");
 d.feed("aa4e20ec0022170110022404000203050300000020060006211439030e0100000000000402022d1e002217010f022404000203050300000020060006231439030e0100000000000402022d1e50bb");expect_eq(d.property("energy"),"1571");
 d.feed("aa4e20ec002217010f022404000203050300000020060006231439030e0100000000000402022d1e002217010e022404000203050300000020060006251439030e0100000000000402022d1e52bb");expect_eq(d.property("energy"),"1573");
 d.feed("aa4e20ec002217010e022404000203050300000020060006251439030e0100000000000402022d1e002217010d022404000203050300000020060006271439030e0100000000000402022d1e5cbb");expect_eq(d.property("energy"),"1575");
 d.feed("aa4e20ec002217010d022404000203050300000020060006271439030e0100000000000402022d1e002217010c022404000203050300000020060006291439030e0100000000000402022d1e5ebb");expect_eq(d.property("energy"),"1577");
 d.feed("aa0020cd00019001030117010c022400000d0002050003030001200600000003000000000006290455555556574e4e4d4d4decececebec08c308c708c608c608c606f306e006e006e006e000a000a800a600a600a68989898989933300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100620300000000070000000300017802eaffea03003901000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a2000000000000000000000000000000000000000000000000000000000000c2bb");expect_eq(d.property("energy"),"1577");
 d.feed("aa4e20ec002217010c022404000203050300000020060006291439030e0100000000000402022d1e002217010b0224040002030503000000200600062b1439030e0100000000000402022d1e58bb");expect_eq(d.property("energy"),"1579");
 d.feed("aa4e20ec002217010b0224040002030503000000200600062b1439030e0100000000000402022d1e002217010a0224040002030503000000200600062e1439030e0100000000000402022d1e45bb");expect_eq(d.property("energy"),"1582");
 d.feed("aa4e20ec002217010a0224040002030503000000200600062e1439030e0100000000000402022d1e0022170109022404000203050300000020060006301439030e0100000000000402022d1e46bb");expect_eq(d.property("energy"),"1584");
 d.feed("aa4e20ec0022170109022404000203050300000020060006301439030e0100000000000402022d1e0022170108022404000203050300000020060006321439030e0100000000000402022d1e40bb");expect_eq(d.property("energy"),"1586");
 d.feed("aa4e20ec0022170108022404000203050300000020060006321439030e0100000000000402022d1e0022170107022404000203050300000020060006331439030e0100000000000402022d1e43bb");expect_eq(d.property("energy"),"1587");
 d.feed("aa0020cd000190010301170107022400000d0002050003030001200600000003000000000006330457585857574c4c4b4b4bececedebed08c608c608c608c608c606e006e006e006e006e000a600a600a600a600a689898989899b2600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100620300000000070000000300017802eeffea03003901000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a2000000000000000000000000000000000000000000000000000000000000dabb");expect_eq(d.property("energy"),"1587");
 d.feed("aa4e20ec0022170107022404000203050300000020060006331439030e0100000000000402022d1e0022170106022404000203050300000020060006341439030e0100000000000402022d1e43bb");expect_eq(d.property("energy"),"1588");
 d.feed("aa4e20ec0022170106022404000203050300000020060006341439030e0100000000000402022d1e0022170105022404000203050300000020060006351439030e0100000000000402022d1e43bb");expect_eq(d.property("energy"),"1589");
 d.feed("aa4e20ec0022170105022404000203050300000020060006351439030e0100000000000402022d1e0022170104022404000203050300000020060006361439030e0100000000000402022d1e43bb");expect_eq(d.property("energy"),"1590");
 d.feed("aa4e20ec0022170104022404000203050300000020060006361439030e0100000000000402022d1e0022170103022404000203050300000020060006371439030e0100000000000402022d1e43bb");expect_eq(d.property("energy"),"1591");
 d.feed("aa4e20ec0022170103022404000203050300000020060006371439030e0100000000000402022d1e00221701020224040002030503000000200600063a1439030e0100000000000402022d1e4dbb");expect_eq(d.property("energy"),"1594");
 d.feed("aa0020cd000190010301170102022400000d00020500030300012006000000030000000000063a0454545352524a4a494948ecebecebeb08c608c608c608c608c606e006e006e006e006e000a600a600a600a600a689898989898c6200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100620300000000070000000300017802dfffea03003902000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a2000000000000000000000000000000000000000000000000000000000000debb");expect_eq(d.property("energy"),"1594");
 d.feed("aa4e20ec00221701020224040002030503000000200600063a1439030e0100000000000402022d1e0022170101022404000203050300000020060006551439030e0100000000000402022d1e61bb");expect_eq(d.property("energy"),"1621");
 d.feed("aa4e20ec0022170101022404000203050300000020060006551439030e0100000000000402022d1e00221701000224040002030503000000200600066f1439030e0100000000000402022d1e32bb");expect_eq(d.property("energy"),"1647");
 d.feed("aa4e20ec00221701000224040002030503000000200600066f1439030e0100000000000402022d1e002217003b0224040002030503000000200600068a1439030e0100000000000402022d1e80bb");expect_eq(d.property("energy"),"1674");
 d.feed("aa4e20ec002217003b0224040002030503000000200600068a1439030e0100000000000402022d1e002217003a022404000203050300000020060006a51439030e0100000000000402022d1e11bb");expect_eq(d.property("energy"),"1701");
 d.feed("aa4e20ec002217003a022404000203050300000020060006a51439030e0100000000000402022d1e0022170039022404000203050300000020060006bf1439030e0100000000000402022d1e22bb");expect_eq(d.property("energy"),"1727");
 d.feed("aa0020cd000190010301170039022400000d0002050003030001200600000003000000000006c00451505251504d5051524fecebebecea08c608c608c608c608c606e006e006e006e006e000a600a600a600a600a68989898989985700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100620300000000070000000300017802e6ffea03003e02000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a20000000000000000000000000000000000000000000000000000000000003cbb");expect_eq(d.property("energy"),"1728");
 d.feed("aa4e20ec0022170039022404000203050300000020060006bf1439030e0100000000000402022d1e0022170038022404000203050300000020060006db1439030e0100000000000402022d1efebb");expect_eq(d.property("energy"),"1755");
 d.feed("aa4e20ec0022170038022404000203050300000020060006db1439030e0100000000000402022d1e0022170037022404000203050300000020060006f51439030e0100000000000402022d1e8abb");expect_eq(d.property("energy"),"1781");
 d.feed("aa4e20ec0022170037022404000203050300000020060006f51439030e0100000000000402022d1e0022170036022404000203050300000020060007101439030e0100000000000402022d1e46bb");expect_eq(d.property("energy"),"1808");
 d.feed("aa4e20ec0022170036022404000203050300000020060007101439030e0100000000000402022d1e00221700350224040002030503000000200600072b1439030e0100000000000402022d1e1dbb");expect_eq(d.property("energy"),"1835");
 d.feed("aa4e20ec00221700350224040002030503000000200600072b1439030e0100000000000402022d1e00221700340224040002030503000000200600072c1439030e0100000000000402022d1e37bb");expect_eq(d.property("energy"),"1836");
 d.feed("aa0020cd000190010301170034022400000d00020500030300012006000000030000000000072c0451514f504f5253545535eaebeaeae608c608c608c608c608c606e006e006e006e006e000a600a600a600a600a6898989898699d700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100620300000000070000000300017802e9ffea03004202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a200000000000000000000000000000000000000000000000000000000000068bb");expect_eq(d.property("energy"),"1836");
 d.feed("aa4e20ec00221700340224040002030503000000200600072c1439030e0100000000000402022d1e00221700340224040002030503000000204600072d1439030e0100000000000402022d1ef6bb");expect_eq(d.property("energy"),"1837");
 d.feed("aa4e20ec00221700340224040002030503000000204600072d1439030e0100000000000402022d1e00221700330224040002030503000000204600072d1439030e0100000000000402022d1eb6bb");expect_eq(d.property("energy"),"1837");
 d.feed("aa4e20ec00221700330224040002030503000000204600072d1439030e0100000000000402022d1e00221700330224040002030503000000200600072d1439030e0100000000000402022d1ef7bb");expect_eq(d.property("energy"),"1837");
 d.feed("aa4e20ec00221700330224040002030503000000200600072d1439030e0100000000000402022d1e00221700320224040002030503000000200600072e1439030e0100000000000402022d1e37bb");expect_eq(d.property("energy"),"1838");
 d.feed("aa4e20ec00221700320224040002030503000000200600072e1439030e0100000000000402022d1e00221700310224040002030503000000200600072f1439030e0100000000000402022d1e37bb");expect_eq(d.property("energy"),"1839");
 d.feed("aa4e20ec00221700310224040002030503000000200600072f1439030e0100000000000402022d1e00221700310224040002030503000000204600072f1439030e0100000000000402022d1ef7bb");expect_eq(d.property("energy"),"1839");
 d.feed("aa4e20ec00221700310224040002030503000000204600072f1439030e0100000000000402022d1e0022170030022404000203050300000020460007301439030e0100000000000402022d1eb7bb");expect_eq(d.property("energy"),"1840");
 d.feed("aa4e20ec0022170030022404000203050300000020460007301439030e0100000000000402022d1e0022170030022404000203050300000020060007301439030e0100000000000402022d1ef7bb");expect_eq(d.property("energy"),"1840");
 d.feed("aa4e20ec0022170030022404000203050300000020060007301439030e0100000000000402022d1e002217002f022404000203050300000020060007311439030e0100000000000402022d1e37bb");expect_eq(d.property("energy"),"1841");
 d.feed("aa0020cd00019001030117002f022400000d000205000303000120060000000300000000000731044f504f4e5141342c3329f9eceafaf008c608c608c608c608c606e006e006e006e006e000a600a600a600a600a68786858685940700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100620300000000070000000300017802e1ffea03004202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a2000000000000000000000000000000000000000000000000000000000000a1bb");expect_eq(d.property("energy"),"1841");
 d.feed("aa4e20ec002217002f022404000203050300000020060007311439030e0100000000000402022d1e002217002f022404000203050300000020460007321439030e0100000000000402022d1ef6bb");expect_eq(d.property("energy"),"1842");
 d.feed("aa4e20ec002217002f022404000203050300000020460007321439030e0100000000000402022d1e002217002f022404000203050300000020060007321439030e0100000000000402022d1ef1bb");expect_eq(d.property("energy"),"1842");
 d.feed("aa4e20ec002217002f022404000203050300000020060007321439030e0100000000000402022d1e002217002e022404000203050300000020060007341439030e0100000000000402022d1e30bb");expect_eq(d.property("energy"),"1844");
 d.feed("aa4e20ec002217002e022404000203050300000020060007341439030e0100000000000402022d1e002217002d022404000203050300000020060007371439030e0100000000000402022d1e3dbb");expect_eq(d.property("energy"),"1847");
 d.feed("aa4e20ec002217002d022404000203050300000020060007371439030e0100000000000402022d1e002217002d022404000203050300000020460007371439030e0100000000000402022d1effbb");expect_eq(d.property("energy"),"1847");
 d.feed("aa4e20ec002217002d022404000203050300000020460007371439030e0100000000000402022d1e002217002c022404000203050300000020460007381439030e0100000000000402022d1ebfbb");expect_eq(d.property("energy"),"1848");
 d.feed("aa4e20ec002217002c022404000203050300000020460007381439030e0100000000000402022d1e002217002b022404000203050300000020460007391439030e0100000000000402022d1ebfbb");expect_eq(d.property("energy"),"1849");
 d.feed("aa4e20ec002217002b022404000203050300000020460007391439030e0100000000000402022d1e002217002b0224040002030503000000200600073a1439030e0100000000000402022d1efebb");expect_eq(d.property("energy"),"1850");
 d.feed("aa4e20ec002217002b0224040002030503000000200600073a1439030e0100000000000402022d1e002217002a0224040002030503000000200600073b1439030e0100000000000402022d1e39bb");expect_eq(d.property("energy"),"1851");
 d.feed("aa0020cd00019001030117002a022400000d00020500030300012006000000030000000000073b045353525253282a2b2321e2e8f9e8de08c608c608c608c608c606e006e006e006e006e000a600a600a600a600a685858584849a9e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100620300000000070000000300017802daffea03004202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a200000000000000000000000000000000000000000000000000000000000078bb");expect_eq(d.property("energy"),"1851");
 d.feed("aa4e20ec002217002a0224040002030503000000200600073b1439030e0100000000000402022d1e00221700290224040002030503000000200600073d1439030e0100000000000402022d1e38bb");expect_eq(d.property("energy"),"1853");
 d.feed("aa4e20ec00221700290224040002030503000000200600073d1439030e0100000000000402022d1e00221700290224040002030503000000204600073d1439030e0100000000000402022d1efbbb");expect_eq(d.property("energy"),"1853");
 d.feed("aa4e20ec00221700290224040002030503000000204600073d1439030e0100000000000402022d1e00221700280224040002030503000000204600073d1439030e0100000000000402022d1eb8bb");expect_eq(d.property("energy"),"1853");
 d.feed("aa4e20ec00221700280224040002030503000000204600073d1439030e0100000000000402022d1e00221700270224040002030503000000204600073f1439030e0100000000000402022d1eb8bb");expect_eq(d.property("energy"),"1855");
 d.feed("aa4e20ec00221700270224040002030503000000204600073f1439030e0100000000000402022d1e0022170027022404000203050300000020060007401439030e0100000000000402022d1efabb");expect_eq(d.property("energy"),"1856");
 d.feed("aa4e20ec0022170027022404000203050300000020060007401439030e0100000000000402022d1e0022170026022404000203050300000020060007411439030e0100000000000402022d1e25bb");expect_eq(d.property("energy"),"1857");
 d.feed("aa4e20ec0022170026022404000203050300000020060007411439030e0100000000000402022d1e0022170025022404000203050300000020060007451439030e0100000000000402022d1e26bb");expect_eq(d.property("energy"),"1861");
 d.feed("aa4e20ec0022170025022404000203050300000020060007451439030e0100000000000402022d1e0022170025022404000203050300000020060007461439030e0100000000000402022d1e22bb");expect_eq(d.property("energy"),"1862");
 d.feed("aa0020cd000190010301170025022400000d0002050003030001200600000003000000000007460451505252582122201e1fe5fbf1e5e708c608c608c608c608c606e006e006e006e006e000a600a600a600a600a684848484849b9c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100620300000000070000000300017802f3ffea03004202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a20000000000000000000000000000000000000000000000000000000000006ebb");expect_eq(d.property("energy"),"1862");
 d.feed("aa4e20ec0022170025022404000203050300000020060007461439030e0100000000000402022d1e0022170025022404000203050300000020460007461439030e0100000000000402022d1eedbb");expect_eq(d.property("energy"),"1862");
 d.feed("aa4e20ec0022170025022404000203050300000020460007461439030e0100000000000402022d1e0022170024022404000203050300000020460007471439030e0100000000000402022d1eadbb");expect_eq(d.property("energy"),"1863");
 d.feed("aa4e20ec0022170024022404000203050300000020460007471439030e0100000000000402022d1e0022170023022404000203050300000020460007471439030e0100000000000402022d1ea2bb");expect_eq(d.property("energy"),"1863");
 d.feed("aa4e20ec0022170023022404000203050300000020460007471439030e0100000000000402022d1e0022170022022404000203050300000020460007491439030e0100000000000402022d1ea2bb");expect_eq(d.property("energy"),"1865");
 d.feed("aa4e20ec0022170022022404000203050300000020460007491439030e0100000000000402022d1e0022170022022404000203050300000020060007491439030e0100000000000402022d1eedbb");expect_eq(d.property("energy"),"1865");
 d.feed("aa4e20ec0022170022022404000203050300000020060007491439030e0100000000000402022d1e00221e00210224040000030003000000200600074c1739030e0100000000000402022d1e28bb");expect_eq(d.property("energy"),"1868");
 d.feed("aa0020bd00020190010301170022022400000d00020500030300012006000000030000000000074c0252515200001f1e1d0000ffede4000008c608c608c60000000006e006e006e00000000000a600a600a60000000084848400009b8900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100620300000000070000000300017802deffea03004202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a2000000000000000000000000000000000000000000000000000000000000dabb");expect_eq(d.property("energy"),"1868");
 d.feed("aa4e20ec00221e00210224040000030003000000200600074c1739030e0100000000000402022d1e00221e00200224040000030003000000200600074e1739030e0100000000000402022d1ed6bb");expect_eq(d.property("energy"),"1870");
 d.feed("aa0020cd0001900103011e0020022400000d00000000030300012006000000030000000000074e0452515253541f1e1d1d1dffede4e0f908c608c608c608c608c606e006e006e006e006e000a600a600a600a600a684848483849af300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100620300000000070000000300017802e9ffea030042020000dbf90100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a200000000000000000000000000000000000000000000000000000000000008bb");expect_eq(d.property("energy"),"1870");
 d.feed("aa4e20ec00221e00200224040000030003000000200600074e1739030e0100000000000402022d1e00221e001f0224040000030003000000200600074e1739030e0100000000000402022d1ed6bb");expect_eq(d.property("energy"),"1870");
 d.feed("aa4e20ec00221e001f0224040000030003000000200600074e1739030e0100000000000402022d1e00221e001e022404000003000300000020060007521739030e0100000000000402022d1ed0bb");expect_eq(d.property("energy"),"1874");
 d.feed("aa4e20ec00221e001e022404000003000300000020060007521739030e0100000000000402022d1e00221e001d022404000003000300000020060007531739030e0100000000000402022d1eddbb");expect_eq(d.property("energy"),"1875");
 d.feed("aa4e20ec00221e001d022404000003000300000020060007531739030e0100000000000402022d1e00221e001c022404000003000300000020060007541739030e0100000000000402022d1eddbb");expect_eq(d.property("energy"),"1876");
 d.feed("aa0020cd0001900103011e001c022400000d0000000003030001200600000003000000000007540455545151511d1e1e1d1bfffffff0e608c608c608c608c608c606e006e006e006e006e000a600a600a600a600a6848484848497bd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000401460600000000040000000304017802deffe6020042020000dbfb01053104029b0000000a2413003b18320202b200000005180500320b3104029800000010161000381b320202520000000708010013063202028e000000091608002c0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a200000000000000000000000000000000000000000000000000000000000052bb");expect_eq(d.property("energy"),"1876");
 d.feed("aa4e20ec00221e001c022404000003000300000020060007541739030e0100000000000402022d1e00221e001b022404000003000300000020060007581739030e0100000000000402022d1edebb");expect_eq(d.property("energy"),"1880");
 d.feed("aa4e20ec00221e001b022404000003000300000020060007581739030e0100000000000402022d1e00221e001a0224040000030002000000200600075c1739030e0100000000000402022d1ec5bb");expect_eq(d.property("energy"),"1884");
 d.feed("aa0020bd000201900103011e001b022400000d00000000030300012006000000030000000000075c0152560000001b1b000000dfde00000008c608c600000000000006e006e000000000000000a600a60000000000008484000000986000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000401460600000000040000000304017802e4ffdc030042020000dbfb01053104029b0000000a2413003b18320202b200000005180500320b3104029800000010161000381b320202520000000708010013063202028e000000091608002c0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a2000000000000000000000000000000000000000000000000000000000000cabb");expect_eq(d.property("energy"),"1884");
 d.feed("aa4e20ec00221e001a0224040000030002000000200600075c1739030e0100000000000402022d1e00221e00190224040000030002000000200600075d1739030e0100000000000402022d1ec7bb");expect_eq(d.property("energy"),"1885");
 d.feed("aa4e20ec00221e00190224040000030002000000200600075d1739030e0100000000000402022d1e00221e00180224040000030002000000200600075d1739030e0100000000000402022d1ec4bb");expect_eq(d.property("energy"),"1885");
 d.feed("aa4e20ec00221e00180224040000030002000000200600075d1739030e0100000000000402022d1e00221e0017022404000003000200000020060007601739030e0100000000000402022d1ec7bb");expect_eq(d.property("energy"),"1888");
 d.feed("aa4e20ec00221e0017022404000003000200000020060007601739030e0100000000000402022d1e00221e0015022404000003000200000020060007601739030e0100000000000402022d1ec7bb");expect_eq(d.property("energy"),"1888");
 d.feed("aa0020cd0001900103011e0015022400000d0000000002030001200600000003000000000007600452565153511b1b1c1c1ddfdee5ffff08c608c608c608c608c606e006e006e006e006e000a600a600a600a600a684848484849b7700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000401460600000000040000000304017802e6ffdc030042020000dcfb0101310403b30000000e170e002717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002ee02ee0000000000a2000000000000000000000000000000000000000000000000000000000000a6bb");expect_eq(d.property("energy"),"1888");
 d.feed("aa4e20ec00221e0015022404000003000200000020060007601739030e0100000000000402022d1e00221e0014022404000003000200000020060007651739030e0100000000000402022d1ec1bb");expect_eq(d.property("energy"),"1893");
 d.feed("aa4e20ec00221e0014022404000003000200000020060007651739030e0100000000000402022d1e00221e0013022404000003000200000020060007651739030e0100000000000402022d1ec2bb");expect_eq(d.property("energy"),"1893");
 d.feed("aa0020cd0001900103011e0013022400000d000000000203000120060000000300000000000769045350504f511d1d1c1b1afffff4eee408c608c608c608c608c606e006e006e006e006e000a600a600a600a600a684848484849a8900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000401460600000000040000000304017802d1ffe4030042020000dcfb0101310403b30000000e170e002717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002ee02ee0100000000a20000000000000000000000000000000000000000000000000000000000004cbb");expect_eq(d.property("energy"),"1897");
 d.feed("aa4e20ec00221e0013022404000003000200000020060007651739030e0100000000000402022d1e00221e00120224040000030002000000200600076b1739030e0100000000000402022d1ecebb");expect_eq(d.property("energy"),"1899");
 d.feed("aa4e20ec00221e00120224040000030002000000200600076b1739030e0100000000000402022d1e00221e00110224040000030001000000200600076f1739030e0100000000000402022d1ef7bb");expect_eq(d.property("energy"),"1903");
 d.feed("aa0020bd000201900103011e0012022400000d00000000020300012006000000030000000000076f0150520000001b1b000000dddc00000008c608c600000000000006e006e000000000000000a600a600000000000083840000009a7400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000401460600000000040000000304017802dbffdc040042020000dcfb0101310403b30000000e170e002717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002ee02ee0100000000a20000000000000000000000000000000000000000000000000000000000005abb");expect_eq(d.property("energy"),"1903");
 d.feed("aa4e20ec00221e00110224040000030001000000200600076f1739030e0100000000000402022d1e00221e0010022404000003000100000020060007701739030e0100000000000402022d1ef1bb");expect_eq(d.property("energy"),"1904");
 d.feed("aa4e20ec00221e0010022404000003000100000020060007701739030e0100000000000402022d1e00221e000f022404000003000100000020060007711739030e0100000000000402022d1ef1bb");expect_eq(d.property("energy"),"1905");
 d.feed("aa4e20ec00221e000f022404000003000100000020060007711739030e0100000000000402022d1e00221e000e022404000003000100000020060007721739030e0100000000000402022d1ef1bb");expect_eq(d.property("energy"),"1906");
 d.feed("aa0020cd0001900103011e000e022400000d00000000010300012006000000030000000000077404505252504f1b1b1b1b1bdddceff8ff08c608c608c608c608c606e006e006e006e006e000a600a600a600a600a68384848484996800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000401460600000000040000000304017802ccffdc040042020000dcfe0103310402f30000000a100600240f3402006a0000000f2007007714320202720000000f260800521400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002ee02ee0000000000a2000000000000000000000000000000000000000000000000000000000000c2bb");expect_eq(d.property("energy"),"1908");
 d.feed("aa4e20ec00221e000e022404000003000100000020060007721739030e0100000000000402022d1e00221e000c022404000003000100000020060007741739030e0100000000000402022d1ef1bb");expect_eq(d.property("energy"),"1908");
 d.feed("aa4e20ec00221e000c022404000003000100000020060007741739030e0100000000000402022d1e00221e000b022404000003000100000020060007781739030e0100000000000402022d1ef2bb");expect_eq(d.property("energy"),"1912");
 d.feed("aa4e20ec00221e000b022404000003000100000020060007781739030e0100000000000402022d1e00221e000a022404000003000100000020060007781739030e0100000000000402022d1efcbb");expect_eq(d.property("energy"),"1912");
 d.feed("aa4e20ec00221e000a022404000003000100000020060007781739030e0100000000000402022d1e00221e0009022404000003000100000020060007791739030e0100000000000402022d1efdbb");expect_eq(d.property("energy"),"1913");
 d.feed("aa0020cd0001900103011e0009022400000d00000000010300012006000000030000000000077b04504f4e4d4c1c1c1c1c1bfffbf8f8f208c608c608c608c608c606e006e006e006e006e000a600a600a600a600a6848484848494ce00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000401460600000000040000000304017802b9fff2020042020000dcfe0103310402f30000000a100600240f3402006a0000000f2007007714320202720000000f260800521400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002ee02ee0100000000a200000000000000000000000000000000000000000000000000000000000064bb");expect_eq(d.property("energy"),"1915");
 d.feed("aa4e20ec00221e0009022404000003000100000020060007791739030e0100000000000402022d1e00221e00080224040000030001000000200600077e1739030e0100000000000402022d1ef9bb");expect_eq(d.property("energy"),"1918");
 d.feed("aa4e20ec00221e00080224040000030001000000200600077e1739030e0100000000000402022d1e00221e0007022404000003000100000020060007831739030e0100000000000402022d1ee1bb");expect_eq(d.property("energy"),"1923");
 d.feed("aa4e20ec00221e0007022404000003000100000020060007831739030e0100000000000402022d1e0022280007022404000003000000000020060007851e39030e0100000000000402022d1e9fbb");expect_eq(d.property("energy"),"1925");
 d.feed("aa4e20ec0022280007022404000003000000000020060007851e39030e0100000000000402022d1e0022280006022404000003000000000020060007851e39030e0100000000000402022d1e8ebb");expect_eq(d.property("energy"),"1925");
 d.feed("aa0020bd000201900103011e0007022400000d000000000103000120060000000300000000000785024d4e5100001b1b1b0000eae1e6000008c608c608c60000000006e006e006e00000000000a600a600a6000000008383840000986c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000401460600000000040000000304017802dbffe1040042020000e5f90103310402f30000000a100600240f3402006a0000000f2007007714320202720000000f260800521400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002ee02ee0100000000a200000000000000000000000000000000000000000000000000000000000070bb");expect_eq(d.property("energy"),"1925");
 d.feed("aa4e20ec0022280006022404000003000000000020060007851e39030e0100000000000402022d1e0022280005022404000003000000000020060007871e39030e0100000000000402022d1e8ebb");expect_eq(d.property("energy"),"1927");
 d.feed("aa4e20ec0022280005022404000003000000000020060007871e39030e0100000000000402022d1e0022280004022404000003000000000020060007881e39030e0100000000000402022d1e89bb");expect_eq(d.property("energy"),"1928");
 d.feed("aa4e20ec0022280004022404000003000000000020060007881e39030e0100000000000402022d1e00222800030224040000030000000000200600078c1e39030e0100000000000402022d1e8abb");expect_eq(d.property("energy"),"1932");
 d.feed("aa4e20ec00222800030224040000030000000000200600078c1e39030e0100000000000402022d1e00222800020224040000030000000000200600078f1e39030e0100000000000402022d1eb1bb");expect_eq(d.property("energy"),"1935");
 d.feed("aa0020cd000190010301280002022400000d000000000003000120060000000300000000000792044f4f4e4f501b1b1c1c1cffffffffff08c608c608c608c608c606e006e006e006e006e000a600a600a600a600a684848484849bc500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000401460600000000040000000304017802caffe1040042020000f9ff01113104039900000008160c00221132020248000000050d01001a06320202760000000b220500501232020278000000041003001d073104030d00000010160800240e320202c20000000115050021073104045d000000182b09005719320202440000000c1e05004611310402fb000000041906002d09320202a60000000515040026073202026200000006150400270a3202029a00000006140400280b3202028c000000072b08006511320202720000000411030021073104029000000010280a00461102ee02ee0100000000a20000000000000000000000000000000000000000000000000000000000004abb");expect_eq(d.property("energy"),"1938");
 d.feed("aa4e20ec00222800020224040000030000000000200600078f1e39030e0100000000000402022d1e0022280001022404000003000000000020060007931e39030e0100000000000402022d1ebcbb");expect_eq(d.property("energy"),"1939");
 d.feed("aa4e20ec0022280001022404000003000000000020060007931e39030e0100000000000402022d1e0022280001022404000000000000000000060007951e39030e0100000000000402022d1e9ebb");expect_eq(d.property("energy"),"1941");
 d.feed("aa4e20ec0022280001022404000000000000000000060007951e39030e0100000000000402022d1e00223c0000000000000000000000000000060007952839040e0000000000000402022d1ec8bb");expect_eq(d.property("energy"),"1941");
 d.feed("aa4e20ec00223c0000000000000000000000000000060007952839040e0000000000000402022d1e00223c0000000000000000000000000000020007952839040e0000000000000402022d1ed9bb");expect_eq(d.property("energy"),"1941");
 d.feed("aa0020bd00030190010301280001022400000d000000000000000100060000000300000000000795004f000000001c00000000ff0000000008c6000000000000000006e0000000000000000000a6000000000000000084000000009ac200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000401460600000000040000000304017802b4ffe1040042020000f9ff01113104039900000008160c00221132020248000000050d01001a06320202760000000b220500501232020278000000041003001d073104030d00000010160800240e320202c20000000115050021073104045d000000182b09005719320202440000000c1e05004611310402fb000000041906002d09320202a60000000515040026073202026200000006150400270a3202029a00000006140400280b3202028c000000072b08006511320202720000000411030021073104029000000010280a00461102ee02ee0200000000a20000000000000000000000000000000000000000000000000000000000004503010100040506033900000000ff015a00000000031b2c00041e1b001104fd4b4b0000fdfd000000fd000005fa0518030007000d30200005500000c042d58851839a002200c7bb");expect_eq(d.property("energy"),"1941");
 d.feed("aa4e20ec00223c0000000000000000000000000000020007952839040e0000000000000402022d1e0022000000000000000000000000000000020007953c39040e0000000000000402022d1e35bb");expect_eq(d.property("energy"),"1941");
 expect_eq(d.script_error(),());
}

// Constructed extension of the existing 34-byte captured layout, not a new live capture.
fn test_extended_record_keeps_existing_fields_presets_and_automatic_resume() {
 let d=device();d.start();let p=heavy_duty_wash();p.push(0);p.push(0);
 d.feed(a::record(0x20,0xeb,0,p));
 expect_props(d,#{energy:"300",remote_start:"true",door_lock:"true",op_course:"heavy_duty",soil:"heavy",load_level:"0"});
 d.set("course_select","heavy_duty");let n=d.sent().len();d.set("start","");
 expect_eq(a::payload_hex(d,n),"060303040300002000200e00000000000000000000");
 p[0]=6;d.feed(a::record(0x20,0xeb,0,p));d.set("start","");
 expect_eq(a::payload_hex(d,n+1),"060303040300002000000e00000000000000000000");
 expect_eq(d.script_error(),());
}
