import "runtime_test" as runtime;

// Tests of WTL_FXU_BDV_NA_01, ported from upstream rethink's test suite (commit 0e57069; real
// captures from a WashTower, and synthetic resync frames upstream builds the same way). Expected
// values are what upstream's driver publishes, in IL names: its washer/x and dryer/x are washer_x
// and dryer_x, LG's identifiers are lowercased, and "N/A" is not_applicable. The buzzers, the
// display theme and remote maintain apply only while their unit is powered, so those writes
// follow a state with it on.

fn status_washer_running() { "aad0360a00d0008542000100ec00be013200030e0e0e1600000000000000002d002d00000016010000070000020f0202022d2d00000000000c380000000000070401002a000000000000000000003c00000001000200000200000000201800810700000000070000000000000000013200030e0e0e1600000000000000002d002d000000160b0100070000020f0202022d2d00000010000c380000000000070401002a000000000000000000003c0000000100020000020000000020180081070000000007000000000000000023a9bb" }
fn state_resync() { "aa71360a00710085f3000100eb005f013200030e0e0e1600000000000000002a002d000200160b2600070000020f0202022d2d00000010010c380000000000060401002a000000000000000000000000000001000200000000000000000000810700000000060000000000000000d05dbb" }
fn washer_door_open() { "aa42360a0042007d83000201030007100c010b1000330105002557544c5f4658555f4244565f4e415f30310000000102d71c0b8b010700000000000000000018babb" }
fn washer_door_close() { "aa42360a0042007d84000201030007100c010b1001330105002557544c5f4658555f4244565f4e415f30310000000102d51c0b8b0107000000000000000000c4cebb" }
fn dryer_door_open() { "aa4e360a004e007d850002010300130a0a01040a000021ff000000000000000105340105002557544c5f4658555f4244565f4e415f30310000000102d81c0b8b0107000000000000000000b590bb" }
fn dryer_door_close() { "aa4e360a004e007d860002010300130a0a01040a00002200000000000000000005340105002557544c5f4658555f4244565f4e415f30310000000102d71c0b8b0107000000000000000000b490bb" }
fn send_washer_power_on() { "AA0DF0E50002013301020193BB" }
fn send_washer_power_off() { "AA0DF0E50002013301020090BB" }
fn send_dryer_power_on() { "AA0DF0E50002013401020192BB" }
fn send_dryer_power_off() { "AA0DF0E50002013401020093BB" }
fn send_init_lcd_default() { "AA0DF0E50002013301510041BB" }
fn send_init_lcd_spring2() { "AA0DF0E5000201330151054CBB" }
fn send_washer_buzzer_off() { "AA0DF0E50002013301130083BB" }
fn send_washer_buzzer_low() { "AA0DF0E50002013301130182BB" }
fn send_washer_buzzer_vhigh() { "AA0DF0E5000201330113048FBB" }
fn send_dryer_buzzer_off() { "AA0DF0E50002013401130082BB" }
fn send_dryer_buzzer_low() { "AA0DF0E5000201340113018DBB" }
fn send_dryer_buzzer_vhigh() { "AA0DF0E5000201340113048EBB" }
fn send_start() { "AA0EF0ED1121010000001800B5BB" }
fn send_washer_remote_maintain_on() { "AA0AF0241001013358BB" }
fn send_washer_remote_maintain_off() { "AA0AF0241001003359BB" }
fn send_dryer_remote_maintain_on() { "AA0AF024100101345BBB" }
fn send_dryer_remote_maintain_off() { "AA0AF0241001003458BB" }

fn fed(frames) { let d = device(); for f in frames { d.feed(f); } d }

// A 0x71 resync of one block with some bytes set: 13 header bytes, the 95-byte block, one more.
fn resync(overrides) {
    let inner = blob(109, 0);
    inner[3] = 0x71;
    for o in overrides { inner[13 + o[0]] = o[1]; }
    aabb_wrap(inner)
}

// A device whose units are both powered, for the writes that need them.
fn powered() {
    let d = device();
    d.start();
    d.feed(resync([[23, 0x01], [66, 0x01]]));
    d
}

fn last_hex(d) { hex_encode_upper(d.sent()[d.sent().len() - 1]) }

// config exposes expected HA components
fn test_the_descriptor() {
    let d = device();
    d.start();
    let props = runtime::descriptor(d).props;
    for p in ["washer_state", "washer_power", "washer_door", "washer_course", "washer_temp", "washer_spin",
              "washer_remaining_time", "washer_remote_maintain", "dryer_state", "dryer_power", "dryer_door",
              "dryer_course", "dryer_remote_maintain", "init_lcd"] { expect(props.contains(p), p); }
    expect_eq(props.init_lcd.type, "select");
    expect(props.init_lcd.options.contains("default") && props.init_lcd.options.contains("christmas"), "themes");
}

// 0xd0 status packet decodes washer state
fn test_status_decodes_the_washer() {
    expect_props(fed([status_washer_running()]), #{ washer_power: "true", washer_state: "running",
        washer_course: "delicates", washer_temp: "not_applicable", washer_remaining_time: "45",
        washer_initial_time: "45", init_lcd: "summer_2" });
}

// 0xd0 status packet decodes dryer state (dryer off in this capture)
fn test_status_decodes_the_dryer() {
    expect_props(fed([status_washer_running()]), #{ dryer_power: "false", dryer_state: "poweroff", dryer_remaining_time: "60" });
}

// 0x42 washer door open publishes washer/door=OPEN
fn test_the_washer_door_opens() { expect_eq(fed([washer_door_open()]).property("washer_door"), "true"); }

// 0x42 washer door close publishes washer/door=CLOSE
fn test_the_washer_door_closes() { expect_eq(fed([washer_door_close()]).property("washer_door"), "false"); }

// 0x4e dryer door open publishes dryer/door=OPEN
fn test_the_dryer_door_opens() { expect_eq(fed([dryer_door_open()]).property("dryer_door"), "true"); }

// 0x4e dryer door close publishes dryer/door=CLOSE
fn test_the_dryer_door_closes() { expect_eq(fed([dryer_door_close()]).property("dryer_door"), "false"); }

// wrong-length 0xd0 packet is ignored
fn test_a_short_status_is_ignored() { expect_eq(fed(["aaff360a00d000854200010090bb"]).property("available"), ()); }

// setProperty washer/power ON sends correct packet
fn test_washer_power_on() { let d = device(); d.start(); d.set("washer_power", "true"); expect_eq(last_hex(d), send_washer_power_on()); }

// setProperty washer/power OFF sends correct packet
fn test_washer_power_off() { let d = device(); d.start(); d.set("washer_power", "false"); expect_eq(last_hex(d), send_washer_power_off()); }

// setProperty dryer/power ON sends correct packet
fn test_dryer_power_on() { let d = device(); d.start(); d.set("dryer_power", "true"); expect_eq(last_hex(d), send_dryer_power_on()); }

// setProperty dryer/power OFF sends correct packet
fn test_dryer_power_off() { let d = device(); d.start(); d.set("dryer_power", "false"); expect_eq(last_hex(d), send_dryer_power_off()); }

// setProperty shared/init_lcd sends correct packet with theme index
fn test_the_display_theme() {
    let d = powered();
    d.set("init_lcd", "default"); expect_eq(last_hex(d), send_init_lcd_default());
    d.set("init_lcd", "spring_2"); expect_eq(last_hex(d), send_init_lcd_spring2());
}

// setProperty shared/init_lcd with unknown theme sends nothing
fn test_an_unknown_theme_sends_nothing() {
    let d = powered();
    let n = d.sent().len();
    d.set("init_lcd", "not_a_theme");
    expect_eq(d.sent().len(), n);
}

// start() sends get-full-state packet; the doors stay absent (upstream assumes them shut)
fn test_start_asks_for_the_state() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 1);
    expect_eq(last_hex(d), send_start());
    expect_eq(d.property("washer_door"), ());
    expect_eq(d.property("dryer_door"), ());
}

// 0x71 state resync decodes washer state
fn test_a_resync_decodes_the_washer() {
    expect_props(fed([state_resync()]), #{ washer_power: "true", washer_state: "running", washer_remaining_time: "42",
        washer_initial_time: "45", washer_buzzer: "medium", washer_remote_start: "true", washer_door_lock: "true",
        washer_add_garment: "false", washer_child_lock: "false", init_lcd: "summer_1" });
}

// 0x71 state resync decodes dryer state
fn test_a_resync_decodes_the_dryer() {
    expect_props(fed([state_resync()]), #{ dryer_power: "false", dryer_state: "poweroff", dryer_remaining_time: "0",
        dryer_buzzer: "off", dryer_duct_clogging: "none", dryer_remote_start: "false", dryer_child_lock: "false" });
}

// wrong-length 0x71 packet is ignored
fn test_a_short_resync_is_ignored() { expect_eq(fed(["aa0e360a00710000000000008abb"]).property("available"), ()); }

// 0x71 washer bitmask sensors decode correctly
fn test_the_washer_bits() {
    expect_props(fed([resync([[39, 0xa0], [40, 0x01]])]), #{ washer_add_garment: "true", washer_child_lock: "true",
        washer_remote_start: "false" });
}

// 0x71 dryer bitmask sensors decode correctly
fn test_the_dryer_bits() {
    expect_props(fed([resync([[79, 0x50], [75, 0x01]])]), #{ dryer_remote_start: "true", dryer_child_lock: "true",
        dryer_duct_clogging: "level_1" });
}

// setProperty washer/buzzer sends correct packet
fn test_the_washer_buzzer() {
    let d = powered();
    d.set("washer_buzzer", "off"); expect_eq(last_hex(d), send_washer_buzzer_off());
    d.set("washer_buzzer", "low"); expect_eq(last_hex(d), send_washer_buzzer_low());
    d.set("washer_buzzer", "very_high"); expect_eq(last_hex(d), send_washer_buzzer_vhigh());
}

// setProperty washer/buzzer with unknown value sends nothing
fn test_an_unknown_washer_buzzer_sends_nothing() {
    let d = powered();
    let n = d.sent().len();
    d.set("washer_buzzer", "deafening");
    expect_eq(d.sent().len(), n);
}

// setProperty dryer/buzzer sends correct packet
fn test_the_dryer_buzzer() {
    let d = powered();
    d.set("dryer_buzzer", "off"); expect_eq(last_hex(d), send_dryer_buzzer_off());
    d.set("dryer_buzzer", "low"); expect_eq(last_hex(d), send_dryer_buzzer_low());
    d.set("dryer_buzzer", "very_high"); expect_eq(last_hex(d), send_dryer_buzzer_vhigh());
}

// setProperty dryer/buzzer with unknown value sends nothing
fn test_an_unknown_dryer_buzzer_sends_nothing() {
    let d = powered();
    let n = d.sent().len();
    d.set("dryer_buzzer", "veyr_very_loud");
    expect_eq(d.sent().len(), n);
}

// 0x71 washer remote_maintain decodes from block[42] bit2
fn test_the_washer_remote_maintain_bit() {
    expect_eq(fed([resync([[42, 0x04]])]).property("washer_remote_maintain"), "true");
    expect_eq(fed([resync([[42, 0x00]])]).property("washer_remote_maintain"), "false");
}

// 0x71 dryer remote_maintain decodes from block[80] bit1
fn test_the_dryer_remote_maintain_bit() {
    expect_eq(fed([resync([[80, 0x02]])]).property("dryer_remote_maintain"), "true");
    expect_eq(fed([resync([[80, 0x00]])]).property("dryer_remote_maintain"), "false");
}

// setProperty washer/remote_maintain sends correct packet
fn test_the_washer_remote_maintain_write() {
    let d = powered();
    d.set("washer_remote_maintain", "true"); expect_eq(last_hex(d), send_washer_remote_maintain_on());
    d.set("washer_remote_maintain", "false"); expect_eq(last_hex(d), send_washer_remote_maintain_off());
}

// setProperty dryer/remote_maintain sends correct packet
fn test_the_dryer_remote_maintain_write() {
    let d = powered();
    d.set("dryer_remote_maintain", "true"); expect_eq(last_hex(d), send_dryer_remote_maintain_on());
    d.set("dryer_remote_maintain", "false"); expect_eq(last_hex(d), send_dryer_remote_maintain_off());
}

// (IL) the settings that need their unit powered are refused while it is off
fn test_unit_settings_are_refused_while_off() {
    let d = device();
    d.start();
    d.feed(status_washer_running()); // the dryer is off here
    let n = d.sent().len();
    d.set("dryer_buzzer", "low");
    d.set("dryer_remote_maintain", "true");
    expect_eq(d.sent().len(), n);
    d.set("washer_buzzer", "low"); // the washer is on
    expect_eq(d.sent().len(), n + 1);
}
