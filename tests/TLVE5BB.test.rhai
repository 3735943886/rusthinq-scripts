import "runtime_test" as runtime;

// Tests of TLVE5BB, ported from upstream rethink's test suite (commit 0e57069; real frames
// captured from a WT21BWV6 while washing). Each EC frame holds the previous and current 50-byte
// records; only the current one is published. lid_lock is true while locked, as upstream's.

fn running_87_to_86() {
    "aa ff 20 0a 00 76 00 9c 86 00 01 00 ec 00 64" +
        "00 05 08 03 0e 09 00 00 09 06 00 00 00 00 57 00 6a 00 15 00 2e 0b 0b 6f 00 00 00 03 2d 04 00 00 00 00 00 00 00 10 01 00 30 00 00 00 00 00 00 00 00 00" +
        "00 05 08 03 0e 09 00 00 09 06 00 00 00 00 56 00 6a 00 17 00 2e 0b 0b 6f 00 00 00 03 2d 04 00 00 00 00 00 00 00 10 01 00 30 00 00 00 00 00 00 00 00 00" +
        "17 c9 bb"
}
fn end_() { "aaff200a007600a0cd000100ec0064000508000e09000009060000000001006a0050002e0e0e6f000000002d040000000000000010010030000000000000000000000508000e09000009060000000001006a0055002e10106f000000002d0400000000000000000100300000000000000000001e67bb" }
fn end_unlocked() { "aaff200a007600a0d4000100ec0064000508000e09000009060000000001006a0055002e10106f000000002d040000000000000000010030000000000000000000000508000e09000009060000000001006a0055002e10106f000000002d0400000000000000000000300000000000000000003a09bb" }
fn off_() { "aaff200a007600a0dd000100ec0064000508000e09000009060000000001006a0055002e10106f000000002d040000000000000000000030000000000000000000000508000e09000009060000000001006a0055002e00006f000000002d04000000000000000000003000000000000000000033b6bb" }
fn off_snapshot() { "aaff200a004400a0fa000100eb0032000508000e09000009060000000001006a0055002e00006f000000002d040000000000000000000030000000000000000000d5a3bb" }

// decodes the current record from a paired running update
fn test_a_running_update_decodes_the_current_record() {
    let d = device();
    d.feed(running_87_to_86());
    expect_props(d, #{ power: "true", status: "running", remaining_time: "86", initial_time: "106",
                       energy: "23", soil: "heavy", temp: "cold", spin: "medium", rinses_remaining: "3",
                       tub_clean_count: "45", buzzer: "very_loud", lid_lock: "true" });
}

// reports the real end-of-cycle transition
fn test_the_end_of_a_cycle() {
    let d = device();
    d.feed(end_());
    expect_props(d, #{ power: "true", status: "end", remaining_time: "1", energy: "85",
                       rinses_remaining: "0", lid_lock: "true" });
}

// tracks the lid unlocking while the washer remains in End
fn test_the_lid_unlocks_at_the_end() {
    let d = device();
    d.feed(end_unlocked());
    expect_props(d, #{ status: "end", lid_lock: "false" });
}

// reports off and clears the stale remaining minute
fn test_off_clears_the_stale_minute() {
    let d = device();
    d.feed(off_());
    expect_props(d, #{ power: "false", status: "off", remaining_time: "0", initial_time: "0",
                       energy: "85", lid_lock: "false" });
}

// decodes the single-record snapshot sent after power-off
fn test_the_single_record_snapshot_after_power_off() {
    let d = device();
    d.feed(off_snapshot());
    expect_props(d, #{ power: "false", status: "off", remaining_time: "0", initial_time: "0",
                       energy: "85", lid_lock: "false" });
}

// rejects frames whose declared record length does not match this model
fn test_a_record_length_this_model_does_not_use_is_ignored() {
    let d = device();
    let text = running_87_to_86();
    text.replace(" ", "");
    let frame = hex_decode(text);
    frame[13] = 0;
    frame[14] = 99;
    d.feed(frame);
    expect_eq(d.property("power"), ());
    expect_eq(d.property("available"), ());
}

// (beyond upstream's tests) start() asks for the status
fn test_start_asks_for_the_status() {
    let d = device();
    d.start();
    expect_eq(aabb_unwrap(d.sent()[0]), hex_decode("F0ED112101000000180411120000"));
}

fn test_every_property_is_read_only() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("power", "false");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "reject");
}
