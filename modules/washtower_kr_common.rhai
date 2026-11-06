// Korean split WashTower protocol. Models supply only their verified fields and course rules.
// State has AA FF length/CRC framing; controls use short byte-sum AABB frames.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;
fn field(key) { for f in model().fields {if f.key==key {return f;}} () }
fn entity(key) {
 switch key {
 "reserveTimeMinute"=>"reserve_time","remainTimeMinute"=>"remaining_time","initialTimeMinute"=>"initial_time",
 "doorClose"=>"door","childLock"=>"child_lock","doorLock"=>"door_lock","remoteStart"=>"remote_start",
 "remoteMaintain"=>"remote_maintain","soilWash"=>"soil_wash","freshCare"=>"fresh_care","turboWash"=>"turbo_wash",
 "ecoHybrid"=>"eco_hybrid","wrinkleCare"=>"wrinkle_care","dryLevel"=>"dry_level",_=>key }
}
fn public_keys() { let out=["state","course","reserveTimeMinute","remainTimeMinute","initialTimeMinute","error","childLock","doorLock","remoteStart"];if model().tag==0x33 {out.push("doorClose");}out }
fn definition(f) {
 if ["childLock","doorLock","remoteStart","doorClose"].contains(f.key) {return #{type:"binary"};}
 if f.values!=() {return #{type:"select",options:t::options(f.values)};}
 #{type:"number",unit:"min"}
}
fn descriptor(ctx) {
 let props=#{available:#{type:"binary",role:"available"},power:#{type:"binary",rw:true},
 power_transition:#{type:"select",category:"diagnostic",options:["standby","turning_on","turning_off","command_accepted","complete","timeout"]},
 wake:#{type:"trigger"},power_off:#{type:"trigger"},pause:#{type:"trigger"},start:#{type:"trigger"},remote_maintain:#{type:"binary",rw:true}};
 for key in public_keys() {let f=field(key);if f!=() {props[entity(key)]=definition(f);}}
 for key in settings() {
  let f=field(key);if f==() || f.values==() {continue;}
  let options=t::options(f.values);
  if key=="course" {options=[];for id in rules().keys() {options.push(f.values[id]);}}
  props["setting_"+entity(key)]=#{type:"select",rw:true,options:options};
 }
 json_stringify(#{il:0,kind:if model().tag==0x33 {"washer"} else {"dryer"},label:model().deviceName,vendor:"LG",model:ctx.model_id(),props:props})
}
fn publish_config(ctx) {il::publish_il(ctx,descriptor(ctx));}
fn status_query(ctx) {ctx.send_raw(aabb_wrap(hex_decode("f0ed112101000000180411120000")));}
// Runs after publish_config on attach and on a watched hot reload: ask for a record so a
// reloaded driver republishes state instead of leaving entities unknown while the tower sleeps.
// power_transition is republished here too: kept driver state already marks it as seen, so
// on_data would not publish it again after a reload.
fn start(ctx) {
 if ctx.state_get("pending_power")!=true && ctx.state_get("pending_off")!=true {il::publish_property(ctx,"power_transition","standby");}
 status_query(ctx);
}
fn on_drop(ctx) {
 ctx.cancel_timer("power_on_timeout");ctx.cancel_timer("power_off_timeout");ctx.cancel_timer("status_refresh");
 ctx.state_remove("pending_power");ctx.state_remove("pending_off");il::publish_property(ctx,"available","false");
}
fn on_timer(ctx,name) {
 if name=="power_on_timeout" && ctx.state_get("pending_power")==true {
  ctx.state_remove("pending_power");ctx.state_remove("power_refresh");il::publish_property(ctx,"power_transition","timeout");
 }
 if name=="power_off_timeout" && ctx.state_get("pending_off")==true {
  ctx.state_remove("pending_off");ctx.state_remove("off_accepted");il::publish_property(ctx,"power_transition","timeout");
 }
 if name=="status_refresh" {
  status_query(ctx);
  // One retry 2 s later (3 s after acceptance) if the transition has not settled yet.
  if ctx.state_get("refresh_retry")==true && (ctx.state_get("pending_power")==true || ctx.state_get("pending_off")==true) {
   ctx.state_set("refresh_retry",false);ctx.set_timer("status_refresh",2000);
  }
 }
}
fn checksum(data) {
 if data.len()<4 || data[0]!=0xaa || data[data.len()-1]!=0xbb {return false;}
 let sum=0;for i in 0..data.len()-2 {sum+=data[i];}
 data[data.len()-2]==((sum & 255)^0x55)
}
// The tower answers an F0 E5 power command with an E6 frame: 000201ff010200 accepts ON and
// 000001ff010200 accepts OFF (both captured live 2026-11-06). Acceptance arms a status query
// 1 s later and one retry at 3 s, so the transition settles without waiting for the tower to
// volunteer a record (it usually does ~3 s after the command, but not always after a long
// sleep); a record that settles it first cancels the rest. Only the first acceptance counts.
fn power_response(ctx,data) {
 let m=model();
 if ![13,13+m.liveRecordLength,13+m.recordLength].contains(data.len()) || data[1]!=data.len() || data[2]!=m.tag || data[3]!=0xe6 || !checksum(data) {return;}
 let reply=hex_encode(data.extract(4,7));
 if reply=="000201ff010200" && ctx.state_get("pending_power")==true && ctx.state_get("power_refresh")!=true {
  ctx.state_set("power_refresh",true);
 } else if reply=="000001ff010200" && ctx.state_get("pending_off")==true && ctx.state_get("off_accepted")!=true {
  ctx.state_set("off_accepted",true);
 } else {return;}
 il::publish_property(ctx,"power_transition","command_accepted");
 ctx.state_set("refresh_retry",true);ctx.set_timer("status_refresh",1000);
}
fn record(data) {
 let m=model();
 if data.len()<18+m.liveRecordLength || data[0]!=0xaa || data[1]!=0xff || data[2]!=m.tag || data[3]!=0x0a || data[data.len()-1]!=0xbb {return ();}
 if data[5]+data[6]*256!=data.len() || data[11]!=0 || ![0xeb,0xec].contains(data[12]) {return ();}
 let n=data[13]*256+data[14];if n!=data.len()-18 {return ();}
 if crc16(data.extract(0,data.len()-3))!=data[data.len()-3]*256+data[data.len()-2] {return ();}
 if data[12]==0xeb {if [m.liveRecordLength,m.recordLength].contains(n) {return data.extract(15,n);}return ();}
 let size=if n==m.liveRecordLength*2 {m.liveRecordLength} else if n==m.recordLength*2 {m.recordLength} else {return ();};
 data.extract(15+size,size)
}
fn raw_value(r,f) {
 let raw=0;for i in 0..f.length {raw=raw*256+r[f.offset+i];}
 if f.bit!=() {raw=(raw>>f.bit) & ((1<<(f.bits ?? 1))-1);}raw
}
fn observed(ctx) {ctx.state_get("observed") ?? #{}}
fn draft(ctx) {ctx.state_get("draft") ?? #{}}
fn dirty(ctx) {ctx.state_get("dirty") ?? #{}}
fn publish_draft(ctx) {
 let draft=draft(ctx);
 for key in settings() {let f=field(key);if draft[key]!=() && f.values!=() {c::pub_name(ctx,"setting_"+entity(key),t::name(f.values,draft[key]));}}
}
fn course_defaults(ctx,course,preserve) {
 let rule=rules()[course.to_string()];if rule==() {return false;}
 let d=draft(ctx);let dirty=dirty(ctx);
 let updates=#{course:course,baseDownloadCourseData:0,downloadCourse:0};
 for key in rule.keys() {updates[key]=rule[key][0];}
 for key in updates.keys() {if preserve && dirty[key]==true {continue;}d[key]=updates[key];dirty[key]=true;}
 ctx.state_set("draft",d);ctx.state_set("dirty",dirty);publish_draft(ctx);true
}
fn on_data(ctx,data) {
 power_response(ctx,data);
 let r=record(data);if r==() {return;}
 let obs=observed(ctx);let d=draft(ctx);let dirty=dirty(ctx);
 for f in model().fields {
  if f.offset+f.length>r.len() {continue;}
  let raw=raw_value(r,f);obs[f.key]=raw;if dirty[f.key]!=true {d[f.key]=raw;}
  if public_keys().contains(f.key) || f.key=="remoteMaintain" {
   let prop=entity(f.key);
   if ["childLock","doorLock","remoteStart","remoteMaintain"].contains(f.key) {il::publish_property(ctx,prop,c::on_off(raw));}
   else if f.key=="doorClose" {il::publish_property(ctx,prop,if raw==0 {"true"} else {"false"});}
   else if f.values!=() {let value=t::name(f.values,raw);if value==() {il::publish_absent(ctx,prop);} else {il::publish_property(ctx,prop,value);}}
   else {il::publish_property(ctx,prop,raw.to_string());}
  }
 }
 ctx.state_set("observed",obs);ctx.state_set("draft",d);
 if ctx.state_get("reconciled")!=true {
  ctx.state_set("reconciled",true);
  if dirty.course!=true {let course=obs.course;if course==() || rules()[course.to_string()]==() {course=if model().tag==0x33 {46} else {7};}course_defaults(ctx,course,true);}
 }
 il::publish_property(ctx,"power",if obs.state==0 {"false"} else {"true"});
 if obs.state!=0 && ctx.state_get("pending_power")==true {
  ctx.state_remove("pending_power");ctx.state_remove("power_refresh");ctx.cancel_timer("power_on_timeout");ctx.cancel_timer("status_refresh");il::publish_property(ctx,"power_transition","complete");
 } else if obs.state==0 && ctx.state_get("pending_off")==true {
  ctx.state_remove("pending_off");ctx.state_remove("off_accepted");ctx.cancel_timer("power_off_timeout");ctx.cancel_timer("status_refresh");il::publish_property(ctx,"power_transition","complete");
 } else if ctx.state_get("transition_seen")!=true && ctx.state_get("pending_power")!=true && ctx.state_get("pending_off")!=true {il::publish_property(ctx,"power_transition","standby");}
 ctx.state_set("transition_seen",true);
}
fn option_byte(d,offset) {
 let value=0;
 for f in model().fields {if f.offset==offset && f.bit!=() && settings().contains(f.key) {value|=((d[f.key] ?? 0) & ((1<<(f.bits ?? 1))-1))<<f.bit;}}
 value
}
fn valid_draft(d) {
 let rule=rules()[(d.course ?? -1).to_string()];if rule==() {return false;}
 for key in rule.keys() {let r=rule[key];let value=d[key];if value==() {return false;}if r.len()>1 {if !r[1].contains(value) {return false;}} else if value!=r[0] {return false;}}
 if model().tag==0x33 {
  let no_wash=(d.soilWash ?? 0)==0;
  if no_wash && (d.temp ?? 0)!=0 {return false;}
  if (no_wash || (d.spin ?? 0)==0 || (d.rinse ?? 0)==0) && (d.turboWash ?? 0)!=0 {return false;}
 } else if (d.steam ?? 0)==1 && ((d.dryLevel ?? 0)==1 || ((d.dryLevel ?? 0)==3 && (d.ecoHybrid ?? 0)==2)) {return false;}
 true
}
fn start_payload(d) {
 let course=d.course ?? 0;
 if model().tag==0x33 {
  return [course,d.soilWash ?? 0,d.spin ?? 0,d.temp ?? 0,d.rinse ?? 0,0,0,option_byte(d,34),option_byte(d,35),option_byte(d,36),course,d.downloadCourse ?? 0,0,0,0,d.dryLevel ?? 0,0,0,0,0,0];
 }
 let reserve=d.reserveTimeMinute ?? 0;
 [course,d.dryLevel ?? 0,d.ecoHybrid ?? 0,d.moreLessTime ?? 0,0,0,reserve/256,reserve%256,0,option_byte(d,24),option_byte(d,25),option_byte(d,26),d.downloadCourse ?? 0,0]
}
fn rejected(ctx,prop) {c::reject(ctx,prop,"command unavailable in current state or option combination");}
fn set_property(ctx,prop,value) {
 if prop.starts_with("setting_") {
  for key in settings() {
   if "setting_"+entity(key)!=prop {continue;}
   let f=field(key);let code=t::code(f.values,value);if code==() {rejected(ctx,prop);return;}
   if key=="course" {if !course_defaults(ctx,code,false) {rejected(ctx,prop);}return;}
   let d=draft(ctx);let dirty=dirty(ctx);d[key]=code;dirty[key]=true;
   ctx.state_set("draft",d);ctx.state_set("dirty",dirty);il::publish_property(ctx,prop,value);return;
  }
 }
 let obs=observed(ctx);let state=obs.state;
 if state==() {rejected(ctx,prop);return;}
 if prop=="wake" {if state!=0 {rejected(ctx,prop);return;}ctx.send_raw(aabb_wrap([0xf0,0x2a,1,0]));return;}
 if prop=="power" && c::to_bool(value) {
  if state!=0 || ctx.state_get("pending_power")==true {rejected(ctx,prop);return;}
  ctx.send_raw(aabb_wrap(hex_decode("f0e5000201ff010201")));
  ctx.state_set("pending_power",true);ctx.state_set("power_refresh",false);ctx.state_set("transition_seen",true);
  ctx.set_timer("power_on_timeout",120000);il::publish_property(ctx,"power_transition","turning_on");return;
 }
 if prop=="remote_maintain" {
  let enable=c::to_bool(value);
  if (enable && state!=0 && state!=1) || (!enable && state!=1) {rejected(ctx,prop);return;}
  ctx.send_raw(aabb_wrap([0xf0,0x24,0x10,1,if enable {1} else {0}]));return;
 }
 if prop=="start" {
  let d=draft(ctx);
  if state!=1 || obs.remoteStart!=1 || (model().tag==0x33 && (obs.reserveTimeMinute ?? 0)!=0) || !valid_draft(d) {rejected(ctx,prop);return;}
  ctx.send_raw(aabb_wrap([0xf0,0x26]+start_payload(d)));return;
 }
 if prop=="power_off" || (prop=="power" && !c::to_bool(value)) {
  // Power off rides the F0 E5 power channel with value 0, as the official app does
  // (AA0DF0E5000001FF010200DABB, captured live 2026-11-05 and confirmed to switch both
  // a FAKPK21021 washer and a BDH_D39302_KR dryer off on 2026-11-06); it is not gated on
  // remote start. Tracked like power on: turning_off -> command_accepted -> complete, or
  // timeout. A repeated request resends and restarts the wait; an OFF supersedes a pending ON.
  if state==0 {rejected(ctx,prop);return;}
  ctx.send_raw(aabb_wrap(hex_decode("f0e5000001ff010200")));
  ctx.state_remove("pending_power");ctx.state_remove("power_refresh");ctx.cancel_timer("power_on_timeout");ctx.cancel_timer("status_refresh");
  ctx.state_set("pending_off",true);ctx.state_set("off_accepted",false);ctx.state_set("transition_seen",true);
  ctx.set_timer("power_off_timeout",60000);il::publish_property(ctx,"power_transition","turning_off");return;
 }
 if prop=="pause" {
  if state==0 || (obs.remoteStart!=1 && obs.remoteMaintain!=1) {rejected(ctx,prop);return;}
  ctx.send_raw(aabb_wrap([0xf0,0x24,4,1,0]));return;
 }
 rejected(ctx,prop);
}
fn on_set_property(ctx,prop,value) {let value=il::validate(ctx,prop,value);if value!=() {set_property(ctx,prop,value);}}
