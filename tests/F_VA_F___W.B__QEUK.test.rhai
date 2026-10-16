import "runtime_test" as runtime;

// Tests of F_VA_F___W.B__QEUK, an alias of F_V__F___W.B_1QEUK, ported from upstream rethink's
// test suite (commit 0e57069; F_V__F captures). Expected values are what upstream's driver
// publishes for the same input, in IL names; door_lock is true while locked (upstream publishes
// it inverted, for Home Assistant's lock class).

fn sample_initial_wash_1200_40c_dry_auto() { "AA5420EC00250101000100180000000000020000000000000600001000640000000000000000000000000000250104380438130003090401020000000000000400001000640000040000000000000000000053BB" }

// upstream maps this model to F_V__F___W.B_1QEUK
fn test_decodes_as_f_v__f() {
    let d = device();
    d.feed(sample_initial_wash_1200_40c_dry_auto());
    expect_props(d, #{ course: "wash_dry", spin: "1200", temp: "40", drying_mode: "auto", cycles: "16" });
}

