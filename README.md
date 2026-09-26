# rusthinq-scripts

Device drivers for [rusthinq](https://github.com/3735943886/rusthinq): one `<modelId>.rhai`
script per LG ThinQ appliance model, each producing the IL descriptor, values and commands
described by the IL specification. rusthinq loads them from `[scripting] rhai_dir`; this
repository is that directory.

## Using it

Put a checkout of this repository where rusthinq's `config.toml` can point at it:

```toml
[scripting]
rhai_dir = "/path/to/rusthinq-scripts"
watch = true      # optional: pick up saved, added or removed scripts without a restart
```

rusthinq must be built with the `scripting` feature. A script is matched to an appliance by
its file name, which must equal the `modelId` the appliance reports (case and underscores
included).

## Layout

- `<modelId>.rhai`: one driver per model.
- `aabb_common.rhai`, `monitoring_common.rhai`, `tlv_common.rhai`: shared modules
  (any `*_common.rhai` is a module, not a driver).
- `tests/<modelId>.test.rhai`: that driver's tests, run against frames captured from the
  real appliance wherever there is one; `tests/aabb_test.rhai` and `tests/tlv_test.rhai` are
  helpers shared by them.

The washer / dryer / styler family shares `monitoring_common.rhai` (record parsing for the 0xEC / 0xEB / 0xE2 frames, command acknowledgements reported as rejections, the course a Start will ask for), which itself imports `aabb_common`.
AABB drivers share `aabb_common.rhai` (`import "aabb_common" as c;`): frame check, name/flag/bit helpers, reject.

TLV drivers share `tlv_common.rhai` (`import "tlv_common" as c;`): the capability to values handshake with retries, the slow refresh, and write framing. A module cannot call back into its importer, so each device script keeps the hooks and delegates to it.

## Checking a change

```
rusthinq-script-test .
```

runs every driver test and then checks that every driver has a test file and publishes a
descriptor that is well formed against the IL. It exits non-zero on any failure. The runner
is built from rusthinq:

```
cargo run -p rusthinq-devices --features scripting --bin rusthinq-script-test -- ../rusthinq-scripts
```

`RUSTHINQ_REF` names the rusthinq branch, tag or commit these drivers are developed and
tested against (the host functions a script can call, and the host-side command validation,
belong to rusthinq). CI builds the runner from that ref. Move it forward together with any
driver change that needs a newer host.

To write a new driver, see [docs/writing-a-driver.md](docs/writing-a-driver.md).

## Drivers

| model | script | status |
|---|---|---|
| DHUM_056905_WW (LG dehumidifier) | `DHUM_056905_WW.rhai` | tested against captured frames; not yet run against the live appliance |
| AIR_910604_WW (LG air purifier) | `AIR_910604_WW.rhai` | same |
| 1WPU4CIGCR__2 (LG water purifier, AABB) | `1WPU4CIGCR__2.rhai` | tested against real captured frames and the write frames the appliance accepted (both from rethink's test suite); not yet run live |
| D140110 (LG dishwasher, AABB, read-only) | `D140110.rhai` | tested against nine real frames of a full cycle (from rethink's test suite); not yet run live |
| WBEY3GT (LG cooktop, AABB) | `WBEY3GT.rhai` | tested against real frames and the command frames the LG app sent, byte for byte; not yet run live. Writes are rejected unless the panel has granted remote start, and no command lights a ring |
| Pd0F_F (LG mini washer, AABB monitoring record) | `Pd0F_F.rhai` | commands byte for byte as the LG app sent them (from rethink's test suite); status frames built from the documented offsets and the state the rethink adapter had retained, not yet checked against a live capture |
| RH14_N_KR (LG dryer, AABB monitoring record) | `RH14_N_KR.rhai` | tested against three real frames captured from the appliance while it ran a cycle (their previous records agree with what the rethink adapter had retained at that moment) and the start frame the LG app sent; not yet run live |
| S3BF_POD_DN4 (LG styler, AABB monitoring record) | `S3BF_POD_DN4.rhai` | tested against a real idle frame from the cabinet (energy and downloaded course agree with what the rethink adapter had retained) and the 46-byte Fine Dust start the LG app sent, byte for byte; there is no power-on command (measured: the cabinet acknowledges and ignores them); not yet run live |
| F24VDD (LG washer, AABB monitoring record) | `F24VDD.rhai` | tested against a real idle frame from the washer (energy, download course, Tub Clean count, last operating course and end sound agree with what the rethink adapter had retained) and the Colour Care, Heavy Duty and Steam Refresh starts the LG app sent, byte for byte; not yet run live |
| CST_570004_WW (LG ceiling-cassette air conditioner, TLV) | `CST_570004_WW.rhai` | written for this model only; tested against the real capability and state frames a unit reported (from rethink's test suite); write frames follow rethink's write-attach rules (power on and mode writes carry the other core tags), not yet compared with frames the LG app sent, and not yet run live |
| 2RSFL2DBN3K_Z (LG refrigerator, AABB) | `2RSFL2DBN3K_Z.rhai` | live against the real appliance, captured with `rusthinq-capture`: every property was read back after toggling the matching LG app control, including all three night-glare modes (off / sunset-to-sunrise / custom schedule). Fridge/freezer setpoint, express freeze, and AI Saving Mode (off/balanced/max, its own short F0 10 frame acked with an inner `0x67`, not the F0 17 template every other write here uses) were written from here (`rusthinq/<id>/<prop>/set`) and confirmed acked and reflected in the appliance's own next status frame; `ai_saving_max_schedule` (max mode's own active-hours window, same F0 10 frame) is decoded and reproduced byte-for-byte from a live nudge but never echoed by any status frame, so it publishes its own write back instead. Smart Care+, night-glare mode and the door-alarm-mute toggle are all confirmed writable at the protocol level too (night-glare via its own short F0 10 02 frame, which also carries a custom schedule's start/end time and LCD brightness, and for sunset-to-sunrise two bytes this driver could not pin down, none of it exposed) but are kept read-only here, as sensors rather than controls. `door_open_count_fridge`/`door_open_count_freezer` and `energy_today` come from two more unprompted ~15-minute reports (`0xC5` and `0x3E`) the appliance sends on its own — neither is part of the main status record's single "any door open" bit — and both were confirmed against the LG app's own figures directly: the door counts matched a live three-door test exactly, and the energy total matched the app's energy-monitoring screen byte for byte (503 on the wire, 503 Wh shown) |

## License

GPL-2.0, the same as rusthinq (see `COPYING`).
