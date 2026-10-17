import "runtime_test" as runtime;

// Tests of WFV474PGV, ported from upstream rethink's test suite (commit 0e57069; live captures).
// Expected values are what upstream's driver publishes, in IL names (ON/OFF as true/false, °F/°C
// as fahrenheit/celsius); what upstream publishes as undefined is absent, an empty retained value.
// Writes are compared byte for byte with upstream's. Where IL differs: the kitchen timer is a
// duration in seconds, not "HH:MM:SS"; the clock is written as "HH:MM" (a script has no host clock
// to sync from); a start needs the cavity's remote start ready (`requires`), as upstream gates it
// in Home Assistant.

fn cooktop_off() { "AA8240EC00000000000000004E0000000000000E000000000000000000004D0000000000000E0000000000000000000000000000000000000000000000000000000000000000000000004D0000000000000E000000000000000000004D0000000000000E0000000000000000000000000000000000000000000000000000000090BB" }
fn cooktop_off_to_on() { "AA8240EC00000000000000004E0000000000000E000000000000000000004D0000000000000E0000000000000000000000000000000000000000000000000000000000000000000000004E00000000000006000000000000000000004D00000000000006000001000300000100030000010003000001000300000100030000009FBB" }
fn cooktop_on_to_off() { "AA8240EC00000000000000004E0000000000000E000000000000000000004D0000000000000E00000100190E000100190E000100190E000100190E000100190E000000000000000000004E0000000000000E000000000000000000004C0000000000000E00000000000000000000000000000000000000000000000000000000D8BB" }
fn timer_09_01_13() { "AA8240EC00000000000000004E0000000000000E000000000000000000004C0000000000000E0000000000000000000000000000000000000000000000000000000000000000000000004E00000000000006000000000000000000004C0000000D010906000000000000000000000000000000000000000000000000000000009EBB" }
fn timer_rollover_09_00_59() { "AA8240EC00000000000000004E00000000000006000000000000000000004C000000010109060000000000000000000000000000000000000000000000000000000000000000000000004E00000000000006000000000000000000004C0000003B00090600000000000000000000000000000000000000000000000000000000A6BB" }
fn timer_stopped() { "AA8240EC00000000000000004E00000000000006000000000000000000004C0000001A3A08060000000000000000000000000000000000000000000000000000000000000000000000004E0000000000000E000000000000000000004D0000000000000E0000000000000000000000000000000000000000000000000000000044BB" }
fn start_accepted_ack() { "AA084000430060BB" }
fn start_rejected_ack() { "AA084000434020BB" }
fn timer_expired_alarm() { "AA13407203F50A0000000000000000000024BB" }
fn both_ovens_remote_start_ready() { "AA8240EC00000000000000004E00000000000006000000000000000000004D000008000000060000000000000000000000000000000000000000000000000000000000000000000000004E00000000000001000000000000000000004C0000000000000100000000000000000000000000000000000000000000000000000000F6BB" }
fn lower_only_remote_start_ready() { "AA8240EC0000000000000000850000000000000E000000000000000000004E0000000000000E0000000000000000000000000000000000000000000000000000000000000000000000008500000000000000000000000000000000004E00000000000001000000000000000000000000000000000000000000000000000000004EBB" }
fn lower_convection_roast_350f_time_off() { "AA8240EC00000000000000008300000000000000000000000000000000004E00000000000001000000000000000000000000000000000000000000000000000000000000000000000000830000000000000200000198000000014500000000000000000200000000000000000000000000000000000000000000000000000000C5BB" }
fn lower_bake_285c_five_minutes() { "AA8240EC0000000000000000FE0000000000000000000000000000000000AF00000000000001000000000000000000000000000000000000000000000000000000000000000000000000FE000000000000020000019500050002210000000000000000020000000000000000000000000000000000000000000000000000000093BB" }
fn lower_bake_285c_four_minutes_59() { "AA8240EC0000000000000000FE00000000000002000001950005000221000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000FE00000000000002000001953B040002210000000000000000020000000000000000000000000000000000000000000000000000000047BB" }
fn lower_bake_cancelled_at_252f() { "AA8240EC0000000000000000F400000000000002000001952702000221000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000F40000000000000600000000000000000000FC00000000000006000000000000000000000000000000000000000000000000000000007BBB" }
fn lower_convection_bake_300f_ten_minutes() { "AA8240EC0000000000000000EC0000000000000000000000000000000000F200000000000001000000000000000000000000000000000000000000000000000000000000000000000000EC0000000000000200000197000A0001130000000000000000020000000000000000000000000000000000000000000000000000000088BB" }
fn lower_convection_bake_300f_nine_minutes_59() { "AA8240EC0000000000000000EC0000000000000200000197000A000113000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000EC00000000000002000001973B09000113000000000000000002000000000000000000000000000000000000000000000000000000008BBB" }
fn lower_convection_bake_preheat_complete() { "AA8240EC0000000000000000EB00000000000002000001973009000113000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000E9000000000000020000029705090001130000000000000000020000000000000000000000000000000000000000000000000000000081BB" }
fn upper_broil_high_with_lower_preheating() { "AA8240EC00000000000000007F0000000000000000000198000000014500000000000000000000000000000000000000000000000000000000000000000000000000020700000001900000000000000000020000019800000001450000000000000000020000000000000000000000000000000000000000000000000000000066BB" }
fn lower_preheat_complete_event() { "AA13407203E90A0000000000000000000030BB" }
fn lower_preheat_complete_with_upper_broil() { "AA8240EC0207000000019000000000000000000200000198000000014500000000000000000200000000000000000000000000000000000000000000000000000000020700000001900000000000000000020000029800000001450000000000000000020000000000000000000000000000000000000000000000000000000006BB" }
fn upper_cancelled_with_lower_active() { "AA8240EC02070000000190000000000000000002000002980000000145000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000CE0000000000000200000298000000014500000000000000000200000000000000000000000000000000000000000000000000000000DDBB" }
fn lower_cancelled() { "AA8240EC0000000000000000CC00000000000002000002980000000145000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000CC000000000000060000000000000000000164000000000000060000000000000000000000000000000000000000000000000000000010BB" }
fn upper_oven_170f_three_minutes() { "AA8240EC00000000000000004E00000000000001000000000000000000004D0000000000000100000000000000000000000000000000000000000000000000000000018100030000AA000000000000000002000000000000000000004D000000000000020000000000000000000000000000000000000000000000000000000020BB" }
fn upper_oven_170f_two_minutes_59() { "AA8240EC018100030000AA000000000000000002000000000000000000004D000000000000020000000000000000000000000000000000000000000000000000000001813B020000AA000000000000000002000000000000000000004D0000000000000200000000000000000000000000000000000000000000000000000000C7BB" }
fn upper_bake_125c_one_hour_three_minutes() { "AA8240EC00000000000000009F0000000000000100000000000000000000D100000000000000000000000000000000000000000000000000000000000000000000000181000301010100000000000000000200000000000000000000D0000000000000020000000000000000000000000000000000000000000000000000000070BB" }
fn upper_bake_125c_one_hour_two_minutes_59() { "AA8240EC0181000301010100000000000000000200000000000000000000D0000000000000020000000000000000000000000000000000000000000000000000000001813B0201010100000000000000000200000000000000000000D100000000000002000000000000000000000000000000000000000000000000000000001EBB" }
fn upper_bake_preheat_complete_event() { "AA13407200010A000000000000000000002FBB" }
fn upper_bake_preheat_complete() { "AA8240EC01813B3A00010100000000000000000200000000000000000000C4000000000000020000000000000000000000000000000000000000000000000000000002811F3A00010100000000000000000200000000000000000000C30000000000000200000000000000000000000000000000000000000000000000000000EBBB" }
fn upper_bake_cancelled_at_266f() { "AA8240EC02813A3500010100000000000000000200000000000000000000B9000000000000020000000000000000000000000000000000000000000000000000000000000000000000010A0000000000000600000000000000000000B6000000000000060000000000000000000000000000000000000000000000000000000083BB" }
fn upper_oven_finished_at_124f() { "AA8240EC018102000000AA000000000000000002000000000000000000004C000000000000020000000000000000000000000000000000000000000000000000000003000000000000007C00000000000000000000000000000000004C0000000000000200000000000000000000000000000000000000000000000000000000F6BB" }
fn upper_oven_finished_event() { "AA13407200040A0000000000000000000028BB" }
fn upper_oven_cleared_at_149f() { "AA8240EC03000000000000009500000000000000000000000000000000004D000000000000020000000000000000000000000000000000000000000000000000000000000000000000009500000000000006000000000000000000004D000000000000060000000000000000000000000000000000000000000000000000000078BB" }

fn all_captures() { [cooktop_off(), cooktop_off_to_on(), cooktop_on_to_off(), timer_09_01_13(), timer_rollover_09_00_59(), timer_stopped(), timer_expired_alarm(), both_ovens_remote_start_ready(), lower_only_remote_start_ready(), lower_convection_roast_350f_time_off(), lower_bake_285c_five_minutes(), lower_bake_285c_four_minutes_59(), lower_bake_cancelled_at_252f(), lower_convection_bake_300f_ten_minutes(), lower_convection_bake_300f_nine_minutes_59(), lower_convection_bake_preheat_complete(), upper_broil_high_with_lower_preheating(), lower_preheat_complete_event(), lower_preheat_complete_with_upper_broil(), upper_cancelled_with_lower_active(), lower_cancelled(), upper_oven_170f_three_minutes(), upper_oven_170f_two_minutes_59(), upper_bake_125c_one_hour_three_minutes(), upper_bake_125c_one_hour_two_minutes_59(), upper_bake_preheat_complete_event(), upper_bake_preheat_complete(), upper_bake_cancelled_at_266f(), upper_oven_finished_at_124f(), upper_oven_finished_event(), upper_oven_cleared_at_149f()] }

fn fed(frames) { let d = device(); d.start(); for f in frames { d.feed(f); } d }
fn hex_at(d, i) { hex_encode_upper(d.sent()[i]) }
fn last_hex(d) { hex_at(d, d.sent().len() - 1) }
// the 13-byte preference payload of a sent frame
fn payload(d, i) { let f = d.sent()[i]; let p = []; for x in f.extract(6, f.len() - 8) { p.push(x.to_int()); } p }
fn frame(inner) { aabb_wrap(inner) }
fn record(temperature, state, mode) {
    let r = []; for i in 0..62 { r.push(0); }
    r[7] = temperature / 256; r[8] = temperature % 256; r[0] = state; r[1] = mode;
    r
}
fn snapshot(d) {
    let m = #{};
    for k in runtime::descriptor(d).props.keys() { m[k] = d.property(k); }
    json_stringify(m)
}
// a device whose cavities both report remote start ready
fn ready() { fed([both_ovens_remote_start_ready()]) }
fn sent_count(d) { d.sent().len() }

// is selected by the Home Assistant bridge and queried on connect
// start sends the exact status query observed from LG cloud
fn test_start_sends_the_status_query() {
    let d = fed([]);
    expect_eq(sent_count(d), 1);
    expect_eq(hex_at(d, 0), "AA28F0ED114101000000181A0207080C14191A1E262B30353A00000000000000000000000000F3BB");
}

// publishes status, confirmed write controls, and diagnostics
fn test_the_descriptor_and_defaults() {
    let d = fed([]);
    let p = runtime::descriptor(d).props;
    expect_eq(p.cooktop_status.type, "binary");
    for k in ["cooktop_status", "upper_oven_temperature", "upper_oven_status", "upper_oven_mode", "upper_oven_set_temperature",
              "upper_oven_cook_time", "lower_oven_temperature", "lower_oven_status", "lower_oven_mode",
              "lower_oven_set_temperature", "lower_oven_cook_time", "upper_oven_remote_start", "lower_oven_remote_start"] {
        expect(p[k].rw != true, k + " is read only");
    }
    expect_eq(p.upper_oven_temperature.unit, "°F");
    expect_eq(p.lower_oven_set_temperature.unit, "°F");
    expect_eq(p.timer.rw, true);
    expect_eq(p.timer_stop.type, "trigger");
    expect_eq(p.clock.type, "text");
    expect_eq(p.beeper_volume.options, ["high", "low", "mute"]);
    expect_eq(p.temperature_unit.options, ["fahrenheit", "celsius"]);
    expect_eq(p.preheat_alarm_light.rw, true);
    expect_eq(p.auto_conversion.rw, true);
    expect_eq(p.upper_temperature_adjustment.min, -35);
    expect_eq(p.upper_temperature_adjustment.max, 35);
    expect_eq(p.upper_temperature_adjustment.unit, "°F");
    expect_eq(p.upper_remote_temperature.min, 170);
    expect_eq(p.lower_remote_temperature.max, 550);
    expect_eq(p.upper_start.requires, "upper_oven_remote_start");
    expect_eq(p.lower_start.requires, "lower_oven_remote_start");
    expect_eq(p.lower_remote_mode.options, ["bake", "convection_bake", "convection_roast"]);
    expect_eq(p.upper_oven_status.options, ["idle", "preheating", "active", "complete"]);
    expect_eq(p.upper_oven_mode.options, ["none", "bake", "broil", "convection_bake", "convection_roast"]);
    // write-only preferences are never published
    for k in ["beeper_volume", "preheat_alarm_light", "temperature_unit", "auto_conversion", "clock",
              "upper_temperature_adjustment", "lower_temperature_adjustment"] { expect_eq(d.property(k), ()); }
    expect_props(d, #{ upper_remote_temperature: "350", upper_remote_cook_time: "10", lower_remote_temperature: "350",
        lower_remote_cook_time: "10", lower_remote_mode: "bake", upper_oven_remote_start: "false",
        lower_oven_remote_start: "false" });
}

// no captured frame publishes an oven state or mode outside the declared options
fn test_every_capture_stays_within_the_options() {
    let d = fed([]);
    let p = runtime::descriptor(d).props;
    for f in all_captures() {
        d.feed(f);
        for k in ["upper_oven_status", "lower_oven_status", "upper_oven_mode", "lower_oven_mode"] {
            let v = d.property(k);
            expect(v == () || v == "" || p[k].options.contains(v), k + " published " + v);
        }
    }
}

// 40 EB decodes its single status block
fn test_the_eb_block() { expect_eq(fed([frame([0x40, 0xeb] + record(350, 0, 0))]).property("upper_oven_temperature"), "350"); }

// 40 EC decodes the second (current) block, not the first
fn test_the_ec_current_block() {
    expect_eq(fed([frame([0x40, 0xec] + record(100, 0, 0) + record(350, 0, 0))]).property("upper_oven_temperature"), "350");
}

// undecoded state and mode bytes publish unknown
fn test_undecoded_state_and_mode_are_absent() {
    let d = fed([frame([0x40, 0xeb] + record(0, 0x7f, 0x7e))]);
    expect_props(d, #{ upper_oven_status: "", upper_oven_mode: "" });
}

// real cooktop transitions publish OFF, ON, then OFF from the five slot flags
fn test_the_cooktop_transitions() {
    let d = fed([cooktop_off()]);
    expect_eq(d.property("cooktop_status"), "false");
    d.feed(cooktop_off_to_on());
    expect_eq(d.property("cooktop_status"), "true");
    d.feed(cooktop_on_to_off());
    expect_eq(d.property("cooktop_status"), "false");
}

// real timer frames decode set, rollover, and stop states
fn test_the_timer_frames() {
    let d = fed([timer_09_01_13()]);
    expect_eq(d.property("timer"), (9 * 3600 + 60 + 13).to_string());
    d.feed(timer_rollover_09_00_59());
    expect_eq(d.property("timer"), (9 * 3600 + 59).to_string());
    d.feed(timer_stopped());
    expect_eq(d.property("timer"), "0");
}

// real timer-expiry alarm event publishes nothing
fn test_the_timer_expiry_event_publishes_nothing() {
    let d = fed([]);
    let before = snapshot(d);
    d.feed(timer_expired_alarm());
    expect_eq(snapshot(d), before);
}

// real set/start, cancel, and rejection acknowledgements publish nothing
fn test_acknowledgements_publish_nothing() {
    let d = fed([]);
    let before = snapshot(d);
    d.feed(start_accepted_ack());
    d.feed("AA084000440063BB");
    d.feed(start_rejected_ack());
    expect_eq(snapshot(d), before);
}

// (IL) a refused start is reported as a reject of that start
fn test_a_refused_start_is_rejected() {
    let d = ready();
    d.set("upper_start", "");
    d.feed(start_rejected_ack());
    let e = d.event("reject");
    expect(e != () && e.contains("upper_start") && e.contains("refused"), "refused start");
}

// timer set and stop send the exact captured commands
fn test_timer_set_and_stop() {
    let d = fed([]);
    d.set("timer", (9 * 3600 + 60 + 13).to_string());
    expect_eq(last_hex(d), "AA0EF04323068080800D0109FEBB");
    d.set("timer_stop", "");
    expect_eq(last_hex(d), "AA0EF0432306808080000000C1BB");
}

// clock sync reproduces the captured 24-hour preference command
fn test_the_clock_write() {
    let d = fed([]);
    d.set("clock", "23:15");
    expect_eq(sent_count(d), 2);
    expect_eq(last_hex(d), "AA15F043210E170F008080808080808080FF8093BB");
}

// the captured 12-hour clock frame differs only in the hour and byte 2
fn test_the_captured_12_hour_clock_frame() {
    let p = |h| { let f = hex_decode(h); let o = []; for x in f.extract(6, f.len() - 8) { o.push(x.to_int()); } o };
    let tail = [0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0xff, 0x80];
    expect_eq(p.call("AA15F043210E0B0C018080808080808080FF80EDBB"), [0x0b, 0x0c, 0x01] + tail);
    expect_eq(p.call("AA15F043210E170F008080808080808080FF8093BB"), [0x17, 0x0f, 0x00] + tail);
}

// clock sync sends the host time and leaves every other preference unchanged
fn test_a_clock_write_leaves_the_rest_unchanged() {
    let d = fed([]);
    d.set("clock", "07:05");
    expect_eq(hex_encode_upper(d.sent()[1].extract(0, 6)), "AA15F043210E");
    expect_eq(payload(d, 1), [7, 5, 0, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0xff, 0x80]);
}

// beeper volume reproduces all three captured commands
fn test_the_beeper_volume() {
    let d = fed([]);
    d.set("beeper_volume", "mute");
    d.set("beeper_volume", "high");
    d.set("beeper_volume", "low");
    expect_eq(sent_count(d), 4);
    expect_eq(hex_at(d, 1), "AA15F043210E8080808080808080008080FF80F5BB");
    expect_eq(hex_at(d, 2), "AA15F043210E8080808080808080028080FF80F7BB");
    expect_eq(hex_at(d, 3), "AA15F043210E8080808080808080018080FF80F4BB");
}

// a preference write leaves every field it does not set at its no-change sentinel
fn test_a_preference_write_leaves_the_rest() {
    let d = fed([]);
    d.set("beeper_volume", "mute");
    let p = payload(d, 1);
    for i in 0..13 { expect_eq(p[i], if i == 8 { 0 } else if i == 11 { 0xff } else { 0x80 }); }
}

// preheating alarm light reproduces both captured commands
fn test_the_preheating_alarm_light() {
    let d = fed([]);
    d.set("preheat_alarm_light", "false");
    d.set("preheat_alarm_light", "true");
    expect_eq(hex_at(d, 1), "AA15F043210E8080808080808000808080FF80F5BB");
    expect_eq(hex_at(d, 2), "AA15F043210E8080808080808001808080FF80F4BB");
}

// temperature unit reproduces both captured commands
fn test_the_temperature_unit() {
    let d = fed([]);
    d.set("temperature_unit", "celsius");
    d.set("temperature_unit", "fahrenheit");
    expect_eq(hex_at(d, 1), "AA15F043210E8080808080808080800180FF80F4BB");
    expect_eq(hex_at(d, 2), "AA15F043210E8080808080808080800080FF80F5BB");
}

// the display temperature unit does not change how status temperatures decode
fn test_the_display_unit_does_not_change_status() {
    let d = fed([]);
    d.set("temperature_unit", "celsius");
    d.feed(lower_cancelled());
    expect_eq(d.property("lower_oven_temperature"), "356");
}

// auto conversion reproduces both captured commands
fn test_auto_conversion() {
    let d = fed([]);
    d.set("auto_conversion", "false");
    d.set("auto_conversion", "true");
    expect_eq(hex_at(d, 1), "AA15F043210E8080800080808080808080FF80F5BB");
    expect_eq(hex_at(d, 2), "AA15F043210E8080800180808080808080FF80F4BB");
}

// temperature adjustment reproduces the captured Upper -2°F, Lower Off command (Upper +2°F,
// Lower -1°F also): here each write carries one cavity, so the captures are pinned field by field
fn test_temperature_adjustment_encoding() {
    let d = fed([]);
    d.set("upper_temperature_adjustment", "-2");
    d.set("lower_temperature_adjustment", "0");
    d.set("upper_temperature_adjustment", "2");
    d.set("lower_temperature_adjustment", "-1");
    // AA15F043210E8080808000FE0080808080FF80CBBB / AA15F043210E808080800002FF80808080FF80F4BB
    expect_eq(payload(d, 1).extract(4, 3), [0x00, 0xfe, 0x80]);
    expect_eq(payload(d, 2).extract(4, 3), [0x00, 0x80, 0x00]);
    expect_eq(payload(d, 3).extract(4, 3), [0x00, 0x02, 0x80]);
    expect_eq(payload(d, 4).extract(4, 3), [0x00, 0x80, 0xff]);
}

// the captured Celsius trim frame names °C at the temperature adjustment unit index
fn test_the_captured_celsius_trim_frame() {
    let f = hex_decode("AA15F043210E808080800100FF80808080FF80F5BB");
    expect_eq(f[6 + 4], 0x01);
    expect_eq(f[6 + 5], 0x00);
    expect_eq(f[6 + 6], 0xff);
}

// temperature adjustment writes one cavity and leaves the other unchanged
fn test_an_adjustment_writes_one_cavity() {
    let d = fed([]);
    d.set("upper_temperature_adjustment", "-2");
    d.set("lower_temperature_adjustment", "15");
    expect_eq(payload(d, 1).extract(4, 3), [0x00, 0xfe, 0x80]);
    expect_eq(payload(d, 2).extract(4, 3), [0x00, 0x80, 0x0f]);
}

// out-of-range and non-numeric temperature adjustments send nothing
fn test_bad_adjustments_send_nothing() {
    let d = fed([]);
    for v in ["-36", "36", "hot", ""] { d.set("upper_temperature_adjustment", v); }
    d.set("lower_temperature_adjustment", "");
    expect_eq(sent_count(d), 1);
}

// an unknown auto conversion / temperature unit / preheating alarm light / beeper volume payload,
// a bad clock value, and invalid timer values send nothing
fn test_unknown_payloads_send_nothing() {
    let d = fed([]);
    d.set("auto_conversion", "AUTO");
    d.set("temperature_unit", "kelvin");
    d.set("preheat_alarm_light", "MAYBE");
    d.set("beeper_volume", "Deafening");
    d.set("clock", "9:01");
    d.set("clock", "24:00");
    d.set("clock", "");
    d.set("timer", "-1");
    d.set("timer", "1.5");
    d.set("timer", "360000");
    expect_eq(sent_count(d), 1);
}

// Upper and Lower cancel send the exact captured selector commands
fn test_the_cancels() {
    let d = fed([]);
    d.set("upper_cancel", "");
    d.set("lower_cancel", "");
    expect_eq(hex_at(d, 1), "AA07F04400B0BB");
    expect_eq(hex_at(d, 2), "AA07F04401B3BB");
}

// remote start reproduces both captured start commands
fn test_the_captured_remote_starts() {
    let d = ready();
    d.set("upper_remote_temperature", "170");
    d.set("upper_remote_cook_time", "3");
    d.set("lower_remote_temperature", "350");
    d.set("lower_remote_cook_time", "0");
    d.set("lower_remote_mode", "convection_roast");
    let n = sent_count(d);
    d.set("upper_start", "");
    d.set("lower_start", "");
    expect_eq(sent_count(d), n + 2);
    expect_eq(hex_at(d, n), "AA13F043200B010000000000AA000300009CBB");
    expect_eq(hex_at(d, n + 1), "AA13F043200B1800000000015E00000000C7BB");
}

// remote start is sent without a readiness check of our own: under IL the start requires the
// cavity's remote start ready, as upstream's Start button is gated on it in Home Assistant
fn test_a_start_requires_remote_start_ready() {
    let d = fed([]);
    d.set("upper_start", "");
    expect_eq(sent_count(d), 1);
    expect(d.event("reject").contains("requires upper_oven_remote_start"), "requires unmet");
    d.feed(both_ovens_remote_start_ready());
    d.set("upper_start", "");
    expect_eq(last_hex(d), "AA13F043200B0100000000015E000A0000D0BB");
}

// remote-start inputs publish and encode temperature and cook time
fn test_remote_start_inputs() {
    let d = ready();
    let n = sent_count(d);
    d.set("upper_remote_temperature", "400");
    d.set("upper_remote_cook_time", "90");
    expect_props(d, #{ upper_remote_temperature: "400", upper_remote_cook_time: "90" });
    expect_eq(sent_count(d), n);
    d.set("upper_start", "");
    let cmd = d.sent()[n];
    let body = []; for x in cmd.extract(2, cmd.len() - 4) { body.push(x.to_int()); }
    expect_eq(body, [0xf0, 0x43, 0x20, 0x0b, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x90, 0x01, 0x1e, 0x00, 0x00]);
}

// Lower mode selection validates, publishes, and encodes every captured operation
fn test_the_lower_modes() {
    let d = fed([]);
    d.set("lower_remote_mode", "convection_roast");
    d.set("lower_remote_mode", "steam_bake");
    expect_eq(d.property("lower_remote_mode"), "convection_roast");
    expect_eq(sent_count(d), 1);
    d.set("lower_remote_temperature", "300");
    d.set("lower_remote_cook_time", "10");
    for m in [["bake", "AA13F043200B1500000000012C000A000032BB"], ["convection_bake", "AA13F043200B1700000000012C000A00003CBB"],
              ["convection_roast", "AA13F043200B1800000000012C000A00003FBB"]] {
        d.set("lower_remote_mode", m[0]);
        expect_eq(d.property("lower_remote_mode"), m[0]);
        d.feed(lower_only_remote_start_ready());
        d.set("lower_start", "");
        expect_eq(last_hex(d), m[1]);
    }
}

// real upper-oven remote start pins cavity order, temperature, cook time, and readiness
fn test_a_real_upper_remote_start() {
    let d = fed([both_ovens_remote_start_ready()]);
    expect_props(d, #{ upper_oven_remote_start: "true", lower_oven_remote_start: "true" });
    d.feed(upper_oven_170f_three_minutes());
    expect_props(d, #{ upper_oven_status: "preheating", upper_oven_mode: "bake", lower_oven_status: "idle",
        upper_oven_temperature: "", upper_oven_set_temperature: "170", upper_oven_cook_time: "180",
        lower_oven_temperature: "77", lower_oven_set_temperature: "", lower_oven_cook_time: "0",
        upper_oven_remote_start: "false", lower_oven_remote_start: "false" });
    d.feed(upper_oven_170f_two_minutes_59());
    expect_eq(d.property("upper_oven_cook_time"), "179");
    d.feed(upper_oven_finished_at_124f());
    expect_props(d, #{ upper_oven_status: "complete", upper_oven_temperature: "124", upper_oven_set_temperature: "",
        upper_oven_cook_time: "0", upper_oven_remote_start: "false" });
    let before = snapshot(d);
    d.feed(upper_oven_finished_event());
    expect_eq(snapshot(d), before);
    d.feed(upper_oven_cleared_at_149f());
    expect_props(d, #{ upper_oven_status: "idle", upper_oven_temperature: "149", upper_oven_set_temperature: "",
        upper_oven_cook_time: "0", upper_oven_remote_start: "false", lower_oven_remote_start: "false" });
}

// real 125°C Upper Bake frame confirms mode, normalized setpoint, and 01:03:00 countdown
fn test_a_real_125c_upper_bake() {
    let d = fed([upper_bake_125c_one_hour_three_minutes()]);
    expect_props(d, #{ upper_oven_status: "preheating", upper_oven_mode: "bake", upper_oven_set_temperature: "257",
        upper_oven_cook_time: "3780" });
    d.feed(upper_bake_125c_one_hour_two_minutes_59());
    expect_eq(d.property("upper_oven_cook_time"), "3779");
    let before = snapshot(d);
    d.feed(upper_bake_preheat_complete_event());
    expect_eq(snapshot(d), before);
    d.feed(upper_bake_preheat_complete());
    expect_props(d, #{ upper_oven_status: "active", upper_oven_mode: "bake", upper_oven_set_temperature: "257",
        upper_oven_cook_time: "3511" });
    d.feed(upper_bake_cancelled_at_266f());
    expect_props(d, #{ upper_oven_status: "idle", upper_oven_mode: "none", upper_oven_temperature: "266",
        upper_oven_set_temperature: "", upper_oven_cook_time: "0" });
}

// real Lower-only remote-start frame publishes only Lower as ready
fn test_lower_only_ready() {
    expect_props(fed([lower_only_remote_start_ready()]), #{ upper_oven_remote_start: "false", lower_oven_remote_start: "true" });
}

// real 285°C Lower Bake frame confirms mode, normalized setpoint, and countdown
fn test_a_real_285c_lower_bake() {
    let d = fed([lower_bake_285c_five_minutes()]);
    expect_props(d, #{ upper_oven_status: "idle", lower_oven_status: "preheating", lower_oven_mode: "bake",
        lower_oven_set_temperature: "545", lower_oven_cook_time: "300" });
    d.feed(lower_bake_285c_four_minutes_59());
    expect_eq(d.property("lower_oven_cook_time"), "299");
    d.feed(lower_bake_cancelled_at_252f());
    expect_props(d, #{ upper_oven_status: "idle", lower_oven_status: "idle", lower_oven_mode: "none",
        lower_oven_temperature: "252", lower_oven_set_temperature: "", lower_oven_cook_time: "0" });
}

// real 300°F Lower Convection Bake confirms mode, auto-converted setpoint, and countdown
fn test_a_real_lower_convection_bake() {
    let d = fed([lower_convection_bake_300f_ten_minutes()]);
    expect_props(d, #{ upper_oven_status: "idle", lower_oven_status: "preheating", lower_oven_mode: "convection_bake",
        lower_oven_set_temperature: "275", lower_oven_cook_time: "600" });
    d.feed(lower_convection_bake_300f_nine_minutes_59());
    expect_eq(d.property("lower_oven_cook_time"), "599");
    let before = snapshot(d);
    d.feed(lower_preheat_complete_event());
    expect_eq(snapshot(d), before);
    d.feed(lower_convection_bake_preheat_complete());
    expect_props(d, #{ lower_oven_status: "active", lower_oven_mode: "convection_bake", lower_oven_set_temperature: "275",
        lower_oven_cook_time: "545" });
}

// real Lower Convection Roast frame decodes 16-bit auto-converted setpoint and time off
fn test_a_real_lower_convection_roast() {
    expect_props(fed([lower_convection_roast_350f_time_off()]), #{ upper_oven_set_temperature: "", upper_oven_cook_time: "0",
        lower_oven_set_temperature: "325", lower_oven_status: "preheating", lower_oven_mode: "convection_roast",
        lower_oven_cook_time: "0", upper_oven_remote_start: "false", lower_oven_remote_start: "false" });
}

// real manual Upper Broil High frame decodes both simultaneously active cavities
fn test_a_real_upper_broil_with_lower_preheating() {
    expect_props(fed([upper_broil_high_with_lower_preheating()]), #{ upper_oven_status: "active", upper_oven_mode: "broil",
        upper_oven_set_temperature: "400", upper_oven_cook_time: "0", lower_oven_status: "preheating",
        lower_oven_mode: "convection_roast", lower_oven_set_temperature: "325", lower_oven_cook_time: "0" });
}

// real Lower preheat-complete event and transition publish Lower Active
fn test_a_real_lower_preheat_complete() {
    let d = fed([]);
    let before = snapshot(d);
    d.feed(lower_preheat_complete_event());
    expect_eq(snapshot(d), before);
    d.feed(lower_preheat_complete_with_upper_broil());
    expect_props(d, #{ upper_oven_status: "active", upper_oven_mode: "broil", upper_oven_set_temperature: "400",
        lower_oven_status: "active", lower_oven_mode: "convection_roast", lower_oven_set_temperature: "325",
        lower_oven_temperature: "" });
}

// real Upper cancel transition clears only Upper and preserves active Lower
fn test_a_real_upper_cancel() {
    expect_props(fed([upper_cancelled_with_lower_active()]), #{ upper_oven_status: "idle", upper_oven_mode: "none",
        upper_oven_set_temperature: "", upper_oven_temperature: "206", lower_oven_status: "active",
        lower_oven_mode: "convection_roast", lower_oven_set_temperature: "325", lower_oven_temperature: "" });
}

// real Lower cancel transition clears Lower and decodes 16-bit current temperatures
fn test_a_real_lower_cancel() {
    expect_props(fed([lower_cancelled()]), #{ upper_oven_status: "idle", upper_oven_temperature: "204",
        lower_oven_status: "idle", lower_oven_mode: "none", lower_oven_set_temperature: "", lower_oven_temperature: "356",
        upper_oven_remote_start: "false", lower_oven_remote_start: "false" });
}

// other oven opcodes are ignored
fn test_other_opcodes_are_ignored() {
    let d = fed([]);
    let before = snapshot(d);
    d.feed(frame([0x40, 0x31, 0x01, 0x02]));
    expect_eq(snapshot(d), before);
}

// foreign class bytes and malformed status records are ignored, not decoded as status
fn test_foreign_and_malformed_frames_are_ignored() {
    let d = fed([]);
    let before = snapshot(d);
    d.feed(frame([0x32, 0xeb, 0x01]));
    d.feed(frame([0x40, 0xeb, 0x01]));
    d.feed(frame([0x40, 0xec, 0x01]));
    d.feed(frame([0x40, 0x00, 0x45, 0x00]));
    expect_eq(snapshot(d), before);
}

// non-numeric and unknown-option payloads leave the staged value alone
fn test_bad_payloads_leave_the_staged_value() {
    let d = ready();
    d.set("upper_remote_temperature", "425");
    d.set("lower_remote_mode", "convection_bake");
    d.set("upper_remote_temperature", "");
    d.set("upper_remote_temperature", "hot");
    d.set("lower_remote_mode", "steam_bake");
    expect_props(d, #{ upper_remote_temperature: "425", lower_remote_mode: "convection_bake" });
    let n = sent_count(d);
    d.set("upper_start", "");
    d.set("lower_start", "");
    expect_eq(hex_at(d, n), "AA13F043200B010000000001A9000A000085BB");
    expect_eq(hex_at(d, n + 1), "AA13F043200B1700000000015E000A0000CEBB");
}

// reconnect resets staged remote parameters and readiness to defaults
fn test_a_restart_resets_the_staged_parameters() {
    let d = fed([]);
    d.set("upper_remote_temperature", "425");
    d.set("lower_remote_mode", "convection_bake");
    d.feed(both_ovens_remote_start_ready());
    expect_eq(d.property("upper_oven_remote_start"), "true");
    d.start();
    expect_props(d, #{ upper_remote_temperature: "350", lower_remote_mode: "bake", upper_oven_remote_start: "false",
        lower_oven_remote_start: "false" });
}

// unflagged panel-started mode codes decode via the remote-start flag mask
fn test_panel_started_modes() {
    let r = record(0, 0, 0x01);
    r[19] = 0x17;
    expect_props(fed([frame([0x40, 0xeb] + r)]), #{ upper_oven_mode: "bake", lower_oven_mode: "convection_bake" });
}
