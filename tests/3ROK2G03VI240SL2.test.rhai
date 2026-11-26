import "runtime_test" as runtime;
import "aabb_test" as a;

// Tests of 3ROK2G03VI240SL2 (kimchi refrigerator, three compartments) on kimchi_3rek_common.
// Both EC frames are real captures from one unit (2026-11-25, rusthinqctl capture) taken as a
// door was opened and closed; the LG cloud showed left 맛지킴 김치 (강), middle 야채·과일 (강)
// and bottom 야채·과일 (중) at the time. [2] (right) is 0 on this unit and is not published.

fn ec_open() { "AA5411EC0201000403FF0001000123030000000000000000000000000000000000000000000000000078010201000403FF00010101230300000000000000000000000000000000000000000000000000780105BB" }
fn ec_close() { "AA5411EC0201000403FF0001010123030000000000000000000000000000000000000000000000000078010201000403FF00010001230300000000000000000000000000000000000000000000000000780105BB" }

fn test_start_sends_the_family_query() {
    let d = device();
    d.start();
    expect_eq(a::inner_hex(d, 0), "f0ed1211010000010400");
    expect_eq(d.script_error(), ());
}

fn test_the_captured_ec_becomes_il_properties() {
    let d = device();
    d.feed(ec_open());
    expect_props(d, #{
        available: "true",
        left_compartment: "맛지킴 김치 (강)",
        middle_compartment: "야채·과일 (강)",
        bottom_compartment: "야채·과일 (중)",
        one_touch_filter: "false",
        door: "true"
    });
    d.feed(ec_close());
    expect_eq(d.property("door"), "false");
    expect_eq(d.property("right_compartment"), ());
    expect_eq(d.script_error(), ());
}

fn test_three_compartments_and_read_only() {
    let d = device();
    d.start();
    let props = runtime::descriptor(d).props;
    expect_eq(props.right_compartment, ());
    expect_eq(props.left_compartment.rw, false);
    expect_eq(props.one_touch_filter.rw, false);
    let sent = d.sent().len();
    d.set("left_compartment", "냉장 (중)");
    d.set("one_touch_filter", "true");
    expect_eq(d.sent().len(), sent);
    expect(d.event("reject") != (), "a reject event is published");
    expect_eq(d.script_error(), ());
}
