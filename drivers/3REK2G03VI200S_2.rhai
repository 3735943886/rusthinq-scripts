// LG kimchi refrigerator 3REK2G03VI200S_2 (김치냉장고, three compartments 상칸/중칸/하칸):
// device -> IL driver. Port of kshexe/rethink's 3REK2G03VI200S_2.ts
// (https://github.com/kshexe/rethink, commit 8fa8bd4), a fork of upstream rethink whose frames
// were captured against a real unit (2026-09-10..15): every option of every compartment pressed
// in turn, door events isolated one compartment at a time. An AABB appliance, class 0x11.
//
// From the appliance:
//   EB / EC          one / two (previous, current) 10-byte records
//   00 e5            write ack; e6 + 8 + 10 bytes: write echo, whose record is the state
//                    BEFORE the write (seen live) - ignored, the EC push follows
//   3e 00 <delta> <total16> <tick>   energy report (~15 min), Wh (checked against the app's
//                    hourly figures): the total is `energy`, a counter that resets at no fixed
//                    time. The fork's hour/day/month totals, kept on disk by calendar, are not
//                    ported (a consumer's utility meter)
//   72 00 <code> ..  (15 bytes) notification: 23 door_is_open (one sample; the only event
//                    type the official integration lists for this model)
//   31 (51 bytes)    an identification block: ignored
// Record: [1] top, [3] middle, [4] bottom compartment mode (three separate tables; [2] and [5]
//   are 0xff, the absent right room), [6] one-touch deodorize, [7] top door closed (1),
//   [8] any door open (1).
// Writes, captured: f0 e5 00 02 01 ff 01 00 <record index> 00 <value>.
// The connect query is the family's f0 ed 12 11 01 00 00 01 04 00, sent once as in the fork.
// Divergences from the fork: nothing is published from a write (the fork is optimistic; the EC
// push confirms within a second); a mode with no name is absent instead of `unknown_<n>`.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn top_modes() {
    #{ "0": "맛지킴 김치 (중)", "1": "맛지킴 김치 (강)", "2": "맛지킴 김치 (약)", "3": "냉장 (중)",
       "4": "냉장 (강)", "5": "냉장 (약)", "6": "냉동", "7": "익힘", "9": "꺼짐", "10": "유산균 김치+" }
}
fn middle_modes() {
    #{ "0": "맛지킴 김치 (중)", "1": "맛지킴 김치 (강)", "2": "맛지킴 김치 (약)", "3": "야채·과일 (중)",
       "4": "야채·과일 (강)", "5": "야채·과일 (약)", "6": "구입 김치", "7": "유산균 김치+", "11": "익힘",
       "13": "꺼짐" }
}
fn bottom_modes() {
    #{ "0": "맛지킴 김치 (중)", "1": "맛지킴 김치 (강)", "2": "맛지킴 김치 (약)", "3": "야채·과일 (중)",
       "4": "야채·과일 (강)", "5": "야채·과일 (약)", "6": "쌀·잡곡", "7": "육류/생선", "8": "오래 보관",
       "9": "꺼짐" }
}
fn notifications() { #{ "23": "door_is_open" } }

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "fridge", label: "Kimchi refrigerator", vendor: "LG",
                      model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        top_compartment: #{ type: "select", rw: true, options: t::options(top_modes()), label: "Top compartment mode" },
        middle_compartment: #{ type: "select", rw: true, options: t::options(middle_modes()), label: "Middle compartment mode" },
        bottom_compartment: #{ type: "select", rw: true, options: t::options(bottom_modes()), label: "Bottom compartment mode" },
        one_touch_deodorize: #{ type: "binary", rw: true, label: "One-touch deodorize" },
        top_door: #{ type: "binary", class: "door", label: "Top compartment door open" },
        door: #{ type: "binary", class: "door", label: "Any door open" },
        notification: #{ type: "text", category: "diagnostic", label: "Notification" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Energy" }
    } })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn start(ctx) {
    ctx.send_raw(aabb_wrap(hex_decode("f0ed1211010000010400")));
}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let b = c::inner(data, 0x11);
    if b == () { return; }
    if b[1] == 0x3e {
        if b.len() == 7 { il::publish_property(ctx, "energy", (b[4] * 256 + b[5]).to_string()); }
        return;
    }
    if b[1] == 0x72 {
        if b.len() == 15 && b[2] == 0 {
            let name = t::name(notifications(), b[3]);
            if name != () { il::publish_event(ctx, "notification", json_stringify(#{ event_type: name })); }
        }
        return;
    }
    let o = c::common_status_offset(b, 10);
    if o != () { record(ctx, b.extract(o, 10)); }
}

fn mode(ctx, prop, table, raw) {
    let name = t::name(table, raw);
    if name == () { il::publish_absent(ctx, prop); } else { il::publish_property(ctx, prop, name); }
}

fn record(ctx, r) {
    il::publish_property(ctx, "available", "true");
    mode(ctx, "top_compartment", top_modes(), r[1]);
    mode(ctx, "middle_compartment", middle_modes(), r[3]);
    mode(ctx, "bottom_compartment", bottom_modes(), r[4]);
    il::publish_property(ctx, "one_touch_deodorize", c::on_off(r[6]));
    il::publish_property(ctx, "top_door", if r[7] != 1 { "true" } else { "false" });
    il::publish_property(ctx, "door", c::on_off(r[8]));
}

fn write_field(ctx, index, value) {
    let msg = hex_decode("f0e5000201ff0100");
    msg.push(index);
    msg.push(0);
    msg.push(value);
    ctx.send_raw(aabb_wrap(msg));
}

fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value == () { return; }
    switch prop {
        "top_compartment" => write_field(ctx, 1, t::code(top_modes(), value)),
        "middle_compartment" => write_field(ctx, 3, t::code(middle_modes(), value)),
        "bottom_compartment" => write_field(ctx, 4, t::code(bottom_modes(), value)),
        "one_touch_deodorize" => write_field(ctx, 6, if c::to_bool(value) { 1 } else { 0 }),
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}
