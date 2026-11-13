import "aabb_test" as a;
import "runtime_test" as runtime;

// Tests of 3REK2G03VI200S_2.rhai (kimchi refrigerator), ported from kshexe/rethink's
// tests/cloud/devices/3REK2G03VI200S_2.test.ts (commit 8fa8bd4). Every frame is a real capture
// from the fork's unit (2026-09-10..15); the writes are the fork's captured frames.

fn ack() { "aa071100e5f2bb" }
fn id_block() {
    "aa371131020153414134323237363330310000388a000040000003c00002534141343234343534303100005330000040000003c0001bbb"
}
fn baseline() { "aa1011eb0206ff0000ff00010001ebbb" }
fn top_door_open() { "aa1a11ec0206ff0000ff000100010206ff0000ff0000010184bb" }
fn top_door_close() { "aa1a11ec0206ff0000ff000001010206ff0000ff0001000184bb" }
fn middle_door_open() { "aa1a11ec0206ff0000ff000100010206ff0000ff0001010187bb" }
fn top_to_probiotic() { "aa1a11ec0206ff0000ff00000101020aff0000ff0000010180bb" }
fn echo_middle_to_strong() { "aa1811e6000201ff010003000206ff0000ff0001000192bb" }
fn middle_to_strong() { "aa1a11ec0206ff0000ff000100010206ff0100ff0001000187bb" }
fn bottom_to_meat_fish() { "aa1a11ec0206ff0100ff000100010206ff0107ff000100018fbb" }
fn one_touch_on() { "aa1a11ec0206ff0000ff000100010206ff0000ff0101000187bb" }
fn top_off() { "aa1a11ec0209ff0000ff010001010209ff0000ff0001000182bb" }
fn middle_bottom_off() { "aa1a11ec0206ff0d09ff000001010206ff0d09ff00010001a8bb" }
fn middle_vegi_medium() { "aa1a11ec0203ff0106ff000001010203ff0306ff000001018ebb" }
fn middle_vegi_weak() { "aa1a11ec0203ff0406ff000001010203ff0506ff00000101b5bb" }
fn energy_246() { "aa0b113e001000f60e4dbb" }
fn energy_262() { "aa0b113e001001060f7fbb" }
fn door_is_open() { "aa13117200170a0000000000000000000034bb" }

fn test_the_descriptor() {
    let d = device();
    d.start();
    let desc = runtime::descriptor(d);
    expect_eq(desc.kind, "fridge");
    expect_eq(desc.props.middle_compartment.options.len(), 10);
    expect_eq(desc.props.door.class, "door");
    expect_eq(d.script_error(), ());
}

// "start() sends the query frame once, byte for byte, and never again"
fn test_start_queries_once() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 1);
    expect_eq(hex_encode(d.sent()[0]), "aa0ef0ed1211010000010400ebbb");
    expect_eq(d.timers().len(), 0); // no re-query
}

// "the query response publishes the real baseline reading"
fn test_the_baseline() {
    let d = device();
    d.feed(baseline());
    expect_props(d, #{
        available: "true",
        top_compartment: "냉동",
        middle_compartment: "맛지킴 김치 (중)",
        bottom_compartment: "맛지킴 김치 (중)",
        one_touch_deodorize: "false",
        top_door: "false",
        door: "false"
    });
}

// "the ack frame ..." / "the identification block is recognised by shape and silently dropped"
fn test_ack_and_id_block_publish_nothing() {
    let d = device();
    d.feed(ack());
    d.feed(id_block());
    expect_eq(d.property("top_compartment"), ());
    expect_eq(d.script_error(), ());
}

// "상칸 (top) door open/close moves both its own flag and the aggregate; 중칸 only the aggregate"
fn test_doors() {
    let d = device();
    d.feed(top_door_open());
    expect_props(d, #{ top_door: "true", door: "true" });
    d.feed(top_door_close());
    expect_props(d, #{ top_door: "false", door: "false" });
    d.feed(middle_door_open());
    expect_props(d, #{ top_door: "false", door: "true" });
}

// The panel-side change, the three off codes and the vegetable levels.
fn test_modes() {
    let d = device();
    d.feed(top_to_probiotic());
    expect_eq(d.property("top_compartment"), "유산균 김치+");
    d.feed(top_off());
    expect_eq(d.property("top_compartment"), "꺼짐");
    d.feed(middle_bottom_off());
    expect_props(d, #{ middle_compartment: "꺼짐", bottom_compartment: "꺼짐", top_compartment: "냉동" });
    d.feed(middle_vegi_medium());
    expect_eq(d.property("middle_compartment"), "야채·과일 (중)");
    d.feed(middle_vegi_weak());
    expect_eq(d.property("middle_compartment"), "야채·과일 (약)");
}

fn test_an_unknown_mode_is_absent() {
    let d = device();
    d.feed(baseline());
    let b = aabb_unwrap(hex_decode(baseline()));
    b[2 + 1] = 0x08;
    d.feed(a::framed(b));
    expect_eq(d.property("top_compartment"), "");
    expect_eq(d.property("middle_compartment"), "맛지킴 김치 (중)");
}

// "중칸 write reproduces the real frame byte for byte, ... then confirmed by the real state push"
fn test_middle_write() {
    let d = device();
    d.feed(baseline());
    d.set("middle_compartment", "맛지킴 김치 (강)");
    expect_eq(hex_encode(d.sent()[0]), "aa0ff0e5000201ff0100030001c0bb");
    expect_eq(d.property("middle_compartment"), "맛지킴 김치 (중)"); // not optimistic
    // "the write echo (e6) is ... silently dropped"
    d.feed(echo_middle_to_strong());
    expect_eq(d.property("middle_compartment"), "맛지킴 김치 (중)");
    d.feed(middle_to_strong());
    expect_eq(d.property("middle_compartment"), "맛지킴 김치 (강)");
}

// "하칸 write reproduces the real frame byte for byte"
fn test_bottom_write() {
    let d = device();
    d.set("bottom_compartment", "육류/생선");
    expect_eq(hex_encode(d.sent()[0]), "aa0ff0e5000201ff0100040007c9bb");
    d.feed(bottom_to_meat_fish());
    expect_eq(d.property("bottom_compartment"), "육류/생선");
}

// "원터치 탈취 write reproduces the real frame byte for byte, and the resulting state is applied"
fn test_one_touch_write() {
    let d = device();
    d.set("one_touch_deodorize", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa0ff0e5000201ff0100060001cdbb");
    d.feed(one_touch_on());
    expect_eq(d.property("one_touch_deodorize"), "true");
    d.set("top_compartment", "냉동");
    expect_eq(a::inner_hex(d, 1), "f0e5000201ff0100010006");
}

// "an unknown mode label logs a warning and sends nothing"
fn test_an_unknown_label_is_rejected() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("bottom_compartment", "냉동");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "rejected");
}

// The fork feeds only its calendar buckets from the report (not ported); its running total is
// the HA-style energy counter here, rising by each delta (246 + 16 = 262).
fn test_energy() {
    let d = device();
    d.start();
    expect_eq(runtime::descriptor(d).props.energy.series, "counter");
    d.feed(energy_246());
    expect_eq(d.property("energy"), "246");
    d.feed(energy_262());
    expect_eq(d.property("energy"), "262");
    expect_eq(d.property("energy_hour"), ());
}

// "a real notification-channel frame publishes door_is_open"
fn test_door_is_open_notification() {
    let d = device();
    d.feed(door_is_open());
    expect_eq(json_parse(d.event("notification")).event_type, "door_is_open");
}

fn test_reconnect_publishes_no_defaults() {
    let d = device();
    d.start();
    d.feed(baseline());
    d.drop_device();
    d.start();
    expect_eq(d.property("top_compartment"), "냉동");
    expect_eq(d.property("energy_hour"), ());
}
