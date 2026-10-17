import "runtime_test" as runtime;

// Tests of RC90V9_WW (RC91V9EV2Q), which upstream rethink maps to the RC90U2_WW handler
// (dryer_rc90_common), ported from its test suite (commit 0e57069; live captures over a Cotton /
// Extra / Eco cycle).

fn quick_30() { "AA3C30EC001901021400000200000302000000000804000000000000006B00001901001E00000900000302000000000804000000000000006B0038BB" }
fn drying() { "AA3C30EC0019020224030007000401020000000000050000AD0100000071000019020224030007000401030000000000050000AE010000007100A5BB" }
fn cooling() { "AA3C30EC00190200030300070004010400000000000500043F010000007100001902000203000700040105000000002005000444010000007100A8BB" }
fn end_() { "AA3C30EC00190200010300070004010500000000200500044801000000710000190400010300070004010700000000000400044902000000710058BB" }
fn child_lock() { "AA3C30EC001901000000000000000000000000000004000000000000007100001901000000000000000000000000001004700000000000007100F5BB" }

// decodes the knob, a full cycle and the child lock
fn test_the_knob_a_full_cycle_and_the_child_lock() {
    let d = device();
    d.feed(quick_30()); expect_props(d, #{ status: "ready", course: "quick_dry", remaining_time: "30" });
    d.feed(drying());
    expect_props(d, #{ status: "running", phase: "drying", course: "cotton", dry_level: "extra", remaining_time: "156" });
    d.feed(cooling()); expect_props(d, #{ phase: "cooling", remaining_time: "2" });
    d.feed(end_()); expect_eq(d.property("status"), "end");
    d.feed(child_lock()); expect_eq(d.property("child_lock"), "true");
}
