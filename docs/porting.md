# Porting upstream rethink drivers

Plan and tracker for porting every device driver in
[anszom/rethink](https://github.com/anszom/rethink) to Rhai. Each port follows
[writing-a-driver.md](writing-a-driver.md); this page records what exists
upstream, what must be built first, and the order of work.

## Upstream baseline

| | |
|---|---|
| Upstream commit | `0e570698713b038ea0a25da3cc36fd97aea84813` (2026-10-14) |
| Device drivers | 44 files in `cloud/devices/`, plus 6 alias model IDs in `cloud/ha_bridge.ts` |
| Upstream suite | 841 passed, 0 failed (`node --import tsx --test tests/cloud/devices/*.test.ts`) |
| Already here | `DHUM_056905_WW` only; the other ten drivers here have no upstream counterpart |

Port against this commit. When moving the baseline forward, rerun the upstream
suite, update this table, and diff `cloud/devices/` since the previous commit
for drivers that are already ported.

Upstream matches the reported `modelId` exactly. The driver file here must have
the same name (names containing `.` need rusthinq `bfb8e77` or later).

## How to port one driver

1. Read the upstream driver, its shared module and its test file. The TS driver
   is the functional spec: same properties, writes and quirks; IL naming instead
   of Home Assistant entity names. Keep the Rhai short: shared logic goes in a
   module, and the header lists only the offsets the driver itself decodes.
2. Port every upstream test that feeds a frame or checks a sent frame to
   `tests/<modelId>.test.rhai`. Keep the upstream test name in a comment so the
   two suites can be compared.
3. Writes must be byte-identical to what the upstream driver sends for the same
   command. Generate the expected hex by running the upstream driver with
   [tools/rethink_frames.ts](../tools/rethink_frames.ts), not by hand.
4. Cite the upstream commit and test in the driver header. An upstream value
   whose meaning upstream itself does not establish stays unpublished.
5. Add the README driver row with status `captured` only when the upstream
   fixtures are real captures; otherwise `constructed`.
6. Set the tracker row below to `ported`.

## Prerequisites

Shared work that blocks several ports. Do these first.

### Host support

- **`.` in model IDs.** rusthinq accepts dotted driver names such as
  `F_V8_Y___W.B_2QEUK.rhai` since commit `bfb8e77` on master (each
  dot-separated part must be a valid name). 12 upstream model IDs (8 drivers
  and 4 aliases) depend on it. Module names still cannot contain `.`.
- **Aliases.** Upstream maps several model IDs to one driver. Here every model
  needs its own file and test file. Decide between generated copies (an alias
  list read by `tools/prepare.py`) and host-side aliasing before porting the
  aliased drivers.

### Shared modules

| module | needed by | work |
|---|---|---|
| `aabb_common` | 6 drivers with auto-ack; 3 with envelope status; 3 with long frames | Add the cloud ack (`f0 00 <type> 04 [seq]` sent with `ctx.send_clip("ack", 1, ...)`), envelope status (`<class> 0a ...`) and long-frame (`AA FF`, 16-bit checksum) handling from upstream `aabb_device.ts` |
| `fridge_common` | 8 refrigerators | Done: query, record extraction, unit, setpoint conversion and ranges, shared descriptor properties, `F0 17` writes. `2RSFL2DBN3K_Z` uses it with its own captured write template |
| `washer_common` (new) | 9 EU washers, 2 ThinQ1 washers | Port the enum tables from upstream `washer_common.ts`. Distinct from `monitoring_common`, which serves the Korean monitoring-record family |
| `dishwasher_common` (new) | 4 dishwashers | Port upstream `dishwasher_common.ts` (status fields, states, option bits) |
| `tlv_common` | 4 TLV drivers | Compare with upstream `tlv_device.ts`, which changed after the DHUM audit (commit `cd98450d`). Re-check DHUM against the new baseline. `RAC_056905_WW` is the largest TLV driver and may need capability handling `tlv_common` lacks |
| ThinQ1 | 3 drivers | ThinQ1 status arrives through `on_data`; commands go out with `ctx.send_json`. `RAC_056905_WW` has a ThinQ1 and a ThinQ2 variant under the same model ID: branch on `ctx.is_thinq2()` in one file |

## Order

1. Shared `aabb_common` additions, with their own tests.
2. Families with a shared module, one representative first, then the rest:
   refrigerators, dishwashers, EU washers.
3. Standalone AABB drivers, smallest first.
4. TLV: `POT_056905_WW`, then `RAC_056905_WW` (with its ThinQ1 variant).
5. Aliased models, once the alias approach is decided.
6. `WIN_056905_WW` last: upstream has no tests for it.

## Tracker

Status: `todo`, `ported`. Tests and fixtures
are counts of upstream `test(...)` cases and hex fixtures. Ack = upstream
auto-ack enabled; Env = envelope status; Long = long framing.

### Refrigerators (`fridge_common`, AABB)

| model | tests | fixtures | notes | status |
|---|---|---|---|---|
| `2REB1GLVB1__2` | 12 | 6 | | ported |
| `2REF11EBIVPC4` | 18 | 6 | Israeli market | todo |
| `2REF11EIDA__4` | 14 | 5 | | todo |
| `2REF11EIDG__4` | 6 | 16 | LRFXC2606S, Ack | todo |
| `2REFT1DIC4P_U` | 18 | 27 | | todo |
| `2REFTBDII4P_U` | 13 | 10 | 68-byte record | todo |
| `2RES1VE600FWC` | 16 | 9 | different temperature encoding | todo |
| `2RES1VE61NFA2` | 12 | 4 | | ported |

### Dishwashers (`dishwasher_common`, AABB)

| model | tests | fixtures | notes | status |
|---|---|---|---|---|
| `D0211` | 24 | 19 | DB365TXS / DBC435TSL, Ack | todo |
| `D30` | 20 | 27 | LDT54788D | todo |
| `H11` | 19 | 29 | | todo |
| `N17` | 28 | 34 | LDNPQ445S | todo |

### EU washers and washer-dryers (`washer_common`, AABB)

| model | tests | fixtures | notes | status |
|---|---|---|---|---|
| `F_C__Y___W.A__QEUK` | 38 | 14 | F4WV709P1 | todo |
| `F_V8_Y___W.B_2QEUK` | 7 | 7 | aliases `F_V7_Y___W.B_2QEUK`, `F_V7_Y___W.B__QEUK`, `F_V__Y___W.B_2QEUK` | todo |
| `F_VB_F___W.B_2QEUK` | 16 | 8 | CV74J7S2QA washer-dryer | todo |
| `F_VB_Y___W.B_2QEUK` | 13 | 12 | F4WV710ATR, Ack | todo |
| `F_V__F___W.B_1QEUK` | 17 | 9 | alias `F_VA_F___W.B__QEUK` | todo |
| `VCDWL2QEUK` | 29 | 34 | F4X7511TWS | todo |
| `Y_V8_F___W.B_2QEUK` | 6 | 5 | W4WR70E61 washer-dryer | todo |
| `Y_V8_Y___W.B32QEUK` | 31 | 14 | FSR7A04PG, Ack, Env | todo |
| `Y_VB_Y___W.B32QEUK` | 25 | 19 | F14R76BSTA; extends `Y_V8_Y___W.B32QEUK` | todo |

### ThinQ1 washers (`washer_common`, JSON)

| model | tests | fixtures | notes | status |
|---|---|---|---|---|
| `WTDN3` | 13 | 7 | | todo |
| `WTWN3` | 9 | 8 | F4J7TN1W | todo |

### US and other laundry (AABB, standalone)

| model | tests | fixtures | notes | status |
|---|---|---|---|---|
| `T1789EFH_F` | 21 | 22 | WT7300CW top-load washer, Ack | todo |
| `TLVE5BB` | 6 | 7 | WT21BWV6 top-load washer, Env | todo |
| `F3L2CYU__` | 8 | 32 | front-load washer | todo |
| `F3L7CYK5W_US_WIFI` | 18 | 29 | same layout as `F3L2CYU__` | todo |
| `F3P3CYK2_` | 13 | 17 | WM4200HBA, 44-byte records | todo |
| `FAFXU25006` | 28 | 42 | WM5800HVA, Env, Long, 72-byte records | todo |
| `WTL_FXU_BDV_NA_01` | 28 | 29 | WashTower | todo |
| `RV13U6AM8W_D_US_WIFI` | 28 | 23 | DLE7300WE dryer, Ack | todo |
| `RV13B6BSD_D_US_WIFI` | 11 | 22 | electric dryer | todo |
| `RV13B6ES_D_US_WIFI` | 15 | 20 | electric dryer, layout of `RV13B6BSD_D_US_WIFI` | todo |
| `BDH_D30007_US` | 18 | 29 | DLHC5502V heat-pump dryer, Long | todo |
| `RC90U2_WW` | 12 | 19 | RC9DN9029 heat-pump dryer (EU); alias `RC90V9_WW` | todo |
| `ST_B_E4H01Y_APL` | 33 | 49 | Styler S5BBP | todo |

### Cooking (AABB, standalone)

| model | tests | fixtures | notes | status |
|---|---|---|---|---|
| `STUDIO_HOOD` | 17 | 7 | range hood | todo |
| `WMVEM1825` | 15 | 15 | microwave | todo |
| `WMVEL2137` | 17 | 29 | MVEL2033F microwave/hood, Long | todo |
| `WLREL6323S` | 10 | 17 | LREL6323S electric range | todo |
| `WLSI_633_` | 21 | 42 | LSIS6338FE induction range | todo |
| `WFV474PGV` | 52 | 58 | double oven range | todo |

### Air (TLV)

| model | tests | fixtures | notes | status |
|---|---|---|---|---|
| `DHUM_056905_WW` | 16 | 12 | dehumidifier; re-check against the new baseline | ported |
| `POT_056905_WW` | 7 | 11 | LP1022FVSM portable air conditioner | todo |
| `RAC_056905_WW` | 8 + 12 | 22 | air conditioner; ThinQ1 variant `RAC_056905_WW_T1`; alias `RAC_0B0001_WW` | todo |
| `WIN_056905_WW` | 0 | 0 | LW1823HRSM window air conditioner; no upstream tests | todo |
