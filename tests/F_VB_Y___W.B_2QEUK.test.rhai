import "runtime_test" as runtime;

// Tests of F_VB_Y___W.B_2QEUK (washer_common), ported from upstream rethink's test suite
// (commit 0e57069; captures from a Vivace V750, firmware 2.10.123). Expected values are what
// upstream's driver publishes for the same input, in IL names; door_lock is true while locked
// (upstream publishes it inverted, for Home Assistant's lock class).

fn sample_idle() { "AA5420EC002600000000000000000000000000000000000000010008006400000000000002022A1E000201002601000000000000000000000000000000000000000008006400000000000002022A1E00000199BB" }
fn sample_cotton() { "AA5420EC002601002400241B00030503010000000000000001000008006400000300000001002A1E000001002601030203020100030A04010000000000010003000008006400000400000000002A1E0080018EBB" }
fn sample_allergy_steam() { "AA5420EC002601021C021C0900030504010000000000000002000008006400000500000002022A1E000201002601023002302D00030A06010000008000000004000008006400000500000002022A1E00020100BB" }
fn sample_easycare_rinse_prewash() { "AA5420EC002601023502350200030A03020000000000010002000008006400000300000001002A1E000001002601030A030A0200030A03020000004000010003000008006400000400000001002A1E00000197BB" }
fn sample_intensive() { "AA5420EC002601013A013A0200030A04010000000000010002000008006400000300000001002A1E000001002601032003200200040A04010000000000010003000008006400000300000001002A1E000001E3BB" }
fn sample_delay_19h() { "AA5420EC002601000E000E0C00030202010012000100000000000008006400000100000001002A1E000001002601000E000E0C00030202010013000100000000000008006400000100000001002A1E00000118BB" }
fn sample_detergent_high() { "AA5420EC002601031D031D0200030706020000008000010004000008006400000300000002002A1E008001002601031D031D0200030706020000008000010004000008006400000300000003002A1E000001AABB" }
fn sample_softener_high() { "AA5420EC002601000E000E0C00030202010000000100000000000008006400000100000001022A1E000201002601000E000E0C00030202010000000100000000000008006400000100000001032A1E00020164BB" }
fn sample_running() { "AA5420EC002606000C000E0C00030202010000000142200001010008006400000100001301002A1E000001002606000C000E0C00030202010000000142200001010008006400000100001401002A1E00000148BB" }
fn sample_paused() { "AA5420EC0026070009000E0C00030200010000000142000001060008006400000100002301002A1E0000010026020009000E0C00030200010000000140000000070008006400000100002301002A1E000001A2BB" }
fn sample_end() { "AA5420EC00260A0000000E0C00000000000000000040000001080008006400000100002901002A1E00000100260A0000000E0C00000000000000000000000001080008006400000100002901002A1E000001E5BB" }
fn sample_power_off() { "AA5420EC002601010C010C1200030106010000000000000003000009006400000200002900002A1E000001002600010C010C1200000000000000000000000003010009006400000200002900002A1E000001D6BB" }
fn pause_marker() { "AA09207200C80058BB" }
fn ack_pause_marker() { "AA08F00072044DBB" }
fn power_off_marker() { "AA0720D809E7BB" }
fn ack_power_off_marker() { "AA08F000D8042BBB" }

// config exposes the model's components
fn test_the_descriptor_lists_the_model_features() {
    let d = device();
    d.start();
    let props = runtime::descriptor(d).props;
    expect(props.contains("detergent"), "detergent");
    expect(props.contains("softener"), "softener");
    expect(props.contains("soil"), "soil");
    expect(!props.contains("child_lock"), "no child_lock");
    expect(!props.contains("drying_mode"), "no drying_mode");
}

// idle: Ready, no course
fn test_idle() {
    let d = device();
    d.feed(sample_idle());
    expect_props(d, #{ power: "true", status: "standby", error: "false", detergent: "medium", softener: "medium" });
}

// Cotton 1400 RPM 40°C decodes with no options and dosing off
fn test_cotton() {
    let d = device();
    d.feed(sample_cotton());
    expect_props(d, #{ course: "cotton", spin: "1400", temp: "40", initial_time: "182", remaining_time: "182", detergent: "off", softener: "off", extra_rinse: "false", turbo_wash: "false", pre_wash: "false", steam: "false", soil: "normal" });
}

// Allergy Care with Steam
fn test_allergy_care_steam() {
    let d = device();
    d.feed(sample_allergy_steam());
    expect_props(d, #{ course: "allergy_care", temp: "60", steam: "true", pre_wash: "false" });
}

// Rinse+ and Pre-wash
fn test_rinse_plus_and_pre_wash() {
    let d = device();
    d.feed(sample_easycare_rinse_prewash());
    expect_props(d, #{ course: "ease_care", temp: "30", extra_rinse: "true", pre_wash: "true", steam: "false" });
}

// Intensive wash
fn test_intensive() {
    let d = device();
    d.feed(sample_intensive());
    expect_props(d, #{ soil: "intensive", extra_rinse: "false" });
}

// delayed start hours are published as reserve_time
fn test_delay_19h() {
    let d = device();
    d.feed(sample_delay_19h());
    expect_props(d, #{ course: "quick_14", reserve_time: "19", turbo_wash: "true" });
}

// detergent and softener doses
fn test_detergent_high() {
    let d = device();
    d.feed(sample_detergent_high());
    expect_props(d, #{ detergent: "high", softener: "off" });
}

// detergent and softener doses
fn test_softener_high() {
    let d = device();
    d.feed(sample_softener_high());
    expect_props(d, #{ detergent: "low", softener: "high" });
}

// running: door lock engaged, times and energy
fn test_running() {
    let d = device();
    d.feed(sample_running());
    expect_props(d, #{ status: "washing", door_lock: "true", remote_start: "true", initial_time: "14", remaining_time: "12", energy: "20", cycles: "8" });
}

// paused
fn test_paused() {
    let d = device();
    d.feed(sample_paused());
    expect_props(d, #{ status: "paused", remote_start: "false", door_lock: "true" });
}

// end of cycle: door unlocked, final energy
fn test_end() {
    let d = device();
    d.feed(sample_end());
    expect_props(d, #{ status: "end", door_lock: "false", remaining_time: "0", energy: "41" });
}

// powered off: cycle counter has advanced
fn test_power_off() {
    let d = device();
    d.feed(sample_power_off());
    expect_props(d, #{ power: "false", status: "off", cycles: "9", energy: "41" });
}

// acks the other frames of the machine as the cloud does, but not the status packets
fn test_acks_other_frames_but_not_status() {
    let d = device();
    d.feed(pause_marker());
    d.feed(power_off_marker());
    expect_eq(d.clips().map(|c| c.data), [ack_pause_marker(), ack_power_off_marker()]);
    d.feed(sample_running());
    expect_eq(d.clips().len(), 2);
    expect_eq(d.property("status"), "washing");
}

// 19 (AUTO_DT_OPEN_PAUSE) reads as paused on this model (upstream commit 6881ea2)
fn test_auto_door_open_pause_is_paused() {
    let ec = hex_decode(sample_running());
    let r = ec.extract(4 + 39, 39);
    r[2] = 19;
    let d = device();
    d.feed(hex_encode(aabb_wrap(hex_decode("20EB") + r)));
    expect_eq(d.property("status"), "paused");
}
