import "runtime_test" as runtime;

// Tests of T1789EFH_F, ported from upstream rethink's test suite (commit 2d8eaba; real captures from
// a WT7300CW, the start and pause commands as the LG cloud sent them). Expected values are what
// upstream's driver publishes and sends for the same input, in IL names; door_lock is true while
// locked (upstream publishes it inverted, for Home Assistant's lock class), and a state upstream
// cannot name stays unpublished.

fn ec_idle() { "AA3C20EC0019000000011A00000000000000000000100000040800000064000019000000011A000000000000000000001000000408000000640037BB" }
fn ec_heavy_duty() { "AA3C20EC0019050018011A0200050304000000000410000000050000006400001906001D011E0200000304000000000410000000050000006400FABB" }
fn ec_running() { "AA3C20EC001905002B00340800030104000000000410000000030000006400001902002B0034080003010400000000041000000005000000640054BB" }
fn ec_paused() { "AA3C20EC001902002B00340800030104000000000410000000050000006400001902002B00340800030104000000000010000000050000006400A9BB" }
fn ec_resumed() { "AA3C20EC001902002B00340800030104000000000010000000050000006400001905002B00340800030104000000000010000000020000006400ADBB" }
fn ec_spin_to_complete() { "AA3C20EC00190700010019010000030000000000440000000006000000640000190800000019010000030000000000440000000107000000640099BB" }
fn eb_idle() { "AA2120EB00190000010023000000000000000000400000000208000000670091BB" }
fn e2_settings() { "AA2120E20319030102003A010003030100000000400000000101000000640082BB" }
fn e2_stale_washing() { "AA2120E2031905012A012A0800030104040000000415010002020000007800BBBB" }
fn identity() { "AA372031020153414133393935353130330000D05F0000800000000000025341413339393534393033000044FC000040000000000008BB" }
fn short_ack() { "AA0720D80EE2BB" }
fn ec_remaining_over_an_hour() { "AA3C20EC0019050018011A02000503040000000004100000000500000064000019060105011E0200000304000000000410000000050000006400FABB" }
fn normal_turbo_on() { "AA3C20EC001901000100000000000000000000000080000000000000006700001901003B003A010003030400000000400000000000000000670060BB" }
fn deep_wash_dialled() { "AA3C20EC001901012801270200050304000000000010000000000000006700001901003A003919000302040000000000100000000000000067005DBB" }
fn water_plus() { "AA3C20EC001901003B003A0100030304000000004000000000000000008300001901003A00391900030204000000000012000000000000008300C6BB" }
fn whites_extra_rinse() { "AA3C20EC0019010100003B0800010204000000000000000000006B00006B00001901020602050100050205020000004001000000008300008300F9BB" }
fn soak() { "AA3C20EC001901003B003A0100030304000000004000000000000000008300001901011D003A0100030304000000004020000000000000008301E5BB" }
fn stain_care() { "AA3C20EC001901011D003A01000303040000000040200000000000000083010019010120003A01000303030200000000080000000000000083000ABB" }
fn control_lock() { "AA3C20EC00190100390038040001010100000000001000000000000000830000190100390038040001010100000000011000000000000000830068BB" }
fn delay_16h() { "AA3C20EC00190100390038040001010100000F0000100000000000000083000019010039003804000101010000100000100000000000000083000EBB" }
fn delay_19h() { "AA3C20EC00190100390038040001010100001200001000000000000000830000190100390038040001010100001300001000000000000000830034BB" }
fn remote_start() { "AA3C20EC00190100390038040001010100000000001001000000000000830000190100390038040001010100000000041001000000000000830017BB" }
fn spin_only() { "AA3C20EC0019010021002011000003010000000000100000000000000083000019010010000F120000030000000000000000000000000000830093BB" }
fn prewash_normal() { "AA3C20EC0019010039003804000101010000000000100000000000000083000019010119011829000303040000000040000000000000000083000FBB" }
fn tub_clean() { "AA3C20EC001901011901182900030304000000004000000000000000008300001901010801080C00010305000000000000000000000000008300ACBB" }
fn live_complete() { "AA3C20EC00190700010129080000010004000000041101000006000000780000190800010129080000010004000000041100000207000000780098BB" }
fn live_complete_unlocked() { "AA3C20EC00190800010129080000010004000000041100000207000000780000190800010129080000010004000000001100000207000000780099BB" }
fn normal_armed() { "AA3C20EC001901003B003A0100030304000000004000010000000000006400001901003B003A010003030400000000440001000000000000640021BB" }
fn deepwash_armed() { "AA3C20EC001901011200391900030204020000000011000000000000006400001901011200391900030204020000000011010000000000006400A4BB" }
fn dl_curtains() { "AA3C20EC0019010132013102000502050000000040200000000078000078010019010100003B0800010204000000000000000000006B00006B005EBB" }
fn dl_small_load() { "AA3C20EC001901001D001D0700010302000000004000000000006500006500001901003B003A0100010204000000004000000000006400006400A9BB" }
fn dl_sweat_stains() { "AA3C20EC001901003B003A01000102040000000040000000000064000064000019010130012F02000303040000000040200000000069000069011EBB" }
fn dl_swimwear() { "AA3C20EC0019010130012F0200030304000000004020000000006900006901001901010F010E0400010102020000000001000000006A00006A0091BB" }

fn fed(frames) { let d = device(); for f in frames { d.feed(f); } d }
fn prop(f, p) { fed([f]).property(p) }
fn sent_after(f, p) { let d = fed([f]); d.set(p, "true"); d.sent().map(|s| hex_encode(s)) }

// start() requests a status snapshot, so a reconnect does not leave HA blank
fn test_start_asks_for_the_status() {
    let d = device();
    d.start();
    expect_eq(d.sent().map(|s| hex_encode(s)), ["aa0ef0ed1121010000001800b5bb"]);
}

// the washer gets the cloud's acks, but not for its status frames
fn test_acks_other_frames_but_not_status() {
    let d = fed([short_ack(), ec_idle()]);
    expect_eq(d.clips().map(|c| c.data), [hex_encode_upper(aabb_wrap([0xf0, 0x00, 0xd8, 0x04]))]);
}

// end-of-cycle frame reports Complete, not the spin it just left
fn test_end_of_cycle() {
    expect_props(fed([ec_spin_to_complete()]), #{ status: "end", remaining_time: "0", power: "true" });
}

// pause and resume follow the current record
fn test_pause_and_resume() {
    expect_eq(prop(ec_running(), "status"), "paused");
    expect_eq(prop(ec_paused(), "status"), "paused");
    expect_eq(prop(ec_resumed(), "status"), "washing");
}

// mid-cycle Heavy Duty frame reports the phase the machine is in now
fn test_heavy_duty_phase() {
    expect_props(fed([ec_heavy_duty()]), #{ status: "rinsing", remaining_time: "29" });
}

// remaining time reads the hour byte
fn test_remaining_time_reads_the_hour_byte() {
    expect_eq(prop(ec_remaining_over_an_hour(), "remaining_time"), "65");
}

// initial time estimate reads the hour byte and outlives the countdown
fn test_initial_time() {
    expect_props(fed([ec_heavy_duty()]), #{ initial_time: "90", remaining_time: "29" });
}

// powered off, both times report 0 rather than the last cycle leftovers
fn test_off_times() {
    expect_props(fed([eb_idle()]), #{ power: "false", status: "off", remaining_time: "0", initial_time: "0" });
}

// Heavy Duty capture decodes its own declared defaults
fn test_heavy_duty_settings() {
    expect_props(fed([ec_heavy_duty()]), #{ spin: "high", temp: "warm", soil: "none" });
}

// Bedding capture decodes a different triple
fn test_bedding_settings() {
    expect_props(fed([ec_running()]), #{ soil: "normal", spin: "low", temp: "warm" });
}

// idle frame decodes settings as unset rather than unknown
fn test_idle_settings() {
    expect_props(fed([ec_idle()]), #{ course: "none", soil: "none", spin: "none", temp: "none" });
}

// a cycle reaching Complete disarms remote start and unlocks the lid
fn test_complete_disarms_and_unlocks() {
    expect_props(fed([live_complete()]), #{ status: "end", remote_start: "false", door_lock: "true" });
    expect_eq(prop(live_complete_unlocked(), "door_lock"), "false");
}

// non-status frames are ignored even when they contain a valid record
fn test_other_frames_are_ignored() {
    for f in [e2_settings(), e2_stale_washing(), identity(), short_ack()] {
        expect_eq(prop(f, "power"), ());
    }
}

// unknown phase code publishes the unknown fallback (left unpublished here)
fn test_an_unknown_state() {
    let d = fed(["AA2120EB0019FF00010023000000000000000000400000000208000000670091BB"]);
    expect_eq(d.property("power"), "true");
    expect_eq(d.property("status"), ());
}

// course codes decode to the panel names
fn test_courses() {
    expect_eq(prop(normal_turbo_on(), "course"), "normal");
    expect_eq(prop(ec_heavy_duty(), "course"), "heavy_duty");
    expect_eq(prop(deep_wash_dialled(), "course"), "deep_wash");
    expect_eq(prop(spin_only(), "course"), "spin_only");
    expect_eq(prop(prewash_normal(), "course"), "pre_wash_normal");
    expect_eq(prop(tub_clean(), "course"), "tub_clean");
}

// the Downloaded position reports the smart course base cycle, not a code of its own
fn test_downloaded_position() {
    expect_props(fed([whites_extra_rinse()]), #{ course: "normal", temp: "hot", soil: "heavy" });
}

// a powered-off washer reports no cycle options, even ones the machine still holds
fn test_off_options() {
    expect_props(fed([eb_idle()]), #{ status: "off", turbo_wash: "false", course: "none" });
}

// turbo wash
fn test_turbo_wash() {
    expect_eq(prop(normal_turbo_on(), "turbo_wash"), "true");
    expect_eq(prop(deep_wash_dialled(), "turbo_wash"), "false");
}

// water plus is distinguishable from simply selecting Deep Wash
fn test_water_plus() {
    expect_props(fed([deep_wash_dialled()]), #{ course: "deep_wash", water_plus: "false" });
    expect_props(fed([water_plus()]), #{ course: "deep_wash", water_plus: "true" });
}

// extra rinse, stain care and soak
fn test_extra_rinse_stain_care_and_soak() {
    expect_eq(prop(whites_extra_rinse(), "extra_rinse"), "true");
    expect_eq(prop(normal_turbo_on(), "extra_rinse"), "false");
    expect_props(fed([stain_care()]), #{ stain_care: "true", soak: "false" });
    expect_props(fed([soak()]), #{ soak: "true", stain_care: "false" });
}

// control lock
fn test_control_lock() {
    expect_eq(prop(control_lock(), "child_lock"), "true");
    expect_eq(prop(normal_turbo_on(), "child_lock"), "false");
}

// the door locks during ordinary cycles, with remote start off
fn test_door_lock_without_remote_start() {
    for f in [ec_heavy_duty(), ec_spin_to_complete()] {
        expect_props(fed([f]), #{ door_lock: "true", remote_start: "false" });
    }
}

// remote start and door lock are separate bits
fn test_remote_start_and_door_lock() {
    expect_props(fed([remote_start()]), #{ remote_start: "true", door_lock: "true" });
    expect_props(fed([normal_turbo_on()]), #{ remote_start: "false", door_lock: "false" });
}

// delay wash decodes 16 h as 16, not the 10 a BCD reading would give; reaches 19 h; none is 0
fn test_delay_wash() {
    expect_eq(prop(delay_16h(), "reserve_time"), "960");
    expect_eq(prop(delay_19h(), "reserve_time"), "1140");
    expect_eq(prop(normal_turbo_on(), "reserve_time"), "0");
}

// a two-hour remaining estimate reads the hour byte
fn test_two_hours_remaining() {
    expect_eq(prop(whites_extra_rinse(), "remaining_time"), "126");
}

// start button reproduces the command the LG app sent, byte for byte
fn test_start() {
    expect_eq(sent_after(normal_armed(), "start"), ["aa15f02601030304000000000000000040000376bb"]);
}

// start command carries the rinse setting and the opt2 byte verbatim
fn test_start_carries_rinse_and_opt2() {
    expect_eq(sent_after(deepwash_armed(), "start"), ["aa15f02619030204020000000000000000110358bb"]);
}

// the door-lock bit is never echoed back into the command
fn test_start_clears_the_door_lock_bit() {
    let s = fed([normal_armed()]);
    s.set("start", "true");
    expect_eq(s.sent()[0][16], 0x40);
}

// start is not gated in software — the appliance enforces its own arming
fn test_start_is_not_gated() {
    expect_eq(sent_after(eb_idle(), "start").len(), 1);
}

// start refuses before any status frame has been seen
fn test_start_before_any_status() {
    let d = device();
    d.set("start", "true");
    expect_eq(d.sent().len(), 0);
    expect(d.event("reject") != (), "reject");
}

// pause sends the command the LG app sent to pause
fn test_pause() {
    expect_eq(sent_after(normal_armed(), "pause"), ["aa09f02404010099bb"]);
}

// pressing start while Paused resumes with verb 0x01, not a fresh start
fn test_resume_while_paused() {
    let s = sent_after(ec_paused(), "start");
    expect_eq(s.len(), 1);
    let b = hex_decode(s[0]);
    expect_eq([b[2], b[3], b[18]], [0xf0, 0x26, 0x01]);
}

// an unknown property sends nothing
fn test_an_unknown_property() {
    let d = fed([normal_armed()]);
    d.set("nonsense", "true");
    expect_eq(d.sent().len(), 0);
    expect(d.event("reject") != (), "reject");
}

// smart course codes decode to the names the LG app showed
fn test_smart_courses() {
    expect_eq(prop(dl_curtains(), "smart_course"), "curtains");
    expect_eq(prop(dl_small_load(), "smart_course"), "small_load");
    expect_eq(prop(dl_sweat_stains(), "smart_course"), "sweat_stains");
    expect_eq(prop(dl_swimwear(), "smart_course"), "swimwear");
}

// each smart course reports its declared base cycle in the course byte
fn test_smart_course_base_cycles() {
    expect_eq(prop(dl_curtains(), "course"), "bedding");
    expect_eq(prop(dl_small_load(), "course"), "normal");
    expect_eq(prop(dl_sweat_stains(), "course"), "heavy_duty");
    expect_eq(prop(dl_swimwear(), "course"), "delicates");
}

// the downloaded slot is reported separately from the active smart course
fn test_downloaded_course() {
    expect_eq(prop(dl_swimwear(), "downloaded_course"), "swimwear");
}

// no smart course engaged reports Not selected, not unknown
fn test_no_smart_course() {
    expect_eq(prop(ec_heavy_duty(), "smart_course"), "none");
}

// a smart course is distinguishable from its base cycle
fn test_smart_course_versus_base_cycle() {
    expect_eq(prop(whites_extra_rinse(), "course"), prop(normal_turbo_on(), "course"));
    expect(prop(whites_extra_rinse(), "smart_course") != prop(normal_turbo_on(), "smart_course"), "smart course");
}

// power off sends the command the LG app sent
fn test_power_off() {
    expect_eq(sent_after(normal_armed(), "power_off"), ["aa09f0240101009cbb"]);
}

// power off is not gated on remote start being armed
fn test_power_off_is_not_gated() {
    expect_eq(sent_after(eb_idle(), "power_off").len(), 1);
}

// No Spin is reported only as a real selection, not as the powered-off value
fn test_no_spin() {
    expect_eq(prop(eb_idle(), "spin"), "none");
    expect_eq(prop(spin_only(), "spin"), "high");
}

// power is not declared as a running sensor
fn test_power_is_not_a_running_sensor() {
    let d = device();
    d.start();
    let props = runtime::descriptor(d).props;
    expect(!props.power.contains("class"), "no class");
    for p in ["start", "pause", "power_off", "course", "smart_course", "downloaded_course", "soil", "spin",
              "temp", "reserve_time", "door_lock", "child_lock", "remote_start", "turbo_wash", "extra_rinse",
              "water_plus", "stain_care", "soak", "initial_time"] {
        expect(props.contains(p), p);
    }
}
