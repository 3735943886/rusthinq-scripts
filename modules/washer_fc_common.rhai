// The LG A-generation front-load washers: F_C__Y___W.A__QEUK (F4WV709P1) and its alias
// F_V7_Y___W.A__QEUK (WV5-1275W). Port of upstream rethink's F_C__Y___W.A__QEUK.ts (commit
// 2d8eaba), its offsets confirmed there on live captures.
// Status is a class 0x20 EB/EC frame of 30-byte records:
//    2 state   3/4 remaining, 5/6 initial time (h, min)   7 0x02 remote start   8 error
//   10 spin   11 temperature   12 course   14/15 delay remaining (h, min)   16 0x80 steam
//   17 0x20 wrinkle care, 0x40 cycle started, 0x80 child lock   23 washes since Tub Clean
// No record bit follows the door lock. A 3-byte 0x20 0xD8 frame does (non-zero = locked), but
// only while Off or Ready: during a cycle it can read unlocked spuriously, so there the lock
// follows the state (Off unlocked, any running state locked). 0xE2 end-of-cycle alerts carry
// another layout and are ignored. Commands as washer_common. The washer repeats unacked frames
// and then re-deploys, so it gets the cloud's acks.
import "aabb_common" as c;
import "table_common" as t;
import "washer_common" as w;
import "il_common" as il;

// 14 and 15 are WASH_REFRESHING and REFRESHING.
fn states() {
    let s = w::base_states();
    s["15"] = "refreshing";
    s
}

fn descriptor(ctx) {
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer", vendor: "LG",
                      model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", rw: true, class: "running", label: "Powered on" },
        start: #{ type: "trigger", requires: "remote_start" },
        pause: #{ type: "trigger" },
        status: #{ type: "select", options: t::options(states()) },
        error: #{ type: "binary", class: "problem", category: "diagnostic" },
        error_message: #{ type: "text", category: "diagnostic" },
        course: #{ type: "select", options: t::options(w::courses()) },
        spin: #{ type: "select", options: t::options(w::spins()) },
        temp: #{ type: "select", label: "Water temperature", options: t::options(w::temps()) },
        remote_start: #{ type: "binary", category: "diagnostic", label: "Remote start armed at the panel" },
        door_lock: #{ type: "binary", category: "diagnostic" },
        child_lock: #{ type: "binary", category: "diagnostic" },
        steam: #{ type: "binary" },
        wrinkle_care: #{ type: "binary" },
        active: #{ type: "binary", label: "Cycle started" },
        cycles: #{ type: "number", series: "counter", category: "diagnostic", label: "Washes since Tub Clean" },
        initial_time: #{ type: "number", class: "duration", unit: "min", label: "Cycle length" },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        reserve_time: #{ type: "number", class: "duration", unit: "min", label: "Delay remaining" }
    } })
}

fn start(ctx) { w::start(ctx); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let b = c::inner(data, 0x20);
    if b == () { return; }
    if b[1] == 0xd8 && b.len() == 3 {
        let state = ctx.state_get("state");
        if state == () || state <= 1 { il::publish_property(ctx, "door_lock", if b[2] != 0 { "true" } else { "false" }); }
        return;
    }
    let o = c::common_status_offset(b, 30);
    if o == () { return; }
    let s = b.extract(o, 30);
    ctx.state_set("state", s[2]);
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if s[2] > 0 { "true" } else { "false" });
    c::pub_name(ctx, "status", t::name(states(), s[2]));
    il::publish_property(ctx, "error", if s[8] != 0 { "true" } else { "false" });
    il::publish_property(ctx, "error_message", t::name(w::errors(), s[8]) ?? "Unknown error (" + s[8] + ")");
    c::pub_name(ctx, "course", t::name(w::courses(), s[12]));
    c::pub_name(ctx, "spin", t::name(w::spins(), s[10]));
    c::pub_name(ctx, "temp", t::name(w::temps(), s[11]));
    il::publish_property(ctx, "remaining_time", (s[3] * 60 + s[4]).to_string());
    il::publish_property(ctx, "initial_time", (s[5] * 60 + s[6]).to_string());
    il::publish_property(ctx, "reserve_time", (s[14] * 60 + s[15]).to_string());
    il::publish_property(ctx, "remote_start", c::bit(s[7], 0x02));
    il::publish_property(ctx, "steam", c::bit(s[16], 0x80));
    il::publish_property(ctx, "wrinkle_care", c::bit(s[17], 0x20));
    il::publish_property(ctx, "active", c::bit(s[17], 0x40));
    il::publish_property(ctx, "child_lock", c::bit(s[17], 0x80));
    il::publish_property(ctx, "cycles", s[23].to_string());
    if s[2] == 0 { il::publish_property(ctx, "door_lock", "false"); }
    else if s[2] != 1 { il::publish_property(ctx, "door_lock", "true"); }
}

fn set_property(ctx, prop, value) { w::set_property(ctx, prop, value); }

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
