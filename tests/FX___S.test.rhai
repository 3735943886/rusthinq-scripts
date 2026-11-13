import "aabb_test" as a;
import "runtime_test" as runtime;

// Tests of FX___S.rhai (FX25 washer, KR), ported from kshexe/rethink's
// tests/cloud/devices/FX___S.test.ts (commit 8fa8bd4). The full frames are real captures from
// the fork's unit (2026-07-30..09-22); records built with rec() are constructed there too, as
// are the expected writes, which are the app's captured frames or their one-key shape. Names in
// comments are the fork's tests.

fn standby() {
    "aaff200a00980085bc000100ec00860003000408ff0000000000000000520052000700540100f6000000040f04000000002010000000003400000000000004000000000000000000000000000000180000000003030206720000000000000000240024000700720100" +
    "1b000000020f04000000002000000000003400000000000004000000000000000000000000000000180000008025bb"
}
fn started() {
    "aaff200a00980085cf000100ec008600030302067200000000000000002400240007007201001b000000020f04000000002000000000003400000000000004000000000000000000000000000000180000000003030206720000000000000000240024000700720301" +
    "1b000000020f0400000000200000900000340000000000000400000000000000000000000000000018000000f51bbb"
}
fn rinsing() {
    "aaff200a0098008798000100ec0086000303020672000000000000000018001e005e0072280b1b010000020f0400000000200000900100340000000000000400000000000000000000000000000018000000000000020672000000000000000015001c005e00720c0b" +
    "1b010000020f04000000002000009001003400000000000004000000000000000000000000000000180000008b39bb"
}
fn complete() {
    "aaff200a00980088f0000100ec0086000000000672000000000000000001001c007600720e0c1b010000000f0400000000200000900100340000000000000400000000000000000000000000000018000000000000000072000000000000000001001c0080007" +
    "22a0e1b01000000100400000000000000100100340000000000000400000000000000000000000000000018000000b701bb"
}
fn rinse_spin_started() {
    "aaff200a0098008b76000100ec0086000000000072000000000000000001001c008800722f2a1b01000000100400000000000000100100340000000000000c000000000000000000000000000000180000000000000104370000000000000000190019000000370c01" +
    "1105000001100400000000000000900100340000000000000c0000000000000000000000000000001800000046abbb"
}
fn powered_off() {
    "aaff200a0098008c1f000100ec0086000000010437000000000000000014001900050037020c1105000001100400000000000000100100340000000000000c00000000000000000000000000000018000000000000000437000000000000000001000000060037" +
    "00021100000000100400000000000000000100340000000000000400000000000000000000000000000018000000f913bb"
}
fn settings_reply_power_off() {
    "aa5020e6000201ff01020000030300062e00000000000000000100000003002e000105000000000f0300000000200000000000340000000000000400000000000000000000000000000018000000acbb"
}
fn reconnect_snapshot() {
    "aaff200a0055008e8e000100eb00430000000004370000000000000000020019001e00370e0c1105000000100400000000000000900100340000000000000400000000000000000000000000000018000000ac12bb"
}
fn remote_control_on() {
    "aaff200a00980094f8000100ec008600030302067200000000000000002400240032007201001b0000000210040000000020000010000034000000000000040000000000000000000000000000001800000000030302067200000000000000002400240032007201001b000000021004000000002000001001003400000000000004000000000000000000000000000000180000009852bb"
}
fn towels_1_idle() {
    "aaff200a00980085b0000100ec008600030502045500000000000000007c007c0006005501000a000000020f04000000000000000000003400000000000004000000000000000000000000000000180000000003000408ff0000000000000000520052000700540100f6000000040f04000000002010000000003400000000000004000000000000000000000000000000180000000cc4bb"
}
fn door_error_record() {
    "aaff200a009800c3fc000100ec00860000000000370000000000000000010000001d0037002a110000000000030000000000000000000034000000000000040000000000000000000000000000001800000000030302067200000000000000002400240000147202031b000000020003000000002000000000003400000000000004000000000000000000000000000000180000006ad0bb"
}
fn course_table() { "aa1e204d0302160a0272025e022e00f500f60255021b02870237028652bb" }
fn course_table_30() {
    "aa46204d0302171e0272025e022e00f500f60255021b028702370286024a024c0205024e023602080246024f0206" +
    "0212026d026c0269027102410266026a025902380254bcbb"
}
fn declared_20() {
    "aa32204d030218140272025e022e00f500f60255021b028702370286024a024c0205024e023602080246024f02060212" + "5abb"
}
fn zero_course_snapshot() {
    "aaff200a005500a0a7000100eb004300000000000000000000000000000000000000000000010000000000100400000000000000000000300000000000000400000000000000000000000000000018000000c467bb"
}

// A constructed record as a single-record (EB) tunnel frame: `fields` maps offset -> value.
fn rec(fields) {
    let r = blob(66);
    for k in fields.keys() { r[k.parse_int()] = fields[k]; }
    let b = a::bytes([0x20, 0x0a, 0x00, 0x01, 0x00, 0x00, 0x01, 0x00, 0xeb, 0x00, 0x43, 0x00]);
    b += r;
    a::framed(b)
}

fn dial() {
    ["ai_course", "wool", "normal", "normal_1", "towels_1", "tub_clean", "duvet",
     "quick_steam_sanitize", "rinse_spin", "quick_tub_rinse"]
}
fn course_options(d) { runtime::descriptor(d).props.course.options }

// "decodes the idle record"
fn test_the_idle_record() {
    let d = device();
    d.feed(standby());
    expect_props(d, #{
        available: "true", power: "true", status: "initial", running: "false", remaining_time: "0",
        course: "ai_course", soil_wash: "normal", temp: "40", rinse: "2", spin: "high",
        buzzer: "very_high", cycles: "15", initial_time: "36"
    });
    expect_eq(d.property("current_course"), "");
    expect_eq(d.script_error(), ());
}

// "decodes a started cycle, including the running flag and the clock"
fn test_a_started_cycle() {
    let d = device();
    d.feed(started());
    expect_props(d, #{ status: "detecting", running: "true", drum_active: "true", remaining_time: "36",
                       initial_time: "36", current_course: "ai_course" });
}

// "reports the rinse stage and the rinses still to go"
fn test_rinsing() {
    let d = device();
    d.feed(rinsing());
    expect_props(d, #{ status: "rinsing", remaining_time: "21", initial_time: "28", rinse_remaining: "2" });
}

// "does not overwrite the selected settings while a cycle is running"
fn test_settings_hold_during_a_cycle() {
    let d = device();
    d.feed(standby());
    d.feed(started());
    d.feed(rinsing());
    expect_props(d, #{ soil_wash: "normal", temp: "40", rinse: "2" });
}

// "treats phase 42 as complete and suppresses the stuck 1-minute clock"
fn test_complete() {
    let d = device();
    d.feed(complete());
    expect_props(d, #{ status: "end", remaining_time: "0", running: "false", course: "ai_course" });
    expect_eq(d.property("current_course"), "");
}

// "decodes a different course, proving the phase codes are not course-specific"
fn test_rinse_spin() {
    let d = device();
    d.feed(rinse_spin_started());
    expect_props(d, #{ status: "rinsing", remaining_time: "25", rinse_remaining: "1", current_course: "rinse_spin" });
}

// "reports power off from an all-zero record"
fn test_power_off() {
    let d = device();
    d.feed(standby());
    d.feed(powered_off());
    expect_props(d, #{ power: "false", status: "power_off", running: "false", initial_time: "0",
                       cycles: "16", buzzer: "very_high", course: "rinse_spin", soil_wash: "normal",
                       spin: "high" });
}

// "also reads state out of the short-framed settings reply"
fn test_the_settings_reply() {
    let d = device();
    d.feed(settings_reply_power_off());
    expect_eq(d.property("status"), "power_off");
}

// "picks up the single-record snapshot sent on reconnect"
fn test_the_reconnect_snapshot() {
    let d = device();
    d.feed(reconnect_snapshot());
    expect_props(d, #{ status: "spinning", running: "true", course: "rinse_spin", remaining_time: "2",
                       initial_time: "25", cycles: "16", buzzer: "very_high" });
}

// "decodes remote control, the door lock that follows it, and TurboShot"
fn test_remote_control_and_locks() {
    let d = device();
    d.feed(remote_control_on());
    expect_props(d, #{ remote_control: "true", door_lock: "true", child_lock: "false",
                       crease_care: "false", turbo_wash: "true", drum_light: "false",
                       status: "initial", running: "false" });
}

// "decodes the drum light" / "drum_light_auto reads back rec[49] bit 0x20"
fn test_drum_light_and_auto() {
    let d = device();
    d.feed(rec(#{ "20": 1 }));
    expect_props(d, #{ drum_light: "false", drum_light_auto: "false" });
    d.feed(rec(#{ "20": 1, "36": 0x40, "49": 0x60 }));
    expect_props(d, #{ drum_light: "true", drum_light_auto: "true" });
    d.feed(rec(#{ "20": 1 }));
    expect_props(d, #{ drum_light: "false", drum_light_auto: "false" });
}

// "adds a course it has no name for and makes it selectable"
fn test_an_unnamed_course_becomes_an_option() {
    let d = device();
    d.start();
    let b = aabb_unwrap(hex_decode(standby()));
    b[85] = 0x63; // the fork patches frame byte 87, AA FF included
    d.feed(a::framed(b));
    expect_eq(d.property("course"), "course_99");
    expect(course_options(d).contains("course_99"), "offered");
    d.set("course", "course_99");
    expect_eq(hex_encode(d.sent()[0]), "aa0df0e5000201ff010a63a9bb");
}

// "stays available when the appliance drops after being switched off" / "goes unavailable ..."
fn test_availability_on_drop() {
    let d = device();
    d.feed(powered_off());
    d.drop_device();
    expect_eq(d.property("available"), "true");
    let e = device();
    e.feed(standby());
    e.drop_device();
    expect_eq(e.property("available"), "false");
}

// "ignores frames that are not from the appliance"
fn test_frames_not_from_the_appliance() {
    let d = device();
    d.feed("aa09f0241001018cbb");
    expect_eq(d.property("status"), ());
}

// "energy comes from the state record, a minute at a time"
fn test_energy_from_the_record() {
    let d = device();
    d.feed(rec(#{ "20": 11, "4": 0x2e, "16": 1, "17": 25 }));
    expect_eq(d.property("energy"), "281");
    d.feed(rec(#{ "20": 11, "4": 0x2e, "16": 2, "17": 240 }));
    expect_eq(d.property("energy"), "752");
    d.feed(rec(#{ "20": 42, "4": 0x2e, "16": 2, "17": 240 }));
    expect_eq(d.property("energy"), "752");
    d.feed(rec(#{ "20": 0 }));
    expect_eq(d.property("energy"), "752");
    d.feed(rec(#{ "20": 1 }));
    expect_eq(d.property("energy"), "0");
}

// "the appliance reports its own energy every fifteen minutes": `energy` stays the record's,
// and the fork's buckets fed from these are not ported.
fn test_energy_reports() {
    let d = device();
    d.start();
    for f in ["aa0b203e00030003014fbb", "aa0b203e005e00610281bb", "aa0b203e0016007703f6bb",
              "aa0b203e000b008204f1bb", "aa0b203e0003008505f5bb", "aa0b203e0003008806f1bb"] {
        d.feed(f);
        d.feed(f); // each arrived ten times
    }
    expect_eq(d.property("energy"), ());
    expect_eq(d.property("energy_hour"), ());
}

// "FX___S commands": "<name> reproduces the captured frame"
fn test_captured_one_key_writes() {
    let cases = [
        ["power", "false", "aa0df0e5000201ff010200c4bb"],
        ["power", "true", "aa0df0e5000201ff010201c7bb"],
        ["drum_light_auto", "false", "aa0df0e5000201ff011b00ffbb"],
        ["drum_light_auto", "true", "aa0df0e5000201ff011b01febb"],
        ["course", "tub_clean", "aa0df0e5000201ff010a55bbbb"],
        ["course", "ai_course", "aa0df0e5000201ff010a725ebb"],
        ["course", "normal", "aa0df0e5000201ff010a2e92bb"],
        ["laundry_care", "true", "aa0df0e5000201ff015701b2bb"],
        ["laundry_care", "false", "aa0df0e5000201ff015700b3bb"],
        ["buzzer", "mute", "aa0df0e5000201ff011300f7bb"],
        ["buzzer", "low", "aa0df0e5000201ff011301f6bb"],
        ["buzzer", "medium", "aa0df0e5000201ff011302f1bb"],
        ["buzzer", "high", "aa0df0e5000201ff011303f0bb"],
        ["buzzer", "very_high", "aa0df0e5000201ff011304f3bb"],
        ["auto_optimise", "true", "aa0df0e5000201ff014c0189bb"],
        ["auto_optimise", "false", "aa0df0e5000201ff014c008ebb"],
        ["clock_when_off", "true", "aa0df0e5000201ff015801bdbb"],
        ["clock_when_off", "false", "aa0df0e5000201ff015800b2bb"],
        ["steam", "true", "aa0df0e5000201ff013e019bbb"],
        ["turbo_wash", "true", "aa0df0e5000201ff01350190bb"]
    ];
    for c in cases {
        let d = device();
        d.start();
        d.set(c[0], c[1]);
        expect_eq(d.sent().len(), 1);
        expect_eq(hex_encode(d.sent()[0]), c[2]);
    }
}

// Nothing is published from a write; the settings reply's record confirms it.
fn test_writes_are_not_optimistic() {
    let d = device();
    d.start();
    d.feed(rec(#{ "20": 1 }));
    d.set("drum_light_auto", "true");
    expect_eq(d.property("drum_light_auto"), "false");
}

// "start sends the operation write and then the trigger" / "resume ..." / "pause does not ..."
fn test_operations() {
    let d = device();
    d.start();
    d.feed(rec(#{ "20": 1, "36": 0x10 }));
    d.set("start", "");
    expect_eq(hex_encode(d.sent()[0]), "aa0df0e5000201ff010301c6bb");
    expect_eq(hex_encode(d.sent()[1]), "aa09f0241001018cbb");
    d.feed(rec(#{ "20": 11, "36": 0x10 }));
    d.set("pause", "");
    expect_eq(d.sent().len(), 3);
    expect_eq(hex_encode(d.sent()[2]), "aa0df0e5000201ff010302c1bb");
    d.feed(rec(#{ "20": 2, "36": 0x10 }));
    d.set("resume", "");
    expect_eq(hex_encode(d.sent()[3]), "aa0df0e5000201ff010303c0bb");
    expect_eq(hex_encode(d.sent()[4]), "aa09f0241001018cbb");
}

// "add wash replays the frame the app sent, byte for byte"
fn test_add_garment() {
    let d = device();
    d.start();
    d.feed(rec(#{ "20": 42, "36": 0x10 }));
    d.set("add_garment", "");
    expect_eq(d.sent().len(), 1);
    expect_eq(hex_encode(d.sent()[0]), "aa0ff0e5000201ff020a37030182bb");
}

// The fork's button availability, enforced: "standby offers start, and nothing else", "a running
// cycle offers pause", "paused offers resume", "remote control off takes start and resume away,
// but not pause", "switched off, start is not offered either", "add wash is gated like start".
fn refused(d, prop) {
    let n = d.sent().len();
    d.set(prop, "");
    d.sent().len() == n
}

fn test_operation_gating() {
    let d = device();
    d.start();
    d.feed(rec(#{ "20": 1, "36": 0x10 }));
    expect(refused(d, "pause"), "no pause at standby");
    expect(refused(d, "resume"), "no resume at standby");
    d.feed(rec(#{ "20": 11, "36": 0x10 }));
    expect(refused(d, "start"), "no start while running");
    expect(refused(d, "add_garment"), "no add wash while running");
    expect(refused(d, "resume"), "no resume while running");
    d.feed(rec(#{ "20": 2, "36": 0x10 }));
    expect(refused(d, "pause"), "no pause while paused");
    d.feed(rec(#{ "20": 1 }));
    expect(refused(d, "start"), "no start without remote control");
    d.feed(rec(#{ "20": 2 }));
    expect(refused(d, "resume"), "no resume without remote control");
    d.feed(rec(#{ "20": 11 }));
    expect(!refused(d, "pause"), "pause without remote control");
    d.feed(rec(#{ "20": 0, "36": 0x10 }));
    expect(refused(d, "start"), "no start when switched off");
    // "a tub clean is a running cycle": "it offers pause, and does not offer start"
    d.feed(rec(#{ "20": 41, "36": 0x10, "12": 1, "13": 22, "14": 1, "15": 24 }));
    expect_props(d, #{ status: "running", running: "true", remaining_time: "82", initial_time: "84" });
    expect(refused(d, "start"), "no start during a tub clean");
    expect(!refused(d, "pause"), "pause during a tub clean");
}

// "selecting an extended course rebuilds the frame the app itself sent" /
// "an extended course does nothing until a record has been seen"
fn test_extended_course() {
    let d = device();
    d.start();
    d.set("course", "towels_1");
    expect_eq(d.sent().len(), 0);
    d.feed(towels_1_idle());
    d.set("course", "towels_1");
    expect_eq(hex_encode(d.sent()[0]), "aa20f0e5000201ff0a0aff0bf61e03200421081f0035013e0143007f00002cbb");
}

// "rejects a value that is not in the option list"
fn test_bad_values_are_rejected() {
    let d = device();
    d.start();
    d.set("spin", "warp_speed");
    d.set("rinse", "9");
    d.set("status", "initial");
    expect_eq(d.sent().len(), 0);
    expect(d.event("reject") != (), "rejected");
}

// "FX___S course table": "the select becomes the dial, in the order the appliance gives it"
fn test_the_dial() {
    let d = device();
    d.start();
    expect(course_options(d).contains("shirt"), "everything is offered at first");
    d.feed(course_table());
    expect_eq(course_options(d), dial());
    expect_eq(runtime::descriptor(d).props.current_course.options, dial());
    // "the two extended courses are the ones the appliance marks with kind 0x00"
    d.feed(towels_1_idle());
    d.set("course", "normal_1");
    expect(hex_encode_upper(d.sent()[0]).contains("0AFF0BF5"), "extended write");
    // "an ordinary course write goes out for one the declaration no longer lists": refused here,
    // the descriptor offers the dial
    let n = d.sent().len();
    d.set("course", "shirt");
    expect_eq(d.sent().len(), n);
}

// "a declaration whose header byte has moved is read" / "a declaration with a higher revision
// and fewer courses is still read" / "the ten taken off the dial leave the list with it"
fn test_dial_revisions() {
    let d = device();
    d.start();
    d.feed(course_table_30());
    let o = course_options(d);
    expect_eq(o.len(), 30);
    expect_eq(o[29], "towels");
    d.feed(declared_20());
    o = course_options(d);
    expect_eq(o.len(), 20);
    expect_eq(o[19], "colorcare");
    expect(!o.contains("shirt"), "shirt left the dial");
}

// "...except whatever is selected right now, which has to stay offered"
fn test_the_selected_course_stays_offered() {
    let d = device();
    d.start();
    d.feed(course_table_30());
    d.feed(rec(#{ "20": 1, "4": 0x54 }));
    d.feed(declared_20());
    expect_eq(d.property("course"), "towels");
    expect(course_options(d).contains("towels"), "towels kept");
    expect_eq(course_options(d).len(), 21);
}

// "a declared course nobody has named is offered under its number" / "... can actually be selected"
fn test_unnamed_declared_courses() {
    let d = device();
    d.start();
    d.feed("aa10204d03021603022e029900aa00bb");
    expect_eq(course_options(d), ["normal", "course_153", "course_ext_170"]);
    d.set("course", "course_153");
    expect_eq(hex_encode(d.sent()[0]), "aa0df0e5000201ff010a9967bb");
}

// "the other two variants of the message leave the select alone" / "a count that disagrees with
// the frame length is ignored"
fn test_other_dial_variants() {
    let d = device();
    d.start();
    let before = course_options(d);
    d.feed("aa30204d0202160200f52e01071e03200321061f00350143003e0100f65401071e03200421081f00350143003e0132bb");
    d.feed("aa0b204d010301020379bb");
    d.feed("aa10204d0302160a022e029900aa00bb");
    expect_eq(course_options(d), before);
}

// "a course byte of 0 is not offered as a course" / "it leaves the last real course standing"
fn test_a_zero_course() {
    let d = device();
    d.start();
    d.feed(standby());
    let before = course_options(d);
    d.feed(zero_course_snapshot());
    expect_eq(course_options(d), before);
    expect_eq(d.property("course"), "ai_course");
    expect_eq(d.property("power"), "false");
    // "an extended course with a zero identifier is not offered either"
    d.feed(rec(#{ "20": 1, "4": 0xff, "22": 0 }));
    expect_eq(course_options(d), before);
    expect_eq(d.property("course"), "ai_course");
}

// "FX___S current course clears when nothing is running"
fn test_current_course() {
    let d = device();
    d.feed(standby());
    expect_eq(d.property("current_course"), "");
    d.feed(started());
    expect_eq(d.property("current_course"), "ai_course");
    d.feed(rec(#{ "20": 42, "4": 0x72 }));
    expect_eq(d.property("current_course"), "");
    d.feed(rec(#{ "20": 47, "4": 0x72 }));
    expect_eq(d.property("current_course"), "");
    d.feed(rec(#{ "20": 1, "4": 0x2e }));
    expect_eq(d.property("current_course"), "");
    d.feed(rec(#{ "20": 11, "4": 0x2e }));
    expect_eq(d.property("current_course"), "normal");
}

// "phase N is <name>" and "no declared state reads as unknown"
fn test_state_names() {
    let measured = [[0, "power_off"], [1, "initial"], [2, "pause"], [3, "detecting"], [37, "detecting"],
                    [11, "running"], [40, "detecting"], [12, "rinsing"], [14, "spinning"], [41, "running"],
                    [42, "end"], [47, "refreshing"], [7, "reserved"], [16, "end"]];
    let d = device();
    for m in measured {
        d.feed(rec(#{ "20": m[0] }));
        expect_eq(d.property("status"), m[1]);
    }
    for p in [5, 6, 8, 9, 13, 15, 21, 23, 27, 28, 29, 34, 35, 36, 38, 39, 43, 48, 49] {
        d.feed(rec(#{ "20": p }));
        expect(d.property("status") != "", "phase " + p + " is named");
    }
    // "a byte outside the declaration still falls back": absent here
    d.feed(rec(#{ "20": 200 }));
    expect_eq(d.property("status"), "");
}

// "FX___S delay-end reservation"
fn idle(minutes, flag) {
    let f = #{ "0": 3, "1": 3, "2": 2, "3": 6, "4": 0x72, "20": 1, "33": 0x20,
               "10": (minutes >> 8) & 0xff, "11": minutes & 0xff };
    if flag { f["38"] = 0x80; }
    rec(f)
}

fn test_reservation_reads() {
    let d = device();
    d.feed(idle(300, true));
    expect_eq(d.property("reserve_time"), "300");
    d.feed(idle(330, true));
    expect_eq(d.property("reserve_time"), "330");
    d.feed(idle(210, true));
    expect_eq(d.property("reserve_time"), "210");
    // "reads no reservation as zero, and ignores a stale count without the flag"
    d.feed(idle(330, false));
    expect_eq(d.property("reserve_time"), "0");
}

// "writing 5 hours reproduces the frame the app sent" / "writing 5.5 hours ..." / "zero is sent"
fn test_reservation_writes() {
    let d = device();
    d.start();
    d.feed(idle(0, false));
    d.set("reserve_time", "300");
    expect_eq(hex_encode(d.sent()[0]), "aa1cf0e5000201ff081e03200221061f0335013e0043007f012cc1bb");
    d.set("reserve_time", "330");
    expect_eq(hex_encode(d.sent()[1]), "aa1cf0e5000201ff081e03200221061f0335013e0043007f014ae7bb");
    d.set("reserve_time", "0");
    expect(a::inner_hex(d, 2).ends_with("7f0000"), "zero is the app's none");
}

// "refuses what the appliance declares out of range" / "does nothing until a record has been seen"
fn test_reservation_refusals() {
    let d = device();
    d.start();
    d.set("reserve_time", "300");
    expect_eq(d.sent().len(), 0);
    d.feed(idle(0, false));
    d.set("reserve_time", "120");
    d.set("reserve_time", "1200");
    d.set("reserve_time", "315");
    expect_eq(d.sent().len(), 0);
}

// "FX___S reservation armed on the appliance itself"
fn armed(minutes) {
    rec(#{ "4": 0x72, "10": (minutes >> 8) & 0xff, "11": minutes & 0xff, "20": 7, "21": 1,
           "36": 0x80, "38": 0x80, "13": 30 })
}

fn test_an_armed_reservation() {
    let d = device();
    d.feed(armed(180));
    expect_props(d, #{ status: "reserved", reserve_time: "180", drum_active: "false", running: "false",
                       remaining_time: "0" });
    // "it counts down a minute at a time without the reservation setpoint jittering"
    for m in [420, 419, 418, 417, 416] {
        d.feed(armed(m));
        expect_eq(d.property("reserve_time"), "420");
    }
    // "powering off clears the reservation"
    d.feed(rec(#{}));
    expect_props(d, #{ reserve_time: "0", status: "power_off" });
    // "the bit still means the drum in the phases where that was measured"
    d.feed(started());
    expect_eq(d.property("drum_active"), "true");
}

// "course auto-optimisation is key 0x4C and bit 0x08 of byte 39" / "the clock while switched off
// is key 0x58 and bit 0x80 of byte 46"
fn test_appliance_settings_read_back() {
    let d = device();
    d.feed(rec(#{ "20": 1, "39": 0x34, "46": 0x04 }));
    expect_props(d, #{ auto_optimise: "false", clock_when_off: "false", laundry_care: "false" });
    d.feed(rec(#{ "20": 1, "39": 0x3c, "46": 0x84 }));
    expect_props(d, #{ auto_optimise: "true", clock_when_off: "true", laundry_care: "false" });
    d.feed(rec(#{ "20": 1, "46": 0x8c }));
    expect_props(d, #{ clock_when_off: "true", laundry_care: "true" });
}

// "the switches take the selection from standby", "and from the first record of a cycle",
// "but only on the move in", "and hold it when the appliance zeroes the bytes"
fn cycle(phase, turbo, steam) {
    let f = #{ "20": phase, "4": 0x2e, "46": 0x04 };
    if turbo { f["33"] = 0x20; }
    if steam { f["34"] = 0x10; }
    rec(f)
}

fn test_cycle_settings_are_held() {
    let d = device();
    d.feed(cycle(1, false, false));
    expect_eq(d.property("steam"), "false");
    d.feed(cycle(3, true, true));
    expect_props(d, #{ steam: "true", turbo_wash: "true" });
    d.feed(cycle(12, false, false));
    expect_eq(d.property("steam"), "true");
    d.feed(cycle(42, false, false));
    d.feed(cycle(0, false, false));
    expect_props(d, #{ steam: "true", turbo_wash: "true" });
    d.feed(cycle(1, false, false));
    expect_props(d, #{ steam: "false", turbo_wash: "false" });
}

// "the steam sensor answers 'does this cycle use steam' for the whole cycle", "a cycle joined
// after the steam stage cannot claim steam", "the sensors answer the other question"
fn test_cycle_uses() {
    let d = device();
    d.feed(cycle(1, true, true));
    expect_props(d, #{ steam_active: "false", turbo_wash_active: "false" });
    d.feed(cycle(11, true, true));
    expect_props(d, #{ steam_active: "true", turbo_wash_active: "true" });
    d.feed(cycle(12, true, false));
    expect_props(d, #{ steam_active: "true", turbo_wash_active: "true" });
    d.feed(cycle(2, true, true));
    expect_props(d, #{ running: "false", turbo_wash_active: "true" });
    d.feed(cycle(42, false, false));
    expect_props(d, #{ steam_active: "false", turbo_wash_active: "false" });
    let e = device();
    e.feed(cycle(12, true, false));
    expect_eq(e.property("steam_active"), "false");
}

// "FX___S the two moments it announces"
fn test_notifications() {
    let d = device();
    d.feed("aa09207200000010bb");
    expect_eq(json_parse(d.event("notification")).event_type, "washing_is_complete");
    expect_eq(d.property("status"), ());
    d.feed("aa0c2072006403000000fabb");
    expect_eq(json_parse(d.event("notification")).event_type, "error_during_washing");
    let e = device();
    e.feed("aa09207200c80058bb");
    e.feed("aa09207200c9005bbb");
    expect_eq(e.event("notification"), ());
}

// "the fault names itself", "a fault already present in the very first record is not fired",
// "a code LG does not declare still publishes something"
fn test_error_events() {
    let d = device();
    d.feed(door_error_record());
    expect_eq(d.event("error"), ());
    d.feed(standby());
    d.feed(door_error_record());
    expect_eq(json_parse(d.event("error")).event_type, "door_open_error");
    let e = device();
    e.feed(rec(#{}));
    e.feed(rec(#{ "18": 99 }));
    expect_eq(json_parse(e.event("error")).event_type, "unknown_error");
}

fn test_the_descriptor() {
    let d = device();
    d.start();
    let desc = runtime::descriptor(d);
    expect_eq(desc.kind, "washer");
    expect_eq(desc.props.start.requires, "remote_control");
    expect_eq(desc.props.reserve_time.step, 30);
    expect_eq(desc.props.course.options.len(), 30);
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

fn test_reconnect_publishes_no_defaults() {
    let d = device();
    d.start();
    d.feed(standby());
    d.drop_device();
    d.start();
    expect_eq(d.property("course"), "ai_course");
}
