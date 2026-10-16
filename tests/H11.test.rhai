import "runtime_test" as runtime;

// Tests of H11.rhai (dishwasher), ported from upstream rethink's test suite (commit
// 0e57069; real captures; commands are the ones LG's app was captured sending). Expected values and writes are what upstream's driver
// publishes and sends for the same input.

fn express_starts_running() { "AA6232EC0018010000012E0800012E0000100C00014146640240001000050D050F00020103CE003E0103CE003E0103CE003E0018020200012E0800012E0000100C00014146640240001000050D050F00020103CE003E0103CE003E0103CE003EDABB" }
fn express_starts_rinsing() { "AA6232EC0018020200003B0800002F00001000000141466402400020000F0D050F00040103CE003E0103CE003E0103CE003E0018020300003B0800002F00001000000141466402400020000F0D050F00040103CE003E0103CE003E0103CE003E9ABB" }
fn express_starts_drying() { "AA6232EC0018020300003B0800000100001000000141466402400020000F0D050F00040103CE003E0103CE003E0103CE003E0018020400003B08000001000010000001414E6402400020000F0D050F00040103CE003E0103CE003E0103CE003E2CBB" }
fn express_ends() { "AA6232EC0018020400003B08000001000012000001414E6402400020000F0D050F00040103CE003E0103CE003E0103CE003E0018050500003B08000001000012000001414E6402400020000F0D050F00040103CE003E0103CE003E0103CE003EDFBB" }
fn express_returns_to_standby() { "AA6232EC0018050500003B08000001000012000001414E6402400020000F0D050F00040103CE003E0103CE003E0103CE003E0818040000003B00000001000012000001414C6402400000000F0D050F00040103CE003E0103CE003E0103CE003E33BB" }
fn one_hour_selected() { "AA6232EC0018040000011E0000000100001000000141446402400000000F0D050F00040103CE003E0103CE003E0103CE003E0818010000011E1200011E00001000000141466402400020000F0D050F00040103CE003E0103CE003E0103CE003E6CBB" }
fn standby_snapshot() { "AA3432EB0018040000012E0000012E0000100000014144640240000000050D050F00020103CE003E0103CE003E0103CE003E5CBB" }
fn settings_baseline() { "AA6232EC0018010000013A0800013A0000140C010143466402400020000F0D050F00040103CE003E0103CE003E0103CE003E0018010000013A0800013A0000100C000143466402400020000F0D050F00040103CE003E0103CE003E0103CE003EA8BB" }
fn machine_clean_reserved() { "AA6232EC0018020100012209010122003B1001000141466402400D00000D0D050F00000103CE003E0103CE003E0103CE003E0018020100012209010122003A1001000141466402400D00000D0D050F00000103CE003E0103CE003E0103CE003E9CBB" }
fn cancel_starts_draining() { "AA6232EC0018020200002F0800002E00001000000143466402400010000D0D050F00000103CE003E0103CE003E0103CE003E0018026300002F0000000100001000000143446402400000000D0D050F00000103CE003E0103CE003E0103CE003EF7BB" }
fn cancel_stops_draining() { "AA6232EC0018026300002F0000000100001000000143446402400000000D0D050F00000103CE003E0103CE003E0103CE003E0018010000002F0800002F00001000000143466402400010000D0D050F00000103CE003E0103CE003E0103CE003EF5BB" }
fn energy_total_314() { "AA0B323E0092013A02A1BB" }
fn energy_total_346() { "AA0B323E00C1015A0216BB" }

fn last(d) { let s = d.sent(); hex_encode_upper(s[s.len() - 1]) }

fn test_express_starts_running() {
    let d = device();
    d.feed(express_starts_running());
    expect_props(d, #{ status: "running", process: "washing", power: "true", course: "express", initial_time: "106", remaining_time: "106", delay_start_time: "0", door: "false", extra_dry: "true", high_temp: "true", remote_start: "false", rinse_level: "0", salt_level: "1", auto_dry: "true", clean_reminder: "false", buzzer_level: "low", remote_start_mode: "one_time", end_of_cycle_tone: "true", brightness: "high", extra_rinse: "1" });
}

fn test_express_starts_rinsing() {
    let d = device();
    d.feed(express_starts_rinsing());
    expect_props(d, #{ status: "running", process: "rinsing", power: "true", course: "express", initial_time: "59", remaining_time: "47", delay_start_time: "0", door: "false", extra_dry: "false", high_temp: "false", remote_start: "false", rinse_level: "0", salt_level: "1", auto_dry: "true", clean_reminder: "false", buzzer_level: "low", remote_start_mode: "one_time", end_of_cycle_tone: "true", brightness: "high", extra_rinse: "2" });
}

fn test_express_starts_drying() {
    let d = device();
    d.feed(express_starts_drying());
    expect_props(d, #{ status: "running", process: "drying", power: "true", course: "express", initial_time: "59", remaining_time: "1", delay_start_time: "0", door: "false", extra_dry: "false", high_temp: "false", remote_start: "false", rinse_level: "0", salt_level: "1", auto_dry: "true", clean_reminder: "false", buzzer_level: "low", remote_start_mode: "one_time", end_of_cycle_tone: "true", brightness: "high", extra_rinse: "2" });
}

fn test_express_ends() {
    let d = device();
    d.feed(express_ends());
    expect_props(d, #{ status: "finished", process: "finished", power: "true", course: "express", initial_time: "59", remaining_time: "1", delay_start_time: "0", door: "true", extra_dry: "false", high_temp: "false", remote_start: "false", rinse_level: "0", salt_level: "1", auto_dry: "true", clean_reminder: "false", buzzer_level: "low", remote_start_mode: "one_time", end_of_cycle_tone: "true", brightness: "high", extra_rinse: "2" });
}

fn test_express_returns_to_standby() {
    let d = device();
    d.feed(express_returns_to_standby());
    expect_props(d, #{ status: "standby", process: "none", power: "false", course: "off", initial_time: "59", remaining_time: "1", delay_start_time: "0", door: "true", extra_dry: "false", high_temp: "false", remote_start: "false", rinse_level: "0", salt_level: "1", auto_dry: "true", clean_reminder: "false", buzzer_level: "low", remote_start_mode: "one_time", end_of_cycle_tone: "true", brightness: "high", extra_rinse: "0" });
}

fn test_one_hour_selected() {
    let d = device();
    d.feed(one_hour_selected());
    expect_props(d, #{ status: "ready", process: "none", power: "true", course: "one_hour", initial_time: "90", remaining_time: "90", delay_start_time: "0", door: "false", extra_dry: "false", high_temp: "false", remote_start: "false", rinse_level: "0", salt_level: "1", auto_dry: "true", clean_reminder: "false", buzzer_level: "low", remote_start_mode: "one_time", end_of_cycle_tone: "true", brightness: "high", extra_rinse: "2" });
}

fn test_standby_snapshot() {
    let d = device();
    d.feed(standby_snapshot());
    expect_props(d, #{ status: "standby", process: "none", power: "false", course: "off", initial_time: "106", remaining_time: "106", delay_start_time: "0", door: "false", extra_dry: "false", high_temp: "false", remote_start: "false", rinse_level: "0", salt_level: "1", auto_dry: "true", clean_reminder: "false", buzzer_level: "low", remote_start_mode: "one_time", end_of_cycle_tone: "true", brightness: "high", extra_rinse: "0" });
}

fn test_settings_baseline() {
    let d = device();
    d.feed(settings_baseline());
    expect_props(d, #{ status: "ready", process: "none", power: "true", course: "express", initial_time: "118", remaining_time: "118", delay_start_time: "0", door: "false", extra_dry: "true", high_temp: "true", remote_start: "true", rinse_level: "0", salt_level: "1", auto_dry: "true", clean_reminder: "false", buzzer_level: "low", remote_start_mode: "one_time", end_of_cycle_tone: "true", brightness: "high", extra_rinse: "2" });
}

fn test_machine_clean_reserved() {
    let d = device();
    d.feed(machine_clean_reserved());
    expect_props(d, #{ status: "running", process: "reserved", power: "true", course: "machine_clean", initial_time: "94", remaining_time: "94", delay_start_time: "58", door: "false", extra_dry: "false", high_temp: "false", remote_start: "false", rinse_level: "0", salt_level: "1", auto_dry: "true", clean_reminder: "false", buzzer_level: "low", remote_start_mode: "one_time", end_of_cycle_tone: "true", brightness: "high", extra_rinse: "0" });
}

fn test_cancel_starts_draining() {
    let d = device();
    d.feed(cancel_starts_draining());
    expect_props(d, #{ status: "running", process: "cancelled", power: "true", course: "off", initial_time: "47", remaining_time: "1", delay_start_time: "0", door: "false", extra_dry: "false", high_temp: "false", remote_start: "true", rinse_level: "0", salt_level: "1", auto_dry: "true", clean_reminder: "false", buzzer_level: "low", remote_start_mode: "one_time", end_of_cycle_tone: "true", brightness: "high", extra_rinse: "0" });
}

fn test_cancel_stops_draining() {
    let d = device();
    d.feed(cancel_stops_draining());
    expect_props(d, #{ status: "ready", process: "none", power: "true", course: "express", initial_time: "47", remaining_time: "47", delay_start_time: "0", door: "false", extra_dry: "false", high_temp: "false", remote_start: "true", rinse_level: "0", salt_level: "1", auto_dry: "true", clean_reminder: "false", buzzer_level: "low", remote_start_mode: "one_time", end_of_cycle_tone: "true", brightness: "high", extra_rinse: "1" });
}

fn test_energy_total_314() {
    let d = device();
    d.feed(energy_total_314());
    expect_props(d, #{ energy: "314" });
}

fn test_energy_total_346() {
    let d = device();
    d.feed(energy_total_346());
    expect_props(d, #{ energy: "346" });
}

fn test_writes_match_upstream() {
    for w in [
        ["-", [["power", "true"]], "AA07F0261688BB"],
        ["-", [["power", "false"]], "AA07F026128CBB"],
        ["-", [["pause", "PRESS"]], "AA07F026138FBB"],
        ["-", [["resume", "PRESS"]], "AA07F026148EBB"],
        ["-", [["cancel", "PRESS"]], "AA07F026118DBB"],
        ["SETTINGS_BASELINE", [["rinse_level", "0"]], "AA0EF0260001624040000000E4BB"],
        ["SETTINGS_BASELINE", [["rinse_level", "3"]], "AA0EF0260301624040000000E1BB"],
        ["SETTINGS_BASELINE", [["rinse_level", "4"]], "AA0EF0260401624040000000E0BB"],
        ["SETTINGS_BASELINE", [["salt_level", "0"]], "AA0EF0260000624040000000E5BB"],
        ["SETTINGS_BASELINE", [["salt_level", "2"]], "AA0EF0260002624040000000E7BB"],
        ["SETTINGS_BASELINE", [["salt_level", "4"]], "AA0EF0260004624040000000E1BB"],
        ["SETTINGS_BASELINE", [["buzzer_level", "high"]], "AA0EF0260001644040000000E6BB"],
        ["SETTINGS_BASELINE", [["buzzer_level", "low"]], "AA0EF0260001624040000000E4BB"],
        ["SETTINGS_BASELINE", [["buzzer_level", "off"]], "AA0EF0260001604040000000FABB"],
        ["SETTINGS_BASELINE", [["end_of_cycle_tone", "false"]], "AA0EF026000122404000000024BB"],
        ["SETTINGS_BASELINE", [["clean_reminder", "true"]], "AA0EF02600016A4040000000ECBB"],
        ["SETTINGS_BASELINE", [["auto_dry", "false"]], "AA0EF0260001424040000000C4BB"],
        ["SETTINGS_BASELINE", [["brightness", "low"]], "AA0EF026000162400000000024BB"],
        ["SETTINGS_BASELINE", [["remote_start_mode", "permanent"]], "AA0EF0260001628040000000A4BB"],
        ["SETTINGS_BASELINE", [["remote_start_mode", "one_time"]], "AA0EF0260001624040000000E4BB"],
        ["SETTINGS_BASELINE", [["remote_start_mode", "off"]], "AA0EF026000162C04000000064BB"],
        ["SETTINGS_BASELINE", [["start_course", "PRESS"]], "AA0DF026100100000000008BBB"],
        ["SETTINGS_BASELINE", [["target_course", "one_hour"], ["target_high_temp", "true"], ["target_extra_dry", "true"], ["target_extra_rinse", "1"], ["start_course", "PRESS"]], "AA0DF026101200000C080056BB"],
        ["SETTINGS_BASELINE", [["target_course", "one_hour"], ["target_high_temp", "true"], ["target_extra_dry", "true"], ["target_extra_rinse", "1"], ["target_delay", "1"], ["start_course", "PRESS"]], "AA0DF026101201000C080051BB"],
        ["SETTINGS_BASELINE", [["target_course", "download_cycle"], ["start_course", "PRESS"]], "AA0DF026100B00000040007DBB"],
        ["SETTINGS_BASELINE", [["target_course", "machine_clean"], ["target_extra_rinse", "3"], ["target_delay", "12"], ["start_course", "PRESS"]], "AA0DF02610090C000018005FBB"],
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
        "SETTINGS_BASELINE" => settings_baseline(),
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

fn test_start_publishes_the_staged_defaults_and_course_options_are_distinct() {
    let d = device();
    d.start();
    expect_props(d, #{ target_course: "auto", target_delay: "0", target_high_temp: "false",
                       target_extra_dry: "false", target_extra_rinse: "0" });
    let options = runtime::descriptor(d).props.course.options;
    expect_eq(options.filter(|o| o == "machine_clean").len(), 1);
    expect(!runtime::descriptor(d).props.target_course.options.contains("off"), "off cannot be started");
}

fn test_settings_writes_wait_for_a_status_record() {
    let d = device();
    d.start();
    d.set("rinse_level", "3");
    expect_eq(d.sent().len(), 0);
    expect(d.event("reject") != (), "the write is rejected");
}

// The settings baseline with an unknown remote start mode code (byte 16 of the payload 0x06),
// as upstream tests it: no snapshot may be sent with a stale mode.
fn test_an_unknown_remote_start_mode_blocks_settings_writes() {
    let d = device();
    d.start();
    d.feed(settings_baseline());
    d.feed("AA6232EC0018010000013A0800013A0000140C010143466402400020000F0D050F00040103CE003E0103CE003E0103CE003E0018010000013A0800013A0000100C000143066402400020000F0D050F00040103CE003E0103CE003E0103CE003EA8BB");
    d.set("rinse_level", "3");
    expect_eq(d.sent().len(), 0);
}

fn test_start_requires_remote_start_armed() {
    let d = device();
    d.start();
    d.feed(express_starts_running());
    d.set("start_course", "PRESS");
    expect_eq(d.sent().len(), 0);
    expect(d.event("reject") != (), "the start is rejected");
}

fn test_start_sends_nothing() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 0);
}
