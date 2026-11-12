// LG lightwave oven ML32PWFOTA (Korean MW series, "광파오븐"): device -> IL driver, read only.
// Port of SdrgonLee/rethink's ML32PWFOTA.ts (https://github.com/SdrgonLee/rethink, commit
// 491b177), a fork of upstream rethink; its tests carry a captured 10 s microwave start and
// labelled cleaning runs, the rest are constructed records.
//
// State frames are AA <len> 40 EB|EC ...: EB carries one 28-byte record (sent on connect and in
// answer to the status query), EC the previous record followed by the current one. Record:
//   [0]  state: 0 initial, 1 preheating, 2 cooking, 3 cleaning, 4 paused, 5 done,
//        6 preheat done, 7 preference (setting up)
//   [1]  program: 1 microwave .. 0x16 steam ferment (programs()); 0x12 marks a cleaning
//        function, named by [2] (cleanings()); 0x13 is a saved "my recipe"
//   [3..5] remaining h/m/s, meaningful only while cooking, cleaning or paused (the preheat
//        countdown is not the cook time)
//   [6]  target temperature in C, meaningful only with a known program
// Other 0x40 frames (72, BF) are not state and are ignored.
//
// The oven reports remaining time on its own only while the ThinQ app is watching it; the app
// keeps asking with F0 EF 00 46. The fork sends that query on connect and every 30 s, which
// keeps the countdown current here too.
//
// total_time is the remaining time latched when a cycle starts running from initial,
// preference, done or preheat done (EC's previous record says so), kept through a pause and
// cleared when the cycle ends. A record seen without that transition (EB on connect, a
// resumed session) leaves it absent rather than mistaking a part-run cycle for its total.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn rec_len() { 28 }
fn query_ms() { 30000 }
fn query() { [0xf0, 0xef, 0x00, 0x46] }

fn states() {
    #{ "0": "initial", "1": "preheating", "2": "cooking", "3": "cleaning", "4": "paused",
       "5": "done", "6": "preheat_done", "7": "preference" }
}

fn programs() {
    #{ "1": "microwave", "2": "steam_microwave", "3": "grill", "4": "oven", "5": "steam_oven",
       "6": "steam", "7": "dehydrate", "19": "my_recipe", "21": "ferment", "22": "steam_ferment" }
}

fn cleanings() {
    #{ "1": "steam_deodorize", "2": "steam_clean", "3": "cavity_dry", "4": "drain_residual_water",
       "5": "steam_generator_clean" }
}

fn program_options() {
    let o = t::options(programs());
    o += t::options(cleanings());
    o
}

fn descriptor(ctx) {
    let props = #{
        available: #{ type: "binary", role: "available" },
        oven_state: #{ type: "select", options: t::options(states()), label: "Oven state" },
        program: #{ type: "select", options: program_options(), label: "Program" },
        remaining_time: #{ type: "number", class: "duration", unit: "s", label: "Remaining time" },
        total_time: #{ type: "number", class: "duration", unit: "s", label: "Total time" },
        target_temperature: #{ type: "number", class: "temperature", unit: "°C", label: "Target temperature" }
    };
    json_stringify(#{ il: 0, kind: "oven", label: "Oven", vendor: "LG",
                      model: ctx.model_id(), props: props })
}

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn start(ctx) {
    ctx.send_raw(aabb_wrap(query()));
    ctx.set_timer("status_query", query_ms());
}

fn on_timer(ctx, name) {
    if name != "status_query" { return; }
    ctx.send_raw(aabb_wrap(query()));
    ctx.set_timer("status_query", query_ms());
}

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn active(s) { s == 1 || s == 2 || s == 3 || s == 4 || s == 6 }

// The program name, or `()` when the record names none this driver knows (absent).
fn program(r) {
    let s = r[0];
    let id = r[1];
    if !active(s) || id == 0 { return (); }
    if s == 3 || (s == 4 && id == 0x12) {
        if id != 0x12 { return (); }
        return t::name(cleanings(), r[2]);
    }
    if id == 0x12 { return (); }
    t::name(programs(), id)
}

fn opt(ctx, prop, v) {
    if v == () { il::publish_absent(ctx, prop); } else { il::publish_property(ctx, prop, v.to_string()); }
}

fn record(ctx, r, previous) {
    let s = r[0];
    let remaining = r[3] * 3600 + r[4] * 60 + r[5];
    il::publish_property(ctx, "available", "true");
    opt(ctx, "oven_state", t::name(states(), s));
    opt(ctx, "program", program(r));
    opt(ctx, "remaining_time", if s == 2 || s == 3 || s == 4 { remaining } else { () });
    let known = r[1] == 0x13 || (r[1] != 0x12 && t::name(programs(), r[1]) != ());
    opt(ctx, "target_temperature", if active(s) && known && r[6] != 0 { r[6] } else { () });

    let running = ctx.state_get("cycle_active") == true;
    if s == 2 || s == 3 {
        if !running {
            let fresh = previous != () && [0, 1, 5, 6, 7].contains(previous);
            opt(ctx, "total_time", if fresh { remaining } else { () });
            ctx.state_set("cycle_active", true);
        }
    } else if s == 4 {
        if !running { il::publish_absent(ctx, "total_time"); }
    } else {
        ctx.state_set("cycle_active", false);
        il::publish_absent(ctx, "total_time");
    }
}

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let body = c::inner(data, 0x40);
    if body == () { return; }
    let off = c::common_status_offset(body, rec_len());
    if off == () { return; }
    let previous = if body[1] == 0xec { body[2].to_int() } else { () };
    record(ctx, body.extract(off, rec_len()), previous);
}

// Read-only: il_common's validation rejects every write against the descriptor.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { c::reject(ctx, prop, "read-only driver"); }
}
