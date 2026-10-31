// The LG US front-load washers F3L2CYU__ and F3L7CYK5W_US_WIFI: `import "washer_f3l_common" as w;`.
// They share a record layout and the soil, spin and temperature tables, as upstream rethink's
// drivers for them (commit 0e57069) do, but differ in their course and status tables and in
// several bits, so each driver keeps its own hooks.
//
// Status is a 0x20 EB frame of one 26-byte block or EC of two (previous, current); a block is one
// leading byte and a 25-byte record that starts with a 0x18 marker. Record offsets:
//   1 phase (0 off)   2/3 remaining time (h, min)   6 course   8 soil   9 spin   10 temperature
//   11 extra rinses (high nibble)   13/14 delay wash time left (h, min)
//   15 options (0x02 delay wash, 0x04 steam, 0x08 pre-wash, 0x40 extra rinse)
//   16 options (0x10 cold wash, 0x80 door locked)
// Index 0 of soil, spin and temperature means the setting does not apply (it drops to 0 once it
// stops applying); course 0 and 0xFE are no selection.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn record(data) {
    let b = c::inner(data, 0x20);
    if b == () { return (); }
    let o = c::common_status_offset(b, 26);
    if o == () || b[o + 1] != 0x18 { return (); }
    b.extract(o + 1, 25)
}

fn soils() { #{ "0": "none", "1": "light", "2": "light_normal", "3": "normal", "4": "normal_heavy", "5": "heavy" } }
fn spins() { #{ "0": "none", "1": "no_spin", "2": "low", "3": "medium", "4": "high", "5": "extra_high" } }
fn temps() { #{ "0": "none", "1": "tap_cold", "2": "cold", "4": "warm", "6": "hot", "7": "extra_hot" } }

fn props(statuses, courses) {
    #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", class: "running", label: "Powered on" },
        status: #{ type: "select", options: t::options(statuses) },
        course: #{ type: "select", options: t::options(courses) },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        reserve_time: #{ type: "number", class: "duration", unit: "min", label: "Delay wash time left" },
        soil: #{ type: "select", label: "Soil level", options: t::options(soils()) },
        spin: #{ type: "select", options: t::options(spins()) },
        temp: #{ type: "select", label: "Water temperature", options: t::options(temps()) },
        extra_rinse: #{ type: "binary" },
        extra_rinse_count: #{ type: "number", series: "gauge" },
        pre_wash: #{ type: "binary" },
        steam: #{ type: "binary" },
        cold_wash: #{ type: "binary" },
        delay_wash: #{ type: "binary" },
        door_lock: #{ type: "binary", category: "diagnostic" }
    }
}

fn descriptor(ctx, props) {
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

// The fields both models report. The times read 0 while `idle` (the record parks on a stale minute).
fn publish(ctx, r, statuses, courses, idle) {
    let off = r[1] == 0;
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if off { "false" } else { "true" });
    c::pub_name(ctx, "status", t::name(statuses, r[1]));
    c::pub_name(ctx, "course", t::name(courses, r[6]));
    il::publish_property(ctx, "remaining_time", if idle { "0" } else { (r[2] * 60 + r[3]).to_string() });
    il::publish_property(ctx, "reserve_time", if off { "0" } else { (r[13] * 60 + r[14]).to_string() });
    c::pub_name(ctx, "soil", t::name(soils(), r[8]));
    c::pub_name(ctx, "spin", t::name(spins(), r[9]));
    c::pub_name(ctx, "temp", t::name(temps(), r[10]));
    il::publish_property(ctx, "extra_rinse_count", (r[11] >> 4).to_string());
    il::publish_property(ctx, "extra_rinse", c::bit(r[15], 0x40));
    il::publish_property(ctx, "pre_wash", c::bit(r[15], 0x08));
    il::publish_property(ctx, "steam", c::bit(r[15], 0x04));
    il::publish_property(ctx, "delay_wash", c::bit(r[15], 0x02));
    il::publish_property(ctx, "cold_wash", c::bit(r[16], 0x10));
    il::publish_property(ctx, "door_lock", c::bit(r[16], 0x80));
}
