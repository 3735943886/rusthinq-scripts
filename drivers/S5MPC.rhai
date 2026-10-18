// Port of anszom/rethink PR #173, 6c239b821cb8dcabf033827745454a3053bd3bc5.
// Captures: tests/cloud/devices/S5MPC.test.ts at that revision.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;
fn states() {
    #{
        "0": "power_off",
        "1": "standby",
        "2": "running",
        "3": "pause",
        "4": "complete",
        "5": "error",
        "6": "smart_diagnosis",
        "7": "storing",
        "8": "reserved",
        "9": "power_save_running",
        "50": "steam_preparing",
        "51": "refreshing",
        "52": "refreshing",
        "53": "refreshing",
        "54": "drying",
        "55": "drying",
        "56": "drying",
        "57": "sterilizing",
        "58": "complete",
        "59": "complete"
    }
}
fn courses() {
    #{
        "0": "none",
        "1": "styling_standard",
        "3": "styling_quick",
        "5": "styling_intensive",
        "6": "wool_knit",
        "7": "suit_coat",
        "8": "functionality",
        "10": "downloaded_course",
        "11": "sterilize_standard",
        "12": "bedding_sterilize",
        "13": "baby_clothing_sanitary",
        "14": "doll_sanitary",
        "15": "auto_dry",
        "16": "wool_delicate_dry",
        "17": "timed_dry_30",
        "18": "timed_dry_60",
        "19": "timed_dry_90",
        "20": "timed_dry_120",
        "27": "uniform_management",
        "28": "padding_care",
        "30": "fine_dust",
        "31": "virus",
        "32": "jeans_care",
        "33": "fur_leather_care",
        "36": "suit_uniform_sterilize",
        "67": "silent",
        "78": "fur_leather"
    }
}
fn smart_courses() {
    #{
        "0": "none",
        "1": "panel_course",
        "61": "suits_uniforms",
        "62": "scarves",
        "66": "pants",
        "67": "silent",
        "68": "coat_warmer",
        "69": "static_removal",
        "71": "stored_items",
        "73": "blanket_warmer",
        "75": "dress_shirts",
        "76": "snow_raing_drying",
        "78": "fur_leather",
        "93": "jeans_management",
        "94": "baby_clothing_sanitary",
        "95": "doll_sanitary",
        "96": "wool_delicate_dry",
        "97": "rainy_days",
        "98": "uniform",
        "99": "padding_management",
        "100": "thin_padding_management",
        "101": "thick_padding_management",
        "102": "silk_care",
        "112": "athleisure_refresh",
        "113": "athleisure_dry",
        "114": "swimsuit_dry",
        "120": "golf_wear_care",
        "121": "golf_wear_dry"
    }
}
fn params() {
    #{
        "1": "02645a00000005005a05b45a01b4001ab40000000000000000000000000000000000000000",
        "3": "82645a00000003005a00000001b4000eb40000000000000000000000000000000000000000",
        "5": "02645a00000007005a05c85a01c80031b40000000000000000000000000000000000000000",
        "6": "82000000000004000000000001000014780000000000000000000000000000000000000000",
        "7": "82645a00000004005a04b45a01b40017780000000000000000000000000000000000000000",
        "8": "0200000000000300000000000000001400000000000000000400000300000178001a780000",
        "11": "0200002d000006000008000003000023780000000000000000000000000000000000000000",
        "12": "0200002d000006000008000003000028000000000000000000000000000000000000000000",
        "15": "0000000000000000000000000000005a780000000000000000000000000000000000000000",
        "17": "8000000000000000000000000000001e780000000000000000000000000000000000000000",
        "18": "8000000000000000000000000000003c780000000000000000000000000000000000000000",
        "19": "8000000000000000000000000000005a780000000000000000000000000000000000000000",
        "20": "8000000000000000000000000000003c780000000000000000000000000000000000000000",
        "28": "82005a00000005005a05b45a01b4002eb40000000000000000000000000000000000000000",
        "30": "82000000000000000000000005c80000000000000000000003005a02c85a01c80028c80000",
        "31": "8200002d000007000008000003000043000000000000000000000000000000000000000000",
        "32": "8200002d000006000008000003000028000000000000000000000000000000000000000000",
        "33": "8000000000000000000000000000001e780000000000000000000000000000000000000000",
        "36": "8200002d00000600000800000300002b780000000000000000000000000000000000000000"
    }
}
fn smart_params() {
    #{
        "61": ["8200002d000006000008000003000023780000000000000000000000000000000000000000", 10],
        "62": ["82000000000004000000000001000010780000000000000000000000000000000000000000", 10],
        "66": ["02000000000006000000000001000023000000000000000004000000000001b40019b40000", 10],
        "67": ["8200000000000400000200000200002800000000000000000700000300000200003a000000", 67],
        "68": ["8000000000000000000000000000000a780000000000000000000000000000000000000000", 10],
        "69": ["82000000000002000000000001780005780000000000000000000000000000000000000000", 10],
        "71": ["82000000000005005a05a05a0178001aa00000000000000000000000000000000000000000", 10],
        "73": ["8000000000000000000000000000001e780000000000000000000000000000000000000000", 10],
        "75": ["82000000000007000002c80001000064780000000000000000000000000000000000000000", 10],
        "76": ["0200000000000300000000000100002d780000000000000000000000000000000000000000", 10],
        "78": ["8000000000000000000000000000001e780000000000000000000000000000000000000000", 78],
        "93": ["8200002d000006000008000003000028000000000000000000000000000000000000000000", 32],
        "94": ["0200002d00000500000800000300001f000000000000000000000000000000000000000000", 13],
        "95": ["0200002d000006000008000003000030000000000000000000000000000000000000000000", 14],
        "96": ["80000000000000000000000000000096780000000000000000000000000000000000000000", 16],
        "97": ["8000000000000000000000000000005a780000000000000000000000000000000000000000", 10],
        "98": ["02000000000000000000000005c80000000000000000000008005a07c85a01c80031b40000", 27],
        "99": ["82005a00000005005a05b45a01b4002eb40000000000000000000000000000000000000000", 28],
        "100": ["80000000000000000000000008b40037780000000000000000000000000008b4000ab40000", 17],
        "101": ["80000000000000000000000005b4006e780000000000000000000000000005b4001eb40000", 17],
        "102": ["82000000000001005a00000001b40014b40000000000000000000000000000000000000000", 16],
        "112": ["02005a00000003000005a00001a00017a00000000000000000000000000000000000000000", 10],
        "113": ["80000000000000000000000000000064780000000000000000000000000000000000000000", 17],
        "114": ["80000000000000000000000000000050780000000000000000000000000000000000000000", 17],
        "120": ["02005a00000003005a0000000000000fa00000000000000003005a03005a01a00017a00000", 8],
        "121": ["80000000000000000000000000000055780000000000000000000000000000000000000000", 17]
    }
}
fn course_ids() { [1, 3, 5, 6, 7, 8, 11, 12, 15, 17, 18, 19, 20, 28, 30, 31, 32, 33, 36] }
fn smart_ids() { [61, 62, 66, 67, 68, 69, 71, 73, 75, 76, 78, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 112, 113, 114, 120, 121] }

fn descriptor(ctx) {
 let offered=[];for id in course_ids()+[10] {offered.push(t::name(courses(),id));}
 let smart=[];for id in smart_ids() {smart.push(t::name(smart_courses(),id));}
 json_stringify(#{il:0,kind:"clothing_care",label:"Styler",vendor:"LG",model:ctx.model_id(),props:#{
 available:#{type:"binary",role:"available"},power:#{type:"binary"},status:#{type:"select",options:t::options(states())},
 course:#{type:"select",options:t::options(courses())},course_select:#{type:"select",rw:true,options:offered},
 smart_course:#{type:"select",options:t::options(smart_courses())},smart_course_select:#{type:"select",rw:true,options:smart},
 power_off:#{type:"trigger"},start:#{type:"trigger"},pause:#{type:"trigger"},resume:#{type:"trigger"},
 reserve_hours:#{type:"number",rw:true,min:0,max:19,step:1,unit:"h"},store:#{type:"binary",rw:true},
 remaining_time:#{type:"number",unit:"min"},initial_time:#{type:"number",unit:"min"},reserve_time:#{type:"number",unit:"min"},
 remote_start:#{type:"binary"},child_lock:#{type:"binary"},error:#{type:"binary",class:"problem"},error_message:#{type:"text"},
 smart_diagnosis:#{type:"binary"},energy:#{type:"number",class:"energy",series:"counter",unit:"Wh"}}})
}
fn get(ctx,key,fallback) {let v=ctx.state_get(key);if v==() {fallback} else {v}}
fn choose_smart(ctx,id) {
 ctx.state_set("smart",id);ctx.state_set("smart_selected",true);ctx.state_set("base",smart_params()[id.to_string()][1]);
 il::publish_property(ctx,"course_select","downloaded_course");
 il::publish_property(ctx,"smart_course_select",t::name(smart_courses(),id));
 il::publish_property(ctx,"smart_course",t::name(smart_courses(),id));
}
fn on_data(ctx,data) {
 if data.len()<4 || data[0]!=0xaa || data[data.len()-1]!=0xbb {return;}
 let sum=0;for i in 0..data.len()-2 {sum+=data[i];}
 if data[data.len()-2]!=((sum & 255)^0x55) {return;}
 let b=c::inner(data,0x31);if b==() || b.len()<=2 || (b.len()-2)%29!=0 {return;}
 for p in range(2,b.len(),29) {if b[p]*256+b[p+1]!=27 {return;}}
 let r=b.extract(b.len()-27);let state=r[0];let error=r[6];let smart=r[20];
 ctx.state_set("powered",state!=0);ctx.state_set("problem",error!=0);
 il::publish_property(ctx,"power",c::bit(state,255));c::pub_name(ctx,"status",t::name(states(),state));
 if smart!=0 && t::name(smart_courses(),smart)!=() {il::publish_property(ctx,"course","downloaded_course");}
 else {c::pub_name(ctx,"course",t::name(courses(),r[5]));}
 if smart!=0 && t::name(smart_courses(),smart)!=() {c::pub_name(ctx,"smart_course",t::name(smart_courses(),smart));}
 else if smart==0 && get(ctx,"smart_selected",false) {let name=t::name(smart_courses(),get(ctx,"smart",66));il::publish_property(ctx,"smart_course_select",name);il::publish_property(ctx,"smart_course",name);}
 if smart!=0 && smart_ids().contains(smart) {choose_smart(ctx,smart);}
 else if course_ids().contains(r[5]) {
  ctx.state_set("selected",r[5]);ctx.state_set("base",r[5]);ctx.state_set("smart_selected",false);
  il::publish_property(ctx,"course_select",t::name(courses(),r[5]));
 }
 il::publish_property(ctx,"remaining_time",(if state==0 || state==4 {0} else {r[1]*60+r[2]}).to_string());
 il::publish_property(ctx,"initial_time",(r[3]*60+r[4]).to_string());
 il::publish_property(ctx,"reserve_time",(r[12]*60+r[13]).to_string());
 il::publish_property(ctx,"remote_start",c::bit(r[14],8));il::publish_property(ctx,"child_lock",c::bit(r[14],1));
 il::publish_property(ctx,"error",c::bit(error,255));
 il::publish_property(ctx,"error_message",if error==0 {"Normal"} else {"Code "+error});
 il::publish_property(ctx,"smart_diagnosis",c::on_off(if state==6 {1} else {0}));
 il::publish_property(ctx,"energy",(r[17]*256+r[18]).to_string());
}
fn block(ctx,id,smart) {
 let params=if smart==0 {params()[id.to_string()]} else {smart_params()[smart.to_string()][0]};
 if params==() {return ();}
 let head=[id,1,smart,4 | (if get(ctx,"store",false) {2} else {0}),0,0,get(ctx,"reserve",0),0,0];
 for b in hex_decode(params) {head.push(b.to_int());}head
}
fn download(ctx,smart) {
 let entry=smart_params()[smart.to_string()];if entry==() {return false;}
 let body=block(ctx,entry[1],smart);body[3]=0;body[6]=0;
 ctx.send_raw(aabb_wrap([0xf0,0x25,3,0x2d]+body));true
}
fn set_property(ctx,prop,value) {
 if prop=="power_off" || prop=="pause" {ctx.send_raw(aabb_wrap([0xf0,0x24,if prop=="pause" {4} else {1},1,0]));return;}
 if prop=="course_select" {
  let id=t::code(courses(),value);if id==10 {ctx.state_set("smart_selected",true);}
  else {ctx.state_set("selected",id);ctx.state_set("base",id);ctx.state_set("smart_selected",false);}
  il::publish_property(ctx,prop,value);return;
 }
 if prop=="smart_course_select" {let id=t::code(smart_courses(),value);choose_smart(ctx,id);download(ctx,id);return;}
 if prop=="reserve_hours" {
  let hours=value.parse_float().to_int();if hours!=0 && (hours<3 || hours>19) {c::reject(ctx,prop,"reservation is 0 or 3..19 hours");return;}
  ctx.state_set("reserve",hours);il::publish_property(ctx,prop,hours.to_string());return;
 }
 if prop=="store" {ctx.state_set("store",c::to_bool(value));il::publish_property(ctx,prop,value);return;}
 if prop=="resume" {
  let body=[get(ctx,"base",1)];for i in 1..45 {body.push(0);}
  ctx.send_raw(aabb_wrap([0xf0,0x26]+body));return;
 }
 if prop=="start" {
  let smart=if get(ctx,"smart_selected",false) {get(ctx,"smart",66)} else {0};
  let id=if smart!=0 {smart_params()[smart.to_string()][1]} else {get(ctx,"selected",1)};
  if smart!=0 && !download(ctx,smart) {return;}
  ctx.state_set("base",id);let body=block(ctx,id,smart);if body==() {return;}
  ctx.send_raw(aabb_wrap([0xf0,0x26]+body));
  if get(ctx,"powered",false) && !get(ctx,"problem",true) {
   il::publish_property(ctx,if smart==0 {"course"} else {"smart_course"},if smart==0 {t::name(courses(),id)} else {t::name(smart_courses(),smart)});
  }
  return;
 }
 c::reject(ctx,prop,"read-only property");
}
fn publish_config(ctx) {
 il::publish_il(ctx,descriptor(ctx));
 il::publish_property(ctx,"course_select",if get(ctx,"smart_selected",false) {"downloaded_course"} else {t::name(courses(),get(ctx,"selected",1))});
 il::publish_property(ctx,"smart_course_select",t::name(smart_courses(),get(ctx,"smart",66)));
 il::publish_property(ctx,"reserve_hours",get(ctx,"reserve",0).to_string());
 il::publish_property(ctx,"store",if get(ctx,"store",false) {"true"} else {"false"});
 if get(ctx,"smart_selected",false) {il::publish_property(ctx,"smart_course",t::name(smart_courses(),get(ctx,"smart",66)));}
}
fn on_drop(ctx) { il::publish_property(ctx,"available","false"); }
fn on_set_property(ctx,prop,value) {
 if ctx.state_get("__il_descriptor")==() {publish_config(ctx);}
 let value=il::validate(ctx,prop,value);
 if value!=() { set_property(ctx,prop,value); }
}
