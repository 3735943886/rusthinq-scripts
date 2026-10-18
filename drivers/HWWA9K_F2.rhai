// Port of anszom/rethink PR #116, 2da637a2544aa8689b212ba5cced5a7d16fdfe56.
// Captures: tests/cloud/devices/HWWA9K_F2.test.ts at that revision.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;
fn fields() {
    #{
        "status": #{
            "table": #{ "1": "standby", "2": "cleaning", "3": "charging", "4": "charging_complete" },
            "offset": 2,
            "control": 0
        },
        "clean_mode": #{
            "table": #{ "1": "off", "2": "standard", "3": "high", "4": "turbo", "5": "mop", "6": "auto" },
            "offset": 3,
            "control": 0
        },
        "battery": #{
            "table": #{ "0": "off", "1": "high", "2": "mid", "3": "low", "4": "warning" },
            "offset": 7,
            "control": 0
        },
        "nozzle": #{
            "table": #{ "0": "auxiliary_inlet", "1": "powerdrive_floor", "2": "powerdrive_carpet", "3": "powerdrive_mop" },
            "offset": 6,
            "control": 0
        },
        "filter_state": #{ "table": #{ "1": "normal", "2": "cleaning_needed" }, "offset": 4, "control": 0 },
        "passage": #{ "table": #{ "1": "normal", "2": "check_for_debris" }, "offset": 5, "control": 0 },
        "suction_force": #{ "table": #{ "1": "standard", "2": "high", "3": "turbo" }, "offset": 10, "control": 2 },
        "mop_with_sucking": #{ "table": #{ "1": "mop_only", "2": "mop_and_suction_together" }, "offset": 8, "control": 1 },
        "charging_melody": #{
            "table": #{ "1": "lucky", "2": "marble", "3": "ice", "4": "breeze", "5": "nebula" },
            "offset": 11,
            "control": 3
        },
        "volume": #{ "table": #{ "1": "high", "2": "normal", "3": "low" }, "offset": 12, "control": 4 },
        "brightness": #{
            "table": #{ "1": "very_bright", "2": "bright", "3": "normal", "4": "dim", "5": "off" },
            "offset": 13,
            "control": 5
        }
    }
}

fn descriptor(ctx) {
 let props=#{available:#{type:"binary",role:"available"},complete_clean:#{type:"binary"}};
 for prop in fields().keys() { let f=fields()[prop]; props[prop]=#{type:"select",rw:f.control!=0,options:t::options(f.table)}; }
 json_stringify(#{il:0,kind:"vacuum",label:"CordZero A9",vendor:"LG",model:ctx.model_id(),props:props})
}
fn on_data(ctx,data) {
 let b=c::inner(data,0xd2);
 if b==() || b.len()<=2 || (b.len()-2)%14!=0 { return; }
 let p=b.len()-14; if b[p+1]!=12 { return; }
 for prop in fields().keys() { let f=fields()[prop]; c::pub_name(ctx,prop,t::name(f.table,b[p+f.offset])); }
 il::publish_property(ctx,"complete_clean",c::on_off(if b[p+9]==2 {1} else {0}));
}
fn set_property(ctx,prop,value) {
 let f=fields()[prop];
 if f==() || f.control==0 { c::reject(ctx,prop,"read-only property"); return; }
 let code=t::code(f.table,value);
 ctx.send_raw(aabb_wrap([0xf0,0x24,f.control,1,code]));
}
fn publish_config(ctx) { il::publish_il(ctx,descriptor(ctx)); }
fn on_drop(ctx) { il::publish_property(ctx,"available","false"); }
fn on_set_property(ctx,prop,value) {
 if ctx.state_get("__il_descriptor")==() {publish_config(ctx);}
 let value=il::validate(ctx,prop,value);
 if value!=() { set_property(ctx,prop,value); }
}
