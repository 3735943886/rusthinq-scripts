import "runtime_test" as runtime;

// Tests of IV12SNNWW (LG robot vacuum, JSON ThinQ2). NO live capture exists yet:
// both frames below are CONSTRUCTED from the model's official model JSON
// (Monitoring paths + Value enums), in the two payload shapes on_data accepts.
// They pin the driver's decoding of its own spec; the first real capture must
// replace them (see the driver header).
//
// sample_flat:
//   {"ROBOT_STATE":"WORKING","EMERGENCY":"NONE","BATT_P":87,"MODE":"ZZ",
//    "SUCTION_LEVEL":"STRONG","WATERSUPPLY_LEVEL":"LOW1","VOLUME_LEVEL":"MEDIUM",
//    "CLEAN_TIME":12,"SMART_TURBO":false,"MAINT_FILTER":42,"RT_POSE":{"x":1,"y":2}}
fn sample_flat() { "7b22524f424f545f5354415445223a22574f524b494e47222c22454d455247454e4359223a224e4f4e45222c22424154545f50223a38372c224d4f4445223a225a5a222c2253554354494f4e5f4c4556454c223a225354524f4e47222c225741544552535550504c595f4c4556454c223a224c4f5731222c22564f4c554d455f4c4556454c223a224d454449554d222c22434c45414e5f54494d45223a31322c22534d4152545f545552424f223a66616c73652c224d41494e545f46494c544552223a34322c2252545f504f5345223a7b2278223a312c2279223a327d7d" }

// sample_nested:
//   {"ROBOT_STATE":{"ROBOT_STATE":"CHARGING","EMERGENCY":"E_BATTERY_LOW"},"BATT_P":"55"}
fn sample_nested() { "7b22524f424f545f5354415445223a7b22524f424f545f5354415445223a224348415247494e47222c22454d455247454e4359223a22455f424154544552595f4c4f57227d2c22424154545f50223a223535227d" }

fn test_the_descriptor_lists_the_vacuum_properties() {
    let d = device();
    d.start();
    let props = runtime::descriptor(d).props;
    for p in ["state", "state_raw", "error", "error_code", "battery", "clean_mode",
              "suction", "water_supply", "volume", "smart_turbo", "clean_time",
              "maint_filter", "rt_map", "rt_pose", "floor_map"] {
        expect(props.contains(p), p);
    }
    expect(props.state.options.contains("cleaning"), "cleaning");
    expect(props.state.options.contains("charging"), "charging");
    expect(props.water_supply.options.contains("middle"), "middle");
    // Writes are disarmed in this build: no control properties are published.
    expect(!props.contains("clean_start"), "no clean_start while disarmed");
    expect(props.clean_mode.rw != true, "clean_mode read-only while disarmed");
}

fn test_flat_state_report() {
    let d = device();
    d.feed(sample_flat());
    expect_props(d, #{ state: "cleaning", state_raw: "WORKING", error: "false",
                       error_code: "NONE", battery: "87", clean_mode: "zigzag",
                       suction: "strong", water_supply: "middle", volume: "medium",
                       clean_time: "12", smart_turbo: "false", maint_filter: "42",
                       rt_pose: "{\"x\":1,\"y\":2}" });
}

fn test_nested_state_report_with_error() {
    let d = device();
    d.feed(sample_nested());
    expect_props(d, #{ state: "charging", state_raw: "CHARGING", error: "true",
                       error_code: "E_BATTERY_LOW", battery: "55" });
}

fn test_a_write_is_rejected_while_disarmed_and_nothing_is_sent() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("clean_mode", "zigzag");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "reject event");
}

fn test_unrelated_payload_is_ignored() {
    let d = device();
    // {"ack":"ok"} as hex: no ROBOT_STATE, so nothing may be published.
    d.feed("7b2261636b223a226f6b227d");
    expect(d.published("rusthinq/test-device/state") == (), "no state");
}
