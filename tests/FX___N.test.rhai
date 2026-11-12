import "aabb_test" as a;
import "runtime_test" as runtime;

// Tests of FX___N.rhai (LG FX25 washer). Frames and expected writes are the real captures in
// SdrgonLee/rethink (https://github.com/SdrgonLee/rethink) tests/cloud/devices/FX___N.test.ts
// at 4c074bd; upstream test names are kept in the comments. Option names are this driver's IL
// names, not the fork's Home Assistant labels.

fn off_resync() { "AAFF200A0055002228000100EB004300030300062E00000000000000000100000000002E000105000000000C0400000000200000000000380000000000000400000000000000000000000000000018000000F019BB" }
fn power_on() { "AAFF200A0098002290000100EC008600030300062E00000000000000000100000000002E000105000000000C040000000020000000000038000000000000040000000000000000000000000000001800000000030302062E00000000000000002300230000002E01000500000002000400000000200000000000380000000000000400000000000000000000000000000018000000DFE6BB" }
fn power_off() { "AAFF200A009800229D000100EC008600030302062E00000000000000002300230000002E010005000000020C040000000020000000000038000000000000040000000000000000000000000000001800000000030300062E00000000000000000100000000002E000105000000000C040000000020000000000038000000000000040000000000000000000000000000001800000028F8BB" }
fn compact_on() { "AA5020E6000001FF01020000030302062E00000000000000002300230000002E010005000000020C04000000002000000000003800000000000004000000000000000000000000000000180000006ABB" }
fn compact_off() { "AA5020E6000001FF01020000030300062E00000000000000000100000000002E000105000000000C0400000000200000000000380000000000000400000000000000000000000000000018000000A3BB" }
fn door_closed() { "AAFF200A0018002283000101030006100B0B0110029536BB" }
fn door_open() { "AAFF200A0018002285000101030006100B0B0110012A3EBB" }
fn washing() { "aaff200a0098007aba000100ec008600030202062e00000000000000002700270000002e030105000000020c04000000002000009001003c000000000000040000000000000000000000000000001800000000030202062e00000000000000005400540000002e0b0305040000020c04000000002000009001003c00000000000004000000000000000000000000000000180000003b15bb" }
fn rinsing() { "aaff200a0098007c78000100ec008600030202062e00000000000000003300540035002e0b0305040000020c04000000002000009001003c000000000000040000000000000000000000000000001800000000000002062e00000000000000003200540037002e0c0b05040000020c04000000002000009001003c00000000000004000000000000000000000000000000180000009181bb" }
fn spinning() { "aaff200a0098007e64000100ec008600000001062e0000000000000000140054006d002e0c0b05040000010c04000000002000009001003c000000000000040000000000000000000000000000001800000000000000062e0000000000000000130054006d002e0e0c05040000000c04000000002000009001003c0000000000000400000000000000000000000000000018000000761ebb" }
fn complete() { "aaff200a0098007f93000100ec008600000000062e0000000000000000010054008f002e0e0c05040000000c04000000002000009001003c000000000000040000000000000000000000000000001800000000000000002e00000000000000000100540090002e2a0e05040000000d04000000000000001001003c0000000000000400000000000000000000000000000018000000dbe6bb" }
fn laundry_care() { "aa5020e6000201ff01570000000000002e00000000000000000100540091002e2f2a05040000000d04000000000000001001003c0000000000000c00000000000000000000000000000018000000d5bb" }
fn duvet() { "AAFF200A0098009F51000100EC008600030302062E00000000000000002300230000002E010005000000020D040000000020000000000038000000000000040000000000000000000000000000001800000000030803041B00000000000000006200620000001B010009000000030D0400000000000000000000380000000000000400000000000000000000000000000018000000E431BB" }
fn rinse_one() { "AAFF200A0098009F8A000100EC008600030302062E00000000000000002300230000002E010005000000020D040000000020000000000038000000000000040000000000000000000000000000001800000000030301062E00000000000000001D001D0000002E010005000000010D0400000000200000000000380000000000000400000000000000000000000000000018000000A339BB" }
fn settings_response() { "AA5E20E6000201FF081E00200021001F0035003E1143117F1100010802012E00000000000000002600260001002E010005000000020D040000000000000000000038000000000000040000000000000000000000000000001800000075BB" }
fn prewash_response() { "AA5E20E6000201FF081E00201121111F1135113E1143117F1100060302062E00000000000000003200320000002E010005000000020D0400000000200000000000380000000000000400000000000000000000000000000018000000F5BB" }
fn reserve_3h_response() { "AA5E20E6000201FF081E11201121111F1135113E1143117F0000030302062E000000000000B4002300230000002E010005000000020D0400000000200000000080380000000000000400000000000000000000000000000018000000E6BB" }
fn reserve_4h30_response() { "AA5E20E6000201FF081E11201121111F1135113E1143117F0000030302062E0000000000010E002300230000002E010005000000020D04000000002000000000803800000000000004000000000000000000000000000000180000005BBB" }
fn reserve_off_response() { "AA5E20E6000201FF081E11201121111F1135113E1143117F0000030302062E00000000000000002300230001002E010005000000020D0400000000200000000000380000000000000400000000000000000000000000000018000000D5BB" }
fn energy_1() { "AA0B203E00250025010BBB" }
fn energy_2() { "AA0B203E0024004902D7BB" }
fn energy_3() { "AA0B203E0022005803C5BB" }

// A captured frame with byte `i` set to `v` (as the fork's tests patch their buffers).
fn patched(hex, i, v) {
    let b = hex_decode(hex);
    b[i] = v;
    hex_encode(b)
}
// The fork's remote-enabled Initial (full packet byte 119 = current block[37] | 0x10).
fn remote_initial() { let b = hex_decode(power_on()); patched(power_on(), 119, b[119] | 0x10) }
fn remote_off_complete() { let b = hex_decode(complete()); patched(complete(), 119, b[119] & 0xef) }

fn sent_hex(d, i) { hex_encode_upper(d.sent()[i]) }
// The frames the driver wrote, acks left out.
fn writes(d) {
    let out = [];
    for f in d.sent() { let b = aabb_unwrap(f); if b[1] == 0xe5 { out.push(hex_encode_upper(f)); } }
    out
}

fn test_descriptor() {
    let d = device();
    d.start();
    let desc = runtime::descriptor(d);
    expect_eq(desc.kind, "washer");
    expect_eq(desc.props.power.role, "on");
    expect_eq(desc.props.power.rw, true);
    expect_eq(desc.props.course.requires.prop, "status");
    expect_eq(desc.props.start.requires, "remote_start");
    expect_eq(desc.props.reserve_time.step, 30);
    expect_eq(d.sent().len(), 0);
}

// "real 0x55 resync decodes the powered-off state without a stale countdown"
fn test_off_resync() {
    let d = device();
    d.feed(off_resync());
    expect_props(d, #{ available: "true", power: "false", status: "off", remaining_time: "0",
                       initial_time: "0", error: "none", tub_clean_count: "12", reserve_time: "0" });
    expect(d.property("course") == (), "a powered-off block does not set the course");
    expect_eq(d.script_error(), ());
}

// "real 0x98 update reads the second block as current and decodes selected settings"
fn test_power_on_update() {
    let d = device();
    d.feed(power_on());
    expect_props(d, #{ power: "true", status: "initial", course: "normal", remaining_time: "35",
                       initial_time: "35", soil: "normal", rinse: "2", temp: "40", spin: "high",
                       turbo_wash: "true", reserve_time: "0", remote_start: "false" });
}

// "real one-setting capture proves temperature and rinse occupy distinct adjacent offsets"
fn test_rinse_one() {
    let d = device();
    d.feed(rinse_one());
    expect_props(d, #{ temp: "40", rinse: "1", spin: "high", soil: "normal" });
}

// "the post-write E6 response publishes its authoritative settings block without polling"
fn test_settings_echo() {
    let d = device();
    d.feed(settings_response());
    expect_props(d, #{ course: "normal", soil: "light", rinse: "2", spin: "delicate", temp: "cold", turbo_wash: "false" });
}

// "HA power writes reproduce both official ThinQ command frames byte-for-byte"
fn test_power_writes() {
    let d = device();
    d.start();
    d.set("power", "true");
    d.set("power", "false");
    expect_eq(writes(d), ["AA0DF0E5000201FF010201C7BB", "AA0DF0E5000201FF010200C4BB"]);
    expect_eq(d.script_error(), ());
}

// "captured pre-wash command is writable through soil and waits for the appliance response"
fn test_prewash_write() {
    let d = device();
    d.start();
    d.feed(power_on());
    d.set("soil", "pre_wash");
    expect_props(d, #{ soil: "normal" }); // nothing is published from a write
    expect_eq(writes(d), ["AA1CF0E5000201FF081E06200221061F0335013E0043007F00003FBB"]);
    d.feed(prewash_response());
    expect_props(d, #{ soil: "pre_wash" });
}

// "captured reserve commands use big-endian minutes and reported state remains authoritative"
fn test_reserve_writes() {
    let d = device();
    d.start();
    d.feed(power_on());
    d.set("reserve_time", "180");
    expect_props(d, #{ reserve_time: "0" });
    expect_eq(writes(d), ["AA1CF0E5000201FF081E03200221061F0335013E0043007F00B44EBB"]);
    d.feed(reserve_3h_response());
    expect_props(d, #{ reserve_time: "180" });
    // the live countdown does not replace the chosen time
    d.feed(patched(patched(reserve_3h_response(), 36, 0), 37, 179));
    expect_props(d, #{ reserve_time: "180" });
    d.feed(reserve_3h_response());
    d.set("reserve_time", "270");
    expect_eq(writes(d)[1], "AA1CF0E5000201FF081E03200221061F0335013E0043007F010E23BB");
    d.feed(reserve_4h30_response());
    expect_props(d, #{ reserve_time: "270" });
    d.set("reserve_time", "0");
    expect_eq(writes(d)[2], "AA1CF0E5000201FF081E03200221061F0335013E0043007F000032BB");
    d.feed(reserve_off_response());
    expect_props(d, #{ reserve_time: "0" });
}

fn test_unsettable_reserve_is_rejected() {
    let d = device();
    d.start();
    d.feed(power_on());
    d.set("reserve_time", "90");
    expect_eq(writes(d).len(), 0);
    expect(d.event("reject") != (), "a reject event is published");
}

// "laundry care sends the captured command only from Complete with remote control enabled"
fn test_laundry_care() {
    let d = device();
    d.start();
    d.set("laundry_care", "");
    d.feed(power_on());
    d.set("laundry_care", "");
    d.feed(remote_off_complete());
    d.set("laundry_care", "");
    expect_eq(writes(d).len(), 0);
    d.feed(complete());
    expect_props(d, #{ status: "end_remote_maintain_on", remote_start: "true" });
    d.set("laundry_care", "");
    expect_eq(writes(d), ["AA0DF0E5000201FF015701B2BB"]);
    d.feed(laundry_care());
    expect_props(d, #{ status: "laundry_care" });
    d.set("laundry_care", "");
    expect_eq(writes(d).len(), 1);
}

// "remote start reproduces the official command only from remote-enabled Initial"
fn test_remote_start() {
    let d = device();
    d.start();
    d.set("start", "");
    d.feed(power_on());
    d.set("start", "");
    expect_eq(writes(d).len(), 0);
    d.feed(remote_initial());
    expect_props(d, #{ status: "initial", remote_start: "true" });
    d.set("start", "");
    expect_eq(writes(d), ["AA0DF0E5000201FF010301C6BB"]);
    d.feed(washing());
    d.set("start", "");
    expect_eq(writes(d).len(), 1);
}

// "a select command sends immediately but keeps the reported value until the appliance confirms it"
fn test_rinse_write() {
    let d = device();
    d.start();
    d.feed(power_on());
    d.set("rinse", "1");
    expect_props(d, #{ rinse: "2" });
    expect_eq(hex_encode(aabb_unwrap(hex_decode(writes(d)[0]))), "f0e5000201ff081e03200121061f0335013e0043007f0000");
    d.feed(rinse_one());
    expect_props(d, #{ rinse: "1" });
}

// "course selection is immediate and all select states follow the appliance response"
fn test_course_write() {
    let d = device();
    d.start();
    d.feed(power_on());
    d.set("course", "bedding");
    expect_eq(writes(d), ["AA0DF0E5000201FF010A1BE1BB"]);
    expect_props(d, #{ course: "normal" });
    d.feed(duvet());
    expect_props(d, #{ course: "bedding", temp: "cold", spin: "medium", rinse: "3" });
    expect_eq(writes(d).len(), 1);
}

// "a rejected request reverts to the reported value and clears pending command data"
fn test_pending_cleared_by_the_next_block() {
    let d = device();
    d.start();
    d.feed(power_on());
    d.set("rinse", "1");
    d.feed(power_on());
    expect_props(d, #{ rinse: "2" });
    d.set("spin", "medium");
    expect_eq(hex_encode(aabb_unwrap(hex_decode(writes(d)[1]))), "f0e5000201ff081e03200221041f0335013e0043007f0000");
}

// Two changes before the appliance answers both reach it (the fork merges pending settings).
fn test_two_quick_changes_merge() {
    let d = device();
    d.start();
    d.feed(power_on());
    d.set("rinse", "1");
    d.set("spin", "medium");
    expect_eq(hex_encode(aabb_unwrap(hex_decode(writes(d)[1]))), "f0e5000201ff081e03200121041f0335013e0043007f0000");
}

// "reported-only options and all setting writes while powered off are rejected" and
// "all course selects ... reject writes outside Initial"
fn test_settings_need_initial_and_settable_codes() {
    let d = device();
    d.start();
    d.feed(power_on());
    for x in [["soil", "soaking"], ["rinse", "5"], ["temp", "95"], ["soil", "none"]] {
        d.set(x[0], x[1]);
    }
    d.feed(washing());
    d.set("course", "bedding");
    d.set("rinse", "1");
    d.feed(power_off());
    d.set("spin", "low");
    expect_eq(writes(d).len(), 0);
    expect(d.event("reject") != (), "a reject event is published");
    expect_eq(d.script_error(), ());
}

fn test_settings_before_any_state_are_rejected() {
    let d = device();
    d.start();
    d.set("rinse", "1");
    expect_eq(writes(d).len(), 0);
}

// "real power-off update clears the countdown and uses the current block"
fn test_power_off_update() {
    let d = device();
    d.feed(power_on());
    d.feed(power_off());
    expect_props(d, #{ power: "false", status: "off", remaining_time: "0", initial_time: "0",
                       tub_clean_count: "12", course: "normal", reserve_time: "0" });
}

// "real compact 0xE6 snapshots correct retained state on power-on and power-off"
fn test_compact_snapshots() {
    let d = device();
    d.feed(compact_on());
    expect_props(d, #{ power: "true", status: "initial", remaining_time: "35", initial_time: "35", course: "normal" });
    d.feed(compact_off());
    expect_props(d, #{ power: "false", status: "off", remaining_time: "0", initial_time: "0", tub_clean_count: "12" });
}

// "real 0x18 events decode door close and open"
fn test_door_events() {
    let d = device();
    d.feed(door_closed());
    expect_props(d, #{ door: "false" });
    d.feed(door_open());
    expect_props(d, #{ door: "true" });
}

// "real full-cycle frames follow washing through laundry care"
fn test_full_cycle() {
    let d = device();
    for x in [[washing(), "washing", "84", "12"], [rinsing(), "rinsing", "50", "12"],
              [spinning(), "spinning", "19", "12"], [complete(), "end_remote_maintain_on", "1", "13"],
              [laundry_care(), "laundry_care", "1", "13"]] {
        d.feed(x[0]);
        expect_props(d, #{ status: x[1], remaining_time: x[2], tub_clean_count: x[3] });
    }
}

// "real 0x3E reports publish 15-minute average power and authoritative cycle energy"
fn test_energy_reports() {
    let d = device();
    d.start();
    expect(d.property("energy") == (), "start publishes no default");
    d.feed(energy_1());
    expect_props(d, #{ average_power: "148", energy: "37" });
    d.feed(energy_2());
    expect_props(d, #{ average_power: "144", energy: "73" });
}

// "cycle cumulative energy recovers missed reports and resets only when a new cycle starts"
fn test_cycle_energy_resets_on_a_new_cycle() {
    let d = device();
    d.feed(energy_1());
    d.feed(energy_3());
    expect_props(d, #{ average_power: "136", energy: "88" });
    d.feed(complete());
    expect_props(d, #{ energy: "88" });
    d.feed(power_on());
    expect_props(d, #{ energy: "88" });
    d.feed(washing());
    expect_props(d, #{ average_power: "0", energy: "0" });
    d.feed(energy_1());
    expect_props(d, #{ energy: "37" });
}

// "unknown door values and malformed state frames are ignored"
fn test_malformed_frames_are_ignored() {
    let d = device();
    d.feed(door_open());
    d.feed("AAFF200A0018002285000101030006110B0B0111050D00BB");
    d.feed("AA10200A0055000000000000430000BB");
    d.feed(patched(off_resync(), 12, 0xea));
    d.feed(patched(compact_off(), 8, 0x02));
    expect_props(d, #{ door: "true" });
    expect(d.property("power") == (), "no state was decoded");
    expect_eq(d.script_error(), ());
}

fn test_unknown_codes_are_absent() {
    let d = device();
    d.feed(power_on());
    // current block starts at full-packet byte 2 + 13 + 67 = 82: course [5], state [21], error [19]
    let x = patched(patched(patched(power_on(), 87, 0x99), 103, 0x63), 101, 0x63);
    d.feed(x);
    expect_props(d, #{ course: "normal", status: "initial", error: "Unknown error (99)" });
    expect_eq(d.script_error(), ());
}

fn test_reconnect_publishes_no_default() {
    let d = device();
    d.start();
    d.feed(washing());
    d.drop_device();
    d.start();
    expect_props(d, #{ status: "washing", remaining_time: "84" });
    expect_eq(d.script_error(), ());
}
