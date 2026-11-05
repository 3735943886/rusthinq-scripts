// LG dishwasher D121110: device -> IL driver. Port of the owner's rethink
// TypeScript driver (dishwasher_d121110.ts), verified against this unit's own
// captures (2026-11-04). An AABB appliance (class 0x32); it broadcasts status on
// its own, so `start` sends nothing (the sibling drivers disagree on the query
// frame and neither was captured against this model - the TS driver's reasoning).
//   0xEB  one status record, 0xEC two (previous, then current). Each record is
//         26 bytes: a [flag][0x18] prefix (the flag is uncorrelated noise and is
//         ignored) plus the 24-byte body below. Exact record counts are enforced.
//   Body: [0] state, [1] process, [3..4] initial time H/M, [5] course,
//         [7..8] remaining H/M, [9..10] reserved (delay start) H/M,
//         [11] flags1 (0x01 child lock, 0x02 door open, 0x04 rinse refill,
//         0x08 salt refill), [12] options (0x04 extra dry, 0x08 high temp - the
//         only two bits both sibling implementations agree on), [13] rinse level,
//         [14] softening level. A record whose time fields are implausible
//         (minutes > 59 or hours > 99) is dropped, the sibling handlers' rule.
// Provenance (kept from the TS driver): the envelope, state byte, door bit and the
// two times are verified on this unit; the remaining offsets and the state/process
// names follow the dishwasher family's common skeleton (anszom's decode, measured
// on D0211/N17); the course table is this model's own modelJSON ConvertingRule.
// Course and the two option bits hold a selection only while a cycle runs, so they
// are gated on state == Running (2) exactly as the TS driver gates them; the power
// read-back keys on the state byte (0 and 4 are this unit's captured off values,
// anything else is on - kshexe's H01 rule).
// The only write is power: F0 26 16 on / F0 26 12 off (cross-confirmed by kshexe's
// H01 and anszom's N17). Like the TS driver (the H01 pattern) the switch publishes
// optimistically and the next status record corrects it - a deliberate divergence
// from this repository's "never publish from a write" convention, kept because the
// TS control surface was verified live that way. Course start and settings writes
// exist in sibling drivers but were never captured for this model: not implemented.
// child_lock publishes the lock bit directly (true = locked), following this
// repository's IL convention (cf. washtower_kr_common); the TS driver's HA topic
// inverts it because HA's lock binary_sensor reads ON as unlocked.

import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn states() {
    #{ "0": "Off", "1": "Ready", "2": "Running", "3": "Pause", "4": "Standby", "5": "End" }
}
fn processes() {
    #{ "0": "Idle", "1": "Delayed Start", "2": "Washing", "3": "Rinsing", "4": "Drying",
       "5": "End", "6": "Night Dry", "99": "Cancel" }
}
fn courses() {
    #{ "0": "NONE", "1": "AUTO", "2": "HEAVY-INTENSIVE", "3": "DELICATE", "4": "TURBO",
       "5": "NORMAL-ECO", "6": "RINSE", "7": "REFRESH", "8": "EXPRESS",
       "9": "MACHINE_CLEAN", "10": "SHORT_MODE", "11": "DOWNLOAD_CYCLE" }
}

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", rw: true, label: "Power" },
        status: #{ type: "select", options: t::options(states()), label: "Status" },
        process: #{ type: "select", options: t::options(processes()), label: "Process" },
        course: #{ type: "select", options: t::options(courses()), label: "Course" },
        remaining_time: #{ type: "number", class: "duration", unit: "min", label: "Remaining time" },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Initial time" },
        delay_start_time: #{ type: "number", class: "duration", unit: "min", label: "Delay start time" },
        door: #{ type: "binary", class: "door", label: "Door" },
        child_lock: #{ type: "binary", label: "Child lock" },
        rinse_refill: #{ type: "binary", label: "Rinse refill" },
        salt_refill: #{ type: "binary", label: "Salt refill" },
        extra_dry: #{ type: "binary", label: "Extra dry" },
        high_temp: #{ type: "binary", label: "High temp" },
        rinse_level: #{ type: "number", label: "Rinse level" },
        softening_level: #{ type: "number", label: "Softening level" }
    };
    json_stringify(#{ il: 0, kind: "dishwasher", label: "Dishwasher", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn start(ctx) {}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let inner = c::inner(data, 0x32);
    if inner == () { return; }
    if inner[1] != 0xeb && inner[1] != 0xec { return; }
    // Exact lengths, like the sibling handlers insist on.
    if (inner.len() - 2) % 26 != 0 { return; }
    let count = (inner.len() - 2) / 26;
    let expected = if inner[1] == 0xeb { 1 } else { 2 };
    if count != expected { return; }
    // Previous record first, current last, so the current one stays published.
    for i in 0..count {
        record(ctx, inner.extract(2 + i * 26, 26));
    }
}

// Selects may only publish listed options (il V-3): an undecoded code
// clears the value instead of publishing the TS driver's `Unknown (n)`
// fallback string.
fn publish_enum(ctx, prop, table, raw) {
    let name = t::name(table, raw);
    if name == () { il::publish_absent(ctx, prop); } else { il::publish_property(ctx, prop, name); }
}

fn record(ctx, r) {
    if r[1] != 0x18 { return; }
    let b = r.extract(2);
    // Sanity: minutes must be 0..59, hours plausible, or the record is dropped.
    if b[4] > 59 || b[8] > 59 || b[10] > 59 || b[3] > 99 || b[7] > 99 || b[9] > 99 { return; }
    let state = b[0];
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "initial_time", (b[3] * 60 + b[4]).to_string());
    il::publish_property(ctx, "remaining_time", (b[7] * 60 + b[8]).to_string());
    il::publish_property(ctx, "delay_start_time", (b[9] * 60 + b[10]).to_string());
    publish_enum(ctx, "status", states(), state);
    publish_enum(ctx, "process", processes(), b[1]);
    il::publish_property(ctx, "power", if state != 0 && state != 4 { "true" } else { "false" });
    let running = state == 2;
    if running { publish_enum(ctx, "course", courses(), b[5]); } else { il::publish_property(ctx, "course", "NONE"); }
    il::publish_property(ctx, "extra_dry", if running { c::bit(b[12], 0x04) } else { "false" });
    il::publish_property(ctx, "high_temp", if running { c::bit(b[12], 0x08) } else { "false" });
    il::publish_property(ctx, "child_lock", c::bit(b[11], 0x01));
    il::publish_property(ctx, "door", c::bit(b[11], 0x02));
    il::publish_property(ctx, "rinse_refill", c::bit(b[11], 0x04));
    il::publish_property(ctx, "salt_refill", c::bit(b[11], 0x08));
    il::publish_property(ctx, "rinse_level", b[13].to_string());
    il::publish_property(ctx, "softening_level", b[14].to_string());
}

fn set_property(ctx, prop, value) {
    switch prop {
        "power" => {
            let on = c::to_bool(value);
            ctx.send_raw(aabb_wrap([0xf0, 0x26, if on { 0x16 } else { 0x12 }]));
            // Optimistic (the H01 pattern, kept from the TS driver); the next
            // status record's state byte corrects it if the appliance disagreed.
            il::publish_property(ctx, "power", value);
        }
        _ => { c::reject(ctx, prop, "unknown or read-only property"); }
    }
}

fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
