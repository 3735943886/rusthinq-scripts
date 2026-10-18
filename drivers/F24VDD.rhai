// Port of anszom/rethink PR #180, 5c0acfd8ec17f2aee451572a64d686f49d06f2fb.
// Captures: tests/cloud/devices/F24VDD.test.ts at that revision.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;
import "washer_f24_legacy_common" as legacy;
fn courses() {
    #{
        "0": "none",
        "1": "steam_refresh",
        "2": "allergy_care",
        "3": "functional_wear",
        "4": "economy_boil",
        "5": "baby_wear",
        "6": "heavy_duty",
        "7": "cotton",
        "8": "speed_wash",
        "9": "quiet",
        "10": "colour_care",
        "11": "duvet",
        "12": "lingerie_wool",
        "13": "rinse_spin",
        "14": "downloaded_course",
        "15": "tub_clean"
    }
}
fn states() {
    #{
        "0": "off",
        "5": "initial",
        "6": "paused",
        "7": "error_auto_off",
        "10": "reserved",
        "20": "sensing",
        "21": "draining",
        "22": "detergent_dosing",
        "23": "washing",
        "24": "pre_wash",
        "30": "rinsing",
        "31": "rinse_hold",
        "40": "spinning",
        "50": "drying",
        "60": "complete",
        "61": "refreshing",
        "83": "freeze_protection_initial",
        "84": "freeze_protection_running",
        "85": "freeze_protection_paused",
        "101": "audible_diagnosis"
    }
}
fn templates() {
    #{
        "1": "f026010200000000003000200100000000000000000000",
        "2": "f026020203000403003000200200000000000000000000",
        "3": "f026030201000303003000200300000000000000000000",
        "4": "f026040203050303002000200d00000000000000000000",
        "5": "f026050203000404003000200b00000000000000000000",
        "6": "f026060303040304002000200e00000000000000000000",
        "7": "f026070201040100002080200500000000000000000000",
        "8": "f026080203000103003080200400000000000000000000",
        "9": "f026090202030403002000200700000000000000000000",
        "10": "f0260a0202020303002000201000000000000000000000",
        "11": "f0260b0203010403002000200900000000000000000000",
        "12": "f0260c0202010304002000200800000000000000000000",
        "13": "f0260d0003000103002000201100000000000000000000",
        "15": "f0260f0203040203002000200a00000000000000000000"
    }
}
fn course_options() {
    #{
        "1": "steam_refresh",
        "2": "allergy_care",
        "3": "functional_wear",
        "4": "economy_boil",
        "5": "baby_wear",
        "6": "heavy_duty",
        "7": "cotton",
        "8": "speed_wash",
        "9": "quiet",
        "10": "colour_care",
        "11": "duvet",
        "12": "lingerie_wool",
        "13": "rinse_spin",
        "15": "tub_clean",
        "14": "downloaded_course"
    }
}
fn downloads() {
    #{
        "cold_wash": "f02503150e0204010300000000000f33000000000000000000",
        "small_load": "f02503150e0203000200001080000434000000000000000000",
        "skin_care": "f02503150e0204030400000080000535000000000000000000",
        "rainy_day": "f02503150e0205030200000080000536000000000000000000",
        "sweat_stain": "f02503150e0303030300000000000e37000000000000000000",
        "single_garments": "f02503150e0203000100001080000438000000000000000000",
        "kids_wear": "f02503150e0303040400000000000e39000000000000000000",
        "shirt": "f02503150e0302040300000000000e3a000000000000000000",
        "school_uniform": "f02503150e020303020000008000053b000000000000000000",
        "static_reduce": "f02503150e020000000000100000013c000000000000000000",
        "spin_only": "f02503150e000300000000000000153f000000000000000000",
        "deodorization": "f02503150e0200000000001000000141000000000000000000",
        "cloth_care": "f02503150e0202030300000000000843000000000000000000",
        "smart_rinse": "f02503150e0204030400000080000544000000000000000000"
    }
}
fn spins() { #{"0": "no_spin", "1": "very_low", "2": "low", "3": "medium", "4": "high", "5": "extra_high"} }
fn temperatures() { #{"0": "none", "1": "cold", "2": "30", "3": "40", "4": "60", "5": "95"} }
fn smart_ids() {
    #{
        "51": "cold_wash",
        "52": "small_load",
        "53": "skin_care",
        "54": "rainy_day",
        "55": "sweat_stain",
        "56": "single_garments",
        "57": "kids_wear",
        "58": "shirt",
        "59": "school_uniform",
        "60": "static_reduce",
        "63": "spin_only",
        "65": "deodorization",
        "67": "cloth_care",
        "68": "smart_rinse"
    }
}
fn smart_starts() {
    #{
        "cold_wash": "f0260e0204010300002000200f33000000000000000000",
        "small_load": "f0260e0203000200003080200434000000000000000000",
        "skin_care": "f0260e0204030400002080200535000000000000000000",
        "rainy_day": "f0260e0205030200002080200536000000000000000000",
        "sweat_stain": "f0260e0303030300002000200e37000000000000000000",
        "single_garments": "f0260e0203000100003080200438000000000000000000",
        "kids_wear": "f0260e0303040400002000200e39000000000000000000",
        "shirt": "f0260e0302040300002000200e3a000000000000000000",
        "school_uniform": "f0260e020303020000208020053b000000000000000000",
        "static_reduce": "f0260e020000000000300020013c000000000000000000",
        "spin_only": "f0260e000300000000200020153f000000000000000000",
        "deodorization": "f0260e0200000000003000200141000000000000000000",
        "cloth_care": "f0260e0202030300002000200843000000000000000000",
        "smart_rinse": "f0260e0204030400002080200544000000000000000000"
    }
}
fn writable() {
    #{
        "2": #{ "rinse": [0, 1, 2, 3, 4, 5], "spin": [0, 1, 2, 3, 4, 5], "temp": [] },
        "3": #{ "rinse": [0, 1, 2, 3, 4, 5], "spin": [0, 1], "temp": [] },
        "4": #{ "rinse": [0, 1, 2, 3, 4, 5], "spin": [0, 1, 2, 3, 4, 5], "temp": [] },
        "5": #{ "rinse": [0, 1, 2, 3, 4, 5], "spin": [0, 1, 2, 3, 4, 5], "temp": [] },
        "6": #{ "rinse": [0, 1, 2, 3, 4, 5], "spin": [0, 1, 2, 3, 4, 5], "temp": [3, 4] },
        "7": #{ "rinse": [0, 1, 2, 3, 4, 5], "spin": [0, 1, 2, 3, 4, 5], "temp": [1, 2, 3, 4] },
        "8": #{ "rinse": [0, 1, 2, 3, 4, 5], "spin": [0, 1, 2, 3, 4, 5], "temp": [] },
        "9": #{ "rinse": [0, 1, 2, 3, 4, 5], "spin": [0, 1, 2, 3, 4, 5], "temp": [1, 2, 3, 4] },
        "10": #{ "rinse": [0, 1, 2, 3, 4, 5], "spin": [0, 1, 2, 3, 4, 5], "temp": [1, 2, 3] },
        "11": #{ "rinse": [0, 1, 2, 3, 4, 5], "spin": [0, 1, 2, 3], "temp": [1, 2, 3] },
        "12": #{ "rinse": [0, 1, 2, 3, 4, 5], "spin": [0, 1, 2], "temp": [1, 2, 3] },
        "13": #{ "rinse": [1, 2, 3, 4, 5], "spin": [1, 2, 3, 4, 5], "temp": [] },
        "15": #{ "rinse": [], "spin": [], "temp": [] }
    }
}
fn is_dryer() { false }

fn get(ctx,key,fallback) { let v=ctx.state_get("captured_"+key); if v==() {fallback} else {v} }
fn put(ctx,key,v) {ctx.state_set("captured_"+key,v);}
fn descriptor(ctx) {
 let props=base_props(ctx);
 // A different record length does not establish different remote-start permissions.
 props.course_select=#{type:"select",rw:true,options:t::options(course_options())};
 props.smart_course=#{type:"select",options:downloads().keys()};
 props.smart_course_select=#{type:"select",rw:true,options:downloads().keys()};
 props.reserve_hours=#{type:"number",rw:true,min:0,max:19,step:1,unit:"h"};
 props.resume=#{type:"trigger",requires:"remote_start"};
 props.start_course=#{type:"trigger",requires:"remote_start"};
 props.smart_diagnosis=#{type:"binary",category:"diagnostic"};
 if is_dryer() {
  props.dry_level_select=#{type:"select",rw:true,options:t::options(dry_levels())};
  props.eco_hybrid_select=#{type:"select",rw:true,options:t::options(eco_hybrids())};
  props.anti_crease_select=#{type:"binary",rw:true};
 } else {
  props.spin_select=#{type:"select",rw:true,options:t::options(spins())};
  props.temperature_select=#{type:"select",rw:true,options:["cold","30","40","60"]};
  props.rinse_count=#{type:"number",rw:true,min:0,max:5,step:1};
 }
 json_stringify(#{il:0,kind:if is_dryer() {"dryer"} else {"washer"},class:"washing_machine",label:if is_dryer() {"Dryer"} else {"Washer"},vendor:"LG",model:ctx.model_id(),props:props})
}
fn start(ctx) {ctx.send_raw(aabb_wrap(hex_decode("f0ed1121010000001800")));}
fn valid_checksum(data) {
 if data.len()<4 || data[0]!=0xaa || data[data.len()-1]!=0xbb {return false;}
 let sum=0; for i in 0..data.len()-2 {sum+=data[i];}
 data[data.len()-2]==((sum & 255)^0x55)
}
fn on_data(ctx,data) {
 if !valid_checksum(data) {return;}
 // These captures use byte-sum framing even when the length byte wraps to zero.
 let b=data.extract(2,data.len()-4);
 if b.len()<2 {return;}
 if b[0]!=(if is_dryer() {0x30} else {0x20}) {return;}
 if !is_dryer() {
  if b[1]==0x72 && b.len()==5 {il::publish_property(ctx,"remote_start",c::bit(b[3],1));return;}
  if b[1]==0xd8 && b.len()==3 {il::publish_property(ctx,"power",c::bit(b[2],255));return;}
  if (b[1]==0xcd && b.len()==405) || (b[1]==0xbd && [406,476].contains(b.len())) {
   // The user's app-checked 1941 Wh capture disproves the PR's low-byte read.
   let off=if b[1]==0xcd {35} else {36};
   il::publish_property(ctx,"energy",(b[off]*256+b[off+1]).to_string());return;
  }
 }
 let one=if is_dryer() {29} else {40};let two=if is_dryer() {56} else {78};
 let p=if b[1]==0xeb && b.len()==one {3} else if b[1]==0xec && b.len()==two {if is_dryer() {30} else {41}} else {legacy_data(ctx,data);return;};
 if b[p]!=(if is_dryer() {0x19} else {0x24}) {return;}
 if !get(ctx,"protocol",false) {put(ctx,"protocol",true);publish_config(ctx);}
 let state=b[p+1];let course=b[p+6];let error=b[p+7];
 put(ctx,"state",state);
 il::publish_property(ctx,"power",c::bit(state,255));
 c::pub_name(ctx,"status",t::name(states(),state));
 c::pub_name(ctx,"course",t::name(courses(),course));
 il::publish_property(ctx,"error",c::bit(error,255));
 il::publish_property(ctx,"remaining_time",(b[p+2]*60+b[p+3]).to_string());
 il::publish_property(ctx,"initial_time",(b[p+4]*60+b[p+5]).to_string());
 let reserve=if is_dryer() {11} else {13};
 il::publish_property(ctx,"reserve_time",(b[p+reserve]*60+b[p+reserve+1]).to_string());
 decode_model(ctx,b,p);
 // The known 34-byte monitoring payload is the common prefix of these 36-byte
 // captures. Keep existing fields, flags, selection-following and 16-bit energy.
 let normal=[0x20,0xeb,0,34];
 for byte in b.extract(p+1,34) {normal.push(byte.to_int());}
 legacy::on_data(ctx,aabb_wrap(normal));
}
fn select_smart(ctx,name) {
 put(ctx,"smart",name);put(ctx,"downloaded",true);
 il::publish_property(ctx,"smart_course_select",name);il::publish_property(ctx,"course_select","downloaded_course");
}
fn set_property(ctx,prop,value) {
 if legacy_control(ctx,prop,value) {return;}
 put(ctx,"controls",true);
 if prop=="power_off" || prop=="pause" {ctx.send_raw(aabb_wrap([0xf0,0x24,if prop=="pause" {4} else {1},1,0]));return;}
 if prop=="course_select" {
  if value=="downloaded_course" {put(ctx,"downloaded",true);}
  else {let id=t::code(course_options(),value);put(ctx,"selected",id);put(ctx,"downloaded",false);course_defaults(ctx,id);}
  il::publish_property(ctx,prop,value);return;
 }
 if prop=="smart_course_select" {
  let body=downloads()[value];if body==() {return;}
  select_smart(ctx,value);ctx.send_raw(aabb_wrap(hex_decode(body)));
  if is_dryer() {il::publish_property(ctx,"smart_course",value);}
  return;
 }
 if prop=="reserve_hours" {
  let hours=value.parse_float().to_int();if hours!=0 && (hours<3 || hours>19) {c::reject(ctx,prop,"reservation is 0 or 3..19 hours");return;}
  put(ctx,"reserve",hours);il::publish_property(ctx,prop,hours.to_string());return;
 }
 if option_control(ctx,prop,value) {return;}
 if prop=="start" || prop=="start_course" || prop=="resume" {
  let body=build_start(ctx,prop=="resume" || (prop=="start" && ctx.state_get("state")==6));
  if body==() {c::reject(ctx,prop,"no captured command for this selection");return;}
  ctx.send_raw(aabb_wrap(body));return;
 }
 c::reject(ctx,prop,"read-only property");
}

fn base_props(ctx) {json_parse(legacy::descriptor(ctx)).props}
fn legacy_data(ctx,data) {legacy::on_data(ctx,data);}
fn legacy_control(ctx,prop,value) {
 // Core API keeps the existing presets and automatic paused-cycle resume.
 // PR option/download commands explicitly opt into the captured control builder.
 if get(ctx,"controls",false) || (prop=="course_select" && value=="downloaded_course") {return false;}
 if prop=="course_select" {let id=t::code(course_options(),value);put(ctx,"selected",id);put(ctx,"downloaded",value=="downloaded_course");}
 if ["course_select","start","power_off","pause"].contains(prop) {legacy::set_property(ctx,prop,value);return true;}
 false
}
fn decode_model(ctx,b,p) {
 il::publish_property(ctx,"child_lock",c::bit(b[p+15],8));
 il::publish_property(ctx,"steam",c::bit(b[p+15],0x10));
 il::publish_property(ctx,"turbo_shot",c::bit(b[p+16],0x80));
 il::publish_property(ctx,"smart_diagnosis",c::on_off(if b[p+1]==101 {1} else {0}));
 c::pub_name(ctx,"spin",t::name(spins(),b[p+9]));
 c::pub_name(ctx,"temp",t::name(temperatures(),b[p+10]));
 il::publish_property(ctx,"rinse",b[p+11].to_string());
 il::publish_property(ctx,"error_message",t::name(legacy::errors(),b[p+7]) ?? "Unknown error ("+b[p+7]+")");
 if b[p+6]==14 {put(ctx,"downloaded",true);il::publish_property(ctx,"course_select","downloaded_course");}
 let smart=t::name(smart_ids(),b[p+21]);
 if smart!=() {put(ctx,"smart",smart);il::publish_property(ctx,"smart_course",smart);il::publish_property(ctx,"smart_course_select",smart);}
}
fn course_defaults(ctx,id) {}
fn option_control(ctx,prop,value) {
 let code=();let key=();
 switch prop {
 "spin_select"=>{key="spin";code=t::code(spins(),value);}
 "temperature_select"=>{key="temp";code=t::code(temperatures(),value);}
 "rinse_count"=>{key="rinse";code=value.parse_float().to_int();}
 _=>{return false;}
 }
 put(ctx,key,code);il::publish_property(ctx,prop,if prop=="rinse_count" {code.to_string()} else {value});true
}
fn build_start(ctx,resume) {
 let body=();
 if get(ctx,"downloaded",false) {
  let smart=get(ctx,"smart","cold_wash");let template=smart_starts()[smart];
  if template==() {return ();}body=hex_decode(template);
  il::publish_property(ctx,"smart_course",smart);
 } else {
  let id=get(ctx,"selected",7).to_string();let template=templates()[id];if template==() {return ();}
  body=hex_decode(template);let rules=writable()[id];
  for field in [["spin",4,1],["temp",5,4],["rinse",6,1]] {
   let v=get(ctx,field[0],field[2]);
   if rules!=() && rules[field[0]]!=() && rules[field[0]].contains(v) {body[field[1]]=v;}
  }
 }
 body[7]=get(ctx,"reserve",0);body[11]=if resume {0} else {0x20};body
}
fn publish_config(ctx) { il::publish_il(ctx,descriptor(ctx)); }
fn on_drop(ctx) { il::publish_property(ctx,"available","false"); }
fn on_set_property(ctx,prop,value) {
 if ctx.state_get("__il_descriptor")==() && !["start","pause","power_off","course_select"].contains(prop) {publish_config(ctx);}
 let value=il::validate(ctx,prop,value);
 if value!=() { set_property(ctx,prop,value); }
}
