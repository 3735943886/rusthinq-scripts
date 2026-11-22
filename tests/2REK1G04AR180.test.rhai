import "aabb_test" as a;

// Tests of 2REK1G04AR180.rhai (kimchi refrigerator, read-only). The status record is the one the
// contributor quoted from their unit (11 eb 02 06 02 00 09 ff 00 01 01); the door event and the
// 11 cf frame are built from the layout described in the driver header.

fn test_start_sends_the_family_query() {
    let d = device();
    d.start();
    expect_eq(a::inner_hex(d, 0), "f0ed1211010000010400");
    expect_eq(d.script_error(), ());
}

fn test_the_9_byte_record_becomes_il_properties() {
    let d = device();
    d.feed(a::framed(hex_decode("11eb0206020009ff000101")));
    expect_eq(d.script_error(), ());
    expect_props(d, #{
        available: "true", left_compartment: "냉동", right_compartment: "맛지킴 김치 (약)",
        middle_compartment: "맛지킴 김치 (중)", bottom_compartment: "꺼짐", one_touch_filter: "false",
        door: "false", door_left: "false", door_right: "false",
        door_drawer_upper: "false", door_drawer_lower: "false"
    });
}

fn test_r8_zero_means_a_door_is_open() {
    let d = device();
    d.feed(a::framed(hex_decode("11eb0206020009ff000100")));
    expect_eq(d.property("door"), "true");
}

fn test_per_door_events() {
    let d = device();
    d.feed(a::framed(hex_decode("11a80401")));
    expect_eq(d.property("door_drawer_lower"), "true");
    d.feed(a::framed(hex_decode("11a80101")));
    expect_eq(d.property("door_left"), "true");
    d.feed(a::framed(hex_decode("11a80400")));
    expect_eq(d.property("door_drawer_lower"), "false");
    expect_eq(d.script_error(), ());
}

// The 6th signed 16-bit LE value after the aa aa aa ee 5d marker, in 0.1 °C.
fn test_the_cf_frame_gives_the_room_temperature_estimate() {
    let d = device();
    d.feed(a::framed(hex_decode("11cf0000aaaaaaee5d01000200030004000500cb000000000000")));
    expect_eq(d.script_error(), ());
    expect_eq(d.property("room_temperature"), "20.3");
}

fn test_writes_are_rejected() {
    let d = device();
    d.set("left_compartment", "냉동");
    expect_eq(d.sent().len(), 0);
    expect(d.event("reject") != (), "a reject event was published");
}
