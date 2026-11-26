// LG water purifier 1WPD4CMBIR__3 (KR): device -> IL driver, READ-ONLY.
// Written from captures of one unit (2026-11-25/26, rusthinqctl capture --cloud) compared with
// the LG cloud reports (wpState) of the same moments. Its frames differ from 1WPD6CMIDR__3 and
// 1WPU4CIGCR__2, so this is a separate, minimal driver. Class 0x12:
//   12 EB one 110-byte record (frame 116 bytes); 12 EC the previous record then the current
//         one (frame 226 bytes). r[2] selected water (1 HOT, 2 NORMAL, 3 COLD; matched cloud
//         waterSelection), r[6] hot water temperature level (3 matched cloud hotWaterTemp 3;
//         255 = not selected, published absent).
//   12 1F dispense report, u16 big-endian: [2..3] normal, [4..5] hot, [6..7] cold. The numbers
//         equal the cloud's normal/hot/coldWaterAmount; the unit is mL (181 read for a 180 mL
//         cold pour). [8..13] stayed 0 (presumably mineral/soda/sterilization; not published).
//   12 AF [2] 15, [3..4] Wh: a 15-minute energy delta, as on 2REBGLUB_2P__. The deltas are added
//         into `energy`, which covers one session (it starts again from 0 on connect).
//   12 B2, 12 CF, 12 0A and F0 0D frames are acknowledged but not decoded.
// No command has been captured, so nothing is ever sent.

import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn water_types() { #{ "1": "HOT", "2": "NORMAL", "3": "COLD" } }

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        water_selection: #{ type: "select", options: t::options(water_types()), label: "Selected water" },
        hot_water_temp_level: #{ type: "number", label: "Hot water temperature level" },
        last_normal_amount: #{ type: "number", class: "volume", series: "gauge", unit: "mL", label: "Last normal water amount" },
        last_hot_amount: #{ type: "number", class: "volume", series: "gauge", unit: "mL", label: "Last hot water amount" },
        last_cold_amount: #{ type: "number", class: "volume", series: "gauge", unit: "mL", label: "Last cold water amount" },
        energy: #{ type: "number", class: "energy", series: "counter", unit: "Wh", label: "Energy" }
    };
    json_stringify(#{ il: 0, kind: "dispenser", class: "water_purifier", label: "Water purifier",
                      vendor: "LG", model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

// The purifier reports on its own; the session energy total starts from 0.
fn start(ctx) { ctx.state_set("energy", 0); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn u16(b, o) { b[o] * 256 + b[o + 1] }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let b = c::inner(data, 0x12);
    if b == () { return; }
    if b[1] == 0xeb && b.len() >= 112 { status(ctx, b.extract(2, 110)); return; }
    if b[1] == 0xec && b.len() >= 222 { status(ctx, b.extract(112, 110)); return; }
    if b[1] == 0x1f && b.len() >= 8 {
        let n = u16(b, 2);
        let h = u16(b, 4);
        let k = u16(b, 6);
        if n > 0 { il::publish_property(ctx, "last_normal_amount", n.to_string()); }
        if h > 0 { il::publish_property(ctx, "last_hot_amount", h.to_string()); }
        if k > 0 { il::publish_property(ctx, "last_cold_amount", k.to_string()); }
        return;
    }
    if b[1] == 0xaf && b.len() >= 5 {
        let total = (ctx.state_get("energy") ?? 0) + u16(b, 3);
        ctx.state_set("energy", total);
        il::publish_property(ctx, "energy", total.to_string());
    }
}

fn status(ctx, r) {
    il::publish_property(ctx, "available", "true");
    let name = t::name(water_types(), r[2]);
    if name == () { il::publish_absent(ctx, "water_selection"); }
    else { il::publish_property(ctx, "water_selection", name); }
    if r[6] == 255 { il::publish_absent(ctx, "hot_water_temp_level"); }
    else { il::publish_property(ctx, "hot_water_temp_level", r[6].to_string()); }
}

fn on_set_property(ctx, prop, value) {
    // Every property is read-only, so il::validate publishes the reject; nothing is sent.
    let value = il::validate(ctx, prop, value);
    if value != () { c::reject(ctx, prop, "read-only on this model"); }
}
