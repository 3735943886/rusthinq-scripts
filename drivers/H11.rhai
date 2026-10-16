// LG dishwasher H11: device -> IL driver. Port of upstream rethink's driver (commit 0e57069).
// 46-byte records (a 0x18 payload, then 20 bytes not decoded); dishwasher_common decodes the
// shared fields, plus
//   11 flags1: 0x10 auto dry, 0x40 clean reminder       15 flags2: 0x02 remote start armed,
//   16 flags3: 0x04 end-of-cycle tone, 0xC0 remote start mode    0xC0 buzzer level
//   19 0x40 bright display      20 downloaded course (downloads()), overrides the course
//   21 extra rinse count in the high nibble
// Settings are written as one F0 26 snapshot of all of them, so a write waits until a status
// record has reported every one: F0 26 <rinse> <salt> <opt1> <opt2> <opt3> 00 00 00, where the
// setting bits sit in other positions than in the record (see write_settings).
import "aabb_common" as c;
import "dishwasher_common" as w;
import "table_common" as t;
import "il_common" as il;

fn courses() {
    #{ "0": "off", "1": "auto", "2": "heavy_intensive", "5": "normal_eco", "8": "express",
       "9": "machine_clean", "11": "download_cycle", "16": "silent_night", "18": "one_hour" }
}

fn downloads() {
    #{ "2": "pots_and_pans", "3": "glassware_and_wine_glasses", "4": "grilled_meat",
       "5": "greasy_tableware", "6": "dishes_with_baked_on_food", "7": "fish_dishes",
       "8": "delicate", "10": "rinse_only", "13": "machine_clean", "15": "plastic_wash" }
}

fn buzzer() { #{ "0": "off", "1": "low", "2": "high" } }
fn remote_modes() { #{ "1": "one_time", "2": "permanent", "3": "off" } }
fn brightness() { #{ "0": "low", "1": "high" } }

fn descriptor(ctx) {
    let course_options = t::options(courses());
    for n in t::options(downloads()) { if !course_options.contains(n) { course_options.push(n); } }
    let props = w::props(course_options);
    props += w::control_props(t::options(courses()).filter(|n| n != "off"));
    let level = #{ type: "number", rw: true, min: 0, max: 4, step: 1, category: "config" };
    let setting = #{ type: "binary", rw: true, category: "config" };
    props += #{
        power: #{ type: "binary", rw: true },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle time" },
        delay_start_time: #{ type: "number", class: "duration", unit: "min", label: "Delayed start" },
        extra_dry: #{ type: "binary" },
        high_temp: #{ type: "binary" },
        extra_rinse: #{ type: "number", label: "Extra rinses" },
        rinse_level: level + #{ label: "Rinse aid level" },
        salt_level: level + #{ label: "Salt level" },
        buzzer_level: #{ type: "select", rw: true, options: t::options(buzzer()), category: "config" },
        end_of_cycle_tone: setting,
        clean_reminder: setting,
        auto_dry: setting,
        brightness: #{ type: "select", rw: true, options: t::options(brightness()), category: "config" },
        remote_start_mode: #{ type: "select", rw: true, options: t::options(remote_modes()), category: "config" },
        target_extra_rinse: #{ type: "number", rw: true, min: 0, max: 3, step: 1, label: "Start with extra rinses" }
    };
    json_stringify(#{ il: 0, kind: "washer", class: "dishwasher", label: "Dishwasher", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn start(ctx) {
    for pair in [["target_course", "auto"], ["target_delay", "0"], ["target_high_temp", "false"],
              ["target_extra_dry", "false"], ["target_extra_rinse", "0"]] {
        il::publish_property(ctx, pair[0], w::target(ctx, pair[0], pair[1]));
    }
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    if w::energy(ctx, data) { return; }
    let p = w::payload(data, 46, 0x18);
    if p == () { return; }
    w::publish(ctx, p);
    il::publish_property(ctx, "power", if p[0] == 4 { "false" } else { "true" });
    let course = if p[20] != 0 { t::name(downloads(), p[20]) } else { t::name(courses(), p[5]) };
    c::pub_name(ctx, "course", course);
    il::publish_property(ctx, "initial_time", w::minutes(p, 3).to_string());
    il::publish_property(ctx, "delay_start_time", w::minutes(p, 9).to_string());
    il::publish_property(ctx, "extra_dry", c::bit(p[12], 0x04));
    il::publish_property(ctx, "high_temp", c::bit(p[12], 0x08));
    il::publish_property(ctx, "remote_start", c::bit(p[15], 0x02));
    if p[21] >> 4 <= 3 { il::publish_property(ctx, "extra_rinse", (p[21] >> 4).to_string()); }

    // Settings as codes; an unknown code is `()` and blocks settings writes until reported again.
    let s = #{
        rinse_level: if p[13] <= 4 { p[13] } else { () },
        salt_level: if p[14] <= 4 { p[14] } else { () },
        buzzer_level: if (p[15] >> 6) <= 2 { p[15] >> 6 } else { () },
        remote_start_mode: if (p[16] >> 6) >= 1 { p[16] >> 6 } else { () },
        end_of_cycle_tone: (p[16] >> 2) & 1,
        clean_reminder: (p[11] >> 6) & 1,
        auto_dry: (p[11] >> 4) & 1,
        brightness: (p[19] >> 6) & 1
    };
    ctx.state_set("settings", s);
    for k in ["rinse_level", "salt_level"] { if s[k] != () { il::publish_property(ctx, k, s[k].to_string()); } }
    for k in ["end_of_cycle_tone", "clean_reminder", "auto_dry"] { il::publish_property(ctx, k, c::on_off(s[k])); }
    if s.buzzer_level != () { il::publish_property(ctx, "buzzer_level", t::name(buzzer(), s.buzzer_level)); }
    if s.remote_start_mode != () {
        il::publish_property(ctx, "remote_start_mode", t::name(remote_modes(), s.remote_start_mode));
    }
    il::publish_property(ctx, "brightness", t::name(brightness(), s.brightness));
}

fn write_settings(ctx, prop, code) {
    let s = ctx.state_get("settings");
    if s == () { return c::reject(ctx, prop, "settings not reported yet"); }
    s[prop] = code;
    for v in s.values() { if v == () { return c::reject(ctx, prop, "settings not reported yet"); } }
    ctx.state_set("settings", s);
    let opt1 = (s.end_of_cycle_tone << 6) | (s.auto_dry << 5) | (s.clean_reminder << 3) | (s.buzzer_level << 1);
    w::command(ctx, [s.rinse_level, s.salt_level, opt1, s.remote_start_mode << 6, s.brightness << 6, 0, 0, 0]);
}

fn set_property(ctx, prop, value) {
    if w::control(ctx, prop) { return; }
    let on = if c::to_bool(value) { 1 } else { 0 };
    switch prop {
        "power" => w::command(ctx, [if on == 1 { 0x16 } else { 0x12 }]),
        "rinse_level" | "salt_level" => write_settings(ctx, prop, c::to_number(value).to_int()),
        "end_of_cycle_tone" | "clean_reminder" | "auto_dry" => write_settings(ctx, prop, on),
        "buzzer_level" => write_settings(ctx, prop, t::code(buzzer(), value)),
        "brightness" => write_settings(ctx, prop, t::code(brightness(), value)),
        "remote_start_mode" => write_settings(ctx, prop, t::code(remote_modes(), value)),
        "target_course" | "target_high_temp" | "target_extra_dry" => w::set_target(ctx, prop, value),
        "target_delay" | "target_extra_rinse" => w::set_target(ctx, prop, c::to_number(value).to_int().to_string()),
        "start_course" => {
            let course = t::code(courses(), w::target(ctx, "target_course", "auto"));
            let opt3 = w::opt(ctx, "target_high_temp", 0x08) | w::opt(ctx, "target_extra_dry", 0x04);
            let opt4 = w::target(ctx, "target_extra_rinse", "0").parse_int() << 3;
            w::start_course(ctx, course, opt3, if course == 0x0b { opt4 | 0x40 } else { opt4 });
        }
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
