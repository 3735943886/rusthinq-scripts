import "aabb_test" as a;

// Tests of F24D7N_KR_WIFI_V2.rhai (washer, read-only), on 25-byte records built from the layout
// in the driver header (the head of F24VDD's 34-byte record).

// Washing cotton, 1:05 left of 1:30, medium spin, 40 C, two rinses, remote start, door lock,
// turbo shot, 120 Wh, 30 cycles since the tub was cleaned, load level 2.
fn washing() {
    let p = a::payload(25, [23, 1, 5, 1, 30, 6, 0, 2, 3, 3, 2]);
    p[14] = 0x20;
    p[15] = 0x84;
    p[18] = 120;
    p[21] = 30;
    p[23] = 2;
    p
}

fn test_start_sends_the_status_request() {
    let d = device();
    d.start();
    expect_eq(a::inner_hex(d, 0), "f0ed1121010000001800");
    expect_eq(d.sent().len(), 1);
}

fn test_an_ec_record_becomes_il_properties() {
    let d = device();
    d.feed(a::status(0x20, washing()));
    expect_eq(d.script_error(), ());
    expect_props(d, #{
        available: "true", power: "true", status: "washing", course: "cotton", remaining_time: "65",
        initial_time: "90", soil: "normal", spin: "medium", temp: "40", rinse: "2", energy: "120",
        load_level: "2", tub_clean_count: "30", tub_clean_due: "true", turbo_shot: "true",
        door_lock: "true", remote_start: "true", error: "false", error_message: "No error"
    });
}

fn test_an_eb_record_is_decoded_too() {
    let d = device();
    d.feed(a::record(0x20, 0xeb, 0, washing()));
    expect_eq(d.property("status"), "washing");
}

fn test_an_unlisted_error_code_is_named_by_number() {
    let d = device();
    let p = washing();
    p[6] = 99;
    d.feed(a::status(0x20, p));
    expect_props(d, #{ error: "true", error_message: "Unknown error (99)" });
}

fn test_a_34_byte_record_is_ignored() {
    let d = device();
    d.feed(a::status(0x20, a::payload(34, [23])));
    expect_eq(d.property("status"), ());
}

fn test_dropping_the_washer_shows_it_off_and_unavailable() {
    let d = device();
    d.feed(a::status(0x20, washing()));
    d.drop_device();
    expect_props(d, #{ available: "false", power: "false", status: "off", remaining_time: "0", door_lock: "false" });
    d.start();
    expect_eq(d.property("available"), "true");
}

fn test_writes_are_rejected() {
    let d = device();
    d.set("power", "false");
    expect_eq(d.sent().len(), 0);
}
