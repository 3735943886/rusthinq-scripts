// LG combi oven WMLJ32RS: device -> IL driver. Port of the owner's rethink
// TypeScript driver (oven_wmlj32rs.ts). READ-ONLY: the TS driver sends nothing at
// all (no AABB course-send frame for this model has ever been captured, and its
// modelJSON control surface is LG-cloud remote-start commands), so this driver
// has no writable property and never sends.
// The one decoded frame shape is the state frame: inner bytes are exactly 97 -
// [0..1] 40 eb, [2..7] an undecoded 6-byte header, then the 89-byte state record
// in this model's own modelJSON Monitoring.protocol order. Only the fields the
// TS driver publishes are read:
//   [0] oven_state (0 = 'initial', anything else `unknown_<n>` - modelJSON gives
//       option names, not wire numbers, and the sibling ML32PWFOTA's live map
//       contradicts this model's enum order, so no further names are assigned)
//   [1] standby (0 'normal', 1 'standby'), [2] control_lock and [3] error
//       (0 'disable', 1 'enable'), [14] cook_mode (0 'standby', else unknown_<n>)
//   [16] target temperature, [34] current temperature - the modelJSON field
//       names carry _F, but protocol [22] is MonTempUnit (modelJSON: 0 = C,
//       1 = F) and says how these values are encoded; this unit reports 0
//       (CELSIUS - also the model's SetCookStart unit), so values publish as
//       °C, converting only if the flag ever reads 1.
//   [25..27] remaining H/M/S and [28..30] target H/M/S, published as seconds.
//       The timer fields after [30] are NOT read: in the captured frame [31]
//       reads 0x53, impossible for an hour field, so the tail alignment is
//       suspect past [30] (the TS driver's reasoning, kept).

import "aabb_common" as c;
import "il_common" as il;

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        oven_state: #{ type: "text", label: "Oven state" },
        cook_mode: #{ type: "text", label: "Cook mode" },
        target_temperature: #{ type: "number", class: "temperature", unit: "°C", label: "Target temperature" },
        current_temperature: #{ type: "number", class: "temperature", unit: "°C", label: "Current temperature" },
        remaining_time: #{ type: "number", class: "duration", unit: "s", label: "Remaining time" },
        target_time: #{ type: "number", class: "duration", unit: "s", label: "Target time" },
        standby: #{ type: "text", category: "diagnostic", label: "Standby" },
        control_lock: #{ type: "text", category: "diagnostic", label: "Control lock" },
        error: #{ type: "text", category: "diagnostic", label: "Error" }
    };
    json_stringify(#{ il: 0, kind: "oven", label: "Oven", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn start(ctx) {}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn flag(b, zero, one) {
    if b == 0 { zero } else if b == 1 { one } else { "unknown_" + b.to_string() }
}

fn temp_c(r, idx) {
    let v = r[idx];
    if r[22] == 1 { ((v.to_float() - 32.0) * 5.0 / 9.0 * 10.0).round() / 10.0 } else { v }
}

fn on_data(ctx, data) {
    let inner = c::inner(data, 0x40);
    if inner == () { return; }
    // Only this exact shape is decoded; anything else is not parsed on a guess.
    if inner.len() != 97 || inner[1] != 0xeb { return; }
    let r = inner.extract(8, 89);
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "oven_state", if r[0] == 0 { "initial" } else { "unknown_" + r[0].to_string() });
    il::publish_property(ctx, "standby", flag(r[1], "normal", "standby"));
    il::publish_property(ctx, "control_lock", flag(r[2], "disable", "enable"));
    il::publish_property(ctx, "error", flag(r[3], "disable", "enable"));
    il::publish_property(ctx, "cook_mode", if r[14] == 0 { "standby" } else { "unknown_" + r[14].to_string() });
    il::publish_property(ctx, "target_temperature", temp_c(r, 16).to_string());
    il::publish_property(ctx, "current_temperature", temp_c(r, 34).to_string());
    il::publish_property(ctx, "remaining_time", (r[25] * 3600 + r[26] * 60 + r[27]).to_string());
    il::publish_property(ctx, "target_time", (r[28] * 3600 + r[29] * 60 + r[30]).to_string());
}

// Read-only: il_common's validation rejects every write against the descriptor.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { c::reject(ctx, prop, "read-only driver"); }
}
