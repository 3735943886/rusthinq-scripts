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
modules/              IL, AABB, TLV, refrigerator, monitoring and energy modules;
                      il_config_common.rhai.example (descriptor prefix template)
tests/                Device tests, protocol test helpers and runtime_test.rhai
tools/prepare.py      Assembles the flat runtime directory
tools/rethink_frames.ts  Prints upstream rethink frames for ported tests
RUSTHINQ_REF          rusthinq ref the drivers are tested against
dist/0.2/             Generated runtime directory (ignored by Git)
```

The washer/dryer/styler family uses `monitoring_common`, and refrigerators use
`fridge_common`; both import `aabb_common`. TLV drivers delegate handshake,
retry, refresh and framing to `tlv_common`. Every driver publishes through
`il_common`; named `*_common.rhai` files are modules, not device drivers.

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

| model | appliance | protocol | status |
|---|---|---|---|
| `2RSFL2DBN3K_Z` | refrigerator | AABB | live |
| `2REB1GLVB1__2` | refrigerator | AABB | captured |
| `2RES1VE61NFA2` | refrigerator | AABB | captured |
| `1WPU4CIGCR__2` | water purifier | AABB | captured |
| `AIR_910604_WW` | air purifier | TLV | captured |
| `CST_570004_WW` | ceiling-cassette air conditioner | TLV | captured |
| `D140110` | dishwasher (read-only) | AABB | captured |
| `DHUM_056905_WW` | dehumidifier | TLV | captured |
| `F24VDD` | washer | AABB monitoring | captured |
| `RH14_N_KR` | dryer | AABB monitoring | captured |
| `S3BF_POD_DN4` | styler | AABB monitoring | captured |
| `WBEY3GT` | cooktop | AABB | captured |
| `Pd0F_F` | mini washer | AABB monitoring | constructed |

- **live**: run against the real appliance; reads and writes confirmed.
- **captured**: tested against frames captured from a real appliance and, where
  available, writes the LG app sent; not yet run live.
- **constructed**: status frames built from documented offsets; writes match
  captured frames.

Each test file cites the captures its driver is checked against.
Drivers planned from upstream rethink are tracked in
[docs/porting.md](docs/porting.md).

## License

GPL-2.0, the same as rusthinq (see `COPYING`).
