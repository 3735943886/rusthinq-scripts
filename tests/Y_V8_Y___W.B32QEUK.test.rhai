import "runtime_test" as runtime;

// Tests of Y_V8_Y___W.B32QEUK (washer_y8_common), ported from upstream rethink's test suite
// (commit 0e57069; captures from an FSR7A04PG). Expected values and writes are what upstream's
// driver publishes and sends for the same input, in IL names; door_lock and child_lock are true
// while locked (upstream publishes them inverted, for Home Assistant's lock class).

fn sample_initial() { "AAFF200A0039000381000100EB0027000001032603260000000000000000000000000003000011007100000000000000000000000000974EBB" }
fn sample_running_door_locked() { "AAFF200A0039000398000100EB0027000006000E000E0C0003020201000000014220000101001100710000010000000000000000000056D9BB" }
fn sample_rinsing() { "AAFF200A00390003C6000100EB0027000007000B000E0C000302000100000001420000010600110071000001000022000000000000004970BB" }
fn sample_spinning() { "AAFF200A0039000435000100EB00270000080005000E0C00000200000000000042000001070011007100000100002600000000000000AF09BB" }
fn sample_end() { "AAFF200A0039000478000100EB002700000A0000000E0C00000000000000000040000001080011007100000100002900000000000000C901BB" }
fn sample_power_off() { "AAFF200A0039000487000100EB00270000000000000E0C000000000000000000000000000A0011007100000100002900000000000000CB19BB" }
fn pair_power_on() { "AAFF200A006000027F000100EC004E00000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000E0048000000000000000000000000006E4BBB" }
fn pair_course_selected() { "AAFF200A0060000286000100EC004E00000100000000000000000000000000000000000000000E004800000000000000000000000000000001003B003B3A00030A0401000000000001000200000E0048000004000000000000000000004282BB" }
fn pair_steam_and_60c() { "AAFF200A0060000288000100EC004E000001003B003B3A00030A0401000000000001000200000E004800000400000000000000000000000001013201323A00030A0601000000800001000300000E0048000004000000000000000000000709BB" }
fn pair_power_off() { "AAFF200A006000028B000100EC004E000001013201323A00030A0601000000800001000300000E004800000400000000000000000000000000013201323A0000000000000000000001000301000E004800000400000000000000000000BEFABB" }
fn pair_hygiene_selected() { "AAFF200A006000074F000100EC004E00000100000000000000000000000000004200000000000E004800000000000000000000000000000001023002302D00030A0601000000804200000000480E00480000000000000000000000C000B72ABB" }

fn last(d) { let s = d.sent(); hex_encode_upper(s[s.len() - 1]) }

fn unmapped_course() { "AAFF200A006000074F000100EC004E00000100000000000000000000000000004200000000000E004800000000000000000000000000000001023002306300030A06010000008042000000005A0E00480000000000000000000000C000B72ABB" }

// config is published on construction
fn test_the_descriptor_offers_the_states() {
    let d = device();
    d.start();
    let status = runtime::descriptor(d).props.status.options;
    expect(status.contains("washing") && status.contains("error"), "states");
}

// initial state push decodes status, time and cycles
fn test_initial() {
    let d = device();
    d.feed(sample_initial());
    expect_props(d, #{ power: "true", status: "standby", error: "false", error_message: "OK", remaining_time: "218", initial_time: "218", cycles: "17", energy: "0", remote_start: "false", door_lock: "false", child_lock: "false", reserve_time: "0", turbo_wash: "false" });
}

// running state with door locked + remote_start active
fn test_running_door_locked() {
    let d = device();
    d.feed(sample_running_door_locked());
    expect_props(d, #{ status: "washing", course: "speed_14", spin: "400", temp: "20", initial_time: "14", remaining_time: "14", remote_start: "true", door_lock: "true", child_lock: "false", wrinkle_care: "false", turbo_wash: "true", steam: "false", pre_wash: "false", soil: "normal", ai_dd: "false", rinse: "normal", reserve_time: "0" });
}

// spin holds for the whole cycle and energy accumulates
fn test_spin_holds_and_energy_accumulates() {
    let d = device();
    d.feed(sample_running_door_locked());
    expect_props(d, #{ spin: "400", energy: "0" });
    d.feed(sample_rinsing());
    expect_props(d, #{ spin: "400", energy: "34" });
    d.feed(sample_spinning());
    expect_props(d, #{ spin: "400", energy: "38" });
    d.feed(sample_end());
    expect_props(d, #{ energy: "41" });
    d.feed(sample_power_off());
    expect_props(d, #{ energy: "41" });
}

// rinsing state
fn test_rinsing() {
    let d = device();
    d.feed(sample_rinsing());
    expect_props(d, #{ status: "rinsing", remaining_time: "11" });
}

// spinning state
fn test_spinning() {
    let d = device();
    d.feed(sample_spinning());
    expect_props(d, #{ status: "spinning" });
}

// end state
fn test_end() {
    let d = device();
    d.feed(sample_end());
    expect_props(d, #{ status: "end", remaining_time: "0", door_lock: "true", remote_start: "false" });
}

// power-off transition (status=0)
fn test_power_off() {
    let d = device();
    d.feed(sample_power_off());
    expect_props(d, #{ power: "false", status: "off" });
}

// a status envelope is acked, so the appliance stops retransmitting it
fn test_a_status_envelope_is_acked() {
    let d = device();
    d.feed(sample_initial());
    let clips = d.clips();
    expect_eq(clips.len(), 1);
    expect_eq(clips[0].cmd, "ack");
    expect_eq(clips[0].data, "AA0AF0000A04038163BB");
    expect_eq(d.sent().len(), 0);
}

// The cloud's acks for captured frames, from upstream rethink 09f2530 (formerly the host's
// reference vectors): envelopes carry their sequence number; the appliance's own acks, 0xC3
// heartbeats, EB/EC records and frames too short or malformed to read are not acked.
fn test_ack_frames_match_the_cloud() {
    for pair in [
        ["aaff310a00230053ed000101030011100b0306100000008a00000000000000059317bb", "AA0AF0000A0453EDA7BB"],
        ["aaff200a00120010130001007f0000e91dbb", "AA0AF0000A04101380BB"],
        ["aa11200a00110010b00001007f000063bb", "AA0AF0000A0410B027BB"],
        ["aa0720d801ffbb", "AA08F000D8042BBB"],
        ["aa0720720111bb", "AA08F00072044DBB"],
        ["aa0720e901eebb", "AA08F000E904DABB"],
    ] {
        let d = device();
        d.feed(pair[0]);
        let clips = d.clips();
        expect_eq(clips.len(), 1, pair[0]);
        expect_eq(clips[0].data, pair[1], pair[0]);
    }
    for frame in [
        "AA084000430060BB", "aa0731c302f2bb", "aa0720eb01e8bb", "aa0720ec01ebbb", "0102030405",
        "AA08200A01020304BB", "aaff200a00110010120001007f00decabb", "aa10200a00100010c00001007f0011bb",
    ] {
        let d = device();
        d.feed(frame);
        expect_eq(d.clips().len(), 0, frame);
    }
}

// 0x00ec state pairs: switching on is reported, so the power switch holds
fn test_pair_power_on() {
    let d = device();
    d.feed(pair_power_on());
    expect_props(d, #{ power: "true", status: "standby", cycles: "14" });
}

// 0x00ec state pairs: a course selected on the panel reaches HA
fn test_pair_course_selected() {
    let d = device();
    d.feed(pair_course_selected());
    expect_props(d, #{ course: "ai_wash", spin: "1400", temp: "40", initial_time: "59", remaining_time: "59", ai_dd: "true", steam: "false", soil: "normal" });
}

// 0x00ec state pairs: the replacing record wins, not the one being replaced
fn test_the_replacing_record_wins() {
    let d = device();
    d.feed(pair_steam_and_60c());
    expect_props(d, #{ temp: "60", steam: "true", spin: "1400", course: "ai_wash", initial_time: "110", crease_care: "false", pre_wash: "false", medic_rinse: "false", steam_softener: "false" });
}

// 0x00ec state pairs: switching off is reported
fn test_pair_power_off() {
    let d = device();
    d.feed(pair_steam_and_60c());
    expect_props(d, #{ steam: "true" });
    d.feed(pair_power_off());
    expect_props(d, #{ power: "false", status: "off", steam: "false" });
}

// 0x00ec state pairs: an envelope whose payload is shorter than it claims is ignored
fn test_a_short_envelope_is_ignored() {
    let d = device();
    d.feed("AA13200A001300028B000100EC004E00010203BB");
    expect_eq(d.property("power"), ());
}

// a downloaded course is reported separately from the base course it is built on
fn test_downloaded_course() {
    let d = device();
    d.feed(pair_hygiene_selected());
    expect_props(d, #{ smart_course: "hygiene", course: "allergy_spa_steam", temp: "60", steam: "true", spin: "1400", rinse: "normal" });
}

// an unmapped course is not published
fn test_an_unmapped_course_is_not_published() {
    let d = device();
    d.feed(unmapped_course());
    expect_eq(d.property("course"), ());
    expect_eq(d.property("smart_course"), ());
}

// start() sends the F0ED initialisation packet; HA write power=ON / power=OFF / pause button
fn test_query_power_and_pause() {
    let d = device();
    d.start();
    expect_eq(last(d), "AA0EF0ED1121010000001800B5BB");
    d.set("power", "true");
    expect_eq(last(d), "AA08F02A010098BB");
    d.set("power", "false");
    expect_eq(last(d), "AA09F0240101009CBB");
    d.set("pause", "");
    expect_eq(last(d), "AA09F02404010099BB");
}

// HA write start button. Upstream sends it whatever the panel says; here it waits for remote start.
fn test_start_needs_remote_start() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("start", "");
    expect_eq(d.sent().len(), n);
    d.feed(sample_running_door_locked());
    d.set("start", "");
    expect_eq(last(d), "AA09F02405010098BB");
}

// HA write to unknown property emits no packet
fn test_unknown_and_read_only_writes_are_rejected() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("does-not-exist", "whatever");
    d.set("status", "off");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "rejects are published");
}

// frames not matching the AA..BB envelope / with wrong inner length are ignored
fn test_other_frames_are_ignored() {
    let d = device();
    d.feed("001122");
    d.feed("AA08200A01020304BB");
    expect_eq(d.property("status"), ());
}

// running a programme: the assembled command matches the one the LG app sends. Remote start is
// armed by a running record first, whose TurboWash is then switched off.
fn test_the_programme_matches_the_lg_app() {
    let d = device();
    d.feed(sample_running_door_locked());
    d.set("target_course", "allergy_spa_steam");
    d.set("target_soil", "normal");
    d.set("target_spin", "max");
    d.set("target_temp", "60");
    d.set("target_rinse", "normal");
    d.set("target_steam", "true");
    d.set("target_turbo_wash", "false");
    d.set("start_course", "");
    expect_eq(last(d), "AA16F0262D03FF06010000000080030000000000DABB");
}

// running a programme: an untouched start runs what the appliance already reports
fn test_an_untouched_programme_runs_what_is_reported() {
    let d = device();
    d.feed(pair_hygiene_selected());
    d.set("start_course", "");
    expect_eq(last(d), "AA16F0262D030A06010000000080030000000000CFBB");
}

// running a programme: a chosen setting overrides the reported one, and is released once it has run
fn test_a_chosen_setting_is_released_once_run() {
    let d = device();
    d.feed(pair_hygiene_selected());
    expect_eq(d.property("target_temp"), "60");
    d.set("target_temp", "30");
    expect_eq(d.property("target_temp"), "30");
    d.set("start_course", "");
    expect_eq(last(d), "AA16F0262D030A03010000000080030000000000C2BB");
    d.feed(pair_hygiene_selected());
    expect_eq(d.property("target_temp"), "60");
}

// running a programme: option switches set and clear their own bit only
fn test_option_targets_set_and_clear_their_own_bit() {
    let d = device();
    d.feed(pair_hygiene_selected());
    d.set("target_pre_wash", "true");
    d.set("start_course", "");
    expect_eq(last(d), "AA16F0262D030A060100000000C00300000000008FBB");
    d.feed(pair_hygiene_selected());
    d.set("target_steam", "false");
    d.set("start_course", "");
    expect_eq(last(d), "AA16F0262D030A060100000000000300000000004FBB");
}

// running a programme: an idle appliance leaves every select in a state it offers
fn test_an_idle_appliance_leaves_the_targets_valid() {
    let d = device();
    d.start();
    d.feed(sample_power_off());
    let props = runtime::descriptor(d).props;
    for p in ["target_course", "target_temp", "target_spin", "target_rinse", "target_soil"] {
        expect(props[p].options.contains(d.property(p)), p);
    }
}

// running a programme: a delayed end outside the range the appliance accepts is ignored
fn test_a_delay_end_outside_the_range_is_rejected() {
    let d = device();
    d.start();
    d.set("target_delay_end", "5");
    expect_eq(d.property("target_delay_end"), "5");
    d.set("target_delay_end", "1");
    expect_eq(d.property("target_delay_end"), "5");
    d.set("target_delay_end", "0");
    expect_eq(d.property("target_delay_end"), "0");
}
