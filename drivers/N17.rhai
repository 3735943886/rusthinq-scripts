// LG dishwasher N17 (LDNPQ445S): device -> IL driver. Port of upstream rethink's driver (commit
// 0e57069), whose fields and commands were all confirmed on a live appliance. 31-byte records
// (a 0x1D payload); dishwasher_common decodes the shared fields, plus
//   11 flags1: 0x10 automatic selection, 0x20 tub clean reminder, 0x40 clean indicator light
//   12 options: 0x80 steam     15 flags2: 0x02 remote start armed, 0x80 chime sound
//   16 flags3: 0x04 end-of-cycle tone      20 downloaded cycle (smart()), overrides the course
//   21 0x40 status indicator light
// Settings are written as one snapshot of all of them, so a write waits for a status record:
// F0 26 <rinse> 00 <opts> 40 00 <light> 00 00, with the bits of settings().
// The start offers only the courses LG's cloud was seen starting on this appliance.
import "aabb_common" as c;
import "dishwasher_common" as w;
import "table_common" as t;
import "il_common" as il;

fn courses() {
    #{ "0": "off", "1": "auto", "2": "heavy", "4": "turbo", "5": "normal", "9": "machine_clean",
       "11": "download_cycle" }
}

fn smart() {
    #{ "1": "tub_clean", "2": "express", "3": "rinse", "4": "pots_and_pans", "5": "casseroles",
       "6": "glassware", "7": "night_care", "8": "delicate", "9": "refresh" }
}

fn start_courses() { ["auto", "heavy", "turbo", "normal", "download_cycle"] }

// Setting -> [record offset, record bit, snapshot bit]; the light has its own snapshot byte.
fn settings() {
    #{ chime_sound: [15, 0x80, 0x04], end_of_cycle_tone: [16, 0x04, 0x40],
       tub_clean_reminder: [11, 0x20, 0x01], clean_indicator_light: [11, 0x40, 0x08],
       automatic_selection: [11, 0x10, 0x20], status_indicator_light: [21, 0x40, 0] }
}

fn descriptor(ctx) {
    let props = w::props(t::options(courses()) + t::options(smart()));
    props += w::control_props(start_courses());
    props += #{
        power_off: #{ type: "trigger" },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle time" },
        delay_start_time: #{ type: "number", class: "duration", unit: "min", label: "Delayed start" },
        extra_dry: #{ type: "binary" },
        high_temp: #{ type: "binary" },
        steam: #{ type: "binary" },
        rinse_level: #{ type: "number", rw: true, min: 0, max: 4, step: 1, category: "config",
                        label: "Rinse aid level" },
        target_steam: #{ type: "binary", rw: true, label: "Start with steam" }
    };
    for k in settings().keys() { props[k] = #{ type: "binary", rw: true, category: "config" }; }
    json_stringify(#{ il: 0, kind: "washer", class: "dishwasher", label: "Dishwasher", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn start(ctx) {
    w::query(ctx);
    for pair in [["target_course", "auto"], ["target_high_temp", "false"], ["target_extra_dry", "false"],
              ["target_steam", "false"], ["target_delay", "0"]] {
        il::publish_property(ctx, pair[0], w::target(ctx, pair[0], pair[1]));
    }
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    if w::energy(ctx, data) { return; }
    let p = w::payload(data, 31, 0x1d);
    if p == () { return; }
    w::publish(ctx, p);
    let course = if p[20] != 0 { t::name(smart(), p[20]) } else { t::name(courses(), p[5]) };
    c::pub_name(ctx, "course", course);
    il::publish_property(ctx, "initial_time", w::minutes(p, 3).to_string());
    il::publish_property(ctx, "delay_start_time", w::minutes(p, 9).to_string());
    il::publish_property(ctx, "extra_dry", c::bit(p[12], 0x04));
    il::publish_property(ctx, "high_temp", c::bit(p[12], 0x08));
    il::publish_property(ctx, "steam", c::bit(p[12], 0x80));
    il::publish_property(ctx, "remote_start", c::bit(p[15], 0x02));
    let s = #{ rinse_level: p[13] };
    let t = settings();
    for k in t.keys() { s[k] = (p[t[k][0]] & t[k][1]) != 0; }
    ctx.state_set("settings", s);
    il::publish_property(ctx, "rinse_level", s.rinse_level.to_string());
    for k in t.keys() { il::publish_property(ctx, k, s[k].to_string()); }
}

fn write_settings(ctx, prop, value) {
    let s = ctx.state_get("settings");
    if s == () { return c::reject(ctx, prop, "settings not reported yet"); }
    s[prop] = value;
    ctx.state_set("settings", s);
    let opts = 0;
    let t = settings();
    for k in t.keys() { if s[k] { opts = opts | t[k][2]; } }
    w::command(ctx, [s.rinse_level, 0, opts, 0x40, 0, if s.status_indicator_light { 1 } else { 0 }, 0, 0]);
}

fn set_property(ctx, prop, value) {
    if w::control(ctx, prop) { return; }
    if settings().contains(prop) { return write_settings(ctx, prop, c::to_bool(value)); }
    switch prop {
        "rinse_level" => write_settings(ctx, prop, c::to_number(value).to_int()),
        "target_course" | "target_high_temp" | "target_extra_dry" | "target_steam" => w::set_target(ctx, prop, value),
        "target_delay" => w::set_target(ctx, prop, c::to_number(value).to_int().to_string()),
        "start_course" => {
            let opt3 = w::opt(ctx, "target_high_temp", 0x08) | w::opt(ctx, "target_extra_dry", 0x04)
                | w::opt(ctx, "target_steam", 0x80);
            w::start_course(ctx, t::code(courses(), w::target(ctx, "target_course", "auto")), opt3, 0);
        }
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
