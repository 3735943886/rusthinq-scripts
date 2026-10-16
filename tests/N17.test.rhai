import "runtime_test" as runtime;

// Tests of N17.rhai (dishwasher), ported from upstream rethink's test suite (commit
// 0e57069; real captures from an LDNPQ445S; commands are the ones LG's cloud sent). Expected values and writes are what upstream's driver
// publishes and sends for the same input.

fn statistics_zero() { "AA0B323E000000000070BB" }
fn statistics_two_wh() { "AA0B323E00020002017FBB" }
fn ec_real_running() { "AA4432EC001D0202000221010001030000540002008946640000004000010102030500001D020200022101000102000054000200894664000000400001010203050012BB" }
fn ec_real_drying_door_open() { "AA4432EC001D020400022101000019000054000200894E640000004000010102030500001D020400022101000019000056000200894E640000004000010102030500DDBB" }
fn ec_real_complete() { "AA4432EC001D020400022101000001000056000200894E640000004000010102030500001D050500022101000001000056000200894E6400000040000101020305000BBB" }
fn ec_real_turbo_extra_dry() { "AA4432EC001D0100000221010002210000540002008B46640000004000010102030500001D020200021D0400021D0000540402008B46640000004000010102030500D3BB" }
fn ec_real_heavy_high_temp() { "AA4432EC001D010000021D0400021D0000540402008B46640000004000010102030500001D0202000324020003240000540802008B46640000004000010102030500C2BB" }
fn ec_real_delayed_start() { "AA4432EC001D010000021C0500021C0B00560102008946640000004000010102030500001D020100021C0500021C0B00540102008946640000004000010102030500C5BB" }
fn ec_real_normal_steam() { "AA4432EC001D010000021C0500021C0000540002008B46640000004000010102030500001D020200032B0500032B0000548002008B466400000040000101020305004EBB" }
fn ec_real_download_tub_clean() { "AA4432EC001D010000032B0500032B0000548002008B46640000004000010102030500001D020100010009010100003B540102008B4664000001400001010203050077BB" }
fn ec_settings_chime_on() { "AA4432EC001D010000021C0500021C0000560002008946640000004000010102030500001D010000021C0500021C000052000000894664000000400001010203050027BB" }
fn ec_settings_tub_only() { "AA4432EC001D010000021C0500021C0000320000000942640000004000010102030500001D010000021C0500021C000022000000094264000000400001010203050041BB" }
fn ec_settings_status_light_off() { "AA4432EC001D010000021C0500021C0000220000000942640000004000010102030500001D010000021C0500021C000022000000094264000000000001010203050091BB" }
fn ec_settings_rinse_4() { "AA4432EC001D010000021C0500021C0000560004000942640000000000010102030500001D010000021C0500021C000056000400094264000000400001010203050061BB" }
fn foreign_class() { "AA2330EB001B000029002900000000000100000000280000000100000064000000B6BB" }

fn last(d) { let s = d.sent(); hex_encode_upper(s[s.len() - 1]) }

fn test_statistics_zero() {
    let d = device();
    d.feed(statistics_zero());
    expect_props(d, #{ energy: "0" });
}

fn test_statistics_two_wh() {
    let d = device();
    d.feed(statistics_two_wh());
    expect_props(d, #{ energy: "2" });
}

fn test_ec_real_running() {
    let d = device();
    d.feed(ec_real_running());
    expect_props(d, #{ status: "running", process: "washing", course: "auto", initial_time: "153", remaining_time: "62", delay_start_time: "0", door: "false", extra_dry: "false", high_temp: "false", steam: "false", remote_start: "false", rinse_level: "2", chime_sound: "true", end_of_cycle_tone: "true", tub_clean_reminder: "false", clean_indicator_light: "true", automatic_selection: "true", status_indicator_light: "true" });
}

fn test_ec_real_drying_door_open() {
    let d = device();
    d.feed(ec_real_drying_door_open());
    expect_props(d, #{ status: "running", process: "drying", course: "auto", initial_time: "153", remaining_time: "25", delay_start_time: "0", door: "true", extra_dry: "false", high_temp: "false", steam: "false", remote_start: "false", rinse_level: "2", chime_sound: "true", end_of_cycle_tone: "true", tub_clean_reminder: "false", clean_indicator_light: "true", automatic_selection: "true", status_indicator_light: "true" });
}

fn test_ec_real_complete() {
    let d = device();
    d.feed(ec_real_complete());
    expect_props(d, #{ status: "finished", process: "finished", course: "auto", initial_time: "153", remaining_time: "1", delay_start_time: "0", door: "true", extra_dry: "false", high_temp: "false", steam: "false", remote_start: "false", rinse_level: "2", chime_sound: "true", end_of_cycle_tone: "true", tub_clean_reminder: "false", clean_indicator_light: "true", automatic_selection: "true", status_indicator_light: "true" });
}

fn test_ec_real_turbo_extra_dry() {
    let d = device();
    d.feed(ec_real_turbo_extra_dry());
    expect_props(d, #{ status: "running", process: "washing", course: "turbo", initial_time: "149", remaining_time: "149", delay_start_time: "0", door: "false", extra_dry: "true", high_temp: "false", steam: "false", remote_start: "true", rinse_level: "2", chime_sound: "true", end_of_cycle_tone: "true", tub_clean_reminder: "false", clean_indicator_light: "true", automatic_selection: "true", status_indicator_light: "true" });
}

fn test_ec_real_heavy_high_temp() {
    let d = device();
    d.feed(ec_real_heavy_high_temp());
    expect_props(d, #{ status: "running", process: "washing", course: "heavy", initial_time: "216", remaining_time: "216", delay_start_time: "0", door: "false", extra_dry: "false", high_temp: "true", steam: "false", remote_start: "true", rinse_level: "2", chime_sound: "true", end_of_cycle_tone: "true", tub_clean_reminder: "false", clean_indicator_light: "true", automatic_selection: "true", status_indicator_light: "true" });
}

fn test_ec_real_delayed_start() {
    let d = device();
    d.feed(ec_real_delayed_start());
    expect_props(d, #{ status: "running", process: "reserved", course: "normal", initial_time: "148", remaining_time: "148", delay_start_time: "660", door: "false", extra_dry: "false", high_temp: "false", steam: "false", remote_start: "false", rinse_level: "2", chime_sound: "true", end_of_cycle_tone: "true", tub_clean_reminder: "false", clean_indicator_light: "true", automatic_selection: "true", status_indicator_light: "true" });
}

fn test_ec_real_normal_steam() {
    let d = device();
    d.feed(ec_real_normal_steam());
    expect_props(d, #{ status: "running", process: "washing", course: "normal", initial_time: "223", remaining_time: "223", delay_start_time: "0", door: "false", extra_dry: "false", high_temp: "false", steam: "true", remote_start: "true", rinse_level: "2", chime_sound: "true", end_of_cycle_tone: "true", tub_clean_reminder: "false", clean_indicator_light: "true", automatic_selection: "true", status_indicator_light: "true" });
}

fn test_ec_real_download_tub_clean() {
    let d = device();
    d.feed(ec_real_download_tub_clean());
    expect_props(d, #{ status: "running", process: "reserved", course: "tub_clean", initial_time: "60", remaining_time: "60", delay_start_time: "59", door: "false", extra_dry: "false", high_temp: "false", steam: "false", remote_start: "true", rinse_level: "2", chime_sound: "true", end_of_cycle_tone: "true", tub_clean_reminder: "false", clean_indicator_light: "true", automatic_selection: "true", status_indicator_light: "true" });
}

fn test_ec_settings_chime_on() {
    let d = device();
    d.feed(ec_settings_chime_on());
    expect_props(d, #{ status: "ready", process: "none", course: "normal", initial_time: "148", remaining_time: "148", delay_start_time: "0", door: "true", extra_dry: "false", high_temp: "false", steam: "false", remote_start: "false", rinse_level: "0", chime_sound: "true", end_of_cycle_tone: "true", tub_clean_reminder: "false", clean_indicator_light: "true", automatic_selection: "true", status_indicator_light: "true" });
}

fn test_ec_settings_tub_only() {
    let d = device();
    d.feed(ec_settings_tub_only());
    expect_props(d, #{ status: "ready", process: "none", course: "normal", initial_time: "148", remaining_time: "148", delay_start_time: "0", door: "true", extra_dry: "false", high_temp: "false", steam: "false", remote_start: "false", rinse_level: "0", chime_sound: "false", end_of_cycle_tone: "false", tub_clean_reminder: "true", clean_indicator_light: "false", automatic_selection: "false", status_indicator_light: "true" });
}

fn test_ec_settings_status_light_off() {
    let d = device();
    d.feed(ec_settings_status_light_off());
    expect_props(d, #{ status: "ready", process: "none", course: "normal", initial_time: "148", remaining_time: "148", delay_start_time: "0", door: "true", extra_dry: "false", high_temp: "false", steam: "false", remote_start: "false", rinse_level: "0", chime_sound: "false", end_of_cycle_tone: "false", tub_clean_reminder: "true", clean_indicator_light: "false", automatic_selection: "false", status_indicator_light: "false" });
}

fn test_ec_settings_rinse_4() {
    let d = device();
    d.feed(ec_settings_rinse_4());
    expect_props(d, #{ status: "ready", process: "none", course: "normal", initial_time: "148", remaining_time: "148", delay_start_time: "0", door: "true", extra_dry: "false", high_temp: "false", steam: "false", remote_start: "false", rinse_level: "4", chime_sound: "false", end_of_cycle_tone: "false", tub_clean_reminder: "false", clean_indicator_light: "true", automatic_selection: "true", status_indicator_light: "true" });
}

fn test_foreign_class() {
    let d = device();
    d.feed(foreign_class());
    expect_eq(d.property("status"), ());
    expect_eq(d.property("energy"), ());
}

fn test_writes_match_upstream() {
    for w in [
        ["-", [["pause", "PRESS"]], "AA07F026138FBB"],
        ["-", [["resume", "PRESS"]], "AA07F026148EBB"],
        ["EC_REAL_TURBO_EXTRA_DRY", [["cancel", "PRESS"]], "AA07F026118DBB"],
        ["EC_REAL_TURBO_EXTRA_DRY", [["power_off", "PRESS"]], "AA07F026128CBB"],
        ["EC_REAL_TURBO_EXTRA_DRY", [["start_course", "PRESS"]], "AA0DF026100100000000008BBB"],
        ["EC_REAL_TURBO_EXTRA_DRY", [["target_course", "download_cycle"], ["target_delay", "1"], ["start_course", "PRESS"]], "AA0DF026100B0100000000BCBB"],
        ["EC_REAL_TURBO_EXTRA_DRY", [["target_course", "turbo"], ["target_extra_dry", "true"], ["start_course", "PRESS"]], "AA0DF02610040000040000B0BB"],
        ["EC_REAL_TURBO_EXTRA_DRY", [["target_course", "heavy"], ["target_high_temp", "true"], ["start_course", "PRESS"]], "AA0DF02610020000080000B2BB"],
        ["EC_REAL_TURBO_EXTRA_DRY", [["target_course", "normal"], ["target_steam", "true"], ["start_course", "PRESS"]], "AA0DF0261005000080000037BB"],
        ["EC_REAL_TURBO_EXTRA_DRY", [["target_course", "normal"], ["target_steam", "true"], ["target_high_temp", "true"], ["target_extra_dry", "true"], ["start_course", "PRESS"]], "AA0DF026100500008C00003BBB"],
        ["EC_SETTINGS_CHIME_ON", [["chime_sound", "false"]], "AA0EF026000068400001000022BB"],
        ["EC_SETTINGS_RINSE_4", [["rinse_level", "2"]], "AA0EF02602002840000100006CBB"],
        ["EC_SETTINGS_TUB_ONLY", [["status_indicator_light", "false"]], "AA0EF02600000140000000005ABB"],
        ["EC_SETTINGS_CHIME_ON", [["end_of_cycle_tone", "false"]], "AA0EF02600002C40000100006EBB"],
        ["EC_SETTINGS_CHIME_ON", [["tub_clean_reminder", "true"]], "AA0EF02600006D400001000029BB"],
        ["EC_SETTINGS_CHIME_ON", [["clean_indicator_light", "false"]], "AA0EF026000064400001000026BB"],
        ["EC_SETTINGS_CHIME_ON", [["automatic_selection", "false"]], "AA0EF02600004C40000100000EBB"],
        ["EC_SETTINGS_TUB_ONLY", [["chime_sound", "true"]], "AA0EF026000005400001000041BB"],
    ] {
        let d = device();
        d.start();
        if w[0] != "-" { d.feed(fixture(w[0])); }
        for s in w[1] { d.set(s[0], s[1]); }
        expect_eq(last(d), w[2]);
    }
}

fn fixture(name) {
    switch name {
        "EC_REAL_TURBO_EXTRA_DRY" => ec_real_turbo_extra_dry(),
        "EC_SETTINGS_CHIME_ON" => ec_settings_chime_on(),
        "EC_SETTINGS_RINSE_4" => ec_settings_rinse_4(),
        "EC_SETTINGS_TUB_ONLY" => ec_settings_tub_only(),
        _ => ()
    }
}

fn test_unknown_and_read_only_writes_are_rejected() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("does_not_exist", "1");
    d.set("door", "true");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "rejects are published");
}

fn test_start_publishes_the_staged_defaults() {
    let d = device();
    d.start();
    expect_props(d, #{ target_course: "auto", target_high_temp: "false", target_extra_dry: "false",
                       target_steam: "false", target_delay: "0" });
}

// Upstream sends a start regardless and leaves the interlock to the appliance and to Home
// Assistant's availability; here the descriptor's `requires` refuses it.
fn test_start_requires_remote_start_armed() {
    let d = device();
    d.start();
    d.feed(ec_real_running());
    let n = d.sent().len();
    d.set("start_course", "PRESS");
    expect_eq(d.sent().len(), n);
}

fn test_a_course_outside_the_observed_set_cannot_be_staged() {
    let d = device();
    d.start();
    d.feed(ec_real_turbo_extra_dry());
    d.set("target_course", "machine_clean");
    expect_props(d, #{ target_course: "auto" });
    d.set("start_course", "PRESS");
    expect_eq(last(d), "AA0DF026100100000000008BBB");
}

fn test_settings_writes_wait_for_a_status_record() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("chime_sound", "false");
    d.set("rinse_level", "2");
    d.set("rinse_level", "9");
    expect_eq(d.sent().len(), n);
}
