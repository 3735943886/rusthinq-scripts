// LG dishwasher D30 (LDT54788D): device -> IL driver. Port of upstream rethink's driver (commit
// 0e57069). Read only. 26-byte records; dishwasher_common decodes the shared fields, plus
//   11 flags: 0x01 child lock, 0x08 rinse aid refill, 0x80 night dry
//   12 options: 0x01 delay start, 0x02 energy saver, 0x10 dual zone, 0x40 half load
// The course and option bytes clear at the end of a cycle, so they read off outside Ready,
// Running and Paused. 0x32 0xD8 <n> counts washes since the last Machine Clean.
import "aabb_common" as c;
import "dishwasher_common" as w;
import "table_common" as t;
import "il_common" as il;

fn courses() {
    #{ "0": "off", "1": "auto", "2": "heavy", "3": "delicate", "4": "turbo", "5": "normal",
       "6": "rinse", "8": "express", "9": "machine_clean" }
}

fn options() {
    #{ delay_start: 0x01, energy_saver: 0x02, extra_dry: 0x04, high_temp: 0x08, dual_zone: 0x10,
       half_load: 0x40 }
}

fn descriptor(ctx) {
    let props = w::props(t::options(courses()));
    props += #{
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle time" },
        delay_start_time: #{ type: "number", class: "duration", unit: "min", label: "Delayed start" },
        child_lock: #{ type: "binary" },
        night_dry: #{ type: "binary" },
        rinse_refill: #{ type: "binary", class: "problem", label: "Rinse aid low" },
        tub_clean_counter: #{ type: "number", category: "diagnostic", label: "Washes since machine clean" }
    };
    for o in options().keys() { props[o] = #{ type: "binary" }; }
    json_stringify(#{ il: 0, kind: "washer", class: "dishwasher", label: "Dishwasher", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn start(ctx) { w::query(ctx); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    let body = c::inner(data, 0x32);
    if body != () && body[1] == 0xd8 && body.len() == 3 {
        return il::publish_property(ctx, "tub_clean_counter", body[2].to_string());
    }
    let p = w::payload(data, 26, 0x18);
    if p == () || !w::sane(p) || p[10] > 59 { return; }
    w::publish(ctx, p);
    il::publish_property(ctx, "initial_time", w::minutes(p, 3).to_string());
    il::publish_property(ctx, "delay_start_time", w::minutes(p, 9).to_string());
    let active = p[0] >= 1 && p[0] <= 3;
    c::pub_name(ctx, "course", if active { t::name(courses(), p[5]) } else { "off" });
    let o = options();
    for k in o.keys() { il::publish_property(ctx, k, if active { c::bit(p[12], o[k]) } else { "false" }); }
    il::publish_property(ctx, "night_dry", c::bit(p[11], 0x80));
    il::publish_property(ctx, "rinse_refill", c::bit(p[11], 0x08));
    il::publish_property(ctx, "child_lock", c::bit(p[11], 0x01));
}

fn set_property(ctx, prop, value) { c::reject(ctx, prop, "read-only appliance"); }

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
