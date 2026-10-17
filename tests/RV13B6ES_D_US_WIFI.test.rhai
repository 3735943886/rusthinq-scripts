import "runtime_test" as runtime;

// Tests of RV13B6ES_D_US_WIFI (dryer_rv13_common), ported from upstream rethink's test suite
// (commit 0e57069; live captures correlated against the LG cloud's decoded state). Expected values
// are what upstream's driver publishes, in IL names; the course, dry level and temperature codes
// upstream leaves unknown are its documented "not selected" codes, published as "none".

fn eb_idle() { "aa2330eb001b000029002900000000000100000000280000000100000064000000b6bb" }
fn power_on_normal() { "aa4030ec001b01000a000a00000000000100000040280000000000000064000000001b0100290029030003040001000000402800000000000000640000001dbb" }
fn antibacterial() { "aa4030ec001b01001f001f16000005000100000040280000000000000064000000001b01010a010a080005050001000000402800000000000000640000000cbb" }
fn wrinkle_care_on() { "aa4030ec001b010029002903000304000100000040280000000000000064000000001b010029002903000304000100000050280000000000000064000000f5bb" }
fn wrinkle_care_off() { "aa4030ec001b010029002903000304000100000050280000000000000064000000001b010029002903000304000100000040280000000000000064000000f5bb" }
fn child_lock_on() { "aa4030ec001b010029002903000304000100000040280000000000000064000000001b010029002903000304000100000041280000000000000064000000c4bb" }
fn turbo_steam_on() { "aa4030ec001b010029002903000304000100000000280000000000000064000000001b0100290029030003040001000000002c000000000000006400000041bb" }
fn energy_saver_on() { "aa4030ec001b010029002903000304000100000000280000000000000264000000001b0101030103030003040001000000002a000000000000026400000099bb" }
fn reduce_static_and_load_item() { "aa4030ec001b010029002903000304000100000000280000000000000064000000001b01002700270300030400010000000228000000000000056400000046bb" }
fn starts_drying() { "aa4030ec001b01000a000a100000020001f1000000280000000000000064000000001b32000a000a100000020001f1000000290000000100000064000000ecbb" }
fn pauses() { "aa4030ec001b32000a000a100000020001f1000000290000000100000064000000001b03000a000a100000020001f10000402800000132000000640000007bbb" }
fn resumes() { "aa4030ec001b03000a000a100000020001f1000040280000013200000064000000001b32000a000a100000020001f100000028000001030000006400000065bb" }
fn cooling() { "aa4030ec001b320006000a100000020001f10000002900000e0300000064000000001b330005000a100000020001f100000029000012320000006400000062bb" }
fn ends() { "aa4030ec001b330001000b100000020001f1000000290000243200000064000000001b040001000b100000020001f1000040280000243300000064000000ccbb" }
fn settles_off() { "aa4030ec001b040001000b100000020001f1000040280000243300000064000000001b0000010001000000000001000000402800002404000000640000003fbb" }
fn signal_off() { "aa4030ec001b010036003601000305000400000040280000000000000064000000001b01003600360100030500000000004028000000000000006400000091bb" }
fn signal_low() { "aa4030ec001b010036003601000305000000000040280000000000000064000000001b01003600360100030500010000004028000000000000006400000094bb" }
fn signal_high() { "aa4030ec001b010029002903000304000100000040280000000000000064000000001b010029002903000304000400000040280000000000000064000000c6bb" }

fn fed(frames) { let d = device(); for f in frames { d.feed(f); } d }

// 0xEB single-record frames decode with the same offsets as 0xEC
fn test_a_single_record_frame() {
    expect_props(fed([eb_idle()]), #{ power: "false", status: "off", course: "none", remaining_time: "0" });
}

// power on with Normal selected
fn test_power_on_with_normal() {
    expect_props(fed([power_on_normal()]), #{ power: "true", status: "initial", course: "normal",
        dry_level: "normal", temp: "mid_high", remaining_time: "41", initial_time: "41" });
}

// an hour-plus estimate folds hour and minute into one value
fn test_an_hour_plus_estimate() {
    expect_props(fed([antibacterial()]), #{ course: "antibacterial", dry_level: "very",
        remaining_time: "70", initial_time: "70" });
}

// Wrinkle Care is read from rec[15] bit 0x10, not rec[16]
fn test_wrinkle_care_is_in_the_first_options_byte() {
    expect_props(fed([wrinkle_care_on()]), #{ wrinkle_care: "true", energy_saver: "false", turbo_steam: "false" });
    expect_eq(fed([wrinkle_care_on(), wrinkle_care_off()]).property("wrinkle_care"), "false");
}

// child lock, reduce static and damp dry share rec[15] without collision
fn test_the_first_options_byte_bits() {
    expect_props(fed([child_lock_on()]), #{ child_lock: "true", wrinkle_care: "false", reduce_static: "false" });
    expect_props(fed([reduce_static_and_load_item()]), #{ reduce_static: "true", child_lock: "false", wrinkle_care: "false" });
}

// load item count is reported from rec[23]
fn test_the_load_items() {
    expect_eq(fed([reduce_static_and_load_item()]).property("load_item"), "5");
}

// turbo steam and energy saver share rec[16]
fn test_turbo_steam_and_energy_saver() {
    expect_props(fed([turbo_steam_on()]), #{ turbo_steam: "true", energy_saver: "false" });
    // energy saver stretches the estimate
    expect_props(fed([energy_saver_on()]), #{ energy_saver: "true", turbo_steam: "false", remaining_time: "63" });
}

// More/Less Time is a signed trim of the course default
fn test_more_less_time_is_signed() {
    // Speed Dry's 25 min default trimmed to 10
    expect_props(fed([starts_drying()]), #{ more_less_time: "-15", remaining_time: "10" });
}

// remote start is visible in rec[16] bit 0x01
fn test_remote_start() {
    expect_eq(fed([starts_drying()]).property("remote_start"), "true");
    expect_eq(fed([starts_drying(), pauses()]).property("remote_start"), "false");
}

// a real run: Initial -> Drying -> Pause -> Drying -> Cooling
fn test_a_real_run() {
    // Speed Dry does not sense dryness: the cloud's NO_DRYLEVEL
    expect_props(fed([starts_drying()]), #{ status: "drying", course: "speed_dry", temp: "low", dry_level: "none" });
    expect_eq(fed([starts_drying(), pauses()]).property("status"), "paused");
    expect_eq(fed([starts_drying(), pauses(), resumes()]).property("status"), "drying");
    // the remaining time counts down while the initial estimate stays pinned
    expect_props(fed([starts_drying(), pauses(), resumes(), cooling()]), #{ status: "cooling",
        remaining_time: "5", initial_time: "10" });
}

// the run finishes: Cooling -> End -> Off, and Off clears the selection
fn test_the_run_finishes() {
    expect_props(fed([starts_drying(), resumes(), cooling(), ends()]), #{ status: "end", power: "true" });
    expect_props(fed([starts_drying(), resumes(), cooling(), ends(), settles_off()]), #{ status: "off",
        power: "false", course: "none", remaining_time: "0", more_less_time: "0" });
}

// the Signal beeper setting is read from rec[11]
fn test_the_signal_beeper() {
    expect_eq(fed([signal_off()]).property("signal"), "off");
    expect_eq(fed([signal_low()]).property("signal"), "low");
    // pressing Signal does not disturb the neighbouring fields
    expect_props(fed([signal_high()]), #{ signal: "high", course: "normal", dry_level: "normal" });
}

// start() requests a status snapshot, so a reconnect does not leave HA blank
fn test_start_asks_for_the_status() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 1);
    expect_eq(hex_encode(d.sent()[0]), "aa0ef0ed1121010000001800b5bb");
}

// the reply to start() decodes as an ordinary status frame
fn test_the_reply_to_start_decodes_as_status() {
    let d = device();
    d.start();
    d.feed(eb_idle());
    expect_props(d, #{ status: "off", power: "false" });
}

// frames that are not status frames publish nothing
fn test_other_frames_publish_nothing() {
    for junk in ["aa0730d82b91bb", "aa09307200c80048bb", "aa0a30ec001b010029bb"] {
        let d = device();
        d.feed(junk);
        expect_eq(d.property("available"), (), junk);
    }
}
