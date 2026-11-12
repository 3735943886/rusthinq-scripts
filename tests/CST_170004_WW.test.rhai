import "runtime_test" as runtime;
import "tlv_test" as t;

// Tests of CST_170004_WW.rhai (cst_common), ported from the owner's rethink test suite
// (tests/cloud/devices/CST_170004_WW.test.ts, up to "power on CST units with the power preset").
// Its fixtures are values captured from the installed units: feature caps 0x2cb = 0x1006, jet /
// swing caps 0x2cd = 0x1fe7b7, setpoint range 16-30, cool, auto fan, room 29, setpoint 18,
// power 177 W, humidity 47 %, display 50 %, vane position 4. The frames below are those fixtures
// framed as the TS test frames them, and every expected write is what the TS driver sent for the
// same command (run with the TS mocks), byte for byte. Upstream test names are quoted.

fn caps() { "000004000000A702010115B2E01006B3701FE7B7B4C1B6A01234B85020B8903C452D" }
fn values() {
    "000004000000A70204012F7DC17E407E887F503A7F902481418180838387D096894A8FC0ACD0B1AD600D8DC8" +
    "44CDA001D6D5502FD5A00960F58031D3"
}
// {0x1f7 = 0, 0x1f9 = 2, 0x1fa = 8}: off, in fan_only, auto fan.
fn off_in_fan_only() { "000004000000A7020401067DC07E427E88A51F" }
// {0x1f9 = 2, 0x1fa = 4, 0x21a = 120}: the unit echoing the fan-2h preset.
fn fan_2h_echo() { "000004000000A7020401077E427E8486907891F5" }
fn fan_report(v) {
    switch v {
        6 => "000004000000A7020401027E864D86",
        7 => "000004000000A7020401027E875DA7",
        8 => "000004000000A7020401027E88AC48"
    }
}
// {0x1fe = 54, 0x1fa = 6}: out of power fan, the setpoint from before it restored.
fn left_power_fan() { "000004000000A7020401057F90367E861DF1" }

fn running() { t::running(device(), caps(), values()) }

fn sent_hex(d, n) {
    let out = [];
    for i in n..d.sent().len() { out.push(hex_encode(d.sent()[i])); }
    out
}

// "captured capabilities publish the CST climate configuration"
fn test_the_captured_capabilities_give_the_descriptor() {
    let d = running();
    let p = runtime::descriptor(d).props;
    expect_eq(p.mode.options, ["cool", "dry", "fan_only", "auto"]);
    expect_eq(p.fan.options, ["auto", "very_low", "low", "medium", "high", "power"]);
    expect_eq(p.vane_position.options, ["off", "1", "2", "3", "4", "5", "6"]);
    expect_eq(p.preset.options, ["none", "fan_2h_off", "power"]);
    expect_eq(p.target.min, 16);
    expect_eq(p.target.max, 30);
    expect_eq(p.sleep_timer.max, 420);
    expect_eq(p.swing_vertical.role, "swing_vertical");
    expect_eq(p.swing_horizontal.role, "swing_horizontal");
    expect(p.auto_dry != (), "auto dry");
    expect(p.energy_save != (), "energy saving");
    expect(p.jet == (), "no jet: 0x2cd claims it, the unit has none");
    expect_eq(p.odu_power.unit, "W");
}

// "captured initial state decodes CST climate and diagnostic values"
fn test_the_captured_state_becomes_il_properties() {
    expect_props(running(), #{
        available: "true", power: "true", mode: "cool", fan: "auto", temperature: "29",
        target: "18", action: "cooling", swing_vertical: "true", swing_horizontal: "false",
        vane_position: "4", humidity: "47", power_draw: "177", odu_power: "3469",
        auto_dry: "60min", auto_dry_remaining: "10", display: "50%", comfort_saving: "false",
        wind_mode: "off", filter_remaining: "2", filter_used: "2353", filter_life: "2400",
        preset: "none"
    });
}

// "power-off writes only power TLV 0x1f7=0"
fn test_power_off_writes_only_the_power_tag() {
    let d = running();
    let n = d.sent().len();
    d.set("power", "false");
    expect_eq(sent_hex(d, n), ["01010400000065020101027dc00576"]);
}

// Power on carries mode, fan and setpoint: this family ignores a bare power-on write. (The same
// frame "firing a reservation persists its removal before sending power" checks.)
fn test_power_on_carries_mode_fan_and_setpoint() {
    let d = running();
    let n = d.sent().len();
    d.set("power", "true");
    expect_eq(t::sent_since(d, n), [[[0x1f7, 1], [0x1f9, 0], [0x1fa, 8], [0x1fe, 36]]]);
    d.feed(off_in_fan_only());
    let n = d.sent().len();
    d.set("power", "true");
    expect_eq(sent_hex(d, n), ["01010400000065020101097dc17e427e887f902458d5"]);
}

// "dry mode writes mode TLV and required powered-on context"
fn test_a_mode_write_carries_power_on() {
    let d = running();
    let n = d.sent().len();
    d.set("mode", "dry");
    expect_eq(sent_hex(d, n), ["01010400000065020101097e417dc17e887f90244a52"]);
}

// "strong fan writes fan TLV 0x1fa=6 with mode and target context"
fn test_high_fan_writes_6_with_mode_and_setpoint() {
    let d = running();
    let n = d.sent().len();
    d.set("fan", "high");
    expect_eq(sent_hex(d, n), ["01010400000065020101077e867e407f902405f0"]);
}

// "20.5 C target writes half-degree TLV 0x1fe=41"
fn test_the_setpoint_goes_out_in_half_degrees() {
    let d = running();
    let n = d.sent().len();
    d.set("target", "20.5");
    expect_eq(sent_hex(d, n), ["01010400000065020101077f90297e407e8878ee"]);
}

// "power preset turns an off unit on in cooling with fan 7": the preset rides the mode frame,
// which carries power on; a fan-only write would leave an off unit off.
fn test_the_power_preset_turns_an_off_unit_on_in_cool_with_power_fan() {
    let d = running();
    d.feed(off_in_fan_only());
    let n = d.sent().len();
    d.set("preset", "power");
    expect_eq(sent_hex(d, n), ["01010400000065020101097e407dc17e877f9024d96f"]);
    expect_eq(d.property("preset"), "none"); // nothing is published from a write
    d.feed(t::notify([[0x1f7, 1], [0x1f9, 0], [0x1fa, 7]]));
    expect_eq(d.property("preset"), "power");
    expect_eq(d.property("power"), "true");
}

// "fan-2h preset writes fan_only carrying 중풍 and arms the 120 min sleep timer"
fn test_the_fan_2h_preset_carries_medium_fan_and_arms_the_sleep_timer() {
    let d = running();
    let n = d.sent().len();
    d.set("preset", "fan_2h_off");
    expect_eq(sent_hex(d, n), [
        "01010400000065020101097e427dc17e847f9024cd15",
        "0101040000006502010103869078b292",
    ]);
    d.feed(fan_2h_echo());
    expect_eq(d.property("mode"), "fan_only");
    expect_eq(d.property("fan"), "medium");
    expect_eq(d.property("sleep_timer"), "120");
    expect_eq(d.property("preset"), "fan_2h_off");
}

fn test_the_none_preset_clears_the_sleep_timer_only() {
    let d = running();
    d.set("preset", "fan_2h_off");
    d.feed(fan_2h_echo());
    let n = d.sent().len();
    d.set("preset", "none");
    expect_eq(sent_hex(d, n), ["010104000000650201010286808289"]);
    d.feed(t::notify([[0x21a, 0]]));
    expect_eq(d.property("preset"), "none");
    expect_eq(d.property("mode"), "fan_only");
}

// fan_2h_off is the more specific reading: power fan in fan_only with a timer is still fan_2h_off.
fn test_the_preset_reads_fan_2h_before_power() {
    let d = running();
    d.feed(t::notify([[0x1f9, 2], [0x1fa, 7], [0x21a, 30]]));
    expect_eq(d.property("preset"), "fan_2h_off");
    d.feed(t::notify([[0x21a, 0]]));
    expect_eq(d.property("preset"), "power");
}

// "a setpoint asked for in 파워풍 ends 파워풍 first and lands on the appliance report"
fn test_a_setpoint_in_power_fan_ends_it_first_and_lands_on_the_report() {
    let d = running();
    d.feed(fan_report(7));
    expect_eq(d.property("preset"), "power");
    let n = d.sent().len();
    d.set("target", "26");
    // first frame: end power fan; the setpoint it carries is the unit's own pinned 18
    expect_eq(sent_hex(d, n), ["01010400000065020101077e867e407f902405f0"]);
    d.feed(left_power_fan());
    expect_eq(sent_hex(d, n), [
        "01010400000065020101077e867e407f902405f0",
        "01010400000065020101077f90347e407e86bc00",
    ]);
    expect_eq(d.property("preset"), "none");
}

// "the held setpoint is written once and not replayed on a later fan change"
fn test_the_held_setpoint_is_written_once() {
    let d = running();
    d.feed(fan_report(7));
    let n = d.sent().len();
    d.set("target", "26");
    d.feed(fan_report(6));
    expect_eq(d.sent().len(), n + 2);
    d.feed(fan_report(8));
    expect_eq(d.sent().len(), n + 2);
}

// A report that the fan is still at power does not release the held setpoint.
fn test_the_held_setpoint_waits_while_the_fan_stays_at_power() {
    let d = running();
    d.feed(fan_report(7));
    let n = d.sent().len();
    d.set("target", "26");
    d.feed(fan_report(7));
    expect_eq(d.sent().len(), n + 1);
}

// "a setpoint asked for at any other fan speed still writes the target first"
fn test_a_setpoint_at_another_fan_speed_is_written_at_once() {
    let d = running();
    d.feed(fan_report(6));
    let n = d.sent().len();
    d.set("target", "26");
    expect_eq(sent_hex(d, n), ["01010400000065020101077f90347e407e86bc00"]);
}

// "left-right swing writes the measured 0x205 and 0x206 flag pair": both flags go out in one
// frame. From the captured 0x205 = 1 / 0x206 = 0 these four writes give the TS driver's frames for
// both, left-right, stop and up-down.
fn test_swing_writes_both_flags_in_one_frame() {
    let d = running();
    let n = d.sent().len();
    d.set("swing_horizontal", "true");
    d.set("swing_vertical", "false");
    d.set("swing_horizontal", "false");
    d.set("swing_vertical", "true");
    expect_eq(sent_hex(d, n), [
        "0101040000006502010104814181815934",
        "0101040000006502010104814081816e04",
        "0101040000006502010104814081807e25",
        "0101040000006502010104814181804915",
    ]);
}

fn test_the_vane_position_is_read_and_written_on_0x321() {
    let d = running();
    let n = d.sent().len();
    d.set("vane_position", "6");
    d.set("vane_position", "off");
    expect_eq(sent_hex(d, n), ["0101040000006502010102c84615c0", "0101040000006502010102c8407506"]);
    d.feed(t::notify([[0x321, 0]]));
    expect_eq(d.property("vane_position"), "off");
    // continuous sweep (100) is not a position this unit holds: the last reading stands
    d.feed(t::notify([[0x321, 100]]));
    expect_eq(d.property("vane_position"), "off");
}

fn test_the_model_settings_write_the_ts_drivers_frames() {
    let d = running();
    let n = d.sent().len();
    d.set("wind_mode", "manner");
    d.set("energy_save", "true");
    d.set("sleep_timer", "30");
    d.set("sleep_timer", "420");
    d.set("auto_dry", "smart");
    d.set("display", "50%");
    d.set("comfort_saving", "true");
    expect_eq(sent_hex(d, n), [
        "010104000000650201010aa400a440f540f581f5c0850e",
        "01010400000065020101028341b411",
        "010104000000650201010386901ebef2",
        "010104000000650201010486a001a4f047",
        "01010400000065020101038390ffb80d",
        "010104000000650201010387d096948e",
        "01010400000065020101028fc160f4",
    ]);
}

fn test_the_outdoor_unit_power_is_read_from_0x2b5() {
    let d = running();
    d.feed(t::notify([[0x2b5, 3261]]));
    expect_eq(d.property("odu_power"), "3261");
}

fn test_a_bad_write_is_refused_and_sends_nothing() {
    let d = running();
    let n = d.sent().len();
    d.set("preset", "boost");
    d.set("vane_position", "on");
    d.set("vane_position", "7");
    d.set("sleep_timer", "421");
    d.set("fan", "turbo");
    d.set("mode", "heat");
    d.set("target", "30.5");
    d.set("odu_power", "100"); // read only
    d.set("turn_on_timer", "30"); // not offered here
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "a reject event");
}

fn test_unknown_codes_leave_the_last_reading() {
    let d = running();
    d.feed(t::notify([[0x1fa, 3], [0x1f9, 9]]));
    expect_eq(d.property("fan"), "auto");
    expect_eq(d.property("mode"), "cool");
}

fn test_reconnect_keeps_the_reported_values() {
    let d = running();
    d.drop_device();
    expect_eq(d.property("available"), "false");
    d.start();
    expect_eq(d.script_error(), ());
    expect_eq(d.property("available"), "true");
    expect_eq(d.property("preset"), "none");
    expect_eq(d.property("vane_position"), "4");
    expect_eq(d.property("odu_power"), "3469");
}

// The captured state carries no 0x20d. Energy saving set while cooling is written again when
// the unit next enters cool, since it forgets it over a power cycle and does not report it.
fn test_energy_saving_is_rewritten_after_a_power_cycle_without_a_report() {
    let d = running();
    d.set("energy_save", "true");
    d.feed(t::notify([[0x1f7, 0]]));
    let n = d.sent().len();
    d.feed(t::notify([[0x1f7, 1], [0x1f9, 0]]));
    expect_eq(t::sent_since(d, n), [[[0x20d, 1]]]);
    expect_eq(d.property("energy_save"), "true");
}
