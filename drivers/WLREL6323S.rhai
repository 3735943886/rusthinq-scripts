// LG electric range LREL6323S (modelName WLREL6323S): port of upstream rethink's WLREL6323S.ts
// (commit 0e57069). Read only: no write has been captured.
//
// Status is a 0x40 EB frame of one 62-byte block or EC of two (previous, current); block offsets:
// 0 oven state   1 oven mode   5-6 oven setpoint (big endian, °F; 0 when no cook is programmed or
// the mode has none)   11 bit 3 the oven door open   36/38 normal surface elements, 37/39 the
// warming zone; individual elements report alike, so they are one aggregate cooktop state. A
// setpoint of 0 and a state or mode the tables do not name are published absent.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn states() { #{ "0": "idle", "1": "preheating", "2": "cooking", "4": "cooling", "9": "cleaning" } }

fn modes() {
    #{ "0": "none", "1": "bake", "3": "convection_bake", "4": "convection_roast", "7": "broil", "8": "warm",
       "13": "easy_clean", "15": "self_clean", "16": "air_fry" }
}

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "oven", label: "Electric range", vendor: "LG", model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        cooktop_status: #{ type: "binary", label: "Cooktop" },
        oven_status: #{ type: "select", options: ["idle", "preheating", "cooking", "cooling", "cleaning"] },
        oven_mode: #{ type: "select", options: ["none", "bake", "convection_bake", "convection_roast", "broil", "warm",
                                                 "easy_clean", "self_clean", "air_fry"] },
        oven_set_temperature: #{ type: "number", class: "temperature", unit: "°F" },
        oven_door: #{ type: "binary", class: "door" }
    } })
}

fn start(ctx) {
    ctx.send_raw(aabb_wrap(hex_decode("f0ed114101000000181a0207080c14191a1e262b30353a00000000000000000000000000")));
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn publish_name(ctx, prop, name) {
    if name == () { il::publish_absent(ctx, prop); } else { il::publish_property(ctx, prop, name); }
}

fn on_data(ctx, data) {
    let b = c::inner(data, 0x40);
    let o = c::common_status_offset(b, 62);
    if o == () { return; }
    let r = b.extract(o, 62);
    il::publish_property(ctx, "available", "true");
    publish_name(ctx, "oven_status", t::name(states(), r[0]));
    publish_name(ctx, "oven_mode", t::name(modes(), r[1]));
    let set = r[5] * 256 + r[6];
    if set == 0 { il::publish_absent(ctx, "oven_set_temperature"); }
    else { il::publish_property(ctx, "oven_set_temperature", set.to_string()); }
    il::publish_property(ctx, "oven_door", if (r[11] & 0x08) != 0 { "true" } else { "false" });
    let cooktop = r[36] != 0 || r[37] != 0 || r[38] != 0 || r[39] != 0;
    il::publish_property(ctx, "cooktop_status", if cooktop { "true" } else { "false" });
}

fn on_set_property(ctx, prop, value) { il::validate(ctx, prop, value); }
