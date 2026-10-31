import "runtime_test" as runtime;

// Tests of Y_V8_F___W.B_2QEUK, ported from upstream rethink's test suite (commit 0e57069;
// captures from a W4WR70E61). Expected values and writes are what upstream's driver publishes
// and sends for the same input, in IL names; door_lock and child_lock are true while locked
// (upstream publishes them inverted, for Home Assistant's lock class).

fn sample_armed_ready() { "AAFF200A0060007F7F000100EC004E000001040A040A1300030A03010200000042000004000010000000000400000000000000000000000001040A040A1300030A0301020000004200000400001000000000040000000000000000C0007A96BB" }
fn sample_rinsing() { "AAFF200A006000823E000100EC004E000006022803131300030A03010200000042200001040010000000000400009800000000000000000007022703131300030A000102000000420000010600100000000004000098000000000000001066BB" }
fn sample_drying() { "AAFF200A0060008A6A000100EC004E000009011D031D130000000000020000004200000104001000000000040003E800000000000000000009011D031D130000000000020000004200000104001000000000040003E9000000000000005A45BB" }
fn sample_off() { "AAFF200A0060009437000100EC004E00000B0000031D13000000000002000000400000020A00100000000004000872000000000000000000000000031D13000000000000000000400000040B00100000000004000872000000000000008FEABB" }
fn sample_config() { "AAFF200A005300C807000201030018120A0102120134000807001D00000000000000000000000001050025595F56385F465F5F5F572E425F325145554B00000102D51CED6F0104000000000000000000B596BB" }

fn last(d) { let s = d.sent(); hex_encode_upper(s[s.len() - 1]) }

// config exposes the drying mode and energy sensors
fn test_the_descriptor_lists_drying_mode_energy_and_cycles() {
    let d = device();
    d.start();
    let props = runtime::descriptor(d).props;
    for p in ["drying_mode", "energy", "cycles"] { expect(props.contains(p), p); }
}

// armed ready state decodes course, spin, temp, drying mode and remote start
fn test_armed_ready() {
    let d = device();
    d.feed(sample_armed_ready());
    expect_props(d, #{ power: "true", status: "standby", course: "wash_dry", spin: "1400", temp: "30", drying_mode: "auto", remote_start: "true", door_lock: "false", initial_time: "250", remaining_time: "250", energy: "0" });
}

// rinse phase decodes remaining time and the running energy counter
fn test_rinsing() {
    let d = device();
    d.feed(sample_rinsing());
    expect_props(d, #{ status: "rinsing", course: "wash_dry", remaining_time: "159", initial_time: "199", energy: "152" });
}

// drying phase decodes status=Drying with the energy counter advancing
fn test_drying() {
    let d = device();
    d.feed(sample_drying());
    expect_props(d, #{ status: "drying", drying_mode: "auto", remaining_time: "89", energy: "1001" });
}

// powered-off frame decodes power=OFF and the final cycle energy
fn test_off() {
    let d = device();
    d.feed(sample_off());
    expect_props(d, #{ power: "false", status: "off", energy: "2162" });
}

// configuration frame decodes the wash cycle counter
fn test_config() {
    let d = device();
    d.feed(sample_config());
    expect_props(d, #{ cycles: "52" });
}

// start() sends the F0ED initialisation packet; HA write power=ON / power=OFF / pause button
fn test_query_power_and_pause() {
    let d = device();
    d.start();
    expect_eq(last(d), "AA0EF0ED1121010000001800B5BB");
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
    d.feed(sample_armed_ready());
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
