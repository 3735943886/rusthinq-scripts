// Port of anszom/rethink PR #182, c4fc160c0363193d0b8adda5e202c10dc10c1a5a.
// Captures: tests/cloud/devices/RH16_T_KR.test.ts at that revision.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;
fn courses() {
    #{
        "0": "off",
        "1": "steam_refresh",
        "2": "towel",
        "4": "bulky_item",
        "5": "easy_care",
        "7": "standard",
        "8": "sports_wear",
        "9": "quick_dry",
        "11": "wool",
        "15": "bedding_brush",
        "16": "allergy_care",
        "18": "condenser_care",
        "19": "tub_clean",
        "20": "padding_refresh",
        "21": "time_dry",
        "22": "outdoor_refresh",
        "23": "baby_wear"
    }
}
fn states() { #{"0": "power_off", "1": "standby", "2": "drying", "3": "pause", "4": "complete", "5": "error", "8": "smart_diagnosis", "100": "reserved"} }
fn templates() {
    #{
        "1": "f0260100020000000300000003080000",
        "2": "f0260200020000000300000003000000",
        "4": "f0260400030000000400000203000000",
        "5": "f0260503020000000300000003000000",
        "7": "f0260703020000000000000001000000",
        "8": "f0260800010000000400000003000000",
        "9": "f0260900030000000300000203000000",
        "11": "f0260b00020000000300000003000000",
        "15": "f0260f00030000000400000003000000",
        "16": "f0261000030000000300000003080000",
        "18": "f0261200030000000000000003080000",
        "19": "f0261300030000000300000003080000",
        "20": "f0261400030000000300000003000000",
        "21": "f0261500021e00000300000003000000",
        "22": "f0261600033c00000300000003000000",
        "23": "f0261700020000000400000003000000"
    }
}
fn course_options() {
    #{
        "1": "steam_refresh",
        "2": "towel",
        "4": "bulky_item",
        "5": "easy_care",
        "7": "standard",
        "8": "sports_wear",
        "9": "quick_dry",
        "11": "wool",
        "15": "bedding_brush",
        "16": "allergy_care",
        "18": "condenser_care",
        "19": "tub_clean",
        "20": "padding_refresh",
        "21": "time_dry",
        "22": "outdoor_refresh",
        "23": "baby_wear",
        "-1": "downloaded_course"
    }
}
fn downloads() {
    #{
        "powerful_dry": "f0250315000264000000000000001177000000000000000000",
        "wrinkle_care_dry": "f025031500025a000000000200000772000000030000000000",
        "full_size_load": "f0250315000364000000000000000774000000050000000000",
        "refresh": "f0250315000314000000000000000f6b000000000000000000",
        "small_load": "f025031500031e000000000000000e6c000000000000000000",
        "gym_clothes": "f025031500013d000000000000000866000000000000000000",
        "rainy_season": "f0250315000328000000000000000e69000000000000000000",
        "economic_dry": "f025031500017d000000000000000770000000030000000000",
        "easy_iron": "f025031500034100000000000000076e000000010000000000",
        "big_size_item": "f02503150003af000000000000000471000000000000000000"
    }
}
fn dry_levels() { #{"0": "off", "1": "delicate", "2": "light", "3": "standard", "4": "standard_plus", "5": "strong"} }
fn eco_hybrids() { #{"0": "off", "1": "energy", "2": "auto", "3": "speed"} }
fn processes() { #{"0": "detecting", "1": "steam", "2": "drying", "3": "drying", "4": "drying", "5": "cooling", "6": "anti_crease", "7": "complete"} }
fn errors() {
    #{
        "0": "normal",
        "1": "te1",
        "2": "te2",
        "4": "te4",
        "5": "te5",
        "6": "te6",
        "7": "ce1",
        "13": "oe_drain_motor",
        "14": "empty_water",
        "15": "de_door",
        "16": "filter_clogging",
        "17": "no_filter",
        "19": "f1",
        "20": "le2",
        "21": "ae",
        "30": "le1",
        "37": "de4",
        "39": "le3",
        "42": "de2"
    }
}
fn defaults() {
    #{
        "1": #{ "dry": 0, "eco": 2, "ac": 0 },
        "2": #{ "dry": 0, "eco": 2, "ac": 0 },
        "4": #{ "dry": 0, "eco": 3, "ac": 1 },
        "5": #{ "dry": 3, "eco": 2, "ac": 0 },
        "7": #{ "dry": 3, "eco": 2, "ac": 0 },
        "8": #{ "dry": 0, "eco": 1, "ac": 0 },
        "9": #{ "dry": 0, "eco": 3, "ac": 1 },
        "11": #{ "dry": 0, "eco": 2, "ac": 0 },
        "15": #{ "dry": 0, "eco": 3, "ac": 0 },
        "16": #{ "dry": 0, "eco": 3, "ac": 0 },
        "18": #{ "dry": 0, "eco": 3, "ac": 0 },
        "19": #{ "dry": 0, "eco": 3, "ac": 0 },
        "20": #{ "dry": 0, "eco": 3, "ac": 0 },
        "21": #{ "dry": 0, "eco": 2, "ac": 0 },
        "22": #{ "dry": 0, "eco": 3, "ac": 0 },
        "23": #{ "dry": 0, "eco": 2, "ac": 0 }
    }
}
fn dry_writable() { #{"5": [2, 3], "7": [1, 2, 3, 4, 5]} }
fn eco_writable() { #{"7": [1, 2, 3]} }
fn ac_writable() { [1, 2, 4, 5, 7, 8, 9, 11, 15, 16, 20, 21, 22, 23] }
fn is_dryer() { true }

fn get(ctx,key,fallback) { let v=ctx.state_get("captured_"+key); if v==() {fallback} else {v} }
fn put(ctx,key,v) {ctx.state_set("captured_"+key,v);}
fn descriptor(ctx) {
 let props=base_props(ctx);
 props.course_select=#{type:"select",rw:true,options:t::options(course_options())};
 props.smart_course=#{type:"select",options:downloads().keys()};
 props.smart_course_select=#{type:"select",rw:true,options:downloads().keys()};
 props.reserve_hours=#{type:"number",rw:true,min:0,max:19,step:1,unit:"h"};
 props.resume=#{type:"trigger"};
 props.start_course=#{type:"trigger"};
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
 json_stringify(#{il:0,kind:if is_dryer() {"dryer"} else {"washer"},label:if is_dryer() {"Dryer"} else {"Washer"},vendor:"LG",model:ctx.model_id(),props:props})
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
   il::publish_property(ctx,"energy",b[if b[1]==0xcd {36} else {37}].to_string());return;
  }
 }
 let one=if is_dryer() {29} else {40};let two=if is_dryer() {56} else {78};
 let p=if b[1]==0xeb && b.len()==one {3} else if b[1]==0xec && b.len()==two {if is_dryer() {30} else {41}} else {legacy_data(ctx,data);return;};
 if b[p]!=(if is_dryer() {0x19} else {0x24}) {return;}
 put(ctx,"protocol",true);
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
}
fn select_smart(ctx,name) {
 put(ctx,"smart",name);put(ctx,"downloaded",true);
 il::publish_property(ctx,"smart_course_select",name);il::publish_property(ctx,"course_select","downloaded_course");
}
fn set_property(ctx,prop,value) {
 if legacy_control(ctx,prop,value) {return;}
 put(ctx,"protocol",true);
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
  let body=build_start(ctx,prop=="resume");
  if body==() {c::reject(ctx,prop,"no captured command for this selection");return;}
  ctx.send_raw(aabb_wrap(body));return;
 }
 c::reject(ctx,prop,"read-only property");
}

fn base_props(ctx) {
 let status_options=t::options(states());for v in t::options(processes()) {if !status_options.contains(v) {status_options.push(v);}}
 #{available:#{type:"binary",role:"available"},power:#{type:"binary"},status:#{type:"select",options:status_options},
 course:#{type:"select",options:t::options(courses())+["downloaded_course"]},
 dry_level:#{type:"select",options:t::options(dry_levels())},eco_hybrid:#{type:"select",options:t::options(eco_hybrids())},
 start:#{type:"trigger"},pause:#{type:"trigger"},power_off:#{type:"trigger"},
 remaining_time:#{type:"number",unit:"min"},initial_time:#{type:"number",unit:"min"},reserve_time:#{type:"number",unit:"min"},
 energy:#{type:"number",class:"energy",series:"counter",unit:"Wh"},error:#{type:"binary",class:"problem"},error_message:#{type:"text"},
 child_lock:#{type:"binary"},anti_crease:#{type:"binary"},reservation:#{type:"binary"},remote_start:#{type:"binary"},steam:#{type:"binary"}}
}
fn legacy_data(ctx,data) {}
fn legacy_control(ctx,prop,value) {false}
fn decode_model(ctx,b,p) {
 let state=b[p+1];
 if (state==2 || state==3) && (b[p+11]!=0 || b[p+12]!=0 || b[p+13]!=0 || b[p+14]!=0) {il::publish_property(ctx,"status","reserved");}
 else if state==2 {c::pub_name(ctx,"status",t::name(processes(),b[p+10]));}
 il::publish_property(ctx,"child_lock",c::bit(b[p+15],0x10));
 il::publish_property(ctx,"anti_crease",c::bit(b[p+15],2));
 il::publish_property(ctx,"reservation",c::bit(b[p+15],1));
 il::publish_property(ctx,"remote_start",c::bit(b[p+16],1));
 il::publish_property(ctx,"steam",c::bit(b[p+17],8));
 il::publish_property(ctx,"smart_diagnosis",c::on_off(if state==8 {1} else {0}));
 il::publish_property(ctx,"energy",(b[p+18]*256+b[p+19]).to_string());
 c::pub_name(ctx,"dry_level",t::name(dry_levels(),b[p+8]));
 c::pub_name(ctx,"eco_hybrid",t::name(eco_hybrids(),b[p+9]));
 il::publish_property(ctx,"error_message",t::name(errors(),b[p+7]) ?? "Unknown error ("+b[p+7]+")");
 let matched=false;
 for name in downloads().keys() {
  let blob=hex_decode(downloads()[name]);
  if blob[14]==b[p+6] && blob[15]==b[p+21] {select_smart(ctx,name);matched=true;il::publish_property(ctx,"smart_course",name);}
 }
 if !matched && templates().contains(b[p+6].to_string()) {
  put(ctx,"selected",b[p+6]);put(ctx,"downloaded",false);
  il::publish_property(ctx,"course_select",t::name(courses(),b[p+6]));
 }
 if matched || get(ctx,"downloaded",false) {il::publish_property(ctx,"course","downloaded_course");}
 let name=get(ctx,"smart",());if name!=() {il::publish_property(ctx,"smart_course",name);il::publish_property(ctx,"smart_course_select",name);}
}
fn course_defaults(ctx,id) {
 let d=defaults()[id.to_string()];if d==() {return;}
 put(ctx,"dry",d.dry);put(ctx,"eco",d.eco);put(ctx,"ac",d.ac);
 il::publish_property(ctx,"dry_level_select",t::name(dry_levels(),d.dry));
 il::publish_property(ctx,"eco_hybrid_select",t::name(eco_hybrids(),d.eco));
 il::publish_property(ctx,"anti_crease_select",c::on_off(d.ac));
}
fn option_control(ctx,prop,value) {
 let key=switch prop {"dry_level_select"=>"dry","eco_hybrid_select"=>"eco","anti_crease_select"=>"ac",_=>()};
 if key==() {return false;}
 let code=if key=="dry" {t::code(dry_levels(),value)} else if key=="eco" {t::code(eco_hybrids(),value)} else {if c::to_bool(value) {1} else {0}};
 put(ctx,key,code);il::publish_property(ctx,prop,value);true
}
fn build_start(ctx,resume) {
 let reserve=get(ctx,"reserve",0);
 if get(ctx,"downloaded",false) {
  if resume {return ();}
  let name=get(ctx,"smart",());if name==() {return ();}
  let blob=hex_decode(downloads()[name]);
  return [0xf0,0x26,blob[14],blob[19],blob[5],blob[6],blob[7],blob[8],reserve,blob[10],blob[12],blob[11],3,blob[13],blob[15],0];
 }
 let id=get(ctx,"selected",7).to_string();let body=hex_decode(templates()[id]);
 body[8]=reserve;
 let dry=get(ctx,"dry",3);let eco=get(ctx,"eco",2);
 if dry_writable()[id]!=() && dry_writable()[id].contains(dry) {body[3]=dry;}
 if eco_writable()[id]!=() && eco_writable()[id].contains(eco) {body[4]=eco;}
 if ac_writable().contains(id.parse_int()) {body[11]=if get(ctx,"ac",0)==1 {2} else {0};}
 body
}
fn publish_config(ctx) {
 il::publish_il(ctx,descriptor(ctx));
 let smart=get(ctx,"smart",());
 il::publish_property(ctx,"course_select",if get(ctx,"downloaded",false) {"downloaded_course"} else {t::name(courses(),get(ctx,"selected",7))});
 il::publish_property(ctx,"reserve_hours",get(ctx,"reserve",0).to_string());
 il::publish_property(ctx,"dry_level_select",t::name(dry_levels(),get(ctx,"dry",3)));
 il::publish_property(ctx,"eco_hybrid_select",t::name(eco_hybrids(),get(ctx,"eco",2)));
 il::publish_property(ctx,"anti_crease_select",c::on_off(get(ctx,"ac",0)));
 if smart!=() {il::publish_property(ctx,"smart_course",smart);il::publish_property(ctx,"smart_course_select",smart);}
}
fn on_drop(ctx) { il::publish_property(ctx,"available","false"); }
fn on_set_property(ctx,prop,value) {
 if ctx.state_get("__il_descriptor")==() {publish_config(ctx);}
 let value=il::validate(ctx,prop,value);
 if value!=() { set_property(ctx,prop,value); }
}
