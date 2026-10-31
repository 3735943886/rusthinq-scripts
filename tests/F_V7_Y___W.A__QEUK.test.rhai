import "runtime_test" as runtime;

// Tests of F_V7_Y___W.A__QEUK, an alias of F_C__Y___W.A__QEUK (washer_fc_common), ported from
// upstream rethink's test suite (commit 2d8eaba; live captures from a WV5-1275W). Expected values
// are what upstream's driver publishes for the same input, in IL names; door_lock is true while
// locked (upstream publishes it inverted, for Home Assistant's lock class).

fn sample_measuring() { "AA4220EC001C0100000000010000000000000000000000000001002C006400000000001C04023A023A010003090401000000000000000104002C006400000000B3BB" }
fn sample_washing() { "AA4220EC001C04023A023A010003090401000000004000000104002C006400000000001C06010F010F010003090401000000004000000106002C006400000000F7BB" }
fn sample_washing_tick() { "AA4220EC001C06010E010F010003090401000000004000000106002C006400000000001C06010D010F010003090401000000004000000106002C0064000000001EBB" }
fn sample_bd_dump() { "AA0020BD000101900101020800010034000008000000000005000900600000640E2B000000000005CC03313132343118191A1918FFFFFFFFFF0000000000000000000000000000000000000000000000000000000000000000000000013B000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003004606000000000300000100EB00D20184FFEE010006000000E7FF011D330400DE0E3918000000000000330400F2164119000000000000320207061641190000000000003A0207061641190000000000003304015C536C200000000000003304011E2C521C000000000000340202C2224B1B0000000000003A0202C2224B1B000000000000340202EE264E1C00000000000032020646264E1C000000000000340202BE44621F0000000000003A0202BE44621F000000000000340202CC375A1D000000000000340203346878220000000000003303022468782200000000000002D000000100000000000000000000000000000000000000000000000000000000000000000000A7BB" }

// Measuring packet decodes Cotton 40°C 1200 rpm 178 min
fn test_measuring() {
    let d = device();
    d.feed(sample_measuring());
    expect_props(d, #{ power: "true", status: "detecting", course: "cotton", temp: "40", spin: "1200", remaining_time: "178", initial_time: "178", error: "false", active: "false", cycles: "44", door_lock: "true" });
}

// Washing after load-sense publishes 75 min and active=ON
fn test_washing_after_load_sense() {
    let d = device();
    d.feed(sample_washing());
    expect_props(d, #{ status: "washing", course: "cotton", temp: "40", spin: "1200", remaining_time: "75", initial_time: "75", active: "true", steam: "false", door_lock: "true" });
}

// remaining time counts down without resetting initial
fn test_remaining_time_counts_down() {
    let d = device();
    d.feed(sample_washing());
    d.feed(sample_washing_tick());
    expect_props(d, #{ status: "washing", remaining_time: "73", initial_time: "75" });
}

// 0xBD dump does not clobber 0xEC status
fn test_bd_dump_does_not_clobber_the_status() {
    let d = device();
    d.feed(sample_measuring());
    d.feed(sample_bd_dump());
    expect_props(d, #{ status: "detecting", course: "cotton", remaining_time: "178" });
}
