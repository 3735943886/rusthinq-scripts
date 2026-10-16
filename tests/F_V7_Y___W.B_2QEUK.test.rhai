import "runtime_test" as runtime;

// Tests of F_V7_Y___W.B_2QEUK, an alias of F_V8_Y___W.B_2QEUK, ported from upstream rethink's
// test suite (commit 0e57069; F_V8_Y captures). Expected values are what upstream's driver
// publishes for the same input, in IL names; door_lock is true while locked (upstream publishes
// it inverted, for Home Assistant's lock class).

fn sample_allergy_steam() { "AA5420EC002501021C021C0900030504010000000000000002000001006400000500000000000000000000002501023002302D00030B06010000008000000003000001006400000500000000000000000000F2BB" }

// upstream maps this model to F_V8_Y___W.B_2QEUK
fn test_decodes_as_f_v8_y() {
    let d = device();
    d.feed(sample_allergy_steam());
    expect_props(d, #{ course: "allergy_care", temp: "60", spin: "1600", steam: "true", soil: "normal" });
}

