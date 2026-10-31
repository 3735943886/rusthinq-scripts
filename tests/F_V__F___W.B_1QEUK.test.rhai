import "runtime_test" as runtime;

// Tests of F_V__F___W.B_1QEUK (washer_v__f_common), ported from upstream rethink's test suite
// (commit 0e57069; upstream does not say whether its fixtures are captures). Expected values
// are what upstream's driver publishes for the same input, in IL names; door_lock is true while
// locked (upstream publishes it inverted, for Home Assistant's lock class).

fn sample_initial() { "AA5420EC002500000000000000000000000000000000000000010036006400000000000000000000000000002501000000000000000000000000000000000000000036006400000000000000000000000000DFBB" }
fn sample_initial_wash_1200_40c_dry_auto() { "AA5420EC00250101000100180000000000020000000000000600001000640000000000000000000000000000250104380438130003090401020000000000000400001000640000040000000000000000000053BB" }
fn sample_initial_cotton_1000_40c_turbo_wash_dry_1h() { "AA5420EC002501040C040C0100030904010400000000010002000010006400000400000000000000000000002501030603060100030704010400000100010002000010006400000400000000000000000000FCBB" }
fn sample_running_quick_400_40c() { "AA5420EC002506001300140C00030204010000000142200001010036006400000100000E00000000000000002506001300140C00030204010000000142200001010036006400000100000F00000000000000A2BB" }
fn sample_rinsing_quick_400_40c() { "AA5420EC002507000A00140C0003020001000000014200000106003600640000010000B900000000000000002507000A00140C0003020001000000014200000106003600640000010000BA00000000000000AABB" }
fn sample_spinning_quick_400_40c() { "AA5420EC002507000600140C0003020001000000014200000106003600640000010000BC00000000000000002508000500140C0000020000000000004200000107003600640000010000BC00000000000000ADBB" }
fn sample_end_quick_400_40c() { "AA5420EC002508000100140C0000020000000000004200000107003600640000010000BF0000000000000000250A000000140C0000000000000000000000000108003600640000010000BF00000000000000E5BB" }
fn sample_power_off() { "AA5420EC00250A000000140C0000000000000000000000000108003600640000010000BF00000000000000002500000000140C000000000000000000000000010A003600640000010000BF0000000000000033BB" }

// config exposes the model's components
fn test_the_descriptor_lists_the_model_features() {
    let d = device();
    d.start();
    let props = runtime::descriptor(d).props;
    expect(props.contains("power"), "power");
    expect(props.contains("start"), "start");
    expect(props.contains("pause"), "pause");
    expect(props.contains("status"), "status");
    expect(props.contains("error"), "error");
    expect(props.contains("error_message"), "error_message");
    expect(props.contains("course"), "course");
    expect(props.contains("temp"), "temp");
    expect(props.contains("spin"), "spin");
    expect(props.contains("drying_mode"), "drying_mode");
    expect(props.contains("cycles"), "cycles");
    expect(props.contains("remote_start"), "remote_start");
    expect(props.contains("door_lock"), "door_lock");
    expect(props.contains("energy"), "energy");
    expect(props.contains("initial_time"), "initial_time");
    expect(props.contains("remaining_time"), "remaining_time");
    expect(!props.contains("soil"), "no soil");
    expect(!props.contains("child_lock"), "no child_lock");
    expect(!props.contains("detergent"), "no detergent");
    expect(!props.contains("reserve_time"), "no reserve_time");
}

// initial state push decodes status, time and error state
fn test_initial() {
    let d = device();
    d.feed(sample_initial());
    expect_props(d, #{ power: "true", status: "standby", error: "false", error_message: "OK", remaining_time: "0", initial_time: "0", drying_mode: "off", cycles: "54", energy: "0", remote_start: "false", door_lock: "false" });
}

// initial (wash + dry auto) state push decodes status, course, drying mode, temp and spin
fn test_initial_wash_dry_auto() {
    let d = device();
    d.feed(sample_initial_wash_1200_40c_dry_auto());
    expect_props(d, #{ power: "true", status: "standby", course: "wash_dry", error: "false", error_message: "OK", remaining_time: "296", initial_time: "296", spin: "1200", temp: "40", drying_mode: "auto", cycles: "16", energy: "0", remote_start: "false", door_lock: "false" });
}

// initial (wash + dry 1H) state push decodes status, course, drying mode, temp and spin
fn test_initial_cotton_dry_1h() {
    let d = device();
    d.feed(sample_initial_cotton_1000_40c_turbo_wash_dry_1h());
    expect_props(d, #{ power: "true", status: "standby", course: "cotton", error: "false", error_message: "OK", remaining_time: "186", initial_time: "186", spin: "1000", temp: "40", drying_mode: "60_min", cycles: "16", energy: "0", remote_start: "false", door_lock: "false" });
}

// running state with door locked + remote_start active
fn test_running() {
    let d = device();
    d.feed(sample_running_quick_400_40c());
    expect_props(d, #{ status: "washing", course: "quick_14", spin: "400", temp: "40", drying_mode: "off", initial_time: "20", remaining_time: "19", remote_start: "true", door_lock: "true", energy: "15" });
}

// rinsing state
fn test_rinsing() {
    let d = device();
    d.feed(sample_rinsing_quick_400_40c());
    expect_props(d, #{ status: "rinsing", remaining_time: "10", energy: "186" });
}

// spinning state
fn test_spinning() {
    let d = device();
    d.feed(sample_spinning_quick_400_40c());
    expect_props(d, #{ status: "spinning", remaining_time: "5", energy: "188" });
}

// end state
fn test_end() {
    let d = device();
    d.feed(sample_end_quick_400_40c());
    expect_props(d, #{ status: "end", remaining_time: "0", door_lock: "false", remote_start: "false", energy: "191" });
}

// power-off transition (status=0)
fn test_power_off() {
    let d = device();
    d.feed(sample_power_off());
    expect_props(d, #{ power: "false", status: "off" });
}

fn last(d) { let s = d.sent(); hex_encode_upper(s[s.len() - 1]) }

// start() sends the F0ED initialisation packet
fn test_start_sends_the_status_query() {
    let d = device();
    d.start();
    expect_eq(last(d), "AA0EF0ED1121010000001800B5BB");
}

// HA write power=ON / power=OFF / pause button
fn test_power_and_pause_writes() {
    let d = device();
    d.start();
    d.set("power", "true");
    expect_eq(last(d), "AA08F02A010098BB");
    d.set("power", "false");
    expect_eq(last(d), "AA09F0240101009CBB");
    d.set("pause", "");
    expect_eq(last(d), "AA09F02404010099BB");
}

// HA write start button. Upstream sends it whatever the panel says; here it waits for remote start.
fn test_start_needs_remote_start() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("start", "");
    expect_eq(d.sent().len(), n);
    d.feed(sample_running_quick_400_40c());
    d.set("start", "");
    expect_eq(last(d), "AA09F02405010098BB");
}

// HA write to unknown property emits no packet
fn test_unknown_and_read_only_writes_are_rejected() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("does-not-exist", "whatever");
    d.set("status", "off");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "rejects are published");
}

// frames not matching the AA..BB envelope / with wrong inner length are ignored
fn test_other_frames_are_ignored() {
    let d = device();
    d.feed("001122");
    d.feed("AA08200A01020304BB");
    expect_eq(d.property("status"), ());
}

