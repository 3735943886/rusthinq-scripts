import "runtime_test" as runtime;
// BEGIN PR VECTORS
// Regression vectors from rethink PR #182 (c4fc160c0363193d0b8adda5e202c10dc10c1a5a).
// Original test names are retained below. Expected TX bytes come from executing the TS driver.

// decodes the current real powered-off EB snapshot
fn test_pr_182_1() {
    let d = device();
    d.feed("aa2130eb00190000000000000000000000000000000000000000000000770023bb");
    expect_props(d, #{"power": "false", "status": "power_off", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// publishes this-cycle energy from the record+18 Wh counter
fn test_pr_182_2() {
    let d = device();
    d.feed("aa3c30ec00190201080114120000030300000000201b0800ad01000000770000190201070114120000030300000000201b0800b001000000770023bb");
    expect_props(d, #{"course_select": "condenser_care", "power": "true", "status": "drying", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "condenser_care", "dry_level": "off", "eco_hybrid": "speed", "steam": "true", "remaining_time": "67", "initial_time": "80", "reserve_time": "0", "energy": "176"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec00190200010114120000030500000000001b0802b301000000770000190400010114120000030700000000081a0802b602000000770012bb");
    expect_props(d, #{"course_select": "condenser_care", "power": "true", "status": "complete", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "condenser_care", "dry_level": "off", "eco_hybrid": "speed", "steam": "true", "remaining_time": "1", "initial_time": "80", "reserve_time": "0", "energy": "694"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// decodes the real Initial EB snapshot
fn test_pr_182_3() {
    let d = device();
    d.feed("aa2130eb001901000000000000000000000000000804000000000000007700d6bb");
    expect_props(d, #{"power": "true", "status": "standby", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// uses the current record in a real EC frame
fn test_pr_182_4() {
    let d = device();
    d.feed("aa2130eb00190000000000000000000000000000000000000000000000770023bb");
    expect_props(d, #{"power": "false", "status": "power_off", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec00190100000000000000000000000000080400000000000000770000190100000000000000000000000000000400000000000000770061bb");
    expect_props(d, #{"power": "true", "status": "standby", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// keeps Error separate from the state enum and derives it from the error code
fn test_pr_182_5() {
    let d = device();
    d.feed("aa2130eb0019050000000000000000000000000000000000000000000077002ebb");
    expect_props(d, #{"power": "true", "status": "error", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa2130eb0019080000000000000000000000000000000000000000000077002bbb");
    expect_props(d, #{"power": "true", "status": "smart_diagnosis", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "true", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// maps the model-declared error byte and safely handles an undefined code
fn test_pr_182_6() {
    let d = device();
    d.feed("aa2130eb00190000000000000100000000000000000000000000000000770022bb");
    expect_props(d, #{"power": "false", "status": "power_off", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "true", "error_message": "te1", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa2130eb00190000000000000000000000000000000000000000000000770023bb");
    expect_props(d, #{"power": "false", "status": "power_off", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa2130eb0019000000000000030000000000000000000000000000000077002cbb");
    expect_props(d, #{"power": "false", "status": "power_off", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "true", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// uses the captured process sub-state for Detecting, Drying, then Pause
fn test_pr_182_7() {
    let d = device();
    d.feed("aa3c30ec00190100000000000000000000000000001900000000000000770000190201280128070003020000000000009b0000000100000077006dbb");
    expect_props(d, #{"power": "true", "status": "detecting", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "standard", "eco_hybrid": "auto", "steam": "false", "remaining_time": "100", "initial_time": "100", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec00190201280128070003020000000000009b000000010000007700001902010f010f070003020200000000001b0000000100000077003fbb");
    expect_props(d, #{"power": "true", "status": "drying", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "standard", "eco_hybrid": "auto", "steam": "false", "remaining_time": "75", "initial_time": "75", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec001902010f010f070003020200000000001b000000010000007700001903010f010f070003020200000000081b00000002000000770091bb");
    expect_props(d, #{"power": "true", "status": "pause", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "standard", "eco_hybrid": "auto", "steam": "false", "remaining_time": "75", "initial_time": "75", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// reports Reserved while a real 19h or 3h reservation is pending
fn test_pr_182_8() {
    let d = device();
    d.feed("aa3c30ec001903010c010f0700030202000000000819000005020000007700001902001e001e070001010013001300019b000000030000007700d1bb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "delicate", "eco_hybrid": "energy", "steam": "false", "remaining_time": "30", "initial_time": "30", "reserve_time": "1140", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec001903013701370700010102123a123a091b000000020000007700001902001e001e07000203000300030001990000000300000077001ebb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "light", "eco_hybrid": "speed", "steam": "false", "remaining_time": "30", "initial_time": "30", "reserve_time": "180", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// reservation flag follows the same rec[15] byte as anti_crease, bit 0x01
fn test_pr_182_9() {
    let d = device();
    d.feed("aa3c30ec001903010c010f0700030202000000000819000005020000007700001902001e001e070001010013001300019b000000030000007700d1bb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "delicate", "eco_hybrid": "energy", "steam": "false", "remaining_time": "30", "initial_time": "30", "reserve_time": "1140", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa2130eb00190000000000000000000000000000000000000000000000770023bb");
    expect_props(d, #{"power": "false", "status": "power_off", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// decodes child lock from the isolated real ON and OFF transition
fn test_pr_182_10() {
    let d = device();
    d.feed("aa3c30ec0019030020002001000002010d380d38010a0800050200000077000019030020002001000002010d380d38110a0800050200000077005dbb");
    expect_props(d, #{"course_select": "steam_refresh", "power": "true", "status": "reserved", "child_lock": "true", "anti_crease": "false", "reservation": "true", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "steam_refresh", "dry_level": "off", "eco_hybrid": "auto", "steam": "true", "remaining_time": "32", "initial_time": "32", "reserve_time": "836", "energy": "5"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec0019030020002001000002010d380d38110a0800050200000077000019030020002001000002010d380d38010a0800050200000077005dbb");
    expect_props(d, #{"course_select": "steam_refresh", "power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "steam_refresh", "dry_level": "off", "eco_hybrid": "auto", "steam": "true", "remaining_time": "32", "initial_time": "32", "reserve_time": "836", "energy": "5"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a frame with a corrupted checksum is dropped, not decoded
fn test_pr_182_11() {
    let d = device();
    d.feed("aa2130eb00190000000000000000000000000000000000000000000000770023bb");
    expect_props(d, #{"power": "false", "status": "power_off", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec001903002000df01000002010d380d38010a0800050200000077000019030020002001000002010d380d38110a0800050200000077005dbb");
    expect_props(d, #{"power": "false", "status": "power_off", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// does not mistake the unrelated 0x08 bit for child lock
fn test_pr_182_12() {
    let d = device();
    d.feed("aa2130eb001901000000000000000000000000000804000000000000007700d6bb");
    expect_props(d, #{"power": "true", "status": "standby", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec001902010f010f070003020200000000001b000000010000007700001903010f010f070003020200000000081b00000002000000770091bb");
    expect_props(d, #{"power": "true", "status": "pause", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "standard", "eco_hybrid": "auto", "steam": "false", "remaining_time": "75", "initial_time": "75", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// keeps child lock and anti-crease on separate bits of the same byte
fn test_pr_182_13() {
    let d = device();
    d.feed("aa3c30ec001903011401140700040202033b033b0919000000020000007700001902001e001e0700050300030003000399000000030000007700a5bb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "true", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "strong", "eco_hybrid": "speed", "steam": "false", "remaining_time": "30", "initial_time": "30", "reserve_time": "180", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec0019030020002001000002010d380d38010a0800050200000077000019030020002001000002010d380d38110a0800050200000077005dbb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "true", "anti_crease": "false", "reservation": "true", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "steam_refresh", "dry_level": "off", "eco_hybrid": "auto", "steam": "true", "remaining_time": "32", "initial_time": "32", "reserve_time": "836", "energy": "5", "course_select": "steam_refresh"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// decodes anti-crease from the single-toggle ON and OFF pair
fn test_pr_182_14() {
    let d = device();
    d.feed("aa3c30ec001903011401140700040202033b033b0919000000020000007700001902001e001e0700050300030003000399000000030000007700a5bb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "true", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "strong", "eco_hybrid": "speed", "steam": "false", "remaining_time": "30", "initial_time": "30", "reserve_time": "180", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec001902001e001e070005030003000300019b000000030000007700001902001e001e070005030003000300019900000003000000770051bb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "strong", "eco_hybrid": "speed", "steam": "false", "remaining_time": "30", "initial_time": "30", "reserve_time": "180", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// decodes remote start from the isolated real ON and OFF transition
fn test_pr_182_15() {
    let d = device();
    d.feed("aa3c30ec00190100000000000000000000000000000900000000000000770000190100000000000000000000000000001900000000000000770013bb");
    expect_props(d, #{"power": "true", "status": "standby", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec00190100000000000000000000000000001900000000000000770000190100000000000000000000000000001800000000000000770000bb");
    expect_props(d, #{"power": "true", "status": "standby", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// decodes course, dry level, eco and steam from real reservation frames
fn test_pr_182_16() {
    let d = device();
    d.feed("aa3c30ec001903010c010f0700030202000000000819000005020000007700001902001e001e070001010013001300019b000000030000007700d1bb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "delicate", "eco_hybrid": "energy", "steam": "false", "remaining_time": "30", "initial_time": "30", "reserve_time": "1140", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec001902010a010a050002020203000300031b000000030000007700001902010a010a0500020202023b023b031b0000000300000077007fbb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "true", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "easy_care", "dry_level": "light", "eco_hybrid": "auto", "steam": "false", "remaining_time": "70", "initial_time": "70", "reserve_time": "179", "energy": "0", "course_select": "easy_care"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec00190202370237040000030204000400031b00000003000000770000190202370237040000030204000400031900000003000000770039bb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "true", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "bulky_item", "dry_level": "off", "eco_hybrid": "speed", "steam": "false", "remaining_time": "175", "initial_time": "175", "reserve_time": "240", "energy": "0", "course_select": "bulky_item"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec00190301000100170000020204000400091b0000000200000077000019020128012802000002000300030001990000000300000077003ebb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "towel", "dry_level": "off", "eco_hybrid": "auto", "steam": "false", "remaining_time": "100", "initial_time": "100", "reserve_time": "180", "energy": "0", "course_select": "towel"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec001903010a010a0500020202023b023b0b1900000002000000770000190200200020010000020103000300011908000003000000770002bb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "steam_refresh", "dry_level": "off", "eco_hybrid": "auto", "steam": "true", "remaining_time": "32", "initial_time": "32", "reserve_time": "180", "energy": "0", "course_select": "steam_refresh"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec0019030020002001000002010b000b0001190800010200000077000019020020002001000002010b000b00011908000103000000770073bb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "steam_refresh", "dry_level": "off", "eco_hybrid": "auto", "steam": "true", "remaining_time": "32", "initial_time": "32", "reserve_time": "660", "energy": "1", "course_select": "steam_refresh"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec00190301000100160000030103000300091900000002000000770000190201140114120000030100000000001908000003000000770084bb");
    expect_props(d, #{"power": "true", "status": "steam", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "condenser_care", "dry_level": "off", "eco_hybrid": "speed", "steam": "true", "remaining_time": "80", "initial_time": "80", "reserve_time": "0", "energy": "0", "course_select": "condenser_care"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_17() {
    let d = device();
    d.set("course_select", "steam_refresh");
    expect_props(d, #{"course_select": "steam_refresh", "dry_level_select": "off"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"course_select": "steam_refresh", "dry_level_select": "off"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "steam_refresh", "dry_level_select": "off"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260100020000000000000003080000b7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_18() {
    let d = device();
    d.set("course_select", "towel");
    expect_props(d, #{"course_select": "towel", "dry_level_select": "off"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"course_select": "towel", "dry_level_select": "off"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "towel", "dry_level_select": "off"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f02602000200000000000000030000008ebb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_19() {
    let d = device();
    d.set("course_select", "bulky_item");
    expect_props(d, #{"course_select": "bulky_item", "dry_level_select": "off", "eco_hybrid_select": "speed", "anti_crease_select": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"course_select": "bulky_item", "dry_level_select": "off", "eco_hybrid_select": "speed", "anti_crease_select": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "bulky_item", "dry_level_select": "off", "eco_hybrid_select": "speed", "anti_crease_select": "true"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260400030000000000000203000000b5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_20() {
    let d = device();
    d.set("course_select", "easy_care");
    expect_props(d, #{"course_select": "easy_care"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"course_select": "easy_care"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "easy_care"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260503020000000000000003000000b4bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_21() {
    let d = device();
    d.set("course_select", "standard");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260703020000000000000001000000b4bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_22() {
    let d = device();
    d.set("course_select", "sports_wear");
    expect_props(d, #{"course_select": "sports_wear", "dry_level_select": "off", "eco_hybrid_select": "energy"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"course_select": "sports_wear", "dry_level_select": "off", "eco_hybrid_select": "energy"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "sports_wear", "dry_level_select": "off", "eco_hybrid_select": "energy"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260800010000000000000003000000b5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_23() {
    let d = device();
    d.set("course_select", "quick_dry");
    expect_props(d, #{"course_select": "quick_dry", "dry_level_select": "off", "eco_hybrid_select": "speed", "anti_crease_select": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"course_select": "quick_dry", "dry_level_select": "off", "eco_hybrid_select": "speed", "anti_crease_select": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "quick_dry", "dry_level_select": "off", "eco_hybrid_select": "speed", "anti_crease_select": "true"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260900030000000000000203000000b0bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_24() {
    let d = device();
    d.set("course_select", "wool");
    expect_props(d, #{"course_select": "wool", "dry_level_select": "off"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"course_select": "wool", "dry_level_select": "off"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "wool", "dry_level_select": "off"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260b00020000000000000003000000b1bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_25() {
    let d = device();
    d.set("course_select", "bedding_brush");
    expect_props(d, #{"course_select": "bedding_brush", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"course_select": "bedding_brush", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "bedding_brush", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260f00030000000000000003000000bcbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_26() {
    let d = device();
    d.set("course_select", "allergy_care");
    expect_props(d, #{"course_select": "allergy_care", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"course_select": "allergy_care", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "allergy_care", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0261000030000000000000003080000a7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_27() {
    let d = device();
    d.set("course_select", "condenser_care");
    expect_props(d, #{"course_select": "condenser_care", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"course_select": "condenser_care", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "condenser_care", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0261200030000000000000003080000a1bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_28() {
    let d = device();
    d.set("course_select", "tub_clean");
    expect_props(d, #{"course_select": "tub_clean", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"course_select": "tub_clean", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "tub_clean", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0261300030000000000000003080000a0bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_29() {
    let d = device();
    d.set("course_select", "padding_refresh");
    expect_props(d, #{"course_select": "padding_refresh", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"course_select": "padding_refresh", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "padding_refresh", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0261400030000000000000003000000bbbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_30() {
    let d = device();
    d.set("course_select", "time_dry");
    expect_props(d, #{"course_select": "time_dry", "dry_level_select": "off"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"course_select": "time_dry", "dry_level_select": "off"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "time_dry", "dry_level_select": "off"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0261500021e0000000000000300000059bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_31() {
    let d = device();
    d.set("course_select", "outdoor_refresh");
    expect_props(d, #{"course_select": "outdoor_refresh", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"course_select": "outdoor_refresh", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "outdoor_refresh", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0261600033c0000000000000300000079bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_32() {
    let d = device();
    d.set("course_select", "baby_wear");
    expect_props(d, #{"course_select": "baby_wear", "dry_level_select": "off"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "0");
    expect_props(d, #{"course_select": "baby_wear", "dry_level_select": "off"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "baby_wear", "dry_level_select": "off"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0261700020000000000000003000000a5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course replays the captured template per course with reserve folded in
fn test_pr_182_33() {
    let d = device();
    d.set("course_select", "standard");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260703020000000300000001000000b1bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course folds dry, eco and anti-crease in only where the model allows
fn test_pr_182_34() {
    let d = device();
    d.set("course_select", "standard");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("dry_level_select", "strong");
    expect_props(d, #{"dry_level_select": "strong"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("eco_hybrid_select", "speed");
    expect_props(d, #{"dry_level_select": "strong", "eco_hybrid_select": "speed"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("anti_crease_select", "true");
    expect_props(d, #{"dry_level_select": "strong", "eco_hybrid_select": "speed", "anti_crease_select": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"dry_level_select": "strong", "eco_hybrid_select": "speed", "anti_crease_select": "true", "reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"dry_level_select": "strong", "eco_hybrid_select": "speed", "anti_crease_select": "true", "reserve_hours": "3"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260705030000000300000201000000bcbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course folds dry, eco and anti-crease in only where the model allows
fn test_pr_182_35() {
    let d = device();
    d.set("course_select", "easy_care");
    expect_props(d, #{"course_select": "easy_care"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("dry_level_select", "strong");
    expect_props(d, #{"course_select": "easy_care", "dry_level_select": "strong"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("eco_hybrid_select", "speed");
    expect_props(d, #{"course_select": "easy_care", "dry_level_select": "strong", "eco_hybrid_select": "speed"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "easy_care", "dry_level_select": "strong", "eco_hybrid_select": "speed"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260503020000000000000003000000b4bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Start course folds dry, eco and anti-crease in only where the model allows
fn test_pr_182_36() {
    let d = device();
    d.set("course_select", "condenser_care");
    expect_props(d, #{"course_select": "condenser_care", "dry_level_select": "off", "eco_hybrid_select": "speed"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("anti_crease_select", "true");
    expect_props(d, #{"course_select": "condenser_care", "dry_level_select": "off", "eco_hybrid_select": "speed", "anti_crease_select": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "condenser_care", "dry_level_select": "off", "eco_hybrid_select": "speed", "anti_crease_select": "true"});
    expect_eq(hex_encode(d.sent()[0]), "aa14f0261200030000000000000003080000a1bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Resume replays the remembered full start frame
fn test_pr_182_37() {
    let d = device();
    d.set("resume", "");
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260703020000000000000001000000b4bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// reserve_hours=1 or 2 is refused: LG declares 0 or 3..19, not 1 or 2
fn test_pr_182_38() {
    let d = device();
    d.set("reserve_hours", "1");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "2");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "3");
    expect_props(d, #{"reserve_hours": "3"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "19");
    expect_props(d, #{"reserve_hours": "19"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "20");
    expect_props(d, #{"reserve_hours": "19"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// selecting a course resets options to the model defaults
fn test_pr_182_39() {
    let d = device();
    d.set("course_select", "bulky_item");
    expect_props(d, #{"course_select": "bulky_item", "dry_level_select": "off", "eco_hybrid_select": "speed", "anti_crease_select": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("course_select", "sports_wear");
    expect_props(d, #{"course_select": "sports_wear", "dry_level_select": "off", "eco_hybrid_select": "energy", "anti_crease_select": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// invalid select values fall back to the remembered defaults
fn test_pr_182_40() {
    let d = device();
    d.set("course_select", "rack_dry");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("reserve_hours", "20");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("dry_level_select", "damp");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_eq(hex_encode(d.sent()[0]), "aa14f0260703020000000000000001000000b4bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// counts the reserve minute byte, not just whole hours
fn test_pr_182_41() {
    let d = device();
    d.feed("aa3c30ec0019030020002001000002010d380d3801130800010200000077000019030020002001000002010d380d38011b0800010200000077005fbb");
    expect_props(d, #{"course_select": "steam_refresh", "power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "steam_refresh", "dry_level": "off", "eco_hybrid": "auto", "steam": "true", "remaining_time": "32", "initial_time": "32", "reserve_time": "836", "energy": "1"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// every Status value it can publish is a declared option
fn test_pr_182_42() {
    let d = device();
    d.feed("aa2130eb001901000000000000000000000000000804000000000000007700d6bb");
    expect_props(d, #{"power": "true", "status": "standby", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa2130eb00190000000000000000000000000000000000000000000000770023bb");
    expect_props(d, #{"power": "false", "status": "power_off", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec001903010c010f0700030202000000000819000005020000007700001902001e001e070001010013001300019b000000030000007700d1bb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "delicate", "eco_hybrid": "energy", "steam": "false", "remaining_time": "30", "initial_time": "30", "reserve_time": "1140", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec00190100000000000000000000000000001900000000000000770000190201280128070003020000000000009b0000000100000077006dbb");
    expect_props(d, #{"power": "true", "status": "detecting", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "standard", "eco_hybrid": "auto", "steam": "false", "remaining_time": "100", "initial_time": "100", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec00190201280128070003020000000000009b000000010000007700001902010f010f070003020200000000001b0000000100000077003fbb");
    expect_props(d, #{"power": "true", "status": "drying", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "standard", "eco_hybrid": "auto", "steam": "false", "remaining_time": "75", "initial_time": "75", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec001902010f010f070003020200000000001b000000010000007700001903010f010f070003020200000000081b00000002000000770091bb");
    expect_props(d, #{"power": "true", "status": "pause", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "standard", "eco_hybrid": "auto", "steam": "false", "remaining_time": "75", "initial_time": "75", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec0019030020002001000002010d380d3801130800010200000077000019030020002001000002010d380d38011b0800010200000077005fbb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "steam_refresh", "dry_level": "off", "eco_hybrid": "auto", "steam": "true", "remaining_time": "32", "initial_time": "32", "reserve_time": "836", "energy": "1", "course_select": "steam_refresh"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec00190301000100160000030103000300091900000002000000770000190201140114120000030100000000001908000003000000770084bb");
    expect_props(d, #{"power": "true", "status": "steam", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "condenser_care", "dry_level": "off", "eco_hybrid": "speed", "steam": "true", "remaining_time": "80", "initial_time": "80", "reserve_time": "0", "energy": "0", "course_select": "condenser_care"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec0019030020002001000002010d380d38010a0800050200000077000019030020002001000002010d380d38110a0800050200000077005dbb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "true", "anti_crease": "false", "reservation": "true", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "steam_refresh", "dry_level": "off", "eco_hybrid": "auto", "steam": "true", "remaining_time": "32", "initial_time": "32", "reserve_time": "836", "energy": "5", "course_select": "steam_refresh"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// never publishes the literal None, which HA reads as unknown
fn test_pr_182_43() {
    let d = device();
    d.feed("aa2130eb001901000000000000000000000000000804000000000000007700d6bb");
    expect_props(d, #{"power": "true", "status": "standby", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa2130eb00190000000000000000000000000000000000000000000000770023bb");
    expect_props(d, #{"power": "false", "status": "power_off", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec001903010c010f0700030202000000000819000005020000007700001902001e001e070001010013001300019b000000030000007700d1bb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "delicate", "eco_hybrid": "energy", "steam": "false", "remaining_time": "30", "initial_time": "30", "reserve_time": "1140", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec001903010a010a0500020202023b023b0b1900000002000000770000190200200020010000020103000300011908000003000000770002bb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "steam_refresh", "dry_level": "off", "eco_hybrid": "auto", "steam": "true", "remaining_time": "32", "initial_time": "32", "reserve_time": "180", "energy": "0", "course_select": "steam_refresh"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec0019030020002001000002010b000b0001190800010200000077000019020020002001000002010b000b00011908000103000000770073bb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "steam_refresh", "dry_level": "off", "eco_hybrid": "auto", "steam": "true", "remaining_time": "32", "initial_time": "32", "reserve_time": "660", "energy": "1", "course_select": "steam_refresh"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec00190301000100160000030103000300091900000002000000770000190201140114120000030100000000001908000003000000770084bb");
    expect_props(d, #{"power": "true", "status": "steam", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "condenser_care", "dry_level": "off", "eco_hybrid": "speed", "steam": "true", "remaining_time": "80", "initial_time": "80", "reserve_time": "0", "energy": "0", "course_select": "condenser_care"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec001902010a010a050002020203000300031b000000030000007700001902010a010a0500020202023b023b031b0000000300000077007fbb");
    expect_props(d, #{"power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "true", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "easy_care", "dry_level": "light", "eco_hybrid": "auto", "steam": "false", "remaining_time": "70", "initial_time": "70", "reserve_time": "179", "energy": "0", "course_select": "easy_care"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// Power off reproduces the exact ThinQ app command captured by MCP
fn test_pr_182_44() {
    let d = device();
    d.set("power_off", "");
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240101009cbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Pause reproduces the exact ThinQ app command captured by MCP
fn test_pr_182_45() {
    let d = device();
    d.set("pause", "");
    expect_eq(hex_encode(d.sent()[0]), "aa09f02404010099bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// Smart course select installs and stays visible while powered off
fn test_pr_182_46() {
    let d = device();
    d.feed("aa2130eb00190000000000000000000000000000000000000000000000770023bb");
    expect_props(d, #{"power": "false", "status": "power_off", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("smart_course_select", "powerful_dry");
    expect_props(d, #{"power": "false", "status": "power_off", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "off", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0", "course_select": "downloaded_course", "smart_course_select": "powerful_dry", "smart_course": "powerful_dry"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df0250315000264000000000000001177000000000000000000b7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// restores an armed Smart course when the handler reconnects
fn test_pr_182_47() {
    let d = device();
    d.set("smart_course_select", "wrinkle_care_dry");
    expect_props(d, #{"smart_course_select": "wrinkle_care_dry", "smart_course": "wrinkle_care_dry"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df025031500025a0000000002000007720000000300000000009bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// installing a download course replays the exact captured app bytes
fn test_pr_182_48() {
    let d = device();
    d.set("smart_course_select", "powerful_dry");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "powerful_dry", "smart_course": "powerful_dry"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df0250315000264000000000000001177000000000000000000b7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// installing the second download course replays its captured bytes
fn test_pr_182_49() {
    let d = device();
    d.set("smart_course_select", "wrinkle_care_dry");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "wrinkle_care_dry", "smart_course": "wrinkle_care_dry"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df025031500025a0000000002000007720000000300000000009bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// installing Full Size Load replays its captured bytes
fn test_pr_182_50() {
    let d = device();
    d.set("smart_course_select", "full_size_load");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "full_size_load", "smart_course": "full_size_load"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150003640000000000000007740000000500000000008ebb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// installing Refresh replays its captured bytes
fn test_pr_182_51() {
    let d = device();
    d.set("smart_course_select", "refresh");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "refresh", "smart_course": "refresh"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df0250315000314000000000000000f6b000000000000000000d0bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// installing Small Load replays its captured bytes
fn test_pr_182_52() {
    let d = device();
    d.set("smart_course_select", "small_load");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "small_load", "smart_course": "small_load"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df025031500031e000000000000000e6c000000000000000000dabb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// installing Gym Clothes replays its captured bytes
fn test_pr_182_53() {
    let d = device();
    d.set("smart_course_select", "gym_clothes");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "gym_clothes", "smart_course": "gym_clothes"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df025031500013d000000000000000866000000000000000000f5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// installing Rainy Season replays its captured bytes
fn test_pr_182_54() {
    let d = device();
    d.set("smart_course_select", "rainy_season");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "rainy_season", "smart_course": "rainy_season"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df0250315000328000000000000000e69000000000000000000c3bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// installing Economic Dry replays its captured bytes
fn test_pr_182_55() {
    let d = device();
    d.set("smart_course_select", "economic_dry");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "economic_dry", "smart_course": "economic_dry"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df025031500017d000000000000000770000000030000000000b9bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// installing Easy Iron replays its captured bytes
fn test_pr_182_56() {
    let d = device();
    d.set("smart_course_select", "easy_iron");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "easy_iron", "smart_course": "easy_iron"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df025031500034100000000000000076e000000010000000000fbbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// installing Big Size Item replays its captured bytes
fn test_pr_182_57() {
    let d = device();
    d.set("smart_course_select", "big_size_item");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "big_size_item", "smart_course": "big_size_item"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150003af0000000000000004710000000000000000004ebb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// refuses a download course with no captured install blob
fn test_pr_182_58() {
    let d = device();
    d.set("smart_course_select", "");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// identifies a running download and reports Downloaded Course
fn test_pr_182_59() {
    let d = device();
    d.start();
    expect_eq(hex_encode(d.sent()[0]), "aa0ef0ed1121010000001800b5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec00190202370237040000030203000300011b000000017100007100001902023702370400000302023b023b011b000000017100007100f9bb");
    expect_props(d, #{"course_select": "downloaded_course", "power": "true", "status": "reserved", "child_lock": "false", "anti_crease": "false", "reservation": "true", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "smart_course_select": "big_size_item", "smart_course": "big_size_item", "course": "downloaded_course", "dry_level": "off", "eco_hybrid": "speed", "steam": "false", "remaining_time": "175", "initial_time": "175", "reserve_time": "179", "energy": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// an armed download survives an idle status frame with no signature
fn test_pr_182_60() {
    let d = device();
    d.set("smart_course_select", "powerful_dry");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "powerful_dry", "smart_course": "powerful_dry"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df0250315000264000000000000001177000000000000000000b7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("aa2130eb00190000000000000000000000000000000000000000000000770023bb");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "powerful_dry", "smart_course": "powerful_dry", "power": "false", "status": "power_off", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "false", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "downloaded_course", "dry_level": "off", "eco_hybrid": "off", "steam": "false", "remaining_time": "0", "initial_time": "0", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// a real native-course status frame keeps the installed download visible
fn test_pr_182_61() {
    let d = device();
    d.set("smart_course_select", "powerful_dry");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "powerful_dry", "smart_course": "powerful_dry"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df0250315000264000000000000001177000000000000000000b7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec00190100000000000000000000000000001900000000000000770000190201280128070003020000000000009b0000000100000077006dbb");
    expect_props(d, #{"course_select": "standard", "smart_course_select": "powerful_dry", "smart_course": "powerful_dry", "power": "true", "status": "detecting", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "standard", "eco_hybrid": "auto", "steam": "false", "remaining_time": "100", "initial_time": "100", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// repeated identical status frames do not rewrite the memory file
fn test_pr_182_62() {
    let d = device();
    d.feed("aa3c30ec00190100000000000000000000000000001900000000000000770000190201280128070003020000000000009b0000000100000077006dbb");
    expect_props(d, #{"power": "true", "status": "detecting", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "standard", "eco_hybrid": "auto", "steam": "false", "remaining_time": "100", "initial_time": "100", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec00190100000000000000000000000000001900000000000000770000190201280128070003020000000000009b0000000100000077006dbb");
    expect_props(d, #{"power": "true", "status": "detecting", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "standard", "eco_hybrid": "auto", "steam": "false", "remaining_time": "100", "initial_time": "100", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa3c30ec00190100000000000000000000000000001900000000000000770000190201280128070003020000000000009b0000000100000077006dbb");
    expect_props(d, #{"power": "true", "status": "detecting", "child_lock": "false", "anti_crease": "false", "reservation": "false", "remote_start": "true", "error": "false", "error_message": "normal", "smart_diagnosis": "false", "course": "standard", "dry_level": "standard", "eco_hybrid": "auto", "steam": "false", "remaining_time": "100", "initial_time": "100", "reserve_time": "0", "energy": "0"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// starts Powerful Dry through Downloaded Course with the captured F026 frame
fn test_pr_182_63() {
    let d = device();
    d.set("smart_course_select", "powerful_dry");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "powerful_dry", "smart_course": "powerful_dry"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df0250315000264000000000000001177000000000000000000b7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "downloaded_course");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "powerful_dry", "smart_course": "powerful_dry"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "powerful_dry", "smart_course": "powerful_dry"});
    expect_eq(hex_encode(d.sent()[1]), "aa14f026110002640000000000000300770090bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// starts Wrinkle Care Dry through Downloaded Course with the captured F026 frame
fn test_pr_182_64() {
    let d = device();
    d.set("smart_course_select", "wrinkle_care_dry");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "wrinkle_care_dry", "smart_course": "wrinkle_care_dry"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df025031500025a0000000002000007720000000300000000009bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "downloaded_course");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "wrinkle_care_dry", "smart_course": "wrinkle_care_dry"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "wrinkle_care_dry", "smart_course": "wrinkle_care_dry"});
    expect_eq(hex_encode(d.sent()[1]), "aa14f0260703025a00000000000203007200e4bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// builds a checksummed start frame for every captured download definition
fn test_pr_182_65() {
    let d = device();
    d.set("smart_course_select", "powerful_dry");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "powerful_dry", "smart_course": "powerful_dry"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df0250315000264000000000000001177000000000000000000b7bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "downloaded_course");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "powerful_dry", "smart_course": "powerful_dry"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "powerful_dry", "smart_course": "powerful_dry"});
    expect_eq(hex_encode(d.sent()[1]), "aa14f026110002640000000000000300770090bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// builds a checksummed start frame for every captured download definition
fn test_pr_182_66() {
    let d = device();
    d.set("smart_course_select", "wrinkle_care_dry");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "wrinkle_care_dry", "smart_course": "wrinkle_care_dry"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df025031500025a0000000002000007720000000300000000009bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "downloaded_course");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "wrinkle_care_dry", "smart_course": "wrinkle_care_dry"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "wrinkle_care_dry", "smart_course": "wrinkle_care_dry"});
    expect_eq(hex_encode(d.sent()[1]), "aa14f0260703025a00000000000203007200e4bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// builds a checksummed start frame for every captured download definition
fn test_pr_182_67() {
    let d = device();
    d.set("smart_course_select", "full_size_load");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "full_size_load", "smart_course": "full_size_load"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150003640000000000000007740000000500000000008ebb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "downloaded_course");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "full_size_load", "smart_course": "full_size_load"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "full_size_load", "smart_course": "full_size_load"});
    expect_eq(hex_encode(d.sent()[1]), "aa14f0260705036400000000000003007400ebbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// builds a checksummed start frame for every captured download definition
fn test_pr_182_68() {
    let d = device();
    d.set("smart_course_select", "refresh");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "refresh", "smart_course": "refresh"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df0250315000314000000000000000f6b000000000000000000d0bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "downloaded_course");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "refresh", "smart_course": "refresh"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "refresh", "smart_course": "refresh"});
    expect_eq(hex_encode(d.sent()[1]), "aa14f0260f00031400000000000003006b003dbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// builds a checksummed start frame for every captured download definition
fn test_pr_182_69() {
    let d = device();
    d.set("smart_course_select", "small_load");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "small_load", "smart_course": "small_load"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df025031500031e000000000000000e6c000000000000000000dabb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "downloaded_course");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "small_load", "smart_course": "small_load"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "small_load", "smart_course": "small_load"});
    expect_eq(hex_encode(d.sent()[1]), "aa14f0260e00031e00000000000003006c0027bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// builds a checksummed start frame for every captured download definition
fn test_pr_182_70() {
    let d = device();
    d.set("smart_course_select", "gym_clothes");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "gym_clothes", "smart_course": "gym_clothes"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df025031500013d000000000000000866000000000000000000f5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "downloaded_course");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "gym_clothes", "smart_course": "gym_clothes"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "gym_clothes", "smart_course": "gym_clothes"});
    expect_eq(hex_encode(d.sent()[1]), "aa14f0260800013d00000000000003006600d6bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// builds a checksummed start frame for every captured download definition
fn test_pr_182_71() {
    let d = device();
    d.set("smart_course_select", "rainy_season");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "rainy_season", "smart_course": "rainy_season"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df0250315000328000000000000000e69000000000000000000c3bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "downloaded_course");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "rainy_season", "smart_course": "rainy_season"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "rainy_season", "smart_course": "rainy_season"});
    expect_eq(hex_encode(d.sent()[1]), "aa14f0260e000328000000000000030069002cbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// builds a checksummed start frame for every captured download definition
fn test_pr_182_72() {
    let d = device();
    d.set("smart_course_select", "economic_dry");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "economic_dry", "smart_course": "economic_dry"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df025031500017d000000000000000770000000030000000000b9bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "downloaded_course");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "economic_dry", "smart_course": "economic_dry"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "economic_dry", "smart_course": "economic_dry"});
    expect_eq(hex_encode(d.sent()[1]), "aa14f0260703017d000000000000030070009abb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// builds a checksummed start frame for every captured download definition
fn test_pr_182_73() {
    let d = device();
    d.set("smart_course_select", "easy_iron");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "easy_iron", "smart_course": "easy_iron"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df025031500034100000000000000076e000000010000000000fbbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "downloaded_course");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "easy_iron", "smart_course": "easy_iron"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "easy_iron", "smart_course": "easy_iron"});
    expect_eq(hex_encode(d.sent()[1]), "aa14f0260701034100000000000003006e00c4bb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// builds a checksummed start frame for every captured download definition
fn test_pr_182_74() {
    let d = device();
    d.set("smart_course_select", "big_size_item");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "big_size_item", "smart_course": "big_size_item"});
    expect_eq(hex_encode(d.sent()[0]), "aa1df02503150003af0000000000000004710000000000000000004ebb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("course_select", "downloaded_course");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "big_size_item", "smart_course": "big_size_item"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course", "smart_course_select": "big_size_item", "smart_course": "big_size_item"});
    expect_eq(hex_encode(d.sent()[1]), "aa14f026040003af00000000000003007100abbb");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// does not guess a downloaded start or resume without captured state
fn test_pr_182_75() {
    let d = device();
    d.set("course_select", "downloaded_course");
    expect_props(d, #{"course_select": "downloaded_course"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("start_course", "");
    expect_props(d, #{"course_select": "downloaded_course"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("resume", "");
    expect_props(d, #{"course_select": "downloaded_course"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// asks only for the family-wide read-only status snapshot on connect
fn test_pr_182_76() {
    let d = device();
    d.start();
    expect_eq(hex_encode(d.sent()[0]), "aa0ef0ed1121010000001800b5bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// ignores other device types and malformed RH16 status shapes
fn test_pr_182_77() {
    let d = device();
    d.feed("aa2120eb00190000000000000000000000000000000000000000000000770033bb");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa0730eb00a8bb");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

fn test_valid_empty_envelope_does_not_decode_as_status() {
 let d=device();d.feed("aa00ffbb");expect_eq(d.script_error(),());
}
