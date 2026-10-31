import "runtime_test" as runtime;

// Tests of RV13D5JSD_D_US, ported from upstream rethink's test suite (commit 2d8eaba; unmodified
// captures from a DLEX4200B). Expected values and writes are what upstream's driver publishes and
// sends for the same input, in IL names; a value upstream leaves unknown is absent here (an empty
// retained value).

fn eb_off() { "AA2330EB001B000039003900000000000400000000A800000001000000CA000000B9BB" }
fn normal() { "AA4030EC001B010001000100000000000400000040A800000000000000CA000000001B010039003903000304000400000040AA00000000000000CA0000007FBB" }
fn small_load() { "AA4030EC001B010037003707000303000400000040A800000000000000CA000000001B01001E001E09000305000400000040A800000000000000CA00000027BB" }
fn sportswear() { "AA4030EC001B010019001910000005000400000040A800000000000000CA000000001B01001B001B0B000303000400000040A800000000000000CA0000006DBB" }
fn antibacterial() { "AA4030EC001B01001E001E09000305000400000040A800000000000000CA000000001B01010A010A08000505000400000040A800000000000000CA0000004ABB" }
fn time_dry_60() { "AA4030EC001B010028002812000003030400000040A800000000000002CA000000001B010100010012000005050400000040A800000000000000CA00000067BB" }
fn time_dry_20() { "AA4030EC001B010100010012000005050400000040A800000000000000CA000000001B010014001412000005010400000040A800000000000000CA0000005DBB" }
fn temp_ultra_low() { "AA4030EC001B010028002812000005030400000040A800000000000000CA000000001B010028002812000001030400000040A800000000000000CA0000002FBB" }
fn less_time() { "AA4030EC001B010014001412000005010400000040A800000000000000CA000000001B01000F000F120000050104FB000040A800000000000000CA0000004EBB" }
fn more_time() { "AA4030EC001B01000F000F120000050104FB000040A800000000000000CA000000001B010014001412000005010400000040A800000000000000CA0000004EBB" }
fn signal_off() { "AA4030EC001B010014001412000005010400000040A800000000000000CA000000001B010014001412000005010000000040A800000000000000CA00000073BB" }
fn signal_high() { "AA4030EC001B010014001412000005010000000040A800000000000000CA000000001B010014001412000005010400000040A800000000000000CA00000073BB" }
fn wrinkle_care_on() { "AA4030EC001B010014001412000005010400000040A800000000000000CA000000001B010014001412000005010400000050A800000000000000CA0000006FBB" }
fn wrinkle_care_off() { "AA4030EC001B010014001412000005010400000050A800000000000000CA000000001B010014001412000005010400000040A800000000000000CA0000006FBB" }
fn damp_dry_on() { "AA4030EC001B010036003601000305000400000040A800000000000000CA000000001B010036003601000305000400000048A800000000000000CA000000C9BB" }
fn damp_dry_off() { "AA4030EC001B010036003601000305000400000048A800000000000000CA000000001B010036003601000305000400000040A800000000000000CA000000C9BB" }
fn reduce_static_on() { "AA4030EC001B010036003601000305000400000040A800000000000000CA000000001B010034003401000305000400000042A800000000000005CA000000C2BB" }
fn reduce_static_off() { "AA4030EC001B010034003401000305000400000042A800000000000005CA000000001B010036003601000305000400000040A800000000000002CA000000CCBB" }
fn turbo_steam_on() { "AA4030EC001B010036003601000305000400000040A800000000000002CA000000001B010036003601000305000400000040AC00000000000000CA000000CFBB" }
fn turbo_steam_off() { "AA4030EC001B010036003601000305000400000040AC00000000000000CA000000001B010036003601000305000400000040A800000000000000CA000000CDBB" }
fn drying() { "AA4030EC001B000001000100000000000400000040A80001A738000000CA000000001B320039003903000304000400000000AB00000001000000CA000000A9BB" }
fn cooling() { "AA4030EC001B320006010303000304000400000000AB00068801000000CA000000001B330005010203000304000400000000AB0006B032000000CA00000065BB" }
fn end() { "AA4030EC001B330001010903000304000400000000AB0006D632000000CA000000001B040001010903000304000400000040AA0006D633000000CA000000BEBB" }
fn wrinkle_care_running() { "AA4030EC001B040001000A15000004000400000050A80001A733000002CA000000001B380001000115000004000400000050A90001A704000002CA0000009ABB" }
fn settles_off() { "AA4030EC001B040001010903000304000400000040AA0006D633000000CA000000001B000001000100000000000400000040A80006D604000000CA000000E1BB" }
fn identity() { "AA3730310201534141333839363434333200006322000080000000000002534141333839363433313400001FF2000080000000000081BB" }

fn fed(frames) { let d = device(); for f in frames { d.feed(f); } d }

// acks a captured identity frame under the MQTT ack command
fn test_acks_an_identity_frame() {
    let d = fed([identity()]);
    expect_eq(d.clips().map(|c| c.data), ["AA08F000310482BB"]);
    expect_eq(d.sent().len(), 0);
}

// does not ack ordinary EB and EC status frames
fn test_does_not_ack_status_frames() {
    let d = fed([eb_off(), normal()]);
    expect_eq(d.clips().len(), 0);
    expect_eq(d.sent().len(), 0);
}

// an unknown phase clears the previous status instead of reporting Running
fn test_an_unknown_phase_clears_the_status() {
    let d = fed([normal()]);
    expect_eq(d.property("status"), "initial");
    // a deliberate synthetic mutation, not an observed dryer phase
    let b = hex_decode(normal());
    let inner = b.extract(2, b.len() - 4);
    inner[33] = 0x7f;
    d.feed(hex_encode(aabb_wrap(inner)));
    expect_eq(d.property("status"), "");
}

// power-off button sends the command captured from the ThinQ app (offered while powered on, as
// upstream's button is available only then)
fn test_power_off() {
    let d = device();
    d.start();
    d.feed(normal());
    let n = d.sent().len();
    d.set("power_off", "true");
    expect_eq(d.sent().map(|s| hex_encode(s)).extract(n), ["aa09f0240101009cbb"]);
    let off = device();
    off.start();
    off.feed(eb_off());
    let n = off.sent().len();
    off.set("power_off", "true");
    expect_eq(off.sent().len(), n);
    expect(off.event("reject").contains("requires_unmet"), "requires power");
}

// 0xEB reconnect snapshot decodes as Off
fn test_eb_off() {
    expect_props(fed([eb_off()]), #{ power: "false", status: "off", course: "", dry_completed: "false" });
}

// dial course, time, dry-level and temperature fields decode from captured values
fn test_dial_fields() {
    expect_props(fed([normal()]), #{ course: "normal", remaining_time: "57", initial_time: "57", dry_level: "normal", temp: "mid_high", energy_saver: "true" });
    expect_props(fed([small_load()]), #{ course: "small_load", remaining_time: "30", temp: "high" });
    expect_props(fed([sportswear()]), #{ course: "sportswear", remaining_time: "27", temp: "medium" });
    expect_props(fed([antibacterial()]), #{ course: "antibacterial", remaining_time: "70", dry_level: "very" });
}

// Time Dry button cycles setting codes and its temperature can be changed
fn test_time_dry() {
    expect_props(fed([time_dry_60()]), #{ course: "time_dry", remaining_time: "60", time_dry_setting: "60", temp: "high" });
    expect_props(fed([time_dry_60(), time_dry_20()]), #{ remaining_time: "20", time_dry_setting: "20" });
    expect_eq(fed([temp_ultra_low()]).property("temp"), "ultra_low");
}

// More/Less Time is decoded as a signed minute adjustment
fn test_more_less_time() {
    expect_props(fed([less_time()]), #{ remaining_time: "15", more_less_time: "-5" });
    expect_props(fed([less_time(), more_time()]), #{ remaining_time: "20", more_less_time: "0" });
}

// Signal and each captured option bit toggle without colliding
fn test_signal_and_options() {
    expect_eq(fed([signal_off()]).property("signal"), "off");
    expect_eq(fed([signal_off(), signal_high()]).property("signal"), "high");
    expect_props(fed([wrinkle_care_on()]), #{ wrinkle_care: "true", damp_dry_signal: "false", reduce_static: "false" });
    expect_eq(fed([wrinkle_care_on(), wrinkle_care_off()]).property("wrinkle_care"), "false");
    expect_props(fed([damp_dry_on()]), #{ damp_dry_signal: "true", wrinkle_care: "false" });
    expect_eq(fed([damp_dry_on(), damp_dry_off()]).property("damp_dry_signal"), "false");
    expect_props(fed([reduce_static_on()]), #{ reduce_static: "true", load_item: "5" });
    expect_eq(fed([reduce_static_on(), reduce_static_off()]).property("reduce_static"), "false");
    expect_eq(fed([turbo_steam_on()]).property("turbo_steam"), "true");
    expect_eq(fed([turbo_steam_on(), turbo_steam_off()]).property("turbo_steam"), "false");
}

// full run decodes Drying, Cooling and End, then latches completion through Off
fn test_a_full_run() {
    expect_props(fed([drying()]), #{ status: "drying", dry_completed: "false" });
    expect_eq(fed([drying(), cooling()]).property("status"), "cooling");
    expect_props(fed([drying(), cooling(), end()]), #{ status: "end", dry_completed: "true", remaining_time: "0" });
    expect_props(fed([drying(), cooling(), end(), settles_off()]), #{ status: "off", power: "false", dry_completed: "true" });
    expect_eq(fed([drying(), cooling(), end(), settles_off(), normal()]).property("dry_completed"), "false");
}

// post-completion Wrinkle Care is a state and keeps completion latched
fn test_wrinkle_care_after_completion() {
    expect_props(fed([end(), wrinkle_care_running()]), #{ status: "wrinkle_care", power: "true", remaining_time: "0", dry_completed: "true" });
}

// start requests a status snapshot
fn test_start_asks_for_the_status() {
    let d = device();
    d.start();
    expect_eq(d.sent().map(|s| hex_encode(s)), ["aa0ef0ed1121010000001800b5bb"]);
}

// unrelated and truncated frames are ignored
fn test_other_frames_are_ignored() {
    for junk in ["AA09307200C80048BB", "AA0A30EC001B010029BB", "001122"] {
        expect_eq(fed([junk]).property("power"), ());
    }
}
