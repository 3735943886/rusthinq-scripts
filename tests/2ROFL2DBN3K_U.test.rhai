import "runtime_test" as runtime;
import "aabb_test" as a;

// Tests of 2ROFL2DBN3K_U.rhai (fridge), ported from the owner's rethink TS driver.
// The EB/EC status frames and the three 0x3E energy frames are real captures from
// the owner's unit (rethink frame log, 2026-11-03): the status record reads fridge
// wire 5 / freezer wire 4 (3 C / -18 C, matching the official integration's live
// values that day), and the energy deltas add onto the running totals exactly
// (7 + 762 = 773, 11 + 773 = 780 in the following reports' totals).

fn eb() { "aa6010eb0205040107ffff00010001ffffffffffff01ffffffffffffffffe70101ff02ffffffffffffffffff01ff0000ffffffffffffffffffffffffffffffffffffff0078ffffffffffffffffffffffff000000ffffffffffffffffffff6ebb" }
fn ec() { "aaba10ec0205040107ffff00010001ffffffffffff01ffffffffffffffffe70101ff02ffffffffffffffffff01ff0000ffffffffffffffffffffffffffffffffffffff0078ffffffffffffffffffffffff000000ffffffffffffffffffff0205040107ffff00010001ffffffffffff01ffffffffffffffffe80101ff02ffffffffffffffffff01ff0000ffffffffffffffffffffffffffffffffffffff0078ffffffffffffffffffffffff000000ffffffffffffffffffff98bb" }

fn test_start_is_silent_and_publishes_no_buckets_on_a_cold_start() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 0);
    // Fresh state: start must not overwrite retained values with zero
    // buckets. The first report publishes the buckets (and the total).
    expect_eq(d.property("energy"), ());
    expect_eq(d.property("energy_hour"), ());
    expect_eq(d.property("energy_day"), ());
    expect_eq(d.property("energy_month"), ());
    expect_eq(d.script_error(), ());
}

// Device frames other than status records are acknowledged ahead of decoding (c::ack), as the
// other AABB drivers do; without it the appliance repeated each notification ~10 times
// (seen live 2026-11-05). aa0710190289bb is a real frame of this class; the ACK is the captured reply.
fn test_device_frames_are_acknowledged() {
    let d = device();
    d.feed("aa0710190289bb");
    let clips = d.clips();
    expect_eq(clips.len(), 1);
    expect_eq(clips[0].cmd, "ack");
    expect_eq(clips[0].data, "AA08F0001904EABB");
    expect_eq(d.script_error(), ());
}

fn test_the_live_eb_becomes_il_properties() {
    let d = device();
    d.feed(eb());
    expect_props(d, #{
        available: "true",
        fridge_setpoint: "3",
        freezer_setpoint: "-18",
        express_freeze: "false",
        door: "false"
    });
    expect_eq(d.script_error(), ());
}

fn test_the_live_ec_publishes_the_current_record() {
    let d = device();
    d.feed(ec());
    expect_props(d, #{
        fridge_setpoint: "3",
        freezer_setpoint: "-18",
        express_freeze: "false",
        door: "false"
    });
    expect_eq(d.script_error(), ());
}

fn test_energy_reports_dedupe_and_accumulate() {
    let d = device();
    d.start();
    // delta 7, total 762, tick 0x58 - then the same report retransmitted.
    d.feed("aa0b103e000702fa580bbb");
    expect_props(d, #{ energy_hour: "7", energy_day: "7", energy_month: "7" });
    d.feed("aa0b103e000702fa580bbb");
    expect_props(d, #{ energy_hour: "7", energy_day: "7", energy_month: "7" });
    // delta 11, total 773 (= 762 + 11), tick 0x59 - a new report.
    d.feed("aa0b103e000b0305593abb");
    expect_props(d, #{ energy_hour: "18", energy_day: "18", energy_month: "18" });
    expect_eq(d.script_error(), ());
}

fn test_the_hour_bucket_rolls_over_on_its_timer() {
    let d = device();
    d.start();
    d.feed("aa0b103e000702fa580bbb");
    d.fire("energy_hour_roll");
    expect_props(d, #{ energy_hour: "0", energy_day: "7", energy_month: "7" });
    expect_eq(d.script_error(), ());
}

fn test_fridge_setpoint_write_is_the_f017_template() {
    let d = device();
    d.set("fridge_setpoint", "5");
    // [1] = 8 - 5 = 3, [8] = 1 (zone selector), everything else the app template.
    expect_eq(a::inner_hex(d, 0),
        "f017ff03ffffffffffff01ffffffffffffffffffffffff000000ffff00ffffffff00ffffffffffffffffff00ffffff1effffffffffffffffffffffffffffffffffffffffffffffff0affffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffff");
    expect_eq(d.script_error(), ());
}

fn test_freezer_setpoint_write() {
    let d = device();
    d.set("freezer_setpoint", "-20");
    // [2] = -14 - (-20) = 6, [8] = 1.
    expect_eq(a::inner_hex(d, 0),
        "f017ffff06ffffffffff01ffffffffffffffffffffffff000000ffff00ffffffff00ffffffffffffffffff00ffffff1effffffffffffffffffffffffffffffffffffffffffffffff0affffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffff");
}

fn test_express_freeze_write_has_no_zone_selector() {
    let d = device();
    d.set("express_freeze", "true");
    // [3] = 2 and [8] stays 0xff - the captured difference from temperature writes.
    expect_eq(a::inner_hex(d, 0),
        "f017ffffff02ffffffffffffffffffffffffffffffffff000000ffff00ffffffff00ffffffffffffffffff00ffffff1effffffffffffffffffffffffffffffffffffffffffffffff0affffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffff");
}

fn test_an_out_of_range_setpoint_is_rejected() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("fridge_setpoint", "9");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "a reject event is published");
}

fn test_a_read_only_property_is_rejected() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("door", "true");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "a reject event is published");
}

fn test_the_descriptor_is_celsius_with_the_ts_ranges() {
    let d = device();
    d.start();
    let desc = runtime::descriptor(d);
    expect_eq(desc.props.fridge_setpoint.unit, "°C");
    expect_eq(desc.props.fridge_setpoint.min, 1);
    expect_eq(desc.props.fridge_setpoint.max, 7);
    expect_eq(desc.props.freezer_setpoint.min, -23);
    expect_eq(desc.props.freezer_setpoint.max, -15);
}
