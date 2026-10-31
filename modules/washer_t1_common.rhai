// The LG ThinQ1 front-load washers (WTDN3, WTWN3). Port of upstream rethink's WTDN3.ts and
// WTWN3.ts (commit 2d8eaba). A driver inherits all of this with `import "washer_t1_common";`
// and overrides `features()` (and `courses()`) where its model differs; WTDN3 is the default.
//
// ThinQ1 status arrives as the base64 `Data` of each push the appliance sends after Mon/Start,
// which the host decodes for on_data: a 28-byte record (anszom/rethink#16; WTWN3 offsets from
// LG's modelJson):
//   0 state      1/2 remaining, 3/4 initial time (h, min)   5 course   6 error   7 soil (wash)
//   8 spin       9 temperature   10 rinse   11 drying mode   12/13 delay start (h, min)
//   14 options (0x01 TurboWash, 0x02 crease care, 0x10 medic rinse, 0x40 pre-wash, 0x80 steam)
//   15 locks (0x02 remote start, 0x40 door, 0x80 child lock)   20 downloaded course, which
//   overrides byte 5 when set   21 washes since the last tub clean   27 standby
// Commands are ThinQ1 JSON: Control/Power On|Off and Control/Operation Start|Stop.
import "washer_common" as w;
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

// What the model reports beyond the common fields. Override in the model's driver.
fn features() { ["drying_mode"] }

// 5 is pre-wash and 19 (AUTO_DT_OPEN_PAUSE) paused on these models.
fn states() {
    let s = w::base_states();
    s["5"] = "pre_wash";
    s["19"] = "paused";
    s
}

// Base and downloaded courses share one label space on these models.
fn courses() { w::courses() }

fn options() { #{ turbo_wash: 0x01, crease_care: 0x02, medic_rinse: 0x10, pre_wash: 0x40, steam: 0x80 } }

fn descriptor(ctx) {
    let f = features();
    let props = #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", rw: true, class: "running", label: "Powered on" },
        start: #{ type: "trigger" },
        pause: #{ type: "trigger" },
        status: #{ type: "select", options: t::options(states()) },
        error: #{ type: "binary", class: "problem", category: "diagnostic" },
        error_message: #{ type: "text", category: "diagnostic" },
        course: #{ type: "select", options: t::options(courses()) },
        spin: #{ type: "select", options: t::options(w::spins()) },
        temp: #{ type: "select", label: "Water temperature", options: t::options(w::temps()) },
        tub_clean_count: #{ type: "number", category: "diagnostic", label: "Washes since tub clean" },
        remote_start: #{ type: "binary", category: "diagnostic", label: "Remote start armed at the panel" },
        door_lock: #{ type: "binary", category: "diagnostic" },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle length" },
        remaining_time: #{ type: "number", class: "duration", unit: "min" }
    };
    if f.contains("drying_mode") {
        props.drying_mode = #{ type: "select", options: t::options(w::drying_modes()) };
    }
    if f.contains("soil") {
        props.soil = #{ type: "select", label: "Soil level", options: t::options(w::soil_levels()) };
    }
    if f.contains("rinse") { props.rinse = #{ type: "select", options: t::options(w::rinses()) }; }
    if f.contains("reserve_time") {
        props.reserve_time = #{ type: "number", class: "duration", unit: "min", label: "Delay start" };
    }
    if f.contains("options") { for o in options().keys() { props[o] = #{ type: "binary" }; } }
    if f.contains("child_lock") { props.child_lock = #{ type: "binary", category: "diagnostic" }; }
    if f.contains("standby") { props.standby = #{ type: "binary", category: "diagnostic" }; }
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

// The appliance pushes status only after Mon/Start, as when the LG app opens the device.
fn start(ctx) { ctx.send_json(json_stringify(#{ Cmd: "Mon", CmdOpt: "Start" })); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, b) {
    if b.len() != 28 { return; }
    let f = features();
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if b[0] > 0 { "true" } else { "false" });
    c::pub_name(ctx, "status", t::name(states(), b[0]));
    il::publish_property(ctx, "error", if b[6] != 0 { "true" } else { "false" });
    il::publish_property(ctx, "error_message", t::name(w::errors(), b[6]) ?? "Unknown error (" + b[6] + ")");
    c::pub_name(ctx, "course", t::name(courses(), b[20]) ?? t::name(courses(), b[5]));
    c::pub_name(ctx, "spin", t::name(w::spins(), b[8]));
    c::pub_name(ctx, "temp", t::name(w::temps(), b[9]));
    il::publish_property(ctx, "tub_clean_count", b[21].to_string());
    il::publish_property(ctx, "remote_start", c::bit(b[15], 0x02));
    il::publish_property(ctx, "door_lock", c::bit(b[15], 0x40));
    il::publish_property(ctx, "initial_time", (b[3] * 60 + b[4]).to_string());
    il::publish_property(ctx, "remaining_time", (b[1] * 60 + b[2]).to_string());

    if f.contains("drying_mode") { c::pub_name(ctx, "drying_mode", t::name(w::drying_modes(), b[11])); }
    if f.contains("soil") { c::pub_name(ctx, "soil", t::name(w::soil_levels(), b[7])); }
    if f.contains("rinse") { c::pub_name(ctx, "rinse", t::name(w::rinses(), b[10])); }
    if f.contains("reserve_time") { il::publish_property(ctx, "reserve_time", (b[12] * 60 + b[13]).to_string()); }
    if f.contains("options") { for o in options().keys() { il::publish_property(ctx, o, c::bit(b[14], options()[o])); } }
    if f.contains("child_lock") { il::publish_property(ctx, "child_lock", c::bit(b[15], 0x80)); }
    if f.contains("standby") { il::publish_property(ctx, "standby", if b[27] != 0 { "true" } else { "false" }); }
}

fn control(ctx, option, value) {
    ctx.send_json(json_stringify(#{ Cmd: "Control", CmdOpt: option, Value: value, Format: "B64", Data: "" }));
}

// Start carries no programme: upstream sends the button's empty payload as Data.
fn set_property(ctx, prop, value) {
    switch prop {
        "power" => control(ctx, "Power", if c::to_bool(value) { "On" } else { "Off" }),
        "pause" => control(ctx, "Operation", "Stop"),
        "start" => control(ctx, "Operation", "Start"),
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
