// Port of anszom/rethink PR #169, a8a9c64795163182e3351af61a3ef4234ac848e3.
// Captures: tests/cloud/devices/1WPD6CMIDR__3.test.ts at that revision.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;
fn fields() {
    #{
        "last_water_type": #{
            "def": #{
                "type": "select",
                "options": ["hot_water", "normal_water", "cold_water", "sterilization_water", "ice"],
                "rw": false
            },
            "offset": 22,
            "write": (),
            "table": #{ "1": "hot_water", "2": "normal_water", "3": "cold_water", "4": "sterilization_water", "5": "ice" }
        },
        "cock_state": #{
            "def": #{ "type": "select", "options": ["off", "on", "cock_manual_on"], "rw": false },
            "offset": 140,
            "write": (),
            "table": #{ "0": "off", "1": "on", "2": "cock_manual_on" }
        },
        "ice_status": #{
            "def": #{
                "type": "select",
                "options": ["waiting", "drying_icedisable", "drying_iceenable", "making", "full", "ice_enough"],
                "rw": false
            },
            "offset": 255,
            "write": (),
            "table": #{
                "0": "waiting",
                "1": "drying_icedisable",
                "2": "drying_iceenable",
                "3": "making",
                "4": "full",
                "5": "ice_enough"
            }
        },
        "sterilize_state": #{
            "def": #{
                "type": "select",
                "options": ["off", "auto_dwp_a_type", "auto_dwp_b_type", "manual_dwp_a_type", "flush", "care_cancel"],
                "rw": false
            },
            "offset": 162,
            "write": (),
            "table": #{
                "0": "off",
                "1": "auto_dwp_a_type",
                "2": "auto_dwp_b_type",
                "3": "manual_dwp_a_type",
                "4": "flush",
                "5": "care_cancel"
            }
        },
        "default_water_type": #{
            "def": #{ "type": "select", "options": ["recent_water", "normal_water", "cold_water"], "rw": true },
            "offset": 149,
            "write": 12,
            "table": #{ "1": "recent_water", "2": "normal_water", "3": "cold_water" }
        },
        "default_water_amount": #{
            "def": #{
                "type": "select",
                "options": ["preset_120ml", "preset_250ml", "preset_500ml", "preset_1000ml", "last_used"],
                "rw": true
            },
            "offset": 150,
            "write": 13,
            "table": #{
                "1": "preset_120ml",
                "2": "preset_250ml",
                "3": "preset_500ml",
                "4": "preset_1000ml",
                "5": "last_used"
            }
        },
        "lever_dispensing_type": #{
            "def": #{ "type": "select", "options": ["pressing", "click"], "rw": true },
            "offset": 263,
            "write": 126,
            "table": #{ "0": "pressing", "1": "click" }
        },
        "default_hot_water_temp": #{
            "def": #{ "type": "select", "options": ["40", "70", "90"], "rw": true },
            "offset": 229,
            "write": 92,
            "table": #{ "1": "40", "2": "70", "3": "90" }
        },
        "hot_water_lock": #{ "def": #{ "type": "binary", "rw": true }, "offset": 165, "write": 28, "invert": true },
        "ice_lock": #{ "def": #{ "type": "binary", "rw": true }, "offset": 250, "write": 113, "invert": false },
        "ice_lever": #{ "def": #{ "type": "binary", "rw": true }, "offset": 251, "write": 114, "invert": false },
        "ice_first_mode": #{ "def": #{ "type": "binary", "rw": true }, "offset": 258, "write": 121, "invert": false },
        "child_lock": #{ "def": #{ "type": "binary", "rw": false }, "offset": 254, "write": (), "invert": false },
        "cold_water_enabled": #{ "def": #{ "type": "binary", "rw": true }, "offset": 256, "write": 119, "invert": false },
        "dnd_mode": #{ "def": #{ "type": "binary", "rw": true }, "offset": 222, "write": 85, "invert": false },
        "dnd_ice_mode": #{ "def": #{ "type": "binary", "rw": true }, "offset": 264, "write": 127, "invert": false },
        "ice_maker": #{ "def": #{ "type": "binary", "rw": false }, "offset": 249, "write": (), "invert": false },
        "product_sound": #{ "def": #{ "type": "binary", "rw": true }, "offset": 257, "write": 120, "invert": false },
        "button_sound": #{ "def": #{ "type": "binary", "rw": true }, "offset": 151, "write": 14, "invert": false },
        "voice_guidance": #{ "def": #{ "type": "binary", "rw": true }, "offset": 152, "write": 15, "invert": false },
        "dnd_start_hour": #{
            "def": #{ "type": "number", "rw": true, "min": 0, "max": 23, "step": 1 },
            "offset": 223,
            "write": 86
        },
        "dnd_end_hour": #{
            "def": #{ "type": "number", "rw": true, "min": 0, "max": 23, "step": 1 },
            "offset": 225,
            "write": 88
        },
        "display_dimming_min": #{
            "def": #{ "type": "number", "rw": true, "min": 1, "max": 30, "step": 1 },
            "offset": 261,
            "write": 124
        },
        "display_off_min": #{
            "def": #{ "type": "number", "rw": true, "min": 1, "max": 30, "step": 1 },
            "offset": 262,
            "write": 125
        },
        "display_brightness": #{
            "def": #{ "type": "select", "rw": true, "options": ["20", "40", "60", "80", "100"] },
            "offset": 252,
            "write": 115
        },
        "voice_volume": #{
            "def": #{ "type": "select", "rw": true, "options": ["20", "40", "60", "80", "100"] },
            "offset": 153,
            "write": 16
        }
    }
}

fn descriptor(ctx) {
 let props=#{available:#{type:"binary",role:"available"},
 dispense_state:#{type:"select",options:["idle","preparing","dispensing"]},dispensing:#{type:"binary"},
 hot_water_amount:#{type:"number",unit:"mL"},cold_water_amount:#{type:"number",unit:"mL"},normal_water_amount:#{type:"number",unit:"mL"},
 hot_water_temp:#{type:"number",unit:"°C"},sterilizing:#{type:"binary"},
 time_format:#{type:"select",rw:true,options:["12","24"]},display_mode:#{type:"select",rw:true,options:["always_on","waiting_screen_clock","off"]}};
 for prop in fields().keys() { props[prop]=fields()[prop].def; }
 json_stringify(#{il:0,kind:"dispenser",class:"water_purifier",label:"Water purifier",vendor:"LG",model:ctx.model_id(),props:props})
}
fn on_data(ctx,data) {
 let b=aabb_unwrap(data); if b==() {return;}
 if b.len()==266 {
  for prop in fields().keys() {
   if prop=="last_water_type" {continue;}
   let f=fields()[prop]; let v=b[f.offset];
   if f.table!=() {c::pub_name(ctx,prop,t::name(f.table,v));}
   else if f.def.type=="binary" {il::publish_property(ctx,prop,c::on_off(if f.invert==true {if v==0 {1} else {0}} else {v}));}
   else if v!=255 {il::publish_property(ctx,prop,v.to_string());}
  }
  let sterilize=b[162]; if fields().sterilize_state.table.contains(sterilize.to_string()) {il::publish_property(ctx,"sterilizing",c::bit(sterilize,255));}
  il::publish_property(ctx,"time_format",if b[253]==1 {"24"} else {"12"});
  il::publish_property(ctx,"display_mode",if b[259]==1 {"always_on"} else if b[260]==1 {"waiting_screen_clock"} else {"off"});
  if b[145]==255 {il::publish_absent(ctx,"hot_water_temp");} else {il::publish_property(ctx,"hot_water_temp",b[145].to_string());}
  return;
 }
 if b.len()<=12 || 12+b[10]>b.len() {return;}
 let state=b.extract(0,12)+b.extract(12+b[10]);
 if state.len()!=330 {return;}
 c::pub_name(ctx,"last_water_type",t::name(fields().last_water_type.table,state[22]));
 let preparing=false; let dispensing=false;
 let names=["hot_water_amount","cold_water_amount","normal_water_amount"];
 let offsets=[47,45,43];
 for i in 0..3 {
  let v=state[offsets[i]];
  if v==2 {preparing=true;v=0;}
  if v>0 {dispensing=true;}
  il::publish_property(ctx,names[i],v.to_string());
 }
 il::publish_property(ctx,"dispensing",if dispensing {"true"} else {"false"});
 il::publish_property(ctx,"dispense_state",if dispensing {"dispensing"} else if preparing {"preparing"} else {"idle"});
}
fn set_property(ctx,prop,value) {
 let out=[0xf0,0x17]; for i in 2..145 {out.push(255);}
 if prop=="display_mode" {
  let pair=switch value {"always_on"=>[0,1],"waiting_screen_clock"=>[1,0],_=>[0,0]};
  out[122]=pair[0];out[123]=pair[1];
 } else if prop=="time_format" {out[116]=if value=="24" {1} else {0};}
 else {
  let f=fields()[prop]; if f==() || f.write==() {c::reject(ctx,prop,"read-only property");return;}
  let v=if f.table!=() {t::code(f.table,value)} else if f.def.type=="binary" {if c::to_bool(value) {1} else {0}} else {value.parse_float().to_int()};
  if f.invert==true {v=1-v;}
  out[f.write]=v;
 }
 ctx.send_raw(aabb_wrap(out));
}
fn publish_config(ctx) { il::publish_il(ctx,descriptor(ctx)); }
fn on_drop(ctx) { il::publish_property(ctx,"available","false"); }
fn on_set_property(ctx,prop,value) {
 if ctx.state_get("__il_descriptor")==() {publish_config(ctx);}
 let value=il::validate(ctx,prop,value);
 if value!=() { set_property(ctx,prop,value); }
}
