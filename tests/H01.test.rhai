import "aabb_test" as a;
import "runtime_test" as runtime;

// Tests of H01.rhai (dishwasher), ported from kshexe/rethink's tests/cloud/devices/H01.test.ts
// (commit 8fa8bd4). The status frames are real captures from the fork's unit (2026-09-10..18);
// the power and settings writes are the fork's captured frames. The energy report and the course
// start are constructed there (never seen from this unit) and so here.

fn ack() { "aa08320026005fbb" }
fn ec_standard_55() {
    "aa3a32ec001800000000370000003700005000000009915f00000000000c00180100000037050000370000520000000b935f00000000000c91bb"
}
fn eb_off_55() { "aa2032eb001804000000370000000100000200000002805f00000000000c7fbb" }
fn end_melody_on() {
    "aa3a32ec00180100000037050000370000500000000b935f00000000000c00180100000037050000370000500000000b975f00000000000c85bb"
}
fn air_filter_off() {
    "aa3a32ec00180100000037050000370000500000000b935f00000000000c00180100000037050000370000500000000b835f00000000000ce9bb"
}
fn wash_complete_light_off() {
    "aa3a32ec00180100000037050000370000500000000b935f00000000000c00180100000037050000370000100000000b935f00000000000cd9bb"
}
fn time_display_off() {
    "aa3a32ec00180100000037050000370000500000000b935f00000000000c001801000000370500003700005000000003935f00000000000c91bb"
}
fn auto_select_off() {
    "aa3a32ec00180100000037050000370000500000000b935f00000000000c00180100000037050000370000400000000b935f00000000000ce9bb"
}
fn cool_dry_off() {
    "aa3a32ec00180100000037050000370000500000000b935f00000000000c00180100000037050000370000500000000b925f00000000000c9ebb"
}
fn energy_synthetic() { "aa0b323e003201f4031abb" }

fn test_the_descriptor() {
    let d = device();
    d.start();
    let desc = runtime::descriptor(d);
    expect_eq(desc.props.cool_dry.rw, true);
    expect_eq(desc.props.cool_dry.category, "config");
    expect_eq(desc.props.steam.rw, ());
    expect_eq(desc.props.target_course.options, ["자동", "강력", "표준", "통살균", "건조단독", "야간조용"]);
    expect_eq(hex_encode_upper(d.sent()[0]), "AA0EF0ED1211010000010400EBBB");
    expect_eq(d.script_error(), ());
}

// "power write reproduces the captured frame byte for byte"
fn test_power_writes() {
    let d = device();
    d.set("power", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa07f0261688bb");
    d.set("power", "false");
    expect_eq(hex_encode(d.sent()[1]), "aa07f026128cbb");
    expect_eq(d.property("power"), ()); // not optimistic: the record reads it back
}

// "start_course is not sent before target_course is set"
fn test_start_course_needs_a_target() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("start_course", "");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "rejected");
}

// "target_course is published ..., start_course then reproduces the UNVERIFIED shape"
fn test_start_course() {
    let d = device();
    d.start();
    d.set("target_course", "표준");
    expect_eq(d.property("target_course"), "표준");
    d.set("start_course", "");
    expect_eq(hex_encode(d.sent()[1]), "aa0df02610050000000000b7bb");
    // An unknown course is refused by the descriptor.
    let n = d.sent().len();
    d.set("target_course", "다운로드");
    expect_eq(d.property("target_course"), "표준");
    expect_eq(d.sent().len(), n);
}

fn test_a_reload_keeps_the_target_course() {
    let d = device();
    d.start();
    d.set("target_course", "강력");
    d.start();
    expect_eq(d.property("target_course"), "강력");
}

// "the ack frame is accepted and publishes nothing"
fn test_the_ack() {
    let d = device();
    d.feed(ack());
    expect_eq(d.property("power"), ());
    expect_eq(d.script_error(), ());
}

// "a real 0xEC status frame decodes power/duration/course/options"
fn test_a_real_ec_record() {
    let d = device();
    d.feed(ec_standard_55());
    expect_props(d, #{
        available: "true",
        power: "true",
        initial_time: "55",
        course_index: "5",
        reservation_hours: "0",
        steam: "false",
        intensive_wash_top: "false",
        intensive_wash_bottom: "false",
        high_temp: "false",
        extra_rinse: "false",
        heat_dry: "0",
        auto_select: "true",
        wash_complete_light: "true",
        time_indicator: "true",
        cool_dry: "true",
        end_alarm_sound: "false",
        air_filter: "true"
    });
    expect_eq(d.script_error(), ());
}

// "a real 0xEB query response decodes the same way as an 0xEC record"
fn test_a_real_eb_record() {
    let d = device();
    d.feed(eb_off_55());
    expect_props(d, #{ power: "false", initial_time: "55", course_index: "0" });
}

// The option bits and dry tier (constructed: the baseline record with [14] = 0xe8, [17] = 0x3f).
fn test_option_bits_and_dry_tier() {
    let d = device();
    let b = aabb_unwrap(hex_decode(eb_off_55()));
    b[2 + 14] = 0xe8;
    b[2 + 17] = 0x3f;
    b[2 + 11] = 3;
    d.feed(a::framed(b));
    expect_props(d, #{
        steam: "true", intensive_wash_top: "true", intensive_wash_bottom: "true", high_temp: "true",
        extra_rinse: "true", heat_dry: "90", reservation_hours: "3"
    });
}

// "<prop> reads <want> off a real captured status frame, siblings unaffected"
fn test_the_six_settings_read_back() {
    let cases = [
        ["end_alarm_sound", end_melody_on(), "true"],
        ["air_filter", air_filter_off(), "false"],
        ["wash_complete_light", wash_complete_light_off(), "false"],
        ["time_indicator", time_display_off(), "false"],
        ["auto_select", auto_select_off(), "false"],
        ["cool_dry", cool_dry_off(), "false"]
    ];
    for c in cases {
        let d = device();
        d.feed(c[1]);
        expect_eq(d.property(c[0]), c[2]);
    }
}

// "a settings write is not sent before any status record has been seen"
fn test_a_setting_needs_a_record() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("auto_select", "false");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "rejected");
}

// "each settings write reproduces the captured frame byte for byte, both directions"
fn test_the_captured_settings_writes() {
    let cases = [
        ["end_alarm_sound", "true", "aa0ef0260000f882000000001dbb"],
        ["end_alarm_sound", "false", "aa0ef0260000b882000000005dbb"],
        ["air_filter", "false", "aa0ef0260000b8800000000053bb"],
        ["air_filter", "true", "aa0ef0260000b882000000005dbb"],
        ["wash_complete_light", "false", "aa0ef0260000b0820000000055bb"],
        ["wash_complete_light", "true", "aa0ef0260000b882000000005dbb"],
        ["time_indicator", "false", "aa0ef0260000a88200000000adbb"],
        ["time_indicator", "true", "aa0ef0260000b882000000005dbb"],
        ["auto_select", "false", "aa0ef0260000988200000000bdbb"],
        ["auto_select", "true", "aa0ef0260000b882000000005dbb"],
        ["cool_dry", "false", "aa0ef0260000388200000000ddbb"],
        ["cool_dry", "true", "aa0ef0260000b882000000005dbb"]
    ];
    for c in cases {
        let d = device();
        d.feed(ec_standard_55());
        let n = d.sent().len();
        d.set(c[0], c[1]);
        expect_eq(d.sent().len(), n + 1);
        expect_eq(hex_encode(d.sent()[n]), c[2]);
        // Not optimistic: the property stays at the record's value until the next record.
        expect_eq(d.property("cool_dry"), "true");
    }
}

// "a 32 3e report publishes the cycle total directly ..."
fn test_the_constructed_energy_report() {
    let d = device();
    d.start();
    d.feed(energy_synthetic());
    expect_eq(d.property("energy"), "500");
    expect_eq(d.property("energy_hour"), ()); // the fork's buckets are not ported
}

fn test_reconnect_publishes_no_defaults() {
    let d = device();
    d.start();
    d.feed(ec_standard_55());
    d.drop_device();
    d.start();
    expect_eq(d.property("power"), "true");
}
