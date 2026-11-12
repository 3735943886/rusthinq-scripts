import "runtime_test" as runtime;
import "tlv_test" as t;
// BEGIN PR VECTORS
// Regression vectors from rethink PR #114 (5898c3b6c2407c71281d8ef6e6caffb036a82b22).
// Original test names are retained below. Expected TX bytes come from executing the TS driver.
// Changed: bell_sound now reads raw 1 as "false" (muted), per the shipped LG app module; see
// hum_common's header for how far that evidence goes.

// the captured values frame populates the entities it is meant to
fn test_pr_114_1() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// config offers the LG mode and fan vocabularies
fn test_pr_114_2() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// every mode code decodes to its label
fn test_pr_114_3() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400027e45d21d");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400027e4c4334");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "humidify_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400037e5018ef34");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "humidify", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// every mode label writes its wire code and turns the appliance on
fn test_pr_114_4() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("mode", "air_clean");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[1]), "01010400000065020101047e457dc1d03f");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("mode", "humidify_clean");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[2]), "01010400000065020101047e4c7dc14eae");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("mode", "humidify");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[3]), "01010400000065020101057e50187dc1f4a9");
    expect_eq(d.sent().len(), 4);
    expect_eq(d.script_error(), ());
}

// every fan code decodes, and every fan label writes 0x1fa alone
fn test_pr_114_5() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400027e88dafc");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "auto", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("fan", "auto");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "auto", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[1]), "01010400000065020101027e8899e9");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400027e827bb6");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("fan", "low");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[2]), "01010400000065020101027e8238a3");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400027e841b70");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "medium", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("fan", "medium");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "medium", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[3]), "01010400000065020101027e845865");
    expect_eq(d.sent().len(), 4);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400027e863b32");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "high", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 4);
    expect_eq(d.script_error(), ());
    d.set("fan", "high");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "high", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[4]), "01010400000065020101027e867827");
    expect_eq(d.sent().len(), 5);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400027e872b13");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "turbo", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 5);
    expect_eq(d.script_error(), ());
    d.set("fan", "turbo");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "turbo", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[5]), "01010400000065020101027e876806");
    expect_eq(d.sent().len(), 6);
    expect_eq(d.script_error(), ());
}

// target humidity snaps to LG’s 5% step
fn test_pr_114_6() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    // Changed: the descriptor now declares LG's step of 5 (min 30, max 70), and the IL refuses
    // values off it instead of snapping 52 to 50 as rethink does. 50 writes what 52 used to.
    d.set("target", "52");
    expect_eq(d.sent().len(), 1);
    expect_eq(json_parse(d.event("reject")).code, "bad_step");
    d.set("target", "50");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[1]), "010104000000650201010394d0327bd3");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// target humidity rejects non-finite and out-of-range writes
fn test_pr_114_7() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("target", "nan");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("target", "infinity");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("target", "-1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("target", "101");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// enum entities use the exact unknown fallback and declare their options
fn test_pr_114_8() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400037e506320c8");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204000378d06389f0");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// display brightness round-trips its LG codes
fn test_pr_114_9() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204000287c92b40");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "level_2", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("display", "level_3");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "level_2", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[1]), "010104000000650201010287ca5836");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// every registered tag is present in the captured values response
fn test_pr_114_10() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// unverified and raw-only entities are not exposed
fn test_pr_114_11() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    let doc = runtime::descriptor(d);
    for prop in ["over_prevention", "auto_dry"] { expect_eq(doc.props[prop], (), prop + " is not exposed"); }
    expect_eq(d.property("over_prevention"), ());
    expect_eq(d.property("auto_dry"), ());
}

// the off timer is hours in HA and minutes on the wire, as on RAC_056905_WW
fn test_pr_114_12() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204000386d05ad6d9");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "90", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("off_timer", "135");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "90", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[1]), "010104000000650201010386d087a1ae");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// the absolute HHMM schedule tags are not exposed
fn test_pr_114_13() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "false", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

fn test_descriptor_uses_il_humidity_roles_and_minute_timer() {
 let d=device();d.start();let doc=runtime::descriptor(d);
 expect_eq(doc.props.power.role,"on");expect_eq(doc.props.target.role,"target_humidity");
 expect_eq(doc.props.humidity.role,"current_humidity");
 expect_eq(doc.props.off_timer.unit,"min");expect_eq(doc.props.off_timer.max,720);
 expect_eq(doc.props.temperature["class"],"temperature");
 expect_eq(d.script_error(),());
}

// tlv_fields_common: an exact_one switch reads only 0 and 1; any other code leaves the last reading.
fn test_exact_one_switches_keep_their_reading_on_other_codes() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_eq(d.property("night_mode"), "true");
    d.feed(t::notify([[0x109, 255]]));
    expect_eq(d.property("night_mode"), "true");
    d.feed(t::notify([[0x109, 0]]));
    expect_eq(d.property("night_mode"), "false");
    d.feed(t::notify([[0x109, 2]]));
    expect_eq(d.property("night_mode"), "false");
    expect_eq(d.script_error(), ());
}

// Behavior of a private rethink fork driver running on installed units. The frames are live,
// read-only captures from 2026-11-10 of complete capability and values replies from two units of
// this model: one declares the cozy humidify mode, the other the separate humidify switch, the
// sensor mode setting and power standby sterilization. Undecoded per-unit values (0x173, 0x174,
// 0x2da, 0x2db) are zeroed where they differ from the PR #114 vectors, with length and CRC
// recomputed; nothing reads them.
fn cozy_caps() { "000004000000a702011681640064406c4cb00eb06010205270100000965020b0a001d4b4e05000b5b020100058101f7960027b7d30400000b680b6c0b700b7507eb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d41080dd04f7905af7d014fa01fb0bf8703ffe00ef80b5c5b600b648b5ccb600b648b5d018b600b648b5c5b600b6403074" }
fn cozy_values() { "000004000000a7020419a56880698069c06a006a406a806ac06b006b406b806bc06c006cc06e4059015b40fa807dc07e457e847f50304240584179c07a437a807b50647b8fb450c8b790c886c0870087ca895055898094d03cd8808790c8cd40cd00ccc09000cd90348840d55064d59064ab007f00e801e900e949e98aea40ebc1ed00ed40ee405cc05d00f80a6e0078c479007981ab40b5c5b600b648b5ccb600b648b5d018b600b648b5c5b600b6402ecf" }
fn basic_caps() { "000004000000a702018878640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b648b5ccb600b648b5d018b600b6485acd" }
fn basic_values() { "000004000000a702048b9e6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e4c7e847f50314241584179c07a437a807b50647b8fb45037b7901e86c0870087c0895078898094d037d880879082cd47cd05ccc49001cd90358840d5503bd59064ab007f00e801e900e94ae989ebc0ed00ed40ee405cf0180c055d00f8086e0078c079007981ab40b5c5b600b648b5ccb600b648b5d018b600b648c750" }

fn ready(caps, values) { let d = device(); d.start(); d.feed(caps); d.feed(values); d }
fn last_tlvs(d) { d.sent_tlvs(d.sent().len() - 1) }
fn expect_rejected(d, prop, value) {
    let n = d.sent().len();
    d.set(prop, value);
    expect_eq(d.sent().len(), n, prop + "=" + value + " sent nothing");
    expect(d.event("reject") != (), prop + "=" + value + " rejected");
    expect_eq(json_parse(d.event("reject")).prop, prop);
}

fn test_each_unit_keeps_only_the_options_its_capability_reply_declares() {
    let cozy = ready(cozy_caps(), cozy_values());
    let doc = runtime::descriptor(cozy);
    expect_eq(doc.props.mode.options, ["air_clean", "humidify_clean", "humidify", "cozy_humidify"]);
    expect_eq(doc.props.fan.options, ["low", "medium", "high", "turbo", "auto"]);
    expect_eq(doc.props.hygiene_dry.options, ["off", "gentle", "quiet", "quick", "focus"]);
    expect_eq(doc.props.standby_sterilize.options, ["rapid", "normal", "silent"]);
    expect_eq(doc.props.mood_color.options, ["pure_white", "aquarium", "candlelight", "sunlight", "rose", "mint", "lime", "very_peri", "warm_white", "cool_white", "sapphire", "rainbow"]);
    expect_eq(doc.props.humidify, ());
    expect_eq(doc.props.sensor_mon, ());

    let basic = ready(basic_caps(), basic_values());
    let doc = runtime::descriptor(basic);
    expect_eq(doc.props.mode.options, ["air_clean", "humidify_clean", "humidify"]);
    expect_eq(doc.props.hygiene_dry.options, ["off", "gentle", "quiet", "quick"]);
    expect_eq(doc.props.standby_sterilize.options, ["rapid", "normal", "silent", "power"]);
    expect_eq(doc.props.mood_color.options, ["yellow", "pure_white", "aquarium", "candlelight", "sunlight", "rose", "mint", "lime", "very_peri", "warm_white", "cool_white", "sapphire", "rainbow", "salmon_pink", "lavender", "orange", "amber"]);
    expect_eq(doc.props.sensor_mon.options, ["while_on", "always"]);
    expect(doc.props.humidify != (), "the humidify switch is declared");
    for d in [cozy, basic] {
        let doc = runtime::descriptor(d);
        expect_eq([doc.props.target.min, doc.props.target.max, doc.props.target.step], [30, 70, 5]);
        expect_eq(doc.props.over_prevention, ()); expect_eq(doc.props.auto_dry, ());
        expect_eq(d.script_error(), ());
    }
}

fn test_captured_values_decode() {
    let d = ready(cozy_caps(), cozy_values());
    expect_props(d, #{ power: "false", mode: "air_clean", fan: "medium", temperature: "24", target: "60",
        humidity: "52", hygiene_dry: "quick", standby_sterilize: "normal", display: "level_3",
        mood_color: "candlelight", mood_light: "false", night_mode: "false", anti_glare: "true",
        auto_strength: "true", sleep_mode: "false", bell_sound: "false", status: "drying",
        water_lack: "false", watertank_light: "200", air_quality: "0", error: "0",
        autodry_remain: "85", filter_used_time: "100", filter_life_time: "100", off_timer: "0" });
    // Not declared by this unit, so not published although the reply carries 0x1e7.
    expect_eq(d.property("humidify"), "");

    let d = ready(basic_caps(), basic_values());
    expect_props(d, #{ power: "true", mode: "humidify_clean", humidify: "false", standby_sterilize: "silent",
        pm1: "4", pm25: "5", pm10: "7", air_quality: "1", filter_used_time: "59", status: "normal",
        mood_color: "pure_white", watertank_light: "130" });
    let doc = runtime::descriptor(d);
    expect_eq(doc.props.autodry_remain.unit, "min");
    expect_eq(doc.props.filter_used_time.unit, ());
    expect_eq(doc.props.filter_used_time["class"], ());
    expect_eq(d.script_error(), ());
}

fn test_every_declared_select_option_writes_its_wire_code() {
    let codes = #{
        mode: [0x1f9, #{ air_clean: 5, humidify_clean: 12, humidify: 24, cozy_humidify: 109 }],
        fan: [0x1fa, #{ auto: 8, low: 2, medium: 4, high: 6, turbo: 7 }],
        hygiene_dry: [0x1e9, #{ off: 0, gentle: 1, quiet: 2, quick: 3, focus: 4 }],
        standby_sterilize: [0x164, #{ rapid: 0, normal: 1, silent: 2, power: 3 }],
        display: [0x21f, #{ off: 0, level_1: 8, level_2: 9, level_3: 10 }],
        sensor_mon: [0x337, #{ while_on: 0, always: 1 }],
        mood_color: [0x3e0, #{ yellow: 6, pure_white: 8, aquarium: 9, candlelight: 10, sunlight: 11, rose: 12,
            mint: 13, lime: 14, very_peri: 15, warm_white: 16, cool_white: 17, sapphire: 18, rainbow: 19,
            salmon_pink: 20, lavender: 21, orange: 22, amber: 23 }]
    };
    for pair in [[cozy_caps(), cozy_values()], [basic_caps(), basic_values()]] {
        let d = ready(pair[0], pair[1]);
        let doc = runtime::descriptor(d);
        for prop in codes.keys() {
            if doc.props[prop] == () { continue; }
            let tag = codes[prop][0];
            for option in doc.props[prop].options {
                d.set(prop, option);
                let expected = [[tag, codes[prop][1][option]]];
                if prop == "mode" { expected.push([0x1f7, 1]); }
                expect_eq(last_tlvs(d), expected, prop + "=" + option);
                d.feed(t::notify([[tag, codes[prop][1][option]]]));
                expect_eq(d.property(prop), option);
            }
            expect_rejected(d, prop, "unsupported option");
        }
        expect_eq(d.script_error(), ());
    }
}

fn test_filtered_controls_are_rejected_and_never_written() {
    let d = ready(cozy_caps(), cozy_values());
    expect_rejected(d, "humidify", "true");
    expect_rejected(d, "sensor_mon", "always");
    expect_rejected(d, "standby_sterilize", "power");
    expect_rejected(d, "mode", "ai_humidify");
    expect_rejected(d, "hygiene_dry", "default");
    // No capability bit offers colours 1-4 and 7, so they are not options at all.
    expect_rejected(d, "mood_color", "blue");
    d.feed(t::notify([[0x3e0, 1]]));
    expect_eq(d.property("mood_color"), "candlelight");
    expect_rejected(d, "over_prevention", "true");
    expect_rejected(d, "auto_dry", "true");
    expect_eq(d.script_error(), ());
}

fn test_narrowing_clears_values_the_descriptor_no_longer_allows() {
    let d = ready(basic_caps(), basic_values());
    d.feed(t::notify([[0x164, 3], [0x337, 1]]));
    expect_props(d, #{ humidify: "false", sensor_mon: "always", standby_sterilize: "power" });
    // A session whose capability reply drops them: the retained readings are cleared, not left.
    d.drop_device();
    d.start();
    d.feed(cozy_caps());
    expect_props(d, #{ humidify: "", sensor_mon: "", standby_sterilize: "", mode: "humidify_clean" });
    expect_eq(d.script_error(), ());
}

fn test_switches_write_both_states_and_keep_the_last_reading_on_unknown_codes() {
    let d = ready(basic_caps(), basic_values());
    for p in [["night_mode", 0x109], ["sleep_mode", 0x1e4], ["auto_strength", 0x1e6], ["humidify", 0x1e7],
              ["anti_glare", 0x161], ["mood_light", 0x1b8], ["power", 0x1f7]] {
        d.set(p[0], "true"); expect_eq(last_tlvs(d), [[p[1], 1]], p[0]);
        d.set(p[0], "false"); expect_eq(last_tlvs(d), [[p[1], 0]], p[0]);
        d.feed(t::notify([[p[1], 1]]));
        expect_eq(d.property(p[0]), "true");
        if p[0] != "power" {
            d.feed(t::notify([[p[1], 255]]));
            expect_eq(d.property(p[0]), "true", p[0] + " keeps its reading");
        }
        expect_rejected(d, p[0], "invalid");
    }
    expect_eq(d.script_error(), ());
}

fn test_off_timer_keeps_whole_minutes() {
    let d = ready(cozy_caps(), cozy_values());
    for v in [0, 34, 719, 720] {
        d.set("off_timer", v.to_string());
        expect_eq(last_tlvs(d), [[0x21b, v]]);
    }
    for v in ["-1", "721", "34.5", "", "nan"] { expect_rejected(d, "off_timer", v); }
    d.set("watertank_light", "101");
    expect_eq(last_tlvs(d), [[0x21e, 101]]);
    expect_rejected(d, "watertank_light", "201");
    expect_rejected(d, "watertank_light", "101.4");
    expect_eq(d.script_error(), ());
}

fn test_target_humidity_takes_the_declared_steps_only() {
    let d = ready(cozy_caps(), cozy_values());
    for v in [30, 55, 70] {
        d.set("target", v.to_string());
        expect_eq(last_tlvs(d), [[0x253, v]]);
    }
    // rethink snaps 52 to 50 and clamps 5 and 95; the IL refuses them.
    expect_rejected(d, "target", "52");
    expect_eq(json_parse(d.event("reject")).code, "bad_step");
    expect_rejected(d, "target", "5");
    expect_rejected(d, "target", "95");
    expect_eq(d.script_error(), ());
}

fn test_water_shortage_is_its_own_problem_flag() {
    let d = ready(basic_caps(), basic_values());
    expect_eq(runtime::descriptor(d).props.water_lack["class"], "problem");
    d.feed(t::notify([[0x1e3, 2]]));
    expect_props(d, #{ status: "low_water", water_lack: "true" });
    // An unknown status code leaves both readings.
    d.feed(t::notify([[0x1e3, 99]]));
    expect_props(d, #{ status: "low_water", water_lack: "true" });
    // A missing tank is not a shortage: the purifier runs without one.
    d.feed(t::notify([[0x1e3, 1]]));
    expect_props(d, #{ status: "no_tank", water_lack: "false" });
    expect_eq(d.script_error(), ());
}

fn test_commands_wait_for_the_capability_reply() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 1);
    expect_rejected(d, "power", "true");
    expect_eq(json_parse(d.event("reject")).code, "not_now");
    expect_rejected(d, "bell_sound", "true");
    expect_eq(d.script_error(), ());
}

fn test_reconnect_does_not_publish_defaults_over_readings() {
    let d = ready(basic_caps(), basic_values());
    d.drop_device();
    expect_eq(d.property("available"), "false");
    d.start();
    expect_props(d, #{ available: "true", humidity: "53", mode: "humidify_clean" });
    expect_eq(d.script_error(), ());
}

// Raw 0 is sound on and raw 1 muted, per a static reading of the shipped LG app module (GPH
// 3501.04); the modelJSON labels say the opposite. Not checked against the beep itself.
fn test_sound_writes_zero_for_on_and_one_for_off() {
    let d = ready(basic_caps(), basic_values());
    expect_eq(d.property("bell_sound"), "false");
    d.set("bell_sound", "true");
    expect_eq(last_tlvs(d), [[0x3a0, 0]]);
    d.set("bell_sound", "false");
    expect_eq(last_tlvs(d), [[0x3a0, 1]]);
    d.feed(t::notify([[0x3a0, 0]]));
    expect_eq(d.property("bell_sound"), "true");
    d.feed(t::notify([[0x3a0, 255]]));
    expect_eq(d.property("bell_sound"), "true");
    expect_eq(d.script_error(), ());
}
