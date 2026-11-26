// LG induction cooktop WBEI3ANHL (KR, three burners): device -> IL driver, READ-ONLY.
// Written from captures of one unit (2026-11-25, rusthinqctl capture --cloud) compared with
// the LG cloud reports of the same moments. Class 0x42 status records are 98 bytes:
// 42 EB carries one record (frame 104 bytes), 42 EC the previous record then the current one
// (frame 202 bytes). WBEI3GT.rhai expects 48-byte records, so on this unit it decodes the
// middle of the previous record.
// Burner blocks are 9 bytes from offset 2 as on WBEI3GT, but here:
//   +0 (state) stayed 0 while a burner was lit, so a burner counts as lit when its power
//      level (+1) is above 0;
//   +1 power level: matched cloud PowerLevel_1_2 (3, then 6) and PowerLevel_3_2 (1);
//   +5 timer display flag and +8 a 1-hour figure followed cloud TimerDisplay_* and
//      RemainTimeHour_*, but no running timer was captured, so neither is published;
//   +2..4 (operation time) did not move and is not published.
// Burner positions: offset 2 left front (lit, confirmed), offset 11 right front (lit,
// confirmed), offset 20 left rear (by position only, never lit in a capture). WBEY3GT has the
// same offset order, but its offset 20 is a highlight (radiant) burner, so on this all-induction
// model the third burner's position is a guess.
// [0] is a bitset (181/176/177) that toggled with cloud FotaEnable/RecipeDownEnable; it is not
// published. No command has been captured, so nothing is ever sent.

import "aabb_common" as c;
import "il_common" as il;

fn burners() {
    [
        #{ key: "lf", offset: 2, label: "Left front burner" },
        #{ key: "rf", offset: 11, label: "Right front burner" },
        #{ key: "lr", offset: 20, label: "Third burner (left rear, position unconfirmed)" }
    ]
}

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        cooking: #{ type: "binary", class: "heat" }
    };
    for b in burners() {
        props[b.key] = #{ type: "binary", group: b.key, label: b.label };
        props[b.key + "_power_level"] = #{ type: "number", series: "gauge", group: b.key, label: b.label + " power level" };
    }
    json_stringify(#{ il: 0, kind: "cooktop", label: "Cooktop", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

// The cooktop reports on change; a reload re-decodes the kept record and sends nothing.
fn start(ctx) {
    let kept = ctx.state_get("last_record");
    if kept != () { publish_record(ctx, hex_decode(kept)); }
}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let inner = c::inner(data, 0x42);
    if inner == () { return; }
    let r = ();
    if inner[1] == 0xeb && inner.len() >= 100 { r = inner.extract(2, 98); }
    if inner[1] == 0xec && inner.len() >= 198 { r = inner.extract(100, 98); }
    if r == () { return; }
    ctx.state_set("last_record", hex_encode_upper(r));
    publish_record(ctx, r);
}

fn publish_record(ctx, r) {
    il::publish_property(ctx, "available", "true");
    let any_on = false;
    for b in burners() {
        let p = r[b.offset + 1];
        if p > 0 { any_on = true; }
        il::publish_property(ctx, b.key, if p > 0 { "true" } else { "false" });
        il::publish_property(ctx, b.key + "_power_level", p.to_string());
    }
    il::publish_property(ctx, "cooking", if any_on { "true" } else { "false" });
}

fn on_set_property(ctx, prop, value) {
    // Every property is read-only, so il::validate publishes the reject; nothing is sent.
    let value = il::validate(ctx, prop, value);
    if value != () { c::reject(ctx, prop, "read-only on this model"); }
}
