// Port of anszom/rethink PR #170, 7109e55b741593f7ff0e411c38d28cf795a2cbe8.
// Captures: tests/cloud/devices/PAC_910604_WW.test.ts at that revision.
import "tlv_fields_common";
fn identity() { #{"kind": "climate", "class": "air_conditioner", "label": "Floor-standing air conditioner"} }
fn fields() {
    #{
        "power": #{ "tag": 503, "def": #{ "type": "binary", "rw": true, "role": "on" } },
        "mode": #{
            "tag": 505,
            "def": #{ "type": "select", "rw": true, "role": "mode" },
            "table": #{ "0": "cool", "1": "dry" },
            "power_on": true,
            "attach": [503, 506, 510]
        },
        "fan": #{
            "tag": 506,
            "def": #{ "type": "select", "rw": true, "role": "fan_speed" },
            "table": #{ "8": "auto", "2": "low", "4": "medium", "6": "high", "7": "turbo", "9": "max" }
        },
        "target": #{
            "tag": 510,
            "def": #{
                "type": "number",
                "rw": true,
                "min": 18,
                "max": 30,
                "step": 1,
                "unit": "°C",
                "role": "target_temperature"
            },
            "scale": 2,
            "attach": [505, 506]
        },
        "temperature": #{ "tag": 509, "def": #{ "type": "number", "unit": "°C", "role": "current_temperature" }, "scale": 2 },
        "swing_v": #{ "tag": 517, "def": #{ "type": "select", "rw": true }, "table": #{ "0": "off", "1": "on" } },
        "swing_h": #{
            "tag": 518,
            "def": #{ "type": "select", "rw": true },
            "table": #{ "0": "off", "1": "right", "256": "left", "257": "both" }
        },
        "human_sense": #{
            "tag": 520,
            "def": #{ "type": "select", "rw": true },
            "table": #{ "0": "off", "1": "direct", "2": "indirect" }
        },
        "air_quality": #{
            "tag": 576,
            "def": #{ "type": "select" },
            "table": #{ "1": "good", "2": "moderate", "3": "bad", "4": "very_bad" }
        },
        "smartguide": #{ "tag": 575, "def": #{ "type": "binary" } },
        "autodry": #{ "tag": 526, "def": #{ "type": "binary" } },
        "eco": #{ "tag": 525, "def": #{ "type": "binary", "rw": true } },
        "airclean": #{ "tag": 527, "def": #{ "type": "binary", "rw": true } },
        "smartcare": #{ "tag": 574, "def": #{ "type": "binary", "rw": true } },
        "sleep_timer": #{
            "tag": 538,
            "def": #{ "type": "number", "rw": true, "min": 0, "max": 420, "step": 10, "unit": "min" }
        },
        "start_timer": #{
            "tag": 540,
            "def": #{ "type": "number", "rw": true, "min": 0, "max": 1440, "step": 60, "unit": "min" }
        },
        "stop_timer": #{
            "tag": 539,
            "def": #{ "type": "number", "rw": true, "min": 0, "max": 1440, "step": 60, "unit": "min" }
        },
        "pm1": #{ "tag": 819, "def": #{ "type": "number", "unit": "µg/m³" } },
        "pm25": #{ "tag": 820, "def": #{ "type": "number", "unit": "µg/m³" } },
        "pm10": #{ "tag": 821, "def": #{ "type": "number", "unit": "µg/m³" } },
        "humidity": #{ "tag": 822, "def": #{ "type": "number", "unit": "%" } },
        "dry_remain": #{ "tag": 549, "def": #{ "type": "number", "unit": "min" } },
        "power_draw": #{ "tag": 691, "def": #{ "type": "number", "unit": "W" } },
        "error": #{ "tag": 545, "def": #{ "type": "number" } }
    }
}
// This exact model is passive: no handshake, masking or polling.
fn passive() { true }
fn receive_frame(ctx, data) {
 let tlvs = tlv_frame_parse(data);
 if tlvs == () { return (); }
 // Cache the complete frame before deriving values that depend on other tags.
 for e in tlvs { if [0x1f7,0x1f9,0x1fa,0x1fe,0x236,0x209,0x355,0x356].contains(e.t) { c::put(ctx,e.t,e.v); } }
 #{ tlvs: tlvs, caps: false, first: false }
}
fn extra_props() {
 #{ wind_mode: #{ type: "select", rw: true, options: ["off","coolpower","longpower"] },
 filter_used_time: #{ type: "number", unit: "h", category: "diagnostic" },
 filter_life_time: #{ type: "number", unit: "h", category: "diagnostic" },
 filter_remaining: #{ type: "number", unit: "h", category: "diagnostic" } }
}
fn apply_extra(ctx,tag,v) {
 if tag == 0x1fa {
  let level = v & 0xff; if level == 0xff { level = (v >> 8) & 0xff; }
  let name = t::name(fields().fan.table,level);
  if name != () { il::publish_property(ctx,"fan",name); }
 }
 if tag == 0x236 || tag == 0x209 {
  il::publish_property(ctx,"wind_mode",if c::get(ctx,0x236)!=0 {"coolpower"} else if c::get(ctx,0x209)!=0 {"longpower"} else {"off"});
 }
 if tag == 0x355 || tag == 0x356 {
  let used = ctx.state_get("t853"); let life = ctx.state_get("t854");
  if used != () && life != () && life > 0 {
   il::publish_property(ctx,"filter_used_time",used.to_string());
   il::publish_property(ctx,"filter_life_time",life.to_string());
   il::publish_property(ctx,"filter_remaining",(if life>used {life-used} else {0}).to_string());
  }
 }
}
fn write_extra(ctx,prop,value) {
 if prop=="power" { let on=c::to_bool(value); c::write(ctx,0x1f7,if on {1} else {0},if on {[0x1f9,0x1fa,0x1fe]} else {[]}); return true; }
 if prop=="fan" { let code=t::code(fields().fan.table,value); c::put(ctx,0x1f7,1); c::write(ctx,0x1fa,code*257,[0x1f7,0x1f9,0x1fe]); return true; }
 if prop=="wind_mode" {
  if value=="coolpower" { c::write(ctx,0x236,1,[]); }
  else {
   let mode=ctx.state_get("t505"); let target=ctx.state_get("t510");
   if mode==() || target==() { c::reject(ctx,prop,"mode and target unknown"); return true; }
   let fan=if value=="longpower" {2313} else {1542};
   c::put(ctx,0x1fa,fan);
   ctx.send_raw(tlv_frame_build(c::write_header(),[#{t:0x1f9,v:mode},#{t:0x1fa,v:fan},#{t:0x1fe,v:target}]));
  }
  return true;
 }
 false
}
