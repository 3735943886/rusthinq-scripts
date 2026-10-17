import "runtime_test" as runtime;
import "tlv_test" as t;

// Tests of RAC_0B0001_WW, an alias of RAC_056905_WW (rac_common): upstream rethink maps it to the
// same TLV handler and has no captures of its own, so these replay RAC_056905_WW's (commit 0e57069).

fn caps_response() {
    "0000040000008702010249" +
    "B001B05057B0A0017CB0C1B103B306B34FB4C7B582B541B543B6A04D81B6F0690409B701BC40BD47" +
    "B5C0B61024B643B5C1B600B643B5C2B600B643B5C4B61026B643B5C6B6102CB643" +
    "44E1"
}
fn query_response() {
    "00000400000087020415" +
    "777E447DC17E837F50297F9026C840C880C8C08340838083C0868086C0870087C0894088408A1011" +
    "8A505A8A8F8CA0C0BA8CD010ACE00164D540D580C900CAD0A0CB1040CB40CB8CCBCFCC1032CC504F" +
    "CC90438B40BF600155BFE00271BFA00155C0200271BE509FBE90A01B01BED050C300C340C0C0C380" +
    "3E6B"
}

// upstream maps this model to RAC_056905_WW
fn test_decodes_as_rac_056905_ww() {
    let d = device();
    d.start();
    d.feed(caps_response());
    d.feed(query_response());
    d.fire("filter_probe");
    d.feed(query_response());
    expect_props(d, #{ power: "true", mode: "heat", fan: "low", temperature: "20.5", target: "19",
                       swing_vertical: "off", jet: "false" });
    expect(runtime::descriptor(d).props.contains("sleep_timer"), "capability features");
}
