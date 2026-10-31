import "runtime_test" as runtime;

// Tests of F_V__Y___W.B__QEUK, an alias of F_V8_Y___W.B_2QEUK (upstream rethink commit 7300491).
// Upstream adds no captures for it; this feeds an F_V8_Y capture.

fn sample_allergy_steam() { "AA5420EC002501021C021C0900030504010000000000000002000001006400000500000000000000000000002501023002302D00030B06010000008000000003000001006400000500000000000000000000F2BB" }

// upstream maps this model to F_V8_Y___W.B_2QEUK
fn test_decodes_as_f_v8_y() {
    let d = device();
    d.feed(sample_allergy_steam());
    expect_props(d, #{ course: "allergy_care", temp: "60", spin: "1600", steam: "true", soil: "normal" });
}
