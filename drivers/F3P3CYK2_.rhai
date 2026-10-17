// LG front-load washer F3P3CYK2_ (WM4200HBA): port of upstream rethink's F3P3CYK2_.ts (commit
// 0e57069), decoded there from real traffic while operating the washer. Same family as F3L2CYU__,
// but its own 44-byte record: a 0x20 EB frame of one block or EC of two (previous, current), a block
// being one leading byte and the record, which starts with a 0x2b marker. Record offsets:
//   2 soil   3 temperature   4 rinse   5 spin   6 course   12/13 delay, 14/15 remaining,
//   16/17 initial time (minutes, big-endian)   20 error (modelJSON index)   22 state (0 off, 16 end)
//   29 washes since the last tub clean   30 buzzer   36 options (0x20 Rinse+Spin)
// The times read 0 while off; the End record is published as is. Soil and temperature 0 (Rinse+Spin)
// and course 0 (off) read "none"; course 0xFF is a real selection here, Downloaded. 0xE2 replays and
// 0xBD/0xCD dumps are not this record. The one write is power off (F0 24 01 01 00, captured from the
// ThinQ app), offered only while powered on; remote power-on is deliberately absent.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn errors() {
    #{ "2": "IE", "3": "OE", "4": "UE", "5": "FE", "6": "AE", "7": "PE", "8": "tE", "9": "LE", "10": "CE",
       "11": "dHE", "13": "FF", "14": "dCE", "15": "EE", "16": "LOE", "19": "PS", "20": "dE1 - Door Open",
       "21": "dE2", "23": "VS", "35": "PF", "41": "sud", "43": "Ed1", "44": "Ed2", "45": "Ed3", "46": "Ed4",
       "47": "Ed5" }
}

fn states() {
    #{ "0": "off", "1": "initial", "2": "paused", "3": "detecting", "5": "add_drain",
       "6": "detergent_amount", "7": "reserved", "9": "pre_wash", "11": "running", "12": "rinsing",
       "13": "rinse_hold", "14": "spinning", "15": "drying", "16": "end", "21": "refreshing",
       "23": "error_auto_off", "27": "frozen_prevent_initial", "28": "frozen_prevent_pause",
       "29": "frozen_prevent_running", "34": "audible_diagnosis", "35": "auto_door_open_pause",
       "36": "confirm_start_for_control" }
}

fn courses() {
    #{ "0": "none", "5": "allergiene", "13": "bedding", "22": "delicates", "25": "drain_spin",
       "35": "heavy_duty", "46": "normal", "48": "perm_press", "60": "sanitary", "74": "speed_wash",
       "79": "sportswear", "84": "towels", "85": "tub_clean", "90": "bright_whites", "255": "downloaded" }
}

fn soils() { #{ "0": "none", "1": "light", "2": "light_normal", "3": "normal", "4": "normal_heavy", "5": "heavy" } }
fn temps() { #{ "0": "none", "13": "tap_cold", "14": "cold", "15": "eco_warm", "16": "warm", "17": "warm_rinse", "18": "hot", "19": "extra_hot" } }
fn rinses() { #{ "14": "normal", "15": "plus", "16": "plus_2", "17": "plus_3" } }
fn spins() { #{ "12": "no_spin", "13": "low", "14": "medium", "15": "high", "16": "extra_high" } }
fn buzzers() { #{ "0": "off", "1": "1", "2": "2", "3": "3", "4": "4" } }

// An unmapped state reads as "running", as upstream's.
fn state_options() { let o = t::options(states()); if !o.contains("running") { o.push("running"); } o }

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer", vendor: "LG",
                      model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", class: "running", label: "Powered on" },
        power_off: #{ type: "trigger", requires: "power" },
        status: #{ type: "select", options: state_options() },
        run_completed: #{ type: "binary" },
        error: #{ type: "binary", class: "problem", category: "diagnostic" },
        error_message: #{ type: "text", category: "diagnostic" },
        course: #{ type: "select", options: t::options(courses()) },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle length" },
        reserve_time: #{ type: "number", class: "duration", unit: "min", label: "Delay" },
        soil: #{ type: "select", label: "Soil level", options: t::options(soils()) },
        temp: #{ type: "select", label: "Water temperature", options: t::options(temps()) },
        rinse: #{ type: "select", options: t::options(rinses()) },
        spin: #{ type: "select", options: t::options(spins()) },
        rinse_spin: #{ type: "binary", label: "Rinse + Spin" },
        tub_clean_count: #{ type: "number", category: "diagnostic", label: "Washes since tub clean" },
        buzzer: #{ type: "select", category: "diagnostic", options: t::options(buzzers()) }
    } })
}

fn start(ctx) {
    ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x11, 0x21, 0x01, 0x00, 0x00, 0x00, 0x18, 0x04, 0x13, 0x14, 0x00, 0x00]));
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn u16be(r, o) { (r[o] * 256 + r[o + 1]).to_string() }

fn hex2(n) { let h = "0123456789ABCDEF"; h.sub_string(n / 16, 1) + h.sub_string(n % 16, 1) }

fn on_data(ctx, data) {
    let b = c::inner(data, 0x20);
    if b == () { return; }
    let o = c::common_status_offset(b, 45);
    if o == () || b[o + 1] != 0x2b { return; }
    let r = b.extract(o + 1, 44);
    let off = r[22] == 0;
    let code = r[20];
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if off { "false" } else { "true" });
    il::publish_property(ctx, "error", if code != 0 { "true" } else { "false" });
    il::publish_property(ctx, "error_message",
        if code == 0 { "-" } else { t::name(errors(), code) ?? "Unknown error (0x" + hex2(code) + ")" });
    il::publish_property(ctx, "status", t::name(states(), r[22]) ?? "running");
    c::pub_name(ctx, "course", t::name(courses(), r[6]));
    il::publish_property(ctx, "remaining_time", if off { "0" } else { u16be(r, 14) });
    il::publish_property(ctx, "initial_time", if off { "0" } else { u16be(r, 16) });
    il::publish_property(ctx, "reserve_time", if off { "0" } else { u16be(r, 12) });
    c::pub_name(ctx, "soil", t::name(soils(), r[2]));
    c::pub_name(ctx, "temp", t::name(temps(), r[3]));
    c::pub_name(ctx, "rinse", t::name(rinses(), r[4]));
    c::pub_name(ctx, "spin", t::name(spins(), r[5]));
    il::publish_property(ctx, "rinse_spin", c::bit(r[36], 0x20));
    il::publish_property(ctx, "tub_clean_count", r[29].to_string());
    c::pub_name(ctx, "buzzer", t::name(buzzers(), r[30]));
    il::publish_property(ctx, "run_completed", if r[22] == 16 { "true" } else { "false" });
}

fn on_set_property(ctx, prop, value) {
    if il::validate(ctx, prop, value) == () { return; }
    if prop == "power_off" { ctx.send_raw(aabb_wrap([0xf0, 0x24, 0x01, 0x01, 0x00])); }
    else { c::reject(ctx, prop, "unknown or read-only property"); }
}
