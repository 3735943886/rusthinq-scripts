import "runtime_test" as runtime;

// Tests of WTDN3 (washer_t1_common), ported from upstream rethink's test suite (commit 0e57069;
// samples based on anszom/rethink#16). Expected values are what upstream's driver publishes for
// the same input, in IL names: door_lock is true while locked (upstream publishes it inverted,
// for Home Assistant's lock class), and byte 21 is tub_clean_count (upstream's "cycles"; the
// issue decodes it as the tub clean count, which WTWN3 confirmed).

fn sample_off() { "00000000000000000000000000000000000000000006006400000000" }
fn sample_ready_cotton_1200_40c() { "01030403040100030904010000000000000003000006006400000400" }
fn sample_wash_cotton_1200_40c_remain_1h20() { "06011401140100030904010000000040000001040006006400000400" }
fn sample_fast30_running() { "06001e001e2200030502010000000040000001010006006400000200" }
fn sample_custom_reducing_wrinkles() { "01030003000100030904010000000242000003006f08006f00000400" }
fn sample_error_de1() { "12030403040102030904010000000000000003010008006400000400" }
fn sample_remote_start_on() { "01010e010e0000000000000000000042000003000007006400000000" }

// The body of the n-th ThinQ1 command sent, without the host's CmdWId.
fn sent(d, n) { let body = d.clips()[n].Body; body.remove("CmdWId"); body }

// config exposes expected components
fn test_the_descriptor_lists_the_washer_dryer_properties() {
    let d = device_t1();
    d.start();
    let props = runtime::descriptor(d).props;
    for p in ["power", "start", "pause", "status", "error", "error_message", "course", "temp", "spin",
              "drying_mode", "tub_clean_count", "remote_start", "door_lock", "initial_time",
              "remaining_time"] {
        expect(props.contains(p), p);
    }
    // Status options are the supported states, without the unassigned codes.
    expect(props.status.options.contains("washing"), "washing");
    expect(props.status.options.contains("error"), "error");
    expect(!props.contains("child_lock"), "no child_lock");
}

// OFF state push publishes power=OFF and "Off" status
fn test_off() {
    let d = device_t1();
    d.feed(sample_off());
    expect_props(d, #{ power: "false", status: "off", error: "false", error_message: "OK",
                       tub_clean_count: "6", initial_time: "0", remaining_time: "0" });
}

// READY+COTTON@1200/40C state push decodes course/spin/temperature
fn test_ready_cotton_1200_40c() {
    let d = device_t1();
    d.feed(sample_ready_cotton_1200_40c());
    expect_props(d, #{ power: "true", status: "standby", course: "cotton", spin: "1200", temp: "40",
                       initial_time: "184", remaining_time: "184", error: "false", drying_mode: "off" });
}

// WASH state with door lock active publishes door_lock=OFF
fn test_washing_locks_the_door() {
    let d = device_t1();
    d.feed(sample_wash_cotton_1200_40c_remain_1h20());
    expect_props(d, #{ status: "washing", remaining_time: "80", door_lock: "true", remote_start: "false" });
}

// Fast 30 running publishes the right course and remaining time
fn test_fast_30_running() {
    let d = device_t1();
    d.feed(sample_fast30_running());
    expect_props(d, #{ status: "washing", course: "quick_30", spin: "800", temp: "20",
                       initial_time: "30", remaining_time: "30" });
}

// Custom course overrides the native course when CC is non-zero
fn test_a_downloaded_course_overrides_the_base_course() {
    let d = device_t1();
    d.feed(sample_custom_reducing_wrinkles());
    expect_props(d, #{ course: "reducing_wrinkles" });
}

// Error state publishes error binary + descriptive message
fn test_error_de1() {
    let d = device_t1();
    d.feed(sample_error_de1());
    expect_props(d, #{ status: "error", error: "true", error_message: "Door open error (DE1)" });
}

// Remote-start flag publishes remote_start=ON
fn test_remote_start() {
    let d = device_t1();
    d.feed(sample_remote_start_on());
    expect_props(d, #{ remote_start: "true", door_lock: "true" });
}

// Frames of unexpected length are ignored
fn test_other_lengths_are_ignored() {
    let d = device_t1();
    d.feed("AABBCC");
    expect_eq(d.property("power"), ());
    expect_eq(d.property("available"), ());
}

// start() sends a Mon/Start subscription on the wire
fn test_start_subscribes_to_status() {
    let d = device_t1();
    d.start();
    expect_eq(d.clips().len(), 1);
    expect_eq(sent(d, 0), #{ Cmd: "Mon", CmdOpt: "Start" });
    expect_eq(d.clips()[0].Header["x-lgedm-deviceId"], "test-device");
    expect(d.clips()[0].Body.CmdWId.starts_with("n-"), "CmdWId");
}

// HA write power=ON sends Control/Power/On envelope
fn test_power_on() {
    let d = device_t1();
    d.start();
    d.set("power", "true");
    expect_eq(sent(d, 1), #{ Cmd: "Control", CmdOpt: "Power", Value: "On", Format: "B64", Data: "" });
}

// HA write power=OFF sends Control/Power/Off envelope
fn test_power_off() {
    let d = device_t1();
    d.start();
    d.set("power", "false");
    expect_eq(sent(d, 1), #{ Cmd: "Control", CmdOpt: "Power", Value: "Off", Format: "B64", Data: "" });
}

// HA write pause sends Control/Operation/Stop envelope
fn test_pause() {
    let d = device_t1();
    d.start();
    d.set("pause", "");
    expect_eq(sent(d, 1), #{ Cmd: "Control", CmdOpt: "Operation", Value: "Stop", Format: "B64", Data: "" });
}

// (upstream has no test for the start payload) start sends Control/Operation/Start, empty Data
fn test_start() {
    let d = device_t1();
    d.start();
    d.set("start", "");
    expect_eq(sent(d, 1), #{ Cmd: "Control", CmdOpt: "Operation", Value: "Start", Format: "B64", Data: "" });
}

// A read-only or unknown property is rejected and sends nothing
fn test_unknown_and_read_only_writes_are_rejected() {
    let d = device_t1();
    d.start();
    for prop in ["status", "nonsense"] {
        let n = d.clips().len();
        d.set(prop, "x");
        expect_eq(d.clips().len(), n, prop);
        expect(d.event("reject") != (), prop);
    }
}
