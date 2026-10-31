import "runtime_test" as runtime;

// Tests of G2V7_Y___W.B_2QEUK, ported from upstream rethink's test suite (commit 2d8eaba; real
// frames from an F2NX50S9TKC). Expected values and writes are what upstream's driver publishes and
// sends for the same input, in IL names; a value upstream leaves unknown ("None") is absent here (an
// empty retained value), and child_lock is true while locked (upstream publishes it inverted, for
// Home Assistant's lock class).

fn ready_cotton() { "AAFF200A005500C7F9000100EB00430003030E082E0000000000000000CB00CB0000002E010090000004020504000000000000004000001000000000000004000000000000000000000000000000180000009383BB" }
fn pair_easy_care() { "AAFF200A009800C818000100EC00860003030E082E0000000000000000CB00CB0000002E010090000004020504000000000000004000001000000000000004000000000000000000000000000000180000000003030E081D00000000000000009400940000001D01009000000302050400000000000000400000100000000000000400000000000000000000000000000018000000B3FCBB" }
fn pair_download_cycle() { "AAFF200A009800C84B000100EC00860003030E044F00000000000000003900390000004F010090090002020504000000000000004000001000000000000004000000000000000000000000000000180000000003000E08FF0000000000000000100010000000FF0100900900010105040000000000000040000010000000000000040000000000000000000000000000001800000078E8BB" }
fn ready_cold() { "AAFF200A005500C8D3000100EB00430003080E082E00000000000000005D005D0000002E010090000004020504000000000000000000001000000000000004000000000000000000000000000000180000005B9EBB" }
fn pair_door_closed() { "AAFF200A009800CE17000100EC00860003030E062B00000000000000005600560000002B010090000003020504000000000000000000001000000000000004000000000000000000000000000000180000000003030E062B00000000000000005600560000002B01009000000302050400000000000000010000100000000000000400000000000000000000000000000018000000B10DBB" }
fn paused_no_spin() { "AAFF200A00550005E4000100EB00430003050E0C2E00000000000000004200420000002E020B90010004020404000000000000004101001000000000000004000000000000000000000000000000180000008068BB" }
fn pair_washing() { "AAFF200A0098000D67000100EC00860003020E082E00000000000000007100710000002E030190000000020504000000000000009101001000000000000004000000000000000000000000000000180000000003020E082E00000000000000003900390000002E0B039003000002050400000000000000910100100000000000000400000000000000000000000000000018000000AAE0BB" }
fn pair_rinsing() { "AAFF200A0098000ECE000100EC00860003020E082E0000000000000000260039001E002E0B0390030000020504000000000000009101001000000000000004000000000000000000000000000000180000000003000E082E0000000000000000250039001E002E0C0B9003000002050400000000000000110100100000000000000400000000000000000000000000000018000000C9D3BB" }
fn pair_spinning() { "AAFF200A009800AE67000100EC00860003000E082E00000000000000000C003A00C8002E0C0B900400010106040000000000000011010010000000000000040000000000000000000000000000001800000000000000082E00000000000000000B003A00C8002E0E0C9004000100060400000000000000110100100000000000000400000000000000000000000000000018000000B40CBB" }
fn end() { "AAFF200A00550011BD000100EB004300000000002E0000000000000000000039004C002E100E90000001000604000000000000004101001000000000000004000000000000000000000000000000180000008F81BB" }
fn pair_off_after_end() { "AAFF200A00980011CF000100EC008600000000002E0000000000000000000039004C002E100E900000010006040000000000000041010010000000000000040000000000000000000000000000001800000000000000002E0000000000000000000039004C002E00109000000400060400000000000000400000100000000000000400000000000000000000000000000018000000DDA3BB" }
fn pair_energy_high_byte() { "AAFF200A00980001A3000100EC00860003030E087A00000000000000001B002700FF007A0B0190090000010B04000000002000001101001000000000000004000000000000000000000000000000180000000003030E087A00000000000000001B00270100007A0B0190090000010B04000000002000001101001000000000000004000000000000000000000000000000180000000421BB" }
fn after_power_cut() { "AAFF200A00550005C9000100EB0043000000000000000000000000000000000000000000000000000000000004000000000000000000201000000000000004000000000000000000000000000000180000007749BB" }
fn pair_child_lock_on() { "AAFF200A0098008ED9000100EC00860003010E014B00000000000000000E000E0000004B0B0290090000021504000000002000009101001000000000000004000000000000000000000000000000180000000003010E014B00000000000000000E000E0000004B0B029009000002150400000000200000B101001000000000000004000000000000000000000000000000180000002F90BB" }
fn pair_child_lock_off() { "AAFF200A0098008EEC000100EC00860003010E014B00000000000000000D000E0008004B0B029009000002150400000000200000B101001000000000000004000000000000000000000000000000180000000003010E014B00000000000000000D000E0009004B0B0290090000021504000000002000009101001000000000000004000000000000000000000000000000180000003804BB" }
fn pair_remote_start_on() { "AAFF200A0098008E83000100EC00860003010E014B00000000000000000E000E0000004B010090090001021504000000002000004100001000000000000004000000000000000000000000000000180000000003010E014B00000000000000000E000E0000004B01009009000102150400000000200000510000100000000000000400000000000000000000000000000018000000BE45BB" }
fn pair_rinse_plus() { "AAFF200A0098009060000100EC00860003030E082E0000000000000000CB00CB0000002E010090000004021604000000000000004000001000000000000004000000000000000000000000000000180000000003030F082E0000000000000000DA00DA0000002E01009000000502160400000000000000400040100000000000000400000000000000000000000000000018000000C1A2BB" }
fn pair_intensive() { "AAFF200A0098009068000100EC00860003030E082E0000000000000000CB00CB0000002E01009000000402160400000000000000400000100000000000000400000000000000000000000000000018000000000A030E082E0000000000000000EA00EA0000002E010090000004021604000000000800004000001000000000000004000000000000000000000000000000180000003A49BB" }
fn pair_prewash() { "AAFF200A009800906F000100EC00860003030E082E0000000000000000CB00CB0000002E010090000004021604000000000000004000001000000000000004000000000000000000000000000000180000000003030E082E0000000000000000DC00DC0000002E01009000000502160400000000400000400000100000000000000400000000000000000000000000000018000000C0E0BB" }
fn pair_turbowash() { "AAFF200A0098009077000100EC00860003030E082E0000000000000000CB00CB0000002E010090000004021604000000000000004000001000000000000004000000000000000000000000000000180000000003030E062E0000000000000000A600A60000002E010090000004021604000000002000004000001000000000000004000000000000000000000000000000180000000D53BB" }
fn pair_delay_5h() { "AAFF200A0098009155000100EC00860003030E082E000000000000B400CB00CB0001002E010090000004021604000000000000004100801000000000000004000000000000000000000000000000180000000003030E082E0000000000012C00CB00CB0001002E010090000004021604000000000000004100801000000000000004000000000000000000000000000000180000005D26BB" }
fn pair_delayed() { "AAFF200A0098009125000100EC00860003030E082E000000000000B4003800380000002E070390010000021604000000000000009101801000000000000004000000000000000000000000000000180000000003030E082E000000000000B3003800380000002E07039001000002160400000000000000910180100000000000000400000000000000000000000000000018000000FA24BB" }
fn start_refused() { "AA08200024FFA0BB" }
fn start_taken() { "AA0820002400A3BB" }

fn fed(frames) { let d = device(); for f in frames { d.feed(f); } d }

// asks for the status once on connect, and never again
fn test_start_asks_for_the_status() {
    let d = device();
    d.start();
    expect_eq(d.sent().map(|s| hex_encode_upper(s)), ["AA0EF0ED1121010000001800B5BB"]);
}

// the 0xeb answer decodes the selected course
fn test_the_eb_answer() {
    expect_props(fed([ready_cotton()]), #{ power: "true", status: "standby", course: "cotton", temp: "40", spin: "1200",
                                           initial_time: "203", remaining_time: "203", door: "true", cycles: "5" });
}

// a pushed 0xec pair is read from its second record
fn test_a_pushed_pair() {
    let d = fed([ready_cotton(), pair_easy_care()]);
    expect_props(d, #{ course: "easy_care", initial_time: "148" });
    d.feed(pair_download_cycle());
    // Rinse + Spin heats nothing
    expect_props(d, #{ course: "download_cycle", temp: "", spin: "1200", initial_time: "16" });
}

// the zero settings sit past the top of their scales
fn test_the_zero_settings() {
    let d = fed([ready_cold()]);
    expect_eq(d.property("temp"), "cold");
    d.feed(paused_no_spin());
    expect_props(d, #{ status: "paused", temp: "60", spin: "no_spin" });
}

// the door
fn test_the_door() {
    let d = fed([ready_cold()]);
    expect_eq(d.property("door"), "true");
    d.feed(pair_door_closed());
    expect_props(d, #{ door: "false", course: "mix", spin: "1000" });
}

// a wash, phase by phase
fn test_a_wash() {
    let d = fed([pair_washing()]);
    expect_props(d, #{ status: "washing", temp: "30", initial_time: "57" });
    d.feed(pair_rinsing());
    // the temperature clears once the wash phase is over
    expect_props(d, #{ status: "rinsing", remaining_time: "37", energy: "30", temp: "", spin: "1200" });
    d.feed(pair_spinning());
    expect_props(d, #{ status: "spinning", remaining_time: "11", energy: "200" });
}

// the energy count is 16 bits
fn test_the_energy_count() {
    expect_props(fed([pair_energy_high_byte()]), #{ course: "turbo_wash_39", energy: "256", cycles: "11" });
}

// an idle machine publishes no settings, but keeps its energy total
fn test_an_idle_machine() {
    let d = fed([end()]);
    expect_props(d, #{ status: "end", remaining_time: "0", spin: "" });
    d.feed(pair_off_after_end());
    // course and times are still in the record, but the panel no longer shows them
    expect_props(d, #{ power: "false", status: "off", course: "", initial_time: "", remaining_time: "", energy: "76", cycles: "6" });
}

// the wash count is not taken from a machine that is off
fn test_the_wash_count_after_a_power_cut() {
    expect_props(fed([ready_cotton(), after_power_cut()]), #{ power: "false", cycles: "5" });
}

// child lock
fn test_child_lock() {
    let d = fed([pair_child_lock_on()]);
    expect_props(d, #{ course: "quick_14", child_lock: "true" });
    d.feed(pair_child_lock_off());
    expect_props(d, #{ child_lock: "false", energy: "9" });
}

// remote start
fn test_remote_start() {
    let d = fed([pair_remote_start_on()]);
    // TurboWash is Quick 14's default
    expect_props(d, #{ remote_start: "true", turbo_wash: "true" });
    d.feed(pair_washing()); // a wash started at the panel
    expect_eq(d.property("remote_start"), "true");
    d.feed(ready_cotton());
    expect_eq(d.property("remote_start"), "false");
}

// the option buttons
fn test_the_option_buttons() {
    let d = fed([ready_cotton()]);
    let options = |d| [d.property("rinse_plus"), d.property("intensive"), d.property("pre_wash"), d.property("turbo_wash")];
    expect_eq(options.call(d), ["false", "false", "false", "false"]);
    d.feed(pair_rinse_plus());
    expect_eq(options.call(d), ["true", "false", "false", "false"]);
    expect_eq(d.property("initial_time"), "218");
    d.feed(pair_intensive());
    expect_eq(options.call(d), ["false", "true", "false", "false"]);
    d.feed(pair_prewash());
    expect_eq(options.call(d), ["false", "false", "true", "false"]);
    d.feed(pair_turbowash());
    expect_eq(options.call(d), ["false", "false", "false", "true"]);
    expect_eq(d.property("spin"), "1000");
}

// delay end
fn test_delay_end() {
    let d = fed([ready_cotton()]);
    expect_eq(d.property("delay_end"), "0");
    d.feed(pair_delay_5h());
    expect_eq(d.property("delay_end"), "300");
    d.feed(pair_delayed());
    expect_props(d, #{ status: "delayed", delay_end: "179", remaining_time: "56" });
}

// a refused command is logged (upstream); here a command answer is simply not status
fn test_a_command_answer_is_not_status() {
    expect_eq(fed(["AA0820002400A3BB", "AA08200024FFA0BB"]).property("power"), ());
}

// every envelope is acked by its sequence number
fn test_every_envelope_is_acked() {
    let d = fed([ready_cotton(), pair_easy_care()]);
    expect_eq(d.clips().map(|c| c.data),
              [hex_encode_upper(aabb_wrap(hex_decode("f0000a04c7f9"))), hex_encode_upper(aabb_wrap(hex_decode("f0000a04c818")))]);
}

// commands (start and pause offered while Remote Start is armed, which the washer itself requires)
fn test_commands() {
    let d = device();
    d.start();
    d.feed(pair_remote_start_on());
    let n = d.sent().len();
    d.set("power", "true");
    d.set("power", "false");
    d.set("pause", "");
    d.set("start", "");
    expect_eq(d.sent().map(|s| hex_encode_upper(s)).extract(n),
              ["AA08F02A010098BB", "AA09F0240101009CBB", "AA09F02404010099BB", "AA09F02405010098BB"]);
}

// start is refused here, as by the washer, while Remote Start is off
fn test_start_needs_remote_start() {
    let d = device();
    d.start();
    d.feed(ready_cotton());
    let n = d.sent().len();
    d.set("start", "");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject").contains("requires_unmet"), "requires remote_start");
}
