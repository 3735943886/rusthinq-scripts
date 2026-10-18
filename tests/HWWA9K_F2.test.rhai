import "runtime_test" as runtime;
// BEGIN PR VECTORS
// Regression vectors from rethink PR #116 (2da637a2544aa8689b212ba5cced5a7d16fdfe56).
// Original test names are retained below. Expected TX bytes come from executing the TS driver.

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_1() {
    let d = device();
    d.set("mop_with_sucking", "mop_only");
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240101019fbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_2() {
    let d = device();
    d.set("mop_with_sucking", "mop_and_suction_together");
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240101029ebb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_3() {
    let d = device();
    d.set("suction_force", "standard");
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240201019ebb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_4() {
    let d = device();
    d.set("suction_force", "high");
    expect_eq(hex_encode(d.sent()[0]), "aa09f02402010299bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_5() {
    let d = device();
    d.set("suction_force", "turbo");
    expect_eq(hex_encode(d.sent()[0]), "aa09f02402010398bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_6() {
    let d = device();
    d.set("charging_melody", "lucky");
    expect_eq(hex_encode(d.sent()[0]), "aa09f02403010199bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_7() {
    let d = device();
    d.set("charging_melody", "marble");
    expect_eq(hex_encode(d.sent()[0]), "aa09f02403010298bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_8() {
    let d = device();
    d.set("charging_melody", "ice");
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240301039bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_9() {
    let d = device();
    d.set("charging_melody", "breeze");
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240301049abb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_10() {
    let d = device();
    d.set("charging_melody", "nebula");
    expect_eq(hex_encode(d.sent()[0]), "aa09f02403010585bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_11() {
    let d = device();
    d.set("volume", "high");
    expect_eq(hex_encode(d.sent()[0]), "aa09f02404010198bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_12() {
    let d = device();
    d.set("volume", "normal");
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240401029bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_13() {
    let d = device();
    d.set("volume", "low");
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240401039abb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_14() {
    let d = device();
    d.set("brightness", "very_bright");
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240501019bbb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_15() {
    let d = device();
    d.set("brightness", "bright");
    expect_eq(hex_encode(d.sent()[0]), "aa09f0240501029abb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_16() {
    let d = device();
    d.set("brightness", "normal");
    expect_eq(hex_encode(d.sent()[0]), "aa09f02405010385bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_17() {
    let d = device();
    d.set("brightness", "dim");
    expect_eq(hex_encode(d.sent()[0]), "aa09f02405010484bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// each write reproduces the frame LG itself sent for that command
fn test_pr_116_18() {
    let d = device();
    d.set("brightness", "off");
    expect_eq(hex_encode(d.sent()[0]), "aa09f02405010587bb");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// an unknown option is refused rather than guessed
fn test_pr_116_19() {
    let d = device();
    d.set("suction_force", "invalidforce");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("brightness", "invalidbrightness");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("status", "charging");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// real captured frame decodes to what LG read from the same frame
fn test_pr_116_20() {
    let d = device();
    d.feed("aa14d2eb000c04010101ff00010102010103c3bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each probed offset moves exactly the field LG said it moves
fn test_pr_116_21() {
    let d = device();
    d.feed("aa14d2eb000c04010101ff00010102010103c3bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa14d2eb000c03010101ff00010102010103c0bb");
    expect_props(d, #{"status": "charging", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each probed offset moves exactly the field LG said it moves
fn test_pr_116_22() {
    let d = device();
    d.feed("aa14d2eb000c04010101ff00010102010103c3bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa14d2eb000c04010101ff00010103010103c2bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "turbo", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each probed offset moves exactly the field LG said it moves
fn test_pr_116_23() {
    let d = device();
    d.feed("aa14d2eb000c04010101ff00010102010103c3bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa14d2eb000c04010101ff00010102010102c0bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "bright"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each probed offset moves exactly the field LG said it moves
fn test_pr_116_24() {
    let d = device();
    d.feed("aa14d2eb000c04010101ff00010102010103c3bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa14d2eb000c040101010300010102010103cfbb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal", "nozzle": "powerdrive_mop"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// each probed offset moves exactly the field LG said it moves
fn test_pr_116_25() {
    let d = device();
    d.feed("aa14d2eb000c04010101ff00010102010103c3bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa14d2eb000c04010101ff00010202010103c2bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "true", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a single-byte probe changes nothing else
fn test_pr_116_26() {
    let d = device();
    d.feed("aa14d2eb000c04010101ff00010102010103c3bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa14d2eb000c04010101ff00010103010103c2bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "turbo", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the 44-byte capability frame is ignored, not decoded as state
fn test_pr_116_27() {
    let d = device();
    d.feed("aa14d2eb000c04010101ff00010102010103c3bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aaffd20a002c00005200010a85001a00040456432d31010456432d32010456432d33010456432d34014880bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// the two-record echo is read, and its LAST record is the current state
fn test_pr_116_28() {
    let d = device();
    d.feed("aa14d2eb000c04010101ff00010102010103c3bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa22d2ec000c04010101ff00020101030304000c04010101ff000201020303049ebb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_and_suction_together", "charging_melody": "ice", "volume": "low", "brightness": "dim"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// an unrecognized enum code publishes HA's accepted 'unknown' fallback
fn test_pr_116_29() {
    let d = device();
    d.feed("aa14d2eb000c09010101ff00010102010103c3bb");
    expect_props(d, #{"clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a code the table does not list leaves the select where it was
fn test_pr_116_30() {
    let d = device();
    d.feed("aa14d2eb000c04010101ff00010102010103c3bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa14d2eb000c04010101ff00010109010103c8bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// a frame whose field count is not 12 is left alone
fn test_pr_116_31() {
    let d = device();
    d.feed("aa14d2eb000c04010101ff00010102010103c3bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("aa14d2eb000304010101ff00010102010103c3bb");
    expect_props(d, #{"status": "charging_complete", "clean_mode": "off", "battery": "off", "filter_state": "normal", "passage": "normal", "complete_clean": "false", "suction_force": "high", "mop_with_sucking": "mop_only", "charging_melody": "lucky", "volume": "high", "brightness": "normal"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

fn test_descriptor_limits_controls_to_captured_settings() {
 let d=device();d.start();let doc=runtime::descriptor(d);
 for name in ["suction_force","mop_with_sucking","charging_melody","volume","brightness"] {expect_eq(doc.props[name].rw,true);}
 expect_eq(doc.props.battery.rw,false);expect_eq(doc.props.clean_mode.rw,false);
 expect_eq(doc.props.power,());expect_eq(doc.props.start,());expect_eq(d.sent().len(),0);
}
