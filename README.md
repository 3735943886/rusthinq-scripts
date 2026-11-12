# rusthinq-scripts

Device drivers for [rusthinq](https://github.com/3735943886/rusthinq) 0.2. Each
`<modelId>.rhai` implements one LG ThinQ appliance's IL descriptor, values and
commands.

rusthinq 0.1 is no longer supported here. The last layout that supported
both 0.1 and 0.2 is kept on the
[`legacy`](https://github.com/3735943886/rusthinq-scripts/tree/legacy) branch;
use it for a 0.1 host.

## Using it

Point `[drivers] directory` at this checkout (or an extracted release):

```toml
[drivers]
directory = "/path/to/rusthinq-scripts"
topic_prefix = "rusthinq"
watch = true
```

The host looks up `<model>.rhai` in `drivers/` and modules in `modules/`; this
needs rusthinq `bfb8e77` or later. With `watch = true`, `git pull` or an edit
reloads the affected drivers; otherwise restart the daemon.

A `.rhai` file in the checkout root overrides the one of the same name in
`drivers/` or `modules/`. Set `[drivers] topic_prefix` in the host configuration
(default deployment value: `"rusthinq"`). States, commands and IL descriptors all
use this prefix: `<prefix>/<id>/<prop>`, `<prefix>/<id>/<prop>/set` and
`<prefix>/<id>/descriptor`. There is no separate IL prefix configuration.
Read the host's [upgrade notes](https://github.com/3735943886/rusthinq/blob/master/docs/0.2-tools-migration.md#release-notes-upgrading)
before upgrading from the old `il/<id>` descriptor topic; `rusthinqctl retained-delete`
clears retained values left on an old prefix.

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
modules/              IL, code table, AABB, TLV, refrigerator, dishwasher,
                      monitoring and energy modules
tests/                Device tests, protocol test helpers and runtime_test.rhai
tools/rethink_frames.ts  Prints upstream rethink frames for ported tests
tools/rethink_fixtures.mjs  Prints an upstream rethink test's fixtures
RUSTHINQ_REF          rusthinq ref the drivers are tested against
VERSION               commit and date, filled in by GitHub archives; do not edit
```

The washer/dryer/styler family uses `monitoring_common`, refrigerators use
`fridge_common`, dishwashers `dishwasher_common` and the EU washers
`washer_common`; all import `aabb_common`. TLV drivers delegate handshake,
retry, refresh and framing to `tlv_common`; PAC listens passively. `tlv_fields_common` supplies fixed field maps for the newer
TLV profiles (`hum_common` the humidifying purifiers'), and `washtower_kr_common` handles the Korean split WashTower. Every driver publishes through
`il_common`; named `*_common.rhai` files are modules, not device drivers.

## Checking a change

Run the host's runner against the checkout:

```sh
# From a rusthinq checkout:
cargo run -p rusthinq-tools --bin rusthinq-script-test -- /path/to/rusthinq-scripts
```

Run the common and IL contracts as well:

```sh
python3 tools/check_contracts.py /path/to/rusthinq-script-test
```

Declare each driver in `tests/contracts.json` (`il` or `raw`, and transport).
CI runs both suites against
the rusthinq ref in `RUSTHINQ_REF`; move it forward when a change needs a newer
host.

To write a new driver, start with [docs/capture-and-test.md](docs/capture-and-test.md)
for the capture, control and observe loop, then follow
[docs/writing-a-driver.md](docs/writing-a-driver.md).

## Dated releases

Push an annotated date tag to run the release workflow:

```sh
git tag -a 2026.10.08 -m "Driver release 2026.10.08"
git push origin 2026.10.08
```

Tags must be valid calendar dates in `yyyy.mm.dd` form. For another release on
that date, use `yyyy.mm.dd.1`, then `.2`, and so on; existing releases are not
replaced. Use the Asia/Seoul date when choosing the tag.

After the driver suite passes, the workflow publishes a GitHub Release whose
notes name the tested rusthinq commit. Its source archive is the checkout as is:
extract it and point the host at that directory. In any GitHub archive, a release
or a branch, `VERSION` holds the archived commit and date, which rusthinq shows for
installs that are not Git checkouts. Root overrides are not in the
archive, so extracting an update over it keeps them; stop rusthinq first.

The rusthinq Home Assistant integration installs the dated release it pins, so a
driver change reaches its users once a release is tagged and the integration moves
its pin.

## Drivers

[docs/drivers.md](docs/drivers.md) lists every supported model and how far each has
been verified: run on the real appliance, tested against its captures, or tested
against constructed frames.

## License

GPL-2.0, the same as rusthinq (see `COPYING`).
