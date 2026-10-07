# rethink upstream driver audit

Reviewed on 2026-10-08 against official [anszom/rethink](https://github.com/anszom/rethink)
master commit `cd98450d0c195ba89068d56c16cdadf094977d65` (2026-10-04).
This is a source/fixture audit, not live-appliance validation. Production drivers
were not changed by this review.

## Exact model coverage

Only `DHUM_056905_WW` has an exact-model TS driver in this upstream revision.
The other ten models have no matching filename or model reference in upstream's
`cloud/` or `tests/`: `1WPU4CIGCR__2`, `2RSFL2DBN3K_Z`, `AIR_910604_WW`,
`CST_570004_WW`, `D140110`, `F24VDD`, `Pd0F_F`, `RH14_N_KR`,
`S3BF_POD_DN4`, `WBEY3GT`. Similar family drivers are not evidence of exact-model
correctness. References to rethink captures in existing tests may originate from
a different revision or fork; they do not establish coverage by current upstream.

## DHUM findings

1. **Unverified extra temperature interpretation.**
   `drivers/DHUM_056905_WW.rhai` publishes `0x1fd / 2` as Celsius temperature.
   Upstream exposes no temperature field and explicitly distinguishes `0x1fd`
   from humidity, mentioning its temperature meaning on RAC/WIN platforms only.
   A captured value and a plausible converted temperature do not establish its
   meaning on DHUM. The Rhai assertion expecting 31°C checks the implementation,
   not agreement with an independently observed appliance temperature. Obtain
   DHUM-specific evidence before considering this property verified.

2. **Unverified extra tank enum and conflicting outputs.**
   Rhai interprets `0x186` as `not_full/full_stopped/full_fan_mode`; upstream
   uses `0x2b2 != 0` for bucket-full and `0x2b1 == 256` to clear it. These latter
   paths work correctly in Rhai too, but its descriptor lists only `0x186` as
   the source of `tank_full`. Its `tank_state` changes only on `0x186`, so
   `0x186=0` followed by `0x2b2=1` yields `tank_state=not_full` and
   `tank_full=true`. The enum's meaning needs independent evidence; do not invent
   a three-state mapping from upstream's binary bucket-full signal.

3. **Capability-phase filtering differs.**
   Upstream stores `0x336` without publishing humidity while its capability
   query is pending. Rhai discards packets containing `0x2da`, but applies
   a standalone `0x336` packet before capabilities complete. Replaying
   `0x336=52` immediately after `start` publishes humidity 52 while availability
   remains false. This is a confirmed behavior difference; whether it matters
   for a real DHUM requires evidence of capability responses/notification order.
   The shared `tlv_common` is involved, so any correction needs other TLV models
   checked too.

## Confirmed agreement and intentional differences

The upstream-supported controls agree: power, mode aliases and write codes,
fan low/high, five mode-fan capability rows (laundry fixed high), target humidity,
ionizer (`sterilize`), UVnano, bucket light and off timer. Attachments and packet
framing match. Silent-mode entry defaults the fan to low and subsequently permits
high. Bucket full/empty and humidity are independent.

Timer state is intentionally minutes in IL rather than upstream's rounded-up
hours; writes of 60/300/540 minutes match upstream's 1/5/9 hours. Invalid target
commands are rejected by IL rather than clamped/rounded as upstream does.
Enumeration spelling, MQTT topics, HA entity layout and eager descriptor
publication are integration differences, not wire protocol defects.
The extra `0x221` error property is also not confirmed by this exact upstream
driver. Unknown-tag handling differs: Rhai skips unknown enum values rather than
publishing upstream's fallback representation.

## Validation evidence

- Upstream's DHUM suite: **16 passed, 0 failed**, using
  `node --import tsx --test --test-reporter=spec tests/cloud/devices/DHUM_056905_WW.test.ts`.
- Real upstream query/ionizer/UV/bucket-light/bucket-full/empty/countdown fixtures
  replayed against both Rhai hosts.
- **20 sequential valid commands** compared with TS-generated full packet hex,
  including CRC: **all byte-identical on 0.1 and 0.2**.
- Original 188 tests plus seven audit assertions: **195 passed on each host**;
  0.1 additionally checked all 11 descriptors with zero problems.
- Audit artifacts: [additional assertions](DHUM_056905_WW.upstream.rhai) and
  [TS-generated command frames](DHUM_056905_WW.upstream-writes.json).
  Append the assertions to the prepared `tests/DHUM_056905_WW.test.rhai`, then
  run the matching host runner. Preparing again restores the regular suite.

Primary references at the pinned revision:
[DHUM driver](https://github.com/anszom/rethink/blob/cd98450d0c195ba89068d56c16cdadf094977d65/cloud/devices/DHUM_056905_WW.ts),
[DHUM tests](https://github.com/anszom/rethink/blob/cd98450d0c195ba89068d56c16cdadf094977d65/tests/cloud/devices/DHUM_056905_WW.test.ts),
[TLV base](https://github.com/anszom/rethink/blob/cd98450d0c195ba89068d56c16cdadf094977d65/cloud/devices/tlv_device.ts).
