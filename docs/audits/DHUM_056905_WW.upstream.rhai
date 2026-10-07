// Append to the prepared tests/DHUM_056905_WW.test.rhai for audit replay.
// Replay real upstream DHUM frames from anszom/rethink cd98450.
fn upstream_running() {
    let d = device(); d.start(); d.feed(caps());
    d.feed("00000400000087020400117DC17E50117E827F503094D023D801A8803F5E");
    d
}
fn test_upstream_query_response() {
    expect_props(upstream_running(), #{available: "true", target: "35", mode: "smart",
        fan: "low", sterilize: "true", uvnano: "false"});
}
fn test_upstream_live_switch_frames() {
    let d = upstream_running();
    for row in [
        ["000004000000A702043F02D80085A3", "sterilize", "false"],
        ["000004000000A702044B02A88184D7", "uvnano", "true"],
        ["000004000000A702044A08A8808C90388CD041E991", "uvnano", "false"],
        ["000004000000A702048C0287817086", "bucket_light", "true"],
        ["000004000000A702048A028780473E", "bucket_light", "false"],
        ["000004000000A70204EE02AC811E20", "tank_full", "true"],
        ["000004000000A702046706AC600100AC807407", "tank_full", "false"]
    ] {
        d.feed(row[0]); expect_eq(d.property(row[1]), row[2]);
        expect_eq(d.script_error(), ());
    }
}
fn test_upstream_countdown_frames() {
    let d = upstream_running();
    for row in [["000004000000A70204ED0386D03BB028", "59"],
        ["000004000000A70204F30486E0012BC8DA", "299"],
        ["000004000000A70204EE0286C0AFE8", "0"]] {
        d.feed(row[0]); expect_eq(d.property("off_timer"), row[1]);
    }
}
fn test_upstream_write_attachments() {
    let d = upstream_running(); let n = d.sent().len();
    d.set("sterilize", "true"); d.set("uvnano", "true");
    d.set("bucket_light", "true"); d.set("off_timer", "540");
    expect_eq(t::sent_since(d, n), [
        [[0x360, 1], [0x1f7, 1], [0x1f9, 17]],
        [[0x2a2, 1], [0x1f7, 1], [0x1f9, 17]],
        [[0x21e, 1]], [[0x21b, 540]]]);
}
fn test_upstream_humidity_and_tank_are_independent() {
    let d = upstream_running(); d.feed(t::notify([[0x2b2, 1]]));
    d.feed(t::notify([[0x336, 48]]));
    expect_props(d, #{humidity: "48", tank_full: "true"});
}
// Characterize an upstream difference: before caps, upstream suppresses 0x336.
fn test_audit_pre_caps_humidity_is_published_by_rhai() {
    let d = device(); d.start(); d.feed(t::notify([[0x336, 52]]));
    expect_props(d, #{humidity: "52", available: "false"});
}

fn test_upstream_all_supported_write_frames_byte_for_byte() {
 let d = upstream_running();
 d.set("power", "true");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "01010400000065020101057dc17e5011385c");
 d.set("power", "false");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "01010400000065020101027dc00576");
 d.set("mode", "jet");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "01010400000065020101057e50127dc13368");
 d.set("mode", "silent");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "01010400000065020101057e50137dc10458");
 d.set("fan", "high");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "01010400000065020101257e86b5d011b600b646b5d012b600b646b5d014b600b646b5d015b600b646b5d016b600b646aa7f");
 d.set("fan", "low");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "01010400000065020101257e82b5d011b600b642b5d012b600b642b5d014b600b642b5d015b600b646b5d016b600b64280f7");
 d.set("mode", "spot");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "01010400000065020101057e50147dc181c8");
 d.set("mode", "laundry");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "01010400000065020101057e50157dc1b6f8");
 d.set("mode", "smart");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "01010400000065020101057e50117dc16a38");
 d.set("target", "45");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "010104000000650201010894d02d7dc17e50112fd0");
 d.set("sterilize", "true");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "0101040000006502010107d8017dc17e50117f77");
 d.set("sterilize", "false");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "0101040000006502010107d8007dc17e50113ad7");
 d.set("uvnano", "true");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "0101040000006502010107a8817dc17e50112f36");
 d.set("uvnano", "false");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "0101040000006502010107a8807dc17e50116a96");
 d.set("bucket_light", "true");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "01010400000065020101028781a199");
 d.set("bucket_light", "false");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "01010400000065020101028780b1b8");
 d.set("off_timer", "540");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "010104000000650201010486e0021c9e6a");
 d.set("off_timer", "300");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "010104000000650201010486e0012cfd6a");
 d.set("off_timer", "60");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "010104000000650201010386d03cb71e");
 d.set("off_timer", "0");
 expect_eq(hex_encode(d.sent()[d.sent().len()-1]), "010104000000650201010286c0ca4d");
}
