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
   [tools/rethink_frames.ts](../tools/rethink_frames.ts), not by hand;
   [tools/rethink_fixtures.mjs](../tools/rethink_fixtures.mjs) prints the
   upstream test's fixtures.
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
- **Aliases and extensions.** Upstream maps several model IDs to one driver,
  and some drivers extend another. rusthinq `9db5422` lets a driver inherit a
  module's functions with an unaliased `import "<module>";`, its own
  definitions overriding them. Put the shared driver body in `modules/`; an
  alias is then the one import line, and an extension overrides only what
  differs. Each model still needs its own test file.

### Shared modules

| module | needed by | work |
|---|---|---|
| `aabb_common` | 6 drivers with auto-ack; 3 with envelope status; 3 with long frames | Cloud ack (`c::ack`) and envelope status (`c::enveloped_status`) done. Long frames (`AA FF`) need nothing more: the host's `aabb_unwrap` leaves the 16-bit checksum's extra byte on the body, as upstream does |
| `fridge_common` | 8 refrigerators | Done: query, record extraction, unit, setpoint conversion and ranges, shared descriptor properties, and `F0 17` writes over a 0xFF record or the LG app's 118-byte record, which every captured model sends a prefix of. `2RSFL2DBN3K_Z` uses it too |
| `washer_common` | 9 EU washers, 2 ThinQ1 washers | Done: the tables of upstream `washer_common.ts` and a whole driver that `F_V8_Y` and relatives inherit, overriding `features()`; `washer_v__f_common` carries `F_V__F` for its alias. `washer_y8_common` is the `Y_V8_Y` driver, which `Y_VB_Y` extends. `F_C__Y` and `VCDWL2QEUK` use only its tables, as does `washer_t1_common`, the ThinQ1 driver that `WTDN3` and `WTWN3` inherit |
| `dishwasher_common` | 4 dishwashers | Done: status query, record payload, states and phases, shared descriptor properties, `0x3E` energy, `F0 26` actions and staged remote start. `D140110` uses it too |
| `tlv_common` | 4 TLV drivers | Compared with upstream `tlv_device.ts` for RAC: its private `0xfd` commands (the filter) are `rac_common`'s own frames, and the faster polling is `climate_common`'s. Re-check DHUM against the new baseline |
| `climate_common` | 4 air conditioners | Done: a whole driver over `tlv_common` for power, mode, fan, setpoint, room temperature, the action and its 28 s polling, the setpoint range from the capabilities and the 1200 masking, taken from `CST_570004_WW` (which inherits it, descriptor unchanged). Hooks for capability features, the first state, own frames and timers; a driver that overrides a hook reaches it as `climate_<hook>`. `POT_056905_WW` and `rac_common` (`RAC_056905_WW`, `RAC_0B0001_WW`, with the ThinQ1 variant) inherit it |
| ThinQ1 | 3 drivers | Done: `washer_t1_common` and `rac_common`'s ThinQ1 branch. Status arrives through `on_data`, decoded from the push's base64; `start` sends Mon/Start, commands go out with `ctx.send_json`. Acks need rusthinq `2fe89dd` or later, and the RAC's ~2 KB JSON status needs the larger blob limit of rusthinq `bb81da0` or later |

## Order

1. Refrigerators and dishwashers: done.
2. EU and ThinQ1 washers: done.
3. Standalone AABB drivers, smallest first.
4. TLV air conditioners on `climate_common`: `POT_056905_WW` and `RAC_056905_WW` (with its ThinQ1 variant) done.
5. Aliased models (one-line inheriting drivers).
6. `WIN_056905_WW`: done, with constructed tests (upstream has none).

## Tracker

Status: `todo`, `ported`. Tests and fixtures
are counts of upstream `test(...)` cases and hex fixtures. Ack = upstream
auto-ack enabled; Env = envelope status; Long = long framing.

### Refrigerators (`fridge_common`, AABB)

| model | tests | fixtures | notes | status |
|---|---|---|---|---|
| `2REB1GLVB1__2` | 12 | 6 | | ported |
| `2REF11EBIVPC4` | 18 | 6 | Israeli market; upstream reads setpoints in half degrees but writes whole ones | ported |
| `2REF11EIDA__4` | 14 | 5 | | ported |
| `2REF11EIDG__4` | 6 | 16 | LRFXC2606S, Ack | ported |
| `2REFT1DIC4P_U` | 18 | 27 | | ported |
| `2REFTBDII4P_U` | 13 | 10 | 68-byte record | ported |
| `2RES1VE600FWC` | 16 | 9 | different temperature encoding | ported |
| `2RES1VE61NFA2` | 12 | 4 | | ported |

### Dishwashers (`dishwasher_common`, AABB)

| model | tests | fixtures | notes | status |
|---|---|---|---|---|
| `D0211` | 24 | 19 | DB365TXS / DBC435TSL, Ack | ported |
| `D30` | 20 | 27 | LDT54788D | ported |
| `H11` | 19 | 29 | | ported |
| `N17` | 28 | 34 | LDNPQ445S; start requires remote start armed (upstream sends it anyway) | ported |

### EU washers and washer-dryers (`washer_common`, AABB)

| model | tests | fixtures | notes | status |
|---|---|---|---|---|
| `F_C__Y___W.A__QEUK` | 38 | 14 | F4WV709P1 | ported |
| `F_V8_Y___W.B_2QEUK` | 7 | 7 | aliases `F_V7_Y___W.B_2QEUK`, `F_V7_Y___W.B__QEUK`, `F_V__Y___W.B_2QEUK` | ported |
| `F_VB_F___W.B_2QEUK` | 16 | 8 | CV74J7S2QA washer-dryer | ported |
| `F_VB_Y___W.B_2QEUK` | 13 | 12 | F4WV710ATR, Ack | ported |
| `F_V__F___W.B_1QEUK` | 17 | 9 | alias `F_VA_F___W.B__QEUK` | ported |
| `VCDWL2QEUK` | 29 | 34 | F4X7511TWS | ported |
| `Y_V8_F___W.B_2QEUK` | 6 | 5 | W4WR70E61 washer-dryer | ported |
| `Y_V8_Y___W.B32QEUK` | 31 | 14 | FSR7A04PG, Ack, Env | ported |
| `Y_VB_Y___W.B32QEUK` | 25 | 19 | F14R76BSTA; extends `Y_V8_Y___W.B32QEUK` | ported |

### ThinQ1 washers (`washer_t1_common`, JSON)

| model | tests | fixtures | notes | status |
|---|---|---|---|---|
| `WTDN3` | 13 | 7 | F2J7HG1W washer-dryer | ported |
| `WTWN3` | 9 | 8 | F4J7TN1W | ported |

### US and other laundry (AABB, standalone)

| model | tests | fixtures | notes | status |
|---|---|---|---|---|
| `T1789EFH_F` | 21 | 22 | WT7300CW top-load washer, Ack | ported |
| `TLVE5BB` | 6 | 7 | WT21BWV6 top-load washer, Env | ported |
| `F3L2CYU__` | 8 | 32 | front-load washer (`washer_f3l_common`) | ported |
| `F3L7CYK5W_US_WIFI` | 18 | 29 | same layout as `F3L2CYU__`, own course table and bits (`washer_f3l_common`) | ported |
| `F3P3CYK2_` | 13 | 17 | WM4200HBA, 44-byte records; power off only | ported |
| `FAFXU25006` | 28 | 42 | WM5800HVA, Env, Long, 72-byte records | ported |
| `WTL_FXU_BDV_NA_01` | 28 | 29 | WashTower; doors absent until reported (upstream assumes shut) | ported |
| `RV13U6AM8W_D_US_WIFI` | 28 | 23 | DLE7300WE dryer, Ack (`dryer_rv13_common`) | ported |
| `RV13B6BSD_D_US_WIFI` | 11 | 22 | electric dryer (`dryer_rv13_common`) | ported |
| `RV13B6ES_D_US_WIFI` | 15 | 20 | electric dryer, layout of `RV13B6BSD_D_US_WIFI` (`dryer_rv13_common`) | ported |
| `BDH_D30007_US` | 18 | 29 | DLHC5502V heat-pump dryer, Long | ported |
| `RC90U2_WW` | 12 | 19 | RC9DN9029 heat-pump dryer (EU; `dryer_rc90_common`); alias `RC90V9_WW` | ported |
| `ST_B_E4H01Y_APL` | 33 | 49 | Styler S5BBP; undefined codes absent | ported |

### Cooking (AABB, standalone)

| model | tests | fixtures | notes | status |
|---|---|---|---|---|
| `STUDIO_HOOD` | 17 | 7 | range hood | ported |
| `WMVEM1825` | 15 | 15 | microwave | ported |
| `WMVEL2137` | 17 | 29 | MVEL2033F microwave/hood, Long | todo |
| `WLREL6323S` | 10 | 17 | LREL6323S electric range | todo |
| `WLSI_633_` | 21 | 42 | LSIS6338FE induction range | todo |
| `WFV474PGV` | 52 | 58 | double oven range | todo |

### Air (TLV)

| model | tests | fixtures | notes | status |
|---|---|---|---|---|
| `DHUM_056905_WW` | 16 | 12 | dehumidifier; re-check against the new baseline | ported |
| `POT_056905_WW` | 7 | 11 | LP1022FVSM portable air conditioner (`climate_common`) | ported |
| `RAC_056905_WW` | 8 + 12 | 22 | air conditioner (`rac_common`); ThinQ1 variant `RAC_056905_WW_T1` in the same file; alias `RAC_0B0001_WW`. Filter reset not offered: it needs today's date | ported |
| `WIN_056905_WW` | 0 | 0 | LW1823HRSM window air conditioner (`climate_common`); no upstream tests, so constructed ones; dry left out, as upstream reads no code for it | ported |
