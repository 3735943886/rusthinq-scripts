// LG electric dryer RV13D5JSD_D_US (DLEX4200B): port of upstream rethink's RV13D5JSD_D_US.ts
// (commit 2d8eaba), mapped there from a full dial walk, isolated option toggles and two complete
// runs. dryer_rv13_common's record (0x1b marker), with its own phase and course tables; beyond the
// shared fields:
//   10 Time Dry setting (1..5 = 20..60 min, on the Time Dry course)   11 Signal beeper
//   12 More/Less Time trim (signed minutes)   15 0x10 Wrinkle Care   23 load items
// No child lock or remote start. An unknown phase clears the status, and the course is absent
// while off. The times read 0 off and once the cycle completes (End or the Wrinkle Care that
// follows it); completion stays latched through the automatic power off, until a new cycle.
// The dryer repeats unacked frames, so it gets the cloud's acks. The one write is power off
// (F0 24 01 01 00, captured from the ThinQ app), offered while powered on; start() asks for the
// status, which the dryer otherwise sends only on a change.
import "dryer_rv13_common" as w;
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn statuses() {
    #{ "0": "off", "1": "initial", "3": "paused", "4": "end", "50": "drying", "51": "cooling",
       "56": "wrinkle_care" }
}

fn courses() {
    #{ "1": "heavy_duty", "2": "towels", "3": "normal", "4": "perm_press", "5": "delicates",
       "7": "bedding", "8": "antibacterial", "9": "small_load", "11": "sportswear", "16": "speed_dry",
       "17": "air_dry", "18": "time_dry", "21": "steam_fresh", "22": "steam_sanitary" }
}

fn signals() { #{ "0": "off", "1": "low", "4": "high" } }

fn descriptor(ctx) {
    w::descriptor(ctx, #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", class: "running", label: "Powered on" },
        power_off: #{ type: "trigger", requires: "power" },
        status: #{ type: "select", options: t::options(statuses()) },
        dry_completed: #{ type: "binary", label: "Dry completed" },
        course: #{ type: "select", options: t::options(courses()) },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        initial_time: #{ type: "number", class: "duration", unit: "min", category: "diagnostic", label: "Initial time estimate" },
        dry_level: #{ type: "select", options: t::options(w::dry_levels()) },
        temp: #{ type: "select", label: "Temperature", options: t::options(w::temps()) },
        time_dry_setting: #{ type: "number", class: "duration", unit: "min", category: "diagnostic", label: "Time Dry setting" },
        more_less_time: #{ type: "number", class: "duration", unit: "min", category: "diagnostic", label: "More/Less Time" },
        signal: #{ type: "select", category: "diagnostic", options: t::options(signals()) },
        reduce_static: #{ type: "binary" },
        damp_dry_signal: #{ type: "binary" },
        energy_saver: #{ type: "binary" },
        turbo_steam: #{ type: "binary" },
        wrinkle_care: #{ type: "binary" },
        load_item: #{ type: "number", series: "gauge" }
    })
}

fn start(ctx) { w::status_query(ctx); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let r = w::record(data);
    if r == () { return; }
    let off = r[1] == 0;
    let complete = r[1] == 4 || r[1] == 56;
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if off { "false" } else { "true" });
    let status = t::name(statuses(), r[1]);
    if status == () { il::publish_absent(ctx, "status"); } else { il::publish_property(ctx, "status", status); }
    let course = if off { () } else { t::name(courses(), r[6]) };
    if course == () { il::publish_absent(ctx, "course"); } else { il::publish_property(ctx, "course", course); }
    il::publish_property(ctx, "remaining_time", if off || complete { "0" } else { (r[2] * 60 + r[3]).to_string() });
    il::publish_property(ctx, "initial_time", if off || complete { "0" } else { (r[4] * 60 + r[5]).to_string() });
    c::pub_name(ctx, "dry_level", t::name(w::dry_levels(), r[8]));
    c::pub_name(ctx, "temp", t::name(w::temps(), r[9]));
    c::pub_name(ctx, "signal", t::name(signals(), r[11]));
    let trim = if r[12] >= 128 { r[12] - 256 } else { r[12] };
    il::publish_property(ctx, "more_less_time", if off { "0" } else { trim.to_string() });
    il::publish_property(ctx, "load_item", r[23].to_string());
    let time_dry = if r[6] == 18 && r[10] >= 1 && r[10] <= 5 { (r[10] + 1) * 10 } else { 0 };
    il::publish_property(ctx, "time_dry_setting", time_dry.to_string());
    il::publish_property(ctx, "reduce_static", c::bit(r[15], 0x02));
    il::publish_property(ctx, "damp_dry_signal", c::bit(r[15], 0x08));
    il::publish_property(ctx, "wrinkle_care", c::bit(r[15], 0x10));
    il::publish_property(ctx, "energy_saver", c::bit(r[16], 0x02));
    il::publish_property(ctx, "turbo_steam", c::bit(r[16], 0x04));
    if complete {
        il::publish_property(ctx, "dry_completed", "true");
        ctx.state_set("completion_known", true);
    } else if !off || ctx.state_get("completion_known") != true {
        il::publish_property(ctx, "dry_completed", "false");
        ctx.state_set("completion_known", true);
    }
}

fn set_property(ctx, prop, value) {
    if prop == "power_off" { ctx.send_raw(aabb_wrap([0xf0, 0x24, 0x01, 0x01, 0x00])); return; }
    c::reject(ctx, prop, "read-only property");
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
