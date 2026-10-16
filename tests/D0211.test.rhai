import "runtime_test" as runtime;

// Tests of D0211.rhai (dishwasher), ported from upstream rethink's test suite (commit
// 0e57069; real captures from a DB365TXS / DBC435TSL). Expected values and writes are what upstream's driver
// publishes and sends for the same input.

fn sensing_steam() { "AA2032EB0018010000040B0200040B0000728002040100000000000000004CBB" }
fn idle_eco() { "AA3A32EC001801000003350500033500007200020401000000000000000008180100000335050003350000720002040100000000000000004DBB" }
fn running_dry_steam() { "AA3A32EC0018020300040B0200011F0000708002040100000000000000000018020400040B0200011F000070800204010000000000000000D8BB" }
fn completing_options_cleared() { "AA3A32EC0018020400040B020000010000728002040100000000000000000018050500040B020000010000720002040100000000000000008DBB" }
fn end() { "AA3A32EC0018050500040B020000010000720002040100000000000000000018040000040B0000000100007200020401000000000000000001BB" }
fn running_intensive_no_options() { "AA3A32EC001801000003050200030500007200020401000000000000000000180202000305020003050000700002040100000000000000001EBB" }
fn running_dual_zone() { "AA3A32EC0018010000022A0100022A0000721002040100000000000000000818020200022A0100022A00007010020401000000000000000054BB" }
fn running_salt() { "AA3A32EC001801000002390100023900007A020204010000000000000000081802020002390100023900007802020401000000000000000064BB" }
fn running_eco_extra_dry() { "AA3A32EC001801000003210500032100007204020401000000000000000000180202000321050003210000700402040100000000000000009CBB" }
fn running_auto_high_temp_half_load() { "AA3A32EC0018010000032C0100032C0000724802040100000000000000000018020200032C0100032C00007048020401000000000000000020BB" }
fn countdown_delay_start() { "AA3A32EC0018010000033505000335000072110204010000000000000000001802010003350500033501007011020401000000000000000066BB" }
fn idle_high_temp() { "AA3A32EC0018010000033201000332000072080204010000000000000000001801000003320100033200007218020401000000000000000049BB" }
fn idle_child_lock() { "AA3A32EC0018010000033201000332000072180204010000000000000000001801000003320100033200007318020401000000000000000078BB" }
fn idle_half_load_extra_dry() { "AA3A32EC0018010000031201000312000072540204010000000000000000001801000003120100031200007244020401000000000000000041BB" }
fn running_rinse_refill() { "AA3A32EC001802040003350500003800007210020401000000000000000000180204000335050000380000761002040100000000000000006BBB" }
fn transition() { "AA0732D81199BB" }
fn handshake() { "AA373231020153414134313236333932350000D1DB00008000000000000253414134313236313032300000FFA7FFFC000000000000A5BB" }

fn last(d) { let s = d.sent(); hex_encode_upper(s[s.len() - 1]) }

fn test_sensing_steam() {
    let d = device();
    d.feed(sensing_steam());
    expect_props(d, #{ initial_time: "251", remaining_time: "251", status: "ready", process: "none", course: "off", delay_start: "false", energy_saver: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", half_load: "false", steam: "false", child_lock: "false", door: "true", rinse_refill: "false", salt_refill: "false" });
}

fn test_idle_eco() {
    let d = device();
    d.feed(idle_eco());
    expect_props(d, #{ initial_time: "233", remaining_time: "233", status: "ready", process: "none", course: "off", delay_start: "false", energy_saver: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", half_load: "false", steam: "false", child_lock: "false", door: "true", rinse_refill: "false", salt_refill: "false" });
}

fn test_running_dry_steam() {
    let d = device();
    d.feed(running_dry_steam());
    expect_props(d, #{ initial_time: "251", remaining_time: "91", status: "running", process: "drying", course: "intensive", delay_start: "false", energy_saver: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", half_load: "false", steam: "true", child_lock: "false", door: "false", rinse_refill: "false", salt_refill: "false" });
}

fn test_completing_options_cleared() {
    let d = device();
    d.feed(completing_options_cleared());
    expect_props(d, #{ initial_time: "251", remaining_time: "1", status: "finished", process: "finished", course: "off", delay_start: "false", energy_saver: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", half_load: "false", steam: "false", child_lock: "false", door: "true", rinse_refill: "false", salt_refill: "false" });
}

fn test_end() {
    let d = device();
    d.feed(end());
    expect_props(d, #{ initial_time: "251", remaining_time: "1", status: "standby", process: "none", course: "off", delay_start: "false", energy_saver: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", half_load: "false", steam: "false", child_lock: "false", door: "true", rinse_refill: "false", salt_refill: "false" });
}

fn test_running_intensive_no_options() {
    let d = device();
    d.feed(running_intensive_no_options());
    expect_props(d, #{ initial_time: "185", remaining_time: "185", status: "running", process: "washing", course: "intensive", delay_start: "false", energy_saver: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", half_load: "false", steam: "false", child_lock: "false", door: "false", rinse_refill: "false", salt_refill: "false" });
}

fn test_running_dual_zone() {
    let d = device();
    d.feed(running_dual_zone());
    expect_props(d, #{ initial_time: "162", remaining_time: "162", status: "running", process: "washing", course: "auto", delay_start: "false", energy_saver: "false", extra_dry: "false", high_temp: "false", dual_zone: "true", half_load: "false", steam: "false", child_lock: "false", door: "false", rinse_refill: "false", salt_refill: "false" });
}

fn test_running_salt() {
    let d = device();
    d.feed(running_salt());
    expect_props(d, #{ initial_time: "177", remaining_time: "177", status: "running", process: "washing", course: "auto", delay_start: "false", energy_saver: "true", extra_dry: "false", high_temp: "false", dual_zone: "false", half_load: "false", steam: "false", child_lock: "false", door: "false", rinse_refill: "false", salt_refill: "true" });
}

fn test_running_eco_extra_dry() {
    let d = device();
    d.feed(running_eco_extra_dry());
    expect_props(d, #{ initial_time: "213", remaining_time: "213", status: "running", process: "washing", course: "eco", delay_start: "false", energy_saver: "false", extra_dry: "true", high_temp: "false", dual_zone: "false", half_load: "false", steam: "false", child_lock: "false", door: "false", rinse_refill: "false", salt_refill: "false" });
}

fn test_running_auto_high_temp_half_load() {
    let d = device();
    d.feed(running_auto_high_temp_half_load());
    expect_props(d, #{ initial_time: "224", remaining_time: "224", status: "running", process: "washing", course: "auto", delay_start: "false", energy_saver: "false", extra_dry: "false", high_temp: "true", dual_zone: "false", half_load: "true", steam: "false", child_lock: "false", door: "false", rinse_refill: "false", salt_refill: "false" });
}

fn test_countdown_delay_start() {
    let d = device();
    d.feed(countdown_delay_start());
    expect_props(d, #{ initial_time: "233", remaining_time: "233", status: "running", process: "reserved", course: "eco", delay_start: "true", energy_saver: "false", extra_dry: "false", high_temp: "false", dual_zone: "true", half_load: "false", steam: "false", child_lock: "false", door: "false", rinse_refill: "false", salt_refill: "false" });
}

fn test_idle_high_temp() {
    let d = device();
    d.feed(idle_high_temp());
    expect_props(d, #{ initial_time: "230", remaining_time: "230", status: "ready", process: "none", course: "off", delay_start: "false", energy_saver: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", half_load: "false", steam: "false", child_lock: "false", door: "true", rinse_refill: "false", salt_refill: "false" });
}

fn test_idle_child_lock() {
    let d = device();
    d.feed(idle_child_lock());
    expect_props(d, #{ initial_time: "230", remaining_time: "230", status: "ready", process: "none", course: "off", delay_start: "false", energy_saver: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", half_load: "false", steam: "false", child_lock: "true", door: "true", rinse_refill: "false", salt_refill: "false" });
}

fn test_idle_half_load_extra_dry() {
    let d = device();
    d.feed(idle_half_load_extra_dry());
    expect_props(d, #{ initial_time: "198", remaining_time: "198", status: "ready", process: "none", course: "off", delay_start: "false", energy_saver: "false", extra_dry: "false", high_temp: "false", dual_zone: "false", half_load: "false", steam: "false", child_lock: "false", door: "true", rinse_refill: "false", salt_refill: "false" });
}

fn test_running_rinse_refill() {
    let d = device();
    d.feed(running_rinse_refill());
    expect_props(d, #{ initial_time: "233", remaining_time: "56", status: "running", process: "drying", course: "eco", delay_start: "false", energy_saver: "false", extra_dry: "false", high_temp: "false", dual_zone: "true", half_load: "false", steam: "false", child_lock: "false", door: "true", rinse_refill: "true", salt_refill: "false" });
}

fn test_transition() {
    let d = device();
    d.feed(transition());
    expect_props(d, #{ tub_clean_counter: "17" });
    let clips = d.clips();
    expect_eq(clips.len(), 1);
    expect_eq(clips[0].cmd, "ack");
    expect_eq(clips[0].data, "AA08F000D8042BBB");
}

fn test_handshake() {
    let d = device();
    d.feed(handshake());
    expect_eq(d.property("status"), ());
    expect_eq(d.property("energy"), ());
    let clips = d.clips();
    expect_eq(clips.len(), 1);
    expect_eq(clips[0].cmd, "ack");
    expect_eq(clips[0].data, "AA08F000310482BB");
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
    expect_eq(hex_encode_upper(d.sent()[0]), "AA0EF0ED1121010000001800B5BB");
}
