// LG kimchi refrigerator 2REK1G04AR180 (4 compartments, ThinQ2, deviceType 102): device -> IL driver.
// Based on the upstream 3REK2G04VK230D_2 driver; mode tables unchanged (they match the
// official lg_thinq integration on this unit). Verified on a live unit, 2026-11-21.
//
// READ-ONLY: on_set_property rejects everything. A write trial with the upstream frame
// (f0 e5 00 02 01 ff 01 00 04 00 03, lower drawer -> vegetables) got no ack and no state
// change; the panel needs unlocking to change modes, and r[7]=1 might be that lock (untested).
// set_property is kept for reference.
//
// Differences found on this unit vs 3REK2G04VK230D_2:
//   - 9-byte EB/EC record (11 eb 02 06 02 00 09 ff 00 01 01), not 39 bytes; the head layout matches.
//   - r[8] is 1 when ALL doors are closed, 0 while any is open (inverted), checked door by door.
//   - Per-door events: 11 a8 <door> <1 open | 0 closed>, door 1 left, 2 right, 3 upper drawer, 4 lower drawer.
//   - 11 af 00 00 00 01 01 is a periodic frame (~every 15 min), not the door buzzer.
//   - 11 cf every 5 min: after the marker aa aa aa ee 5d come signed 16-bit LE values in 0.1 °C.
//     The 6th (20.3-21.1 °C) looks like ambient temperature -> published as an estimate (UNVERIFIED).
//     The 4th (-22..-26 °C) is colder than a thermometer in a freezer-mode compartment (-16.4 °C),
//     so it is probably the evaporator, not compartment air; the 5th looks like a defrost sensor.
//   - No 11 3e energy report in a 2-hour capture, so the energy props are left out.
//
// Record layout (head only):
//   [0] 0x02 constant and [5] 0xff - alignment guards
//   [1] left, [2] right mode (shared table), [3] middle (upper drawer), [4] bottom (lower drawer),
//   [6] one-touch deodorize (1 on), [8] all doors closed (1)

import "aabb_common" as c;
import "fridge_common" as f;
import "table_common" as t;
import "il_common" as il;

fn left_modes() { #{ "0": "맛지킴 김치 (중)", "1": "맛지킴 김치 (강)", "2": "맛지킴 김치 (약)", "3": "냉장 (중)", "4": "냉장 (강)", "5": "냉장 (약)", "6": "냉동", "7": "유산균 김치+", "8": "유산균 김치+ (1단계)", "9": "유산균 김치+ (2단계)", "10": "유산균 김치+ (3단계)", "11": "익힘", "12": "맛지킴 김치 (중) 익힘 완료", "21": "맛지킴 김치 (약)", "22": "맛지킴 김치 (강)", "45": "멀티모드 45", "46": "멀티모드 46", "47": "멀티모드 47", "48": "멀티모드 48", "59": "멀티모드 59", "60": "멀티모드 60", "61": "멀티모드 61", "101": "클라우드 보관" } }
fn middle_modes() { #{ "0": "맛지킴 김치 (중)", "1": "맛지킴 김치 (강)", "2": "맛지킴 김치 (약)", "3": "야채·과일 (중)", "4": "야채·과일 (강)", "5": "야채·과일 (약)", "6": "구입 김치", "7": "유산균 김치+", "8": "유산균 김치+ (1단계)", "9": "유산균 김치+ (2단계)", "10": "유산균 김치+ (3단계)", "11": "익힘", "12": "맛지킴 김치 (중) 익힘 완료", "13": "꺼짐", "21": "맛지킴 김치 (약)", "22": "맛지킴 김치 (강)", "31": "멀티모드 31", "32": "멀티모드 32", "33": "멀티모드 33", "34": "멀티모드 34", "35": "멀티모드 35", "37": "멀티모드 37", "38": "멀티모드 38", "39": "멀티모드 39", "40": "멀티모드 40", "42": "멀티모드 42", "43": "멀티모드 43", "44": "멀티모드 44", "49": "멀티모드 49", "55": "멀티모드 55", "56": "멀티모드 56", "58": "멀티모드 58", "59": "멀티모드 59", "60": "멀티모드 60", "61": "멀티모드 61", "101": "클라우드 보관", "102": "클라우드 익힘", "103": "클라우드 익힘 (1단계)", "104": "클라우드 익힘 (2단계)", "105": "클라우드 익힘 (3단계)" } }
fn bottom_modes() { #{ "0": "맛지킴 김치 (중)", "1": "맛지킴 김치 (강)", "2": "맛지킴 김치 (약)", "3": "야채·과일 (중)", "4": "야채·과일 (강)", "5": "야채·과일 (약)", "6": "쌀·잡곡", "7": "육류/생선", "8": "오래 보관", "9": "꺼짐", "21": "맛지킴 김치 (약)", "22": "맛지킴 김치 (강)", "31": "멀티모드 31", "32": "멀티모드 32", "33": "멀티모드 33", "34": "멀티모드 34", "35": "멀티모드 35", "36": "멀티모드 36", "37": "멀티모드 37", "38": "멀티모드 38", "39": "멀티모드 39", "40": "멀티모드 40", "41": "멀티모드 41", "42": "멀티모드 42", "43": "멀티모드 43", "44": "멀티모드 44", "49": "멀티모드 49", "50": "멀티모드 50", "51": "멀티모드 51", "52": "멀티모드 52", "53": "멀티모드 53", "54": "멀티모드 54", "55": "멀티모드 55", "56": "멀티모드 56", "57": "멀티모드 57", "58": "멀티모드 58", "59": "멀티모드 59", "60": "멀티모드 60", "61": "멀티모드 61", "101": "클라우드 보관" } }

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        left_compartment: #{ type: "select", options: t::options(left_modes()), label: "Left compartment mode" },
        right_compartment: #{ type: "select", options: t::options(left_modes()), label: "Right compartment mode" },
        middle_compartment: #{ type: "select", options: t::options(middle_modes()), label: "Upper drawer mode" },
        bottom_compartment: #{ type: "select", options: t::options(bottom_modes()), label: "Lower drawer mode" },
        room_temperature: #{ type: "number", class: "temperature", series: "gauge", unit: "°C", label: "Room temperature (estimated)" },
        one_touch_filter: #{ type: "binary", label: "One-touch deodorize" },
        door: #{ type: "binary", class: "door", label: "Any door open" },
        door_left: #{ type: "binary", class: "door", label: "Left door" },
        door_right: #{ type: "binary", class: "door", label: "Right door" },
        door_drawer_upper: #{ type: "binary", class: "door", label: "Upper drawer" },
        door_drawer_lower: #{ type: "binary", class: "door", label: "Lower drawer" }
    };
    json_stringify(#{ il: 0, kind: "fridge", label: "Kimchi refrigerator", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn start(ctx) {
    f::query(ctx); // f0 ed 12 11 01 00 00 01 04 00
}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_timer(ctx, name) {}

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let inner = c::inner(data, 0x11);
    if inner == () { return; }
    if inner[1] == 0x3e { return; } // energy report: never seen on this unit
    // Per-door event: 11 a8 <door> <1 open / 0 closed>
    if inner[1] == 0xa8 {
        if inner.len() >= 4 { door_event(ctx, inner[2], inner[3]); }
        return;
    }
    // 5-minute diagnostic frame 11 cf (see header). 6th value = ambient estimate.
    if inner[1] == 0xcf {
        let n = inner.len();
        for i in 2..(n - 17) {
            if inner[i] == 0xaa && inner[i + 1] == 0xaa && inner[i + 2] == 0xaa && inner[i + 3] == 0xee && inner[i + 4] == 0x5d {
                let raw = inner[i + 15] + inner[i + 16] * 256;
                if raw >= 32768 { raw -= 65536; }
                if raw > -400 && raw < 600 {
                    il::publish_property(ctx, "room_temperature", (raw / 10.0).to_string());
                }
                break;
            }
        }
        return;
    }
    let o = c::common_status_offset(inner, 9);
    if o == () { return; }
    record(ctx, inner.extract(o, 9));
}

fn record(ctx, r) {
    if r[0] != 0x02 || r[5] != 0xff { return; }
    il::publish_property(ctx, "available", "true");
    mode(ctx, "left_compartment", left_modes(), r[1]);
    mode(ctx, "right_compartment", left_modes(), r[2]);
    mode(ctx, "middle_compartment", middle_modes(), r[3]);
    mode(ctx, "bottom_compartment", bottom_modes(), r[4]);
    il::publish_property(ctx, "one_touch_filter", c::on_off(r[6]));
    // r[8] = 1 when all doors are closed (inverse of 3REK2G04VK230D_2)
    il::publish_property(ctx, "door", if r[8] == 0 { "true" } else { "false" });
    if r[8] == 1 {
        for p in ["door_left", "door_right", "door_drawer_upper", "door_drawer_lower"] {
            il::publish_property(ctx, p, "false");
        }
    }
}

fn door_event(ctx, door, state) {
    let prop = switch door {
        1 => "door_left",
        2 => "door_right",
        3 => "door_drawer_upper",
        4 => "door_drawer_lower",
        _ => ()
    };
    if prop == () { return; }
    il::publish_property(ctx, prop, if state == 1 { "true" } else { "false" });
}

fn mode(ctx, prop, table, raw) {
    let name = t::name(table, raw);
    if name == () { il::publish_absent(ctx, prop); return; }
    il::publish_property(ctx, prop, name);
}

// The single-field write from 3REK2G04VK230D_2: constant header, then <record index> 00 <value>.
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

// READ-ONLY: see header.
fn on_set_property(ctx, prop, value) {
    c::reject(ctx, prop, "read-only driver");
}

