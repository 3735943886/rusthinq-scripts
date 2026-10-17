// LG electric dryer RV13B6ES_D_US_WIFI, read only: dryer_rv13_common, as upstream rethink's
// RV13B6ES_D_US_WIFI.ts (commit 0e57069). Not an alias of RV13B6BSD_D_US_WIFI: Wrinkle Care is
// record 15 bit 0x10 here, and beyond the shared fields it reports remote start (16 bit 0x01),
// the Signal beeper (11; mapped from the panel, the cloud has no field for it), the signed
// More/Less Time trim in minutes (12) and the load items (23). start() asks for the status.
import "dryer_rv13_common" as w;
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn courses() {
    #{ "0": "none", "1": "heavy_duty", "2": "towels", "3": "normal", "4": "perm_press", "5": "delicates",
       "7": "bedding", "8": "antibacterial", "16": "speed_dry", "17": "air_dry", "18": "time_dry",
       "21": "steam_fresh", "22": "steam_sanitary", "26": "super_dry" }
}

fn signals() { #{ "0": "off", "1": "low", "4": "high" } }

fn descriptor(ctx) {
    let props = w::props(courses());
    props.remote_start = #{ type: "binary", category: "diagnostic" };
    props.signal = #{ type: "select", category: "config", options: t::options(signals()) };
    props.more_less_time = #{ type: "number", class: "duration", unit: "min", label: "More/Less Time" };
    props.load_item = #{ type: "number", series: "gauge" };
    w::descriptor(ctx, props)
}

fn start(ctx) { w::status_query(ctx); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let r = w::record(data);
    if r == () { return; }
    w::publish(ctx, r, courses());
    il::publish_property(ctx, "wrinkle_care", c::bit(r[15], 0x10));
    il::publish_property(ctx, "remote_start", c::bit(r[16], 0x01));
    c::pub_name(ctx, "signal", t::name(signals(), r[11]));
    let trim = if r[12] >= 128 { r[12] - 256 } else { r[12] };
    il::publish_property(ctx, "more_less_time", if r[1] == 0 { "0" } else { trim.to_string() });
    il::publish_property(ctx, "load_item", r[23].to_string());
}

fn on_set_property(ctx, prop, value) {
    il::validate(ctx, prop, value); // every property is read only: il_common publishes the reject
}
