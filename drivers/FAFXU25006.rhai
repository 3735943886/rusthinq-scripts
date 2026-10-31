// LG front-load washer FAFXU25006 (WM5800HVA), read only: port of upstream rethink's
// FAFXU25006.ts (commit 0e57069), every offset confirmed live there against the LG cloud's decoded
// state. Status is an enveloped 0x20 frame (long AA FF framing) of one 72-byte record (EB) or two,
// previous and current (EC), the record led by a 0x0a marker; `aabb_common::enveloped_status`
// takes the current one. Record offsets:
//   1 soil   2 temperature   3 rinse   4 spin   5 course   12/13 delay wash left,
//   14/15 remaining, 16/17 initial time (minutes, little-endian)   18/19 energy used (Wh,
//   little-endian)   21 state (0 off)   24 load level (100 until weighed)   28 washes since the
//   last tub clean   29 buzzer   30/31 EZDispense detergent / softener   34 options (0x20
//   TurboWash, 0x40 pre-wash, 0x80 auto soak)   35 (0x10 steam)   36 (0x40 fresh care)
//   37 (0x20 child lock, 0x40 drum light)   38 door lock   39 (0x80 delay wash)
//   40 (0x04 remote maintain)   69 end melody
// The door is not in the record: its own enveloped frame (inner type 0x03, 14 bytes) reads 1 open,
// 2 shut. LG's not-applicable dashes (soil, rinse and EZDispense 0xFF, temperature 0) read "none";
// the unweighed load level is absent. The times read 0 while off; energy survives power-off.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

// The model JSON's state indices, named as upstream names them across its washers: 27, 28 and
// 29 are FROZEN_PREVENT_INITIAL, _PAUSE and _RUNNING, 23 is ERROR_AUTO_OFF. Upstream leaves 34
// and up as LG names them, unverified.
fn states() {
    #{ "0": "off", "1": "standby", "27": "standby", "2": "paused", "28": "paused", "3": "detecting",
       "5": "filling", "6": "detergent_amount", "7": "delayed", "8": "soaking", "9": "pre_wash",
       "11": "washing", "29": "washing", "12": "rinsing", "13": "rinse_hold", "14": "spinning",
       "15": "drying", "16": "end", "21": "refreshing", "23": "error", "34": "audible_diagnosis",
       "35": "auto_door_open_pause", "36": "confirm_start_for_control", "37": "clothing_recognition",
       "38": "detergent_input", "39": "softener_input", "40": "pollution_detecting",
       "41": "tub_cleaning", "42": "end_remote_maintain_on", "43": "steam", "47": "laundry_care",
       "48": "ezdispense_cleaning", "52": "dry_cooling" }
}

fn courses() {
    #{ "5": "allergiene", "6": "coldwash", "18": "color_care", "22": "delicates", "27": "bedding",
       "35": "heavy_duty", "38": "jeans", "39": "kids_wear", "46": "normal", "47": "overnight_wash",
       "48": "perm_press", "55": "rinse_spin", "60": "sanitary", "68": "small_load", "74": "quick_wash",
       "78": "spin_only", "84": "towels", "85": "tub_clean", "90": "brightwhites", "94": "hand_wool",
       "99": "activewear", "113": "sweat_stains", "114": "ai_wash", "119": "pet_care", "130": "swimwear",
       "131": "dresses", "132": "large_load", "133": "xl_load", "136": "microplastics_care" }
}

fn soils() { #{ "255": "none", "1": "light", "2": "light_normal", "3": "normal", "4": "normal_heavy", "5": "heavy" } }
fn spins() { #{ "12": "drain_only", "13": "low", "14": "medium", "15": "high", "16": "extra_high" } }
fn temps() { #{ "0": "none", "7": "tap_cold", "8": "cold", "9": "warm", "10": "hot", "11": "extra_hot" } }
fn ez_dispenses() { #{ "255": "none", "0": "off", "1": "less", "2": "normal", "3": "more" } }
fn buzzers() { #{ "0": "off", "1": "1", "2": "2", "3": "3", "4": "4" } }
fn rinses() { #{ "255": "none", "14": "normal", "15": "plus", "16": "plus_2", "17": "plus_3" } }

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer", vendor: "LG",
                      model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", class: "running", label: "Powered on" },
        status: #{ type: "select", options: t::options(states()) },
        course: #{ type: "select", options: t::options(courses()) },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle length" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Cycle energy" },
        reserve_time: #{ type: "number", class: "duration", unit: "min", label: "Delay wash left" },
        delay_wash: #{ type: "binary" },
        door: #{ type: "binary", class: "door", label: "Door open" },
        load_level: #{ type: "number", series: "gauge", category: "diagnostic" },
        tub_clean_count: #{ type: "number", category: "diagnostic", label: "Washes since tub clean" },
        buzzer: #{ type: "select", category: "diagnostic", options: t::options(buzzers()) },
        end_melody: #{ type: "binary", category: "diagnostic" },
        auto_soak: #{ type: "binary" },
        fresh_care: #{ type: "binary" },
        child_lock: #{ type: "binary", category: "diagnostic" },
        remote_maintain: #{ type: "binary" },
        ez_dispense_detergent: #{ type: "select", options: t::options(ez_dispenses()) },
        ez_dispense_softener: #{ type: "select", options: t::options(ez_dispenses()) },
        drum_light: #{ type: "binary" },
        soil: #{ type: "select", label: "Soil level", options: t::options(soils()) },
        spin: #{ type: "select", options: t::options(spins()) },
        temp: #{ type: "select", label: "Water temperature", options: t::options(temps()) },
        rinse: #{ type: "select", options: t::options(rinses()) },
        turbo_wash: #{ type: "binary" },
        pre_wash: #{ type: "binary" },
        steam: #{ type: "binary" },
        door_lock: #{ type: "binary", category: "diagnostic" }
    } })
}

fn start(ctx) {
    ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x11, 0x21, 0x01, 0x00, 0x00, 0x00, 0x18, 0x04, 0x11, 0x12, 0x00, 0x00]));
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn u16le(r, o) { (r[o] + r[o + 1] * 256).to_string() }

// The door frame: an envelope whose inner type is 0x03, 14 bytes, the door at body offset 22.
fn door_event(ctx, data) {
    let b = c::inner(data, 0x20);
    if b == () || b.len() != 69 || b[1] != 0x0a || b[10] != 0x03 || b[11] * 256 + b[12] != 14 { return; }
    if b[22] == 1 { il::publish_property(ctx, "door", "true"); }
    else if b[22] == 2 { il::publish_property(ctx, "door", "false"); }
}

fn on_data(ctx, data) {
    let r = c::enveloped_status(data, 0x20, 72);
    if r == () { door_event(ctx, data); return; }
    if r[0] != 0x0a { return; }
    let off = r[21] == 0;
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if off { "false" } else { "true" });
    c::pub_name(ctx, "status", t::name(states(), r[21]));
    c::pub_name(ctx, "course", t::name(courses(), r[5]));
    c::pub_name(ctx, "soil", t::name(soils(), r[1]));
    c::pub_name(ctx, "spin", t::name(spins(), r[4]));
    c::pub_name(ctx, "temp", t::name(temps(), r[2]));
    c::pub_name(ctx, "rinse", t::name(rinses(), r[3]));
    il::publish_property(ctx, "remaining_time", if off { "0" } else { u16le(r, 14) });
    il::publish_property(ctx, "initial_time", if off { "0" } else { u16le(r, 16) });
    il::publish_property(ctx, "energy", u16le(r, 18));
    il::publish_property(ctx, "reserve_time", u16le(r, 12));
    il::publish_property(ctx, "delay_wash", c::bit(r[39], 0x80));
    il::publish_property(ctx, "drum_light", c::bit(r[37], 0x40));
    if r[24] == 100 { il::publish_absent(ctx, "load_level"); } else { il::publish_property(ctx, "load_level", r[24].to_string()); }
    il::publish_property(ctx, "tub_clean_count", r[28].to_string());
    c::pub_name(ctx, "buzzer", t::name(buzzers(), r[29]));
    c::pub_name(ctx, "ez_dispense_detergent", t::name(ez_dispenses(), r[30]));
    c::pub_name(ctx, "ez_dispense_softener", t::name(ez_dispenses(), r[31]));
    il::publish_property(ctx, "end_melody", if r[69] != 0 { "true" } else { "false" });
    il::publish_property(ctx, "turbo_wash", c::bit(r[34], 0x20));
    il::publish_property(ctx, "pre_wash", c::bit(r[34], 0x40));
    il::publish_property(ctx, "auto_soak", c::bit(r[34], 0x80));
    il::publish_property(ctx, "fresh_care", c::bit(r[36], 0x40));
    il::publish_property(ctx, "child_lock", c::bit(r[37], 0x20));
    il::publish_property(ctx, "remote_maintain", c::bit(r[40], 0x04));
    il::publish_property(ctx, "steam", c::bit(r[35], 0x10));
    il::publish_property(ctx, "door_lock", if r[38] != 0 { "true" } else { "false" });
}

fn on_set_property(ctx, prop, value) {
    il::validate(ctx, prop, value); // every property is read only: il_common publishes the reject
}
