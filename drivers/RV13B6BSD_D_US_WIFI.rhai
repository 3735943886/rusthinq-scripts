// LG electric dryer RV13B6BSD_D_US_WIFI (DLEX3900B), read only: dryer_rv13_common, as upstream
// rethink's RV13B6BSD_D_US_WIFI.ts (commit 0e57069), whose offsets were live-verified against the
// LG cloud's decoded state. Wrinkle Care is record 16 bit 0x10 on this model. It volunteers status
// frames; upstream sends no status query.
import "dryer_rv13_common" as w;
import "aabb_common" as c;
import "il_common" as il;

fn courses() {
    #{ "0": "none", "1": "heavy_duty", "2": "towels", "3": "normal", "4": "perm_press", "5": "delicates",
       "7": "bedding", "8": "antibacterial", "9": "small_load", "11": "sportswear", "16": "speed_dry",
       "17": "air_dry", "18": "time_dry", "21": "steam_fresh", "22": "steam_sanitary", "26": "super_dry" }
}

fn descriptor(ctx) { w::descriptor(ctx, w::props(courses())) }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let r = w::record(data);
    if r == () { return; }
    w::publish(ctx, r, courses());
    il::publish_property(ctx, "wrinkle_care", c::bit(r[16], 0x10));
}

fn on_set_property(ctx, prop, value) {
    il::validate(ctx, prop, value); // every property is read only: il_common publishes the reject
}
