import "runtime_test" as runtime;

// Tests of 2RES1VE61NFWA (GSX961MCCZ), an alias of 2RES1VE600FWC (fridge_2res600_common; upstream
// rethink commit e727324). Upstream adds no captures for it; this feeds a 2RES1VE600FWC capture.

fn sample_delta_door_open() { "AA1E10EC02030501FFFFFF0001FF01FF02030501FFFFFF0101FF01FF80BB" }

// upstream maps this model to 2RES1VE600FWC
fn test_decodes_as_2res1ve600fwc() {
    let d = device();
    d.feed(sample_delta_door_open());
    expect_props(d, #{ door: "true", fridge_setpoint: "5", freezer_setpoint: "-18", express_freeze: "false" });
}
