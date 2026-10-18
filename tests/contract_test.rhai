// Executed for every declared driver by tools/check_contracts.py.
fn lifecycle(d) {
    d.start();
    d.feed("");
    d.feed("00");
    d.feed("aa");
    // Exercise the timers actually installed by this driver, once each.
    for timer in d.timers() { d.fire(timer[0]); }
    d.drop_device();
    d.start();
    expect_eq(d.script_error(), ());
}

fn il_contract(d) {
    d.start();
    let payload = d.published("rusthinq/test-device/descriptor");
    expect(payload != (), "IL driver must publish its descriptor at device_topic()/descriptor");
    let doc = json_parse(payload);
    expect_eq(doc.il, 0);
    expect_eq(doc.id, "test-device");
    expect_eq(type_of(doc.props), "map");
    expect_eq(doc["x-mqtt"].state, "rusthinq/{id}/{prop}");
    expect_eq(doc["x-mqtt"].set, "rusthinq/{id}/{prop}/set");
    for prop in doc.props.keys() {
        expect(!["descriptor", "reject"].contains(prop), "reserved topic name: " + prop);
        let def = doc.props[prop];
        expect(["binary", "number", "select", "text", "trigger"].contains(def.type), "invalid property type: " + prop);
        if def.min != () && def.max != () { expect(def.min <= def.max, "inverted range: " + prop); }
        if def.step != () { expect(def.step > 0, "nonpositive step: " + prop); }
        if def.type == "select" { expect_eq(type_of(def.options), "array"); }
        if def.role == "available" { expect_eq(d.property(prop), "true"); }
        // Invalid writes must never emit physical commands, including read-only properties.
        if def.type != "trigger" && (def.rw != true || ["binary", "number", "select"].contains(def.type)) {
            let sent = d.sent().len();
            let clips = d.clips().len();
            d.set(prop, "__contract_invalid_value__");
            expect_eq(d.sent().len(), sent, "invalid write sent a packet: " + prop);
            expect_eq(d.clips().len(), clips, "invalid write sent a command: " + prop);
            let rejected = d.event("reject");
            expect(rejected != (), "missing reject: " + prop);
            expect_eq(json_parse(rejected).prop, prop);
        }
    }
    d.drop_device();
    for prop in doc.props.keys() {
        if doc.props[prop].role == "available" { expect_eq(d.property(prop), "false"); }
    }
    d.start();
    for prop in doc.props.keys() {
        if doc.props[prop].role == "available" { expect_eq(d.property(prop), "true"); }
    }
}
