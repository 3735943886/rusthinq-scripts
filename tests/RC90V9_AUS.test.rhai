import "runtime_test" as runtime;

// Tests of RC90V9_AUS (DVH9-09B), an alias of RC90U2_WW (dryer_rc90_common; upstream rethink
// commit 7300491). Upstream adds no captures for it; this feeds an RC90U2_WW capture.

fn course_duvet() { "AA3C30EC001901010A00000600030302000000000804000000000000006B00001901023700000400000302000000000804000000000000006B002ABB" }

// upstream maps this model to RC90U2_WW
fn test_decodes_as_rc90u2() {
    let d = device();
    d.feed(course_duvet());
    expect_props(d, #{ course: "duvet", dry_level: "none", eco_hybrid: "time", remaining_time: "175" });
}
