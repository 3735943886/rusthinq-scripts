// Port of anszom/rethink PR #114, 5898c3b6c2407c71281d8ef6e6caffb036a82b22.
// Captures: tests/cloud/devices/HUM_056905_WW.test.ts at that revision.
import "tlv_fields_common";
fn identity() { #{"kind": "humidifier", "label": "Humidifying air purifier"} }
fn fields() {
    #{
        "power": #{ "tag": 503, "def": #{ "type": "binary", "rw": true, "role": "on" } },
        "mode": #{
            "tag": 505,
            "def": #{ "type": "select", "rw": true, "role": "mode" },
            "table": #{ "5": "air_clean", "12": "humidify_clean", "24": "humidify" },
            "power_on": true,
            "attach": [503]
        },
        "target": #{
            "tag": 595,
            "def": #{
                "type": "number",
                "rw": true,
                "min": 0,
                "max": 100,
                "step": 1,
                "unit": "%",
                "role": "target_humidity"
            }
        },
        "humidity": #{
            "tag": 822,
            "def": #{ "type": "number", "unit": "%", "role": "current_humidity", "class": "humidity" }
        },
        "fan": #{
            "tag": 506,
            "def": #{ "type": "select", "rw": true, "role": "fan_speed" },
            "table": #{ "8": "auto", "2": "low", "4": "medium", "6": "high", "7": "turbo" }
        },
        "hygiene_dry": #{
            "tag": 489,
            "def": #{ "type": "select", "rw": true },
            "table": #{ "0": "off", "1": "gentle", "2": "quiet", "3": "quick", "4": "focus", "5": "default" }
        },
        "standby_sterilize": #{
            "tag": 356,
            "def": #{ "type": "select", "rw": true },
            "table": #{ "0": "rapid", "1": "normal", "2": "silent", "3": "power" }
        },
        "display": #{
            "tag": 543,
            "def": #{ "type": "select", "rw": true },
            "table": #{ "0": "off", "8": "level_1", "9": "level_2", "10": "level_3" }
        },
        "mood_color": #{
            "tag": 992,
            "def": #{ "type": "select", "rw": true },
            "table": #{
                "1": "blue",
                "2": "green",
                "3": "red",
                "4": "purple",
                "6": "yellow",
                "7": "pink",
                "8": "pure_white",
                "9": "aquarium",
                "10": "candlelight",
                "11": "sunlight",
                "12": "rose",
                "13": "mint",
                "14": "lime",
                "15": "very_peri",
                "16": "warm_white",
                "17": "cool_white",
                "18": "sapphire",
                "19": "rainbow"
            }
        },
        "temperature": #{ "tag": 509, "def": #{ "type": "number", "unit": "°C", "class": "temperature" }, "scale": 2 },
        "status": #{
            "tag": 483,
            "def": #{ "type": "select" },
            "table": #{
                "0": "normal",
                "1": "no_tank",
                "2": "low_water",
                "3": "sterilizing",
                "4": "drying",
                "5": "boiling",
                "6": "boiling_low"
            }
        },
        "off_timer": #{
            "tag": 539,
            "def": #{ "type": "number", "rw": true, "min": 0, "max": 720, "step": 15, "unit": "min", "class": "duration" }
        },
        "night_mode": #{ "tag": 265, "def": #{ "type": "binary", "rw": true }, "exact_one": true },
        "sleep_mode": #{ "tag": 484, "def": #{ "type": "binary", "rw": true }, "exact_one": true },
        "auto_strength": #{ "tag": 486, "def": #{ "type": "binary", "rw": true }, "exact_one": true },
        "humidify": #{ "tag": 487, "def": #{ "type": "binary", "rw": true }, "exact_one": true },
        "anti_glare": #{ "tag": 353, "def": #{ "type": "binary", "rw": true }, "exact_one": true },
        "mood_light": #{ "tag": 440, "def": #{ "type": "binary", "rw": true }, "exact_one": true },
        "bell_sound": #{ "tag": 928, "def": #{ "type": "binary", "rw": true }, "exact_one": true },
        "pm1": #{ "tag": 819, "def": #{ "type": "number", "unit": "µg/m³" } },
        "pm25": #{ "tag": 820, "def": #{ "type": "number", "unit": "µg/m³" } },
        "pm10": #{ "tag": 821, "def": #{ "type": "number", "unit": "µg/m³" } },
        "watertank_remain": #{ "tag": 494, "def": #{ "type": "number", "unit": "%" } },
        "watertank_time": #{ "tag": 685, "def": #{ "type": "number", "unit": "min" } },
        "water_filter": #{ "tag": 493, "def": #{ "type": "number", "unit": "%" } },
        "filter_used_time": #{ "tag": 853, "def": #{ "type": "number", "unit": "h" } },
        "filter_life_time": #{ "tag": 854, "def": #{ "type": "number", "unit": "h" } },
        "autodry_remain": #{ "tag": 549, "def": #{ "type": "number", "unit": "%" } }
    }
}
// HUM capabilities use 0x3e8, rather than 0x2da.
fn receive_frame(ctx, data) {
 let tlvs = tlv_frame_parse(data); if tlvs == () { return (); }
 let caps = tlvs.some(|e| e.t == 0x3e8);
 if caps && !c::is_set(ctx, "caps") {
  ctx.state_set("caps", true); ctx.cancel_timer("caps_retry");
  c::query(ctx, 2); ctx.set_timer("values_retry", c::retry_ms());
 }
 let first = !caps && c::is_set(ctx, "caps") && !c::is_set(ctx, "values") && tlvs.some(|e| [0x1f7,0x1f9,0x1fa].contains(e.t));
 if first { ctx.state_set("values", true); ctx.cancel_timer("values_retry"); ctx.set_timer("refresh", c::refresh_ms()); }
 #{ tlvs: tlvs, caps: caps, first: first }
}

fn write_extra(ctx, prop, value) {
 if prop=="target" {let v=c::to_number(value);c::write(ctx,0x253,(v/5.0).round().to_int()*5,[]);return true;}
 false
}
