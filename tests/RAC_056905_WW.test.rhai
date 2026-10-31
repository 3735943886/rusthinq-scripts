import "runtime_test" as runtime;
import "tlv_test" as t;

// Tests of RAC_056905_WW (climate_common), ported from upstream rethink's test suite (commit
// 2d8eaba; real captures from RAC_056905_WW units, the display ones from an S4NW12JA31A,
// firmware 0x690441). Writes are compared byte for byte with upstream's captures; HA's climate
// mode "off" is the IL power switch here. Sensor values are what upstream's lookup tables give.

fn caps_request() { "01010400000065020201027D416A0D" }
// Carries 0x2da (EEPROM checksum 0x4d81, not a verified display revision).
fn caps_response() {
    "0000040000008702010249" +
    "B001B05057B0A0017CB0C1B103B306B34FB4C7B582B541B543B6A04D81B6F0690409B701BC40BD47" +
    "B5C0B61024B643B5C1B600B643B5C2B600B643B5C4B61026B643B5C6B6102CB643" +
    "44E1"
}
// Heat, power on, fan low, room 20.5, setpoint 19.
fn query_response() {
    "00000400000087020415" +
    "777E447DC17E837F50297F9026C840C880C8C08340838083C0868086C0870087C0894088408A1011" +
    "8A505A8A8F8CA0C0BA8CD010ACE00164D540D580C900CAD0A0CB1040CB40CB8CCBCFCC1032CC504F" +
    "CC90438B40BF600155BFE00271BFA00155C0200271BE509FBE90A01B01BED050C300C340C0C0C380" +
    "3E6B"
}
// The S4NW12JA31A advertises the display light (0x2d6 bit 0x2, checksum 0x4e88).
fn display_caps_response() {
    "000004000000870201F361" +
    "B001B05057B0A0017CB85024B8903CB8D020B9103CBAD024BB103CB0C1B103B306B280B347B4C7" +
    "B582B541B543B6A04E88B6F0690441B701B740BC40BD4FB5C0B6102EB643B5C1B61028B643B5C2" +
    "B61028B643B5C4B6102EB643B5C6B6102EB643EE35"
}
// The full state right after LIGHT was pressed: 0x21f = 0, the display off.
fn display_off_query_response() {
    "0000040000008702042679" +
    "7E447DC17E827F502A7F9030C840C880C8C08340838083C0868086C0870087C08F80894088408A10" +
    "2A8A50548A8F8C90238CC2ACE0027ACA00D540D580C900CAD0B8CB1061CB40CB8CCBCFCC00CC9068" +
    "8B40BF600155BFC0BFA00155C000BE502DBE8CCC504F1B01BED050C340C0C0C380CCC0CD00CD4090000AA0"
}
// The notification after writing 0x21f = 1; the display turned on.
fn display_on_notify() { "0000040000008702047D0287C1BF4D" }
fn write_display_on() { "010104000000650201010287C1E95D" }
fn write_display_off() { "010104000000650201010287C0F97C" }
fn write_mode_fan_only() { "01010400000065020101067E427E837F80B452" }
fn write_mode_heat() { "01010400000065020101077E447E837F902AF936" }
fn write_power_off() { "01010400000065020101027DC00576" }

// The private filter query (command 0x02): upstream's sendPrivCommand(0x02, 0x02), with its crc16.
fn filter_query() { "00FF0400000065FD02000102511B" }

fn sent_hex(d, i) { hex_encode_upper(d.sent()[i]) }
fn last_hex(d) { sent_hex(d, d.sent().len() - 1) }

// Through caps -> values -> the filter probe timing out -> the values query again.
fn ready_with(caps, state) {
    let d = device();
    d.start();
    d.feed(caps);
    d.feed(state);
    d.fire("filter_probe");
    d.feed(state);
    d
}
fn ready() { ready_with(caps_response(), query_response()) }

// verified S4NW12JA31A exposes and reports the display light
fn test_a_verified_revision_exposes_the_display_light() {
    let d = ready_with(display_caps_response(), display_off_query_response());
    let light = runtime::descriptor(d).props.display_light;
    expect_eq(light.type, "binary");
    expect_eq(light.category, "config");
    expect_eq(d.property("display_light"), "false");
    d.feed(display_on_notify());
    expect_eq(d.property("display_light"), "true");
    d.set("display_light", "true");
    expect_eq(last_hex(d), write_display_on());
    d.set("display_light", "false");
    expect_eq(last_hex(d), write_display_off());
}

// does not expose display light for an unverified hardware revision
fn test_an_unverified_revision_has_no_display_light() {
    expect(!runtime::descriptor(ready()).props.contains("display_light"), "no display_light");
}

// caps and values responses triggers config publish
fn test_the_capabilities_decide_the_optional_features() {
    let props = runtime::descriptor(ready()).props;
    for p in ["jet", "energy_save", "auto_dry", "sleep_timer", "turn_on_timer", "turn_off_timer"] {
        expect(props.contains(p), p);
    }
    expect(!props.contains("air_purify"), "air_purify off (0x2cc bit 0x1 unset)");
    expect_eq(props.swing_vertical.options, ["1", "2", "3", "4", "5", "6", "on", "off"]);
    expect_eq(props.swing_horizontal.options, ["1", "2", "3", "4", "5", "1-3", "3-5", "on", "off"]);
    expect_eq(props.mode.options, ["cool", "dry", "fan_only", "heat", "auto"]);
    expect_eq(props.fan.options, ["auto", "very_low", "low", "medium", "high", "very_high"]);
    expect_eq(props.target.min, 18);
}

// initial state response publishes all expected HA properties
fn test_the_captured_state_becomes_il_properties() {
    let d = ready();
    expect_props(d, #{ available: "true", power: "true", mode: "heat", fan: "low",
                       temperature: "20.5", target: "19", swing_vertical: "off",
                       swing_horizontal: "off", auto_dry: "false", sleep_timer: "0",
                       turn_on_timer: "0", turn_off_timer: "0", jet: "false", action: "heating" });
    // energy saving applies in cool only: not read in heat
    expect_eq(d.property("energy_save"), ());
}

// (beyond upstream's tests) the diagnostic sensors the state carries, through upstream's tables
fn test_the_outdoor_unit_sensors() {
    let d = ready();
    expect_props(d, #{ error: "0", capacity: "3.5", eev: "50", pipe_liquid_temp: "31.65",
                       pipe_gas_temp: "32.05", outdoor_coil_temp: "-1.77", outdoor_temp: "0.68",
                       fan_rpm: "790", power_draw: "296" });
}

// HA write climate-mode=fan_only emits expected bytes
fn test_fan_only() {
    let d = ready();
    d.feed(t::notify([[0x1fa, 3], [0x1fe, 0]])); // the pre-state in the capture
    d.set("mode", "fan_only");
    expect_eq(last_hex(d), write_mode_fan_only());
}

// HA write climate-mode=heat emits expected bytes
fn test_heat() {
    let d = ready();
    d.feed(t::notify([[0x1fa, 3], [0x1fe, 42]]));
    let n = d.sent().len();
    d.set("mode", "heat");
    expect_eq(d.sent().len(), n + 1);
    expect_eq(last_hex(d), write_mode_heat());
}

// HA write climate-mode=off triggers power=OFF instead of mode write
fn test_power_off_writes_only_the_power_tag() {
    let d = ready();
    d.feed(t::notify([[0x1f7, 1], [0x1f9, 0], [0x1fa, 3], [0x1fe, 42]]));
    let n = d.sent().len();
    d.set("power", "false");
    expect_eq(d.sent().len(), n + 1);
    expect_eq(last_hex(d), write_power_off());
}

// constructor sends a queryCaps packet on the wire
fn test_start_asks_for_the_capabilities() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 1);
    expect_eq(sent_hex(d, 0), caps_request());
}

// (beyond upstream's tests) the first state masks the noisy tag and probes for a filter
fn test_the_first_state_masks_reports_and_probes_the_filter() {
    let d = device();
    d.start();
    d.feed(caps_response());
    d.feed(query_response());
    expect_eq(d.clips()[0].cmd, "setMaskingInfo");
    expect_eq(last_hex(d), filter_query());
    expect(d.timers().contains(["filter_probe", 5000]), "probe timeout");
    // no reply: the descriptor completes without a filter and the values are asked for again
    d.fire("filter_probe");
    expect_eq(d.sent_tlvs(d.sent().len() - 1), [[0x1f5, 2]]);
    expect(!runtime::descriptor(d).props.contains("filter_life"), "no filter");
}

// (beyond upstream's tests; a constructed reply, laid out as upstream parses it)
fn test_a_filter_reply_adds_the_filter_readings() {
    let d = device();
    d.start();
    d.feed(caps_response());
    d.feed(query_response());
    // used 120 h, life 2400 h, reset 2026-10-01, little-endian after one leading byte
    let data = [0x00, 0x78, 0x00, 0x00, 0x00, 0x60, 0x09, 0x00, 0x00, 0x89, 0x28, 0x35, 0x01];
    let frame = [0x02, 0xff, 0x04, 0, 0, 0, 0x87, 0xfd, 0x03, 0x00, data.len()];
    frame += data;
    frame += [0, 0];
    d.feed(hex_encode(blob_of(frame)));
    expect(!d.timers().contains(["filter_probe", 5000]), "the probe is answered");
    expect(runtime::descriptor(d).props.contains("filter_life"), "filter props");
    expect_props(d, #{ filter_used: "120", filter_life: "2400", filter_reset_date: "2026-10-01" });
    expect(d.timers().contains(["filter_refresh", 86400000]), "daily refresh");
}

fn blob_of(list) { let b = blob(); for x in list { b.push(x); } b }

// (beyond upstream's tests) energy saving is remembered and written again on entering cool;
// jet, read as off in heat, is written again too, first, in upstream's hook order
fn test_energy_saving_is_rewritten_when_cooling_starts() {
    let d = ready();
    let n = d.sent().len();
    d.set("energy_save", "true"); // heat: remembered, not written
    expect_eq(d.sent().len(), n);
    expect_eq(d.property("energy_save"), "true");
    d.feed(t::notify([[0x1f9, 0]])); // the unit switches to cool
    expect_eq(t::sent_since(d, n), [[[0x323, 0]], [[0x20d, 1]]]);
}

// (beyond upstream's tests) jet writes 2 in heat, 1 in cool, and follows the mode
fn test_jet_follows_the_mode() {
    let d = ready();
    let n = d.sent().len();
    d.set("jet", "true");
    d.feed(t::notify([[0x1f9, 0]]));
    expect_eq(t::sent_since(d, n), [[[0x323, 2]], [[0x323, 1]]]);
    d.feed(t::notify([[0x323, 1]]));
    expect_eq(d.property("jet"), "true");
}

fn test_timers_read_and_write_in_quarter_hours() {
    let d = ready();
    d.feed(t::notify([[0x21a, 70]]));
    expect_eq(d.property("sleep_timer"), "1.25");
    let n = d.sent().len();
    d.set("turn_off_timer", "1.5");
    expect_eq(t::sent_since(d, n), [[[0x21b, 90]]]);
}

fn test_a_bad_write_is_refused_and_sends_nothing() {
    let d = ready();
    let n = d.sent().len();
    d.set("fan", "power");
    d.set("swing_vertical", "7");
    d.set("sleep_timer", "16");
    d.set("air_purify", "true"); // not on this unit
    d.set("display_light", "true"); // unverified revision
    d.set("outdoor_temp", "3"); // read only
    expect_eq(d.sent().len(), n);
}

// ---- the ThinQ1 variant: upstream's RAC_056905_WW_T1 tests (real pushes from a QCA4002 /
// 2.6.7_RTOS_3K unit, anszom/rethink#70). HA's climate mode "off" is the IL power switch, and
// an unknown code stays unpublished instead of reading "None".

fn t1_off() { base64_decode("eyJPcGVyYXRpb24iOiIwIiwiT3BNb2RlIjoiMiIsIldpbmRTdHJlbmd0aCI6IjIiLCJUZW1wVW5pdCI6Ik5TIiwiVGVtcEN1ciI6IjIxIiwiVGVtcENmZyI6IjI0IiwiR3JvdXBUeXBlIjoiMSIsIlNsZWVwVGltZSI6IjAiLCJPblRpbWUiOiIwIiwiT2ZmVGltZSI6IjAiLCJSYWNBZGRGdW5jIjoiTlMiLCJFeHRyYU9wIjoiMCIsIkRpYWdDb2RlIjoiMDAiLCJUaW1lQnNPbiI6IjAiLCJUaW1lQnNPZmYiOiIwIiwiQWlyQ2xlYW4iOiIwIiwiQXV0b0RyeSI6IjAiLCJQb3dlclNhdmUiOiIwIiwiV0RpclZTdGVwIjoiMCIsIldEaXJIU3RlcCI6IjMiLCJUZW1wTGltaXRNYXgiOiIwIiwiVGVtcExpbWl0TWluIjoiMCIsIkR1Y3Rab25lVHlwZSI6IjAiLCJab25lQ29udHJvbCI6IjAiLCJEUkVEIjoiMCIsIlNlbnNvclBNMSI6IjAiLCJTZW5zb3JQTTIiOiIwIiwiU2Vuc29yUE0xMCI6IjAiLCJBaXJQb2x1dGlvbiI6IjAiLCJIdW1pZGl0eUNmZyI6IjAiLCJXYXRlclRlbXBDb29sTWluIjoiMCIsIldhdGVyVGVtcENvb2xNYXgiOiIwIiwiV2F0ZXJUZW1wSGVhdE1pbiI6IjAiLCJXYXRlclRlbXBIZWF0TWF4IjoiMCIsIkhvdFdhdGVyVGVtcE1pbiI6IjAiLCJIb3RXYXRlclRlbXBNYXgiOiIwIiwiU2Vuc29ySHVtaWRpdHkiOiIwIiwiVG90YWxBaXJQb2x1dGlvbiI6IjAiLCJTZW5zb3JNb24iOiIwIiwiQ2xlYW5EcnkiOiIwIiwiUHJvZHVjdFN0YXR1cyI6IjAiLCJBaXJNb25pdG9yaW5nIjoiMCIsIkh1bWlkaWZpY2F0aW9uIjoiMCIsIkFpckZhc3QiOiIwIiwiQWlyUmVtb3ZhbCI6IjAiLCJBaXJVVkRpc2luZmVjdGlvbiI6IjAiLCJXYXRlcnRhbmtMaWdodCI6IjAiLCJTaWduYWxMaWdodGluZyI6IjAiLCJXRGlyVXBEb3duIjoiMCIsIldEaXJMZWZ0UmlnaHQiOiIwIiwiV1N3aXJsIjoiMCIsIkpldCI6IjAiLCJMb3dIZWF0aW5nIjoiMCIsIkNpcmN1bGF0ZVN0cmVuZ3RoIjoiMCIsIkNpcmN1bGF0ZURpciI6IjAiLCJBbnRpQnVncyI6IjAiLCJJY2VWYWxsZXkiOiIwIiwiSHVtc2F2ZSI6IjAiLCJXYXRlclRlbXBDdXIiOiIwIiwiSG90V2F0ZXJUZW1wQ3VyIjoiMCIsIkhvdFdhdGVyVGVtcENmZyI6IjAiLCJIb3RXYXRlck1vZGUiOiIwIiwiSG90V2F0ZXIiOiIwIiwiQVdIUFRlbXBDZmdTd2l0Y2giOiIwIiwiQWlyVGVtcENvb2xNaW4iOiIwIiwiQWlyVGVtcENvb2xNYXgiOiIwIiwiQWlyVGVtcEhlYXRNaW4iOiIwIiwiQWlyVGVtcEhlYXRNYXgiOiIwIiwiV2F0ZXJJblRlbXBDdXIiOiIwIiwiQVdIUFdBVGVtcENvbnRyb2xTdGEiOiIwIiwiRGlzcGxheUNvbnRyb2wiOiIwIiwiU21hcnRDYXJlIjoiMCIsIlR3b1NldENvb2xUZW1wIjoiMCIsIlR3b1NldEhlYXRUZW1wIjoiMCIsIlR3b1NldENvb2xVU0wiOiIwIiwiVHdvU2V0Q29vbExTTCI6IjAiLCJUd29TZXRIZWF0VVNMIjoiMCIsIlR3b1NldEhlYXRMU0wiOiIwIiwiVHdvU2V0QUNPU3RhdGUiOiIwIiwiVHdvU2V0TW9kZURlYWRiYW5kIjoiMCIsIlR3b1NldFN0YXRlIjoiMCJ9") }
fn t1_cool_23_high() { base64_decode("eyJPcGVyYXRpb24iOiIxIiwiT3BNb2RlIjoiMCIsIldpbmRTdHJlbmd0aCI6IjYiLCJUZW1wVW5pdCI6Ik5TIiwiVGVtcEN1ciI6IjIxIiwiVGVtcENmZyI6IjIzIiwiR3JvdXBUeXBlIjoiMSIsIlNsZWVwVGltZSI6IjAiLCJPblRpbWUiOiIwIiwiT2ZmVGltZSI6IjAiLCJSYWNBZGRGdW5jIjoiTlMiLCJFeHRyYU9wIjoiMCIsIkRpYWdDb2RlIjoiMDAiLCJUaW1lQnNPbiI6IjAiLCJUaW1lQnNPZmYiOiIwIiwiQWlyQ2xlYW4iOiIwIiwiQXV0b0RyeSI6IjAiLCJQb3dlclNhdmUiOiIwIiwiV0RpclZTdGVwIjoiMTAwIiwiV0RpckhTdGVwIjoiMyIsIlRlbXBMaW1pdE1heCI6IjAiLCJUZW1wTGltaXRNaW4iOiIwIiwiRHVjdFpvbmVUeXBlIjoiMCIsIlpvbmVDb250cm9sIjoiMCIsIkRSRUQiOiIwIiwiU2Vuc29yUE0xIjoiMCIsIlNlbnNvclBNMiI6IjAiLCJTZW5zb3JQTTEwIjoiMCIsIkFpclBvbHV0aW9uIjoiMCIsIkh1bWlkaXR5Q2ZnIjoiMCIsIldhdGVyVGVtcENvb2xNaW4iOiIwIiwiV2F0ZXJUZW1wQ29vbE1heCI6IjAiLCJXYXRlclRlbXBIZWF0TWluIjoiMCIsIldhdGVyVGVtcEhlYXRNYXgiOiIwIiwiSG90V2F0ZXJUZW1wTWluIjoiMCIsIkhvdFdhdGVyVGVtcE1heCI6IjAiLCJTZW5zb3JIdW1pZGl0eSI6IjAiLCJUb3RhbEFpclBvbHV0aW9uIjoiMCIsIlNlbnNvck1vbiI6IjAiLCJDbGVhbkRyeSI6IjAiLCJQcm9kdWN0U3RhdHVzIjoiMCIsIkFpck1vbml0b3JpbmciOiIwIiwiSHVtaWRpZmljYXRpb24iOiIwIiwiQWlyRmFzdCI6IjAiLCJBaXJSZW1vdmFsIjoiMCIsIkFpclVWRGlzaW5mZWN0aW9uIjoiMCIsIldhdGVydGFua0xpZ2h0IjoiMCIsIlNpZ25hbExpZ2h0aW5nIjoiMCIsIldEaXJVcERvd24iOiIwIiwiV0RpckxlZnRSaWdodCI6IjAiLCJXU3dpcmwiOiIwIiwiSmV0IjoiMCIsIkxvd0hlYXRpbmciOiIwIiwiQ2lyY3VsYXRlU3RyZW5ndGgiOiIwIiwiQ2lyY3VsYXRlRGlyIjoiMCIsIkFudGlCdWdzIjoiMCIsIkljZVZhbGxleSI6IjAiLCJIdW1zYXZlIjoiMCIsIldhdGVyVGVtcEN1ciI6IjAiLCJIb3RXYXRlclRlbXBDdXIiOiIwIiwiSG90V2F0ZXJUZW1wQ2ZnIjoiMCIsIkhvdFdhdGVyTW9kZSI6IjAiLCJIb3RXYXRlciI6IjAiLCJBV0hQVGVtcENmZ1N3aXRjaCI6IjAiLCJBaXJUZW1wQ29vbE1pbiI6IjAiLCJBaXJUZW1wQ29vbE1heCI6IjAiLCJBaXJUZW1wSGVhdE1pbiI6IjAiLCJBaXJUZW1wSGVhdE1heCI6IjAiLCJXYXRlckluVGVtcEN1ciI6IjAiLCJBV0hQV0FUZW1wQ29udHJvbFN0YSI6IjAiLCJEaXNwbGF5Q29udHJvbCI6IjAiLCJTbWFydENhcmUiOiIwIiwiVHdvU2V0Q29vbFRlbXAiOiIwIiwiVHdvU2V0SGVhdFRlbXAiOiIwIiwiVHdvU2V0Q29vbFVTTCI6IjAiLCJUd29TZXRDb29sTFNMIjoiMCIsIlR3b1NldEhlYXRVU0wiOiIwIiwiVHdvU2V0SGVhdExTTCI6IjAiLCJUd29TZXRBQ09TdGF0ZSI6IjAiLCJUd29TZXRNb2RlRGVhZGJhbmQiOiIwIiwiVHdvU2V0U3RhdGUiOiIwIn0=") }
fn t1_fan_only_low() { base64_decode("eyJPcGVyYXRpb24iOiIxIiwiT3BNb2RlIjoiMiIsIldpbmRTdHJlbmd0aCI6IjIiLCJUZW1wVW5pdCI6Ik5TIiwiVGVtcEN1ciI6IjIxIiwiVGVtcENmZyI6IjI0IiwiR3JvdXBUeXBlIjoiMSIsIlNsZWVwVGltZSI6IjAiLCJPblRpbWUiOiIwIiwiT2ZmVGltZSI6IjAiLCJSYWNBZGRGdW5jIjoiTlMiLCJFeHRyYU9wIjoiMCIsIkRpYWdDb2RlIjoiMDAiLCJUaW1lQnNPbiI6IjAiLCJUaW1lQnNPZmYiOiIwIiwiQWlyQ2xlYW4iOiIwIiwiQXV0b0RyeSI6IjAiLCJQb3dlclNhdmUiOiIwIiwiV0RpclZTdGVwIjoiMCIsIldEaXJIU3RlcCI6IjMiLCJUZW1wTGltaXRNYXgiOiIwIiwiVGVtcExpbWl0TWluIjoiMCIsIkR1Y3Rab25lVHlwZSI6IjAiLCJab25lQ29udHJvbCI6IjAiLCJEUkVEIjoiMCIsIlNlbnNvclBNMSI6IjAiLCJTZW5zb3JQTTIiOiIwIiwiU2Vuc29yUE0xMCI6IjAiLCJBaXJQb2x1dGlvbiI6IjAiLCJIdW1pZGl0eUNmZyI6IjAiLCJXYXRlclRlbXBDb29sTWluIjoiMCIsIldhdGVyVGVtcENvb2xNYXgiOiIwIiwiV2F0ZXJUZW1wSGVhdE1pbiI6IjAiLCJXYXRlclRlbXBIZWF0TWF4IjoiMCIsIkhvdFdhdGVyVGVtcE1pbiI6IjAiLCJIb3RXYXRlclRlbXBNYXgiOiIwIiwiU2Vuc29ySHVtaWRpdHkiOiIwIiwiVG90YWxBaXJQb2x1dGlvbiI6IjAiLCJTZW5zb3JNb24iOiIwIiwiQ2xlYW5EcnkiOiIwIiwiUHJvZHVjdFN0YXR1cyI6IjAiLCJBaXJNb25pdG9yaW5nIjoiMCIsIkh1bWlkaWZpY2F0aW9uIjoiMCIsIkFpckZhc3QiOiIwIiwiQWlyUmVtb3ZhbCI6IjAiLCJBaXJVVkRpc2luZmVjdGlvbiI6IjAiLCJXYXRlcnRhbmtMaWdodCI6IjAiLCJTaWduYWxMaWdodGluZyI6IjAiLCJXRGlyVXBEb3duIjoiMCIsIldEaXJMZWZ0UmlnaHQiOiIwIiwiV1N3aXJsIjoiMCIsIkpldCI6IjAiLCJMb3dIZWF0aW5nIjoiMCIsIkNpcmN1bGF0ZVN0cmVuZ3RoIjoiMCIsIkNpcmN1bGF0ZURpciI6IjAiLCJBbnRpQnVncyI6IjAiLCJJY2VWYWxsZXkiOiIwIiwiSHVtc2F2ZSI6IjAiLCJXYXRlclRlbXBDdXIiOiIwIiwiSG90V2F0ZXJUZW1wQ3VyIjoiMCIsIkhvdFdhdGVyVGVtcENmZyI6IjAiLCJIb3RXYXRlck1vZGUiOiIwIiwiSG90V2F0ZXIiOiIwIiwiQVdIUFRlbXBDZmdTd2l0Y2giOiIwIiwiQWlyVGVtcENvb2xNaW4iOiIwIiwiQWlyVGVtcENvb2xNYXgiOiIwIiwiQWlyVGVtcEhlYXRNaW4iOiIwIiwiQWlyVGVtcEhlYXRNYXgiOiIwIiwiV2F0ZXJJblRlbXBDdXIiOiIwIiwiQVdIUFdBVGVtcENvbnRyb2xTdGEiOiIwIiwiRGlzcGxheUNvbnRyb2wiOiIwIiwiU21hcnRDYXJlIjoiMCIsIlR3b1NldENvb2xUZW1wIjoiMCIsIlR3b1NldEhlYXRUZW1wIjoiMCIsIlR3b1NldENvb2xVU0wiOiIwIiwiVHdvU2V0Q29vbExTTCI6IjAiLCJUd29TZXRIZWF0VVNMIjoiMCIsIlR3b1NldEhlYXRMU0wiOiIwIiwiVHdvU2V0QUNPU3RhdGUiOiIwIiwiVHdvU2V0TW9kZURlYWRiYW5kIjoiMCIsIlR3b1NldFN0YXRlIjoiMCJ9") }
fn t1_dry() { base64_decode("eyJPcGVyYXRpb24iOiIxIiwiT3BNb2RlIjoiMSIsIldpbmRTdHJlbmd0aCI6IjIiLCJUZW1wVW5pdCI6Ik5TIiwiVGVtcEN1ciI6IjE5LjUiLCJUZW1wQ2ZnIjoiMTkiLCJHcm91cFR5cGUiOiIxIiwiU2xlZXBUaW1lIjoiMCIsIk9uVGltZSI6IjAiLCJPZmZUaW1lIjoiMCIsIlJhY0FkZEZ1bmMiOiJOUyIsIkV4dHJhT3AiOiIwIiwiRGlhZ0NvZGUiOiIwMCIsIlRpbWVCc09uIjoiMCIsIlRpbWVCc09mZiI6IjAiLCJBaXJDbGVhbiI6IjAiLCJBdXRvRHJ5IjoiMCIsIlBvd2VyU2F2ZSI6IjAiLCJXRGlyVlN0ZXAiOiIwIiwiV0RpckhTdGVwIjoiMyIsIlRlbXBMaW1pdE1heCI6IjAiLCJUZW1wTGltaXRNaW4iOiIwIiwiRHVjdFpvbmVUeXBlIjoiMCIsIlpvbmVDb250cm9sIjoiMCIsIkRSRUQiOiIwIiwiU2Vuc29yUE0xIjoiMCIsIlNlbnNvclBNMiI6IjAiLCJTZW5zb3JQTTEwIjoiMCIsIkFpclBvbHV0aW9uIjoiMCIsIkh1bWlkaXR5Q2ZnIjoiMCIsIldhdGVyVGVtcENvb2xNaW4iOiIwIiwiV2F0ZXJUZW1wQ29vbE1heCI6IjAiLCJXYXRlclRlbXBIZWF0TWluIjoiMCIsIldhdGVyVGVtcEhlYXRNYXgiOiIwIiwiSG90V2F0ZXJUZW1wTWluIjoiMCIsIkhvdFdhdGVyVGVtcE1heCI6IjAiLCJTZW5zb3JIdW1pZGl0eSI6IjAiLCJUb3RhbEFpclBvbHV0aW9uIjoiMCIsIlNlbnNvck1vbiI6IjAiLCJDbGVhbkRyeSI6IjAiLCJQcm9kdWN0U3RhdHVzIjoiMCIsIkFpck1vbml0b3JpbmciOiIwIiwiSHVtaWRpZmljYXRpb24iOiIwIiwiQWlyRmFzdCI6IjAiLCJBaXJSZW1vdmFsIjoiMCIsIkFpclVWRGlzaW5mZWN0aW9uIjoiMCIsIldhdGVydGFua0xpZ2h0IjoiMCIsIlNpZ25hbExpZ2h0aW5nIjoiMCIsIldEaXJVcERvd24iOiIwIiwiV0RpckxlZnRSaWdodCI6IjAiLCJXU3dpcmwiOiIwIiwiSmV0IjoiMCIsIkxvd0hlYXRpbmciOiIwIiwiQ2lyY3VsYXRlU3RyZW5ndGgiOiIwIiwiQ2lyY3VsYXRlRGlyIjoiMCIsIkFudGlCdWdzIjoiMCIsIkljZVZhbGxleSI6IjAiLCJIdW1zYXZlIjoiMCIsIldhdGVyVGVtcEN1ciI6IjAiLCJIb3RXYXRlclRlbXBDdXIiOiIwIiwiSG90V2F0ZXJUZW1wQ2ZnIjoiMCIsIkhvdFdhdGVyTW9kZSI6IjAiLCJIb3RXYXRlciI6IjAiLCJBV0hQVGVtcENmZ1N3aXRjaCI6IjAiLCJBaXJUZW1wQ29vbE1pbiI6IjAiLCJBaXJUZW1wQ29vbE1heCI6IjAiLCJBaXJUZW1wSGVhdE1pbiI6IjAiLCJBaXJUZW1wSGVhdE1heCI6IjAiLCJXYXRlckluVGVtcEN1ciI6IjAiLCJBV0hQV0FUZW1wQ29udHJvbFN0YSI6IjAiLCJEaXNwbGF5Q29udHJvbCI6IjAiLCJTbWFydENhcmUiOiIwIiwiVHdvU2V0Q29vbFRlbXAiOiIwIiwiVHdvU2V0SGVhdFRlbXAiOiIwIiwiVHdvU2V0Q29vbFVTTCI6IjAiLCJUd29TZXRDb29sTFNMIjoiMCIsIlR3b1NldEhlYXRVU0wiOiIwIiwiVHdvU2V0SGVhdExTTCI6IjAiLCJUd29TZXRBQ09TdGF0ZSI6IjAiLCJUd29TZXRNb2RlRGVhZGJhbmQiOiIwIiwiVHdvU2V0U3RhdGUiOiIwIn0=") }
fn t1_heat() { base64_decode("eyJPcGVyYXRpb24iOiIxIiwiT3BNb2RlIjoiNCIsIldpbmRTdHJlbmd0aCI6IjIiLCJUZW1wVW5pdCI6Ik5TIiwiVGVtcEN1ciI6IjE5LjUiLCJUZW1wQ2ZnIjoiMzAiLCJHcm91cFR5cGUiOiIxIiwiU2xlZXBUaW1lIjoiMCIsIk9uVGltZSI6IjAiLCJPZmZUaW1lIjoiMCIsIlJhY0FkZEZ1bmMiOiJOUyIsIkV4dHJhT3AiOiIwIiwiRGlhZ0NvZGUiOiIwMCIsIlRpbWVCc09uIjoiMCIsIlRpbWVCc09mZiI6IjAiLCJBaXJDbGVhbiI6IjAiLCJBdXRvRHJ5IjoiMCIsIlBvd2VyU2F2ZSI6IjAiLCJXRGlyVlN0ZXAiOiIwIiwiV0RpckhTdGVwIjoiMyIsIlRlbXBMaW1pdE1heCI6IjAiLCJUZW1wTGltaXRNaW4iOiIwIiwiRHVjdFpvbmVUeXBlIjoiMCIsIlpvbmVDb250cm9sIjoiMCIsIkRSRUQiOiIwIiwiU2Vuc29yUE0xIjoiMCIsIlNlbnNvclBNMiI6IjAiLCJTZW5zb3JQTTEwIjoiMCIsIkFpclBvbHV0aW9uIjoiMCIsIkh1bWlkaXR5Q2ZnIjoiMCIsIldhdGVyVGVtcENvb2xNaW4iOiIwIiwiV2F0ZXJUZW1wQ29vbE1heCI6IjAiLCJXYXRlclRlbXBIZWF0TWluIjoiMCIsIldhdGVyVGVtcEhlYXRNYXgiOiIwIiwiSG90V2F0ZXJUZW1wTWluIjoiMCIsIkhvdFdhdGVyVGVtcE1heCI6IjAiLCJTZW5zb3JIdW1pZGl0eSI6IjAiLCJUb3RhbEFpclBvbHV0aW9uIjoiMCIsIlNlbnNvck1vbiI6IjAiLCJDbGVhbkRyeSI6IjAiLCJQcm9kdWN0U3RhdHVzIjoiMCIsIkFpck1vbml0b3JpbmciOiIwIiwiSHVtaWRpZmljYXRpb24iOiIwIiwiQWlyRmFzdCI6IjAiLCJBaXJSZW1vdmFsIjoiMCIsIkFpclVWRGlzaW5mZWN0aW9uIjoiMCIsIldhdGVydGFua0xpZ2h0IjoiMCIsIlNpZ25hbExpZ2h0aW5nIjoiMCIsIldEaXJVcERvd24iOiIwIiwiV0RpckxlZnRSaWdodCI6IjAiLCJXU3dpcmwiOiIwIiwiSmV0IjoiMCIsIkxvd0hlYXRpbmciOiIwIiwiQ2lyY3VsYXRlU3RyZW5ndGgiOiIwIiwiQ2lyY3VsYXRlRGlyIjoiMCIsIkFudGlCdWdzIjoiMCIsIkljZVZhbGxleSI6IjAiLCJIdW1zYXZlIjoiMCIsIldhdGVyVGVtcEN1ciI6IjAiLCJIb3RXYXRlclRlbXBDdXIiOiIwIiwiSG90V2F0ZXJUZW1wQ2ZnIjoiMCIsIkhvdFdhdGVyTW9kZSI6IjAiLCJIb3RXYXRlciI6IjAiLCJBV0hQVGVtcENmZ1N3aXRjaCI6IjAiLCJBaXJUZW1wQ29vbE1pbiI6IjAiLCJBaXJUZW1wQ29vbE1heCI6IjAiLCJBaXJUZW1wSGVhdE1pbiI6IjAiLCJBaXJUZW1wSGVhdE1heCI6IjAiLCJXYXRlckluVGVtcEN1ciI6IjAiLCJBV0hQV0FUZW1wQ29udHJvbFN0YSI6IjAiLCJEaXNwbGF5Q29udHJvbCI6IjAiLCJTbWFydENhcmUiOiIwIiwiVHdvU2V0Q29vbFRlbXAiOiIwIiwiVHdvU2V0SGVhdFRlbXAiOiIwIiwiVHdvU2V0Q29vbFVTTCI6IjAiLCJUd29TZXRDb29sTFNMIjoiMCIsIlR3b1NldEhlYXRVU0wiOiIwIiwiVHdvU2V0SGVhdExTTCI6IjAiLCJUd29TZXRBQ09TdGF0ZSI6IjAiLCJUd29TZXRNb2RlRGVhZGJhbmQiOiIwIiwiVHdvU2V0U3RhdGUiOiIwIn0=") }
fn t1_auto() { base64_decode("eyJPcGVyYXRpb24iOiIxIiwiT3BNb2RlIjoiNiIsIldpbmRTdHJlbmd0aCI6IjIiLCJUZW1wVW5pdCI6Ik5TIiwiVGVtcEN1ciI6IjE5LjUiLCJUZW1wQ2ZnIjoiMjIiLCJHcm91cFR5cGUiOiIxIiwiU2xlZXBUaW1lIjoiMCIsIk9uVGltZSI6IjAiLCJPZmZUaW1lIjoiMCIsIlJhY0FkZEZ1bmMiOiJOUyIsIkV4dHJhT3AiOiIwIiwiRGlhZ0NvZGUiOiIwMCIsIlRpbWVCc09uIjoiMCIsIlRpbWVCc09mZiI6IjAiLCJBaXJDbGVhbiI6IjAiLCJBdXRvRHJ5IjoiMCIsIlBvd2VyU2F2ZSI6IjAiLCJXRGlyVlN0ZXAiOiIwIiwiV0RpckhTdGVwIjoiMyIsIlRlbXBMaW1pdE1heCI6IjAiLCJUZW1wTGltaXRNaW4iOiIwIiwiRHVjdFpvbmVUeXBlIjoiMCIsIlpvbmVDb250cm9sIjoiMCIsIkRSRUQiOiIwIiwiU2Vuc29yUE0xIjoiMCIsIlNlbnNvclBNMiI6IjAiLCJTZW5zb3JQTTEwIjoiMCIsIkFpclBvbHV0aW9uIjoiMCIsIkh1bWlkaXR5Q2ZnIjoiMCIsIldhdGVyVGVtcENvb2xNaW4iOiIwIiwiV2F0ZXJUZW1wQ29vbE1heCI6IjAiLCJXYXRlclRlbXBIZWF0TWluIjoiMCIsIldhdGVyVGVtcEhlYXRNYXgiOiIwIiwiSG90V2F0ZXJUZW1wTWluIjoiMCIsIkhvdFdhdGVyVGVtcE1heCI6IjAiLCJTZW5zb3JIdW1pZGl0eSI6IjAiLCJUb3RhbEFpclBvbHV0aW9uIjoiMCIsIlNlbnNvck1vbiI6IjAiLCJDbGVhbkRyeSI6IjAiLCJQcm9kdWN0U3RhdHVzIjoiMCIsIkFpck1vbml0b3JpbmciOiIwIiwiSHVtaWRpZmljYXRpb24iOiIwIiwiQWlyRmFzdCI6IjAiLCJBaXJSZW1vdmFsIjoiMCIsIkFpclVWRGlzaW5mZWN0aW9uIjoiMCIsIldhdGVydGFua0xpZ2h0IjoiMCIsIlNpZ25hbExpZ2h0aW5nIjoiMCIsIldEaXJVcERvd24iOiIwIiwiV0RpckxlZnRSaWdodCI6IjAiLCJXU3dpcmwiOiIwIiwiSmV0IjoiMCIsIkxvd0hlYXRpbmciOiIwIiwiQ2lyY3VsYXRlU3RyZW5ndGgiOiIwIiwiQ2lyY3VsYXRlRGlyIjoiMCIsIkFudGlCdWdzIjoiMCIsIkljZVZhbGxleSI6IjAiLCJIdW1zYXZlIjoiMCIsIldhdGVyVGVtcEN1ciI6IjAiLCJIb3RXYXRlclRlbXBDdXIiOiIwIiwiSG90V2F0ZXJUZW1wQ2ZnIjoiMCIsIkhvdFdhdGVyTW9kZSI6IjAiLCJIb3RXYXRlciI6IjAiLCJBV0hQVGVtcENmZ1N3aXRjaCI6IjAiLCJBaXJUZW1wQ29vbE1pbiI6IjAiLCJBaXJUZW1wQ29vbE1heCI6IjAiLCJBaXJUZW1wSGVhdE1pbiI6IjAiLCJBaXJUZW1wSGVhdE1heCI6IjAiLCJXYXRlckluVGVtcEN1ciI6IjAiLCJBV0hQV0FUZW1wQ29udHJvbFN0YSI6IjAiLCJEaXNwbGF5Q29udHJvbCI6IjAiLCJTbWFydENhcmUiOiIwIiwiVHdvU2V0Q29vbFRlbXAiOiIwIiwiVHdvU2V0SGVhdFRlbXAiOiIwIiwiVHdvU2V0Q29vbFVTTCI6IjAiLCJUd29TZXRDb29sTFNMIjoiMCIsIlR3b1NldEhlYXRVU0wiOiIwIiwiVHdvU2V0SGVhdExTTCI6IjAiLCJUd29TZXRBQ09TdGF0ZSI6IjAiLCJUd29TZXRNb2RlRGVhZGJhbmQiOiIwIiwiVHdvU2V0U3RhdGUiOiIwIn0=") }
fn t1_fan_auto() { base64_decode("eyJPcGVyYXRpb24iOiIxIiwiT3BNb2RlIjoiMiIsIldpbmRTdHJlbmd0aCI6IjgiLCJUZW1wVW5pdCI6Ik5TIiwiVGVtcEN1ciI6IjE5LjUiLCJUZW1wQ2ZnIjoiMjQiLCJHcm91cFR5cGUiOiIxIiwiU2xlZXBUaW1lIjoiMCIsIk9uVGltZSI6IjAiLCJPZmZUaW1lIjoiMCIsIlJhY0FkZEZ1bmMiOiJOUyIsIkV4dHJhT3AiOiIwIiwiRGlhZ0NvZGUiOiIwMCIsIlRpbWVCc09uIjoiMCIsIlRpbWVCc09mZiI6IjAiLCJBaXJDbGVhbiI6IjAiLCJBdXRvRHJ5IjoiMCIsIlBvd2VyU2F2ZSI6IjAiLCJXRGlyVlN0ZXAiOiIwIiwiV0RpckhTdGVwIjoiMyIsIlRlbXBMaW1pdE1heCI6IjAiLCJUZW1wTGltaXRNaW4iOiIwIiwiRHVjdFpvbmVUeXBlIjoiMCIsIlpvbmVDb250cm9sIjoiMCIsIkRSRUQiOiIwIiwiU2Vuc29yUE0xIjoiMCIsIlNlbnNvclBNMiI6IjAiLCJTZW5zb3JQTTEwIjoiMCIsIkFpclBvbHV0aW9uIjoiMCIsIkh1bWlkaXR5Q2ZnIjoiMCIsIldhdGVyVGVtcENvb2xNaW4iOiIwIiwiV2F0ZXJUZW1wQ29vbE1heCI6IjAiLCJXYXRlclRlbXBIZWF0TWluIjoiMCIsIldhdGVyVGVtcEhlYXRNYXgiOiIwIiwiSG90V2F0ZXJUZW1wTWluIjoiMCIsIkhvdFdhdGVyVGVtcE1heCI6IjAiLCJTZW5zb3JIdW1pZGl0eSI6IjAiLCJUb3RhbEFpclBvbHV0aW9uIjoiMCIsIlNlbnNvck1vbiI6IjAiLCJDbGVhbkRyeSI6IjAiLCJQcm9kdWN0U3RhdHVzIjoiMCIsIkFpck1vbml0b3JpbmciOiIwIiwiSHVtaWRpZmljYXRpb24iOiIwIiwiQWlyRmFzdCI6IjAiLCJBaXJSZW1vdmFsIjoiMCIsIkFpclVWRGlzaW5mZWN0aW9uIjoiMCIsIldhdGVydGFua0xpZ2h0IjoiMCIsIlNpZ25hbExpZ2h0aW5nIjoiMCIsIldEaXJVcERvd24iOiIwIiwiV0RpckxlZnRSaWdodCI6IjAiLCJXU3dpcmwiOiIwIiwiSmV0IjoiMCIsIkxvd0hlYXRpbmciOiIwIiwiQ2lyY3VsYXRlU3RyZW5ndGgiOiIwIiwiQ2lyY3VsYXRlRGlyIjoiMCIsIkFudGlCdWdzIjoiMCIsIkljZVZhbGxleSI6IjAiLCJIdW1zYXZlIjoiMCIsIldhdGVyVGVtcEN1ciI6IjAiLCJIb3RXYXRlclRlbXBDdXIiOiIwIiwiSG90V2F0ZXJUZW1wQ2ZnIjoiMCIsIkhvdFdhdGVyTW9kZSI6IjAiLCJIb3RXYXRlciI6IjAiLCJBV0hQVGVtcENmZ1N3aXRjaCI6IjAiLCJBaXJUZW1wQ29vbE1pbiI6IjAiLCJBaXJUZW1wQ29vbE1heCI6IjAiLCJBaXJUZW1wSGVhdE1pbiI6IjAiLCJBaXJUZW1wSGVhdE1heCI6IjAiLCJXYXRlckluVGVtcEN1ciI6IjAiLCJBV0hQV0FUZW1wQ29udHJvbFN0YSI6IjAiLCJEaXNwbGF5Q29udHJvbCI6IjAiLCJTbWFydENhcmUiOiIwIiwiVHdvU2V0Q29vbFRlbXAiOiIwIiwiVHdvU2V0SGVhdFRlbXAiOiIwIiwiVHdvU2V0Q29vbFVTTCI6IjAiLCJUd29TZXRDb29sTFNMIjoiMCIsIlR3b1NldEhlYXRVU0wiOiIwIiwiVHdvU2V0SGVhdExTTCI6IjAiLCJUd29TZXRBQ09TdGF0ZSI6IjAiLCJUd29TZXRNb2RlRGVhZGJhbmQiOiIwIiwiVHdvU2V0U3RhdGUiOiIwIn0=") }
fn t1_vswing_on() { base64_decode("eyJPcGVyYXRpb24iOiIxIiwiT3BNb2RlIjoiMiIsIldpbmRTdHJlbmd0aCI6IjIiLCJUZW1wVW5pdCI6Ik5TIiwiVGVtcEN1ciI6IjIxIiwiVGVtcENmZyI6IjI0IiwiR3JvdXBUeXBlIjoiMSIsIlNsZWVwVGltZSI6IjAiLCJPblRpbWUiOiIwIiwiT2ZmVGltZSI6IjAiLCJSYWNBZGRGdW5jIjoiTlMiLCJFeHRyYU9wIjoiMCIsIkRpYWdDb2RlIjoiMDAiLCJUaW1lQnNPbiI6IjAiLCJUaW1lQnNPZmYiOiIwIiwiQWlyQ2xlYW4iOiIwIiwiQXV0b0RyeSI6IjAiLCJQb3dlclNhdmUiOiIwIiwiV0RpclZTdGVwIjoiMTAwIiwiV0RpckhTdGVwIjoiMyIsIlRlbXBMaW1pdE1heCI6IjAiLCJUZW1wTGltaXRNaW4iOiIwIiwiRHVjdFpvbmVUeXBlIjoiMCIsIlpvbmVDb250cm9sIjoiMCIsIkRSRUQiOiIwIiwiU2Vuc29yUE0xIjoiMCIsIlNlbnNvclBNMiI6IjAiLCJTZW5zb3JQTTEwIjoiMCIsIkFpclBvbHV0aW9uIjoiMCIsIkh1bWlkaXR5Q2ZnIjoiMCIsIldhdGVyVGVtcENvb2xNaW4iOiIwIiwiV2F0ZXJUZW1wQ29vbE1heCI6IjAiLCJXYXRlclRlbXBIZWF0TWluIjoiMCIsIldhdGVyVGVtcEhlYXRNYXgiOiIwIiwiSG90V2F0ZXJUZW1wTWluIjoiMCIsIkhvdFdhdGVyVGVtcE1heCI6IjAiLCJTZW5zb3JIdW1pZGl0eSI6IjAiLCJUb3RhbEFpclBvbHV0aW9uIjoiMCIsIlNlbnNvck1vbiI6IjAiLCJDbGVhbkRyeSI6IjAiLCJQcm9kdWN0U3RhdHVzIjoiMCIsIkFpck1vbml0b3JpbmciOiIwIiwiSHVtaWRpZmljYXRpb24iOiIwIiwiQWlyRmFzdCI6IjAiLCJBaXJSZW1vdmFsIjoiMCIsIkFpclVWRGlzaW5mZWN0aW9uIjoiMCIsIldhdGVydGFua0xpZ2h0IjoiMCIsIlNpZ25hbExpZ2h0aW5nIjoiMCIsIldEaXJVcERvd24iOiIwIiwiV0RpckxlZnRSaWdodCI6IjAiLCJXU3dpcmwiOiIwIiwiSmV0IjoiMCIsIkxvd0hlYXRpbmciOiIwIiwiQ2lyY3VsYXRlU3RyZW5ndGgiOiIwIiwiQ2lyY3VsYXRlRGlyIjoiMCIsIkFudGlCdWdzIjoiMCIsIkljZVZhbGxleSI6IjAiLCJIdW1zYXZlIjoiMCIsIldhdGVyVGVtcEN1ciI6IjAiLCJIb3RXYXRlclRlbXBDdXIiOiIwIiwiSG90V2F0ZXJUZW1wQ2ZnIjoiMCIsIkhvdFdhdGVyTW9kZSI6IjAiLCJIb3RXYXRlciI6IjAiLCJBV0hQVGVtcENmZ1N3aXRjaCI6IjAiLCJBaXJUZW1wQ29vbE1pbiI6IjAiLCJBaXJUZW1wQ29vbE1heCI6IjAiLCJBaXJUZW1wSGVhdE1pbiI6IjAiLCJBaXJUZW1wSGVhdE1heCI6IjAiLCJXYXRlckluVGVtcEN1ciI6IjAiLCJBV0hQV0FUZW1wQ29udHJvbFN0YSI6IjAiLCJEaXNwbGF5Q29udHJvbCI6IjAiLCJTbWFydENhcmUiOiIwIiwiVHdvU2V0Q29vbFRlbXAiOiIwIiwiVHdvU2V0SGVhdFRlbXAiOiIwIiwiVHdvU2V0Q29vbFVTTCI6IjAiLCJUd29TZXRDb29sTFNMIjoiMCIsIlR3b1NldEhlYXRVU0wiOiIwIiwiVHdvU2V0SGVhdExTTCI6IjAiLCJUd29TZXRBQ09TdGF0ZSI6IjAiLCJUd29TZXRNb2RlRGVhZGJhbmQiOiIwIiwiVHdvU2V0U3RhdGUiOiIwIn0=") }
fn t1_vswing_step1() { base64_decode("eyJPcGVyYXRpb24iOiIxIiwiT3BNb2RlIjoiMiIsIldpbmRTdHJlbmd0aCI6IjIiLCJUZW1wVW5pdCI6Ik5TIiwiVGVtcEN1ciI6IjE5LjUiLCJUZW1wQ2ZnIjoiMjMiLCJHcm91cFR5cGUiOiIxIiwiU2xlZXBUaW1lIjoiMCIsIk9uVGltZSI6IjAiLCJPZmZUaW1lIjoiMCIsIlJhY0FkZEZ1bmMiOiJOUyIsIkV4dHJhT3AiOiIwIiwiRGlhZ0NvZGUiOiIwMCIsIlRpbWVCc09uIjoiMCIsIlRpbWVCc09mZiI6IjAiLCJBaXJDbGVhbiI6IjAiLCJBdXRvRHJ5IjoiMCIsIlBvd2VyU2F2ZSI6IjAiLCJXRGlyVlN0ZXAiOiIxIiwiV0RpckhTdGVwIjoiMyIsIlRlbXBMaW1pdE1heCI6IjAiLCJUZW1wTGltaXRNaW4iOiIwIiwiRHVjdFpvbmVUeXBlIjoiMCIsIlpvbmVDb250cm9sIjoiMCIsIkRSRUQiOiIwIiwiU2Vuc29yUE0xIjoiMCIsIlNlbnNvclBNMiI6IjAiLCJTZW5zb3JQTTEwIjoiMCIsIkFpclBvbHV0aW9uIjoiMCIsIkh1bWlkaXR5Q2ZnIjoiMCIsIldhdGVyVGVtcENvb2xNaW4iOiIwIiwiV2F0ZXJUZW1wQ29vbE1heCI6IjAiLCJXYXRlclRlbXBIZWF0TWluIjoiMCIsIldhdGVyVGVtcEhlYXRNYXgiOiIwIiwiSG90V2F0ZXJUZW1wTWluIjoiMCIsIkhvdFdhdGVyVGVtcE1heCI6IjAiLCJTZW5zb3JIdW1pZGl0eSI6IjAiLCJUb3RhbEFpclBvbHV0aW9uIjoiMCIsIlNlbnNvck1vbiI6IjAiLCJDbGVhbkRyeSI6IjAiLCJQcm9kdWN0U3RhdHVzIjoiMCIsIkFpck1vbml0b3JpbmciOiIwIiwiSHVtaWRpZmljYXRpb24iOiIwIiwiQWlyRmFzdCI6IjAiLCJBaXJSZW1vdmFsIjoiMCIsIkFpclVWRGlzaW5mZWN0aW9uIjoiMCIsIldhdGVydGFua0xpZ2h0IjoiMCIsIlNpZ25hbExpZ2h0aW5nIjoiMCIsIldEaXJVcERvd24iOiIwIiwiV0RpckxlZnRSaWdodCI6IjAiLCJXU3dpcmwiOiIwIiwiSmV0IjoiMCIsIkxvd0hlYXRpbmciOiIwIiwiQ2lyY3VsYXRlU3RyZW5ndGgiOiIwIiwiQ2lyY3VsYXRlRGlyIjoiMCIsIkFudGlCdWdzIjoiMCIsIkljZVZhbGxleSI6IjAiLCJIdW1zYXZlIjoiMCIsIldhdGVyVGVtcEN1ciI6IjAiLCJIb3RXYXRlclRlbXBDdXIiOiIwIiwiSG90V2F0ZXJUZW1wQ2ZnIjoiMCIsIkhvdFdhdGVyTW9kZSI6IjAiLCJIb3RXYXRlciI6IjAiLCJBV0hQVGVtcENmZ1N3aXRjaCI6IjAiLCJBaXJUZW1wQ29vbE1pbiI6IjAiLCJBaXJUZW1wQ29vbE1heCI6IjAiLCJBaXJUZW1wSGVhdE1pbiI6IjAiLCJBaXJUZW1wSGVhdE1heCI6IjAiLCJXYXRlckluVGVtcEN1ciI6IjAiLCJBV0hQV0FUZW1wQ29udHJvbFN0YSI6IjAiLCJEaXNwbGF5Q29udHJvbCI6IjAiLCJTbWFydENhcmUiOiIwIiwiVHdvU2V0Q29vbFRlbXAiOiIwIiwiVHdvU2V0SGVhdFRlbXAiOiIwIiwiVHdvU2V0Q29vbFVTTCI6IjAiLCJUd29TZXRDb29sTFNMIjoiMCIsIlR3b1NldEhlYXRVU0wiOiIwIiwiVHdvU2V0SGVhdExTTCI6IjAiLCJUd29TZXRBQ09TdGF0ZSI6IjAiLCJUd29TZXRNb2RlRGVhZGJhbmQiOiIwIiwiVHdvU2V0U3RhdGUiOiIwIn0=") }
fn t1_hswing_step4() { base64_decode("eyJPcGVyYXRpb24iOiIxIiwiT3BNb2RlIjoiMiIsIldpbmRTdHJlbmd0aCI6IjIiLCJUZW1wVW5pdCI6Ik5TIiwiVGVtcEN1ciI6IjE5LjUiLCJUZW1wQ2ZnIjoiMjMiLCJHcm91cFR5cGUiOiIxIiwiU2xlZXBUaW1lIjoiMCIsIk9uVGltZSI6IjAiLCJPZmZUaW1lIjoiMCIsIlJhY0FkZEZ1bmMiOiJOUyIsIkV4dHJhT3AiOiIwIiwiRGlhZ0NvZGUiOiIwMCIsIlRpbWVCc09uIjoiMCIsIlRpbWVCc09mZiI6IjAiLCJBaXJDbGVhbiI6IjAiLCJBdXRvRHJ5IjoiMCIsIlBvd2VyU2F2ZSI6IjAiLCJXRGlyVlN0ZXAiOiIwIiwiV0RpckhTdGVwIjoiNCIsIlRlbXBMaW1pdE1heCI6IjAiLCJUZW1wTGltaXRNaW4iOiIwIiwiRHVjdFpvbmVUeXBlIjoiMCIsIlpvbmVDb250cm9sIjoiMCIsIkRSRUQiOiIwIiwiU2Vuc29yUE0xIjoiMCIsIlNlbnNvclBNMiI6IjAiLCJTZW5zb3JQTTEwIjoiMCIsIkFpclBvbHV0aW9uIjoiMCIsIkh1bWlkaXR5Q2ZnIjoiMCIsIldhdGVyVGVtcENvb2xNaW4iOiIwIiwiV2F0ZXJUZW1wQ29vbE1heCI6IjAiLCJXYXRlclRlbXBIZWF0TWluIjoiMCIsIldhdGVyVGVtcEhlYXRNYXgiOiIwIiwiSG90V2F0ZXJUZW1wTWluIjoiMCIsIkhvdFdhdGVyVGVtcE1heCI6IjAiLCJTZW5zb3JIdW1pZGl0eSI6IjAiLCJUb3RhbEFpclBvbHV0aW9uIjoiMCIsIlNlbnNvck1vbiI6IjAiLCJDbGVhbkRyeSI6IjAiLCJQcm9kdWN0U3RhdHVzIjoiMCIsIkFpck1vbml0b3JpbmciOiIwIiwiSHVtaWRpZmljYXRpb24iOiIwIiwiQWlyRmFzdCI6IjAiLCJBaXJSZW1vdmFsIjoiMCIsIkFpclVWRGlzaW5mZWN0aW9uIjoiMCIsIldhdGVydGFua0xpZ2h0IjoiMCIsIlNpZ25hbExpZ2h0aW5nIjoiMCIsIldEaXJVcERvd24iOiIwIiwiV0RpckxlZnRSaWdodCI6IjAiLCJXU3dpcmwiOiIwIiwiSmV0IjoiMCIsIkxvd0hlYXRpbmciOiIwIiwiQ2lyY3VsYXRlU3RyZW5ndGgiOiIwIiwiQ2lyY3VsYXRlRGlyIjoiMCIsIkFudGlCdWdzIjoiMCIsIkljZVZhbGxleSI6IjAiLCJIdW1zYXZlIjoiMCIsIldhdGVyVGVtcEN1ciI6IjAiLCJIb3RXYXRlclRlbXBDdXIiOiIwIiwiSG90V2F0ZXJUZW1wQ2ZnIjoiMCIsIkhvdFdhdGVyTW9kZSI6IjAiLCJIb3RXYXRlciI6IjAiLCJBV0hQVGVtcENmZ1N3aXRjaCI6IjAiLCJBaXJUZW1wQ29vbE1pbiI6IjAiLCJBaXJUZW1wQ29vbE1heCI6IjAiLCJBaXJUZW1wSGVhdE1pbiI6IjAiLCJBaXJUZW1wSGVhdE1heCI6IjAiLCJXYXRlckluVGVtcEN1ciI6IjAiLCJBV0hQV0FUZW1wQ29udHJvbFN0YSI6IjAiLCJEaXNwbGF5Q29udHJvbCI6IjAiLCJTbWFydENhcmUiOiIwIiwiVHdvU2V0Q29vbFRlbXAiOiIwIiwiVHdvU2V0SGVhdFRlbXAiOiIwIiwiVHdvU2V0Q29vbFVTTCI6IjAiLCJUd29TZXRDb29sTFNMIjoiMCIsIlR3b1NldEhlYXRVU0wiOiIwIiwiVHdvU2V0SGVhdExTTCI6IjAiLCJUd29TZXRBQ09TdGF0ZSI6IjAiLCJUd29TZXRNb2RlRGVhZGJhbmQiOiIwIiwiVHdvU2V0U3RhdGUiOiIwIn0=") }
fn t1_jet_on() { base64_decode("eyJPcGVyYXRpb24iOiIxIiwiT3BNb2RlIjoiMCIsIldpbmRTdHJlbmd0aCI6IjYiLCJUZW1wVW5pdCI6Ik5TIiwiVGVtcEN1ciI6IjI2IiwiVGVtcENmZyI6IjE4IiwiR3JvdXBUeXBlIjoiMSIsIlNsZWVwVGltZSI6IjAiLCJPblRpbWUiOiIwIiwiT2ZmVGltZSI6IjAiLCJSYWNBZGRGdW5jIjoiTlMiLCJFeHRyYU9wIjoiMCIsIkRpYWdDb2RlIjoiMDAiLCJUaW1lQnNPbiI6IjAiLCJUaW1lQnNPZmYiOiIwIiwiQWlyQ2xlYW4iOiIwIiwiQXV0b0RyeSI6IjAiLCJQb3dlclNhdmUiOiIwIiwiV0RpclZTdGVwIjoiMCIsIldEaXJIU3RlcCI6IjMiLCJUZW1wTGltaXRNYXgiOiIwIiwiVGVtcExpbWl0TWluIjoiMCIsIkR1Y3Rab25lVHlwZSI6IjAiLCJab25lQ29udHJvbCI6IjAiLCJEUkVEIjoiMCIsIlNlbnNvclBNMSI6IjAiLCJTZW5zb3JQTTIiOiIwIiwiU2Vuc29yUE0xMCI6IjAiLCJBaXJQb2x1dGlvbiI6IjAiLCJIdW1pZGl0eUNmZyI6IjAiLCJXYXRlclRlbXBDb29sTWluIjoiMCIsIldhdGVyVGVtcENvb2xNYXgiOiIwIiwiV2F0ZXJUZW1wSGVhdE1pbiI6IjAiLCJXYXRlclRlbXBIZWF0TWF4IjoiMCIsIkhvdFdhdGVyVGVtcE1pbiI6IjAiLCJIb3RXYXRlclRlbXBNYXgiOiIwIiwiU2Vuc29ySHVtaWRpdHkiOiIwIiwiVG90YWxBaXJQb2x1dGlvbiI6IjAiLCJTZW5zb3JNb24iOiIwIiwiQ2xlYW5EcnkiOiIwIiwiUHJvZHVjdFN0YXR1cyI6IjAiLCJBaXJNb25pdG9yaW5nIjoiMCIsIkh1bWlkaWZpY2F0aW9uIjoiMCIsIkFpckZhc3QiOiIwIiwiQWlyUmVtb3ZhbCI6IjAiLCJBaXJVVkRpc2luZmVjdGlvbiI6IjAiLCJXYXRlcnRhbmtMaWdodCI6IjAiLCJTaWduYWxMaWdodGluZyI6IjAiLCJXRGlyVXBEb3duIjoiMCIsIldEaXJMZWZ0UmlnaHQiOiIwIiwiV1N3aXJsIjoiMCIsIkpldCI6IjEiLCJMb3dIZWF0aW5nIjoiMCIsIkNpcmN1bGF0ZVN0cmVuZ3RoIjoiMCIsIkNpcmN1bGF0ZURpciI6IjAiLCJBbnRpQnVncyI6IjAiLCJJY2VWYWxsZXkiOiIwIiwiSHVtc2F2ZSI6IjAiLCJXYXRlclRlbXBDdXIiOiIwIiwiSG90V2F0ZXJUZW1wQ3VyIjoiMCIsIkhvdFdhdGVyVGVtcENmZyI6IjAiLCJIb3RXYXRlck1vZGUiOiIwIiwiSG90V2F0ZXIiOiIwIiwiQVdIUFRlbXBDZmdTd2l0Y2giOiIwIiwiQWlyVGVtcENvb2xNaW4iOiIwIiwiQWlyVGVtcENvb2xNYXgiOiIwIiwiQWlyVGVtcEhlYXRNaW4iOiIwIiwiQWlyVGVtcEhlYXRNYXgiOiIwIiwiV2F0ZXJJblRlbXBDdXIiOiIwIiwiQVdIUFdBVGVtcENvbnRyb2xTdGEiOiIwIiwiRGlzcGxheUNvbnRyb2wiOiIwIiwiU21hcnRDYXJlIjoiMCIsIlR3b1NldENvb2xUZW1wIjoiMCIsIlR3b1NldEhlYXRUZW1wIjoiMCIsIlR3b1NldENvb2xVU0wiOiIwIiwiVHdvU2V0Q29vbExTTCI6IjAiLCJUd29TZXRIZWF0VVNMIjoiMCIsIlR3b1NldEhlYXRMU0wiOiIwIiwiVHdvU2V0QUNPU3RhdGUiOiIwIiwiVHdvU2V0TW9kZURlYWRiYW5kIjoiMCIsIlR3b1NldFN0YXRlIjoiMCJ9") }
fn t1_airclean_on() { base64_decode("eyJPcGVyYXRpb24iOiIxIiwiT3BNb2RlIjoiMCIsIldpbmRTdHJlbmd0aCI6IjYiLCJUZW1wVW5pdCI6Ik5TIiwiVGVtcEN1ciI6IjI1LjUiLCJUZW1wQ2ZnIjoiMTgiLCJHcm91cFR5cGUiOiIxIiwiU2xlZXBUaW1lIjoiMCIsIk9uVGltZSI6IjAiLCJPZmZUaW1lIjoiMCIsIlJhY0FkZEZ1bmMiOiJOUyIsIkV4dHJhT3AiOiIwIiwiRGlhZ0NvZGUiOiIwMCIsIlRpbWVCc09uIjoiMCIsIlRpbWVCc09mZiI6IjAiLCJBaXJDbGVhbiI6IjEiLCJBdXRvRHJ5IjoiMCIsIlBvd2VyU2F2ZSI6IjAiLCJXRGlyVlN0ZXAiOiIwIiwiV0RpckhTdGVwIjoiMyIsIlRlbXBMaW1pdE1heCI6IjAiLCJUZW1wTGltaXRNaW4iOiIwIiwiRHVjdFpvbmVUeXBlIjoiMCIsIlpvbmVDb250cm9sIjoiMCIsIkRSRUQiOiIwIiwiU2Vuc29yUE0xIjoiMCIsIlNlbnNvclBNMiI6IjAiLCJTZW5zb3JQTTEwIjoiMCIsIkFpclBvbHV0aW9uIjoiMCIsIkh1bWlkaXR5Q2ZnIjoiMCIsIldhdGVyVGVtcENvb2xNaW4iOiIwIiwiV2F0ZXJUZW1wQ29vbE1heCI6IjAiLCJXYXRlclRlbXBIZWF0TWluIjoiMCIsIldhdGVyVGVtcEhlYXRNYXgiOiIwIiwiSG90V2F0ZXJUZW1wTWluIjoiMCIsIkhvdFdhdGVyVGVtcE1heCI6IjAiLCJTZW5zb3JIdW1pZGl0eSI6IjAiLCJUb3RhbEFpclBvbHV0aW9uIjoiMCIsIlNlbnNvck1vbiI6IjAiLCJDbGVhbkRyeSI6IjAiLCJQcm9kdWN0U3RhdHVzIjoiMCIsIkFpck1vbml0b3JpbmciOiIwIiwiSHVtaWRpZmljYXRpb24iOiIwIiwiQWlyRmFzdCI6IjAiLCJBaXJSZW1vdmFsIjoiMCIsIkFpclVWRGlzaW5mZWN0aW9uIjoiMCIsIldhdGVydGFua0xpZ2h0IjoiMCIsIlNpZ25hbExpZ2h0aW5nIjoiMCIsIldEaXJVcERvd24iOiIwIiwiV0RpckxlZnRSaWdodCI6IjAiLCJXU3dpcmwiOiIwIiwiSmV0IjoiMSIsIkxvd0hlYXRpbmciOiIwIiwiQ2lyY3VsYXRlU3RyZW5ndGgiOiIwIiwiQ2lyY3VsYXRlRGlyIjoiMCIsIkFudGlCdWdzIjoiMCIsIkljZVZhbGxleSI6IjAiLCJIdW1zYXZlIjoiMCIsIldhdGVyVGVtcEN1ciI6IjAiLCJIb3RXYXRlclRlbXBDdXIiOiIwIiwiSG90V2F0ZXJUZW1wQ2ZnIjoiMCIsIkhvdFdhdGVyTW9kZSI6IjAiLCJIb3RXYXRlciI6IjAiLCJBV0hQVGVtcENmZ1N3aXRjaCI6IjAiLCJBaXJUZW1wQ29vbE1pbiI6IjAiLCJBaXJUZW1wQ29vbE1heCI6IjAiLCJBaXJUZW1wSGVhdE1pbiI6IjAiLCJBaXJUZW1wSGVhdE1heCI6IjAiLCJXYXRlckluVGVtcEN1ciI6IjAiLCJBV0hQV0FUZW1wQ29udHJvbFN0YSI6IjAiLCJEaXNwbGF5Q29udHJvbCI6IjAiLCJTbWFydENhcmUiOiIwIiwiVHdvU2V0Q29vbFRlbXAiOiIwIiwiVHdvU2V0SGVhdFRlbXAiOiIwIiwiVHdvU2V0Q29vbFVTTCI6IjAiLCJUd29TZXRDb29sTFNMIjoiMCIsIlR3b1NldEhlYXRVU0wiOiIwIiwiVHdvU2V0SGVhdExTTCI6IjAiLCJUd29TZXRBQ09TdGF0ZSI6IjAiLCJUd29TZXRNb2RlRGVhZGJhbmQiOiIwIiwiVHdvU2V0U3RhdGUiOiIwIn0=") }
fn t1_placeholder() { base64_decode("eyJPcGVyYXRpb24iOiIwIiwiT3BNb2RlIjoiMCIsIldpbmRTdHJlbmd0aCI6IjAiLCJUZW1wVW5pdCI6Ik5TIiwiVGVtcEN1ciI6IjAiLCJUZW1wQ2ZnIjoiMCIsIkdyb3VwVHlwZSI6IjEiLCJTbGVlcFRpbWUiOiIwIiwiT25UaW1lIjoiMCIsIk9mZlRpbWUiOiIwIiwiUmFjQWRkRnVuYyI6Ik5TIiwiRXh0cmFPcCI6IjAiLCJEaWFnQ29kZSI6IjAwIiwiVGltZUJzT24iOiIwIiwiVGltZUJzT2ZmIjoiMCIsIkFpckNsZWFuIjoiMCIsIkF1dG9EcnkiOiIwIiwiUG93ZXJTYXZlIjoiMCIsIldEaXJWU3RlcCI6IjAiLCJXRGlySFN0ZXAiOiIwIiwiVGVtcExpbWl0TWF4IjoiMCIsIlRlbXBMaW1pdE1pbiI6IjAiLCJEdWN0Wm9uZVR5cGUiOiIwIiwiWm9uZUNvbnRyb2wiOiIwIiwiRFJFRCI6IjAiLCJTZW5zb3JQTTEiOiIwIiwiU2Vuc29yUE0yIjoiMCIsIlNlbnNvclBNMTAiOiIwIiwiQWlyUG9sdXRpb24iOiIwIiwiSHVtaWRpdHlDZmciOiIwIiwiV2F0ZXJUZW1wQ29vbE1pbiI6IjAiLCJXYXRlclRlbXBDb29sTWF4IjoiMCIsIldhdGVyVGVtcEhlYXRNaW4iOiIwIiwiV2F0ZXJUZW1wSGVhdE1heCI6IjAiLCJIb3RXYXRlclRlbXBNaW4iOiIwIiwiSG90V2F0ZXJUZW1wTWF4IjoiMCIsIlNlbnNvckh1bWlkaXR5IjoiMCIsIlRvdGFsQWlyUG9sdXRpb24iOiIwIiwiU2Vuc29yTW9uIjoiMCIsIkNsZWFuRHJ5IjoiMCIsIlByb2R1Y3RTdGF0dXMiOiIwIiwiQWlyTW9uaXRvcmluZyI6IjAiLCJIdW1pZGlmaWNhdGlvbiI6IjAiLCJBaXJGYXN0IjoiMCIsIkFpclJlbW92YWwiOiIwIiwiQWlyVVZEaXNpbmZlY3Rpb24iOiIwIiwiV2F0ZXJ0YW5rTGlnaHQiOiIwIiwiU2lnbmFsTGlnaHRpbmciOiIwIiwiV0RpclVwRG93biI6IjAiLCJXRGlyTGVmdFJpZ2h0IjoiMCIsIldTd2lybCI6IjAiLCJKZXQiOiIwIiwiTG93SGVhdGluZyI6IjAiLCJDaXJjdWxhdGVTdHJlbmd0aCI6IjAiLCJDaXJjdWxhdGVEaXIiOiIwIiwiQW50aUJ1Z3MiOiIwIiwiSWNlVmFsbGV5IjoiMCIsIkh1bXNhdmUiOiIwIiwiV2F0ZXJUZW1wQ3VyIjoiMCIsIkhvdFdhdGVyVGVtcEN1ciI6IjAiLCJIb3RXYXRlclRlbXBDZmciOiIwIiwiSG90V2F0ZXJNb2RlIjoiMCIsIkhvdFdhdGVyIjoiMCIsIkFXSFBUZW1wQ2ZnU3dpdGNoIjoiMCIsIkFpclRlbXBDb29sTWluIjoiMCIsIkFpclRlbXBDb29sTWF4IjoiMCIsIkFpclRlbXBIZWF0TWluIjoiMCIsIkFpclRlbXBIZWF0TWF4IjoiMCIsIldhdGVySW5UZW1wQ3VyIjoiMCIsIkFXSFBXQVRlbXBDb250cm9sU3RhIjoiMCIsIkRpc3BsYXlDb250cm9sIjoiMCIsIlNtYXJ0Q2FyZSI6IjAiLCJUd29TZXRDb29sVGVtcCI6IjAiLCJUd29TZXRIZWF0VGVtcCI6IjAiLCJUd29TZXRDb29sVVNMIjoiMCIsIlR3b1NldENvb2xMU0wiOiIwIiwiVHdvU2V0SGVhdFVTTCI6IjAiLCJUd29TZXRIZWF0TFNMIjoiMCIsIlR3b1NldEFDT1N0YXRlIjoiMCIsIlR3b1NldE1vZGVEZWFkYmFuZCI6IjAiLCJUd29TZXRTdGF0ZSI6IjAifQ==") }

fn control(key, value) { let v = #{}; v[key] = value; #{ Cmd: "Control", CmdOpt: "Set", Value: v, Format: "B64", Data: "" } }
fn t1_sent(d) {
    let out = [];
    for c in d.clips() { let b = c.Body; b.remove("CmdWId"); out.push(b); }
    out
}

// start() subscribes to monitoring
fn test_t1_start_subscribes_to_status() {
    let d = device_t1();
    d.start();
    expect_eq(t1_sent(d), [#{ Cmd: "Mon", CmdOpt: "Start" }]);
}

// off: Operation=0 folds into mode "off", other fields still decode
fn test_t1_off() {
    let d = device_t1();
    d.feed(t1_off());
    expect_props(d, #{ power: "false", mode: "fan_only", temperature: "21", target: "24", fan: "very_low",
                       swing_vertical: "off", swing_horizontal: "3", jet: "false", air_purify: "false" });
}

// cool 23C very high fan, vertical swing on
fn test_t1_cool_23_very_high_fan_vertical_swing() {
    let d = device_t1();
    d.feed(t1_cool_23_high());
    expect_props(d, #{ power: "true", mode: "cool", target: "23", fan: "very_high", swing_vertical: "on" });
}

// fan_only with fan very low and horizontal step 3
fn test_t1_fan_only() {
    let d = device_t1();
    d.feed(t1_fan_only_low());
    expect_props(d, #{ mode: "fan_only", fan: "very_low", swing_vertical: "off", swing_horizontal: "3" });
}

// dry / heat / auto modes
fn test_t1_dry_heat_auto() {
    for pair in [[t1_dry(), "dry"], [t1_heat(), "heat"], [t1_auto(), "auto"]] {
        let d = device_t1();
        d.feed(pair[0]);
        expect_eq(d.property("mode"), pair[1]);
    }
}

// half-degree current temperature and auto fan
fn test_t1_half_degrees_and_auto_fan() {
    let d = device_t1();
    d.feed(t1_fan_auto());
    expect_props(d, #{ temperature: "19.5", fan: "auto" });
}

// swing steps decode to their numbered labels
fn test_t1_swing_steps() {
    let d = device_t1();
    d.feed(t1_vswing_step1());
    expect_eq(d.property("swing_vertical"), "1");
    d.feed(t1_hswing_step4());
    expect_eq(d.property("swing_horizontal"), "4");
}

// jet and air purify read back ON
fn test_t1_jet_and_air_purify() {
    let d = device_t1();
    d.feed(t1_jet_on());
    expect_props(d, #{ jet: "true", air_purify: "false" });
    d.feed(t1_airclean_on());
    // the appliance itself pins the setpoint to 18 while jet is active
    expect_props(d, #{ jet: "true", air_purify: "true", target: "18" });
}

// writes use the Set envelope with Format and Data present
fn test_t1_writes_use_the_set_envelope() {
    let d = device_t1();
    d.start();
    d.feed(t1_cool_23_high());
    d.set("target", "21");
    d.set("fan", "high");
    d.set("swing_vertical", "on");
    d.set("swing_horizontal", "1-3");
    d.set("jet", "true");
    d.set("air_purify", "false");
    expect_eq(t1_sent(d).extract(1), [
        control("TempCfg", "21"), control("WindStrength", "5"), control("WDirVStep", "100"),
        control("WDirHStep", "13"), control("Jet", "1"), control("AirClean", "0"),
    ]);
}

// mode change from off powers on first; mode "off" powers off
fn test_t1_a_mode_write_from_off_powers_on_first() {
    let d = device_t1();
    d.start();
    d.feed(t1_off());
    d.set("mode", "cool");
    expect_eq(t1_sent(d).extract(1), [control("Operation", "1"), control("OpMode", "0")]);
    d.feed(t1_cool_23_high());
    let n = d.clips().len();
    d.set("mode", "heat"); // already running: no Operation packet
    d.set("power", "false");
    expect_eq(t1_sent(d).extract(n), [control("OpMode", "4"), control("Operation", "0")]);
}

// zeroed placeholder pushes are dropped, not published
fn test_t1_placeholder_pushes_are_dropped() {
    let d = device_t1();
    d.feed(t1_placeholder());
    expect_eq(d.property("available"), ());
    expect_eq(d.property("mode"), ());
    d.feed(t1_cool_23_high());
    d.feed(t1_placeholder());
    // a later placeholder does not overwrite real state
    expect_props(d, #{ mode: "cool", target: "23", fan: "very_high" });
}

// non-JSON and unknown-code packets are tolerated
fn test_t1_bad_and_unknown_pushes_are_tolerated() {
    let d = device_t1();
    d.feed("not json at all".to_blob());
    expect_eq(d.property("power"), ());
    expect_eq(d.script_error(), ());
    d.feed(`{"Operation":"1","OpMode":"9","WindStrength":"2"}`.to_blob());
    expect_eq(d.property("mode"), ());
    expect_eq(d.property("fan"), "very_low");
}

fn test_t1_the_descriptor_has_no_tlv_features() {
    let d = device_t1();
    d.start();
    let props = runtime::descriptor(d).props;
    expect_eq(props.target.step, 1);
    expect(props.contains("jet") && props.contains("air_purify"), "jet, air purify");
    expect(!props.contains("action"), "no action");
}

// the power sensor keeps the bias correction for a unit without MOMENTARY_OUTDOOR (upstream
// 2d8eaba; the captured caps advertise accumMode 0x2d5 = 3)
fn test_the_power_sensor_keeps_the_bias_correction() {
    let d = ready();
    d.feed("0000040000008702040003ACD0DF0000"); // 0x2b3 = 223
    expect_eq(d.property("power_draw"), "163");
}

// ---- the newer features (upstream RAC_056905_WW.H09S1D.test.ts, commit 2d8eaba) -------------
// Live captures from an H09S1D.NS (firmware 0x55703) and a DC12RT.NSJ (firmware 0x690409), both
// switched off; every write was accepted by the H09S1D and read back. Upstream's per-entity
// availability and descriptions are Home Assistant presentation: here a mode-bound feature declares
// `requires` on the mode and its write is refused while the unit is not running in it.

fn h09s1d_caps_response() { "000004000000870201139FB001E180B05077B0A0017CD41012D3F0100400B85024B8903CB8D020B9103CBAD024BB103CB0C1B1101FB3200205B2B0030000B2C0BC08B34FABC0B4B0041020B4F0045011B5A08000B54EB6A04EB9B6F0055703B701B75020BC40BD30080000EA01BD7040480BFB0FDD046440649054FA016C81B5C0B61028B642B5C1B61020B642B5C2B61020B642B5C4B61028B642B5D02EB61020B642B5C6B6102CB6429A18" }
fn h09s1d_query_response() { "00000400000087020419B27E407DC07E827F50347F90287EC17F00C840C8847BD0147C00C8C083408390FF83C0A880868086C0870087C18F8089407C82E8805940CD903688408A10FF8A408A80ADA00205ACC0AD4059C0A0406D4168816901D440F2700A50018200D540D580D5D03CD61020C900CAC0CB1092CB40CB89CBC0CC10CCCC40CC90908B40E801FA80BF40BFE00355BF80C0200355BE508FBE908E6240BEC0C340C0C0EE40C380CCC0CD00CD4090004B414BC14CC152C053404A4C" }
fn dc12rt_caps_response() { "0000040000008702017C4EB001B05077B0A0017CB0C1B103B307B34FB4C7B582B6A04D87B6F0690409B701BC40BD46B5C0B61029B642B5C1B6102EB642B5C2B6102EB642B5C4B6102CB642B5C5B6102EB642B5C6B6102CB64294E8" }
fn dc12rt_query_response() { "00000400000087020480697E407DC07E827F50317F9029C840C881C8C08340838183C0868086C0870087C1894088408A008A408A808C808CC0ACC0D540D580C900CAC0CB108BCB40CB8CCBC0CC10CCCC40CC90968B40BF6001C7BFC0BFA001C7C000BE5089BE90881B00BEC0C300C340C0C0C3800C05" }
fn write_beep_off() { "0101040000006502010102E8012B05" }
fn h09_write_display_on() { "010104000000650201010287C0F97C" }
fn write_window_off() { "0101040000006502010105F2700A5000FEC8" }
fn write_autodry_off() { "010104000000650201010283807D7C" }
fn write_autodry_on() { "01010400000065020101038390FFB80D" }
fn write_autodry_fan_medium() { "01010400000065020101027C843E07" }
fn write_energy_60() { "010104000000650201010383503C4776" }
fn write_lowheat_on() { "01010400000065020101028B413DB8" }
fn write_aiair_on() { "01010400000065020101028F812830" }
fn write_goodsleep_off() { "01010400000065020101024B403BCD" }
fn h09_write_power_off() { "01010400000065020101027DC00576" }
fn write_softair_on() { "0101040000006502010105D470010000C5B7" }

fn h09() { ready_with(h09s1d_caps_response(), h09s1d_query_response()) }
fn dc12() { ready_with(dc12rt_caps_response(), dc12rt_query_response()) }
fn props(d) { runtime::descriptor(d).props }
fn write(d, prop, value) { let n = d.sent().len(); d.set(prop, value); d.sent().extract(n).map(|s| hex_encode_upper(s)) }

// exposes the features advertised by the unit
fn test_h09s1d_exposes_its_features() {
    let p = props(h09());
    expect_eq([p.target.min, p.target.max], [16, 30]); // heat low limit 0x2e3
    expect_eq([p.humidity.role, p.humidity.class], ["current_humidity", "humidity"]);
    expect_eq(p.energy_limit.options, ["off", "40", "60", "80"]);
    expect_eq(p.auto_dry_fan.options, ["low", "medium", "high"]);
    // mode-bound features say which modes they need
    expect_eq(p.ai_air.requires, #{ prop: "mode", "in": ["cool", "heat"] });
    expect_eq(p.low_heating.requires, #{ prop: "mode", "in": ["heat"] });
    expect_eq(p.soft_air.requires, #{ prop: "mode", "in": ["cool", "fan_only"] });
    expect(!p.beep.contains("requires"), "beep always applies");
    expect(p.contains("turn_on_timer") && p.contains("turn_off_timer"), "relative timers via TIMEBS_ONOFF");
    // auto dry is the setting here, not the read-only status
    expect_eq([p.auto_dry.rw, p.auto_dry.category], [true, "config"]);
    // 0x20d is the energy limit here, not the energy-saving switch
    expect(!p.contains("energy_save"), "no energy saving");
}

// publishes the reported values
fn test_h09s1d_publishes_the_reported_values() {
    // captured with 0x3a0 = 1 and 0x21f = 1, which the ThinQ app shows as beep off and display off;
    // stored preferences show their real value although the AC is off
    expect_props(h09(), #{ humidity: "54", power: "false", window_detection: "true", beep: "false",
        good_sleep: "true", good_sleep_operation: "true", good_sleep_temperature: "true", auto_dry: "true",
        auto_dry_fan: "low", display_light: "false" });
}

// settings write the values the unit accepts
fn test_h09s1d_settings() {
    let d = h09();
    expect_eq(write(d, "beep", "false"), [write_beep_off()]);
    expect_eq(write(d, "window_detection", "false"), [write_window_off()]); // upper bits kept
    expect_eq(write(d, "auto_dry", "false"), [write_autodry_off()]);
    expect_eq(write(d, "auto_dry", "true"), [write_autodry_on()]);
    expect_eq(write(d, "auto_dry_fan", "medium"), [write_autodry_fan_medium()]);
    // a stored preference: written while the AC is off as well
    expect_eq(write(d, "good_sleep", "false"), [write_goodsleep_off()]);
    expect_eq(write(d, "display_light", "true"), [h09_write_display_on()]);
}

// mode 46 (Air Purify started from off) reads back as fan_only
fn test_mode_46_is_fan() {
    let d = h09();
    d.feed(t::notify([[0x1f7, 1], [0x1f9, 46], [0x20f, 1]]));
    expect_props(d, #{ mode: "fan_only", action: "fan", air_purify: "true" });
}

// energy limit is held while off and sent once the unit runs
fn test_the_energy_limit_is_held_while_off() {
    let d = h09();
    expect_eq(write(d, "energy_limit", "60"), []);
    let n = d.sent().len();
    d.feed(t::notify([[0x1f7, 1], [0x1f9, 0]]));
    expect(d.sent().extract(n).map(|s| hex_encode_upper(s)).contains(write_energy_60()), "sent once cooling");
}

// low heating is only sent in heat mode, and not re-applied later
fn test_low_heating() {
    let d = h09();
    d.feed(t::notify([[0x1f7, 1], [0x1f9, 0]]));
    expect_eq(write(d, "low_heating", "true"), []);
    expect(d.event("reject").contains("requires"), "refused in cool mode");
    // the manual: changing temperature, fan or mode cancels it, so a request is not carried over
    let n = d.sent().len();
    d.feed(t::notify([[0x1f9, 4]]));
    expect(!d.sent().extract(n).map(|s| hex_encode_upper(s)).contains(write_lowheat_on()), "not carried over");
    expect_eq(write(d, "low_heating", "true"), [write_lowheat_on()]);
}

// AI Air is written only while running
fn test_ai_air() {
    let d = h09();
    expect_eq(write(d, "ai_air", "true"), []);
    d.feed(t::notify([[0x1f7, 1], [0x1f9, 4]]));
    expect_eq(write(d, "ai_air", "true"), [write_aiair_on()]);
    d.feed(t::notify([[0x23e, 1]]));
    expect_eq(d.property("ai_air"), "true");
}

// the sleep timer is only written while the AC is on
fn test_the_sleep_timer_needs_power() {
    let d = h09();
    expect_eq(write(d, "sleep_timer", "1"), []);
    d.feed(t::notify([[0x1f7, 1], [0x1f9, 0]]));
    expect_eq(write(d, "sleep_timer", "1").len(), 1);
}

// Soft Air is only written in Cooling or Fan
fn test_soft_air() {
    let d = h09();
    expect_eq(write(d, "soft_air", "true"), []);
    d.feed(t::notify([[0x1f7, 1], [0x1f9, 4]]));
    expect_eq(write(d, "soft_air", "true"), []); // not in heating
    d.feed(t::notify([[0x1f9, 0]]));
    expect_eq(write(d, "soft_air", "true"), [write_softair_on()]);
    d.feed(t::notify([[0x351, 0x10000]]));
    expect_eq(d.property("soft_air"), "true");
}

// the power sensor reports the raw value for a unit with MOMENTARY_OUTDOOR, offered while it reads 0
fn test_the_power_sensor_with_momentary_outdoor() {
    let d = h09();
    expect_eq(props(d).power_draw.class, "power");
    d.feed(t::notify([[0x2b3, 223]]));
    expect_eq(d.property("power_draw"), "223");
}

// the power sensor is not offered for a multi-split unit without accumMode
fn test_no_power_sensor_without_accum_mode() {
    expect(!props(dc12()).contains("power_draw"), "no power sensor");
}

// DC12RT: Jet, Energy saving and the Sleep timer keep their requirements
fn test_dc12rt_requirements() {
    let d = dc12();
    expect_eq(props(d).sleep_timer.requires, "power");
    expect_eq(write(d, "sleep_timer", "1"), []);
    d.feed(t::notify([[0x1f7, 1], [0x1f9, 0]]));
    expect_eq(write(d, "sleep_timer", "1").len(), 1);
}

// DC12RT keeps the older feature set
fn test_dc12rt_keeps_the_older_features() {
    let p = props(dc12());
    expect_eq([p.target.min, p.target.max], [18, 30]);
    expect_eq(p.energy_save.type, "binary");
    expect_eq([p.auto_dry.type, p.auto_dry.contains("rw")], ["binary", false]);
    expect_eq(p.sleep_timer.max, 15);
    expect(p.contains("turn_on_timer"), "turn-on timer");
    // the unit ignores 0x21f writes, and none of the newer features are advertised
    for name in ["display_light", "humidity", "ai_air", "energy_limit", "window_detection", "low_heating",
                 "beep", "good_sleep", "soft_air", "auto_dry_fan"] {
        expect(!p.contains(name), name);
    }
}
