import "runtime_test" as runtime;
import "aabb_test" as a;

// Tests of 1WPD4CMBIR__3.rhai (water purifier, read-only). Every frame is a real capture from
// one unit (2026-11-25, rusthinqctl capture --cloud) taken while the LG cloud reported
// waterSelection NORMAL, then HOT with hotWaterTemp 3; normalWaterAmount 26 with
// coldWaterAmount 23, then hotWaterAmount 18.

fn eb_cold() { "AA7412EB020003FF0101FFFF0000030201003C0B1C11000001000000000601000200000C123264000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000E00150003000328465A000000010000000100000001000000001EBB" }
fn ec_normal() { "AAE212EC020003FF0101FFFF0000030201003C0B1C11000001000000000601000200000C123264000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000E00150003000328465A00000001000000010000000100000000020002FF0101FFFF0000030201003C0B1C11000001000000000601000200000C123264000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000E00150003000328465A00000001000000010000000100000000BCBB" }
fn ec_hot() { "AAE212EC020003FF0101FFFF0000030201003C0B1C11000001000000000601000200000C123264000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000E00150003000328465A00000001000000010000000100000000020001FF010103FF0000030201003C0B1C11000001000000000601000200000C123264000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000E00150003000328465A00000001000000010000000100000000B9BB" }

fn test_the_eb_record_becomes_il_properties() {
    let d = device();
    d.feed(eb_cold());
    expect_props(d, #{ available: "true", water_selection: "COLD" });
    // 255 = no hot water selected: published absent.
    expect_eq(d.property("hot_water_temp_level"), "");
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

fn test_the_ec_uses_the_current_record() {
    let d = device();
    d.feed(ec_normal());
    expect_eq(d.property("water_selection"), "NORMAL");
    d.feed(ec_hot());
    expect_props(d, #{ water_selection: "HOT", hot_water_temp_level: "3" });
    expect_eq(d.script_error(), ());
}

fn test_device_frames_are_acknowledged() {
    let d = device();
    d.feed("AA0912AF0F0002D0BB");
    let clips = d.clips();
    expect_eq(clips.len(), 1);
    expect_eq(clips[0].cmd, "ack");
    expect_eq(clips[0].data, "AA08F000AF0400BB");
    expect_eq(d.script_error(), ());
}

fn test_dispense_reports_publish_the_amounts() {
    let d = device();
    d.start();
    d.feed("AA12121F001A000000170000000000004BBB");
    expect_props(d, #{ last_normal_amount: "26", last_cold_amount: "23" });
    expect_eq(d.property("last_hot_amount"), ());
    d.feed("AA12121F000000120000000000000000AABB");
    expect_props(d, #{ last_hot_amount: "18", last_normal_amount: "26", last_cold_amount: "23" });
    expect_eq(runtime::descriptor(d).props.last_cold_amount.series, "gauge");
    expect_eq(d.script_error(), ());
}

fn test_energy_deltas_add_up_from_zero() {
    let d = device();
    d.start();
    expect_eq(runtime::descriptor(d).props.energy.series, "counter");
    d.feed("AA0912AF0F0002D0BB");
    expect_eq(d.property("energy"), "2");
    d.feed("AA0912AF0F000EC4BB");
    expect_eq(d.property("energy"), "16");
    expect_eq(d.script_error(), ());
}

fn test_writes_are_rejected_and_nothing_is_sent() {
    let d = device();
    d.start();
    d.set("water_selection", "COLD");
    expect_eq(d.sent().len(), 0);
    expect(d.event("reject") != (), "a reject event is published");
    expect_eq(d.script_error(), ());
}
