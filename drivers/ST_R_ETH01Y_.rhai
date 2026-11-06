// LG Styler ST_R_ETH01Y_: device -> IL driver. Port of the owner's rethink
// TypeScript driver (styler_st_r_eth01y.ts, adapted from kshexe's), whose frames were
// captured against a real unit on 2026-09-09..18. This model does NOT use the plain
// EB/EC status family: status rides a MSG_TUNNEL envelope (from-device class 0x31,
// byte 1 = 0x0a), and all writes are F0 E5 settings writes
// (`f0 e5 00 02 01 ff <n> [<key> <value>]*n`; the reserve key 0x7f is 16-bit).
//
//   power      key 0x02, 0/1. Its command echo is not readable (one ambiguous
//              capture), so - as in the TS driver - the write is published
//              optimistically and the status record's power byte confirms it.
//   course     a local selection only (no frame): what the next `start` will use.
//              Defaults to the appliance's own default course (강력 스타일링, 0x04).
//   start      one 4-key write: course, key 0x23 = 0 (present in every capture,
//              meaning unconfirmed, reproduced literally), reserve 0x7f = 0,
//              operation key 0x03 = 1.
//   smart care keys 0x1c (fine dust), 0x1b (humidity), 0x1a (night care), captured in
//              both directions; published optimistically like the TS driver. The
//              status record carries no readback for them, so a write that never
//              lands stays published as set.
//
// Status record (36 bytes, extracted from the tunnel envelope the FX___S way):
//   [2] course id, [6] expected duration in minutes, [9] power (nonzero = on).
//   The record start (records from payload[10], body[14] overall) sits one byte
//   later than aabb_common::enveloped_status (body[13]). This model's framing
//   differs, but the offset is NOT yet verified against a raw live capture of
//   this model - the tests are constructed on the same assumption. Check this
//   offset first when a capture becomes available.
//   The course id resets to 0 while off, so active_course / duration_minutes are
//   only published while on. A course id with no confirmed name publishes
//   `unknown_<id>` (the TS driver's fallback).
// Notifications arrive as <0x31> 72 00 <code>: 0 = styling_is_complete,
// 100 = error_has_occurred (one sample only - tentative, as in the TS driver).
// They are published as non-retained events carrying {"event_type": ...}, the TS
// driver's shape. The write ack (<sub> 00 e5 00) is recognised and ignored.

import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn courses() {
    #{
        "1": "표준 스타일링", "2": "인공지능 스타일링", "3": "급속 스타일링", "4": "강력 스타일링",
        "5": "정장/코트 스타일링", "6": "울/니트 스타일링", "9": "미세먼지 제거", "10": "표준 살균",
        "11": "바이러스 살균", "13": "셔츠 한 벌 건조", "14": "인공지능 건조", "15": "실내 제습",
        "17": "침구,베개 살균", "18": "모피/가죽 스타일링", "19": "패딩 건조", "20": "패딩 스타일링",
        "23": "시간 건조", "27": "눈/비 건조", "28": "담요 데우기", "29": "목도리 스타일링",
        "31": "아기옷 살균", "37": "인형 살균", "42": "청바지 스타일링"
    }
}

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", rw: true, label: "Power" },
        course: #{ type: "select", rw: true, options: t::options(courses()), label: "Course for next start" },
        start: #{ type: "trigger", label: "Start course" },
        active_course: #{ type: "text", category: "diagnostic", label: "Active course" },
        duration_minutes: #{ type: "number", class: "duration", unit: "min", category: "diagnostic", label: "Course duration" },
        notification: #{ type: "text", category: "diagnostic", label: "Notification" },
        smart_care_fine_dust: #{ type: "binary", rw: true, category: "config", label: "Smart care fine dust" },
        smart_care_humidity: #{ type: "binary", rw: true, category: "config", label: "Smart care humidity" },
        smart_care_night_care: #{ type: "binary", rw: true, category: "config", label: "Smart care night care" }
    };
    json_stringify(#{ il: 0, kind: "clothing_care", label: "Styler", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn start(ctx) {
    // The TS driver publishes the initially selected course from its constructor.
    il::publish_property(ctx, "course", t::name(courses(), selected(ctx)));
}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn selected(ctx) {
    let v = ctx.state_get("selected_course");
    if v == () { 4 } else { v } // 강력 스타일링, the appliance's own default
}

// Builds `f0 e5 00 02 01 ff <n> [<key> <value>]*n`; a pair value may be a two-byte
// array for the 16-bit reserve key.
fn settings_write(ctx, pairs) {
    let msg = [0xf0, 0xe5, 0x00, 0x02, 0x01, 0xff, pairs.len()];
    for pair in pairs {
        msg.push(pair[0]);
        if type_of(pair[1]) == "array" { msg.push(pair[1][0]); msg.push(pair[1][1]); }
        else { msg.push(pair[1]); }
    }
    ctx.send_raw(aabb_wrap(msg));
}

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let body = c::inner(data, 0x31);
    if body == () { return; }

    // Write ack: <sub> 00 e5 00 - confirms the write landed, nothing to publish.
    if body.len() == 4 && body[1] == 0x00 && body[2] == 0xe5 && body[3] == 0x00 { return; }

    // Notification channel: <0x31> 72 00 <code>; frame length is not fixed.
    if body[1] == 0x72 && body.len() > 3 && body[2] == 0 {
        let name = t::name(#{ "0": "styling_is_complete", "100": "error_has_occurred" }, body[3]);
        if name != () {
            il::publish_event(ctx, "notification", json_stringify(#{ event_type: name }));
        }
        return;
    }

    // Status record inside the MSG_TUNNEL envelope.
    if body[1] == 0x0a {
        let extended = body.len() >= 4 && (body[2] * 256 + body[3]) == body.len() + 4;
        let payload = if extended { body.extract(4) } else { body.extract(2) };
        if payload.len() <= 6 { return; }
        let offset = if payload[6] == 0xec { 36 } else if payload[6] == 0xeb { 0 } else { -1 };
        if offset < 0 { return; }
        let records = payload.extract(10);
        if records.len() < offset + 36 { return; }
        record(ctx, records.extract(offset, 36));
    }
}

fn record(ctx, r) {
    il::publish_property(ctx, "available", "true");
    let on = r[9] != 0;
    // The TS driver publishes power only when it changes.
    if ctx.state_get("power") != on {
        ctx.state_set("power", on);
        il::publish_property(ctx, "power", if on { "true" } else { "false" });
        if !on {
            il::publish_absent(ctx, "active_course");
            il::publish_absent(ctx, "duration_minutes");
        }
    }
    if on {
        let name = t::name(courses(), r[2]);
        if name == () { name = "unknown_" + r[2].to_string(); }
        il::publish_property(ctx, "active_course", name);
        il::publish_property(ctx, "duration_minutes", r[6].to_string());
    }
}

fn set_property(ctx, prop, value) {
    switch prop {
        "power" => {
            let on = c::to_bool(value);
            settings_write(ctx, [[0x02, if on { 1 } else { 0 }]]);
            ctx.state_set("power", on);
            il::publish_property(ctx, "power", value); // optimistic; the record confirms
        }
        "smart_care_fine_dust" => {
            settings_write(ctx, [[0x1c, if c::to_bool(value) { 1 } else { 0 }]]);
            il::publish_property(ctx, "smart_care_fine_dust", value); // optimistic
        }
        "smart_care_humidity" => {
            settings_write(ctx, [[0x1b, if c::to_bool(value) { 1 } else { 0 }]]);
            il::publish_property(ctx, "smart_care_humidity", value); // optimistic
        }
        "smart_care_night_care" => {
            settings_write(ctx, [[0x1a, if c::to_bool(value) { 1 } else { 0 }]]);
            il::publish_property(ctx, "smart_care_night_care", value); // optimistic
        }
        "course" => {
            let code = t::code(courses(), value);
            if code == () { c::reject(ctx, prop, "unknown course"); return; }
            ctx.state_set("selected_course", code);
            il::publish_property(ctx, "course", value); // a selection, not a frame
        }
        "start" => {
            settings_write(ctx, [
                [0x0a, selected(ctx)],
                [0x23, 0],
                [0x7f, [0, 0]],
                [0x03, 1]
            ]);
        }
        _ => { c::reject(ctx, prop, "unknown or read-only property"); }
    }
}

fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
