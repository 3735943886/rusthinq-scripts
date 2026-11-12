import "aabb_test" as a;
import "runtime_test" as runtime;

// Tests of ML32PWFOTA.rhai (lightwave oven). Vectors from SdrgonLee/rethink
// (https://github.com/SdrgonLee/rethink) tests/cloud/devices/ML32PWFOTA.test.ts at 491b177,
// upstream test names kept in the comments. The 10 s microwave frame is a real capture; the
// other records are built as that test builds them (state, program, sub id, h, m, s, temperature).

fn rec(s, id, sub, h, m, sec, temp) {
    let r = blob(28);
    r[0] = s; r[1] = id; r[2] = sub; r[3] = h; r[4] = m; r[5] = sec; r[6] = temp;
    r
}
fn st(s) { rec(s, 0, 0, 0, 0, 0, 0) }

// EC: previous record, then the current one.
fn ec(current, previous) {
    let inner = a::bytes([0x40, 0xec]);
    inner += previous;
    inner += current;
    a::framed(inner)
}
fn eb(current) {
    let inner = a::bytes([0x40, 0xeb]);
    inner += current;
    a::framed(inner)
}

fn absent(d, props) {
    // never published, or cleared with an empty retained value
    for p in props { let v = d.property(p); expect(v == () || v == "", p + " is absent"); }
}

// "queries status immediately and every 30 seconds until dropped"
fn test_queries_status_on_start_and_every_30_seconds() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 1);
    expect_eq(hex_encode_upper(d.sent()[0]), "AA08F0EF004682BB");
    expect(d.timers().contains(["status_query", 30000]), "the query timer is armed");
    d.fire("status_query");
    expect_eq(d.sent().len(), 2);
    expect_eq(hex_encode_upper(d.sent()[1]), "AA08F0EF004682BB");
    expect(d.timers().contains(["status_query", 30000]), "the query timer is re-armed");
    expect_eq(d.script_error(), ());
}

fn test_descriptor() {
    let d = device();
    d.start();
    let desc = runtime::descriptor(d);
    expect_eq(desc.kind, "oven");
    expect_eq(desc.props.remaining_time.unit, "s");
    expect_eq(desc.props.target_temperature.class, "temperature");
    expect(desc.props.program.options.contains("steam_clean"), "cleaning functions are programs");
    expect(desc.props.program.options.contains("my_recipe"), "my recipe is a program");
}

// "decodes the captured 10-second microwave cycle start"
fn test_the_captured_microwave_start() {
    let d = device();
    d.feed("AA3E40EC0701000000000000000000000000000000000000000000000000000002010000000A000000000000000000000000000000000000000000007CBB");
    expect_props(d, #{ available: "true", oven_state: "cooking", program: "microwave",
                       remaining_time: "10", total_time: "10" });
    absent(d, ["target_temperature"]);
    expect_eq(d.script_error(), ());
}

// "uses English entity and state names outside Korea" (the oven case)
fn test_cooking_in_oven_mode() {
    let d = device();
    d.feed(ec(rec(2, 4, 0, 0, 2, 0, 180), st(7)));
    expect_props(d, #{ oven_state: "cooking", program: "oven", target_temperature: "180",
                       remaining_time: "120", total_time: "120" });
}

// "decodes oven preheating without exposing its untrustworthy time as remaining or total"
fn test_preheating_hides_its_time() {
    let d = device();
    d.feed(ec(rec(1, 4, 0, 0, 30, 0, 180), rec(7, 4, 0, 0, 0, 0, 180)));
    expect_props(d, #{ oven_state: "preheating", program: "oven", target_temperature: "180" });
    absent(d, ["remaining_time", "total_time"]);
}

// "keeps a latched total through pause and resume, then clears the cycle on cancellation"
fn test_total_is_latched_through_pause_and_cleared_on_cancel() {
    let d = device();
    d.feed(ec(rec(2, 4, 0, 0, 2, 0, 180), rec(7, 4, 0, 0, 0, 0, 0)));
    d.feed(ec(rec(4, 4, 0, 0, 1, 34, 180), rec(2, 4, 0, 0, 0, 0, 0)));
    expect_props(d, #{ oven_state: "paused", total_time: "120", remaining_time: "94" });
    d.feed(ec(rec(2, 4, 0, 0, 1, 33, 180), rec(4, 4, 0, 0, 0, 0, 0)));
    expect_props(d, #{ oven_state: "cooking", total_time: "120", remaining_time: "93" });
    d.feed(ec(st(0), rec(4, 4, 0, 0, 1, 12, 180)));
    expect_props(d, #{ oven_state: "initial" });
    absent(d, ["program", "remaining_time", "target_temperature", "total_time"]);
}

// "decodes captured cleaning contexts and preserves them while paused"
fn test_cleaning_contexts_survive_a_pause() {
    for x in [[0x02, "steam_clean", 900], [0x03, "cavity_dry", 720]] {
        let d = device();
        let m = x[2] / 60;
        d.feed(ec(rec(3, 0x12, x[0], 0, m, 0, 0), st(7)));
        expect_props(d, #{ oven_state: "cleaning", program: x[1], total_time: x[2].to_string() });
        d.feed(ec(rec(4, 0x12, x[0], 0, m - 1, 33, 0), rec(3, 0x12, x[0], 0, 0, 0, 0)));
        expect_props(d, #{ oven_state: "paused", program: x[1], total_time: x[2].to_string() });
    }
}

// "maps externally documented programs only in active program contexts"
fn test_programs_only_in_active_states() {
    for x in [[0x02, "steam_microwave"], [0x03, "grill"], [0x06, "steam"], [0x07, "dehydrate"],
              [0x15, "ferment"], [0x16, "steam_ferment"]] {
        let d = device();
        d.feed(ec(rec(2, x[0], 0, 0, 1, 0, 0), st(7)));
        expect_props(d, #{ program: x[1] });
    }
    let d = device();
    d.feed(ec(rec(7, 0x15, 0, 0, 1, 0, 0), st(0)));
    absent(d, ["program"]);
    d.feed(ec(rec(2, 0x13, 0, 0, 1, 0, 180), rec(7, 0x13, 0, 0, 0, 0, 0)));
    expect_props(d, #{ program: "my_recipe", target_temperature: "180" });
}

// "maps externally documented cleaning functions only under the cleaning marker"
fn test_cleaning_functions() {
    for x in [[0x01, "steam_deodorize"], [0x04, "drain_residual_water"], [0x05, "steam_generator_clean"]] {
        let d = device();
        d.feed(ec(rec(3, 0x12, x[0], 0, 1, 0, 0), st(7)));
        expect_props(d, #{ program: x[1] });
    }
}

// "clears stale values in setting and complete states"
fn test_preference_and_done_clear_stale_values() {
    let d = device();
    d.feed(ec(rec(2, 4, 0, 0, 2, 0, 180), st(7)));
    d.feed(ec(rec(7, 0x13, 0, 0, 1, 12, 180), st(0)));
    expect_props(d, #{ oven_state: "preference" });
    absent(d, ["program", "remaining_time", "target_temperature", "total_time"]);
    d.feed(ec(st(5), rec(2, 0, 0, 0, 0, 0, 180)));
    expect_props(d, #{ oven_state: "done" });
    absent(d, ["program", "remaining_time", "target_temperature", "total_time"]);
}

// "does not retain a temperature after the course context is cleared at the end of cooking"
fn test_no_temperature_without_a_program() {
    let d = device();
    d.feed(ec(rec(2, 4, 0, 0, 0, 20, 180), st(7)));
    d.feed(ec(rec(2, 0, 0, 0, 0, 0, 180), rec(2, 4, 0, 0, 0, 1, 180)));
    absent(d, ["program", "target_temperature"]);
    expect_props(d, #{ total_time: "20" });
}

// "does not use 4072 or 40BF as authoritative state"
fn test_other_0x40_frames_are_not_state() {
    let d = device();
    d.feed(ec(rec(2, 4, 0, 0, 0, 20, 180), st(7)));
    d.feed("AA13407200040A0000000000000000000028BB");
    d.feed(a::framed(a::bytes([0x40, 0xbf, 0x02, 0x00])));
    expect_props(d, #{ oven_state: "cooking", program: "oven", remaining_time: "20", total_time: "20" });
    expect_eq(d.script_error(), ());
}

// "does not mistake a reconnect snapshot for the total cycle time"
fn test_an_eb_snapshot_is_not_a_total() {
    let d = device();
    d.feed(eb(rec(2, 4, 0, 0, 8, 30, 220)));
    expect_props(d, #{ oven_state: "cooking", program: "oven", remaining_time: "510", target_temperature: "220" });
    absent(d, ["total_time"]);
}

// "leaves contradictory and unknown contexts unknown"
fn test_unknown_codes_are_absent() {
    let d = device();
    d.feed(ec(rec(3, 4, 0, 0, 12, 0, 0), st(7)));
    expect_props(d, #{ oven_state: "cleaning" });
    absent(d, ["program"]);
    d.feed(ec(rec(0x99, 4, 0, 0, 1, 0, 180), rec(3, 4, 0, 0, 0, 0, 0)));
    absent(d, ["oven_state", "program", "remaining_time", "target_temperature", "total_time"]);
    d.feed(ec(rec(2, 0x99, 0, 0, 1, 0, 180), st(7)));
    absent(d, ["program", "target_temperature"]);
    d.feed(ec(rec(3, 0x12, 0x99, 0, 1, 0, 0), st(7)));
    absent(d, ["program"]);
    expect_eq(d.script_error(), ());
}

fn test_reconnect_keeps_reported_values() {
    let d = device();
    d.start();
    d.feed(ec(rec(2, 4, 0, 0, 2, 0, 180), st(7)));
    d.drop_device();
    d.start();
    expect_props(d, #{ oven_state: "cooking", remaining_time: "120" });
    expect_eq(d.script_error(), ());
}

fn test_writes_are_rejected_and_nothing_is_sent() {
    let d = device();
    d.start();
    let n = d.sent().len();
    d.set("target_temperature", "200");
    expect_eq(d.sent().len(), n);
    expect(d.event("reject") != (), "a reject event is published");
    expect_eq(d.script_error(), ());
}
