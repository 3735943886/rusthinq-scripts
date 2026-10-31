// LG front-load washer VCDWL2QEUK (F4X7511TWS): device -> IL driver, read only. Port of upstream
// rethink's driver (commit 2d8eaba), whose offsets were reverse-engineered against the LG app.
// Status is the 0x20 envelope (c::enveloped_status) of 64-byte EB/EC records; past the record's
// leading byte:
//     0 soil (0 outside the wash phase)   1 temperature - 1   3 spin - 1   4 course
//     13 remaining, 15 initial time (min)   16/17 cycle energy (Wh)   20 state (0 = off)
//     26 rinse   27 washes since Drum Clean   29/30 detergent / softener dispenser on
//     (0x02)   31/32 their doses (ml)   33 0x20 TurboWash, 0x40 pre-wash   34 0x10 steam
//     36 0x10 remote start, 0x20 child lock
// Other class 0x20 frames, told apart by body[3] (the low byte of their length):
//   0x88 config: sent at cycle start; taken only as a sign of power.
//   0x41 door snapshot: 18 is 0x01 open, 0x02 closed (0x05 before the first door event).
// An unknown state code leaves the status unpublished. Errors are not located.
import "aabb_common" as c;
import "table_common" as t;
import "washer_common" as w;
import "il_common" as il;

fn courses() {
    #{ "114": "ai_wash", "46": "cotton", "84": "towels", "75": "quick_14", "78": "spin_only",
       "85": "drum_clean", "19": "eco_40_60", "122": "turbo_wash_39", "43": "mix", "22": "delicate",
       "29": "easy_care", "94": "hand_wool", "79": "activewear", "4": "allergy_care", "27": "duvet",
       "17": "cold_wash", "129": "bedding", "169": "cuffs_collars", "106": "rainy_days",
       "66": "silent_wash", "7": "baby_steam_care", "115": "down_jacket", "136": "microplastic_care",
       "55": "rinse_spin" }
}

// From the model JSON and the LG app, several codes to one state as upstream reads them: 27, 28
// and 29 are FROZEN_PREVENT_*, 35 AUTO_DT_OPEN_PAUSE, 37 and 40 clothing recognition and pollution
// detecting, 38 and 39 detergent and softener input, 42 END_REMOTE_MAINTAIN_ON, 47 and 57 Fresh
// Keeper and wrinkle care (which the LG app shows as completed), 48 EZDISPENSE_CLEANING and 49
// END_WAITING. 34 (audible diagnosis) and 36 (confirm start) are left out.
fn states() {
    #{ "0": "off", "1": "standby", "27": "standby", "2": "paused", "28": "paused", "35": "paused",
       "3": "detecting", "37": "detecting", "40": "detecting", "5": "filling", "6": "detergent_amount",
       "7": "delayed", "8": "soaking", "9": "pre_wash", "11": "washing", "29": "washing",
       "38": "washing", "12": "rinsing", "39": "rinsing", "13": "rinse_hold", "14": "spinning",
       "15": "drying", "16": "end", "42": "end", "21": "refreshing", "47": "refreshing",
       "57": "refreshing", "23": "error", "41": "drum_clean", "43": "steam", "48": "cleaning",
       "49": "waiting" }
}

fn soil_levels() { #{ "1": "light", "3": "medium", "5": "heavy" } }

fn descriptor(ctx) {
    let status = t::options(states());
    status.push("running");
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer", vendor: "LG",
                      model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", class: "running", label: "Powered on" },
        status: #{ type: "select", options: status },
        course: #{ type: "select", options: t::options(courses()) },
        temp: #{ type: "select", label: "Water temperature", options: t::options(w::temps()) },
        spin: #{ type: "select", options: t::options(w::spins()) },
        soil: #{ type: "select", label: "Soil level", options: t::options(soil_levels()) },
        rinse: #{ type: "select", options: t::options(w::rinses()) },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Cycle energy" },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle length" },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        door: #{ type: "binary", class: "door", label: "Door open" },
        detergent_dispenser: #{ type: "binary" },
        softener_dispenser: #{ type: "binary" },
        detergent_dose: #{ type: "number", unit: "ml" },
        softener_dose: #{ type: "number", unit: "ml" },
        pre_wash: #{ type: "binary" },
        turbo_wash: #{ type: "binary" },
        steam: #{ type: "binary" },
        child_lock: #{ type: "binary", category: "diagnostic" },
        remote_start: #{ type: "binary", category: "diagnostic", label: "Remote start armed at the panel" },
        cycles: #{ type: "number", category: "diagnostic", label: "Washes since Drum Clean" }
    } })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let s = c::enveloped_status(data, 0x20, 64);
    if s != () { status(ctx, s.extract(1, 63)); return; }
    let b = c::inner(data, 0x20);
    if b == () || b.len() < 6 { return; }
    switch b[3] {
        0x88 => {
            il::publish_property(ctx, "available", "true");
            il::publish_property(ctx, "power", "true");
        }
        0x41 => {
            if b.len() <= 18 { return; }
            if b[18] == 0x01 { il::publish_property(ctx, "door", "true"); }
            if b[18] == 0x02 { il::publish_property(ctx, "door", "false"); }
        }
    }
}

fn status(ctx, r) {
    il::publish_property(ctx, "available", "true");
    c::pub_name(ctx, "status", t::name(states(), r[20]));
    if r[20] == 0 {
        il::publish_property(ctx, "power", "false");
        il::publish_property(ctx, "remaining_time", "0");
        il::publish_property(ctx, "initial_time", "0");
    } else {
        il::publish_property(ctx, "power", "true");
        c::pub_name(ctx, "soil", t::name(soil_levels(), r[0]));
        c::pub_name(ctx, "rinse", t::name(w::rinses(), r[26]));
        c::pub_name(ctx, "temp", t::name(w::temps(), r[1] + 1));
        c::pub_name(ctx, "spin", t::name(w::spins(), r[3] + 1));
        c::pub_name(ctx, "course", t::name(courses(), r[4]));
        il::publish_property(ctx, "remaining_time", r[13].to_string());
        il::publish_property(ctx, "initial_time", r[15].to_string());
        il::publish_property(ctx, "energy", (r[16] * 256 + r[17]).to_string());
        il::publish_property(ctx, "detergent_dispenser", if r[29] == 0x02 { "true" } else { "false" });
        il::publish_property(ctx, "softener_dispenser", if r[30] == 0x02 { "true" } else { "false" });
        il::publish_property(ctx, "detergent_dose", r[31].to_string());
        il::publish_property(ctx, "softener_dose", r[32].to_string());
        il::publish_property(ctx, "pre_wash", c::bit(r[33], 0x40));
        il::publish_property(ctx, "turbo_wash", c::bit(r[33], 0x20));
        il::publish_property(ctx, "steam", c::bit(r[34], 0x10));
    }
    il::publish_property(ctx, "child_lock", c::bit(r[36], 0x20));
    il::publish_property(ctx, "remote_start", c::bit(r[36], 0x10));
    il::publish_property(ctx, "cycles", r[27].to_string());
}

fn set_property(ctx, prop, value) { c::reject(ctx, prop, "read-only appliance"); }

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
