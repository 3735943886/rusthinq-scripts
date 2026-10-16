# rusthinq-scripts

Device drivers for [rusthinq](https://github.com/3735943886/rusthinq) 0.2. Each
`<modelId>.rhai` implements one LG ThinQ appliance's IL descriptor, values and
commands.

rusthinq 0.1 is no longer supported here. The last layout that built and
released for both 0.1 and 0.2 is kept on the
[`legacy`](https://github.com/3735943886/rusthinq-scripts/tree/legacy) branch;
use it or its earlier dated releases for a 0.1 host.

## Using it

Prepare the runtime directory (Python 3 required):

```sh
python3 tools/prepare.py
```

Point `[drivers] directory` at `/path/to/rusthinq-scripts/dist/0.2`.
Enable `watch = true` in the same section if you want automatic reloads.
The host expects a flat runtime directory; do not point it at the source root.
Run the preparation command again after changing or updating source files.
With watching enabled, prepare while the daemon is stopped to avoid loading a
partially copied update; otherwise prepare and restart the daemon.

Edit `dist/0.2/il_config_common.rhai` to choose the descriptor prefix
(default `"il"`; `""` disables descriptor publication). Preparation preserves
this local file. Property and command topics use the host's
`[drivers] topic_prefix`.

rusthinq must have the `scripting` feature. Driver filenames must match the
appliance's reported `modelId`, including case and underscores.

## The IL in Rhai

The rusthinq 0.2 core is IL-independent. `modules/il_common.rhai` handles
descriptors, values, command validation and rejects in Rhai and publishes
through `ctx.publish_raw`. Drivers call `il::publish_il`, `il::publish_property`,
`il::publish_event` and `il::validate`; see
[docs/writing-a-driver.md](docs/writing-a-driver.md).

The descriptor label is the driver's own label. For daemon configuration and
state migration from 0.1, see the
[0.1 → 0.2 migration guide](https://github.com/3735943886/rusthinq/blob/master/docs/0.2-tools-migration.md#release-notes-upgrading).

Non-IL scripts can use supported hooks and `ctx.publish_raw(topic, payload,
retain)`; such scripts must validate their own commands. See
[non-IL drivers](docs/writing-a-driver.md#drivers-that-do-not-use-the-il).

Driver `available` follows the connection lifecycle: initialization publishes `true`,
and disconnect publishes `false`. A fresh appliance state report is not required to
restore availability after reconnecting; reported values may still reflect the last report.

## Layout

```text
drivers/              <modelId>.rhai drivers
modules/              IL, AABB, TLV, monitoring and energy modules;
                      il_config_common.rhai.example (descriptor prefix template)
tests/                Device tests, protocol test helpers and runtime_test.rhai
tools/prepare.py      Assembles the flat runtime directory
RUSTHINQ_REF          rusthinq ref the drivers are tested against
dist/0.2/             Generated runtime directory (ignored by Git)
```

The washer/dryer/styler family uses `monitoring_common`, which imports
`aabb_common`. TLV drivers delegate handshake, retry, refresh and framing to
`tlv_common`. Every driver publishes through `il_common`; named `*_common.rhai`
files are modules, not device drivers.

## Checking a change

Prepare the runtime, then run the host's runner against it:

```sh
python3 tools/prepare.py
# From a rusthinq checkout:
cargo run -p rusthinq-tools --bin rusthinq-script-test -- /path/to/rusthinq-scripts/dist/0.2
```

The preparation tool has its own checks:

```sh
python3 -m unittest discover -s tools -p 'test_*.py'
```

Use `"il"` as the descriptor prefix for tests. CI runs the driver tests against
the rusthinq ref in `RUSTHINQ_REF`; move it forward when a change needs a newer
host.

To write a new driver, see [docs/writing-a-driver.md](docs/writing-a-driver.md).

## Dated releases

Push an annotated date tag to run the release workflow:

```sh
git tag -a 2026.10.08 -m "Driver release 2026.10.08"
git push origin 2026.10.08
```

Tags must be valid calendar dates in `yyyy.mm.dd` form. For another release on
that date, use `yyyy.mm.dd.1`, then `.2`, and so on; existing releases are not
replaced. Use the Asia/Seoul date when choosing the tag.

After the driver suite passes, the workflow publishes one GitHub Release with:

- `rusthinq-scripts-0.2-<tag>.tar.gz`
- `SHA256SUMS`

The archive contains a flat runtime under `rusthinq-scripts-0.2/`,
`INSTALL.txt`, the license, and `RELEASE.json` with the exact scripts and tested
rusthinq commits. No local settings or test fixtures are included. The archive
supplies `il_config_common.rhai.example`; copy it to `il_config_common.rhai` on
first installation and preserve your local file on updates. Extract the archive,
then point your host at the extracted directory as described above. Python is
not needed to use release archives. Stop rusthinq before extracting an update
over its active runtime directory.

Verify downloads with `sha256sum -c SHA256SUMS` in the directory containing the
archive. Changing the source or packaging implementation requires a new tag;
rerunning a published tag does not overwrite its release assets.

## Drivers

| model | script | status |
|---|---|---|
| DHUM_056905_WW (LG dehumidifier) | `drivers/DHUM_056905_WW.rhai` | tested against captured frames; not yet run against the live appliance |
| AIR_910604_WW (LG air purifier) | `drivers/AIR_910604_WW.rhai` | same |
| 1WPU4CIGCR__2 (LG water purifier, AABB) | `drivers/1WPU4CIGCR__2.rhai` | tested against real captured frames and the write frames the appliance accepted (both from rethink's test suite); not yet run live |
| D140110 (LG dishwasher, AABB, read-only) | `drivers/D140110.rhai` | tested against nine real frames of a full cycle (from rethink's test suite); not yet run live |
| WBEY3GT (LG cooktop, AABB) | `drivers/WBEY3GT.rhai` | tested against real frames and the command frames the LG app sent, byte for byte; not yet run live. Writes are rejected unless the panel has granted remote start, and no command lights a ring |
| Pd0F_F (LG mini washer, AABB monitoring record) | `drivers/Pd0F_F.rhai` | commands byte for byte as the LG app sent them (from rethink's test suite); status frames built from the documented offsets and the state the rethink adapter had retained, not yet checked against a live capture |
| RH14_N_KR (LG dryer, AABB monitoring record) | `drivers/RH14_N_KR.rhai` | tested against three real frames captured from the appliance while it ran a cycle (their previous records agree with what the rethink adapter had retained at that moment) and the start frame the LG app sent; not yet run live |
| S3BF_POD_DN4 (LG styler, AABB monitoring record) | `drivers/S3BF_POD_DN4.rhai` | tested against a real idle frame from the cabinet (energy and downloaded course agree with what the rethink adapter had retained) and the 46-byte Fine Dust start the LG app sent, byte for byte; there is no power-on command (measured: the cabinet acknowledges and ignores them); not yet run live |
| F24VDD (LG washer, AABB monitoring record) | `drivers/F24VDD.rhai` | tested against a real idle frame from the washer (energy, download course, Tub Clean count, last operating course and end sound agree with what the rethink adapter had retained) and the Colour Care, Heavy Duty and Steam Refresh starts the LG app sent, byte for byte; not yet run live |
| CST_570004_WW (LG ceiling-cassette air conditioner, TLV) | `drivers/CST_570004_WW.rhai` | written for this model only; tested against the real capability and state frames a unit reported (from rethink's test suite); write frames follow rethink's write-attach rules (power on and mode writes carry the other core tags), not yet compared with frames the LG app sent, and not yet run live |
| 2RSFL2DBN3K_Z (LG refrigerator, AABB) | `drivers/2RSFL2DBN3K_Z.rhai` | live against the real appliance, captured with `rusthinq-capture`: every property was read back after toggling the matching LG app control, including all three night-glare modes (off / sunset-to-sunrise / custom schedule). Fridge/freezer setpoint, express freeze, and AI Saving Mode (off/balanced/max, its own short F0 10 frame acked with an inner `0x67`, not the F0 17 template every other write here uses) were written from here (`rusthinq/<id>/<prop>/set`) and confirmed acked and reflected in the appliance's own next status frame; `ai_saving_max_schedule` (max mode's own active-hours window, same F0 10 frame) is decoded and reproduced byte-for-byte from a live nudge but never echoed by any status frame, so it publishes its own write back instead. Smart Care+, night-glare mode and the door-alarm-mute toggle are all confirmed writable at the protocol level too (night-glare via its own short F0 10 02 frame, which also carries a custom schedule's start/end time and LCD brightness, and for sunset-to-sunrise two bytes this driver could not pin down, none of it exposed) but are kept read-only here, as sensors rather than controls. `door_open_count_fridge`/`door_open_count_freezer` and `energy_today` come from two more unprompted ~15-minute reports (`0xC5` and `0x3E`) the appliance sends on its own — neither is part of the main status record's single "any door open" bit — and both were confirmed against the LG app's own figures directly: the door counts matched a live three-door test exactly, and the energy total matched the app's energy-monitoring screen byte for byte (503 on the wire, 503 Wh shown) |

## License

GPL-2.0, the same as rusthinq (see `COPYING`).
