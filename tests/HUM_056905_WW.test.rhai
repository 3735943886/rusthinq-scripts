import "runtime_test" as runtime;
// BEGIN PR VECTORS
// Regression vectors from rethink PR #114 (5898c3b6c2407c71281d8ef6e6caffb036a82b22).
// Original test names are retained below. Expected TX bytes come from executing the TS driver.

// the captured values frame populates the entities it is meant to
fn test_pr_114_1() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
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
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
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
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400027e45d21d");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400027e4c4334");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "humidify_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400037e5018ef34");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "humidify", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
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
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("mode", "air_clean");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[1]), "01010400000065020101047e457dc1d03f");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("mode", "humidify_clean");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[2]), "01010400000065020101047e4c7dc14eae");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("mode", "humidify");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
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
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400027e88dafc");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "auto", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("fan", "auto");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "auto", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[1]), "01010400000065020101027e8899e9");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400027e827bb6");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("fan", "low");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[2]), "01010400000065020101027e8238a3");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400027e841b70");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "medium", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("fan", "medium");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "medium", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[3]), "01010400000065020101027e845865");
    expect_eq(d.sent().len(), 4);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400027e863b32");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "high", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 4);
    expect_eq(d.script_error(), ());
    d.set("fan", "high");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "high", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(hex_encode(d.sent()[4]), "01010400000065020101027e867827");
    expect_eq(d.sent().len(), 5);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400027e872b13");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "turbo", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 5);
    expect_eq(d.script_error(), ());
    d.set("fan", "turbo");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "turbo", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
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
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("target", "52");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
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
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("target", "nan");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("target", "infinity");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("target", "-1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("target", "101");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
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
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400037e506320c8");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204000378d06389f0");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
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
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204000287c92b40");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "level_2", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("display", "level_3");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "level_2", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
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
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
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
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// the off timer is hours in HA and minutes on the wire, as on RAC_056905_WW
fn test_pr_114_12() {
    let d = device();
    d.feed("000004000000a702012778640f644f6c4cb00eb0601020b480a5c0965020b0a001d4b4e05000b5b020100057c3580f79507bb6a04956b6e04378b700b750feb9501eb99046bc200800bc70020201b3c0bd1031bd60099fbd85d3c0d400dd04f7905af7d014fa01fb0bf870fffc40ef83b5c5b600b642b5ccb600b642b5d018b600b642e059");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042d9d6880698069c06a006a406a806ac06b006b406b806bc06c006cc06e405902fa807dc17e457e827f50374241584179c07a437a807b50647b8fb4501cb7901c86c0870087c08940898094d041d8808790c8cd46cd05ccc49001cd90308840d5503ed59064ab007f00e801e900e94ae989ebc1ed08ed40ee405cf0180c055d00f80b6e0178c179007980ab40b5c5b600b642b5ccb600b642b5d018b600b64290c1");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204000386d05ad6d9");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "90", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("off_timer", "135");
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "90", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
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
    expect_props(d, #{"standby_sterilize": "silent", "power": "true", "mode": "air_clean", "fan": "low", "temperature": "27.5", "night_mode": "true", "anti_glare": "true", "humidify": "false", "hygiene_dry": "quick", "water_filter": "100", "watertank_remain": "15", "off_timer": "0", "display": "off", "autodry_remain": "0", "target": "65", "pm10": "6", "pm25": "5", "pm1": "4", "humidity": "48", "filter_used_time": "62", "filter_life_time": "100", "bell_sound": "true", "mood_color": "sunlight", "mood_light": "true", "status": "no_tank", "sleep_mode": "false", "auto_strength": "false", "watertank_time": "0"});
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
