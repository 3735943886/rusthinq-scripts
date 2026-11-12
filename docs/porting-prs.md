# Korean appliance PR ports

These ports use the open PR heads below, read on 2026-10-18 (Asia/Seoul), in
addition to the master baseline in [porting.md](porting.md). `tunarabuu` in the
request refers to GitHub user `tunarabuuu`.

| Author | PR | Model | Pinned head | Result |
|---|---|---|---|---|
| dohun0310 | [#169](https://github.com/anszom/rethink/pull/169) | `1WPD6CMIDR__3` | `a8a9c64795163182e3351af61a3ef4234ac848e3` | New water/ice purifier, sparse configuration writes |
| dohun0310 | [#170](https://github.com/anszom/rethink/pull/170) | `PAC_910604_WW` | `7109e55b741593f7ff0e411c38d28cf795a2cbe8` | New passive floor-standing AC |
| dohun0310 | [#172](https://github.com/anszom/rethink/pull/172) | `AIR_910604_WW` | `eb15cc6954db7d68d1a71c55280f995cf02ad5dc` | Existing handshake retained; booster fan/rotation and raw filter hours added |
| dohun0310 | [#173](https://github.com/anszom/rethink/pull/173) | `S5MPC` | `6c239b821cb8dcabf033827745454a3053bd3bc5` | New Styler, native and downloaded course controls |
| dohun0310 | [#180](https://github.com/anszom/rethink/pull/180) | `F24VDD` | `5c0acfd8ec17f2aee451572a64d686f49d06f2fb` | New 36-byte record variant, diagnostic energy, options and downloads; original 34-byte format retained |
| dohun0310 | [#182](https://github.com/anszom/rethink/pull/182) | `RH16_T_KR` | `c4fc160c0363193d0b8adda5e202c10dc10c1a5a` | New dryer, native and downloaded course controls |
| tunarabuuu | [#113](https://github.com/anszom/rethink/pull/113) | `DHUM_056905_WW`, `DHUM_231006_WW` | `1419bf64e130f9c1268297221b62869b75ae383c` | Existing 056905 behavior checked against shared PR implementation; new 231006 profile and combined startup reply |
| tunarabuuu | [#114](https://github.com/anszom/rethink/pull/114) | `HUM_056905_WW` | `5898c3b6c2407c71281d8ef6e6caffb036a82b22` | New humidifying purifier; distinct capability marker |
| tunarabuuu | [#115](https://github.com/anszom/rethink/pull/115) | `ST_B_E4H01Y_APL` | `080a8b432d068d913f027db9c27d5e5d28b437ff` | Existing complete port checked against PR vectors; invalid sound options rejected |
| tunarabuuu | [#116](https://github.com/anszom/rethink/pull/116) | `HWWA9K_F2` | `2da637a2544aa8689b212ba5cced5a7d16fdfe56` | New CordZero A9 status and five settings |
| tunarabuuu | [#117](https://github.com/anszom/rethink/pull/117) | `FAKPK21021`, `BDH_D39301_KR` | `3b1942c1411931f5e007b0d86e8bb38e06be2018` | New Korean split WashTower, checked extended framing and guarded controls |
| tunarabuuu | [#118](https://github.com/anszom/rethink/pull/118) | `1WPU4CIGCR__2` | `b815692e1dc6f6e028b6fe9278fbd55979a5806a` | 16-bit last-dispense reports retained; speculative usage counters excluded; read-only diagnostics added |

The device-specific split PRs supersede [#111](https://github.com/anszom/rethink/pull/111).
Its bridge stores and Home Assistant infrastructure are outside the driver port;
[#110](https://github.com/anszom/rethink/pull/110) changes the upstream connection
lifecycle rather than adding a device.

## IL and runtime differences

PR parity is not treated as proof of correctness.

Existing IL property/option names remain stable. New drivers use lowercase
options and IL booleans. Durations use minutes (including HUM's timer, which
upstream presents in hours). Unknown enum readings are left absent or leave the
last confirmed reading standing, as in the existing drivers; Home Assistant's
`None`, `Unsupported`, and `Code N` placeholders are not new IL options.

F24VDD's existing common fields remain in `washer_f24_legacy_common`.
The 36-byte record shares the verified 34-byte prefix; both formats publish the
existing fields. Frame length alone does not select new control defaults or
remove the remote-start interlock. Existing `start` preserves native presets and
automatic resume; explicit new options/download selections and `start_course` /
`resume` use the PR's captured builder. All start/resume aliases keep the existing
remote-start requirement. Diagnostic energy corrects the PR's byte-width bug:
CD +35..36 and BD +36..37 are BE uint16, alongside normal status energy.
Reservation hours are 0 or 3–19; 1 and 2 are rejected.

`S5MPC`, `RH16_T_KR`, and the new F24VDD status variant validate their byte-sum
checksum. Korean WashTower status validates CRC16, length, tag and exact short
or full record sizes. It does not alias the US combined WashTower. Power-on
acceptance triggers one status refresh; actual telemetry confirms power, and
an unconfirmed transition times out after 120 seconds. Start/options and remote
control restrictions follow the PR's model-specific rules.

Download selections are kept in `ctx.state_*`. The Rhai host exposes neither the
PRs' disk course-memory file nor an observation hook for commands forwarded
through the cloud bridge. Therefore selections installed through these drivers
and downloads identified in incoming telemetry work, but a restart without
identifying telemetry needs a fresh selection. A download installed only by an
outgoing tunneled command cannot be identified until telemetry reports it.
These disk/tunnel scenarios are excluded from the replay vectors.

The ATOM-U purifier keeps its existing raw `MM-DD HH:MM` UTC schedule instead of
inventing a year. Its existing per-dispense values and confirmed controls remain;
speculative `water_usage_*` counters are excluded pending event/delta evidence. Filter
percentages on AIR remain available alongside the PR's raw remaining/lifetime
hours. PAC remains passive. AIR retains its existing handshake and refresh timers.

## Later HUM_056905_WW changes

After the PR #114 port, `HUM_056905_WW` moved its fields into `hum_common` and
follows a private rethink fork driver running on installed units; the new test
frames are live captures from 2026-11-10 of two units. The capability reply
narrows modes, options and controls per unit. Writes seen accepted on the wire
are power, modes 5/12/24, fan, target humidity, night, sleep and auto
operation. Never observed accepted, and written as the modelJSON labels say:
the sensor mode (`sensor_mon`, 0x337), the tank light (`watertank_light`,
0x21e), modes 108/109, standby sterilization `power`, and off-timer minutes off
the 15-minute grid. `start_time`/`stop_time` (HHMM) use the appliance's private
command 03, whose set, readback and clear were captured on two units.

### Behavior changes for existing HUM_056905_WW users

- **`bell_sound` is inverted**: raw 0 now reads `true` (sound on) and raw 1
  `false` (muted), and writes follow. The modelJSON labels say 0 off / 1 on; the
  basis is a static reading of the shipped LG app module (GPH 3501.04) and the
  app's label disagreeing with the old reading on an installed unit. Round trips
  were driven from Home Assistant, not the app; the beep was not checked.
- `autodry_remain` declares `min` instead of `%`; LG labels it a remaining
  time, which has not been timed.
- `filter_used_time` and `filter_life_time` lose the `h` unit and the
  `duration` class, and become diagnostic: LG labels them filter
  "remainTime"/"maxTime" with no confirmed unit.
- `target` is 30–70 % in steps of 5 (was 0–100, step 1, snapped to 5): values
  off the step or range are rejected.
- `off_timer` takes whole minutes (was a 15-minute step).
- The capability reply narrows `mode`, `fan`, `hygiene_dry`,
  `standby_sterilize` and `mood_color` options and drops controls and sensors
  the unit does not declare; their retained values are cleared. `hygiene_dry`
  `default` and mood colours `blue`, `green`, `red`, `purple` and `pink` are
  no longer offered by any unit.
- Writes are refused (`not_now`) until the capability reply arrives.
- Switches keep their last reading on codes other than 0 and 1, instead of
  reading `false`.

## Verification

Each `tests/<model>.test.rhai` cites its PR head and retains upstream test names.
The PR vectors were collected by running the pinned TypeScript handlers against
upstream's own test inputs, including constructed negative cases, and recording
properties and exact outgoing packets. Conflicting behavior is corrected or
excluded according to independent evidence in the conflict audit. IL conversion changes names, booleans,
and duration units, not the expected packet bytes. Existing capture-based
regressions remain alongside them. WashTower also has explicit host-timer tests
for accepted, confirmed, timed-out and disconnected power-on transitions.

These are capture/replay ports, not new live-appliance verification. Run the
normal host runner documented in the README against the whole checkout.
