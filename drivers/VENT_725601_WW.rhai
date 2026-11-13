// LG residential ventilator VENT_725601_WW (ERV, 환기시스템): device -> IL driver. Port of
// justicepng/rethink's VENT_725601_WW.ts (https://github.com/justicepng/rethink, commit a44af31),
// a fork of upstream rethink. UNVERIFIED: the fork has no tests and no captures, so every tag,
// scale and offset below is its word alone, and the fork itself swapped two mode codes once
// (6857672). Nothing here was checked against a frame.
//
// TLV tags (the fork's): 0x1f7 power, 0x1f9 mode (0x25 saving, 0x26 bypass, 0x27 auto), 0x1fa fan
// (2 low, 6 high, 7 power: the app's 약풍 / 강풍 / 특강), 0x2a2 UVnano, 0x34c intake, 0x34b exhaust and
// 0x34a outdoor air temperature (°C as sent; the fork does not say whether they are signed), 0x1fd
// the wall controller's room temperature (raw / 2 °C), 0x355 pre-filter and 0x38d fine-dust filter
// life (%), 0x334 an air quality index (the fork's name; on the air purifier this tag is PM2.5).
//
// Air quality: a frame that carries the wall controller's model name "Z-H0151B2SR" holds, 40
// bytes before the name, CO2 (u16 ppm), the indoor level (1 good .. 4 very bad), indoor PM10,
// PM2.5, PM1 (u16 each), outdoor PM10, PM2.5, PM1, and at +16 the outdoor level. The fork found
// these by position relative to the name, not by the frame's structure, so another controller
// model will not match and publishes nothing. Each group is published only when its level is 1..4,
// CO2 only below 5000.
//
// Handshake: the fork takes any TLV frame as both the capability and the values reply, so the first
// frame ends the capability retry, sends one values query and arms the refresh.
//
// Writes, as the fork sends them: power on carries the mode and the fan (auto and low when never
// seen); power off is the power tag alone; a fan write carries power on and the mode; a mode write
// carries power on and the fan; UVnano carries the power and the mode. Divergences from the fork:
// nothing is published from a write (the fork is optimistic); an unknown mode or fan code is absent
// (the fork reads an unknown mode as auto and buckets fan codes by range); the fork's "ventilation"
// preset is left out (it writes the same 0x26 as bypass); a mode write while off is refused (the
// fork keeps it for the next power on but sends nothing); UVnano is refused until the power and the
// mode have been seen (the fork would assume power on).
import "tlv_common" as c;
import "table_common" as t;
import "il_common" as il;

fn modes() { #{ "37": "saving", "38": "bypass", "39": "auto" } }
fn fans() { #{ "2": "low", "6": "high", "7": "power" } }

fn temp(label) {
    #{ type: "number", class: "temperature", series: "gauge", unit: "°C", category: "diagnostic", label: label }
}
fn pm(class, label) { #{ type: "number", class: class, series: "gauge", unit: "μg/m³", label: label } }
fn level(label) { #{ type: "select", class: "air_quality", options: levels(), label: label } }

// The app's 좋음 / 보통 / 나쁨 / 매우나쁨 (1..4), in IL L-5's names.
fn levels() { ["good", "moderate", "poor", "very_poor"] }

fn descriptor(ctx) {
    json_stringify(#{
        il: 0,
        kind: "fan",
        label: "Ventilator",
        vendor: "LG",
        model: ctx.model_id(),
        props: #{
            available: #{ type: "binary", role: "available" },
            power: #{ type: "binary", rw: true, role: "on", src: #{ tlv_tag: "0x1f7" } },
            mode: #{ type: "select", rw: true, role: "mode", src: #{ tlv_tag: "0x1f9" },
                     options: t::options(modes()) },
            fan: #{ type: "select", rw: true, role: "fan_speed", src: #{ tlv_tag: "0x1fa" },
                    options: t::options(fans()) },
            uv_nano: #{ type: "binary", rw: true, label: "UVnano", src: #{ tlv_tag: "0x2a2" } },
            intake_temperature: temp("Intake air temperature"),
            exhaust_temperature: temp("Exhaust air temperature"),
            outdoor_temperature: temp("Outdoor air temperature"),
            temperature: #{ type: "number", class: "temperature", series: "gauge", unit: "°C",
                            label: "Room temperature (controller)", src: #{ tlv_tag: "0x1fd" } },
            pre_filter_life: #{ type: "number", series: "gauge", unit: "%", label: "Pre-filter life",
                                src: #{ tlv_tag: "0x355" } },
            filter_life: #{ type: "number", series: "gauge", unit: "%", label: "Fine dust filter life",
                            src: #{ tlv_tag: "0x38d" } },
            air_quality_index: #{ type: "number", series: "gauge", category: "diagnostic",
                                  src: #{ tlv_tag: "0x334" } },
            carbon_dioxide: #{ type: "number", class: "carbon_dioxide", series: "gauge", unit: "ppm", label: "Indoor CO2" },
            air_quality: level("Indoor air quality"),
            pm1: pm("pm1", "Indoor PM1"),
            pm25: pm("pm25", "Indoor PM2.5"),
            pm10: pm("pm10", "Indoor PM10"),
            outdoor_air_quality: level("Outdoor air quality"),
            outdoor_pm1: pm("pm1", "Outdoor PM1"),
            outdoor_pm25: pm("pm25", "Outdoor PM2.5"),
            outdoor_pm10: pm("pm10", "Outdoor PM10")
        }
    })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn start(ctx) { c::start(ctx); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_timer(ctx, name) { c::on_timer(ctx, name); }

fn on_data(ctx, data) {
    air_quality(ctx, data);
    let tlvs = tlv_frame_parse(data);
    if tlvs == () { return; }
    if !c::is_set(ctx, "caps") {
        ctx.state_set("caps", true);
        ctx.state_set("values", true);
        ctx.cancel_timer("caps_retry");
        c::query(ctx, 2);
        ctx.set_timer("refresh", c::refresh_ms());
    }
    for e in tlvs { apply(ctx, e.t, e.v); }
}

fn apply(ctx, tag, v) {
    switch tag {
        0x1f7 => { c::put(ctx, tag, v); il::publish_property(ctx, "power", c::flag(v)); }
        0x1f9 => { c::put(ctx, tag, v); select(ctx, "mode", modes(), v); }
        0x1fa => { c::put(ctx, tag, v); select(ctx, "fan", fans(), v); }
        0x2a2 => { c::put(ctx, tag, v); il::publish_property(ctx, "uv_nano", c::flag(v)); }
        0x34c => il::publish_property(ctx, "intake_temperature", v.to_string()),
        0x34b => il::publish_property(ctx, "exhaust_temperature", v.to_string()),
        0x34a => il::publish_property(ctx, "outdoor_temperature", v.to_string()),
        0x1fd => il::publish_property(ctx, "temperature", (v / 2.0).to_string()),
        0x355 => il::publish_property(ctx, "pre_filter_life", v.to_string()),
        0x38d => il::publish_property(ctx, "filter_life", v.to_string()),
        0x334 => il::publish_property(ctx, "air_quality_index", v.to_string()),
        _ => {}
    }
}

fn select(ctx, prop, table, v) {
    let name = t::name(table, v);
    if name == () { il::publish_absent(ctx, prop); } else { il::publish_property(ctx, prop, name); }
}

// ---- the air quality frame ------------------------------------------------------------

fn controller_model() { [0x5a, 0x2d, 0x48, 0x30, 0x31, 0x35, 0x31, 0x42, 0x32, 0x53, 0x52] } // "Z-H0151B2SR"

fn find(data, needle) {
    let n = needle.len();
    for i in 0..(data.len() - n + 1) {
        let hit = true;
        for j in 0..n { if data[i + j] != needle[j] { hit = false; break; } }
        if hit { return i; }
    }
    -1
}

fn u16(data, i) { data[i] * 256 + data[i + 1] }

fn level_name(v) { levels()[v - 1] }

fn air_quality(ctx, data) {
    if data.len() < 51 { return; }
    let at = find(data, controller_model());
    if at < 40 { return; }
    let o = at - 40;
    let co2 = u16(data, o);
    let indoor = data[o + 2];
    let outdoor = data[o + 16];
    if indoor >= 1 && indoor <= 4 {
        il::publish_property(ctx, "air_quality", level_name(indoor));
        il::publish_property(ctx, "pm10", u16(data, o + 3).to_string());
        il::publish_property(ctx, "pm25", u16(data, o + 5).to_string());
        il::publish_property(ctx, "pm1", u16(data, o + 7).to_string());
    }
    if outdoor >= 1 && outdoor <= 4 {
        il::publish_property(ctx, "outdoor_air_quality", level_name(outdoor));
        il::publish_property(ctx, "outdoor_pm10", u16(data, o + 9).to_string());
        il::publish_property(ctx, "outdoor_pm25", u16(data, o + 11).to_string());
        il::publish_property(ctx, "outdoor_pm1", u16(data, o + 13).to_string());
    }
    if co2 < 5000 { il::publish_property(ctx, "carbon_dioxide", co2.to_string()); }
}

// ---- writes ---------------------------------------------------------------------------

fn known(ctx, tag) { ctx.state_get("t" + tag) != () }

// The last seen value of a tag, or `fallback` when it was never seen.
fn last(ctx, tag, fallback) { if known(ctx, tag) { c::get(ctx, tag) } else { fallback } }

// Send the tags in this order, each `[tag, value]`, remembering them as the last written.
fn send(ctx, pairs) {
    let tlvs = [];
    for p in pairs { c::put(ctx, p[0], p[1]); tlvs.push(#{ t: p[0], v: p[1] }); }
    ctx.send_raw(tlv_frame_build(c::write_header(), tlvs));
}

fn set_property(ctx, prop, value) {
    switch prop {
        "power" => {
            if c::to_bool(value) {
                send(ctx, [[0x1f7, 1], [0x1f9, last(ctx, 0x1f9, 0x27)], [0x1fa, last(ctx, 0x1fa, 2)]]);
            } else {
                send(ctx, [[0x1f7, 0]]);
            }
        }
        "fan" => {
            let wire = t::code(fans(), value);
            if wire == () { c::reject(ctx, prop, "unknown fan speed"); return; }
            send(ctx, [[0x1f7, 1], [0x1fa, wire], [0x1f9, last(ctx, 0x1f9, 0x27)]]);
        }
        "mode" => {
            let wire = t::code(modes(), value);
            if wire == () { c::reject(ctx, prop, "unknown mode"); return; }
            if c::get(ctx, 0x1f7) != 1 { c::reject(ctx, prop, "the unit is off"); return; }
            send(ctx, [[0x1f7, 1], [0x1f9, wire], [0x1fa, last(ctx, 0x1fa, 2)]]);
        }
        "uv_nano" => {
            if !known(ctx, 0x1f7) || !known(ctx, 0x1f9) { c::reject(ctx, prop, "no state yet"); return; }
            send(ctx, [[0x1f7, c::get(ctx, 0x1f7)], [0x1f9, c::get(ctx, 0x1f9)],
                       [0x2a2, if c::to_bool(value) { 1 } else { 0 }]]);
        }
        _ => c::reject(ctx, prop, "unknown or read-only property")
    }
}

fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
