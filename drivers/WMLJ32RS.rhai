// LG combi oven WMLJ32RS: device -> IL driver. READ-ONLY (no control frame for this
// model has ever been captured), so it has no writable property and never sends.
//
// State frames are AA <len> 40 EB|EC ...: EB carries one 95-byte state record, EC the
// previous record followed by the current one (aabb_common::common_status_offset).
// The unit sends EC on every change while it is used and EB only now and then, so a
// driver that reads EB alone sees almost nothing of a cooking session.
//
// Record layout, decoded from a capture of 2026-11-06 lined up second by second with the
// LG cloud's own state for the same unit (preference -> preheating -> paused ->
// cooking -> paused -> initial; air fry at 180 then 185 C, 1:20 timer):
//   [0]  oven state: 0 initial, 1 preheating, 2 cooking, 4 paused, 5 done (a second
//        capture, a 10 s cook run to the end, matched the cloud's "done"),
//        7 preference (setting up a cook), 10 ready to start (a
//        cook sent from the app, waiting for the start button). Other codes (cooling, cleaning ...) were not in
//        the captures and publish as unknown_<n> rather than a guessed name.
//   [3]  1 while the unit idles, 0 while a cook is being set up or runs
//   [5]  cook mode; 0 when idle, others unknown_<n>. Mapped on 2026-11-06 by sending each
//        modelJSON cook name (SetCookStart, cmdOptionSetCookName) through the LG cloud and
//        reading the code the unit reported in its ready-to-start record (each was then
//        cancelled with SetCookStop): RANGE 1, RANGE_STEAM 2, GRILL 3, OVEN 4,
//        OVEN_STEAM 5, STEAM 6, DRY 7, FERMENTATION 9, FERMENTATION_STEAM 10, AIRFRY 11,
//        AIRSOUSVIDE 13. 0x15 is defrost (INVERTER_DEFROST, not sent by hand): the LG app's own
//        frame for it carried the 0.2 kg default weight only that mode has.
//   [8..9] big-endian set temperature (0xb4 180, 0xb9 185 - the cloud reported exactly
//        these). [6..7] reads 0xd2 only in defrost, so it is not a temperature.
//   [15..17] remaining h/m/s, [18..20] set cook time h/m/s (1:20 counting down
//        1:17, 1:14, 1:12 as the cloud's timeline ran)
//   [30] bit 0x20 set during the preheat phase (also while paused in it)
// The old driver read these 6 bytes off ([0] there was [6] here), so its control_lock
// and error were the high and low byte of the set temperature, and its current
// temperature is not a field this capture can confirm; those three are gone.

import "aabb_common" as c;
import "il_common" as il;

fn rec_len() { 95 }

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        oven_state: #{ type: "text", label: "Oven state" },
        cook_mode: #{ type: "text", label: "Cook mode" },
        target_temperature: #{ type: "number", class: "temperature", unit: "°C", label: "Target temperature" },
        remaining_time: #{ type: "number", class: "duration", unit: "s", label: "Remaining time" },
        target_time: #{ type: "number", class: "duration", unit: "s", label: "Target time" },
        preheat_phase: #{ type: "binary", label: "Preheat phase" },
        standby: #{ type: "text", category: "diagnostic", label: "Standby" }
    };
    json_stringify(#{ il: 0, kind: "oven", label: "Oven", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

// The unit sends a state record only when something changes (and once on connect), so a
// hot reload would leave every entity empty until the oven is next used. Each published
// value is kept in driver state and republished on start; nothing is sent.
fn start(ctx) {
    let keys = ctx.state_get("kept_keys");
    if keys == () { return; }
    for k in keys.split(",") {
        if k == "" { continue; }
        let v = ctx.state_get("kept_" + k);
        if v != () { il::publish_property(ctx, k, v); }
    }
}

fn pubp(ctx, prop, value) {
    il::publish_property(ctx, prop, value);
    ctx.state_set("kept_" + prop, value);
    let keys = ctx.state_get("kept_keys");
    if keys == () { keys = ""; }
    if !("," + keys + ",").contains("," + prop + ",") {
        ctx.state_set("kept_keys", if keys == "" { prop } else { keys + "," + prop });
    }
}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn state_name(v) {
    switch v {
        0 => "initial",
        1 => "preheating",
        2 => "cooking",
        4 => "paused",
        5 => "done",
        7 => "preference",
        10 => "ready_to_start",
        _ => "unknown_" + v.to_string()
    }
}

fn mode_name(v) {
    switch v {
        0 => "none",
        0x01 => "microwave",
        0x02 => "steam_microwave",
        0x03 => "grill",
        0x04 => "oven",
        0x05 => "steam_oven",
        0x06 => "steam",
        0x07 => "dehydrate",
        0x09 => "ferment",
        0x0a => "steam_ferment",
        0x0b => "air_fry",
        0x0d => "air_sous_vide",
        0x15 => "defrost",
        _ => "unknown_" + v.to_string()
    }
}

fn be16(r, i) { r[i] * 256 + r[i + 1] }

fn hms(r, i) { r[i] * 3600 + r[i + 1] * 60 + r[i + 2] }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let body = c::inner(data, 0x40);
    if body == () { return; }
    let off = c::common_status_offset(body, rec_len());
    if off == () { return; }
    let r = body.extract(off, rec_len());
    il::publish_property(ctx, "available", "true");
    pubp(ctx, "oven_state", state_name(r[0]));
    pubp(ctx, "standby", if r[3] == 1 { "standby" } else { "in_use" });
    pubp(ctx, "cook_mode", mode_name(r[5]));
    let t = be16(r, 8);
    pubp(ctx, "target_temperature", t.to_string());
    pubp(ctx, "remaining_time", hms(r, 15).to_string());
    pubp(ctx, "target_time", hms(r, 18).to_string());
    pubp(ctx, "preheat_phase", if (r[30] & 0x20) != 0 { "true" } else { "false" });
}

// Read-only: il_common's validation rejects every write against the descriptor.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { c::reject(ctx, prop, "read-only driver"); }
}
