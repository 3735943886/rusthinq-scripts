# rusthinq-scripts

Device drivers for [rusthinq](https://github.com/3735943886/rusthinq) 0.2. Each
`<modelId>.rhai` implements one LG ThinQ appliance's IL descriptor, values and
commands.

rusthinq 0.1 is no longer supported here. The last layout that built and
released for both 0.1 and 0.2 is kept on the
[`legacy`](https://github.com/3735943886/rusthinq-scripts/tree/legacy) branch;
use it or its earlier dated releases for a 0.1 host.

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
See [prefix migration and retained cleanup](docs/mqtt-topics.md) before upgrading
from the old `il/<id>` descriptor topic or changing the host prefix.

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
TLV profiles, and `washtower_kr_common` handles the Korean split WashTower. Every driver publishes through
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

After the driver suite passes, the workflow publishes a GitHub Release whose
notes name the tested rusthinq commit. Its source archive is the checkout as is:
extract it and point the host at that directory. In any GitHub archive, a release
or a branch, `VERSION` holds the archived commit and date, which rusthinq shows for
installs that are not Git checkouts. Root overrides are not in the
archive, so extracting an update over it keeps them; stop rusthinq first.

## Drivers

| model | appliance | protocol | status |
|---|---|---|---|
| `2RSFL2DBN3K_Z` | refrigerator | AABB | live |
| `2REB1GLVB1__2` | refrigerator | AABB | captured |
| `2REF11EBIVPC4` | refrigerator | AABB | constructed |
| `2REF11EIDA__4` | refrigerator | AABB | captured |
| `2REF11EIDG__4` | refrigerator | AABB | captured |
| `2REFT1DIC4P_U` | refrigerator | AABB | captured |
| `2REFTBDII4P_U` | refrigerator | AABB | captured |
| `2RES1VE600FWC` | refrigerator | AABB | captured |
| `2RES1VE61NFWA` | refrigerator (alias of `2RES1VE600FWC`) | AABB | captured |
| `2RES1VE61NFA2` | refrigerator | AABB | captured |
| `1WPU4CIGCR__2` | water purifier | AABB | captured |
| `1WPD6CMIDR__3` | water/ice purifier (WD722RH) | AABB | captured |
| `AIR_910604_WW` | air purifier | TLV | captured |
| `HUM_056905_WW` | humidifying air purifier | TLV | captured |
| `HWWA9K_F2` | CordZero A9 stick vacuum | AABB | captured |
| `PAC_910604_WW` | floor-standing air conditioner | TLV | captured |
| `CST_570004_WW` | ceiling-cassette air conditioner | TLV | captured |
| `POT_056905_WW` | portable air conditioner | TLV | captured |
| `RAC_056905_WW` | split air conditioner | TLV or ThinQ1 | captured |
| `RAC_0B0001_WW` | split air conditioner (alias of `RAC_056905_WW`) | TLV | captured |
| `WIN_056905_WW` | window air conditioner | TLV | constructed |
| `D140110` | dishwasher (read-only) | AABB | captured |
| `D0211` | dishwasher (read-only) | AABB | captured |
| `D2211` | dishwasher (read-only; alias of `D0211`) | AABB | captured |
| `D30` | dishwasher (read-only) | AABB | captured |
| `H11` | dishwasher | AABB | captured |
| `N17` | dishwasher | AABB | captured |
| `DHUM_056905_WW` | dehumidifier | TLV | captured |
| `DHUM_231006_WW` | dehumidifier | TLV | captured |
| `F_V8_Y___W.B_2QEUK` | washer | AABB | captured |
| `F_V7_Y___W.B_2QEUK`, `F_V7_Y___W.B__QEUK`, `F_V__Y___W.B_2QEUK`, `F_V__Y___W.B__QEUK` | washer (alias of `F_V8_Y___W.B_2QEUK`) | AABB | captured |
| `F_VB_Y___W.B_2QEUK` | washer | AABB | captured |
| `F_VB_F___W.B_2QEUK` | washer-dryer | AABB | constructed |
| `F_V__F___W.B_1QEUK`, `F_VA_F___W.B__QEUK` | washer-dryer | AABB | constructed |
| `F_C__Y___W.A__QEUK` | washer | AABB | captured |
| `F_V7_Y___W.A__QEUK` | washer (alias of `F_C__Y___W.A__QEUK`) | AABB | captured |
| `VCDWL2QEUK` | washer (read-only) | AABB envelope | captured |
| `Y_V8_Y___W.B32QEUK` | washer | AABB envelope | captured |
| `Y_VB_Y___W.B32QEUK` | washer with ezDispense | AABB envelope | captured |
| `Y_V8_F___W.B_2QEUK` | washer-dryer | AABB envelope | captured |
| `F24VDD` | washer | AABB monitoring | captured |
| `RH14_N_KR` | dryer | AABB monitoring | captured |
| `RH16_T_KR` | heat-pump dryer | AABB | captured |
| `S3BF_POD_DN4` | styler | AABB monitoring | captured |
| `ST_B_E4H01Y_APL` | styler | AABB | captured |
| `S5MPC` | styler | AABB | captured |
| `STUDIO_HOOD` | range hood | AABB | captured |
| `WBEY3GT` | cooktop | AABB | captured |
| `WFV474PGV` | double oven range | AABB | captured |
| `WLREL6323S` | electric range (read-only) | AABB | captured |
| `WLSI_633_` | induction range (read-only) | AABB | captured |
| `WMVEL2137` | microwave/hood | AABB | captured |
| `WMVEM1825` | microwave | AABB | captured |
| `Pd0F_F` | mini washer | AABB monitoring | constructed |
| `T1789EFH_F` | top-load washer | AABB | captured |
| `TLVE5BB` | top-load washer (read-only) | AABB envelope | captured |
| `F3L2CYU__` | washer (read-only) | AABB | captured |
| `F3L7CYK5W_US_WIFI` | washer (read-only) | AABB | captured |
| `F3P3CYK2_` | washer (power off only) | AABB | captured |
| `FAFXU25006` | washer (read-only) | AABB envelope | captured |
| `RV13B6BSD_D_US_WIFI` | dryer (read-only) | AABB | captured |
| `RV13B6ES_D_US_WIFI` | dryer (read-only) | AABB | captured |
| `RV13U6AM8W_D_US_WIFI` | dryer (read-only) | AABB | captured |
| `BDH_D30007_US` | heat pump dryer (read-only) | AABB envelope | captured |
| `RC90U2_WW` | heat pump dryer (read-only) | AABB | captured |
| `RC90V9_WW` | heat pump dryer (read-only; alias of `RC90U2_WW`) | AABB | captured |
| `RC90V9_AUS` | heat pump dryer (read-only; alias of `RC90U2_WW`) | AABB | captured |
| `WTL_FXU_BDV_NA_01` | WashTower (washer and dryer) | AABB | captured |
| `FAKPK21021` | Korean WashTower washer | AABB envelope | captured |
| `BDH_D39301_KR` | Korean WashTower dryer | AABB envelope | captured |
| `WTDN3` | washer-dryer | ThinQ1 | captured |
| `WTWN3` | washer | ThinQ1 | captured |

- **live**: run against the real appliance; reads and writes confirmed.
- **captured**: tested against frames captured from a real appliance and, where
  available, writes the LG app sent; not yet run live.
- **constructed**: status frames built from documented offsets or around a
  captured record; writes match captured frames.

Each test file cites the captures its driver is checked against.
Drivers planned from upstream rethink are tracked in
[docs/porting.md](docs/porting.md). Additional open PR ports from `dohun0310` and
`tunarabuuu`, including exact revisions and runtime differences, are recorded in
[docs/porting-prs.md](docs/porting-prs.md).

## License

GPL-2.0, the same as rusthinq (see `COPYING`).
