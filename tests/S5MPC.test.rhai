import "runtime_test" as runtime;
// BEGIN PR VECTORS
// Regression vectors from rethink PR #173 (6c239b821cb8dcabf033827745454a3053bd3bc5).
// Original test names are retained below. Expected TX bytes come from executing the TS driver.

// publishes this-cycle energy from the record+17 Wh counter
fn test_pr_173_1() {
    let d = device();
    d.feed("aa2331eb001b00000100000000040000000000002000000251000000000163420077bb");
    expect_props(d, #{"power": "false", "status": "power_off", "course": "none", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "remote_start": "false", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "593"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// remote start follows the verified flags bit
fn test_pr_173_2() {
    let d = device();
    d.feed("aa4031ec001b010001000100000000000000000020000000000000000001624200001b01000100010000000000000000002800000000000000000162420080bb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b010001000100000000000000000028000000000000000001624200001b01000100010000000000000000002000000000000000000162420080bb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "false", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// child lock follows the verified flags bit, independent of remote start
fn test_pr_173_3() {
    let d = device();
    d.feed("aa4031ec001b010001000100000000000000000020000000000000000001634200001b01000100010000000000000000002100000000000000000163420085bb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "false", "child_lock": "true", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b010001000100000000000000000021000000000000000001634200001b01000100010000000000000000002000000000000000000163420085bb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "false", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b010001000100000000000000000020000000000000000001624200001b01000100010000000000000000002800000000000000000162420080bb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// status tracks the verified state codes
fn test_pr_173_4() {
    let d = device();
    d.feed("aa4031ec001b320027002701000100000000000028000000000000000001624200001b03002700270100320000000000002800000000000000000162420088bb");
    expect_props(d, #{"power": "true", "status": "pause", "course": "styling_standard", "remaining_time": "39", "initial_time": "39", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b010001000100000000000000000028000000000000000001624200001b32002700270100010000000000002800000000000000000162420009bb");
    expect_props(d, #{"power": "true", "status": "steam_preparing", "course": "styling_standard", "remaining_time": "39", "initial_time": "39", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b030027002701003200000000000028000000000000000001624200001b080014001403000300000000130008000000000000000001624200d1bb");
    expect_props(d, #{"power": "true", "status": "reserved", "course": "styling_quick", "remaining_time": "20", "initial_time": "20", "reserve_time": "1140", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0", "course_select": "styling_quick"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b01003b003b1c000300000000000020000000000063000001634200001b00003b003b000001000000000000200000000000000000016342006cbb");
    expect_props(d, #{"power": "false", "status": "power_off", "course": "none", "remaining_time": "0", "initial_time": "59", "reserve_time": "0", "remote_start": "false", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0", "course_select": "styling_quick"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// remaining time reads 0 once the cycle is done
fn test_pr_173_5() {
    let d = device();
    d.feed("aa4031ec001b040001012c0c003800000000000028000002510000000001634200001b000001012c000004000000000000200000025100000000016342004abb");
    expect_props(d, #{"power": "false", "status": "power_off", "course": "none", "remaining_time": "0", "initial_time": "104", "reserve_time": "0", "remote_start": "false", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "593"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b01003b003b1c000300000000000020000000000063000001634200001b00003b003b000001000000000000200000000000000000016342006cbb");
    expect_props(d, #{"power": "false", "status": "power_off", "course": "none", "remaining_time": "0", "initial_time": "59", "reserve_time": "0", "remote_start": "false", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b01003b003b1c000300000000000020000000000063000001634200001b04003b003b0000010000000000002000000000000000000163420068bb");
    expect_props(d, #{"power": "true", "status": "complete", "course": "none", "remaining_time": "0", "initial_time": "59", "reserve_time": "0", "remote_start": "false", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a smart course whose base id is 13/14/16/27/67/78 still reports a course label
fn test_pr_173_6() {
    let d = device();
    d.feed("aa4031ec001b01003b003b1c000300000000000028000000000063000001634200001b01011901194300030000000000002800000000000000000179420036bb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "silent", "remaining_time": "85", "initial_time": "85", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a smart course built on base id 67 reports Downloaded Course on `course`, like the washer
fn test_pr_173_7() {
    let d = device();
    d.feed("aa4031ec001b01003b003b1c000300000000000028000000000063000001634200001b010119011943000300000000000028000000000043000001794200f3bb");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "silent", "power": "true", "status": "standby", "course": "downloaded_course", "smart_course": "silent", "remaining_time": "85", "initial_time": "85", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// uses the common Error and Smart diagnosis states declared by the model
fn test_pr_173_8() {
    let d = device();
    d.feed("aa4031ec001b01003b003b1c000300000000000020000000000063000001634200001b05003b003b000001000000000000200000000000000000016342006bbb");
    expect_props(d, #{"power": "true", "status": "error", "course": "none", "remaining_time": "59", "initial_time": "59", "reserve_time": "0", "remote_start": "false", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b01003b003b1c000300000000000020000000000063000001634200001b06003b003b000001000000000000200000000000000000016342006abb");
    expect_props(d, #{"power": "true", "status": "smart_diagnosis", "course": "none", "remaining_time": "59", "initial_time": "59", "reserve_time": "0", "remote_start": "false", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "true", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a running smart course reports the Downloaded Course placeholder, like the washer
fn test_pr_173_9() {
    let d = device();
    d.feed("aa4031ec001b01003b003b1c000300000000000028000000000063000001634200001b010119011911000300000000000028000000000079000001794200ffbb");
    expect_props(d, #{"smart_course_select": "golf_wear_dry", "smart_course": "golf_wear_dry", "power": "true", "status": "standby", "course": "downloaded_course", "remaining_time": "85", "initial_time": "85", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a frame with a corrupted checksum is dropped, not decoded
fn test_pr_173_10() {
    let d = device();
    d.feed("aa4031ec001b010001000100000000000000000020000000000000000001624200001b01000100010000000000000000002800000000000000000162420080bb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b01003b00c41c000300000000000028000000000063000001634200001b010119011911000300000000000028000000000079000001794200ffbb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// error, smart diagnosis and energy stay clear on every captured frame
fn test_pr_173_11() {
    let d = device();
    d.feed("aa4031ec001b010001000100000000000000000020000000000000000001624200001b01000100010000000000000000002800000000000000000162420080bb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b010001000100000000000000000028000000000000000001624200001b01000100010000000000000000002000000000000000000162420080bb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "false", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b320027002701000100000000000028000000000000000001624200001b03002700270100320000000000002800000000000000000162420088bb");
    expect_props(d, #{"power": "true", "status": "pause", "course": "styling_standard", "remaining_time": "39", "initial_time": "39", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0", "course_select": "styling_standard"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b010001000100000000000000000028000000000000000001624200001b32002700270100010000000000002800000000000000000162420009bb");
    expect_props(d, #{"power": "true", "status": "steam_preparing", "course": "styling_standard", "remaining_time": "39", "initial_time": "39", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0", "course_select": "styling_standard"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b030027002701003200000000000028000000000000000001624200001b080014001403000300000000130008000000000000000001624200d1bb");
    expect_props(d, #{"power": "true", "status": "reserved", "course": "styling_quick", "remaining_time": "20", "initial_time": "20", "reserve_time": "1140", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0", "course_select": "styling_quick"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b01003b003b1c000300000000000020000000000063000001634200001b00003b003b000001000000000000200000000000000000016342006cbb");
    expect_props(d, #{"power": "false", "status": "power_off", "course": "none", "remaining_time": "0", "initial_time": "59", "reserve_time": "0", "remote_start": "false", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0", "course_select": "styling_quick"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// non-state frames are ignored
fn test_pr_173_12() {
    let d = device();
    d.feed("aa4031ec001b010001000100000000000000000020000000000000000001624200001b01000100010000000000000000002800000000000000000162420080bb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa083100240052bb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa09317200c9004abb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa37313102015341413337353639313431000066260000800000000000025341413337353639303230000062a80000400000000000d9bb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_173_13() {
    let d = device();
    d.set("course_select", "styling_standard");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_eq(hex_encode(d.sent()[0]), "aa34f02601010004000000000002645a00000005005a05b45a01b4001ab40000000000000000000000000000000000000000fabb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_173_14() {
    let d = device();
    d.set("course_select", "styling_standard");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("store", "true");
    expect_props(d, #{"store": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "19");
    expect_props(d, #{"store": "true", "reserve_hours": "19"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"store": "true", "reserve_hours": "19"});
    expect_eq(hex_encode(d.sent()[0]), "aa34f02601010006000013000002645a00000005005a05b45a01b4001ab4000000000000000000000000000000000000000091bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_173_15() {
    let d = device();
    d.set("course_select", "styling_quick");
    expect_props(d, #{"course_select": "styling_quick"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "19");
    expect_props(d, #{"course_select": "styling_quick", "reserve_hours": "19"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course_select": "styling_quick", "reserve_hours": "19"});
    expect_eq(hex_encode(d.sent()[0]), "aa34f02603010004000013000082645a00000003005a00000001b4000eb4000000000000000000000000000000000000000076bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_173_16() {
    let d = device();
    d.set("course_select", "styling_standard");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_eq(hex_encode(d.sent()[0]), "aa34f02601010004000000000002645a00000005005a05b45a01b4001ab40000000000000000000000000000000000000000fabb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("pause", "");
    expect_eq(hex_encode(d.sent()[1]), "aa09f02404010099bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("resume", "");
    expect_eq(hex_encode(d.sent()[2]), "aa33f026010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1bb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("power_off", "");
    expect_eq(hex_encode(d.sent()[3]), "aa09f0240101009cbb");
    expect_eq(d.sent().len(), 4);
    expect_eq(d.script_error(), ());
}

// smart starts reproduce the captured download + start pairs
fn test_pr_173_17() {
    let d = device();
    d.set("smart_course_select", "golf_wear_dry");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course": "golf_wear_dry"});
    expect_eq(hex_encode(d.sent()[0]), "aa36f025032d11017900000000000080000000000000000000000000000055780000000000000000000000000000000000000000a8bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course": "golf_wear_dry", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course": "golf_wear_dry", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[1]), "aa36f025032d11017900000000000080000000000000000000000000000055780000000000000000000000000000000000000000a8bb");
    expect_eq(hex_encode(d.sent()[2]), "aa34f0261101790400000300008000000000000000000000000000005578000000000000000000000000000000000000000086bb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// smart starts reproduce the captured download + start pairs
fn test_pr_173_18() {
    let d = device();
    d.set("smart_course_select", "snow_raing_drying");
    expect_props(d, #{"smart_course_select": "snow_raing_drying", "smart_course": "snow_raing_drying"});
    expect_eq(hex_encode(d.sent()[0]), "aa36f025032d0a014c0000000000000200000000000300000000000100002d78000000000000000000000000000000000000000072bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"smart_course_select": "snow_raing_drying", "smart_course": "snow_raing_drying", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"smart_course_select": "snow_raing_drying", "smart_course": "snow_raing_drying", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[1]), "aa36f025032d0a014c0000000000000200000000000300000000000100002d78000000000000000000000000000000000000000072bb");
    expect_eq(hex_encode(d.sent()[2]), "aa34f0260a014c0400000300000200000000000300000000000100002d780000000000000000000000000000000000000000a8bb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// selecting a smart course downloads it straight away, like the washer
fn test_pr_173_19() {
    let d = device();
    d.set("smart_course_select", "golf_wear_dry");
    expect_props(d, #{"smart_course_select": "golf_wear_dry", "smart_course": "golf_wear_dry"});
    expect_eq(hex_encode(d.sent()[0]), "aa36f025032d11017900000000000080000000000000000000000000000055780000000000000000000000000000000000000000a8bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// a polled idle frame does not wipe an armed smart course
fn test_pr_173_20() {
    let d = device();
    d.set("smart_course_select", "golf_wear_dry");
    expect_eq(hex_encode(d.sent()[0]), "aa36f025032d11017900000000000080000000000000000000000000000055780000000000000000000000000000000000000000a8bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b01003b003b1c000300000000000020000000000063000001634200001b00003b003b000001000000000000200000000000000000016342006cbb");
    expect_props(d, #{"power": "false", "status": "power_off", "course": "none", "remaining_time": "0", "initial_time": "59", "reserve_time": "0", "remote_start": "false", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// repeated identical status frames do not rewrite the memory file
fn test_pr_173_21() {
    let d = device();
    d.set("smart_course_select", "golf_wear_dry");
    expect_eq(hex_encode(d.sent()[0]), "aa36f025032d11017900000000000080000000000000000000000000000055780000000000000000000000000000000000000000a8bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("smart_course_select", "golf_wear_dry");
    expect_eq(hex_encode(d.sent()[1]), "aa36f025032d11017900000000000080000000000000000000000000000055780000000000000000000000000000000000000000a8bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("smart_course_select", "golf_wear_dry");
    expect_eq(hex_encode(d.sent()[2]), "aa36f025032d11017900000000000080000000000000000000000000000055780000000000000000000000000000000000000000a8bb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// course_select "Downloaded Course" routes Start course to the pre-selected smart course
fn test_pr_173_22() {
    let d = device();
    d.set("smart_course_select", "golf_wear_dry");
    expect_eq(hex_encode(d.sent()[0]), "aa36f025032d11017900000000000080000000000000000000000000000055780000000000000000000000000000000000000000a8bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"reserve_hours": "3"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "downloaded_course");
    expect_props(d, #{"reserve_hours": "3"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[1]), "aa36f025032d11017900000000000080000000000000000000000000000055780000000000000000000000000000000000000000a8bb");
    expect_eq(hex_encode(d.sent()[2]), "aa34f0261101790400000300008000000000000000000000000000005578000000000000000000000000000000000000000086bb");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// a start shows up straight away instead of waiting for the appliance
fn test_pr_173_23() {
    let d = device();
    d.feed("aa4031ec001b010001000100000000000000000020000000000000000001624200001b01000100010000000000000000002800000000000000000162420080bb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("course_select", "styling_standard");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0", "course_select": "styling_standard"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start", "");
    expect_props(d, #{"power": "true", "status": "standby", "course": "styling_standard", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "true", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0", "course_select": "styling_standard"});
    expect_eq(hex_encode(d.sent()[0]), "aa34f02601010004000000000002645a00000005005a05b45a01b4001ab40000000000000000000000000000000000000000fabb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("aa4031ec001b010001000100000000000000000028000000000000000001624200001b01000100010000000000000000002000000000000000000162420080bb");
    expect_props(d, #{"power": "true", "status": "standby", "course": "none", "remaining_time": "1", "initial_time": "1", "reserve_time": "0", "remote_start": "false", "child_lock": "false", "error": "false", "error_message": "Normal", "smart_diagnosis": "false", "energy": "0", "course_select": "styling_standard"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// reserve hours reject anything outside 0 or 3..19
fn test_pr_173_24() {
    let d = device();
    d.set("reserve_hours", "19");
    expect_props(d, #{"reserve_hours": "19"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "20");
    expect_props(d, #{"reserve_hours": "19"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "-1");
    expect_props(d, #{"reserve_hours": "19"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "1");
    expect_props(d, #{"reserve_hours": "19"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "2");
    expect_props(d, #{"reserve_hours": "19"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"reserve_hours": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a reconnect restores the armed smart course instead of resetting to Pants
fn test_pr_173_25() {
    let d = device();
    d.set("smart_course_select", "golf_wear_dry");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course": "golf_wear_dry"});
    expect_eq(hex_encode(d.sent()[0]), "aa36f025032d11017900000000000080000000000000000000000000000055780000000000000000000000000000000000000000a8bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}
