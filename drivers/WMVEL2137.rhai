// LG over-the-range microwave/hood WMVEL2137 (MVEL2033F): port of upstream rethink's
// WMVEL2137.ts (commit 0e57069). Not the same appliance as WMVEM1825: four vent speeds, not two.
//
// Status is a 0x41 EB frame of one 46-byte block or EC of two (previous, current); block offsets:
// 0 state   5 cook mode family   6-7 dish id (big endian)   10 power level (0-10, x10 %)
// 16/17 remaining time (minutes, seconds; the minutes byte counts past 60)   18/19/20 the length
// the cook was given (h, min, s)   22/23 kitchen timer (minutes, seconds)   35 always 0x53, a check
// that the block is aligned   36 vent speed (low nibble, 0-4) and lamp level (high nibble, 0-2).
// A state, cook mode or dish this table does not name is cleared rather than guessed.
//
// A hood command is F0 43 22 04 <fan cmd> <fan> <lamp cmd> <lamp> 80 80, where cmd 01 sets the
// absolute level that follows, 00 turns the control off and 80 leaves it as it is; so each command
// touches one control only. Turning a control on restores the last level it reported.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn states() { #{ "0": "idle", "2": "cooking", "4": "paused", "5": "done", "7": "settings" } }

fn modes() { #{ "0": "off", "1": "microwave", "21": "inverter_defrost", "24": "sensor_cook", "31": "auto_cook" } }

// Dish ids are sparse and named off the panel; 0 is no dish chosen.
fn items() { #{
    "0": "none", "211": "defrost_meat", "212": "defrost_poultry", "213": "defrost_fish",
    "214": "defrost_bread", "243": "potato", "245": "boiling_water", "246": "canned_vegetables",
    "247": "casserole", "248": "chicken_pieces", "249": "fish_fillets",
    "250": "fresh_vegetables_hard", "251": "fresh_vegetables_soft", "252": "frozen_lasagna",
    "253": "frozen_vegetables", "254": "popcorn", "255": "rice", "256": "shrimp",
    "258": "reheat_baked_goods", "259": "beverage", "260": "reheat_casserole",
    "261": "reheat_dinner_plate", "263": "reheat_pizza", "264": "reheat_soup_or_sauce",
    "3338": "kids_corn_dog", "3346": "kids_mac_and_cheese", "3354": "soften_butter",
    "3355": "soften_cream_cheese", "3357": "soften_frozen_juice", "3358": "soften_ice_cream",
    "3359": "melt_butter", "3361": "melt_cheese", "3362": "melt_chocolate",
    "3363": "melt_marshmallow", "3364": "steam_asparagus", "3365": "steam_broccoli",
    "3366": "steam_brussels_sprouts", "3367": "steam_carrots", "3368": "steam_chicken_breast",
    "3369": "steam_fish", "3370": "steam_zucchini", "3378": "kids_chicken_nuggets"
} }

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "microwave", label: "Microwave", vendor: "LG", model: ctx.model_id(),
                      groups: #{ vent: #{ kind: "fan", label: "Vent fan" }, light: #{ kind: "light", label: "Cooktop light" } },
                      props: #{
        available: #{ type: "binary", role: "available" },
        status: #{ type: "select", options: t::options(states()) },
        cook_mode: #{ type: "select", options: t::options(modes()) },
        cook_item: #{ type: "select", options: t::options(items()) },
        power_level: #{ type: "number", unit: "%" },
        remaining_time: #{ type: "number", class: "duration", unit: "s" },
        cook_time: #{ type: "number", class: "duration", unit: "s" },
        timer: #{ type: "number", class: "duration", unit: "s", label: "Kitchen timer" },
        fan_power: #{ type: "binary", rw: true, role: "on", group: "vent", label: "Vent fan" },
        fan_speed: #{ type: "number", rw: true, min: 0, max: 4, step: 1, group: "vent" },
        light_power: #{ type: "binary", rw: true, role: "on", group: "light", label: "Cooktop light" },
        light_level: #{ type: "number", rw: true, min: 0, max: 2, step: 1, group: "light" }
    } })
}

fn start(ctx) {
    ctx.send_raw(aabb_wrap(hex_decode("f0ed114101000000180e111718191a1a1b00000000000000")));
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn publish_name(ctx, prop, name) {
    if name == () { il::publish_absent(ctx, prop); } else { il::publish_property(ctx, prop, name); }
}

fn on_data(ctx, data) {
    let b = c::inner(data, 0x41);
    let o = c::common_status_offset(b, 46);
    if o == () { return; }
    let r = b.extract(o, 46);
    if r[35] != 0x53 { return; }
    il::publish_property(ctx, "available", "true");
    publish_name(ctx, "status", t::name(states(), r[0]));
    publish_name(ctx, "cook_mode", t::name(modes(), r[5]));
    publish_name(ctx, "cook_item", t::name(items(), r[6] * 256 + r[7]));
    il::publish_property(ctx, "power_level", (r[10] * 10).to_string());
    il::publish_property(ctx, "remaining_time", (r[16] * 60 + r[17]).to_string());
    il::publish_property(ctx, "timer", (r[22] * 60 + r[23]).to_string());
    il::publish_property(ctx, "cook_time", (r[18] * 3600 + r[19] * 60 + r[20]).to_string());
    let fan = (r[36] & 0x0f).to_int();
    let light = (r[36] >> 4).to_int();
    if fan > 0 { ctx.state_set("fan", fan); }
    if light > 0 { ctx.state_set("light", light); }
    il::publish_property(ctx, "fan_power", if fan > 0 { "true" } else { "false" });
    il::publish_property(ctx, "fan_speed", fan.to_string());
    il::publish_property(ctx, "light_power", if light > 0 { "true" } else { "false" });
    il::publish_property(ctx, "light_level", light.to_string());
}

fn command(ctx, fan_cmd, fan, light_cmd, light) {
    ctx.send_raw(aabb_wrap([0xf0, 0x43, 0x22, 0x04, fan_cmd, fan, light_cmd, light, 0x80, 0x80]));
}

fn set_fan(ctx, level) { if level > 0 { command(ctx, 1, level, 0x80, 0x80); } else { command(ctx, 0, 0, 0x80, 0x80); } }
fn set_light(ctx, level) { if level > 0 { command(ctx, 0x80, 0x80, 1, level); } else { command(ctx, 0x80, 0x80, 0, 0); } }

fn set_property(ctx, prop, value) {
    switch prop {
        "fan_power" => set_fan(ctx, if c::to_bool(value) { ctx.state_get("fan") ?? 1 } else { 0 }),
        "fan_speed" => set_fan(ctx, c::to_number(value).round().to_int()),
        "light_power" => set_light(ctx, if c::to_bool(value) { ctx.state_get("light") ?? 1 } else { 0 }),
        "light_level" => set_light(ctx, c::to_number(value).round().to_int()),
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
