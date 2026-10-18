import "runtime_test" as runtime;
// BEGIN PR VECTORS
// Regression vectors from rethink PR #113 (1419bf64e130f9c1268297221b62869b75ae383c).
// Original test names are retained below. Expected TX bytes come from executing the TS driver.

// real initial response completes startup and decodes the confirmed 231006 state
fn test_pr_113_1() {
    let d = device();
    d.feed("000004000000a7020470707dc17e50567e8894d02d7f503686c087008980c900d80187806150b4cd90308840ce80ab00a88187c1e801ee40618089408380ea406241f8008c901b8cd024b5d056b600b648b5d013b600b642b5d055b600b647b5d014b600b648b5d016b600b6485cf05614135d301500fffa80cdc05dc3");
    expect_props(d, #{"power": "true", "mode": "smart_plus", "fan": "auto", "target": "45", "off_timer": "0", "sterilize": "true", "bucket_light": "false", "humidity": "48", "uvnano": "true"});
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// real fan response decodes high and ignores repeated capability rows as state
fn test_pr_113_2() {
    let d = device();
    d.feed("000004000000a7020470707dc17e50567e8894d02d7f503686c087008980c900d80187806150b4cd90308840ce80ab00a88187c1e801ee40618089408380ea406241f8008c901b8cd024b5d056b600b648b5d013b600b642b5d055b600b647b5d014b600b648b5d016b600b6485cf05614135d301500fffa80cdc05dc3");
    expect_props(d, #{"power": "true", "mode": "smart_plus", "fan": "auto", "target": "45", "off_timer": "0", "sterilize": "true", "bucket_light": "false", "humidity": "48", "uvnano": "true"});
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020201027d425a6e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702047d177e86b5d056b600b646b5d014b600b646b5d016b600b64648f8");
    expect_props(d, #{"power": "true", "mode": "smart_plus", "fan": "high", "target": "45", "off_timer": "0", "sterilize": "true", "bucket_light": "false", "humidity": "48", "uvnano": "true"});
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// fan writes use the bare 0x1fa shape from captured cloud writes
fn test_pr_113_3() {
    let d = device();
    d.set("fan", "high");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020101027e867827");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("fan", "auto");
    expect_eq(hex_encode(d.sent()[1]), "01010400000065020101027e8899e9");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// derived inverse tables encode every advertised mode and fan
fn test_pr_113_4() {
    let d = device();
    d.set("mode", "smart_plus");
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020101057e50567dc1f205");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("mode", "silent");
    expect_eq(hex_encode(d.sent()[1]), "01010400000065020101057e50137dc10458");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("mode", "intensive");
    expect_eq(hex_encode(d.sent()[2]), "01010400000065020101057e50147dc181c8");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("mode", "quick");
    expect_eq(hex_encode(d.sent()[3]), "01010400000065020101057e50557dc1ab55");
    expect_eq(d.sent().len(), 4);
    expect_eq(d.script_error(), ());
    d.set("fan", "auto");
    expect_eq(hex_encode(d.sent()[4]), "01010400000065020101027e8899e9");
    expect_eq(d.sent().len(), 5);
    expect_eq(d.script_error(), ());
    d.set("fan", "low");
    expect_eq(hex_encode(d.sent()[5]), "01010400000065020101027e8238a3");
    expect_eq(d.sent().len(), 6);
    expect_eq(d.script_error(), ());
    d.set("fan", "medium");
    expect_eq(hex_encode(d.sent()[6]), "01010400000065020101027e845865");
    expect_eq(d.sent().len(), 7);
    expect_eq(d.script_error(), ());
    d.set("fan", "high");
    expect_eq(hex_encode(d.sent()[7]), "01010400000065020101027e867827");
    expect_eq(d.sent().len(), 8);
    expect_eq(d.script_error(), ());
    d.set("fan", "turbo");
    expect_eq(hex_encode(d.sent()[8]), "01010400000065020101027e876806");
    expect_eq(d.sent().len(), 9);
    expect_eq(d.script_error(), ());
}

// unknown enum values publish HA unknown and unknown commands are rejected
fn test_pr_113_5() {
    let d = device();
    d.feed("000004000000a7020400047e6003e7c8f0");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a7020400047ea003e7ee07");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("mode", "not_a_mode");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("fan", "not_a_fan");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// Repeated combined capability/value frames must not trigger a values-query loop.
fn test_repeated_combined_response_does_not_query_forever() {
 let d=device();d.start();
 let frame="000004000000A7020470707DC17E50567E8894D02D7F503686C087008980C900D80187806150B4CD90308840CE80AB00A88187C1E801EE40618089408380EA406241F8008C901B8CD024B5D056B600B648B5D013B600B642B5D055B600B647B5D014B600B648B5D016B600B6485CF05614135D301500FFFA80CDC05DC3";
 d.feed(frame);let n=d.sent().len();d.feed(frame);
 expect_eq(d.sent().len(),n);expect_eq(d.script_error(),());
}
