// LG top-load washer T1789EFH_F (WT7300CW), read only: port of upstream rethink's T1789EFH_F.ts
// (commit 0e57069). Status is a 0x20 EB frame of one 27-byte block or EC of two (previous,
// current); block offsets: 2 phase (0 off), 4 remaining minutes. Unacked, this washer repeats every
// frame about ten times, re-deploys and never streams its status, so it gets the cloud's acks; it
// volunteers no status until start() asks for it.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn phases() { #{ "0": "off", "1": "fill_sense", "2": "paused", "3": "wash_initial", "5": "wash_main", "6": "rinse_drain", "7": "rinse_drain", "8": "spin" } }

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer", vendor: "LG",
                      model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", class: "running", label: "Powered on" },
        status: #{ type: "select", options: t::options(phases()) },
        remaining_time: #{ type: "number", class: "duration", unit: "min" }
    } })
}

fn start(ctx) { ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x11, 0x21, 0x01, 0x00, 0x00, 0x00, 0x18, 0x00])); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let b = c::inner(data, 0x20);
    if b == () { return; }
    let o = c::common_status_offset(b, 27);
    if o == () { return; }
    let phase = b[o + 2];
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if phase != 0 { "true" } else { "false" });
    c::pub_name(ctx, "status", t::name(phases(), phase));
    il::publish_property(ctx, "remaining_time", b[o + 4].to_string());
}

fn on_set_property(ctx, prop, value) {
    il::validate(ctx, prop, value); // every property is read only: il_common publishes the reject
}
