import "runtime_test" as runtime;

// Tests of F_VB_F___W.B_2QEUK (washer_common), ported from upstream rethink's test suite
// (commit 0e57069; upstream does not say whether its fixtures are captures). Expected values
// are what upstream's driver publishes for the same input, in IL names; door_lock is true while
// locked (upstream publishes it inverted, for Home Assistant's lock class).

fn sample_initial() { "AA5420EC002500050F050F130000000000000000000000000401000A0064000004000CBD02022A1E00030100250100000000000000000000000000000000000000000A006400000000000002022A1E0040014EBB" }
fn sample_child_lock() { "AA5420EC00250100000000000000000000000000000000000000000A006400000000000002022A1E00030100250100000000000000000000000000008000000000000A006400000000000002022A1E00030107BB" }
fn sample_combo_options() { "AA5420EC00250104010401010003070402000000410001000200000A006400000500000000022A1E00020100250104010401010003070402000000410001000200000A006400000500000000032A1E000201C0BB" }
fn sample_delay_end() { "AA5420EC00250104010401010003070402000000410001000200000A006400000500000000032A1E00020100250104010401010003070402000300410001000200000A006400000500000000032A1E000201CCBB" }
fn sample_power_off() { "AA5420EC00250004010401010000000000000000000001000201000A006400000500000000032A1E00020100250004010401010000000000000000000001000201000A006400000500000000032A1E00420161BB" }
fn sample_running() { "AA5420EC002504050F050F1300030A0401020000004220000101000A006400000400000002022A1E000301002506021902191300030A0401020000004220000104000A006400000400000002022A1E0003010CBB" }
fn sample_drying() { "AA5420EC00250100370037180000000000020000000000000600000B006400000000002D00002A1E00000100250900370037180000000000020000000220000101000B006400000000002D00002A1E004001F7BB" }

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
    expect(props.contains("child_lock"), "child_lock");
    expect(props.contains("energy"), "energy");
    expect(props.contains("initial_time"), "initial_time");
    expect(props.contains("remaining_time"), "remaining_time");
    expect(props.contains("reserve_time"), "reserve_time");
    expect(props.contains("detergent"), "detergent");
    expect(props.contains("softener"), "softener");
    expect(props.contains("extra_rinse"), "extra_rinse");
    expect(props.contains("turbo_wash"), "turbo_wash");
    expect(props.contains("eco_hybrid"), "eco_hybrid");
    expect(props.contains("pre_wash"), "pre_wash");
    expect(props.contains("steam"), "steam");
    expect(!props.contains("soil"), "no soil");
}

// initial state push decodes power, status, lock and error state
fn test_initial() {
    let d = device();
    d.feed(sample_initial());
    expect_props(d, #{ power: "true", status: "ready", error: "false", error_message: "OK", drying_mode: "off", reserve_time: "0", extra_rinse: "false", turbo_wash: "false", eco_hybrid: "false", pre_wash: "false", steam: "false", cycles: "10", energy: "0", initial_time: "0", remaining_time: "0", remote_start: "false", door_lock: "false", child_lock: "false" });
}

// child lock engaged frame decodes child_lock=ON, polarity is non-inverted
fn test_child_lock() {
    let d = device();
    d.feed(sample_child_lock());
    expect_props(d, #{ child_lock: "true", door_lock: "false", remote_start: "false" });
}

// combo-options frame decodes extra_rinse, turbowash, prewash, detergent, softener
fn test_combo_options() {
    let d = device();
    d.feed(sample_combo_options());
    expect_props(d, #{ extra_rinse: "true", turbo_wash: "true", pre_wash: "true", eco_hybrid: "false", steam: "false", detergent: "off", softener: "high", spin: "1000", temp: "40", initial_time: "241", remaining_time: "241" });
}

// delay end frame decodes delay_end in hours
fn test_delay_end() {
    let d = device();
    d.feed(sample_delay_end());
    expect_props(d, #{ reserve_time: "3" });
}

// running state on Wash + Dry course decodes status, spin, temp, lock
fn test_running_wash_dry() {
    let d = device();
    d.feed(sample_running());
    expect_props(d, #{ status: "washing", spin: "1400", temp: "40", drying_mode: "auto", door_lock: "true", remote_start: "true", child_lock: "false" });
}

// drying state on Drying-only course decodes status=Drying, drying_mode=Auto
fn test_drying() {
    let d = device();
    d.feed(sample_drying());
    expect_props(d, #{ status: "drying", drying_mode: "auto", initial_time: "55", remaining_time: "55", cycles: "11", spin: "none", temp: "none" });
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
    d.feed(sample_running());
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

