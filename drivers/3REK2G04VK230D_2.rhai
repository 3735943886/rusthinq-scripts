// LG kimchi refrigerator 3REK2G04VK230D_2: device -> IL driver. Port of the owner's
// rethink TypeScript driver (kimchi_3rek2g04vk230d.ts), whose record layout, mode
// tables and write frames were measured on the owner's own unit (2026-11-03; the mode
// tables come from this model's own modelJSON valueMapping). An AABB appliance.
// Inner frames (class 0x11, then):
//   0xEB  one 39-byte status record (the answer to the start query)
//   0xEC  the previous record then the current one, stacked
//   0x3E  energy report - same layout and handling as the 2ROFL2DBN3K_U fridge driver,
//         including the (delta,total,tick) dedupe and the hour/day/month buckets;
//         buckets roll over on elapsed-time timers because Rhai has no wall clock
//         (the TS driver uses KST calendar buckets - the one forced divergence)
//   0x00 0xE5 write ack, 0xE6 write echo, 0x0A/0x31/0xC5 family traffic: ignored
//
// Record layout (only the head is decoded, as in the TS driver):
//   [0] 0x02 constant and [5] 0xff - both are alignment guards; a record failing
//       either is dropped
//   [1] left, [2] right mode (shared table), [3] middle mode, [4] bottom mode,
//   [6] one-touch deodorize filter (1 on), [8] any door open (exactly 1 is open)
// The labels 21/22 in the room tables duplicate 2/1 on purpose (the panel's alternate
// codes); encoding takes the lowest code, which is table_common::code's rule too.
// Writes are the family's single-field frame captured on this unit: the constant
// header f0 e5 00 02 01 ff 01 00, then <record index> 00 <value>. Nothing is published
// optimistically - the 11 EC push with the new value followed every captured write
// within a second. An unknown wire mode publishes the TS driver's fallback string
// `알 수 없음 (<code>)`, which is deliberately outside the select's options.
// The start query is the family-standard frame, byte-identical to fridge_common's.

import "aabb_common" as c;
import "fridge_common" as f;
import "table_common" as t;
import "il_common" as il;
import "energy_common" as e;

fn left_modes() { #{ "0": "맛지킴 김치 (중)", "1": "맛지킴 김치 (강)", "2": "맛지킴 김치 (약)", "3": "냉장 (중)", "4": "냉장 (강)", "5": "냉장 (약)", "6": "냉동", "7": "유산균 김치+", "8": "유산균 김치+ (1단계)", "9": "유산균 김치+ (2단계)", "10": "유산균 김치+ (3단계)", "11": "익힘", "12": "맛지킴 김치 (중) 익힘 완료", "21": "맛지킴 김치 (약)", "22": "맛지킴 김치 (강)", "45": "멀티모드 45", "46": "멀티모드 46", "47": "멀티모드 47", "48": "멀티모드 48", "59": "멀티모드 59", "60": "멀티모드 60", "61": "멀티모드 61", "101": "클라우드 보관" } }
fn middle_modes() { #{ "0": "맛지킴 김치 (중)", "1": "맛지킴 김치 (강)", "2": "맛지킴 김치 (약)", "3": "야채·과일 (중)", "4": "야채·과일 (강)", "5": "야채·과일 (약)", "6": "구입 김치", "7": "유산균 김치+", "8": "유산균 김치+ (1단계)", "9": "유산균 김치+ (2단계)", "10": "유산균 김치+ (3단계)", "11": "익힘", "12": "맛지킴 김치 (중) 익힘 완료", "13": "꺼짐", "21": "맛지킴 김치 (약)", "22": "맛지킴 김치 (강)", "31": "멀티모드 31", "32": "멀티모드 32", "33": "멀티모드 33", "34": "멀티모드 34", "35": "멀티모드 35", "37": "멀티모드 37", "38": "멀티모드 38", "39": "멀티모드 39", "40": "멀티모드 40", "42": "멀티모드 42", "43": "멀티모드 43", "44": "멀티모드 44", "49": "멀티모드 49", "55": "멀티모드 55", "56": "멀티모드 56", "58": "멀티모드 58", "59": "멀티모드 59", "60": "멀티모드 60", "61": "멀티모드 61", "101": "클라우드 보관", "102": "클라우드 익힘", "103": "클라우드 익힘 (1단계)", "104": "클라우드 익힘 (2단계)", "105": "클라우드 익힘 (3단계)" } }
fn bottom_modes() { #{ "0": "맛지킴 김치 (중)", "1": "맛지킴 김치 (강)", "2": "맛지킴 김치 (약)", "3": "야채·과일 (중)", "4": "야채·과일 (강)", "5": "야채·과일 (약)", "6": "쌀·잡곡", "7": "육류/생선", "8": "오래 보관", "9": "꺼짐", "21": "맛지킴 김치 (약)", "22": "맛지킴 김치 (강)", "31": "멀티모드 31", "32": "멀티모드 32", "33": "멀티모드 33", "34": "멀티모드 34", "35": "멀티모드 35", "36": "멀티모드 36", "37": "멀티모드 37", "38": "멀티모드 38", "39": "멀티모드 39", "40": "멀티모드 40", "41": "멀티모드 41", "42": "멀티모드 42", "43": "멀티모드 43", "44": "멀티모드 44", "49": "멀티모드 49", "50": "멀티모드 50", "51": "멀티모드 51", "52": "멀티모드 52", "53": "멀티모드 53", "54": "멀티모드 54", "55": "멀티모드 55", "56": "멀티모드 56", "57": "멀티모드 57", "58": "멀티모드 58", "59": "멀티모드 59", "60": "멀티모드 60", "61": "멀티모드 61", "101": "클라우드 보관" } }

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        left_compartment: #{ type: "select", rw: true, options: t::options(left_modes()), label: "Left compartment mode" },
        right_compartment: #{ type: "select", rw: true, options: t::options(left_modes()), label: "Right compartment mode" },
        middle_compartment: #{ type: "select", rw: true, options: t::options(middle_modes()), label: "Middle compartment mode" },
        bottom_compartment: #{ type: "select", rw: true, options: t::options(bottom_modes()), label: "Bottom compartment mode" },
        one_touch_filter: #{ type: "binary", rw: true, label: "One-touch deodorize" },
        door: #{ type: "binary", class: "door", label: "Any door open" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Energy total" },
        energy_hour: #{ type: "number", class: "energy", unit: "Wh", label: "Energy this hour" },
        energy_day: #{ type: "number", class: "energy", unit: "Wh", label: "Energy today" },
        energy_month: #{ type: "number", class: "energy", unit: "Wh", label: "Energy this month" }
    };
    json_stringify(#{ il: 0, kind: "fridge", label: "Kimchi refrigerator", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn start(ctx) {
    f::query(ctx); // f0 ed 12 11 01 00 00 01 04 00, the frame this unit's traffic shows
    e::start_publish(ctx); // republish buckets only when state survived (see energy_common)
    ctx.set_timer("energy_hour_roll", 3600000);
    ctx.set_timer("energy_day_roll", 86400000);
    ctx.set_timer("energy_month_roll", 2592000000);
}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_timer(ctx, name) {
    e::roll(ctx, name);
}

fn on_data(ctx, data) {
    let inner = c::inner(data, 0x11);
    if inner == () { return; }
    if inner[1] == 0x3e {
        if inner.len() == 7 { e::report(ctx, inner[3], inner[4] * 256 + inner[5], inner[6]); }
        return;
    }
    let o = c::common_status_offset(inner, 39);
    if o == () { return; }
    record(ctx, inner.extract(o, 39));
}

fn record(ctx, r) {
    // Alignment guard: the family constants must hold (the TS driver's rule).
    if r[0] != 0x02 || r[5] != 0xff { return; }
    il::publish_property(ctx, "available", "true");
    mode(ctx, "left_compartment", left_modes(), r[1]);
    mode(ctx, "right_compartment", left_modes(), r[2]);
    mode(ctx, "middle_compartment", middle_modes(), r[3]);
    mode(ctx, "bottom_compartment", bottom_modes(), r[4]);
    il::publish_property(ctx, "one_touch_filter", c::on_off(r[6]));
    il::publish_property(ctx, "door", c::on_off(r[8]));
}

fn mode(ctx, prop, table, raw) {
    // Selects may only publish listed options (il V-3): an undecoded code
    // clears the value instead of publishing a fallback string.
    let name = t::name(table, raw);
    if name == () { il::publish_absent(ctx, prop); return; }
    il::publish_property(ctx, prop, name);
}

// The single-field write: constant header, then <record index> 00 <value>.
fn write_field(ctx, index, value) {
    let msg = hex_decode("f0e5000201ff0100");
    msg.push(index);
    msg.push(0);
    msg.push(value);
    ctx.send_raw(aabb_wrap(msg));
}

fn set_compartment(ctx, prop, table, index, value) {
    let code = t::code(table, value);
    if code == () { c::reject(ctx, prop, "unknown compartment mode"); return; }
    write_field(ctx, index, code);
}

fn set_property(ctx, prop, value) {
    switch prop {
        "left_compartment" => set_compartment(ctx, prop, left_modes(), 1, value),
        "right_compartment" => set_compartment(ctx, prop, left_modes(), 2, value),
        "middle_compartment" => set_compartment(ctx, prop, middle_modes(), 3, value),
        "bottom_compartment" => set_compartment(ctx, prop, bottom_modes(), 4, value),
        "one_touch_filter" => write_field(ctx, 6, if c::to_bool(value) { 1 } else { 0 }),
        _ => { c::reject(ctx, prop, "unknown or read-only property"); }
    }
}

fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
