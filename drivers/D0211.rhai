// LG dishwasher D0211 (DB365TXS / DBC435TSL): device -> IL driver. Port of upstream rethink's
// driver (commit 0e57069). Read only. 26-byte records; dishwasher_common decodes the shared
// fields, plus
//   11 flags: 0x01 child lock, 0x04 rinse aid refill, 0x08 salt refill
//   12 options: 0x01 delay start, 0x02 energy saver, 0x10 dual zone, 0x40 half load, 0x80 steam
// The course and option bytes keep leftovers outside Running, so they read off there.
// 0x32 0xD8 <n> is a cycle counter sent at the rinse-to-dry transition. Every frame is acked
// as the LG cloud does.
import "aabb_common" as c;
import "dishwasher_common" as w;
import "il_common" as il;

fn courses() { #{ "0": "off", "1": "auto", "2": "intensive", "5": "eco" } }

fn options() {
    #{ delay_start: 0x01, energy_saver: 0x02, extra_dry: 0x04, high_temp: 0x08, dual_zone: 0x10,
       half_load: 0x40, steam: 0x80 }
}

fn descriptor(ctx) {
    let props = w::props(c::options(courses()));
    props += #{
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle time" },
        child_lock: #{ type: "binary" },
        rinse_refill: #{ type: "binary", class: "problem", label: "Rinse aid low" },
        salt_refill: #{ type: "binary", class: "problem", label: "Salt low" },
        tub_clean_counter: #{ type: "number", category: "diagnostic", label: "Cycle counter" }
    };
    for o in options().keys() { props[o] = #{ type: "binary" }; }
    json_stringify(#{ il: 0, kind: "washer", class: "dishwasher", label: "Dishwasher", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn start(ctx) { w::query(ctx); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let body = c::inner(data, 0x32);
    if body != () && body[1] == 0xd8 && body.len() == 3 {
        return il::publish_property(ctx, "tub_clean_counter", body[2].to_string());
    }
    let p = w::payload(data, 26, 0x18);
    if p == () || !w::sane(p) { return; }
    w::publish(ctx, p);
    il::publish_property(ctx, "initial_time", w::minutes(p, 3).to_string());
    let running = p[0] == 2;
    c::pub_name(ctx, "course", if running { c::name(courses(), p[5]) } else { "off" });
    let o = options();
    for k in o.keys() { il::publish_property(ctx, k, if running { c::bit(p[12], o[k]) } else { "false" }); }
    il::publish_property(ctx, "child_lock", c::bit(p[11], 0x01));
    il::publish_property(ctx, "rinse_refill", c::bit(p[11], 0x04));
    il::publish_property(ctx, "salt_refill", c::bit(p[11], 0x08));
}

fn set_property(ctx, prop, value) { c::reject(ctx, prop, "read-only appliance"); }

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
