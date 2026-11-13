// LG dishwasher H01 (식기세척기): device -> IL driver. Port of kshexe/rethink's H01.ts
// (https://github.com/kshexe/rethink, commit 8fa8bd4), a fork of upstream rethink whose frames
// were captured against a real unit (2026-09-10..18), each field by toggling one control and
// diffing. An AABB appliance, class 0x32, status as EB (one) / EC (previous, current) 26-byte
// records (aabb_common::common_status_offset).
//
// Record: [2] 0x01 on, 0x04 off (four on/off cycles); [5]/[6] course length h/m; [7] course
//   index (1 auto, 2 heavy, 5 standard, 9 tub sterilize, 15 dry only, 16 night quiet; the
//   download slot shows which download is active, so it stays a number); [11] reservation
//   hours; [13] 0x10 auto select, 0x40 wash complete light; [14] 0x80 steam, 0x40 intensive
//   top rack, 0x20 intensive bottom rack, 0x08 high-temperature sterilize; [17] 0x04 extra
//   rinse, 0x08 time display, (>> 4) & 3 hot air dry tier (0, 40, 60, 90 min); [18] 0x01 cool
//   dry (보관), 0x04 end melody, 0x10 filter reminder.
//
// Writes (each captured on this unit unless noted):
//   power      f0 26 16 on / 12 off
//   settings   f0 26 00 00 <b4> <b5> 00 00 00 00 - the six settings in one write, at other bits
//              than the record reads them: b4 0x08 wash complete light, 0x10 time display,
//              0x20 auto select, 0x40 end melody, 0x80 cool dry; b5 0x02 filter reminder, 0x80
//              always set. A write takes the other five from the last record, so it is refused
//              until a record has arrived. The app offers them only while the appliance is on.
//   start      f0 26 10 <course> 00 00 00 00 00 - NOT captured here: the shape of upstream's H11
//              and N02 with this unit's course indices, as the fork sends it (labelled
//              unverified, as there). `target_course` is the local selection it uses.
// Energy: the 32 3e report of upstream H11 (<u16 delta> <u16 cycle total> <n>), likewise never
//   seen from this unit (the fork's test is constructed); `energy` is the report's total. The
//   fork's hour/day/month totals, kept on disk by calendar, are not ported.
// Divergences from the fork: nothing is published from a write (the fork is optimistic; the
// next record reads every written value back).
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn rec_len() { 26 }

fn start_courses() { #{ "1": "자동", "2": "강력", "5": "표준", "9": "통살균", "15": "건조단독", "16": "야간조용" } }

// Each setting: where the record reads it, and its bit in the settings write.
fn settings() {
    #{
        wash_complete_light: #{ at: 13, bit: 0x40, b4: 0x08 },
        auto_select: #{ at: 13, bit: 0x10, b4: 0x20 },
        time_indicator: #{ at: 17, bit: 0x08, b4: 0x10 },
        cool_dry: #{ at: 18, bit: 0x01, b4: 0x80 },
        end_alarm_sound: #{ at: 18, bit: 0x04, b4: 0x40 },
        air_filter: #{ at: 18, bit: 0x10, b5: 0x02 }
    }
}

fn descriptor(ctx) {
    let config = #{ type: "binary", rw: true, category: "config" };
    let props = #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", role: "on", rw: true, label: "Power" },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Course duration" },
        course_index: #{ type: "number", category: "diagnostic", label: "Course index" },
        reservation_hours: #{ type: "number", class: "duration", unit: "h", label: "Reservation delay" },
        steam: #{ type: "binary", label: "Steam" },
        intensive_wash_top: #{ type: "binary", label: "Intensive wash (top rack)" },
        intensive_wash_bottom: #{ type: "binary", label: "Intensive wash (bottom rack)" },
        high_temp: #{ type: "binary", label: "High-temperature sterilize" },
        extra_rinse: #{ type: "binary", label: "Extra rinse" },
        heat_dry: #{ type: "number", class: "duration", unit: "min", label: "Hot air dry" },
        target_course: #{ type: "select", rw: true, options: t::options(start_courses()), label: "Course for start (unverified)" },
        start_course: #{ type: "trigger", label: "Start course (unverified)" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Cycle energy" }
    };
    let labels = #{ wash_complete_light: "Wash complete light", auto_select: "Auto select",
                    time_indicator: "Time display", cool_dry: "Cool dry (storage)",
                    end_alarm_sound: "End melody", air_filter: "Filter reminder" };
    for k in labels.keys() { let p = config; p.label = labels[k]; props[k] = p; }
    json_stringify(#{ il: 0, kind: "washer", class: "dishwasher", label: "Dishwasher", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn start(ctx) {
    ctx.send_raw(aabb_wrap(hex_decode("f0ed1211010000010400")));
    let course = ctx.state_get("target_course");
    if course != () { il::publish_property(ctx, "target_course", course); }
}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let b = c::inner(data, 0x32);
    if b == () { return; }
    if b[1] == 0x3e {
        if b.len() == 7 {
            il::publish_property(ctx, "energy", (b[4] * 256 + b[5]).to_string());
        }
        return;
    }
    let o = c::common_status_offset(b, rec_len());
    if o != () { record(ctx, b.extract(o, rec_len())); }
}

fn record(ctx, r) {
    ctx.state_set("record", hex_encode(r)); // a Blob is not a state value
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if r[2] == 0x01 { "true" } else { "false" });
    il::publish_property(ctx, "initial_time", (r[5] * 60 + r[6]).to_string());
    il::publish_property(ctx, "course_index", r[7].to_string());
    il::publish_property(ctx, "reservation_hours", r[11].to_string());
    il::publish_property(ctx, "steam", c::bit(r[14], 0x80));
    il::publish_property(ctx, "intensive_wash_top", c::bit(r[14], 0x40));
    il::publish_property(ctx, "intensive_wash_bottom", c::bit(r[14], 0x20));
    il::publish_property(ctx, "high_temp", c::bit(r[14], 0x08));
    il::publish_property(ctx, "extra_rinse", c::bit(r[17], 0x04));
    il::publish_property(ctx, "heat_dry", [0, 40, 60, 90][(r[17] >> 4) & 0x03].to_string());
    let s = settings();
    for k in s.keys() { il::publish_property(ctx, k, c::bit(r[s[k].at], s[k].bit)); }
}

fn send_settings(ctx, prop, on) {
    let r = ctx.state_get("record");
    if r == () { return c::reject(ctx, prop, "no status record reported yet"); }
    r = hex_decode(r);
    let b4 = 0;
    let b5 = 0x80;
    let s = settings();
    for k in s.keys() {
        let set = if k == prop { on } else { (r[s[k].at] & s[k].bit) != 0 };
        if set {
            if s[k].b4 != () { b4 = b4 | s[k].b4; } else { b5 = b5 | s[k].b5; }
        }
    }
    ctx.send_raw(aabb_wrap([0xf0, 0x26, 0x00, 0x00, b4, b5, 0x00, 0x00, 0x00, 0x00]));
}

fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value == () { return; }
    if settings().contains(prop) { return send_settings(ctx, prop, c::to_bool(value)); }
    switch prop {
        "power" => ctx.send_raw(aabb_wrap([0xf0, 0x26, if c::to_bool(value) { 0x16 } else { 0x12 }])),
        "target_course" => {
            // A local selection for start_course, not a device value.
            ctx.state_set("target_course", value);
            il::publish_property(ctx, "target_course", value);
        }
        "start_course" => {
            let course = ctx.state_get("target_course");
            if course == () { return c::reject(ctx, prop, "select target_course first"); }
            ctx.send_raw(aabb_wrap([0xf0, 0x26, 0x10, t::code(start_courses(), course), 0, 0, 0, 0, 0]));
        }
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}
