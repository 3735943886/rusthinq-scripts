// Fixed TLV field maps. Inherit and supply fields(), identity(), receive_frame() and hooks.
// Each field carries its IL definition and wire codec; protocol framing stays in tlv_common.
import "tlv_common" as c;
import "table_common" as t;
import "il_common" as il;
fn identity() { #{ kind: "humidifier", label: "Humidifier" } }
fn fields() { #{} }
fn extra_props() { #{} }
fn passive() { false }
fn receive_frame(ctx, data) { c::receive(ctx, data, 1, [0x1f7, 0x1f9, 0x1fa]); }
fn after_frame(ctx, frame) {}
fn apply_extra(ctx, tag, value) {}
fn write_extra(ctx, prop, value) { false }
// A property's descriptor entry, narrowed for this unit, or () to leave it out.
fn field_def(ctx, prop, field, definition) { definition }
// Only a property the current descriptor lists, and a select value among its options (il.md V-3).
fn publishable(ctx, prop, value) {
    let doc = ctx.state_get("__il_descriptor");
    if doc == () || doc.props == () { return true; }
    let definition = doc.props[prop];
    definition != () && (definition.options == () || definition.options.contains(value))
}
fn descriptor(ctx) {
    let doc = identity();
    doc.il = 0; doc.vendor = "LG"; doc.model = ctx.model_id();
    let props = #{ available: #{ type: "binary", role: "available" } };
    for prop in fields().keys() {
        let field = fields()[prop];
        let definition = field.def;
        if definition.type == "number" {
            if definition.series == () { definition.series = "gauge"; }
            if definition.unit == "°C" { definition["class"] = "temperature"; }
            if definition.unit == "W" { definition["class"] = "power"; }
            if ["min", "h"].contains(definition.unit) { definition["class"] = "duration"; }
            if ["pm1", "pm25", "pm10"].contains(prop) { definition["class"] = prop; }
        }
        if field.table != () { definition.options = t::options(field.table); }
        definition = field_def(ctx, prop, field, definition);
        if definition != () { props[prop] = definition; }
    }
    props += extra_props(); doc.props = props;
    json_stringify(doc)
}
fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }
fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }
fn start(ctx) { if !passive() { c::start(ctx); } }
fn on_timer(ctx, name) { if !passive() { c::on_timer(ctx, name); } }
fn on_data(ctx, data) {
    let frame = receive_frame(ctx, data);
    if frame == () { return; }
    if !frame.caps {
        for e in frame.tlvs {
            for prop in fields().keys() {
                let f = fields()[prop];
                if f.tag != e.t { continue; }
                c::put(ctx, e.t, e.v);
                let value = e.v;
                if f.table != () { value = t::name(f.table, value); }
                else if f.def.type == "binary" {
                    // `on` (default 1) is the wire code for true. exact_one: only `on` and its
                    // complement are states, and any other code leaves the last reading.
                    let on = if f.on == () { 1 } else { f.on };
                    value = if f.exact_one == true { if value == on { "true" } else if value == 1 - on { "false" } else { () } }
                        else if f.on == () { c::flag(value) } else { c::flag(if value == on { 1 } else { 0 }) };
                }
                else if f.scale != () { value = value.to_float() / f.scale; if value == value.floor() { value = value.to_int(); } }
                if value != () && publishable(ctx, prop, value.to_string()) { il::publish_property(ctx, prop, value.to_string()); }
            }
            apply_extra(ctx, e.t, e.v);
        }
    }
    after_frame(ctx, frame);
}
fn set_property(ctx, prop, value) {
    if write_extra(ctx, prop, value) { return; }
    let f = fields()[prop];
    if f == () { c::reject(ctx, prop, "unknown property"); return; }
    let raw = if f.table != () { t::code(f.table, value) }
        else if f.def.type == "binary" { let on = if f.on == () { 1 } else { f.on }; if c::to_bool(value) { on } else { 1 - on } }
        else { let n = c::to_number(value); if n == () { () } else { (n * (if f.scale == () { 1 } else { f.scale })).round().to_int() } };
    if raw == () { c::reject(ctx, prop, "invalid value"); return; }
    if f.power_on == true { c::put(ctx, 0x1f7, 1); }
    c::write(ctx, f.tag, raw, if f.attach == () { [] } else { f.attach });
}
fn on_set_property(ctx, prop, value) {
    if ctx.state_get("__il_descriptor") == () { publish_config(ctx); }
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
