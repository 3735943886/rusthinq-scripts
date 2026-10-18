import "runtime_test" as runtime;
// BEGIN PR VECTORS
// Regression vectors from rethink PR #169 (a8a9c64795163182e3351af61a3ef4234ac848e3).
// Original test names are retained below. Expected TX bytes come from executing the TS driver.

// idle: no dispense in progress
fn test_pr_169_1() {
    let d = device();
    d.feed("aaff120a0150007f920002010200f50b070601033015980167ff0332000100390c0d3c01000000000000000000000000000000000006a3c119230df901370138014e0158000f0113ffba021bffa9ffe00000000000000000000001008400df0f2c0b3401c900640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff0057f0000500070000350000000029302961017aa3000000c701000000000000010000000000320005a000000000000100004600390102000451ffda1e0800000000000144220a0001000000000000000000000000000000000003e803f602f201a5022c0300000000002000303436425700390104004503000082000000004734101f1fd91e06d22f010efdfdfdebc50afcfc01fc0100004801e00000000000000000000000000000000000000000000000007847d90eeb2d1800e01b64bb");
    expect_props(d, #{"last_water_type": "cold_water", "dispense_state": "idle", "dispensing": "false", "hot_water_amount": "0", "cold_water_amount": "0", "normal_water_amount": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// hot water: "preparing" is not yet dispensing
fn test_pr_169_2() {
    let d = device();
    d.feed("aaff120a0151007fb40002010300f6050b070601033015980167ff01195a0100390c0d3c0a010000000000000000000000000000020006a8f9181c0ef9011b012c02c8022800340111ffb10230ffe0000300000080000001000000010186060a0e250c3401c100640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff00638e00050007000035010001002d302961017aa3037000c0053a003802af03730877087a003f3205a000000000000100017f0044000208045100b17e0000000000000144200a0001000000f900000000000e0000000100000003e803f602f201a5024402000000000020003034364257008701040045030000820000000047300f1a1a011f06c02c0330fdfdfde1f809fcfc01fc0100004901e000000000000000000000000000000000000000000000000078470130e12a1800e069f5bb");
    expect_props(d, #{"last_water_type": "hot_water", "dispense_state": "preparing", "dispensing": "false", "hot_water_amount": "0", "cold_water_amount": "0", "normal_water_amount": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a real pour outranks another outlet that is still preparing
fn test_pr_169_3() {
    let d = device();
    d.feed("aaff120a0151007fa70002010300f6010b070601033015980167ff010c5a0100390c0d3c01000000000000000000000000007800020006a4a72b120ef9005c011a01370135000b0112ffc90228ff81ffa1000000000000000000000100847273211b0c3401c900640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff006110000500070000350101010033302961017aa301b800c4053a003b01640164046104e7003c3205a000000000000100016400440003030451ff341a0800000000000142220a0001000000000000000000000000000000000003e803f602f201a50232030000000000200030343642570092010400450300008200000000472f0e1d1dd91e05bd2a0106fdfdfde1ee09fcfc01fc0100004801e00000000000000000000000000000000000000000000000007847d906e12a1800e02231bb");
    expect_props(d, #{"last_water_type": "hot_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "0", "cold_water_amount": "120", "normal_water_amount": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// hot water: dispensing 120 ml
fn test_pr_169_4() {
    let d = device();
    d.feed("aaff120a0151007fa80002010300f6030b070601033015980167ff010c5a0100390c0d3c01000101000001000000000000000000780006a5f908130ef903c0012203d203d8001f0111ffc30299ff79ff9f0000000000000100da0001018902ea3a1b0c3401c900640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff006142000500070000340001010032302961017aa301ae00c0053a003b018c00f904e004a7003b3205a000000000000100016400450003030451ff33120800000000000142220a0001000000000000000000000000000000000003e803f602f201a50232030000000000200030343642570067010400450300008200000000472f0e1d1dd91e05bd2a0106fdfdfde1ee09fcfc01fc0100004801e00000000000000000000000000000000000000000000000007847d906e12a1800e0ede4bb");
    expect_props(d, #{"last_water_type": "hot_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "120", "cold_water_amount": "0", "normal_water_amount": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// filtered water: dispensing 120 ml
fn test_pr_169_5() {
    let d = device();
    d.feed("aaff120a0151007fad0002010300f6030b070601033015980167ff020c000100390c0d3c01000101000100000000000078000000000006a71929140ef900f20123037d02ad001f0113ffb30240ff65ff960000000000000100e00001018902a81f1d0c3401c900640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff0061fc000500070000340001010033302961017aa3019000c5053a00390146014c0405045700393205a000000000000100016400440003030451ff21120800000000000142220a0001000000000000000000000000000000000003e803f602f201a5023203000000000020003034364257003401040045030000820000000047300f3a3a191e05be2b0118fdfdfde1f309fcfc01fc0100004801e000000000000000000000000000000000000000000000000078471918e12a1800e0da03bb");
    expect_props(d, #{"last_water_type": "normal_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "0", "cold_water_amount": "0", "normal_water_amount": "120"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// cold water: dispensing 250 ml
fn test_pr_169_6() {
    let d = device();
    d.feed("aaff120a0151007faf0002010300f6030b070601033015980167ff0319000100390c0d3c0100010100000000000100000000fa00000006a8f913170ef90070012303300295002f0111ffa00234ff57ff8d0000000000000101d90001018902c209200c3401c900640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff006338000500070000350101010033302961017aa3018600c3053a0039017f020604b7046500253205a000000000000100016400440003030451ff20120800000000000140200a000100770077007700050007000d010101000303e803f602f201a5023203000000000020003034364257005101040045030000820000000047300f3a3a191e05be2b0118fdfdfde1f309fcfc01fc0100004801e000000000000000000000000000000000000000000000000078471918e12a1800e0f845bb");
    expect_props(d, #{"last_water_type": "cold_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "0", "cold_water_amount": "250", "normal_water_amount": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the last dispensed water type persists once the pour ends
fn test_pr_169_7() {
    let d = device();
    d.feed("aaff120a0150007f920002010200f50b070601033015980167ff0332000100390c0d3c01000000000000000000000000000000000006a3c119230df901370138014e0158000f0113ffba021bffa9ffe00000000000000000000001008400df0f2c0b3401c900640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff0057f0000500070000350000000029302961017aa3000000c701000000000000010000000000320005a000000000000100004600390102000451ffda1e0800000000000144220a0001000000000000000000000000000000000003e803f602f201a5022c0300000000002000303436425700390104004503000082000000004734101f1fd91e06d22f010efdfdfdebc50afcfc01fc0100004801e00000000000000000000000000000000000000000000000007847d90eeb2d1800e01b64bb");
    expect_props(d, #{"last_water_type": "cold_water", "dispense_state": "idle", "dispensing": "false", "hot_water_amount": "0", "cold_water_amount": "0", "normal_water_amount": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// 337- and 336-byte state frames decode to the same field offsets
fn test_pr_169_8() {
    let d = device();
    d.feed("aaff120a0151007faf0002010300f6030b070601033015980167ff0319000100390c0d3c0100010100000000000100000000fa00000006a8f913170ef90070012303300295002f0111ffa00234ff57ff8d0000000000000101d90001018902c209200c3401c900640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff006338000500070000350101010033302961017aa3018600c3053a0039017f020604b7046500253205a000000000000100016400440003030451ff20120800000000000140200a000100770077007700050007000d010101000303e803f602f201a5023203000000000020003034364257005101040045030000820000000047300f3a3a191e05be2b0118fdfdfde1f309fcfc01fc0100004801e000000000000000000000000000000000000000000000000078471918e12a1800e0f845bb");
    expect_props(d, #{"last_water_type": "cold_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "0", "cold_water_amount": "250", "normal_water_amount": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// 337- and 336-byte state frames decode to the same field offsets
fn test_pr_169_9() {
    let d = device();
    d.feed("aaff120a0150007f920002010200f50b070601033015980167ff0332000100390c0d3c01000000000000000000000000000000000006a3c119230df901370138014e0158000f0113ffba021bffa9ffe00000000000000000000001008400df0f2c0b3401c900640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff0057f0000500070000350000000029302961017aa3000000c701000000000000010000000000320005a000000000000100004600390102000451ffda1e0800000000000144220a0001000000000000000000000000000000000003e803f602f201a5022c0300000000002000303436425700390104004503000082000000004734101f1fd91e06d22f010efdfdfdebc50afcfc01fc0100004801e00000000000000000000000000000000000000000000000007847d90eeb2d1800e01b64bb");
    expect_props(d, #{"last_water_type": "cold_water", "dispense_state": "idle", "dispensing": "false", "hot_water_amount": "0", "cold_water_amount": "0", "normal_water_amount": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// all locks released, all features on
fn test_pr_169_10() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020103ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000151cbb");
    expect_props(d, #{"cock_state": "on", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// hot water lock engaged
fn test_pr_169_11() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000000ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a00000000000000000000000100006400000401010000000102000029cdbb");
    expect_props(d, #{"cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "true", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// ice lock engaged
fn test_pr_169_12() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000000ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000000ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a0000000000000000000000010100640000040101000000010200002e56bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "true", "ice_lock": "true", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// ice-only lever enabled
fn test_pr_169_13() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020103ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000020103ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a0000000000000000000000010001640000050101000000010200001eb2bb");
    expect_props(d, #{"cock_state": "on", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "true", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// ice-first mode enabled
fn test_pr_169_14() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020103ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000020103ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010101000001020000ddb2bb");
    expect_props(d, #{"cock_state": "on", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "true", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// child lock engaged
fn test_pr_169_15() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020001ff01015aff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020001ff01015aff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a00000000000000000000000100006400010401010000000102000092c1bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "true", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": "90"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// ice maker switched off
fn test_pr_169_16() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000000000064000004010100000001020000088fbb");
    expect_props(d, #{"cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "false", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// high-temperature sterilisation running
fn test_pr_169_17() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000000000064000002010100000001020000020003ff0101ffff0001010201003c090d0c390001000104000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000000000064000002010100000001020000216abb");
    expect_props(d, #{"cock_state": "off", "ice_status": "drying_iceenable", "sterilize_state": "flush", "sterilizing": "true", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "false", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// hot water tank temperature
fn test_pr_169_18() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020001ff01015aff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a0000000000000000000000010000640000040101000000010200005ef7bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": "90"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// hot water temperature clears when the pour ends
fn test_pr_169_19() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020001ff01015aff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a0000000000000000000000010000640000040101000000010200005ef7bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": "90"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020103ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000151cbb");
    expect_props(d, #{"cock_state": "on", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// ice status is decoded
fn test_pr_169_20() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020103ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000151cbb");
    expect_props(d, #{"cock_state": "on", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// ice status is decoded
fn test_pr_169_21() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000000000064000004010100000001020000088fbb");
    expect_props(d, #{"cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "false", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// cock state is decoded
fn test_pr_169_22() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020103ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000151cbb");
    expect_props(d, #{"cock_state": "on", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// do not disturb is decoded
fn test_pr_169_23() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000000000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020003ff0101ffff0001010201003c090d0c390001000000000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff010e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000ca5fbb");
    expect_props(d, #{"cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "true", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// do not disturb is decoded
fn test_pr_169_24() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000000000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff010e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020003ff0101ffff0001010201003c090d0c390001000000000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000268fbb");
    expect_props(d, #{"cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// ice making during do not disturb is decoded
fn test_pr_169_25() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000000000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff010e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020003ff0101ffff0001010201003c090d0c390001000000000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff010e001500ffff0328465a000000005a0000000000000000000000010000640000040101000000010200015c24bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "true", "dnd_ice_mode": "true", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// ice making during do not disturb is decoded
fn test_pr_169_26() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000000000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff010e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020001020003ff0101ffff0001010201003c090d0c390001000000000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff010e001500ffff0328465a000000005a0000000000000000000000010000640000040101000000010200007ac1bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "true", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// do not disturb start/end hour are decoded as raw UTC (panel shows KST)
fn test_pr_169_27() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000000000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff010e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020003ff0101ffff0001010201003c090d0c390001000000000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff010d001500ffff0328465a000000005a0000000000000000000000010000640000040101000000010200001751bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "true", "dnd_ice_mode": "false", "dnd_start_hour": "13", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// do not disturb start/end hour are decoded as raw UTC (panel shows KST)
fn test_pr_169_28() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000000000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff010d001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020003ff0101ffff0001010201003c090d0c390001000000000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff010d001400ffff0328465a000000005a000000000000000000000001000064000004010100000001020000d49abb");
    expect_props(d, #{"cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "true", "dnd_ice_mode": "false", "dnd_start_hour": "13", "dnd_end_hour": "20", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// display brightness is decoded
fn test_pr_169_29() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a00000000000000000000000100003c0000050101000000010200002266bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "60", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// time format is decoded
fn test_pr_169_30() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064010005010100000001020000662dbb");
    expect_props(d, #{"cock_state": "off", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "24", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// display mode is decoded for all three captured states
fn test_pr_169_31() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000101020000020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100010001020000d1bfbb");
    expect_props(d, #{"cock_state": "off", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "always_on", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// display mode is decoded for all three captured states
fn test_pr_169_32() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000101020000cf09bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "waiting_screen_clock", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// display mode is decoded for all three captured states
fn test_pr_169_33() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001010064000005010100000001020000cba4bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "true", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// display dimming and off timeouts are decoded in minutes
fn test_pr_169_34() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000005020000afa9bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "5", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// display dimming and off timeouts are decoded in minutes
fn test_pr_169_35() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001050000e0c8bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "5", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// product sound, button sound and voice guidance are decoded
fn test_pr_169_36() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001010064000005010100000001020000cba4bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "true", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// product sound, button sound and voice guidance are decoded
fn test_pr_169_37() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001010064000005010100000001020000cba4bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "true", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// product sound, button sound and voice guidance are decoded
fn test_pr_169_38() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000020003ff0101ffff0001010201013c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000261fbb");
    expect_props(d, #{"cock_state": "off", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "true", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// voice volume is decoded
fn test_pr_169_39() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000020003ff0101ffff00010102010014090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000bab1bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "20", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// default water type and amount preset are decoded
fn test_pr_169_40() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000020003ff0101ffff0001020201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a0000000000000000000000010000640000050101000000010200000493bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "normal_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// default water type and amount preset are decoded
fn test_pr_169_41() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000020003ff0101ffff0001010401003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a00000000000000000000000100006400000501010000000102000036f1bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_1000ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// lever dispensing type is decoded
fn test_pr_169_42() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a0000000000000000000000010000640000050101000000010201005669bb");
    expect_props(d, #{"cock_state": "off", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "click", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// frames without the AA..BB envelope are ignored
fn test_pr_169_43() {
    let d = device();
    d.feed("001122");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// an AA..BB frame of unknown length is ignored
fn test_pr_169_44() {
    let d = device();
    d.feed("aa06ffffff55bb");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a truncated state frame does not throw or publish
fn test_pr_169_45() {
    let d = device();
    d.feed("aaff120a0151007fa8000201030000bb");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a state frame whose variable-region length overruns the buffer is ignored
fn test_pr_169_46() {
    let d = device();
    d.feed("aaff120a0150007f92000201ff00f50b070601033015980167ff0332000100390c0d3c01000000000000000000000000000000000006a3c119230df901370138014e0158000f0113ffba021bffa9ffe00000000000000000000001008400df0f2c0b3401c900640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff0057f0000500070000350000000029302961017aa3000000c701000000000000010000000000320005a000000000000100004600390102000451ffda1e0800000000000144220a0001000000000000000000000000000000000003e803f602f201a5022c0300000000002000303436425700390104004503000082000000004734101f1fd91e06d22f010efdfdfdebc50afcfc01fc0100004801e00000000000000000000000000000000000000000000000007847d90eeb2d1800e01b64bb");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// ice lock ON and OFF reproduce the captured frames byte-for-byte
fn test_pr_169_47() {
    let d = device();
    d.set("ice_lock", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("ice_lock", "false");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffedbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// ice-only lever ON and OFF reproduce the captured frames byte-for-byte
fn test_pr_169_48() {
    let d = device();
    d.set("ice_lever", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("ice_lever", "false");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffedbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// ice-first mode ON and OFF reproduce the captured frames byte-for-byte
fn test_pr_169_49() {
    let d = device();
    d.set("ice_first_mode", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff01ffffffffffffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("ice_first_mode", "false");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffedbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// invalid values and uncaptured properties never transmit
fn test_pr_169_50() {
    let d = device();
    d.set("ice_lock", "invalid");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("ice_maker", "false");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("does-not-exist", "true");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// default hot water temperature reproduces every captured preset
fn test_pr_169_51() {
    let d = device();
    d.set("default_hot_water_temp", "40");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("default_hot_water_temp", "70");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff02ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffefbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("default_hot_water_temp", "90");
    expect_eq(hex_encode(d.sent()[2]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff03ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeebb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// default hot water temperature is decoded
fn test_pr_169_52() {
    let d = device();
    d.feed("aaff120a010e007fff000100ec00fc020103ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0228465a000000005a000000000000000000000001000064000005010100000001020000020103ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000005010100000001020000a56fbb");
    expect_props(d, #{"cock_state": "on", "ice_status": "ice_enough", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// hot water lock ON and OFF reproduce the captured frames (inverted polarity)
fn test_pr_169_53() {
    let d = device();
    d.set("hot_water_lock", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffedbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("hot_water_lock", "false");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffff01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// cold water enable ON and OFF reproduce the captured frames
fn test_pr_169_54() {
    let d = device();
    d.set("cold_water_enabled", "false");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffedbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("cold_water_enabled", "true");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff01ffffffffffffffffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// do not disturb ON and OFF reproduce the captured frames
fn test_pr_169_55() {
    let d = device();
    d.set("dnd_mode", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("dnd_mode", "false");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffedbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// ice making during do not disturb ON and OFF reproduce the captured frames
fn test_pr_169_56() {
    let d = device();
    d.set("dnd_ice_mode", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff01ffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("dnd_ice_mode", "false");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffedbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// do not disturb start/end hour write the raw UTC value
fn test_pr_169_57() {
    let d = device();
    d.set("dnd_start_hour", "13");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0dffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff90bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("dnd_end_hour", "20");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff14ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff99bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// do not disturb start/end hour reject out-of-range values
fn test_pr_169_58() {
    let d = device();
    d.set("dnd_start_hour", "24");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("dnd_start_hour", "-1");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("dnd_end_hour", "not_a_number");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// display brightness reproduces every captured percent literally
fn test_pr_169_59() {
    let d = device();
    d.set("display_brightness", "60");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3cffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa1bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("display_brightness", "100");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff64ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff49bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("display_brightness", "20");
    expect_eq(hex_encode(d.sent()[2]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff14ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff99bb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("display_brightness", "40");
    expect_eq(hex_encode(d.sent()[3]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff28ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb5bb");
    expect_eq(d.sent().len(), 4);
    expect_eq(d.script_error(), ());
    d.set("display_brightness", "80");
    expect_eq(hex_encode(d.sent()[4]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff50ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5dbb");
    expect_eq(d.sent().len(), 5);
    expect_eq(d.script_error(), ());
}

// display brightness rejects the uncaptured 0% option
fn test_pr_169_60() {
    let d = device();
    d.set("display_brightness", "0");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// time format 24 and 12 reproduce the captured frames
fn test_pr_169_61() {
    let d = device();
    d.set("time_format", "24");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("time_format", "12");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffedbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// display mode writes the captured mutually-exclusive byte pairs
fn test_pr_169_62() {
    let d = device();
    d.set("display_mode", "always_on");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0001ffffffffffffffffffffffffffffffffffffffffffefbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("display_mode", "waiting_screen_clock");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0100ffffffffffffffffffffffffffffffffffffffffffefbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("display_mode", "off");
    expect_eq(hex_encode(d.sent()[2]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000ffffffffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// display dimming timeout reproduces the captured minute values
fn test_pr_169_63() {
    let d = device();
    d.set("display_dimming_min", "5");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff05ffffffffffffffffffffffffffffffffffffffffe8bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("display_dimming_min", "1");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff01ffffffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// display dimming timeout rejects out-of-range minutes
fn test_pr_169_64() {
    let d = device();
    d.set("display_dimming_min", "0");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("display_dimming_min", "31");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("display_dimming_min", "not_a_number");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// display off timeout reproduces the captured minute values
fn test_pr_169_65() {
    let d = device();
    d.set("display_off_min", "5");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff05ffffffffffffffffffffffffffffffffffffffe8bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("display_off_min", "2");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff02ffffffffffffffffffffffffffffffffffffffefbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// product sound ON and OFF reproduce the captured frames
fn test_pr_169_66() {
    let d = device();
    d.set("product_sound", "false");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffedbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("product_sound", "true");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff01ffffffffffffffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// voice volume reproduces the captured percent literals
fn test_pr_169_67() {
    let d = device();
    d.set("voice_volume", "20");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffff14ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff99bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("voice_volume", "60");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffff3cffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa1bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// voice volume rejects the uncaptured 0% option
fn test_pr_169_68() {
    let d = device();
    d.set("voice_volume", "0");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// button sound ON and OFF reproduce the captured frames
fn test_pr_169_69() {
    let d = device();
    d.set("button_sound", "false");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffedbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("button_sound", "true");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffff01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// voice guidance ON and OFF reproduce the captured frames
fn test_pr_169_70() {
    let d = device();
    d.set("voice_guidance", "true");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffff01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("voice_guidance", "false");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffedbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// default water type reproduces every captured selection
fn test_pr_169_71() {
    let d = device();
    d.set("default_water_type", "normal_water");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffff02ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffefbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("default_water_type", "cold_water");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffff03ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeebb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("default_water_type", "recent_water");
    expect_eq(hex_encode(d.sent()[2]), "aa95f017ffffffffffffffffffff01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// default water amount reproduces every captured preset
fn test_pr_169_72() {
    let d = device();
    d.set("default_water_amount", "preset_1000ml");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffff04ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe9bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("default_water_amount", "preset_250ml");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffff02ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffefbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("default_water_amount", "last_used");
    expect_eq(hex_encode(d.sent()[2]), "aa95f017ffffffffffffffffffffff05ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe8bb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("default_water_amount", "preset_120ml");
    expect_eq(hex_encode(d.sent()[3]), "aa95f017ffffffffffffffffffffff01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 4);
    expect_eq(d.script_error(), ());
    d.set("default_water_amount", "preset_500ml");
    expect_eq(hex_encode(d.sent()[4]), "aa95f017ffffffffffffffffffffff03ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeebb");
    expect_eq(d.sent().len(), 5);
    expect_eq(d.script_error(), ());
}

// lever dispensing type reproduces both captured modes
fn test_pr_169_73() {
    let d = device();
    d.set("lever_dispensing_type", "click");
    expect_eq(hex_encode(d.sent()[0]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff01ffffffffffffffffffffffffffffffffffffecbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("lever_dispensing_type", "pressing");
    expect_eq(hex_encode(d.sent()[1]), "aa95f017ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffedbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// a select property sent an unrecognised label never transmits
fn test_pr_169_74() {
    let d = device();
    d.set("default_water_type", "not_a_real_option");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("lever_dispensing_type", "not_a_real_option");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// every published enum value is declared in its options list
fn test_pr_169_75() {
    let d = device();
    d.feed("aaff120a0150007f920002010200f50b070601033015980167ff0332000100390c0d3c01000000000000000000000000000000000006a3c119230df901370138014e0158000f0113ffba021bffa9ffe00000000000000000000001008400df0f2c0b3401c900640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff0057f0000500070000350000000029302961017aa3000000c701000000000000010000000000320005a000000000000100004600390102000451ffda1e0800000000000144220a0001000000000000000000000000000000000003e803f602f201a5022c0300000000002000303436425700390104004503000082000000004734101f1fd91e06d22f010efdfdfdebc50afcfc01fc0100004801e00000000000000000000000000000000000000000000000007847d90eeb2d1800e01b64bb");
    expect_props(d, #{"last_water_type": "cold_water", "dispense_state": "idle", "dispensing": "false", "hot_water_amount": "0", "cold_water_amount": "0", "normal_water_amount": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff120a0151007faf0002010300f6030b070601033015980167ff0319000100390c0d3c0100010100000000000100000000fa00000006a8f913170ef90070012303300295002f0111ffa00234ff57ff8d0000000000000101d90001018902c209200c3401c900640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff006338000500070000350101010033302961017aa3018600c3053a0039017f020604b7046500253205a000000000000100016400440003030451ff20120800000000000140200a000100770077007700050007000d010101000303e803f602f201a5023203000000000020003034364257005101040045030000820000000047300f3a3a191e05be2b0118fdfdfde1f309fcfc01fc0100004801e000000000000000000000000000000000000000000000000078471918e12a1800e0f845bb");
    expect_props(d, #{"last_water_type": "cold_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "0", "cold_water_amount": "250", "normal_water_amount": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff120a0151007fb40002010300f6050b070601033015980167ff01195a0100390c0d3c0a010000000000000000000000000000020006a8f9181c0ef9011b012c02c8022800340111ffb10230ffe0000300000080000001000000010186060a0e250c3401c100640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff00638e00050007000035010001002d302961017aa3037000c0053a003802af03730877087a003f3205a000000000000100017f0044000208045100b17e0000000000000144200a0001000000f900000000000e0000000100000003e803f602f201a5024402000000000020003034364257008701040045030000820000000047300f1a1a011f06c02c0330fdfdfde1f809fcfc01fc0100004901e000000000000000000000000000000000000000000000000078470130e12a1800e069f5bb");
    expect_props(d, #{"last_water_type": "hot_water", "dispense_state": "preparing", "dispensing": "false", "hot_water_amount": "0", "cold_water_amount": "0", "normal_water_amount": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff120a0151007fa70002010300f6010b070601033015980167ff010c5a0100390c0d3c01000000000000000000000000007800020006a4a72b120ef9005c011a01370135000b0112ffc90228ff81ffa1000000000000000000000100847273211b0c3401c900640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff006110000500070000350101010033302961017aa301b800c4053a003b01640164046104e7003c3205a000000000000100016400440003030451ff341a0800000000000142220a0001000000000000000000000000000000000003e803f602f201a50232030000000000200030343642570092010400450300008200000000472f0e1d1dd91e05bd2a0106fdfdfde1ee09fcfc01fc0100004801e00000000000000000000000000000000000000000000000007847d906e12a1800e02231bb");
    expect_props(d, #{"last_water_type": "hot_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "0", "cold_water_amount": "120", "normal_water_amount": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff120a0151007fa80002010300f6030b070601033015980167ff010c5a0100390c0d3c01000101000001000000000000000000780006a5f908130ef903c0012203d203d8001f0111ffc30299ff79ff9f0000000000000100da0001018902ea3a1b0c3401c900640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff006142000500070000340001010032302961017aa301ae00c0053a003b018c00f904e004a7003b3205a000000000000100016400450003030451ff33120800000000000142220a0001000000000000000000000000000000000003e803f602f201a50232030000000000200030343642570067010400450300008200000000472f0e1d1dd91e05bd2a0106fdfdfde1ee09fcfc01fc0100004801e00000000000000000000000000000000000000000000000007847d906e12a1800e0ede4bb");
    expect_props(d, #{"last_water_type": "hot_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "120", "cold_water_amount": "0", "normal_water_amount": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff120a0151007fad0002010300f6030b070601033015980167ff020c000100390c0d3c01000101000100000000000078000000000006a71929140ef900f20123037d02ad001f0113ffb30240ff65ff960000000000000100e00001018902a81f1d0c3401c900640c1932640103370000000001010c5a0000000000000000000000000000000000000e0015000300ff00ff0061fc000500070000340001010033302961017aa3019000c5053a00390146014c0405045700393205a000000000000100016400440003030451ff21120800000000000142220a0001000000000000000000000000000000000003e803f602f201a5023203000000000020003034364257003401040045030000820000000047300f3a3a191e05be2b0118fdfdfde1f309fcfc01fc0100004801e000000000000000000000000000000000000000000000000078471918e12a1800e0da03bb");
    expect_props(d, #{"last_water_type": "normal_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "0", "cold_water_amount": "0", "normal_water_amount": "120"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020103ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000151cbb");
    expect_props(d, #{"last_water_type": "normal_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "0", "cold_water_amount": "0", "normal_water_amount": "120", "cock_state": "on", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020001ff01015aff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a0000000000000000000000010000640000040101000000010200005ef7bb");
    expect_props(d, #{"last_water_type": "normal_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "0", "cold_water_amount": "0", "normal_water_amount": "120", "cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": "90"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000000ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a00000000000000000000000100006400000401010000000102000029cdbb");
    expect_props(d, #{"last_water_type": "normal_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "0", "cold_water_amount": "0", "normal_water_amount": "120", "cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "true", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000000ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000000ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a0000000000000000000000010100640000040101000000010200002e56bb");
    expect_props(d, #{"last_water_type": "normal_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "0", "cold_water_amount": "0", "normal_water_amount": "120", "cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "true", "ice_lock": "true", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff120a010e007fff000100ec00fc020001ff01015aff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020001ff01015aff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a00000000000000000000000100006400010401010000000102000092c1bb");
    expect_props(d, #{"last_water_type": "normal_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "0", "cold_water_amount": "0", "normal_water_amount": "120", "cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "true", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "true", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": "90"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000001000064000004010100000001020000020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000000000064000004010100000001020000088fbb");
    expect_props(d, #{"last_water_type": "normal_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "0", "cold_water_amount": "0", "normal_water_amount": "120", "cock_state": "off", "ice_status": "full", "sterilize_state": "off", "sterilizing": "false", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "false", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaff120a010e007fff000100ec00fc020003ff0101ffff0001010201003c090d0c390001000100000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000000000064000002010100000001020000020003ff0101ffff0001010201003c090d0c390001000104000001ff0000000c193264fc03003701015a0c010000000000000000ffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff000e001500ffff0328465a000000005a000000000000000000000000000064000002010100000001020000216abb");
    expect_props(d, #{"last_water_type": "normal_water", "dispense_state": "dispensing", "dispensing": "true", "hot_water_amount": "0", "cold_water_amount": "0", "normal_water_amount": "120", "cock_state": "off", "ice_status": "drying_iceenable", "sterilize_state": "flush", "sterilizing": "true", "hot_water_lock": "false", "ice_lock": "false", "ice_lever": "false", "child_lock": "false", "cold_water_enabled": "true", "dnd_mode": "false", "dnd_ice_mode": "false", "dnd_start_hour": "14", "dnd_end_hour": "21", "ice_maker": "false", "ice_first_mode": "false", "product_sound": "true", "button_sound": "true", "voice_guidance": "false", "display_brightness": "100", "voice_volume": "60", "time_format": "12", "display_mode": "off", "display_dimming_min": "1", "display_off_min": "2", "default_water_type": "recent_water", "default_water_amount": "preset_250ml", "lever_dispensing_type": "pressing", "default_hot_water_temp": "90", "hot_water_temp": ""});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}
