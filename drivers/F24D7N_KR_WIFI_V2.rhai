// LG front-load washer F24D7N_KR_WIFI_V2 (Korea, deviceType 201, firmware 1.3): device -> IL driver.
// New driver written for this model; based on rusthinq-scripts F24VDD.rhai /
// washer_f24_legacy_common / monitoring_common.
//
// READ-ONLY: every write is rejected. The only frame sent to the washer is the status
// request in start(); the washer does not push status until it gets it.
//
// Wire: AABB frames, device byte 0x20.
//   20 EC  [hdr][19][25-byte previous record] [hdr][19][25-byte current record]  (hdr usually 00, 02/03/84 at cycle end)
//   20 EB  [hdr][19][25-byte current record]                                    (right after connect, answer to the status request)
//   20 72 .. C8/C9   remote start disabled / enabled on the panel
// The 25-byte record has the same layout as the head of the 34-byte record in
// washer_f24_legacy_common (F24VDD):
//   0 state, 1-2 remaining (h, min), 3-4 initial time, 5 course (dial), 6 error, 7 soil, 8 spin,
//   9 water temperature, 10 rinse count, 12-13 reservation end, 14 option bits, 15 option bits 2,
//   17-18 energy of the current cycle (Wh), 20 downloaded course, 21 cycles since tub clean,
//   23 load level (AI DD)
// Verified 2026-11-20 with one cotton cycle and a full turn of the dial: state, remaining time
// (matches the panel), turbo shot, door lock, energy, byte 21 = the official LG integration's
// "cycle count" (22 -> 23), and the course table 1..12 below (this model's dial order).

import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn record_len() { 25 }
fn tub_threshold() { 30 }   // the washer shows its tub-clean reminder at this count

fn states() {
    #{ "0": "off", "5": "initial", "6": "paused", "7": "error_auto_off", "10": "reserved", "20": "sensing",
       "21": "draining", "22": "detergent_dosing", "23": "washing", "24": "pre_wash", "30": "rinsing",
       "31": "rinse_hold", "40": "spinning", "50": "drying", "60": "complete", "61": "refreshing",
       "83": "freeze_protection_initial", "84": "freeze_protection_running",
       "85": "freeze_protection_paused", "101": "audible_diagnosis" }
}
// Dial order on this model (checked by turning the dial on the panel). Differs from F24VDD.
fn courses() {
    #{ "0": "none", "1": "lingerie_wool", "2": "functional_wear", "3": "economy_boil", "4": "baby_wear",
       "5": "heavy_duty", "6": "cotton", "7": "speed_wash", "8": "quiet", "9": "colour_care", "10": "duvet",
       "11": "rinse_spin", "12": "downloaded_course" }
}
// Downloaded course ids (same numbering as F24VDD's smart_ids, extended).
fn downloads() {
    #{ "0": "none", "51": "cold_wash", "52": "small_load", "53": "skin_care", "54": "rainy_day",
       "55": "sweat_stain", "56": "single_garments", "57": "kids_wear", "58": "shirt", "59": "school_uniform",
       "60": "static_reduce", "62": "colour_care", "63": "spin_only", "64": "air_wash", "65": "deodorization",
       "66": "bedding_care", "67": "cloth_care", "68": "smart_rinse", "69": "eco_wash", "70": "rinse_twice",
       "71": "heavy_duty", "73": "wash_dry", "74": "quiet", "75": "wrinkle_care", "77": "rinse_spin",
       "78": "baby_wear", "79": "sportswear", "80": "towels", "81": "shirt_1h", "82": "allergy_care",
       "83": "hygiene_wash", "84": "speed_wash", "85": "pet_care", "86": "quick_tub_clean" }
}
fn soils() { #{ "0": "none", "1": "light", "2": "normal", "3": "heavy", "4": "pre_wash", "5": "soak" } }
fn spins() { #{ "0": "no_spin", "1": "very_low", "2": "low", "3": "medium", "4": "high", "5": "extra_high" } }
fn temps() { #{ "0": "none", "1": "cold", "2": "30", "3": "40", "4": "60", "5": "95" } }
fn errors() {
    #{ "0": "No error", "1": "Door lock error (dE2)", "2": "Water supply error (IE)", "3": "Drain error (OE)",
       "4": "Unbalanced load (UE)", "5": "Overflow (FE)", "6": "Water level sensor error (PE)",
       "7": "Temperature sensor error (tE)", "8": "Motor locked (LE)", "9": "Communication error (CE)",
       "10": "Heater error (dHE)", "11": "Power failure (PF)", "12": "Unknown error (FF)",
       "13": "Unknown error (dCE)", "14": "Vibration sensor error (VS)", "15": "Memory error (EEPROM)",
       "16": "Unknown error (PS)", "17": "Door open error (dE1)", "18": "Unknown error (LOE)",
       "19": "Door sensor error (dE4)" }
}

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", class: "running" },
        status: #{ type: "select", options: t::options(states()) },
        course: #{ type: "select", options: t::options(courses()) },
        download_course: #{ type: "select", category: "diagnostic", options: t::options(downloads()) },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        initial_time: #{ type: "number", class: "duration", unit: "min", category: "diagnostic" },
        reserve_time: #{ type: "number", class: "duration", unit: "min" },
        error: #{ type: "binary", class: "problem", category: "diagnostic" },
        error_message: #{ type: "text", category: "diagnostic" },
        remote_start: #{ type: "binary", category: "diagnostic" },
        soil: #{ type: "select", options: t::options(soils()) },
        spin: #{ type: "select", options: t::options(spins()) },
        temp: #{ type: "select", options: t::options(temps()) },
        rinse: #{ type: "number", series: "gauge" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Energy this cycle" },
        load_level: #{ type: "number", series: "gauge", category: "diagnostic", label: "Load level (AI DD 0-4)" },
        tub_clean_count: #{ type: "number", series: "gauge", label: "Cycles since tub clean" },
        tub_clean_due: #{ type: "binary", label: "Tub clean due" },
        steam: #{ type: "binary" },
        turbo_shot: #{ type: "binary" },
        crease_care: #{ type: "binary" },
        fresh_care: #{ type: "binary" },
        rinse_hold: #{ type: "binary" },
        add_load: #{ type: "binary" },
        favorite: #{ type: "binary", category: "diagnostic" },
        alarm: #{ type: "binary", category: "diagnostic" },
        door_lock: #{ type: "binary", category: "diagnostic" },
        child_lock: #{ type: "binary", category: "diagnostic" },
        smart_diagnosis: #{ type: "binary", category: "diagnostic" }
    };
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

// ---- host hooks -----------------------------------------------------------------------

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

// On attach / reload: publish the descriptor and send the same read-only status request
// the LG app sends. The washer only starts reporting after this request.
// A reconnect means the washer is back on the network, so it is available again before the
// first record arrives.
fn start(ctx) {
    publish_config(ctx);
    il::publish_property(ctx, "available", "true");
    ctx.send_raw(aabb_wrap(hex_decode("f0ed1121010000001800")));
}

// The washer leaves the network when switched off. The contributor showed it as off instead of
// unavailable; the IL contract wants `available` false on a drop, so both are published: the
// state reads off for consumers that keep showing it.
fn on_drop(ctx) {
    il::publish_property(ctx, "available", "false");
    il::publish_property(ctx, "power", "false");
    il::publish_property(ctx, "status", "off");
    il::publish_property(ctx, "remaining_time", "0");
    il::publish_property(ctx, "door_lock", "false");
}

fn on_set_property(ctx, prop, value) { c::reject(ctx, prop, "read-only driver"); }

// ---- decoding -------------------------------------------------------------------------

// Byte-sum checksum even when the length byte wraps (same as F24VDD).
fn valid_checksum(data) {
    if data.len() < 4 || data[0] != 0xaa || data[data.len() - 1] != 0xbb { return false; }
    let sum = 0;
    for i in 0..data.len() - 2 { sum += data[i]; }
    data[data.len() - 2] == ((sum & 255) ^ 0x55)
}

fn bit(v, mask) { if (v & mask) != 0 { "true" } else { "false" } }
fn minutes(h, m) { (h * 60 + m).to_string() }
fn pub_name(ctx, prop, table, v) {
    let name = t::name(table, v);
    if name != () { il::publish_property(ctx, prop, name); }
}

fn on_data(ctx, data) {
    if !valid_checksum(data) { return; }
    let b = data.extract(2, data.len() - 4);
    if b.len() < 2 || b[0] != 0x20 { return; }

    // Short frame when remote start is toggled on the panel
    if b[1] == 0x72 && b.len() == 5 {
        if b[3] == 0xc8 || b[3] == 0xc9 { il::publish_property(ctx, "remote_start", bit(b[3], 1)); }
        return;
    }

    // Status record: EC carries two (the last one is current), EB one. Check the length byte 0x19.
    let n = record_len();
    let ok = (b[1] == 0xec && b.len() == 2 + 2 * (n + 2)) || (b[1] == 0xeb && b.len() == 2 + n + 2);
    if !ok || b[b.len() - n - 1] != n { return; }
    decode(ctx, b.extract(b.len() - n, n));
}

fn decode(ctx, r) {
    let state = r[0];
    let off = state == 0;
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if off { "false" } else { "true" });
    pub_name(ctx, "status", states(), state);
    pub_name(ctx, "course", courses(), r[5]);
    pub_name(ctx, "download_course", downloads(), r[20]);

    // When off, the record still holds the last cycle's times, so publish 0.
    il::publish_property(ctx, "remaining_time", if off { "0" } else { minutes(r[1], r[2]) });
    il::publish_property(ctx, "initial_time", if off { "0" } else { minutes(r[3], r[4]) });
    il::publish_property(ctx, "reserve_time", if off { "0" } else { minutes(r[12], r[13]) });

    let error = r[6];
    il::publish_property(ctx, "error", if error != 0 { "true" } else { "false" });
    il::publish_property(ctx, "error_message", t::name(errors(), error) ?? "Unknown error (" + error + ")");

    pub_name(ctx, "soil", soils(), r[7]);
    pub_name(ctx, "spin", spins(), r[8]);
    pub_name(ctx, "temp", temps(), r[9]);
    il::publish_property(ctx, "rinse", r[10].to_string());
    il::publish_property(ctx, "energy", (r[17] * 256 + r[18]).to_string());
    il::publish_property(ctx, "load_level", r[23].to_string());
    il::publish_property(ctx, "tub_clean_count", r[21].to_string());
    il::publish_property(ctx, "tub_clean_due", if r[21] >= tub_threshold() { "true" } else { "false" });
    il::publish_property(ctx, "smart_diagnosis", if state == 101 { "true" } else { "false" });

    let flags = r[14];
    il::publish_property(ctx, "crease_care", bit(flags, 0x01));
    il::publish_property(ctx, "fresh_care", bit(flags, 0x02));
    il::publish_property(ctx, "rinse_hold", bit(flags, 0x04));
    il::publish_property(ctx, "child_lock", bit(flags, 0x08));
    il::publish_property(ctx, "steam", bit(flags, 0x10));
    il::publish_property(ctx, "remote_start", bit(flags, 0x20));
    il::publish_property(ctx, "favorite", bit(flags, 0x40));
    let opt2 = r[15];
    il::publish_property(ctx, "alarm", bit(opt2, 0x02));
    il::publish_property(ctx, "door_lock", bit(opt2, 0x04));
    il::publish_property(ctx, "add_load", bit(opt2, 0x40));
    il::publish_property(ctx, "turbo_shot", bit(opt2, 0x80));
}

