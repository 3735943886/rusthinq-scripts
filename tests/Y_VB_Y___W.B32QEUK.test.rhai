import "runtime_test" as runtime;

// Tests of Y_VB_Y___W.B32QEUK (washer_y8_common), ported from upstream rethink's test suite
// (commit 0e57069; captures from an F14R76BSTA, except sample_cotton_dosed, which upstream
// built from a Y_V8_Y record for a simulated washer). Expected values and writes are what
// upstream's driver publishes and sends for the same input, in IL names; door_lock and
// child_lock are true while locked (upstream publishes them inverted, for Home Assistant's lock
// class).

fn sample_initial() { "AAFF200A006000F52C000100EC004E00000100000000000000000000000000000000000000001F006400000000000002022A1E00800100000100000000000000000000000000000000000000001F006400000000000002022A1E0000010EE4BB" }
fn sample_power_off() { "AAFF200A006000F531000100EC004E00000100000000000000000000000000000000000000001F006400000000000002022A1E00000100000000000000000000000000000000000000000001001F006400000000000002022A1E000001605CBB" }
fn sample_measuring() { "AAFF200A00600008B5000100EC004E000001000000000000000000000000000000000000000020006400000000012402022A1E004001000004010C010C1200030106010000000042000001010020006400000200000000002A1E0000019DB0BB" }
fn sample_running_door_locked() { "AAFF200A006000F98F000100EC004E0000060219021B0400030A0401000000004220000104001F006400000200000103012A1E0040010000060219021B0400030A0401000000004220000104001F006400000200000103012A1E00000164AFBB" }
fn sample_rinsing() { "AAFF200A00600002DA000100EC004E0000070022021B0400030A0001000000004200000106001F00640000020000B903012A1E0000010000070022021B0400030A0001000000004200000106001F00640000020000BA03012A1E000001CE60BB" }
fn sample_spinning() { "AAFF200A006000CC44000100EC004E000007001D021B0400030A0001000000004200000106001100640000020000C102002A1E004001000008001C021B0400000A0000000000004200000107001100640000020000C202002A1E000001DC6CBB" }
fn sample_single_block_washing() { "AAFF200A003900C2A6000100EB00270000060216021B0400030A04010000000042200001040011006400000200000602002A1E00400189A4BB" }
fn sample_unknown_message_type() { "AAFF200A003900CE8600010AE20027000004032603260400030A04010000000002200001010011006400000200011602002A1E000001DBABBB" }
fn sample_downloaded_duvet_selected() { "AAFF200A006000E811000100EC004E000001010C010C1200030106010000000000000003000005003A00000200000000002A1E000001000001011C011C0500030201010000000000000001003A05003A00000300000002022A1E000001990CBB" }
fn sample_ezdispense_42_30() { "AAFF200A0060000400000100EC004E000001000000000000000000000000000000000000000005003400000000000002022A1E004001000001000000000000000000000000000000000000000005003400000000000002022A1E00800151ADBB" }
fn sample_ezdispense_43_30() { "AAFF200A0060000440000100EC004E000001000000000000000000000000000000000000000005003400000000000002022A1E000001000001000000000000000000000000000000000000000005003400000000000002022B1E0000016E6BBB" }
fn sample_ezdispense_43_31() { "AAFF200A006000045A000100EC004E000001000000000000000000000000000000000000000005003400000000000002022B1E000001000001000000000000000000000000000000000000000005003400000000000002022B1F000001FDA5BB" }
fn sample_drawer_opening() { "AAFF200A0060004CD1000100EC004E000001000000000000000000000000000000000000000005003400000000000002022A1E000001000001000000000000000000000000000000000000000005003400000000000002022A1E0004014A1DBB" }
fn sample_drawer_open_pulse_on() { "AAFF200A0060004CD4000100EC004E000001000000000000000000000000000000000000000005003400000000000002022A1E000401000001000000000000000000000000000000000000000005003400000000000002022A1E004401BD20BB" }
fn sample_drawer_open_pulse_off() { "AAFF200A0060004CFF000100EC004E000001000000000000000000000000000000000000000005003400000000000002022A1E004401000001000000000000000000000000000000000000000005003400000000000002022A1E00040183E8BB" }
fn sample_drawer_closed() { "AAFF200A0060004D02000100EC004E000001000000000000000000000000000000000000000005003400000000000002022A1E000401000001000000000000000000000000000000000000000005003400000000000002022A1E000001C8B2BB" }
fn sample_cotton_dosed() { "AAFF200A0039040081000100EB0027000001032603260100000000000000000002000003000011007100000000000003010000000000557ABB" }

fn last(d) { let s = d.sent(); hex_encode_upper(s[s.len() - 1]) }

fn dispenser_clean() { "AAFF200A0039040081000100EB0027000001032603263700000000000000000002000003000011007100000000000003010000000000CFA1BB" }
fn dispense_type_2() { "AAFF200A0039040081000100EB00270000010326032601000000000000000000020000030000110071000000000000030100000200003B1ABB" }

// initial state: neutral start, no program selected
fn test_initial() {
    let d = device();
    d.feed(sample_initial());
    expect_props(d, #{ power: "true", status: "ready", error: "false", error_message: "OK", course: "none", spin: "none", temp: "none", rinse: "none", remaining_time: "0", initial_time: "0", cycles: "31", energy: "0", reserve_time: "0", remote_start: "false", door_lock: "false", child_lock: "false", detergent: "medium", softener: "medium", turbo_wash: "false", pre_wash: "false", steam: "false", downloaded_program: "rinse_spin" });
}

// selecting a downloaded program: course shows its base, smart course its catalog name
fn test_downloaded_duvet() {
    let d = device();
    d.feed(sample_downloaded_duvet_selected());
    expect_props(d, #{ status: "ready", course: "duvet", smart_course: "blanket", downloaded_program: "blanket", spin: "400", initial_time: "88", detergent: "medium", softener: "medium" });
}

// status follows the washer through a cycle
fn test_status_follows_a_cycle() {
    let d = device();
    d.feed(sample_measuring());
    expect_props(d, #{ status: "measuring" });
    d.feed(sample_running_door_locked());
    expect_props(d, #{ status: "washing" });
    d.feed(sample_rinsing());
    expect_props(d, #{ status: "rinsing" });
    d.feed(sample_spinning());
    expect_props(d, #{ status: "spinning" });
    d.feed(sample_power_off());
    expect_props(d, #{ status: "off" });
}

// dispenser drawer follows bit 2 of [37], not the bit 6 pulse
fn test_dispenser_drawer() {
    let d = device();
    d.feed(sample_initial());
    expect_props(d, #{ dispenser_drawer: "false" });
    d.feed(sample_drawer_opening());
    expect_props(d, #{ dispenser_drawer: "true" });
    d.feed(sample_drawer_open_pulse_on());
    expect_props(d, #{ dispenser_drawer: "true" });
    d.feed(sample_drawer_open_pulse_off());
    expect_props(d, #{ dispenser_drawer: "true" });
    d.feed(sample_drawer_closed());
    expect_props(d, #{ dispenser_drawer: "false" });
    d.feed(sample_single_block_washing());
    expect_props(d, #{ dispenser_drawer: "false" });
}

// power-off transition
fn test_power_off() {
    let d = device();
    d.feed(sample_power_off());
    expect_props(d, #{ power: "false", status: "off", error: "false", error_message: "OK" });
}

// measuring state: Tub Clean, door locked, remote_start active
fn test_measuring() {
    let d = device();
    d.feed(sample_measuring());
    expect_props(d, #{ status: "measuring", course: "tub_clean", spin: "no_spin", temp: "60", initial_time: "72", remaining_time: "72", cycles: "32", remote_start: "true", door_lock: "true", detergent: "off", softener: "off" });
}

// running state: Eco 40-60, door locked, remote_start active
fn test_running() {
    let d = device();
    d.feed(sample_running_door_locked());
    expect_props(d, #{ status: "washing", course: "eco_40_60", spin: "1400", temp: "40", rinse: "normal", initial_time: "147", remaining_time: "145", remote_start: "true", door_lock: "true", detergent: "high", softener: "low" });
}

// rinsing state
fn test_rinsing() {
    let d = device();
    d.feed(sample_rinsing());
    expect_props(d, #{ status: "rinsing", course: "eco_40_60", temp: "none", remaining_time: "34", energy: "186", initial_time: "147", remote_start: "true", door_lock: "true" });
}

// spinning state: Eco 40-60, door locked, remote_start active
fn test_spinning() {
    let d = device();
    d.feed(sample_spinning());
    expect_props(d, #{ status: "spinning", course: "eco_40_60", spin: "1400", temp: "none", initial_time: "147", remaining_time: "28", energy: "194", cycles: "17", remote_start: "true", door_lock: "true", detergent: "medium", softener: "off" });
}

// single-block (no payload_b) frame still decodes via payload_a
fn test_single_block() {
    let d = device();
    d.feed(sample_single_block_washing());
    expect_props(d, #{ status: "washing", course: "eco_40_60", spin: "1400", temp: "40", initial_time: "147", remaining_time: "142", energy: "6", cycles: "17", remote_start: "true", door_lock: "true", detergent: "medium", softener: "off" });
}

// a well-formed frame with an unrecognized message_type is ignored
fn test_an_unknown_message_type_is_ignored() {
    let d = device();
    d.feed(sample_unknown_message_type());
    expect_eq(d.property("power"), ());
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
    d.feed(sample_measuring());
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

// ezDispense amounts decode from the status push
fn test_ezdispense_amounts() {
    let d = device();
    d.feed(sample_ezdispense_42_30());
    expect_props(d, #{ ezdispense_detergent: "42", ezdispense_softener: "30", detergent: "medium", softener: "medium" });
    d.feed(sample_ezdispense_43_30());
    expect_props(d, #{ ezdispense_detergent: "43", ezdispense_softener: "30", detergent: "medium", softener: "medium" });
    d.feed(sample_ezdispense_43_31());
    expect_props(d, #{ ezdispense_detergent: "43", ezdispense_softener: "31", detergent: "medium", softener: "medium" });
}

// HA write ezDispense amounts sends the same packets as the LG app, and accepts the edges of
// the app range, 9 and 150 ml
fn test_ezdispense_writes() {
    let d = device();
    d.start();
    d.set("ezdispense_detergent", "43");
    expect_eq(last(d), "AA09F0240D012B55BB");
    d.set("ezdispense_softener", "31");
    expect_eq(last(d), "AA09F0240E011FA0BB");
    d.set("ezdispense_detergent", "9");
    expect_eq(last(d), "AA09F0240D01098BBB");
    d.set("ezdispense_softener", "150");
    expect_eq(last(d), "AA09F0240E019639BB");
}

// HA write ezDispense amounts rejects values outside the app range
fn test_ezdispense_rejects_values_outside_the_range() {
    let d = device();
    d.start();
    let n = d.sent().len();
    for v in ["", " ", "0", "8", "151", "256", "42.5", "-1", "abc"] {
        d.set("ezdispense_detergent", v);
        d.set("ezdispense_softener", v);
    }
    expect_eq(d.sent().len(), n);
}

// the dispenser nozzle clean course decodes
fn test_dispenser_clean() {
    let d = device();
    d.feed(dispenser_clean());
    expect_props(d, #{ course: "dispenser_clean" });
}

// running a programme: the assembled command matches the one the LG app sends, dose levels included
fn test_the_programme_matches_the_lg_app() {
    let d = device();
    d.feed(sample_cotton_dosed());
    expect_props(d, #{ detergent: "high", softener: "low" });
    d.set("target_course", "cotton");
    d.set("target_soil", "normal");
    d.set("target_spin", "max");
    d.set("target_temp", "40");
    d.set("target_rinse", "rinse_plus");
    d.set("start_course", "");
    expect_eq(last(d), "AA16F0260103FF04020000000000030000030100B3BB");
}

// running a programme: the dispense type is repeated as reported
fn test_the_dispense_type_is_repeated() {
    let d = device();
    d.feed(dispense_type_2());
    d.set("start_course", "");
    expect_eq(last(d), "AA16F02601000000000000000000030000030102B5BB");
}
