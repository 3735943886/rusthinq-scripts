// LG front-load washer F3L7CYK5W_US_WIFI, read only: washer_f3l_common, as upstream rethink's
// F3L7CYK5W_US_WIFI.ts (commit 0e57069). Not an alias of F3L2CYU__: its course table differs at
// nine of twelve positions, and beyond the shared fields it reports the initial time (record 4/5,
// pinned once a cycle starts), the rinses left (record 11, low nibble), child lock (15 bit 0x01),
// Rinse+Spin (15 bit 0x20), the load level (24) and washes since the last tub clean (22). It has
// no TurboWash and reports no door position (record 17 is the cycle latch). Both times read 0 at
// Off and at Complete. 0xE2 frames replay a stale snapshot after a cycle and are not status.
// start() asks for the status, as the washer only volunteers it when something changes.
import "washer_f3l_common" as w;
import "aabb_common" as c;
import "il_common" as il;

fn statuses() {
    #{ "0": "off", "5": "initial", "6": "paused", "10": "delay_wash", "20": "sensing",
       "21": "add_garments", "23": "washing", "30": "rinsing", "40": "spinning", "60": "complete" }
}

fn courses() {
    #{ "0": "none", "254": "none", "1": "tub_clean", "2": "allergiene", "3": "sanitary",
       "4": "bedding", "5": "heavy_duty", "6": "normal", "7": "bright_whites", "8": "perm_press",
       "9": "delicates", "10": "towels", "11": "speed_wash", "12": "downloaded" }
}

fn descriptor(ctx) {
    let props = w::props(statuses(), courses());
    props.initial_time = #{ type: "number", class: "duration", unit: "min", label: "Cycle length" };
    props.rinse_count = #{ type: "number", series: "gauge", label: "Rinses remaining" };
    props.rinse_spin = #{ type: "binary", label: "Rinse + Spin" };
    props.child_lock = #{ type: "binary", label: "Control lock" };
    props.load_level = #{ type: "number", series: "gauge", category: "diagnostic" };
    props.tub_clean_count = #{ type: "number", category: "diagnostic", label: "Washes since tub clean" };
    w::descriptor(ctx, props)
}

fn start(ctx) { ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x11, 0x21, 0x01, 0x00, 0x00, 0x00, 0x18, 0x00])); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let r = w::record(data);
    if r == () { return; }
    let idle = r[1] == 0 || r[1] == 0x3c;
    w::publish(ctx, r, statuses(), courses(), idle);
    il::publish_property(ctx, "initial_time", if idle { "0" } else { (r[4] * 60 + r[5]).to_string() });
    il::publish_property(ctx, "rinse_count", (r[11] & 0x0f).to_string());
    il::publish_property(ctx, "child_lock", c::bit(r[15], 0x01));
    il::publish_property(ctx, "rinse_spin", c::bit(r[15], 0x20));
    il::publish_property(ctx, "load_level", r[24].to_string());
    il::publish_property(ctx, "tub_clean_count", r[22].to_string());
}

fn on_set_property(ctx, prop, value) {
    il::validate(ctx, prop, value); // every property is read only: il_common publishes the reject
}
