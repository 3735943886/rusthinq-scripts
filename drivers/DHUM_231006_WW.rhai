// Port of anszom/rethink PR #113, 1419bf64e130f9c1268297221b62869b75ae383c.
// Captures: tests/cloud/devices/DHUM_231006_WW.test.ts at that revision.
// Temperature, tank and error tags follow the owner's live rethink driver, which shares the
// DHUM_056905_WW map: this unit reports 0x1fd, 0x186 and 0x221 in its initial response.
// 0x1fd is taken as half-degrees on one cloud comparison (58 against LG's 29.0 degC at the same
// moment) and the convention the TS driver and ac_common use; like the TS driver, it is read
// unsigned. tank_full follows 0x186 states 1 / 2 as DHUM_056905_WW.rhai does; those codes come
// from the platform modelJSON, and only 0 has been seen on this unit. The 0x2b1 / 0x2b2 tank
// events the TS driver uses appear in no capture of this unit, but are handled the same way.
import "tlv_fields_common";
fn identity() { #{"kind": "humidifier", "class": "dehumidifier", "label": "Dehumidifier"} }
fn fields() {
    #{
        "power": #{ "tag": 503, "def": #{ "type": "binary", "rw": true, "role": "on" } },
        "mode": #{
            "tag": 505,
            "def": #{ "type": "select", "rw": true, "role": "mode" },
            "table": #{ "86": "smart_plus", "19": "silent", "20": "intensive", "85": "quick" },
            "power_on": true,
            "attach": [503]
        },
        "fan": #{
            "tag": 506,
            "def": #{ "type": "select", "rw": true, "role": "fan_speed" },
            "table": #{ "8": "auto", "2": "low", "4": "medium", "6": "high", "7": "turbo" }
        },
        "humidity": #{
            "tag": 822,
            "def": #{ "type": "number", "unit": "%", "role": "current_humidity", "class": "humidity" }
        },
        "target": #{
            "tag": 595,
            "def": #{
                "type": "number",
                "rw": true,
                "min": 30,
                "max": 70,
                "step": 1,
                "unit": "%",
                "role": "target_humidity"
            },
            "power_on": true,
            "attach": [503, 505]
        },
        "sterilize": #{ "tag": 864, "def": #{ "type": "binary", "rw": true }, "attach": [503, 505] },
        "uvnano": #{ "tag": 674, "def": #{ "type": "binary", "rw": true }, "attach": [503, 505] },
        "bucket_light": #{ "tag": 542, "def": #{ "type": "binary", "rw": true } },
        "off_timer": #{
            "tag": 539,
            "def": #{ "type": "number", "rw": true, "min": 0, "max": 540, "step": 60, "unit": "min", "class": "duration" }
        },
        "temperature": #{
            "tag": 509,
            "def": #{ "type": "number", "unit": "°C", "role": "current_temperature" },
            "scale": 2
        },
        "tank_state": #{
            "tag": 390,
            "def": #{ "type": "select", "category": "diagnostic" },
            "table": #{ "0": "not_full", "1": "full_stopped", "2": "full_fan_mode" }
        },
        "error": #{ "tag": 545, "def": #{ "type": "number", "category": "diagnostic" } }
    }
}
fn extra_props() { #{ tank_full: #{ type: "binary", class: "problem" } } }
fn apply_extra(ctx, tag, value) {
 if tag == 0x186 && value >= 0 && value <= 2 { il::publish_property(ctx, "tank_full", c::flag(value)); }
 if tag == 0x2b1 && value == 256 { il::publish_property(ctx, "tank_full", "false"); }
 if tag == 0x2b2 { il::publish_property(ctx, "tank_full", c::flag(value)); }
}
// The first captured packet combines capability rows and live state.
fn receive_frame(ctx, data) {
 let tlvs = tlv_frame_parse(data); if tlvs == () { return (); }
 let tags = tlvs.map(|e| e.t);
 if [0x1f7,0x1f9,0x1fa,0x2d7,0x2d8,0x2d9].all(|tag| tags.contains(tag)) {
  if !c::is_set(ctx,"caps") {ctx.state_set("caps", true);ctx.cancel_timer("caps_retry");c::query(ctx,2);}
  let first = !c::is_set(ctx, "values"); ctx.state_set("values", true);
  ctx.cancel_timer("values_retry"); ctx.set_timer("refresh", c::refresh_ms());
  return #{ tlvs: tlvs, caps: false, first: first };
 }
 c::receive(ctx, data, 1, [0x1f7,0x1f9,0x1fa,0x1fd,0x21b,0x21e,0x253,0x2a2,0x2b2,0x336,0x360])
}
fn after_frame(ctx, frame) {
 if frame.first { ctx.send_clip("setMaskingInfo", 0, "{\"blacklist_tlv\":\"1200\"}"); }
}
fn write_extra(ctx, prop, value) {
 if prop == "power" { let on = c::to_bool(value); c::write(ctx,0x1f7,if on {1} else {0},if on {[0x1f9]} else {[]}); return true; }
 false
}
