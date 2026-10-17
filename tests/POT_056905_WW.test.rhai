import "runtime_test" as runtime;
import "tlv_test" as t;

// Tests of POT_056905_WW (climate_common), ported from upstream rethink's test suite (commit
// 0e57069; real captures from an LG LP1022FVSM). Writes are compared byte for byte with the
// frames upstream's driver sends; HA's climate mode "off" is the IL power switch here.

fn caps_request() { "01010400000065020201027D416A0D" }
fn query_request() { "01010400000065020201027D425A6E" }
// Unlike RAC_056905_WW / WIN_056905_WW, this model uses 0xA7 for device-to-cloud packets.
fn caps_response() {
    "000004000000A702019946" +
    "B01011B047B09054B0C1B103B35010B4E04006B55060B6A0046FB6F0115100BD01B85020B8903C" +
    "B8D020B9103CBC41BD47B5C0B61020B642B5C1B61029B642B5C2B61029B642AD3A"
}
// While physically set to dry: power on, dry, fan low, room 19.5, setpoint 20.5.
fn query_response() {
    "000004000000A702049C47" +
    "7E417DC17E827F50277F9029C840868086C08700884089408A10188A50688A8F8CA002E88CD01BA" +
    "CE00258D55092D590FACAD04BCB10B0CB8CCBCFCC1048CC907C1B01C0C0AC403F51"
}
fn write_mode_dry() { "01010400000065020101097E417DC17E827F902AC337" }
fn write_mode_fan_only() { "01010400000065020101097E427DC17E827F90293B21" }
fn write_power_off() { "01010400000065020101027DC00576" }

fn sent_hex(d, i) { hex_encode_upper(d.sent()[i]) }

fn ready() { t::running(device(), caps_response(), query_response()) }

// config exposes expected climate component
fn test_the_descriptor_is_a_portable_air_conditioner() {
    let d = ready();
    let props = runtime::descriptor(d).props;
    expect_eq(props.mode.options, ["cool", "dry", "fan_only"]);
    expect_eq(props.fan.options, ["low", "medium", "high"]);
    expect_eq(props.swing.type, "binary");
    expect_eq(props.target.step, 1);
    expect_eq(props.target.min, 16);
    expect_eq(props.target.max, 30);
    expect(!props.contains("action"), "no action");
}

// initial state response publishes all expected HA properties
fn test_the_captured_state_becomes_il_properties() {
    let d = ready();
    expect_props(d, #{ available: "true", power: "true", mode: "dry", fan: "low",
                       temperature: "19.5", target: "20.5" });
    // The capture carries 0x321 = 0, but this model's swing is 0x322, which it lacks.
    expect_eq(d.property("swing"), ());
}

// HA write climate-mode=dry from off emits expected bytes
fn test_a_mode_write_from_off_powers_the_unit_on() {
    let d = ready();
    // the pre-state observed while testing mode changes from off
    d.feed(t::notify([[0x1f7, 0], [0x1f9, 0], [0x1fa, 2], [0x1fe, 42]]));
    let n = d.sent().len();
    d.set("mode", "dry");
    expect_eq(d.sent().len(), n + 1);
    expect_eq(sent_hex(d, n), write_mode_dry());
}

// HA write climate-mode=fan_only emits expected bytes
fn test_fan_only() {
    let d = ready();
    let n = d.sent().len();
    d.set("mode", "fan_only");
    expect_eq(d.sent().len(), n + 1);
    expect_eq(sent_hex(d, n), write_mode_fan_only());
}

// HA write climate-mode=off triggers power=OFF instead of mode write
fn test_power_off_writes_only_the_power_tag() {
    let d = ready();
    let n = d.sent().len();
    d.set("power", "false");
    expect_eq(d.sent().len(), n + 1);
    expect_eq(sent_hex(d, n), write_power_off());
}

// 0xA7 caps response triggers values query
fn test_the_0xa7_capabilities_reply_moves_on_to_the_values_query() {
    let d = device();
    d.start();
    d.feed(caps_response());
    expect_eq(d.sent().len(), 2);
    expect_eq(sent_hex(d, 1), query_request());
}

// constructor sends a queryCaps packet on the wire
fn test_start_asks_for_the_capabilities() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 1);
    expect_eq(sent_hex(d, 0), caps_request());
}

// (beyond upstream's tests) the other writes carry what upstream's fields attach
fn test_power_fan_setpoint_and_swing_writes() {
    let d = ready();
    let n = d.sent().len();
    d.set("power", "true");
    d.set("fan", "high");
    d.set("target", "22");
    d.set("swing", "true");
    expect_eq(t::sent_since(d, n), [
        [[0x1f7, 1], [0x1f9, 1]],
        [[0x1fa, 6], [0x1f9, 1], [0x1fe, 41]],
        [[0x1fe, 44], [0x1f9, 1], [0x1fa, 6]],
        [[0x322, 100], [0x1f9, 1], [0x1fa, 6]],
    ]);
}

fn test_a_bad_write_is_refused_and_sends_nothing() {
    let d = ready();
    let n = d.sent().len();
    d.set("mode", "heat");
    d.set("fan", "auto");
    d.set("target", "22.5"); // whole degrees on this model
    d.set("target", "31");
    d.set("temperature", "20"); // read only
    expect_eq(d.sent().len(), n);
}

fn test_swing_reads_on_and_off() {
    let d = ready();
    d.feed(t::notify([[0x322, 100]]));
    expect_eq(d.property("swing"), "true");
    d.feed(t::notify([[0x322, 0]]));
    expect_eq(d.property("swing"), "false");
}
