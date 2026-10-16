import "runtime_test" as runtime;

// Tests of F_V8_Y___W.B_2QEUK (washer_common), ported from upstream rethink's test suite
// (commit 0e57069; captures from an F6WV710P2S, issue #75). Expected values are what upstream's
// driver publishes for the same input, in IL names; door_lock is true while locked (upstream
// publishes it inverted, for Home Assistant's lock class).

fn sample_cotton_std() { "AA5420EC002501000000000000000000000000000000000000000001006400000000000000000000000000002501033A033A0100030B04010000000000010002000001006400000400000000000000000000E0BB" }
fn sample_allergy_steam() { "AA5420EC002501021C021C0900030504010000000000000002000001006400000500000000000000000000002501023002302D00030B06010000008000000003000001006400000500000000000000000000F2BB" }
fn sample_cotton_steam() { "AA5420EC002501031C031C0100030B03010000000000010002000001006400000400000000000000000000002501041104110100030B0601000000800001000300000100640000040000000000000000000015BB" }
fn sample_turbowash() { "AA5420EC002501041104110100030B06010000008000010003000001006400000400000000000000000000002501031D031D010003070601000000010001000300000100640000040000000000000000000016BB" }
fn sample_rinse_plus() { "AA5420EC002501033703370100030706010000000000010004000001006400000400000000000000000000002501040C040C0100030706020000000000010004000001006400000500000000000000000000B9BB" }
fn sample_prewash() { "AA5420EC002501033703370100030706010000000000010004000001006400000400000000000000000000002501040C040C01000307060100000040000100040000010064000005000000000000000000007EBB" }
fn sample_intensive() { "AA5420EC002501033703370100030706010000000000010004000001006400000400000000000000000000002501041604160100040706010000000000010004000001006400000400000000000000000000AABB" }

// Cotton 40°C 1600 RPM decodes with no options set
fn test_cotton_40_1600_no_options() {
    let d = device();
    d.feed(sample_cotton_std());
    expect_props(d, #{ course: "cotton", temp: "40", spin: "1600", extra_rinse: "false", turbo_wash: "false", pre_wash: "false", steam: "false", soil: "normal" });
}

// Allergy Care 60°C Steam 1600 RPM decodes steam=ON
fn test_allergy_care_steam() {
    let d = device();
    d.feed(sample_allergy_steam());
    expect_props(d, #{ course: "allergy_care", temp: "60", spin: "1600", steam: "true", turbo_wash: "false", pre_wash: "false", extra_rinse: "false", soil: "normal" });
}

// Cotton 60°C Steam decodes steam=ON
fn test_cotton_60_steam() {
    let d = device();
    d.feed(sample_cotton_steam());
    expect_props(d, #{ course: "cotton", temp: "60", steam: "true", turbo_wash: "false" });
}

// TurboWash decodes turbowash=ON and 1000 RPM
fn test_turbo_wash() {
    let d = device();
    d.feed(sample_turbowash());
    expect_props(d, #{ turbo_wash: "true", spin: "1000", steam: "false", pre_wash: "false", extra_rinse: "false", soil: "normal" });
}

// Rinse+ decodes extra_rinse=ON
fn test_rinse_plus() {
    let d = device();
    d.feed(sample_rinse_plus());
    expect_props(d, #{ extra_rinse: "true", turbo_wash: "false", pre_wash: "false", steam: "false", soil: "normal" });
}

// Pre-wash decodes prewash=ON
fn test_pre_wash() {
    let d = device();
    d.feed(sample_prewash());
    expect_props(d, #{ pre_wash: "true", turbo_wash: "false", steam: "false", extra_rinse: "false", soil: "normal" });
}

// Intensive Wash decodes soil=Intensive
fn test_intensive() {
    let d = device();
    d.feed(sample_intensive());
    expect_props(d, #{ soil: "intensive", turbo_wash: "false", pre_wash: "false", steam: "false", extra_rinse: "false" });
}

// config exposes the model's components
fn test_the_descriptor_lists_the_model_features() {
    let d = device();
    d.start();
    let props = runtime::descriptor(d).props;
    expect(props.contains("soil"), "soil");
    expect(props.contains("reserve_time"), "reserve_time");
    expect(props.contains("extra_rinse"), "extra_rinse");
    expect(props.contains("turbo_wash"), "turbo_wash");
    expect(props.contains("pre_wash"), "pre_wash");
    expect(props.contains("steam"), "steam");
    expect(props.contains("child_lock"), "child_lock");
    expect(!props.contains("detergent"), "no detergent");
    expect(!props.contains("drying_mode"), "no drying_mode");
    expect(!props.contains("eco_hybrid"), "no eco_hybrid");
}
