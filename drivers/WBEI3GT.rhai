// LG induction cooktop WBEI3GT: device -> IL driver. Port of the owner's rethink
// TypeScript driver (cooktop_wbei3gt.ts). READ-ONLY: there is no wire evidence for
// any command on this model (not even a status request), so this driver sends
// nothing - unlike the sibling WBEY3GT.rhai, a different model whose driver has
// live-verified writes and a different burner map; nothing is borrowed from it.
// Evidence base (the TS driver's, kept explicit): this unit's modelJSON
// Monitoring protocol lists 48 fields - WiFiAccess, FlexMode, five 9-byte burner
// blocks in protocol order LF, LR, RF, RR, Center, then DrawerPowerLevel - and
// exactly one real frame, an idle report (testdata/frames/WBEI3GT.txt), whose
// 48 record bytes match that field count one byte per field. What is confirmed
// is only "an off cooktop reads INIT/0 everywhere"; every nonzero decode below
// is the modelJSON enum order, unverified until lit-burner frames are captured.
//   0xEB carries one record (body >= 50 bytes), 0xEC two (the second is current)
//   [0] WiFiAccess bitset (bit 1 = remote start), [1] flex mode,
//   [47] drawer power level (modelJSON marks it _NOT_USED: diagnostic only)
//   burner block at 2/11/20/29/38: +0 state, +1 power level, +2..4 operation
//   Sec/Min/Hour, +5 timer display (not published), +6..8 remaining Sec/Min/Hour.
//   A burner counts as on unless its state is INIT (0) or LOCK (3) - PAUSED and
//   unknown states report on, the sibling range's call, kept from the TS driver.
//   Unknown enum codes publish as `Unknown (n)`, the TS driver's fallback.

import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn flex_modes() { #{ "0": "OFF", "1": "LEFT_FLEX", "2": "RIGHT_FLEX" } }
fn burner_states() {
    #{ "0": "INIT", "1": "COOKING_IN_PROGRESS", "2": "PAUSED", "3": "LOCK" }
}
// Labels follow this unit's physical burners, not the protocol slot names. The owner's
// unit has three burners (left front, left rear, right); on 2026-11-06 they were lit in
// that order at power 1, 2, 3 and the records lit lf, rf, lr in that order with those
// power levels. On 2026-11-07 a real cook on the left front and right burners lit lf and
// lr, and the cloud named them left_front and right_front. So slot rf is the left rear
// burner and slot lr the right burner; rr and center never changed. Keys stay as they are so entity IDs do not move.
fn burners() {
    [
        #{ key: "lf", offset: 2, label: "Left front burner" },
        #{ key: "lr", offset: 11, label: "Right burner" },
        #{ key: "rf", offset: 20, label: "Left rear burner" },
        #{ key: "rr", offset: 29, label: "Unused slot (right rear)" },
        #{ key: "center", offset: 38, label: "Unused slot (center)" }
    ]
}

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        cooking: #{ type: "binary", label: "Cooking" },
        flex_mode: #{ type: "select", options: t::options(flex_modes()), label: "Flex mode" },
        remote_start: #{ type: "binary", category: "diagnostic", label: "Remote start" },
        drawer_power_level: #{ type: "number", category: "diagnostic", label: "Drawer power level" }
    };
    for b in burners() {
        props[b.key] = #{ type: "binary", label: b.label };
        props[b.key + "_state"] = #{ type: "select", options: t::options(burner_states()), label: b.label + " state" };
        props[b.key + "_power_level"] = #{ type: "number", label: b.label + " power level" };
        props[b.key + "_operation_time"] = #{ type: "number", class: "duration", unit: "s", label: b.label + " operation time" };
        props[b.key + "_timer_remaining"] = #{ type: "number", class: "duration", unit: "s", label: b.label + " timer remaining" };
    }
    json_stringify(#{ il: 0, kind: "cooktop", label: "Cooktop", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

// The cooktop reports only when something changes, so a hot reload (which re-announces
// the entities) left every value unknown until the next use (seen 2026-11-06). The last
// record is kept in driver state and decoded again here; nothing is sent. A fresh attach
// has nothing kept and waits for the cooktop's own record as before.
fn start(ctx) {
    let kept = ctx.state_get("last_record");
    if kept != () { publish_record(ctx, hex_decode(kept)); }
}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

// Selects may only publish listed options (il V-3): an undecoded code
// clears the value instead of publishing an `Unknown (n)` fallback string.
fn publish_enum(ctx, prop, table, raw) {
    let name = t::name(table, raw);
    if name == () { il::publish_absent(ctx, prop); } else { il::publish_property(ctx, prop, name); }
}

// A Sec/Min/Hour triple at `o`, in seconds.
fn duration(r, o) { r[o + 2] * 3600 + r[o + 1] * 60 + r[o] }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let inner = c::inner(data, 0x42);
    if inner == () { return; }
    // The TS driver's length rule is >=, not exact: an EB body of at least
    // 2 + 48, an EC body of at least 2 + 96 (the second record is current).
    let r = ();
    if inner[1] == 0xeb && inner.len() >= 50 { r = inner.extract(2, 48); }
    if inner[1] == 0xec && inner.len() >= 98 { r = inner.extract(50, 48); }
    if r == () { return; }
    ctx.state_set("last_record", hex_encode_upper(r));
    publish_record(ctx, r);
}

fn publish_record(ctx, r) {
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "remote_start", c::bit(r[0], 0x02));
    publish_enum(ctx, "flex_mode", flex_modes(), r[1]);
    il::publish_property(ctx, "drawer_power_level", r[47].to_string());
    let any_on = false;
    for b in burners() {
        let base = b.offset;
        let state = r[base];
        let on = state != 0 && state != 3; // INIT and LOCK are the known not-heating states
        if on { any_on = true; }
        il::publish_property(ctx, b.key, c::on_off(if on { 1 } else { 0 }));
        publish_enum(ctx, b.key + "_state", burner_states(), state);
        il::publish_property(ctx, b.key + "_power_level", r[base + 1].to_string());
        il::publish_property(ctx, b.key + "_operation_time", duration(r, base + 2).to_string());
        il::publish_property(ctx, b.key + "_timer_remaining", duration(r, base + 6).to_string());
    }
    il::publish_property(ctx, "cooking", c::on_off(if any_on { 1 } else { 0 }));
}

// Read-only: il_common's validation rejects every write against the descriptor.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { c::reject(ctx, prop, "read-only driver"); }
}
