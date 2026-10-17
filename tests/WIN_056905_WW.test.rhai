import "runtime_test" as runtime;
import "tlv_test" as t;

// Tests of WIN_056905_WW (climate_common). Upstream rethink has no tests or captures for this
// model, so these are constructed: frames in the 0xa7 notify envelope (tlv_test), checked against
// what upstream's WIN_056905_WW.ts (commit 0e57069) reads and writes.

// A capability reply (0x2da) and a state of at least ten tags with power: heat, power on, fan
// high, room 21.5, setpoint 22, swing on.
fn caps() { t::notify([[0x2da, 1]]) }
fn state() {
    t::notify([[0x1f9, 4], [0x1f7, 1], [0x1fa, 6], [0x1fd, 43], [0x1fe, 44], [0x322, 100],
               [0x21a, 0], [0x221, 0], [0x20d, 0], [0x20e, 0]])
}

fn ready() { t::running(device(), caps(), state()) }

fn test_the_descriptor_is_a_window_air_conditioner() {
    let props = runtime::descriptor(ready()).props;
    expect_eq(props.mode.options, ["cool", "fan_only", "heat"]);
    expect_eq(props.fan.options, ["low", "high"]);
    expect_eq(props.target.step, 0.5);
    expect_eq(props.swing.role, "swing_vertical");
}

fn test_a_state_becomes_il_properties() {
    expect_props(ready(), #{ available: "true", power: "true", mode: "heat", fan: "high",
                             temperature: "21.5", target: "22", swing: "true" });
}

// upstream: setProperty('power', 'ON') first, then the mode with [0x1f7, 0x1fa, 0x1fe, 0x322]
fn test_a_mode_write_powers_on_first_in_its_own_frame() {
    let d = ready();
    d.feed(t::notify([[0x1f7, 0]]));
    let n = d.sent().len();
    d.set("mode", "cool");
    expect_eq(t::sent_since(d, n), [
        [[0x1f7, 1], [0x1f9, 4]],
        [[0x1f9, 0], [0x1f7, 1], [0x1fa, 6], [0x1fe, 44], [0x322, 100]],
    ]);
}

fn test_power_fan_setpoint_and_swing_writes() {
    let d = ready();
    let n = d.sent().len();
    d.set("power", "false");
    d.set("fan", "low");
    d.set("target", "23.5");
    d.set("swing", "false");
    expect_eq(t::sent_since(d, n), [
        [[0x1f7, 0]],
        [[0x1fa, 2], [0x1f9, 4], [0x1fe, 44]],
        [[0x1fe, 47], [0x1f9, 4], [0x1fa, 2]],
        [[0x322, 0], [0x1f9, 4], [0x1fa, 2]],
    ]);
}

fn test_a_bad_write_is_refused_and_sends_nothing() {
    let d = ready();
    let n = d.sent().len();
    d.set("mode", "dry");
    d.set("fan", "medium");
    d.set("target", "31");
    expect_eq(d.sent().len(), n);
}
