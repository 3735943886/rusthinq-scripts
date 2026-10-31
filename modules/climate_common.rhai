// The TLV (DualCool family) air conditioners: CST_570004_WW and the upstream rethink models
// (RAC_056905_WW, POT_056905_WW, WIN_056905_WW). A driver inherits all of this with
// `import "climate_common";` and overrides the model functions below; tlv_common carries the
// handshake, timers and write framing.
//
// Common wire tags: 0x1f7 power, 0x1f9 mode, 0x1fa fan, 0x1fd room temperature and 0x1fe
// setpoint (half degrees). The capability reply may carry the setpoint range (0x2e1 / 0x2e2,
// half degrees; `range_tags()` for models with per-mode limits). A write carries the tags the unit needs with it at their last known values;
// a mode write also powers the unit on when it carries 0x1f7, since the unit ignores a mode
// write while off.
//
// With `tracks_action()`, the unit's action follows power, mode and, when the unit reports
// either, whether the indoor unit is really running (0x189 or 0x6c); the values are polled
// every 28 s while it is active (upstream RAC: the outdoor unit recalculates every 30 s).
import "tlv_common" as c;
import "table_common" as t;
import "il_common" as il;

// ---- model, overridden by the driver ------------------------------------------------

fn modes() { #{ "0": "cool", "1": "dry", "2": "fan_only" } }
fn fans() { #{ "2": "low", "4": "medium", "6": "high" } }
fn fan_options() { t::options(fans()) }
// The setpoint range (degrees) until a capability reply says otherwise, and its step.
fn range() { [16, 30] }
// The capability tags of the lowest and highest setpoint (half degrees); the range is the lowest
// and highest non-zero value among them.
fn range_tags() { [[0x2e1], [0x2e2]] }
fn target_step() { 0.5 }
// What each write carries along.
fn power_attach() { [0x1f9, 0x1fa, 0x1fe] }
fn mode_attach() { [0x1f7, 0x1fa, 0x1fe] }
fn fan_attach() { [0x1f9, 0x1fe] }
fn target_attach() { [0x1f9, 0x1fa] }
// Which frames are the unit's state: at least `state_min_tags()` tags, one of them in `state_tags()`.
fn state_min_tags() { 10 }
fn state_tags() { [0x1f7] }
fn tracks_action() { false }
// Ask the cloud not to relay tag 1200 (the appliance's noisy periodic report) once state arrives.
fn masks_reports() { false }
fn label() { "Air conditioner" }

// Model properties beyond the common ones, and how they read and write.
fn extra_props(ctx) { #{} }
// A tag the model handles itself in `after_values`, so it is neither stored nor applied.
fn held(tag) { false }
fn apply_extra(ctx, tag, v) {}
// After a state or change frame has been applied; `before` is the mode before it.
fn after_values(ctx, tlvs, before) {}
// True when the model handled the write.
fn set_extra(ctx, prop, value) { false }
// True when the model consumed a frame that is not a TLV state frame (its own protocol).
fn own_frame(ctx, data) { false }
// The capability reply's tags, for capability-dependent features. True to republish the descriptor.
fn after_caps(ctx, tlvs) { false }
// Once, after the first state frame (and the report masking).
fn first_values(ctx) {}
// True when the model handled a timer of its own.
fn timer_extra(ctx, name) { false }

// ---- descriptor -------------------------------------------------------------------

fn range_min(ctx) { let v = ctx.state_get("range_min"); if v == () { range()[0] } else { v } }
fn range_max(ctx) { let v = ctx.state_get("range_max"); if v == () { range()[1] } else { v } }

// A driver that overrides a hook can still reach this one as `climate_<hook>`.
fn descriptor(ctx) { climate_descriptor(ctx) }

fn climate_descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", rw: true, role: "on", src: #{ tlv_tag: "0x1f7" } },
        mode: #{ type: "select", rw: true, role: "mode", src: #{ tlv_tag: "0x1f9" },
                 options: t::options(modes()) },
        fan: #{ type: "select", rw: true, role: "fan_speed", src: #{ tlv_tag: "0x1fa" },
                options: fan_options() },
        target: #{ type: "number", rw: true, role: "target_temperature", src: #{ tlv_tag: "0x1fe" },
                   min: range_min(ctx), max: range_max(ctx), step: target_step(), unit: "°C" },
        temperature: #{ type: "number", role: "current_temperature", src: #{ tlv_tag: "0x1fd" },
                        unit: "°C" }
    };
    if tracks_action() { props.action = #{ type: "select", role: "action", options: actions() }; }
    props += extra_props(ctx);
    json_stringify(#{ il: 0, kind: "climate", class: "air_conditioner", label: label(), vendor: "LG",
                      model: ctx.model_id(), props: props })
}

// The action each mode runs as; the descriptor lists those the model's modes can produce.
fn mode_action(mode) {
    switch mode { "cool" => "cooling", "dry" => "drying", "heat" => "heating", "fan_only" => "fan", _ => "active" }
}

fn actions() {
    let out = ["off", "idle"];
    for mode in t::options(modes()) {
        let a = mode_action(mode);
        if !out.contains(a) { out.push(a); }
    }
    out
}

// ---- derived state ----------------------------------------------------------------

fn half(v) { if v % 2 == 0 { (v / 2).to_string() } else { (v / 2.0).to_string() } }
fn deg(v) { if v % 2 == 0 { v / 2 } else { v / 2.0 } }

// "off" while the unit is powered off, else the mode name.
fn effective_mode(ctx) {
    if c::get(ctx, 0x1f7) == 0 { "off" } else { t::name(modes(), c::get(ctx, 0x1f9)) }
}

// Whether the indoor unit is really running, when the unit says (true if it never does).
fn running(ctx) {
    for tag in [0x189, 0x6c] {
        let v = ctx.state_get("t" + tag);
        if v != () { return v != 0; }
    }
    true
}

fn action_name(ctx) {
    let mode = effective_mode(ctx);
    if mode == "off" { "off" }
    else if mode == () { () }
    else if mode == "fan_only" { "fan" }
    else if !running(ctx) { "idle" }
    else { mode_action(mode) }
}

fn poll_ms() { 28000 }

fn publish_action(ctx) {
    let action = action_name(ctx);
    if action != () { il::publish_property(ctx, "action", action); }

    let active = action == "cooling" || action == "drying" || action == "heating" || action == "active";
    let was = ctx.state_get("active") == true;
    ctx.state_set("active", active);
    if active && !was { ctx.set_timer("poll", poll_ms()); }
    if !active && was { ctx.cancel_timer("poll"); }
}

// ---- host hooks -------------------------------------------------------------------

fn start(ctx) { climate_start(ctx); }

fn climate_start(ctx) {
    ctx.state_set("active", false);
    c::start(ctx);
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_timer(ctx, name) { climate_on_timer(ctx, name); }

fn climate_on_timer(ctx, name) {
    if name == "poll" {
        if ctx.state_get("active") == true {
            c::query(ctx, 2);
            ctx.set_timer("poll", poll_ms());
        }
    } else if !timer_extra(ctx, name) {
        c::on_timer(ctx, name);
    }
}

fn on_data(ctx, data) { climate_on_data(ctx, data); }

fn climate_on_data(ctx, data) {
    if own_frame(ctx, data) { return; }
    let frame = c::receive(ctx, data, state_min_tags(), state_tags());
    if frame == () { return; }
    if frame.caps { on_caps(ctx, frame.tlvs); return; }

    let before = ctx.state_get("emode");
    for e in frame.tlvs {
        if !held(e.t) { apply(ctx, e.t, e.v); }
    }
    ctx.state_set("emode", effective_mode(ctx));
    after_values(ctx, frame.tlvs, before);
    if tracks_action() { publish_action(ctx); }

    if frame.first {
        il::publish_property(ctx, "available", "true");
        if masks_reports() { ctx.send_clip("setMaskingInfo", 0, "{\"blacklist_tlv\":\"1200\"}"); }
        first_values(ctx);
    }
}

// The capability reply: adopt the setpoint range the unit reports, and say so in the descriptor
// (il_common then refuses a setpoint outside it).
fn on_caps(ctx, tlvs) {
    let lo = ();
    let hi = ();
    let tags = range_tags();
    for e in tlvs {
        if e.v == 0 { continue; }
        if tags[0].contains(e.t) && (lo == () || e.v < lo) { lo = e.v; }
        if tags[1].contains(e.t) && (hi == () || e.v > hi) { hi = e.v; }
    }
    let changed = after_caps(ctx, tlvs);
    if lo != () && hi != () && lo < hi && (deg(lo) != range_min(ctx) || deg(hi) != range_max(ctx)) {
        ctx.state_set("range_min", deg(lo));
        ctx.state_set("range_max", deg(hi));
        changed = true;
    }
    if changed { il::publish_il(ctx, descriptor(ctx)); }
}

fn apply(ctx, tag, v) {
    c::put(ctx, tag, v);
    switch tag {
        0x1f7 => { il::publish_property(ctx, "power", c::flag(v)); }
        0x1f9 => {
            let name = t::name(modes(), v);
            if name != () { il::publish_property(ctx, "mode", name); }
        }
        0x1fa => {
            let name = t::name(fans(), v);
            if name != () { il::publish_property(ctx, "fan", name); }
        }
        0x1fd => { il::publish_property(ctx, "temperature", half(v)); }
        0x1fe => { il::publish_property(ctx, "target", half(v)); }
        _ => { apply_extra(ctx, tag, v); }
    }
}

// ---- writes -----------------------------------------------------------------------

fn set_property(ctx, prop, value) { climate_set_property(ctx, prop, value); }

fn climate_set_property(ctx, prop, value) {
    switch prop {
        "power" => {
            let on = c::to_bool(value);
            c::write(ctx, 0x1f7, if on { 1 } else { 0 }, if on { power_attach() } else { [] });
        }
        "mode" => {
            let wire = t::code(modes(), value);
            if wire == () { c::reject(ctx, prop, "unknown mode"); return; }
            if mode_attach().contains(0x1f7) { c::put(ctx, 0x1f7, 1); } // the mode write powers the unit on
            c::write(ctx, 0x1f9, wire, mode_attach());
        }
        "fan" => {
            let wire = t::code(fans(), value);
            if wire == () { c::reject(ctx, prop, "unknown fan speed"); return; }
            c::write(ctx, 0x1fa, wire, fan_attach());
        }
        "target" => {
            let n = c::to_number(value);
            if n == () { c::reject(ctx, prop, "not a number"); return; }
            c::write(ctx, 0x1fe, (n * 2).round().to_int(), target_attach());
        }
        _ => {
            if !set_extra(ctx, prop, value) { c::reject(ctx, prop, "unknown or read-only property"); }
        }
    }
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
