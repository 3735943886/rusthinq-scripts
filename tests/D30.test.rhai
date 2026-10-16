import "runtime_test" as runtime;

// Tests of D30.rhai (dishwasher), ported from upstream rethink's test suite (commit
// 0e57069; real captures from an LDT54788D). Expected values and writes are what upstream's driver
// publishes and sends for the same input.

fn sample_eb_starting() { "AA2032EB0018010000030E0200030E0000F218020000000000000000000461BB" }
fn sample_eb_running_washing() { "AA2032EB0018020200030E0200030E0000F018020000000000000000000460BB" }
fn sample_ec_normal_energy_saver() { "AA3A32EC0018010000023205000232000072020200000000000000000004001802020002320500023200007002020000000000000000000456BB" }
fn sample_ec_off() { "AA3A32EC0018040000030E0000030E0000720002000000000000000000040018000000030E0000030E0000720002000000000000000000043FBB" }
fn sample_ec_done() { "AA3A32EC0018010000030E0200030E0000F21802000000000000000000040018040000030E0000030E00007200020000000000000000000450BB" }
fn sample_ec_complete_none() { "AA3A32EC0018020600030E020000010000F80002000000000000000000040018050000030E00000001000078000200000000000000000004B4BB" }
fn sample_ec_complete_complete() { "AA3A32EC0018020400030E020000010000F81802000000000000000000040018050500030E020000010000F80002000000000000000000042BBB" }
fn sample_ec_running_rinsing() { "AA3A32EC0018020200030E020001200000F01802000000000000000000040018020300030E020001200000F0180200000000000000000004EABB" }
fn sample_ec_running_drying() { "AA3A32EC0018020300030E020000210000F81802000000000000000000040018020400030E020000210000F818020000000000000000000484BB" }
fn sample_ec_night_dry() { "AA3A32EC0018050500030E020000010000F80002000000000000000000040018020600030E020000010000F80002000000000000000000043DBB" }
fn sample_ec_half_load() { "AA3A32EC00180100000136030001360000F20002000000000000000000040818010000012B0300012B0000F24002000000000000000000046DBB" }
fn sample_ec_half_load_extra_dry() { "AA3A32EC0818010000012B0300012B0000F240020000000000000000000400180100000203030002030000F24402000000000000000000044DBB" }
fn sample_ec_delicate_washing() { "AA3A32EC00180100000203030002030000F244020000000000000000000401180202000203030002030000F04402000000000000000000049DBB" }
fn sample_ec_delicate_night_dry() { "AA3A32EC00180505000203030000010000F000020000000000000000000400180206000203030000010000F000020000000000000000000417BB" }
fn sample_ec_normal_high_temp_selecting() { "AA3A32EC0018010000023205000232000072080200000000000000000004081801000002320500023200007208020000000000000000000443BB" }
fn sample_ec_normal_paused() { "AA3A32EC0018020200023205000232000070080200000000000000000004001803020002320500023200007208020000000000000000000446BB" }
fn sample_ec_normal_resumed() { "AA3A32EC0018030200023205000232000072080200000000000000000004001802020002320500023200007008020000000000000000000446BB" }
fn sample_ec_malformed_long() { "AAC632EC00180505000203030000010000F0000200000000000000000004AEBB000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003180505000203030000010000F000020000000000000000000445030001040000000043002902C500000000001000050436C0102002FF0000000000142E2223384631000001D1000003018600000000000000000000004D14242C180207C10276BB" }
fn sample_ec_turbo_delay_selected() { "AA3A32EC0018010000003B0400003B0000F20002000000000000000000040018010000003B0400003B0000F20102000000000000000000044CBB" }
fn sample_ec_turbo_delayed() { "AA3A32EC0018020100003B0400003B0100F00102000000000000000000040118020100003B0400003B003BF001020000000000000000000402BB" }
fn sample_ec_turbo_delayed_later() { "AA3A32EC0018020100003B0400003B003BF00102000000000000000000040018020100003B0400003B003AF0010200000000000000000004DABB" }
fn sample_ec_express_washing() { "AA3A32EC00180100000022080000220000F200020000000000000000000400180202000022080000220000F0000200000000000000000004E8BB" }
fn sample_ec_express_control_lock() { "AA3A32EC00180100000022080000220000F200020000000000000000000400180100000022080000220000F3000200000000000000000004E8BB" }
fn sample_ec_machine_clean_washing() { "AA3A32EC00180100000116090001160000720002000000000000000000040018020200011609000116000070000200000000000000000004C6BB" }
fn sample_ec_rinse_control_lock() { "AA3A32EC0018010000000C0600000C0000720002000000000000000000040018010000000C0600000C00007300020000000000000000000434BB" }
fn sample_ec_rinse_rinsing() { "AA3A32EC0018020200000C0600000C0000700002000000000000000000040018020300000C0600000C00007000020000000000000000000436BB" }
fn sample_d8_count_40() { "AA0732D828B6BB" }
fn sample_d8_reset_after_machine_clean() { "AA0732D800EEBB" }
fn sample_d8_count_46() { "AA0732D82EBCBB" }
fn sample_serial() { "AA373231020153414134313236333730330000B6F000008000000000000253414133383636393731310000D743FFFC00000000000024BB" }

fn last(d) { let s = d.sent(); hex_encode_upper(s[s.len() - 1]) }

fn test_sample_eb_starting() {
    let d = device();
    d.feed(sample_eb_starting());
    expect_props(d, #{ initial_time: "194", remaining_time: "194", delay_start_time: "0", status: "ready", process: "none", course: "heavy", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "true", dual_zone: "true", delay_start: "false", night_dry: "true", rinse_refill: "false", door: "true", child_lock: "false" });
}

fn test_sample_eb_running_washing() {
    let d = device();
    d.feed(sample_eb_running_washing());
    expect_props(d, #{ initial_time: "194", remaining_time: "194", delay_start_time: "0", status: "running", process: "washing", course: "heavy", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "true", dual_zone: "true", delay_start: "false", night_dry: "true", rinse_refill: "false", door: "false", child_lock: "false" });
}

fn test_sample_ec_normal_energy_saver() {
    let d = device();
    d.feed(sample_ec_normal_energy_saver());
    expect_props(d, #{ initial_time: "170", remaining_time: "170", delay_start_time: "0", status: "running", process: "washing", course: "normal", energy_saver: "true", half_load: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "false", night_dry: "false", rinse_refill: "false", door: "false", child_lock: "false" });
}

fn test_sample_ec_off() {
    let d = device();
    d.feed(sample_ec_off());
    expect_props(d, #{ initial_time: "194", remaining_time: "194", delay_start_time: "0", status: "off", process: "none", course: "off", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "false", night_dry: "false", rinse_refill: "false", door: "true", child_lock: "false" });
}

fn test_sample_ec_done() {
    let d = device();
    d.feed(sample_ec_done());
    expect_props(d, #{ initial_time: "194", remaining_time: "194", delay_start_time: "0", status: "standby", process: "none", course: "off", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "false", night_dry: "false", rinse_refill: "false", door: "true", child_lock: "false" });
}

fn test_sample_ec_complete_none() {
    let d = device();
    d.feed(sample_ec_complete_none());
    expect_props(d, #{ initial_time: "194", remaining_time: "1", delay_start_time: "0", status: "finished", process: "none", course: "off", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "false", night_dry: "false", rinse_refill: "true", door: "false", child_lock: "false" });
}

fn test_sample_ec_complete_complete() {
    let d = device();
    d.feed(sample_ec_complete_complete());
    expect_props(d, #{ initial_time: "194", remaining_time: "1", delay_start_time: "0", status: "finished", process: "finished", course: "off", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "false", night_dry: "true", rinse_refill: "true", door: "false", child_lock: "false" });
}

fn test_sample_ec_running_rinsing() {
    let d = device();
    d.feed(sample_ec_running_rinsing());
    expect_props(d, #{ initial_time: "194", remaining_time: "92", delay_start_time: "0", status: "running", process: "rinsing", course: "heavy", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "true", dual_zone: "true", delay_start: "false", night_dry: "true", rinse_refill: "false", door: "false", child_lock: "false" });
}

fn test_sample_ec_running_drying() {
    let d = device();
    d.feed(sample_ec_running_drying());
    expect_props(d, #{ initial_time: "194", remaining_time: "33", delay_start_time: "0", status: "running", process: "drying", course: "heavy", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "true", dual_zone: "true", delay_start: "false", night_dry: "true", rinse_refill: "true", door: "false", child_lock: "false" });
}

fn test_sample_ec_night_dry() {
    let d = device();
    d.feed(sample_ec_night_dry());
    expect_props(d, #{ initial_time: "194", remaining_time: "1", delay_start_time: "0", status: "running", process: "night_dry", course: "heavy", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "false", night_dry: "true", rinse_refill: "true", door: "false", child_lock: "false" });
}

fn test_sample_ec_half_load() {
    let d = device();
    d.feed(sample_ec_half_load());
    expect_props(d, #{ initial_time: "103", remaining_time: "103", delay_start_time: "0", status: "ready", process: "none", course: "delicate", energy_saver: "false", half_load: "true", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "false", night_dry: "true", rinse_refill: "false", door: "true", child_lock: "false" });
}

fn test_sample_ec_half_load_extra_dry() {
    let d = device();
    d.feed(sample_ec_half_load_extra_dry());
    expect_props(d, #{ initial_time: "123", remaining_time: "123", delay_start_time: "0", status: "ready", process: "none", course: "delicate", energy_saver: "false", half_load: "true", extra_dry: "true", high_temp: "false", dual_zone: "false", delay_start: "false", night_dry: "true", rinse_refill: "false", door: "true", child_lock: "false" });
}

fn test_sample_ec_delicate_washing() {
    let d = device();
    d.feed(sample_ec_delicate_washing());
    expect_props(d, #{ initial_time: "123", remaining_time: "123", delay_start_time: "0", status: "running", process: "washing", course: "delicate", energy_saver: "false", half_load: "true", extra_dry: "true", high_temp: "false", dual_zone: "false", delay_start: "false", night_dry: "true", rinse_refill: "false", door: "false", child_lock: "false" });
}

fn test_sample_ec_delicate_night_dry() {
    let d = device();
    d.feed(sample_ec_delicate_night_dry());
    expect_props(d, #{ initial_time: "123", remaining_time: "1", delay_start_time: "0", status: "running", process: "night_dry", course: "delicate", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "false", night_dry: "true", rinse_refill: "false", door: "false", child_lock: "false" });
}

fn test_sample_ec_normal_high_temp_selecting() {
    let d = device();
    d.feed(sample_ec_normal_high_temp_selecting());
    expect_props(d, #{ initial_time: "170", remaining_time: "170", delay_start_time: "0", status: "ready", process: "none", course: "normal", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "true", dual_zone: "false", delay_start: "false", night_dry: "false", rinse_refill: "false", door: "true", child_lock: "false" });
}

fn test_sample_ec_normal_paused() {
    let d = device();
    d.feed(sample_ec_normal_paused());
    expect_props(d, #{ initial_time: "170", remaining_time: "170", delay_start_time: "0", status: "paused", process: "washing", course: "normal", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "true", dual_zone: "false", delay_start: "false", night_dry: "false", rinse_refill: "false", door: "true", child_lock: "false" });
}

fn test_sample_ec_normal_resumed() {
    let d = device();
    d.feed(sample_ec_normal_resumed());
    expect_props(d, #{ initial_time: "170", remaining_time: "170", delay_start_time: "0", status: "running", process: "washing", course: "normal", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "true", dual_zone: "false", delay_start: "false", night_dry: "false", rinse_refill: "false", door: "false", child_lock: "false" });
}

fn test_sample_ec_malformed_long() {
    let d = device();
    d.feed(sample_ec_malformed_long());
    expect_eq(d.property("status"), ());
    expect_eq(d.property("energy"), ());
}

fn test_sample_ec_turbo_delay_selected() {
    let d = device();
    d.feed(sample_ec_turbo_delay_selected());
    expect_props(d, #{ initial_time: "59", remaining_time: "59", delay_start_time: "0", status: "ready", process: "none", course: "turbo", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "true", night_dry: "true", rinse_refill: "false", door: "true", child_lock: "false" });
}

fn test_sample_ec_turbo_delayed() {
    let d = device();
    d.feed(sample_ec_turbo_delayed());
    expect_props(d, #{ initial_time: "59", remaining_time: "59", delay_start_time: "59", status: "running", process: "reserved", course: "turbo", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "true", night_dry: "true", rinse_refill: "false", door: "false", child_lock: "false" });
}

fn test_sample_ec_turbo_delayed_later() {
    let d = device();
    d.feed(sample_ec_turbo_delayed_later());
    expect_props(d, #{ initial_time: "59", remaining_time: "59", delay_start_time: "58", status: "running", process: "reserved", course: "turbo", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "true", night_dry: "true", rinse_refill: "false", door: "false", child_lock: "false" });
}

fn test_sample_ec_express_washing() {
    let d = device();
    d.feed(sample_ec_express_washing());
    expect_props(d, #{ initial_time: "34", remaining_time: "34", delay_start_time: "0", status: "running", process: "washing", course: "express", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "false", night_dry: "true", rinse_refill: "false", door: "false", child_lock: "false" });
}

fn test_sample_ec_express_control_lock() {
    let d = device();
    d.feed(sample_ec_express_control_lock());
    expect_props(d, #{ initial_time: "34", remaining_time: "34", delay_start_time: "0", status: "ready", process: "none", course: "express", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "false", night_dry: "true", rinse_refill: "false", door: "true", child_lock: "true" });
}

fn test_sample_ec_machine_clean_washing() {
    let d = device();
    d.feed(sample_ec_machine_clean_washing());
    expect_props(d, #{ initial_time: "82", remaining_time: "82", delay_start_time: "0", status: "running", process: "washing", course: "machine_clean", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "false", night_dry: "false", rinse_refill: "false", door: "false", child_lock: "false" });
}

fn test_sample_ec_rinse_control_lock() {
    let d = device();
    d.feed(sample_ec_rinse_control_lock());
    expect_props(d, #{ initial_time: "12", remaining_time: "12", delay_start_time: "0", status: "ready", process: "none", course: "rinse", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "false", night_dry: "false", rinse_refill: "false", door: "true", child_lock: "true" });
}

fn test_sample_ec_rinse_rinsing() {
    let d = device();
    d.feed(sample_ec_rinse_rinsing());
    expect_props(d, #{ initial_time: "12", remaining_time: "12", delay_start_time: "0", status: "running", process: "rinsing", course: "rinse", energy_saver: "false", half_load: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", delay_start: "false", night_dry: "false", rinse_refill: "false", door: "false", child_lock: "false" });
}

fn test_sample_d8_count_40() {
    let d = device();
    d.feed(sample_d8_count_40());
    expect_props(d, #{ tub_clean_counter: "40" });
}

fn test_sample_d8_reset_after_machine_clean() {
    let d = device();
    d.feed(sample_d8_reset_after_machine_clean());
    expect_props(d, #{ tub_clean_counter: "0" });
}

fn test_sample_d8_count_46() {
    let d = device();
    d.feed(sample_d8_count_46());
    expect_props(d, #{ tub_clean_counter: "46" });
}

fn test_sample_serial() {
    let d = device();
    d.feed(sample_serial());
    expect_eq(d.property("status"), ());
    expect_eq(d.property("energy"), ());
}

fn test_unknown_and_read_only_writes_are_rejected() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("does_not_exist", "1");
    d.set("door", "true");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "rejects are published");
}

fn test_start_sends_the_status_query() {
    let d = device();
    d.start();
    expect_eq(last(d), "AA0EF0ED1121010000001800B5BB");
}
