// LG electric dryer RV13U6AM8W_D_US_WIFI (DLE7300WE), read only: dryer_rv13_common's block, as
// upstream rethink's RV13U6AM8W_D_US_WIFI.ts (commit 0e57069). Block offsets: 2 phase, 4 remaining
// minutes (read 0 at Off and Finishing, which keep a stale minute), 7 cycle, 9 dry level,
// 10 temperature, 17 bit 0x01 the drum turning. The cycle, dry level and temperature read "none"
// while off. The dryer repeats unacked frames and drops connections, so it gets the cloud's acks;
// it sends nothing but identity and heartbeats until start() asks for the status.
import "dryer_rv13_common" as w;
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn statuses() { #{ "0": "off", "1": "starting", "3": "paused", "50": "drying", "51": "cooldown", "4": "finishing" } }

fn cycles() {
    #{ "0": "none", "1": "heavy_duty", "3": "normal", "4": "perm_press", "5": "delicates", "7": "bedding",
       "16": "speed_dry", "17": "air_dry", "18": "manual" }
}

fn descriptor(ctx) {
    w::descriptor(ctx, #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", class: "running", label: "Powered on" },
        status: #{ type: "select", options: t::options(statuses()) },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        drum_running: #{ type: "binary", class: "running" },
        cycle: #{ type: "select", options: t::options(cycles()) },
        temp: #{ type: "select", label: "Temperature", options: t::options(w::temps()) },
        dry_level: #{ type: "select", options: t::options(w::dry_levels()) }
    })
}

fn start(ctx) { w::status_query(ctx); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let b = w::block(data);
    if b == () { return; }
    let phase = b[2];
    il::publish_property(ctx, "available", "true");
    c::pub_name(ctx, "status", t::name(statuses(), phase));
    il::publish_property(ctx, "remaining_time", if phase == 0 || phase == 4 { "0" } else { b[4].to_string() });
    il::publish_property(ctx, "power", if phase != 0 { "true" } else { "false" });
    il::publish_property(ctx, "drum_running", c::bit(b[17], 0x01));
    c::pub_name(ctx, "cycle", t::name(cycles(), b[7]));
    c::pub_name(ctx, "temp", t::name(w::temps(), b[10]));
    c::pub_name(ctx, "dry_level", t::name(w::dry_levels(), b[9]));
}

fn on_set_property(ctx, prop, value) {
    il::validate(ctx, prop, value); // every property is read only: il_common publishes the reject
}
