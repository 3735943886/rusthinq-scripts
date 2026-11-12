# Supported drivers

Every driver in this repository, with how far it has been verified against a real
appliance. The filename in `drivers/` is the `modelId` the appliance reports. To add
a row, see [writing-a-driver.md](writing-a-driver.md#8-wiring-it-in).

## Verification status

- **live**: run against the real appliance; reads and writes confirmed.
- **captured**: tested against frames captured from a real appliance and, where
  available, writes the LG app sent; not yet run live.
- **constructed**: status frames built from documented offsets or around a
  captured record; writes match captured frames.

Each test file cites the captures its driver is checked against.

## Drivers

| model | appliance | protocol | status |
|---|---|---|---|
| `2RSFL2DBN3K_Z` | refrigerator | AABB | live |
| `2REB1GLVB1__2` | refrigerator | AABB | captured |
| `2REBGLUB_2P__` | bottom-freezer refrigerator (GBBSJ2CCEP) | AABB | captured |
| `2REF11EBIVPC4` | refrigerator | AABB | constructed |
| `2REF11EIDA__4` | refrigerator | AABB | captured |
| `2REF11EIDG__4` | refrigerator | AABB | captured |
| `2REF11EII__M2` | refrigerator (LMXS28626) | AABB | captured |
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
| `IV12SNNWW` | robot vacuum (RoboKing AI all-in-one) | JSON | live |
| `PAC_910604_WW` | floor-standing air conditioner | TLV | captured |
| `CST_170004_WW` | ceiling-cassette air conditioner (`cst_common`) | TLV | captured |
| `CST_570004_WW` | ceiling-cassette air conditioner (`cst_common`) | TLV | captured |
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
| `G2V7_Y___W.B_2QEUK` | slim washer (F2NX50S9TKC) | AABB envelope | captured |
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
| `RV13D5JSD_D_US` | dryer (DLEX4200B; power off only) | AABB | captured |
| `BDH_D30007_US` | heat pump dryer (read-only) | AABB envelope | captured |
| `RC90U2_WW` | heat pump dryer (read-only) | AABB | captured |
| `RC90V9_WW` | heat pump dryer (read-only; alias of `RC90U2_WW`) | AABB | captured |
| `RC90V9_AUS` | heat pump dryer (read-only; alias of `RC90U2_WW`) | AABB | captured |
| `WTL_FXU_BDV_NA_01` | WashTower (washer and dryer) | AABB | captured |
| `FAKPK21021` | Korean WashTower washer | AABB envelope | captured |
| `BDH_D39301_KR` | Korean WashTower dryer | AABB envelope | captured |
| `WTDN3` | washer-dryer | ThinQ1 | captured |
| `WTWN3` | washer | ThinQ1 | captured |

## Not yet here

Drivers planned from upstream rethink are tracked in [porting.md](porting.md).
Additional open PR ports from `dohun0310` and `tunarabuuu`, including exact revisions
and runtime differences, are recorded in [porting-prs.md](porting-prs.md).
