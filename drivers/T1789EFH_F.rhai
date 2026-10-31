// LG top-load washer T1789EFH_F (WT7300CW): port of upstream rethink's T1789EFH_F.ts (commit
// 2d8eaba), whose offsets, codes and commands were each confirmed there on the appliance or byte for
// byte against the LG cloud. Status is a 0x20 EB frame of one 27-byte block or EC of two (previous,
// current); a block is one leading byte and a record that starts with a 0x19 marker. Record offsets:
//    1 state   2/3 remaining, 4/5 initial time (h, min)   6 course   8 soil   9 spin   10 temperature
//   11 rinse setting (only carried into the start command)   13/14 delay wash (h, min)
//   15 0x01 child lock, 0x04 door lock, 0x40 TurboWash   16 0x01 extra rinse, 0x02 Water Plus,
//   0x08 Stain Care, 0x10 TurboWash offered but off, 0x20 soak   17 0x01 remote start armed
//   21 active smart course (only while the dial is on Downloaded)   24 the downloaded course
// The Downloaded position reports its smart course's base cycle in byte 6. Off, the times read 0,
// spin reads "none" (No Spin is also the off value) and the cycle options read off (TurboWash stays
// set from the last cycle). 0xE2 frames replay a stale snapshot and are not status.
//
// Unacked, this washer repeats every frame about ten times, re-deploys and never streams its status,
// so it gets the cloud's acks; it volunteers no status until start() asks for it. Commands, as the LG
// cloud sends them:
//   start/resume  F0 26 <course> <soil> <spin> <temp> <rinse> 00 x7 <15 without the door lock> <16>
//                 <03 start, 01 resume while paused>, built from the last record
//   pause F0 24 04 01 00   power off F0 24 01 01 00
// Remote start can only be armed at the panel, and the washer ignores a start that is not armed, so
// start is not gated here, as upstream; resuming a paused cycle needs no arming.
import "aabb_common" as c;
import "table_common" as t;
import "il_common" as il;

fn states() {
    #{ "0": "off", "1": "standby", "2": "paused", "3": "detecting", "4": "soaking", "5": "washing",
       "6": "rinsing", "7": "spinning", "8": "end", "9": "delayed", "10": "updating_firmware",
       "11": "smart_diagnosis" }
}

// The codes are LG's own, not the model JSON's list order.
fn courses() {
    #{ "0": "none", "1": "normal", "2": "heavy_duty", "4": "delicates", "5": "waterproof",
       "7": "speed_wash", "8": "bedding", "12": "tub_clean", "17": "rinse_spin", "18": "spin_only",
       "25": "deep_wash", "41": "pre_wash_normal" }
}

fn smart_courses() {
    #{ "0": "none", "100": "small_load", "101": "single_item", "103": "wrinkle_stop_gentle_wave",
       "104": "rapid_clean", "105": "sweat_stains", "106": "swimwear", "107": "curtains",
       "109": "dress_shirts", "110": "collar_stains", "111": "pillow_covers", "112": "lingerie",
       "113": "baby_wear", "115": "childrens_wear", "116": "juice_food_stains", "117": "baby_bibs",
       "118": "pet_hair_odor", "119": "econo_wash", "120": "collars_cuffs", "121": "delicate_dresses",
       "122": "half_load_wash", "123": "full_load_wash", "131": "whites" }
}

fn soils() { #{ "0": "none", "1": "light", "2": "light_normal", "3": "normal", "4": "normal_heavy", "5": "heavy" } }
fn spins() { #{ "0": "no_spin", "1": "low", "2": "medium", "3": "high", "4": "extra_high" } }
fn temps() { #{ "0": "none", "1": "tap_cold", "2": "cold", "3": "semi_warm", "4": "warm", "5": "hot", "6": "extra_hot" } }

fn descriptor(ctx) {
    let spin = ["none"];
    spin += t::options(spins());
    json_stringify(#{ il: 0, kind: "washer", class: "washing_machine", label: "Washer", vendor: "LG",
                      model: ctx.model_id(), props: #{
        available: #{ type: "binary", role: "available" },
        power: #{ type: "binary", label: "Powered on" },
        start: #{ type: "trigger" },
        pause: #{ type: "trigger" },
        power_off: #{ type: "trigger" },
        status: #{ type: "select", options: t::options(states()) },
        course: #{ type: "select", options: t::options(courses()) },
        smart_course: #{ type: "select", options: t::options(smart_courses()) },
        downloaded_course: #{ type: "select", category: "diagnostic", label: "Downloaded cycle", options: t::options(smart_courses()) },
        soil: #{ type: "select", label: "Soil level", options: t::options(soils()) },
        spin: #{ type: "select", options: spin },
        temp: #{ type: "select", label: "Water temperature", options: t::options(temps()) },
        remaining_time: #{ type: "number", class: "duration", unit: "min" },
        initial_time: #{ type: "number", class: "duration", unit: "min", category: "diagnostic", label: "Cycle length" },
        reserve_time: #{ type: "number", class: "duration", unit: "min", label: "Delay wash" },
        door_lock: #{ type: "binary", category: "diagnostic" },
        child_lock: #{ type: "binary", category: "diagnostic" },
        remote_start: #{ type: "binary", category: "diagnostic", label: "Remote start armed at the panel" },
        turbo_wash: #{ type: "binary" },
        extra_rinse: #{ type: "binary" },
        water_plus: #{ type: "binary" },
        stain_care: #{ type: "binary" },
        soak: #{ type: "binary" }
    } })
}

fn start(ctx) { ctx.send_raw(aabb_wrap([0xf0, 0xed, 0x11, 0x21, 0x01, 0x00, 0x00, 0x00, 0x18, 0x00])); }

fn publish_config(ctx) { il::publish_il(ctx, descriptor(ctx)); }

fn on_drop(ctx) { il::publish_property(ctx, "available", "false"); }

fn on_data(ctx, data) {
    c::ack(ctx, data);
    let b = c::inner(data, 0x20);
    let o = c::common_status_offset(b, 27);
    if o == () { return; }
    let r = b.extract(o + 1, 26);
    ctx.state_set("record", r.to_array());
    let off = r[1] == 0;
    il::publish_property(ctx, "available", "true");
    il::publish_property(ctx, "power", if off { "false" } else { "true" });
    c::pub_name(ctx, "status", t::name(states(), r[1]));
    il::publish_property(ctx, "remaining_time", if off { "0" } else { (r[2] * 60 + r[3]).to_string() });
    il::publish_property(ctx, "initial_time", if off { "0" } else { (r[4] * 60 + r[5]).to_string() });
    c::pub_name(ctx, "course", t::name(courses(), r[6]));
    c::pub_name(ctx, "smart_course", t::name(smart_courses(), r[21]));
    c::pub_name(ctx, "downloaded_course", t::name(smart_courses(), r[24]));
    il::publish_property(ctx, "reserve_time", (r[13] * 60 + r[14]).to_string());
    il::publish_property(ctx, "child_lock", c::bit(r[15], 0x01));
    il::publish_property(ctx, "door_lock", c::bit(r[15], 0x04));
    il::publish_property(ctx, "remote_start", c::bit(r[17], 0x01));
    let flags = if off { 0 } else { r[15] };
    let opt2 = if off { 0 } else { r[16] };
    il::publish_property(ctx, "turbo_wash", c::bit(flags, 0x40));
    il::publish_property(ctx, "extra_rinse", c::bit(opt2, 0x01));
    il::publish_property(ctx, "water_plus", c::bit(opt2, 0x02));
    il::publish_property(ctx, "stain_care", c::bit(opt2, 0x08));
    il::publish_property(ctx, "soak", c::bit(opt2, 0x20));
    c::pub_name(ctx, "soil", t::name(soils(), r[8]));
    c::pub_name(ctx, "spin", if off { "none" } else { t::name(spins(), r[9]) });
    c::pub_name(ctx, "temp", t::name(temps(), r[10]));
}

fn set_property(ctx, prop, value) {
    let r = ctx.state_get("record");
    if r == () { c::reject(ctx, prop, "no status received yet"); return; }
    let msg = switch prop {
        "pause" => [0xf0, 0x24, 0x04, 0x01, 0x00],
        "power_off" => [0xf0, 0x24, 0x01, 0x01, 0x00],
        "start" => [0xf0, 0x26, r[6], r[8], r[9], r[10], r[11], 0, 0, 0, 0, 0, 0, 0,
                    r[15] & 0xfb, r[16], if r[1] == 2 { 0x01 } else { 0x03 }],
        _ => { c::reject(ctx, prop, "unknown or read-only property"); return; }
    };
    ctx.send_raw(aabb_wrap(msg));
}

// il_common validates against the descriptor and rejects invalid commands.
fn on_set_property(ctx, prop, value) {
    let value = il::validate(ctx, prop, value);
    if value != () { set_property(ctx, prop, value); }
}
