// LG front-load washer F3L2CYU__, read only: washer_f3l_common, as upstream rethink's F3L2CYU__.ts
// (commit 0e57069), whose offsets were live-verified against the LG cloud's decoded state. Beyond
// the shared fields: TurboWash (record 15 bit 0x80) and the door, closed when record 17 is 0x02.
// Remaining time is the estimate while selecting and the countdown while running; this model has
// no separate initial time. It volunteers status frames; upstream sends no status query.
import "washer_f3l_common" as w;
import "aabb_common" as c;
import "il_common" as il;

fn statuses() {
    #{ "0": "off", "5": "selecting", "6": "paused", "10": "delay_wash", "20": "sensing",
       "23": "washing", "30": "rinsing", "40": "spinning", "60": "complete" }
}

fn courses() {
    #{ "0": "none", "254": "none", "1": "tub_clean", "2": "bright_whites", "3": "allergiene",
       "4": "sanitary", "5": "bedding", "6": "heavy_duty", "7": "normal", "8": "sportswear",
       "9": "perm_press", "10": "delicates", "11": "towels", "12": "speed_wash", "13": "rinse_spin",
       "14": "small_load" }
}

fn descriptor(ctx) {
    let props = w::props(statuses(), courses());
    props.turbo_wash = #{ type: "binary" };
    props.door = #{ type: "binary", class: "door", label: "Door open" };
    w::descriptor(ctx, props)
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let r = w::record(data);
    if r == () { return; }
    w::publish(ctx, r, statuses(), courses(), r[1] == 0);
    il::publish_property(ctx, "turbo_wash", c::bit(r[15], 0x80));
    il::publish_property(ctx, "door", if r[17] == 0x02 { "false" } else { "true" });
}

fn on_set_property(ctx, prop, value) {
    il::validate(ctx, prop, value); // every property is read only: il_common publishes the reject
}
