import "runtime_test" as runtime;

// Tests of ST_B_E4H01Y_APL, ported from upstream rethink's test suite (commit 0e57069). STATE and
// STATE2 are real frames; the rest are STATE with one byte changed and its CRC recomputed, each
// injected into LG's cloud, so an expectation is LG's own decode. Writes are compared byte for
// byte with the frames LG's converter sent. Expected values are in IL names (LG's labels
// snake_cased; ON/OFF as true/false); a code LG does not define is absent, an empty value.

fn state() { "aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb" }
fn state2() { "aaff310a003a005504000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000251351bb" }
fn ready() { "aaff310a003a0053ea000100eb002800000100010001000001000000000000200000000000000000014e42000004030000000000000025969ebb" }
fn course_standard() { "aaff310a003a0053ea000100eb002800000000010001010001000000000000200000000000000000014e42000004030000000000000025ffd9bb" }
fn error_te1() { "aaff310a003a0053ea000100eb002800000000010001000101000000000000200000000000000000014e420000040300000000000000252b43bb" }
fn prestate_running() { "aaff310a003a0053ea000100eb002800000000010001000002000000000000200000000000000000014e42000004030000000000000025f05fbb" }
fn flags_a_all() { "aaff310a003a0053ea000100eb0028000000000100010000010000000000000f0000000000000000014e42000004030000000000000025df93bb" }
fn remote_maintain() { "aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e42000004040000000000000025c3aebb" }
fn flags_c_all() { "aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300003f0000000025988abb" }
fn buzzer_low() { "aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e42000001030000000000000025b075bb" }
fn melody_1() { "aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e4200000403010000000000002535d6bb" }
fn smart_course_1() { "aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000010000014e420000040300000000000000258234bb" }
fn tcl_1() { "aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e4200000403000000000000000116e3bb" }
fn running_ready() { "aaff310a0062005cd0000100ec005000000000010001000001000000000000200000000000000000014e4200000403000000000000002500000100010001000000000000000000200000000000000000014e42000004030000000000000025ee3ebb" }
fn running_course() { "aaff310a0062005ce5000100ec0050000001011e011e0f0000000000000000280000000000000000014e4200000403000000000000002500000100230023010000000000000000280000000000000000014e42000004030000000000000025042abb" }
fn course_list() { "aaff310a0070005ccc00010a86005e0d053230332d3101073230332d312d3101073230332d312d3201073230332d312d3301073230332d312d34010453542d34010453542d35010453542d36010453542d37010453542d38010453542d39010553542d3130000553542d313201ed79bb" }
fn not_state_35() { "aaff310a00230053ed000101030011100b0306100000008a00000000000000059317bb" }
fn heartbeat() { "aa0731c302f2bb" }

fn fed(frames) { let d = device(); d.start(); for f in frames { d.feed(f); } d }
fn patched(frame, changes) { let f = hex_decode(frame); for c in changes { f[c[0]] = c[1]; } f }
fn hex_of(d, i) { hex_encode(d.sent()[i]) }

// exactly the fields with a captured command frame are writable
fn test_exactly_the_captured_commands_are_writable() {
    let d = device();
    d.start();
    let props = runtime::descriptor(d).props;
    let writable = ["power", "buzzer", "end_melody", "keep_last_course", "smart_care_finedust", "smart_care_humidity",
                    "smart_care_nightcare", "night_care_start", "night_care_end", "remote_maintain", "course_select",
                    "start_course", "pause_course", "resume_course"];
    for name in props.keys() {
        let p = props[name];
        let w = (p.rw ?? false) || p.type == "trigger";
        expect_eq(w, writable.contains(name), name);
    }
}

// each write reproduces the frame LG itself sent for that command
fn test_each_write_reproduces_lg_s_frame() {
    for c in [["power", "true", "aa09f0240101019fbb"], ["power", "false", "aa09f0240101009cbb"],
              ["end_melody", "default_sound", "aa0af0241301010088bb"], ["end_melody", "vivaldi_winter", "aa0af024130101018bbb"],
              ["end_melody", "bach_minuet", "aa0af024130101028abb"], ["end_melody", "home_sweet_home", "aa0af02413010103b5bb"],
              ["end_melody", "breeze", "aa0af02413010104b4bb"], ["end_melody", "old_macdonald", "aa0af02413010105b7bb"],
              ["end_melody", "verdi_brindisi", "aa0af02413010106b6bb"], ["end_melody", "bubble", "aa0af02413010107b1bb"],
              ["end_melody", "beethoven_symphony_no_5_5", "aa0af02413010108b0bb"], ["end_melody", "arirang", "aa0af02413010109b3bb"],
              ["end_melody", "pachelbel_canon", "aa0af0241301010ab2bb"], ["end_melody", "beethoven_choral", "aa0af0241301010bbdbb"],
              ["buzzer", "mute", "aa0af024130103008abb"], ["buzzer", "small", "aa0af02413010301b5bb"],
              ["buzzer", "normal", "aa0af02413010302b4bb"], ["buzzer", "large", "aa0af02413010303b7bb"],
              ["buzzer", "very_large", "aa0af02413010304b6bb"],
              ["smart_care_finedust", "true", "aa0af02413010401b4bb"], ["smart_care_finedust", "false", "aa0af02413010400b5bb"],
              ["smart_care_humidity", "true", "aa0af02413010501b7bb"], ["smart_care_humidity", "false", "aa0af02413010500b4bb"],
              ["smart_care_nightcare", "true", "aa0af02413010601b6bb"], ["smart_care_nightcare", "false", "aa0af02413010600b7bb"],
              ["keep_last_course", "true", "aa0af02413010901b3bb"], ["keep_last_course", "false", "aa0af02413010900b0bb"]] {
        let d = fed([]);
        d.set(c[0], c[1]);
        expect_eq(d.sent().len(), 1, c[0] + "=" + c[1]);
        expect_eq(hex_of(d, 0), c[2], c[0] + "=" + c[1]);
    }
}

// Remote control allowed writes the frame the appliance acknowledged
fn test_remote_maintain_writes_the_acknowledged_frame() {
    for c in [["true", "aa09f0241001018cbb"], ["false", "aa09f0241001008dbb"]] {
        let d = fed([]);
        d.set("remote_maintain", c[0]);
        expect_eq(hex_of(d, 0), c[1]);
    }
}

// Start course reproduces the frame LG itself sent, for both captured courses
fn test_start_course_reproduces_lg_s_frames() {
    for c in [["styling_standard", "aa34f02601010004000000000002645a00000005005a05b45a01b4001ab40000000000000000000000000000000000000000fabb"],
              ["styling_quick", "aa34f02603010004000000000082645a00000003005a00000001b4000eb4000000000000000000000000000000000000000045bb"]] {
        let d = fed([]);
        d.set("course_select", c[0]);
        d.set("start_course", "");
        expect_eq(d.sent().len(), 1, c[0]);
        expect_eq(hex_of(d, 0), c[1], c[0]);
    }
}

// Pause and Resume reproduce their captured frames
fn test_pause_and_resume() {
    let d = fed([]);
    d.set("course_select", "styling_standard");
    d.set("pause_course", "");
    expect_eq(hex_of(d, 0), "aa09f02404010099bb");
    d.set("resume_course", "");
    expect_eq(hex_of(d, 1), "aa33f026010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1bb");
}

// a write shows up straight away instead of waiting for the appliance
fn test_a_write_shows_at_once() {
    let enabled = patched(ready(), [[49, hex_decode(ready())[49] | 0x08]]); // smart care night on
    let d = fed([enabled]);
    d.set("buzzer", "small");
    d.set("smart_care_humidity", "true");
    d.set("night_care_start", "22:30");
    d.set("course_select", "styling_standard");
    d.set("start_course", "");
    expect_props(d, #{ buzzer: "small", smart_care_humidity: "true", night_care_start: "22:30", course: "styling_standard" });
    d.feed(enabled); // the next real frame has the last word
    expect_props(d, #{ buzzer: "very_large", course: "none" });
}

// a setting rejected while powered off is not optimistically published
fn test_nothing_is_shown_while_off() {
    let d = fed([state()]);
    let n = d.sent().len();
    d.set("buzzer", "small");
    d.set("smart_care_humidity", "true");
    d.set("course_select", "styling_standard");
    d.set("start_course", "");
    expect_eq(d.sent().len(), n + 3); // still sent: the appliance has the final say
    expect_props(d, #{ buzzer: "very_large", smart_care_humidity: "false", course: "none", course_select: "styling_standard" });
}

// night-care times rejected while night care is disabled are not optimistically published
fn test_night_care_times_are_not_shown_while_it_is_off() {
    let d = fed([ready()]);
    let n = d.sent().len();
    d.set("night_care_start", "22:30");
    d.set("night_care_end", "06:00");
    expect_eq(d.sent().len(), n + 2);
    expect_props(d, #{ night_care_start: "00:00", night_care_end: "00:00" });
}

// no setting is optimistically published before the first authoritative state
fn test_nothing_is_shown_before_the_first_state() {
    let d = fed([]);
    d.set("buzzer", "small");
    d.set("course_select", "styling_standard");
    d.set("start_course", "");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.property("buzzer"), ());
    expect_eq(d.property("course"), ());
    expect_eq(d.property("course_select"), "styling_standard");
}

// a course rejected by a standing error is not optimistically published
fn test_a_course_is_not_shown_while_an_error_stands() {
    let d = fed([patched(error_te1(), [[17, 1]])]); // powered on, error TE1 standing
    let n = d.sent().len();
    d.set("course_select", "styling_standard");
    d.set("start_course", "");
    expect_eq(d.sent().len(), n + 1);
    expect_props(d, #{ power: "true", error: "true", course: "none" });
}

// Course select chooses without commanding the appliance
fn test_course_select_only_chooses() {
    let d = fed([]);
    d.set("course_select", "sterilize_standard");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.property("course_select"), "sterilize_standard");
    d.set("start_course", "");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.sent()[0][4], 11); // course id 11 leads the block
}

// a course the appliance is running takes over the selection
fn test_a_running_course_takes_over_the_selection() {
    let d = fed([course_standard()]);
    expect_eq(d.property("course_select"), "styling_standard");
    d.feed(state());
    expect_eq(d.property("course_select"), "styling_standard");
}

// an unknown course is refused rather than started
fn test_an_unknown_course_is_refused() {
    let d = fed([]);
    d.set("course_select", "invalid_course");
    expect_eq(d.sent().len(), 0);
    expect(d.event("reject") != (), "reject");
}

// the night-care window writes hour and minute in one frame
fn test_the_night_care_window() {
    for c in [["night_care_start", "23:30", "aa0bf024130207171e4fbb"], ["night_care_start", "00:00", "aa0bf0241302070000b0bb"],
              ["night_care_end", "06:00", "aa0bf0241302080600b9bb"], ["night_care_end", "00:00", "aa0bf0241302080000b3bb"]] {
        let d = fed([]);
        d.set(c[0], c[1]);
        expect_eq(hex_of(d, 0), c[2], c[0] + "=" + c[1]);
    }
}

// a time the appliance would refuse is not written
fn test_a_refused_time_is_not_written() {
    for bad in ["23:45", "24:00", "9:30", "abc", "", "07:1"] {
        let d = fed([]);
        d.set("night_care_start", bad);
        expect_eq(d.sent().len(), 0, bad);
    }
}

// an unknown option is refused rather than guessed
fn test_an_unknown_option_is_refused() {
    let d = fed([]);
    d.set("buzzer", "invalid_volume");
    d.set("end_melody", "silent_night");
    d.set("course", "styling_standard"); // read only
    expect_eq(d.sent().len(), 0);
}

// the power switch reports OFF as soon as it is switched off
fn test_power_off_shows_at_once() {
    let d = fed([ready()]);
    expect_eq(d.property("power"), "true");
    d.set("power", "false");
    expect_eq(d.property("power"), "false");
    d.feed(ready());
    expect_eq(d.property("power"), "true");
}

// every user-facing enum value is English
fn test_values_are_english() {
    let d = fed([state()]);
    for p in ["status", "previous_status", "course", "smart_course", "buzzer", "end_melody", "error_message"] {
        let v = d.property(p);
        expect(v != () && v.len() > 0, p);
    }
}

// real captured frame decodes to what LG read from the same frame
fn test_a_real_frame_decodes_as_lg_read_it() {
    expect_props(fed([state()]), #{ status: "power_off", previous_status: "standby", course: "none", smart_course: "none",
        error_message: "normal", error: "false", remaining_time: "1", initial_time: "1", reserve_time: "0",
        child_lock: "false", night_dry: "false", remote_start: "false", remote_maintain: "false", buzzer: "very_large",
        end_melody: "default_sound", smart_care_finedust: "false", smart_care_humidity: "false",
        smart_care_nightcare: "false", keep_last_course: "false", night_care_start: "00:00", night_care_end: "00:00",
        power: "false", tcl_count: "37", download_course: "fur_leather_care" });
}

// a second real frame with a different sequence number decodes identically
fn test_a_second_real_frame_decodes_identically() {
    let a = fed([state()]);
    let b = fed([state2()]);
    for p in ["status", "previous_status", "course", "buzzer", "end_melody", "tcl_count", "download_course",
              "remaining_time", "power", "error"] {
        expect_eq(b.property(p), a.property(p), p);
    }
}

// each probed offset moves exactly the field LG said it moves
fn test_each_probed_offset() {
    for c in [[ready(), "status", "standby"], [course_standard(), "course", "styling_standard"],
              [error_te1(), "error_message", "te1"], [prestate_running(), "previous_status", "styling"],
              [buzzer_low(), "buzzer", "small"], [melody_1(), "end_melody", "vivaldi_winter"],
              [smart_course_1(), "smart_course", "panel_course"], [tcl_1(), "tcl_count", "1"],
              [remote_maintain(), "remote_maintain", "true"]] {
        expect_eq(fed([state(), c[0]]).property(c[1]), c[2], c[1]);
    }
}

// the running-state codes decode, not just the idle ones
fn test_the_running_state_codes() {
    for c in [[0, "power_off"], [3, "pause"], [9, "power_save_running"], [50, "steam_preparing"], [52, "refreshing"],
              [55, "drying"], [57, "sterilizing"], [58, "course_complete"]] {
        expect_eq(fed([patched(state(), [[17, c[0]]])]).property("status"), c[1], c[1]);
    }
}

// a code LG itself does not define reads unknown: absent, not a wrong name
fn test_an_undefined_state_is_absent() {
    let d = fed([state(), patched(state(), [[17, 20]])]);
    expect_eq(d.property("status"), "");
}

// the error codes decode, and Water refill is not off by one
fn test_the_error_codes() {
    for c in [[0, "normal", "false"], [8, "water_refill", "true"], [11, "ae", "true"], [18, "le", "true"],
              [23, "normal", "false"], [25, "water_drain", "true"], [26, "door_open", "true"], [34, "no_filter", "true"],
              [12, "", "true"]] {
        let d = fed([patched(state(), [[23, c[0]]])]);
        expect_eq(d.property("error_message"), c[1], "error " + c[0]);
        expect_eq(d.property("error"), c[2], "problem flag for error " + c[0]);
    }
}

// byte 31 is a bitfield, not an enum
fn test_the_first_flag_byte() {
    expect_props(fed([flags_a_all()]), #{ child_lock: "true", night_dry: "true", remote_start: "true" });
}

// byte 49 is a bitfield carrying six independent flags
fn test_the_third_flag_byte() {
    expect_props(fed([flags_c_all()]), #{ smart_care_finedust: "true", smart_care_humidity: "true",
        smart_care_nightcare: "true", keep_last_course: "true" });
}

// the night-care window reads back as two clock times
fn test_the_night_care_window_reads_as_clock_times() {
    expect_props(fed([patched(state(), [[50, 23], [51, 30], [52, 6], [53, 0]])]),
                 #{ night_care_start: "23:30", night_care_end: "06:00" });
}

// the 35-byte frame and the heartbeat carry no state
fn test_the_35_byte_frame_and_the_heartbeat_carry_no_state() {
    let d = fed([state()]);
    d.feed(not_state_35());
    d.feed(heartbeat());
    expect_props(d, #{ status: "power_off", tcl_count: "37", buzzer: "very_large" });
}

// hours and minutes are folded into one duration
fn test_hours_and_minutes_fold_into_minutes() {
    expect_props(fed([patched(state(), [[18, 1], [19, 25], [20, 2], [21, 0]])]), #{ remaining_time: "85", initial_time: "120" });
}

// a two-record frame is decoded, and it is the LAST record that counts
fn test_the_last_record_counts() {
    let d = fed([state()]);
    expect_eq(d.property("status"), "power_off");
    d.feed(running_ready());
    expect_eq(d.property("status"), "standby");
    d.feed(running_course());
    expect_props(d, #{ status: "standby", course: "styling_standard", remaining_time: "35", initial_time: "35",
        remote_start: "true", child_lock: "false" });
}

// the course-name list frame is not mistaken for state
fn test_the_course_list_is_not_state() {
    let d = fed([state()]);
    d.feed(course_list());
    expect_props(d, #{ status: "power_off", course: "none", tcl_count: "37" });
}

// a set reservation reads as a delay in minutes
fn test_a_reservation_reads_in_minutes() {
    expect_eq(fed([patched(state(), [[29, 7], [30, 5]])]).property("reserve_time"), "425");
}

// discovery contract: no read-only property claims category config
fn test_no_read_only_property_is_config() {
    let d = device();
    d.start();
    let props = runtime::descriptor(d).props;
    for name in props.keys() {
        let p = props[name];
        if !(p.rw ?? false) && p.type != "trigger" { expect(p.category != "config", name); }
    }
}
// BEGIN PR VECTORS
// Regression vectors from rethink PR #115 (080a8b432d068d913f027db9c27d5e5d28b437ff).
// Original test names are retained below. Expected TX bytes come from executing the TS driver.

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_1() {
    let d = device();
    d.set("power", "true");
    expect_props(d, #{"power": "true"});
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240101019fbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_2() {
    let d = device();
    d.set("power", "false");
    expect_props(d, #{"power": "false"});
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240101009cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_3() {
    let d = device();
    d.set("end_melody", "default_sound");
    expect_eq(hex_encode(d.sent()[0]), "aa0af0241301010088bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_4() {
    let d = device();
    d.set("end_melody", "vivaldi_winter");
    expect_eq(hex_encode(d.sent()[0]), "aa0af024130101018bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_5() {
    let d = device();
    d.set("end_melody", "bach_minuet");
    expect_eq(hex_encode(d.sent()[0]), "aa0af024130101028abb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_6() {
    let d = device();
    d.set("end_melody", "home_sweet_home");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010103b5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_7() {
    let d = device();
    d.set("end_melody", "breeze");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010104b4bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_8() {
    let d = device();
    d.set("end_melody", "old_macdonald");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010105b7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_9() {
    let d = device();
    d.set("end_melody", "verdi_brindisi");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010106b6bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_10() {
    let d = device();
    d.set("end_melody", "bubble");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010107b1bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_11() {
    let d = device();
    d.set("end_melody", "beethoven_symphony_no_5_5");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010108b0bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_12() {
    let d = device();
    d.set("end_melody", "arirang");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010109b3bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_13() {
    let d = device();
    d.set("end_melody", "pachelbel_canon");
    expect_eq(hex_encode(d.sent()[0]), "aa0af0241301010ab2bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_14() {
    let d = device();
    d.set("end_melody", "beethoven_choral");
    expect_eq(hex_encode(d.sent()[0]), "aa0af0241301010bbdbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_15() {
    let d = device();
    d.set("buzzer", "mute");
    expect_eq(hex_encode(d.sent()[0]), "aa0af024130103008abb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_16() {
    let d = device();
    d.set("buzzer", "small");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010301b5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_17() {
    let d = device();
    d.set("buzzer", "normal");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010302b4bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_18() {
    let d = device();
    d.set("buzzer", "large");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010303b7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_19() {
    let d = device();
    d.set("buzzer", "very_large");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010304b6bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_20() {
    let d = device();
    d.set("smart_care_finedust", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010401b4bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_21() {
    let d = device();
    d.set("smart_care_finedust", "false");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010400b5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_22() {
    let d = device();
    d.set("smart_care_humidity", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010501b7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_23() {
    let d = device();
    d.set("smart_care_humidity", "false");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010500b4bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_24() {
    let d = device();
    d.set("smart_care_nightcare", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010601b6bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_25() {
    let d = device();
    d.set("smart_care_nightcare", "false");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010600b7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_26() {
    let d = device();
    d.set("keep_last_course", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010901b3bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_115_27() {
    let d = device();
    d.set("keep_last_course", "false");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010900b0bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Remote control allowed writes the frame the appliance acknowledged
fn test_pr_115_28() {
    let d = device();
    d.set("remote_maintain", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa09f0241001018cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Remote control allowed writes the frame the appliance acknowledged
fn test_pr_115_29() {
    let d = device();
    d.set("remote_maintain", "false");
    expect_eq(hex_encode(d.sent()[0]), "aa09f0241001008dbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course reproduces the frame LG itself sent, for both captured courses
fn test_pr_115_30() {
    let d = device();
    d.set("course_select", "styling_standard");
    expect_props(d, #{"course_select": "styling_standard"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "styling_standard"});
    expect_eq(hex_encode(d.sent()[0]), "aa34f02601010004000000000002645a00000005005a05b45a01b4001ab40000000000000000000000000000000000000000fabb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course reproduces the frame LG itself sent, for both captured courses
fn test_pr_115_31() {
    let d = device();
    d.set("course_select", "styling_quick");
    expect_props(d, #{"course_select": "styling_quick"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "styling_quick"});
    expect_eq(hex_encode(d.sent()[0]), "aa34f02603010004000000000082645a00000003005a00000001b4000eb4000000000000000000000000000000000000000045bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Pause and Resume reproduce their captured frames
fn test_pr_115_32() {
    let d = device();
    d.set("course_select", "styling_standard");
    expect_props(d, #{"course_select": "styling_standard"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("pause_course", "");
    expect_props(d, #{"course_select": "styling_standard"});
    expect_eq(hex_encode(d.sent()[0]), "aa09f02404010099bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("resume_course", "");
    expect_props(d, #{"course_select": "styling_standard"});
    expect_eq(hex_encode(d.sent()[1]), "aa33f026010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// a write shows up straight away instead of waiting for the appliance
fn test_pr_115_33() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000100010001000001000000000000200000000000000000014e42000004030000080000000025969ebb");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "true", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("buzzer", "small");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "small", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "true", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010301b5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("smart_care_humidity", "true");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "small", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "true", "smart_care_nightcare": "true", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(hex_encode(d.sent()[1]), "aa0af02413010501b7bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("night_care_start", "22:30");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "small", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "true", "smart_care_nightcare": "true", "night_care_start": "22:30", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(hex_encode(d.sent()[2]), "aa0bf024130207161e4cbb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("course_select", "styling_standard");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "small", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "true", "smart_care_nightcare": "true", "night_care_start": "22:30", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37", "course_select": "styling_standard"});
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "false", "course": "styling_standard", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "small", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "true", "smart_care_nightcare": "true", "night_care_start": "22:30", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37", "course_select": "styling_standard"});
    expect_eq(hex_encode(d.sent()[3]), "aa34f02601010004000000000002645a00000005005a05b45a01b4001ab40000000000000000000000000000000000000000fabb");
    expect_eq(d.sent().len(), 4);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a003a0053ea000100eb002800000100010001000001000000000000200000000000000000014e42000004030000080000000025969ebb");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "true", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37", "course_select": "styling_standard"});
    expect_eq(d.sent().len(), 4);
    expect_eq(d.script_error(), ());
}

// a setting rejected while powered off is not optimistically published
fn test_pr_115_34() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("buzzer", "small");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010301b5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("smart_care_humidity", "true");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(hex_encode(d.sent()[1]), "aa0af02413010501b7bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("course_select", "styling_standard");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37", "course_select": "styling_standard"});
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37", "course_select": "styling_standard"});
    expect_eq(hex_encode(d.sent()[2]), "aa34f02601010004000000000002645a00000005005a05b45a01b4001ab40000000000000000000000000000000000000000fabb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// night-care times rejected while night care is disabled are not optimistically published
fn test_pr_115_35() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000100010001000001000000000000200000000000000000014e42000004030000000000000025969ebb");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("night_care_start", "22:30");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(hex_encode(d.sent()[0]), "aa0bf024130207161e4cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("night_care_end", "06:00");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(hex_encode(d.sent()[1]), "aa0bf0241302080600b9bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// no setting is optimistically published before the first authoritative state
fn test_pr_115_36() {
    let d = device();
    d.set("buzzer", "small");
    expect_eq(hex_encode(d.sent()[0]), "aa0af02413010301b5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "styling_standard");
    expect_props(d, #{"course_select": "styling_standard"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "styling_standard"});
    expect_eq(hex_encode(d.sent()[1]), "aa34f02601010004000000000002645a00000005005a05b45a01b4001ab40000000000000000000000000000000000000000fabb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// a course rejected by a standing error is not optimistically published
fn test_pr_115_37() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000100010001000101000000000000200000000000000000014e420000040300000000000000252b43bb");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "true", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("course_select", "styling_standard");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "true", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37", "course_select": "styling_standard"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "true", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37", "course_select": "styling_standard"});
    expect_eq(hex_encode(d.sent()[0]), "aa34f02601010004000000000002645a00000005005a05b45a01b4001ab40000000000000000000000000000000000000000fabb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Course select chooses without commanding the appliance
fn test_pr_115_38() {
    let d = device();
    d.set("course_select", "sterilize_standard");
    expect_props(d, #{"course_select": "sterilize_standard"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "sterilize_standard"});
    expect_eq(hex_encode(d.sent()[0]), "aa34f0260b01000400000000000200002d0000060000080000030000237800000000000000000000000000000000000000008abb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// a course the appliance is running takes over the selection
fn test_pr_115_39() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001010001000000000000200000000000000000014e42000004030000000000000025ffd9bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "styling_standard", "smart_course": "none", "course_select": "styling_standard", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "course_select": "styling_standard", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// an unknown course is refused rather than started
fn test_pr_115_40() {
    let d = device();
    d.set("course_select", "invalidcourse");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the night-care window writes hour and minute in one frame
fn test_pr_115_41() {
    let d = device();
    d.set("night_care_start", "23:30");
    expect_eq(hex_encode(d.sent()[0]), "aa0bf024130207171e4fbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// the night-care window writes hour and minute in one frame
fn test_pr_115_42() {
    let d = device();
    d.set("night_care_start", "00:00");
    expect_eq(hex_encode(d.sent()[0]), "aa0bf0241302070000b0bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// the night-care window writes hour and minute in one frame
fn test_pr_115_43() {
    let d = device();
    d.set("night_care_end", "06:00");
    expect_eq(hex_encode(d.sent()[0]), "aa0bf0241302080600b9bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// the night-care window writes hour and minute in one frame
fn test_pr_115_44() {
    let d = device();
    d.set("night_care_end", "00:00");
    expect_eq(hex_encode(d.sent()[0]), "aa0bf0241302080000b3bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// a time the appliance would refuse is not written
fn test_pr_115_45() {
    let d = device();
    d.set("night_care_start", "23:45");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a time the appliance would refuse is not written
fn test_pr_115_46() {
    let d = device();
    d.set("night_care_start", "24:00");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a time the appliance would refuse is not written
fn test_pr_115_47() {
    let d = device();
    d.set("night_care_start", "9_30");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a time the appliance would refuse is not written
fn test_pr_115_48() {
    let d = device();
    d.set("night_care_start", "abc");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a time the appliance would refuse is not written
fn test_pr_115_49() {
    let d = device();
    d.set("night_care_start", "");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a time the appliance would refuse is not written
fn test_pr_115_50() {
    let d = device();
    d.set("night_care_start", "07_1");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// an unknown option is refused rather than guessed
fn test_pr_115_51() {
    let d = device();
    d.set("buzzer", "invalidvolume");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("end_melody", "jingle_bells_intro");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("course", "styling_standard");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the power switch reports OFF as soon as it is switched off
fn test_pr_115_52() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000100010001000001000000000000200000000000000000014e42000004030000000000000025969ebb");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("power", "false");
    expect_props(d, #{"status": "standby", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240101009cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a003a0053ea000100eb002800000100010001000001000000000000200000000000000000014e42000004030000000000000025969ebb");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// every user-facing name and enum option is English
fn test_pr_115_53() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// real captured frame decodes to what LG read from the same frame
fn test_pr_115_54() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a second real frame with a different sequence number decodes identically
fn test_pr_115_55() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a second real frame with a different sequence number decodes identically
fn test_pr_115_56() {
    let d = device();
    d.feed("aaff310a003a005504000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000251351bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each probed offset moves exactly the field LG said it moves
fn test_pr_115_57() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a003a0053ea000100eb002800000100010001000001000000000000200000000000000000014e42000004030000000000000025969ebb");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each probed offset moves exactly the field LG said it moves
fn test_pr_115_58() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a003a0053ea000100eb002800000000010001010001000000000000200000000000000000014e42000004030000000000000025ffd9bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "styling_standard", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37", "course_select": "styling_standard"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each probed offset moves exactly the field LG said it moves
fn test_pr_115_59() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a003a0053ea000100eb002800000000010001000101000000000000200000000000000000014e420000040300000000000000252b43bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "true", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each probed offset moves exactly the field LG said it moves
fn test_pr_115_60() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a003a0053ea000100eb002800000000010001000002000000000000200000000000000000014e42000004030000000000000025f05fbb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "styling", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each probed offset moves exactly the field LG said it moves
fn test_pr_115_61() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e42000001030000000000000025b075bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "small", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each probed offset moves exactly the field LG said it moves
fn test_pr_115_62() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e4200000403010000000000002535d6bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "vivaldi_winter", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each probed offset moves exactly the field LG said it moves
fn test_pr_115_63() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000010000014e420000040300000000000000258234bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "panel_course", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each probed offset moves exactly the field LG said it moves
fn test_pr_115_64() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e4200000403000000000000000116e3bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "1"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each probed offset moves exactly the field LG said it moves
fn test_pr_115_65() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e42000004040000000000000025c3aebb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "true", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the running-state codes decode, not just the idle ones
fn test_pr_115_66() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the running-state codes decode, not just the idle ones
fn test_pr_115_67() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000300010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "pause", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the running-state codes decode, not just the idle ones
fn test_pr_115_68() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000900010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_save_running", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the running-state codes decode, not just the idle ones
fn test_pr_115_69() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800003200010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "steam_preparing", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the running-state codes decode, not just the idle ones
fn test_pr_115_70() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800003400010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "refreshing", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the running-state codes decode, not just the idle ones
fn test_pr_115_71() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800003700010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "drying", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the running-state codes decode, not just the idle ones
fn test_pr_115_72() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800003900010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "sterilizing", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the running-state codes decode, not just the idle ones
fn test_pr_115_73() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800003a00010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "course_complete", "power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a code LG itself does not define is shown as a code, not as a wrong name
fn test_pr_115_74() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800001400010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"power": "true", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the error codes decode, and Water refill is not off by one
fn test_pr_115_75() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the error codes decode, and Water refill is not off by one
fn test_pr_115_76() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000801000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "true", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the error codes decode, and Water refill is not off by one
fn test_pr_115_77() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000b01000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "true", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the error codes decode, and Water refill is not off by one
fn test_pr_115_78() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001001201000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "true", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the error codes decode, and Water refill is not off by one
fn test_pr_115_79() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001001701000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the error codes decode, and Water refill is not off by one
fn test_pr_115_80() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001001901000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "true", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the error codes decode, and Water refill is not off by one
fn test_pr_115_81() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001001a01000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "true", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the error codes decode, and Water refill is not off by one
fn test_pr_115_82() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001002201000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "true", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the error codes decode, and Water refill is not off by one
fn test_pr_115_83() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000c01000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "true", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// byte 31 is a bitfield, not an enum
fn test_pr_115_84() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb0028000000000100010000010000000000000f0000000000000000014e42000004030000000000000025df93bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "true", "night_dry": "true", "remote_start": "true", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// byte 49 is a bitfield carrying six independent flags
fn test_pr_115_85() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300003f0000000025988abb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "true", "smart_care_finedust": "true", "smart_care_humidity": "true", "smart_care_nightcare": "true", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the night-care window reads back as two clock times
fn test_pr_115_86() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e4200000403000000171e0600257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "23:30", "night_care_end": "06:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the 35-byte frame and the heartbeat carry no state
fn test_pr_115_87() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a00230053ed000101030011100b0306100000008a00000000000000059317bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa0731c302f2bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// hours and minutes are folded into one duration
fn test_pr_115_88() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000001190200000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "85", "initial_time": "120", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a two-record frame is decoded, and it is the LAST record that counts
fn test_pr_115_89() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a0062005cd0000100ec005000000000010001000001000000000000200000000000000000014e4200000403000000000000002500000100010001000000000000000000200000000000000000014e42000004030000000000000025ee3ebb");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "power_off", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a0062005ce5000100ec0050000001011e011e0f0000000000000000280000000000000000014e4200000403000000000000002500000100230023010000000000000000280000000000000000014e42000004030000000000000025042abb");
    expect_props(d, #{"status": "standby", "power": "true", "previous_status": "power_off", "error": "false", "course": "styling_standard", "smart_course": "none", "remaining_time": "35", "initial_time": "35", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "true", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37", "course_select": "styling_standard"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the course-name list frame is not mistaken for state
fn test_pr_115_90() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000000200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff310a0070005ccc00010a86005e0d053230332d3101073230332d312d3101073230332d312d3201073230332d312d3301073230332d312d34010453542d34010453542d35010453542d36010453542d37010453542d38010453542d39010553542d3130000553542d313201ed79bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a set reservation reads as a delay in minutes
fn test_pr_115_91() {
    let d = device();
    d.feed("aaff310a003a0053ea000100eb002800000000010001000001000000000705200000000000000000014e420000040300000000000000257205bb");
    expect_props(d, #{"status": "power_off", "power": "false", "previous_status": "standby", "error": "false", "course": "none", "smart_course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "425", "child_lock": "false", "night_dry": "false", "remote_start": "false", "remote_maintain": "false", "buzzer": "very_large", "end_melody": "default_sound", "keep_last_course": "false", "smart_care_finedust": "false", "smart_care_humidity": "false", "smart_care_nightcare": "false", "night_care_start": "00:00", "night_care_end": "00:00", "download_course": "fur_leather_care", "tcl_count": "37"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}
