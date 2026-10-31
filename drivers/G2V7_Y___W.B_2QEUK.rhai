// LG slim front-load washer G2V7_Y___W.B_2QEUK (F2NX50S9TKC): port of upstream rethink's
// G2V7_Y___W.B_2QEUK.ts (commit 2d8eaba), each offset confirmed there on the washer one panel
// setting at a time and over a month of washes. Status is the 0x20 envelope (c::enveloped_status)
// of 67-byte EB/EC records: an EB answers the status query, and every later change is pushed as an
// EC pair. The record is VCDWL2QEUK's with one byte in front, and the codes both offer agree:
//    2 temperature   4 spin   5 course   11/12 delay end (min, BE; to the end of the programme)
//   14 remaining, 16 initial time (min)   17/18 energy (Wh, BE; from zero at power on)
//   21 state   28 washes since Drum Clean   34 0x08 Intensive, 0x20 TurboWash, 0x40 pre-wash
//   37 0x01 door shut, 0x10 remote start, 0x20 child lock   39 0x40 Rinse+
// Cold and No spin sit past the top of their scales (8 and 0x0c). Off, the record keeps the last
// course and times, which the panel no longer shows, so the settings are absent; so is a
// temperature or spin the code does not name (0 once the wash phase is over). The wash count reads
// 0 after a power cut, so it is taken only while on. 20 00 <command> <result> frames answer
// commands (ff refused) and are not status.
//
// The washer repeats its reports unacked, so every envelope gets the cloud's ack. Commands as
// Y_V8_Y___W.B32QEUK's: F0 2A 01 00 power on, F0 24 01 01 00 power off, F0 24 04 01 00 pause,
// F0 24 05 01 00 start (runs what the panel is set to). Start and pause need Remote Start, which
// only the panel arms; the washer refuses a start without it and ignores a pause.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn states() {
    #{ "0": "off", "1": "standby", "2": "paused", "3": "detecting", "7": "delayed", "11": "washing",
       "12": "rinsing", "14": "spinning", "16": "end" }
}

// As VCDWL2QEUK's codes; 0xff is the Download Cycle slot (Rinse + Spin until another is downloaded).
fn courses() {
    #{ "46": "cotton", "19": "eco_40_60", "43": "mix", "29": "easy_care", "94": "hand_wool",
       "79": "activewear", "114": "ai_wash", "122": "turbo_wash_39", "75": "quick_14", "4": "allergy_care",
       "136": "microplastic_care", "255": "download_cycle" }
}

fn temps() { #{ "8": "cold", "1": "20", "2": "30", "3": "40", "5": "60", "6": "95" } }
fn spins() { #{ "12": "no_spin", "1": "400", "4": "800", "6": "1000", "8": "1200" } }

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer", vendor: "LG",
                      model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", rw: true, class: "running", label: "Powered on" },
        start: #{ type: "trigger", requires: "remote_start" },
        pause: #{ type: "trigger", requires: "remote_start" },
        status: #{ type: "select", options: t::options(states()) },
        course: #{ type: "select", options: t::options(courses()) },
        temp: #{ type: "select", label: "Water temperature", options: t::options(temps()) },
        spin: #{ type: "select", options: t::options(spins()) },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle length" },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        delay_end: #{ type: "number", class: "duration", unit: "min", label: "Delay end" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Cycle energy" },
        door: #{ type: "binary", class: "door", label: "Door open" },
        child_lock: #{ type: "binary", category: "diagnostic" },
        remote_start: #{ type: "binary", category: "diagnostic", label: "Remote start armed at the panel" },
        rinse_plus: #{ type: "binary", label: "Rinse+" },
        intensive: #{ type: "binary" },
        pre_wash: #{ type: "binary" },
        turbo_wash: #{ type: "binary" },
        cycles: #{ type: "number", series: "counter", category: "diagnostic", label: "Washes since Drum Clean" }
    } })
}

fn start(ctx) { ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x11, 0x21, 0x01, 0x00, 0x00, 0x00, 0x18, 0x00])); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

// `value` while on, or absent: the panel shows no settings while off.
fn setting(ctx, prop, on, value) {
    if on && value != () { il::publish_property(ctx, prop, value); } else { il::publish_absent(ctx, prop); }
}

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let s = c::enveloped_status(data, 0x20, 67);
    if s == () { return; }
    let on = s[21] != 0;
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if on { "true" } else { "false" });
    c::pub_name(ctx, "status", t::name(states(), s[21]));
    setting(ctx, "course", on, t::name(courses(), s[5]));
    setting(ctx, "temp", on, t::name(temps(), s[2]));
    setting(ctx, "spin", on, t::name(spins(), s[4]));
    setting(ctx, "initial_time", on, s[16].to_string());
    setting(ctx, "remaining_time", on, s[14].to_string());
    setting(ctx, "delay_end", on, (s[11] * 256 + s[12]).to_string());
    setting(ctx, "rinse_plus", on, c::bit(s[39], 0x40));
    setting(ctx, "intensive", on, c::bit(s[34], 0x08));
    setting(ctx, "pre_wash", on, c::bit(s[34], 0x40));
    setting(ctx, "turbo_wash", on, c::bit(s[34], 0x20));
    il::publish_property(ctx, "energy", (s[17] * 256 + s[18]).to_string());
    il::publish_property(ctx, "door", if (s[37] & 0x01) == 0 { "true" } else { "false" });
    il::publish_property(ctx, "child_lock", c::bit(s[37], 0x20));
    il::publish_property(ctx, "remote_start", c::bit(s[37], 0x10));
    if on { il::publish_property(ctx, "cycles", s[28].to_string()); }
}

fn set_property(ctx, prop, value) {
    let msg = switch prop {
        "power" => if c::to_bool(value) { [0xf0, 0x2a, 0x01, 0x00] } else { [0xf0, 0x24, 0x01, 0x01, 0x00] },
        "pause" => [0xf0, 0x24, 0x04, 0x01, 0x00],
        "start" => [0xf0, 0x24, 0x05, 0x01, 0x00],
        _ => { c::reject(ctx, prop, "unknown or read-only property"); return; }
    };
    ctx.send_raw(aabb_wrap(msg));
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
