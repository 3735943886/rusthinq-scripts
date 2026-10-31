// LG front-load washer F3L2CYU__, read only: washer_f3l_common, as upstream rethink's F3L2CYU__.ts
// (commit 0e57069), whose offsets were live-verified against the LG cloud's decoded state. Beyond
// the shared fields: TurboWash (record 15 bit 0x80) and the door, closed when record 17 is 0x02.
// Remaining time is the estimate while selecting and the countdown while running; this model has
// no separate initial time. It volunteers status frames; upstream sends no status query.
import "washer_f3l_common" as w;
import "aabb_common" as c;
import "il_common" as il;

// From the model JSON and the LG app: 83, 84 and 85 are FROZEN_PREVENT_INITIAL, _RUNNING and
// _PAUSE, 7 is ERROR_AUTO_OFF. 65 (audible diagnosis) and 81 (tub clean count alarm) are left
// out, as the LG app does not label them.
fn statuses() {
    #{ "0": "off", "5": "standby", "83": "standby", "6": "paused", "85": "paused", "10": "delayed",
       "20": "detecting", "7": "error", "21": "filling", "22": "detergent_amount", "23": "washing",
       "84": "washing", "24": "pre_wash", "30": "rinsing", "31": "rinse_hold", "40": "spinning",
       "50": "drying", "60": "end", "61": "refreshing", "79": "smart_diagnosis" }
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
