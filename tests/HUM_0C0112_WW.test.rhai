import "runtime_test" as runtime;
import "tlv_test" as t;

// Behavior of a private rethink fork driver running on an installed MAX unit. The frames are live,
// read-only captures from 2026-11-10 of complete capability and values replies, taken twice. They
// check decoding and the declared surface, not the physical effect of every option. Undecoded
// per-unit values (0x173, 0x174, 0x2da, 0x2db) are zeroed, with length and CRC recomputed; nothing
// reads them.
fn caps() {
    "000004000000a702013c90640064708000006c4cb00eb06010205270180000965020b0a001d4b4e05000b5b020100058101f7960027b7d30400000b680b6c0b700b7507eb9501eb99046bc202800bc701e0201b3c0bd1031bd60099fbd85d3c0d41080dd04ea201000f7905af7d014fa01fb0bf8703ffe00efa00700b5c5b600b648b5ccb600b648b5d018b600b648b5ccb600b640b5c5b600b640e5ec"
}
fn values() {
    "000004000000a7020441ac6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e4059015b40fa807dc17e506c7e867f50334240584179c17a437a807b50647b8fb45055b7903886c0870087ca895078898094d034d8808790c8cd46cd04ccc49001cd902c8840d55064d59064ab007f00e801e900e940e980ea40ebc0ed00ed40ee405cc05d00f80a6e0078c079007981ab40b5c5b600b648b5ccb600b648b5d018b600b648b5ccb600b640b5c5b600b6405e73"
}
fn caps_later() {
    "000004000000a70201c190640064708000006c4cb00eb06010205270180000965020b0a001d4b4e05000b5b020100058101f7960027b7d30400000b680b6c0b700b7507eb9501eb99046bc202800bc701e0201b3c0bd1031bd60099fbd85d3c0d41080dd04ea201000f7905af7d014fa01fb0bf8703ffe00efa00700b5c5b600b648b5ccb600b648b5d018b600b648b5ccb600b640b5c5b600b6409a98"
}
fn values_later() {
    "000004000000a70204c3ac6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e4059015b40fa807dc17e506c7e867f50344240584179c17a437a807b50647b8fb45064b7903986c0870087ca895078898094d032d8808790c8cd44cd04ccc49001cd902e8840d55064d59064ab007f00e801e900e940e980ea40ebc0ed00ed40ee405cc05d00f80a6e0078c079007981ab40b5c5b600b648b5ccb600b648b5d018b600b648b5ccb600b640b5c5b600b6404b02"
}
// HUM_056905_WW's native reservation readback, which this model must not publish.
fn res_read_2213() { "00ff0400000087fd03000d03a50800000000000000000000ec97" }
fn res_ack() { "02020400000087fd100005fe030000005aa6" }

fn ready() { let d = device(); d.start(); d.feed(caps()); d.feed(values()); d }
fn last_tlvs(d) { d.sent_tlvs(d.sent().len() - 1) }
fn expect_rejected(d, prop, value) {
    let n = d.sent().len();
    d.set(prop, value);
    expect_eq(d.sent().len(), n, prop + "=" + value + " sent nothing");
    expect(d.event("reject") != (), prop + "=" + value + " rejected");
    expect_eq(json_parse(d.event("reject")).prop, prop);
}

fn test_captured_frames_establish_readiness_and_decode_telemetry() {
    let d = device();
    d.start();
    expect_rejected(d, "bell_sound", "true");
    expect_eq(json_parse(d.event("reject")).code, "not_now");
    d.feed(caps());
    // Only the values query: no reservation GET on this model.
    expect_eq(d.sent().len(), 2);
    expect_eq(d.sent_tlvs(1), [[0x1f5, 2]]);
    d.feed(values());
    expect_props(d, #{ power: "true", mode: "ai_humidify", target: "52", humidity: "44", temperature: "25.5",
        fan: "high", bell_sound: "false", mood_color: "candlelight", hygiene_dry: "quick", status: "normal",
        water_lack: "false", standby_sterilize: "normal", display: "level_3", watertank_light: "200",
        air_quality: "1", error: "0", pm1: "4", pm25: "4", pm10: "6", humidify: "", sensor_mon: "" });
    d.set("bell_sound", "true");
    expect_eq(last_tlvs(d), [[0x3a0, 0]]);
    expect_eq(d.script_error(), ());
}

fn test_a_later_capture_of_the_same_unit_decodes_alike() {
    let d = device();
    d.start(); d.feed(caps_later()); d.feed(values_later());
    expect_props(d, #{ mode: "ai_humidify", target: "50", humidity: "46", temperature: "26", fan: "high" });
    expect_eq(runtime::descriptor(d).props.mode.options.len(), 5);
    expect_eq(d.script_error(), ());
}

fn test_the_descriptor_follows_the_capability_reply() {
    let d = ready();
    let doc = runtime::descriptor(d);
    expect_eq(doc.label, "Humidifying air purifier");
    expect_eq(doc.props.mode.options, ["air_clean", "humidify_clean", "humidify", "ai_humidify", "cozy_humidify"]);
    expect_eq(doc.props.hygiene_dry.options, ["off", "gentle", "quiet", "quick", "focus"]);
    expect_eq(doc.props.standby_sterilize.options, ["rapid", "normal", "silent"]);
    expect_eq(doc.props.mood_color.options, ["pure_white", "aquarium", "candlelight", "sunlight", "rose", "mint", "lime", "very_peri", "warm_white", "cool_white", "sapphire", "rainbow", "aurora", "bonfire", "ripples"]);
    expect_eq([doc.props.target.min, doc.props.target.max, doc.props.target.step], [30, 70, 5]);
    for prop in ["humidify", "sensor_mon", "start_time", "stop_time", "over_prevention", "auto_dry"] {
        expect_eq(doc.props[prop], (), prop + " is not declared");
    }
    expect_eq(doc.props.bell_sound.type, "binary");
    expect_eq(doc.props.water_lack["class"], "problem");
    expect_eq(d.script_error(), ());
}

fn test_reservations_are_never_published_or_written() {
    let d = device();
    d.start();
    expect_eq(runtime::descriptor(d).props.start_time, (), "not even before the capability reply");
    d.feed(caps()); d.feed(values());
    d.feed(res_read_2213());
    d.feed(t::notify([[0x35a, 2213], [0x35b, 100]]));
    // Absent: cleared (empty retained) by the narrowed descriptor, never given a time.
    expect_eq(d.property("start_time"), "");
    expect_eq(d.property("stop_time"), "");
    expect_rejected(d, "start_time", "2213");
    let n = d.sent().len();
    d.feed(res_ack());
    d.fire("refresh");
    expect_eq(d.sent().len(), n + 1);
    expect_eq(last_tlvs(d), [[0x1f5, 2]]);
    expect_eq(d.script_error(), ());
}

fn test_ai_and_cozy_modes_write_their_codes_and_power_on() {
    let d = ready();
    for p in [["ai_humidify", 108], ["cozy_humidify", 109], ["air_clean", 5]] {
        d.set("mode", p[0]);
        expect_eq(last_tlvs(d), [[0x1f9, p[1]], [0x1f7, 1]]);
        d.feed(t::notify([[0x1f9, p[1]]]));
        expect_eq(d.property("mode"), p[0]);
    }
    // An unknown mode code leaves the last reading.
    d.feed(t::notify([[0x1f9, 99]]));
    expect_eq(d.property("mode"), "air_clean");
    expect_rejected(d, "mode", "unknown");
    expect_eq(d.script_error(), ());
}

fn test_max_mood_colours_round_trip() {
    let d = ready();
    for p in [["aurora", 34], ["bonfire", 39], ["ripples", 40]] {
        d.feed(t::notify([[0x3e0, p[1]]]));
        expect_eq(d.property("mood_color"), p[0]);
        d.set("mood_color", p[0]);
        expect_eq(last_tlvs(d), [[0x3e0, p[1]]]);
    }
    // Not offered by any capability bit.
    d.feed(t::notify([[0x3e0, 1]]));
    expect_eq(d.property("mood_color"), "ripples");
    expect_rejected(d, "mood_color", "blue");
    expect_rejected(d, "mood_color", "orange");
    expect_eq(d.script_error(), ());
}

fn test_unsupported_settings_are_rejected() {
    let d = ready();
    expect_rejected(d, "humidify", "true");
    expect_rejected(d, "sensor_mon", "always");
    expect_rejected(d, "standby_sterilize", "power");
    expect_rejected(d, "hygiene_dry", "default");
    expect_eq(d.script_error(), ());
}

fn test_switches_write_both_states_and_reject_bad_payloads() {
    let d = ready();
    for p in [["night_mode", 0x109, 1], ["sleep_mode", 0x1e4, 1], ["auto_strength", 0x1e6, 1],
              ["anti_glare", 0x161, 1], ["mood_light", 0x1b8, 1], ["bell_sound", 0x3a0, 0]] {
        d.feed(t::notify([[p[1], p[2]]]));
        expect_eq(d.property(p[0]), "true", p[0]);
        d.feed(t::notify([[p[1], 1 - p[2]]]));
        expect_eq(d.property(p[0]), "false", p[0]);
        d.set(p[0], "true"); expect_eq(last_tlvs(d), [[p[1], p[2]]], p[0]);
        d.set(p[0], "false"); expect_eq(last_tlvs(d), [[p[1], 1 - p[2]]], p[0]);
        expect_rejected(d, p[0], "invalid");
    }
    d.set("power", "false"); expect_eq(last_tlvs(d), [[0x1f7, 0]]);
    d.set("power", "true"); expect_eq(last_tlvs(d), [[0x1f7, 1]]);
    expect_eq(d.script_error(), ());
}

fn test_selects_write_their_declared_codes() {
    let d = ready();
    for p in [["fan", 0x1fa, [["auto", 8], ["low", 2], ["medium", 4], ["high", 6], ["turbo", 7]]],
              ["hygiene_dry", 0x1e9, [["off", 0], ["gentle", 1], ["quiet", 2], ["quick", 3], ["focus", 4]]],
              ["standby_sterilize", 0x164, [["rapid", 0], ["normal", 1], ["silent", 2]]],
              ["display", 0x21f, [["off", 0], ["level_1", 8], ["level_2", 9], ["level_3", 10]]]] {
        for o in p[2] {
            d.set(p[0], o[0]);
            expect_eq(last_tlvs(d), [[p[1], o[1]]], p[0] + "=" + o[0]);
        }
    }
    expect_eq(d.script_error(), ());
}

fn test_numbers_keep_whole_values_and_reject_the_rest() {
    let d = ready();
    d.set("watertank_light", "101"); expect_eq(last_tlvs(d), [[0x21e, 101]]);
    d.set("off_timer", "34"); expect_eq(last_tlvs(d), [[0x21b, 34]]);
    d.set("target", "50"); expect_eq(last_tlvs(d), [[0x253, 50]]);
    expect_rejected(d, "target", "52");
    for v in ["", " ", "invalid", "Infinity", "-1", "9999", "34.5"] { expect_rejected(d, "off_timer", v); }
    expect_rejected(d, "watertank_light", "101.4");
    expect_eq(d.script_error(), ());
}

fn test_read_only_telemetry_is_never_written() {
    let d = ready();
    for prop in ["humidity", "temperature", "pm1", "pm25", "pm10", "air_quality", "watertank_remain",
                 "watertank_time", "water_filter", "filter_used_time", "filter_life_time", "autodry_remain",
                 "status", "error", "water_lack"] {
        expect_rejected(d, prop, "1");
    }
    expect_eq(d.script_error(), ());
}

fn test_mapped_telemetry_decodes_its_wire_representation() {
    let d = ready();
    d.feed(t::notify([[0x336, 48], [0x1fd, 55], [0x333, 4], [0x334, 5], [0x335, 6], [0x240, 2], [0x1ee, 15],
        [0x2ad, 120], [0x1ed, 87], [0x355, 101], [0x356, 4000], [0x225, 30], [0x1e3, 2], [0x221, 13]]));
    expect_props(d, #{ humidity: "48", temperature: "27.5", pm1: "4", pm25: "5", pm10: "6", air_quality: "2",
        watertank_remain: "15", watertank_time: "120", water_filter: "87", filter_used_time: "101",
        filter_life_time: "4000", autodry_remain: "30", status: "low_water", error: "13", water_lack: "true" });
    d.feed(t::notify([[0x1e3, 99]]));
    expect_eq(d.property("status"), "low_water");
    expect_eq(d.script_error(), ());
}
