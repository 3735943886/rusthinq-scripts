// LG top-load washer TLVE5BB (WT21BWV6), read only: port of upstream rethink's TLVE5BB.ts (commit
// 0e57069). Status is an enveloped 0x20 frame (long AA FF framing) of one 50-byte record (EB) or
// two, previous and current (EC); `aabb_common::enveloped_status` takes the current one. Offsets:
//   1 soil   2 temperature   3 rinses remaining   4 spin   14/15 remaining, 16/17 initial time
//   (min, little-endian)   18/19 cycle energy (Wh, little-endian)   21 state (0 off)
//   28 washes since the last drum clean   29 buzzer   38 lid lock (non-zero: locked)
// The times read 0 while off (the record keeps a stale minute). start() asks for the status.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn record_len() { 50 }

fn states() {
    #{ "0": "off", "1": "initial", "2": "paused", "3": "detecting", "5": "add_drain",
       "6": "detergent_amount", "7": "reserved", "8": "soak", "9": "pre_wash", "11": "running",
       "12": "rinsing", "13": "rinse_hold", "14": "spinning", "15": "drying", "16": "end",
       "21": "refreshing", "23": "error_auto_off", "27": "frozen_prevent_initial",
       "28": "frozen_prevent_pause", "29": "frozen_prevent_running", "34": "audible_diagnosis",
       "35": "auto_door_open_pause", "36": "confirm_start_for_control", "37": "clothing_recognition",
       "38": "detergent_input", "39": "softener_input", "40": "pollution_detecting",
       "41": "tub_cleaning", "42": "end_remote_maintain_on", "43": "steam", "47": "laundry_care",
       "48": "ezdispense_cleaning", "52": "dry_cooling" }
}

fn soils() {
    #{ "1": "light", "2": "light_normal", "3": "normal", "4": "normal_heavy", "5": "heavy",
       "6": "pre_wash", "7": "soaking", "8": "turbo_wash", "9": "time_save", "10": "intensive" }
}

fn spins() { #{ "13": "low", "14": "medium", "15": "high", "16": "extra_high", "17": "dry_intensive", "18": "delicate" } }

fn temps() { #{ "8": "cold", "9": "warm", "10": "hot", "12": "cold_hot" } }

fn buzzers() { #{ "0": "off", "1": "low", "2": "medium", "3": "high", "4": "very_loud" } }

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer", vendor: "LG",
                      model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", class: "running", label: "Powered on" },
        status: #{ type: "select", options: t::options(states()) },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle length" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Cycle energy" },
        soil: #{ type: "select", label: "Soil level", options: t::options(soils()) },
        temp: #{ type: "select", label: "Water temperature", options: t::options(temps()) },
        spin: #{ type: "select", options: t::options(spins()) },
        rinses_remaining: #{ type: "number", series: "gauge" },
        tub_clean_count: #{ type: "number", category: "diagnostic", label: "Washes since drum clean" },
        buzzer: #{ type: "select", category: "diagnostic", options: t::options(buzzers()) },
        lid_lock: #{ type: "binary", category: "diagnostic" }
    } })
}

fn start(ctx) {
    ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x11, 0x21, 0x01, 0x00, 0x00, 0x00, 0x18, 0x04, 0x11, 0x12, 0x00, 0x00]));
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn u16le(r, o) { r[o] + r[o + 1] * 256 }

fn on_data(ctx, data) {
    let r = c::enveloped_status(data, 0x20, record_len());
    if r == () { return; }
    let off = r[21] == 0;
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if off { "false" } else { "true" });
    c::pub_name(ctx, "status", t::name(states(), r[21]));
    il::publish_property(ctx, "remaining_time", if off { "0" } else { u16le(r, 14).to_string() });
    il::publish_property(ctx, "initial_time", if off { "0" } else { u16le(r, 16).to_string() });
    il::publish_property(ctx, "energy", u16le(r, 18).to_string());
    c::pub_name(ctx, "soil", t::name(soils(), r[1]));
    c::pub_name(ctx, "temp", t::name(temps(), r[2]));
    c::pub_name(ctx, "spin", t::name(spins(), r[4]));
    il::publish_property(ctx, "rinses_remaining", r[3].to_string());
    il::publish_property(ctx, "tub_clean_count", r[28].to_string());
    c::pub_name(ctx, "buzzer", t::name(buzzers(), r[29]));
    il::publish_property(ctx, "lid_lock", if r[38] != 0 { "true" } else { "false" });
}

fn on_set_property(ctx, prop, value) {
    il::validate(ctx, prop, value); // every property is read only: il_common publishes the reject
}
