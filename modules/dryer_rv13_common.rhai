// The LG US electric dryers RV13B6BSD_D_US_WIFI, RV13B6ES_D_US_WIFI and RV13U6AM8W_D_US_WIFI:
// `import "dryer_rv13_common" as w;`. They share a status block, as upstream rethink's drivers for
// them (commit 0e57069) do, and differ in tables and bits, so each driver keeps its own hooks.
//
// Status is a 0x30 EB frame of one 29-byte block or EC of two (previous, current). A block is one
// leading byte and a 28-byte record, which on BSD and ES starts with a 0x1b marker. Record offsets
// (block offset - 1):
//   1 phase (0 off)   2/3 remaining time (h, min)   4/5 initial estimate (h, min), pinned while
//   running   6 course   8 dry level   9 temperature
// Dry level 0 is a course that does not sense dryness, temperature 0 one without heat: "none".
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn block(data) {
    let b = c::inner(data, 0x30);
    if b == () { return (); }
    let o = c::common_status_offset(b, 29);
    if o == () { () } else { b.extract(o, 29) }
}

// The record of BSD and ES (after the block's leading byte), or ().
fn record(data) {
    let b = block(data);
    if b == () || b[1] != 0x1b { () } else { b.extract(1, 28) }
}

fn dry_levels() { #{ "0": "none", "1": "damp", "2": "less", "3": "normal", "4": "more", "5": "very" } }
fn temps() { #{ "0": "none", "1": "ultra_low", "2": "low", "3": "medium", "4": "mid_high", "5": "high" } }

fn descriptor(ctx, props) {
    json_stringify(#{ il: 0, kind: "dryer", label: "Dryer", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

// ---- BSD and ES ---------------------------------------------------------------------
//   15 options (0x01 child lock, 0x02 reduce static, 0x08 damp dry signal)
//   16 options (0x02 energy saver, 0x04 turbo steam)

fn statuses() { #{ "0": "off", "1": "initial", "3": "paused", "50": "drying", "51": "cooling", "4": "end" } }

// An unmapped phase reads as "running", as upstream's.
fn status_options() { let o = t::options(statuses()); o.push("running"); o }

fn props(courses) {
    #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", class: "running", label: "Powered on" },
        status: #{ type: "select", options: status_options() },
        course: #{ type: "select", options: t::options(courses) },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        initial_time: #{ type: "number", class: "duration", unit: "min", category: "diagnostic", label: "Initial time estimate" },
        dry_level: #{ type: "select", options: t::options(dry_levels()) },
        temp: #{ type: "select", label: "Temperature", options: t::options(temps()) },
        child_lock: #{ type: "binary", category: "diagnostic" },
        reduce_static: #{ type: "binary" },
        damp_dry_signal: #{ type: "binary" },
        energy_saver: #{ type: "binary" },
        turbo_steam: #{ type: "binary" },
        wrinkle_care: #{ type: "binary" }
    }
}

fn publish(ctx, r, courses) {
    let off = r[1] == 0;
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if off { "false" } else { "true" });
    il::publish_property(ctx, "status", t::name(statuses(), r[1]) ?? "running");
    c::pub_name(ctx, "course", t::name(courses, r[6]));
    il::publish_property(ctx, "remaining_time", if off { "0" } else { (r[2] * 60 + r[3]).to_string() });
    il::publish_property(ctx, "initial_time", if off { "0" } else { (r[4] * 60 + r[5]).to_string() });
    c::pub_name(ctx, "dry_level", t::name(dry_levels(), r[8]));
    c::pub_name(ctx, "temp", t::name(temps(), r[9]));
    il::publish_property(ctx, "child_lock", c::bit(r[15], 0x01));
    il::publish_property(ctx, "reduce_static", c::bit(r[15], 0x02));
    il::publish_property(ctx, "damp_dry_signal", c::bit(r[15], 0x08));
    il::publish_property(ctx, "energy_saver", c::bit(r[16], 0x02));
    il::publish_property(ctx, "turbo_steam", c::bit(r[16], 0x04));
}

fn status_query(ctx) { ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x11, 0x21, 0x01, 0x00, 0x00, 0x00, 0x18, 0x00])); }
