import "runtime_test" as runtime;

// Tests of D2211, an alias of D0211 (dishwasher_d0211_common; upstream rethink commit 7300491).
// Upstream adds no captures for it; this feeds a D0211 capture.

fn running_intensive_no_options() { "AA3A32EC001801000003050200030500007200020401000000000000000000180202000305020003050000700002040100000000000000001EBB" }

// upstream maps this model to D0211
fn test_decodes_as_d0211() {
    let d = device();
    d.feed(running_intensive_no_options());
    expect_props(d, #{ initial_time: "185", remaining_time: "185", status: "running", process: "washing", course: "intensive", door: "false" });
}
