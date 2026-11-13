import "aabb_test" as a;

// Tests of 3REK2G04VK230D_2.rhai (kimchi refrigerator), ported from the owner's
// rethink TS driver. The EB/EC status frames and the two 0x3E energy frames are
// real captures from the owner's unit (rethink frame log, 2026-11-03): the EB
// record reads raw 2/2/0/5 at [1..4], matching the official integration's live
// values that day (left/right = kimchi light, middle = kimchi medium,
// bottom = vegetable/fruit light), and each report's running total is the energy
// counter (111, then 111 + 7 = 118).

fn eb() { "aa2d11eb0202020005ff00010001db0200000000000000000000000000000000000000000000000000780160bb" }
fn ec() { "aa5411ec0202020005ff00010001db020000000000000000000000000000000000000000000000000078010202020005ff00010001dc0200000000000000000000000000000000000000000000000000780195bb" }

fn test_start_sends_the_family_query() {
    let d = device();
    d.start();
    expect_eq(a::inner_hex(d, 0), "f0ed1211010000010400");
    expect_eq(d.script_error(), ());
}

// Device frames other than status records are acknowledged ahead of decoding (c::ack), as the
// other AABB drivers do; without it the appliance repeated each notification ~10 times
// (seen live 2026-11-05). aa0711190288bb is a real frame of this class; the ACK is the captured reply.
fn test_device_frames_are_acknowledged() {
    let d = device();
    d.feed("aa0711190288bb");
    let clips = d.clips();
    expect_eq(clips.len(), 1);
    expect_eq(clips[0].cmd, "ack");
    expect_eq(clips[0].data, "AA08F0001904EABB");
    expect_eq(d.script_error(), ());
}

fn test_the_live_eb_becomes_il_properties() {
    let d = device();
    d.feed(eb());
    expect_props(d, #{
        available: "true",
        left_compartment: "맛지킴 김치 (약)",
        right_compartment: "맛지킴 김치 (약)",
        middle_compartment: "맛지킴 김치 (중)",
        bottom_compartment: "야채·과일 (약)",
        one_touch_filter: "false",
        door: "false"
    });
    expect_eq(d.script_error(), ());
}

fn test_the_live_ec_publishes_the_current_record() {
    let d = device();
    d.feed(ec());
    // In this capture the two records differ only at [10] (outside the decoded
    // head), so the published values match the EB's.
    expect_props(d, #{
        left_compartment: "맛지킴 김치 (약)",
        right_compartment: "맛지킴 김치 (약)",
        middle_compartment: "맛지킴 김치 (중)",
        bottom_compartment: "야채·과일 (약)"
    });
    expect_eq(d.script_error(), ());
}

fn test_a_constructed_ec_uses_the_second_record() {
    let d = device();
    // Constructed: first record all mode 0 / filter off / door closed; second
    // record left 6 (냉동), middle 13 (꺼짐), filter on, door open.
    let r1 = "0200000000ff000000000000000000000000000000000000000000000000000000000000000000";
    let r2 = "0206000d00ff010001000000000000000000000000000000000000000000000000000000000000";
    d.feed(a::framed(hex_decode("11ec" + r1 + r2)));
    expect_props(d, #{
        left_compartment: "냉동",
        middle_compartment: "꺼짐",
        one_touch_filter: "true",
        door: "true"
    });
    expect_eq(d.script_error(), ());
}

fn test_energy_is_the_running_total() {
    let d = device();
    d.start();
    expect_eq(d.timers().len(), 0);
    d.feed("aa0b113e0004006f21cdbb"); // delta 4, total 111, tick 0x21
    expect_eq(d.property("energy"), "111");
    d.feed("aa0b113e0004006f21cdbb"); // retransmission: same total
    expect_eq(d.property("energy"), "111");
    d.feed("aa0b113e0007007622f6bb"); // delta 7, total 118 (= 111 + 7), tick 0x22
    expect_eq(d.property("energy"), "118");
    expect_eq(d.property("energy_hour"), ());
    expect_eq(d.script_error(), ());
}

fn test_a_compartment_write_is_the_single_field_frame() {
    let d = device();
    d.set("left_compartment", "냉동");
    // header + <index 1> 00 <code 6>
    expect_eq(a::inner_hex(d, 0), "f0e5000201ff0100010006");
    expect_eq(d.sent().len(), 1);
}

fn test_a_duplicate_label_encodes_to_the_lowest_code() {
    let d = device();
    // '맛지킴 김치 (약)' exists at codes 2 and 21; the TS driver encodes 2.
    d.set("left_compartment", "맛지킴 김치 (약)");
    expect_eq(a::inner_hex(d, 0), "f0e5000201ff0100010002");
}

fn test_a_middle_compartment_write() {
    let d = device();
    d.set("middle_compartment", "꺼짐");
    expect_eq(a::inner_hex(d, 0), "f0e5000201ff010003000d");
}

fn test_the_deodorize_write() {
    let d = device();
    d.set("one_touch_filter", "true");
    expect_eq(a::inner_hex(d, 0), "f0e5000201ff0100060001");
    d.set("one_touch_filter", "false");
    expect_eq(a::inner_hex(d, 1), "f0e5000201ff0100060000");
}

fn test_an_unknown_mode_is_rejected() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("left_compartment", "없는 모드");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "a reject event is published");
}

fn test_writes_do_not_publish_optimistically() {
    let d = device();
    d.feed(eb());
    d.set("left_compartment", "냉동");
    // Still the wire value until the 11 EC push arrives (the TS driver's rule).
    expect_eq(d.property("left_compartment"), "맛지킴 김치 (약)");
}
