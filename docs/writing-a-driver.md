# Writing a `.rhai` driver

A checklist-shaped recipe for adding a shared driver under `drivers/`. Prepare
`dist/<version>` for execution; see [README.md](../README.md#using-it). Read
[0.2-runtime.md](https://github.com/3735943886/rusthinq/blob/dev/0.2/docs/0.2-runtime.md) first for what each hook means and what the host does around
it (that document is in the rusthinq repository); this document is the step-by-step of turning a device's wire protocol into one. It is
written to be read by an AI agent driving the work as much as by a person.

## 0. What you need before writing anything

- **Real evidence**: frames actually captured from the appliance (rethink's test suite,
  a live capture over `raw_prefix`, an existing TS driver's own doc comments citing a capture).
  Never invent a field's meaning; an offset nothing has confirmed stays unpublished (see
  every existing driver's "not exercised in a capture, so not read here" comments).
- **The old TS driver, if one exists** (`rethink/cloud/devices/<Model>.ts` in the sibling
  checkout): it is the functional spec. Match what it does (which properties, which writes,
  which quirks), not its entity names/ids/topics — those are HA-adapter-specific and out of
  scope (the standing distinction is "function, not naming").
- **The IL spec** (the sibling `ildevice/il.md` and friends, normative for this repository): the
  descriptor/values/commands/rejects you publish must fit it. How you get there in Rhai is free.
  The IL is this repository's convention; rusthinq 0.2 does not require it — see
  [Drivers that do not use the IL](#drivers-that-do-not-use-the-il).
- **Can you capture live?** If the device is connected to a running rusthinq with
  `raw_prefix` set (and `raw` lists at least `rx`, `tx`, `clip_tx`), use
  **`rusthinq-capture <mqtt-host[:port]> <device-uuid> [out.jsonl]`**
  (in the rusthinq repository, `crates/rusthinq-tools/src/bin/rusthinq_capture.rs`) rather than subscribing by hand: it
  taps `rx`/`tx`/`clip/tx` together into one timestamped, TLV/AABB-decoded JSONL file, so rx
  and tx frames are never split across two separate subscriptions racing each other (a real
  write's ack has been missed this way before — don't repeat it). **Set `RUSTHINQ_RAW_PREFIX` to
  the target's `[mqtt] raw_prefix`** (default `rusthinq-raw`) — get this wrong and the tool
  subscribes to a topic nothing publishes and silently captures zero events
  (indistinguishable from "device is idle" until you notice the file never grows).
  Stdin lines become
  timestamped `note` entries in the same file, so ask whoever is operating the real app to
  send a line ("smart_care on") right when they do each thing, and correlate by timestamp
  afterward instead of guessing from wall-clock chat messages. A read-only status query is
  safe to inject via `<raw_prefix>/<id>/raw/inject/set` (same bytes `send_raw`/`aabb_wrap`/
  `tlv_frame_build` would produce, full wire framing included); do not inject a write/command
  frame against a real appliance without the user's sign-off. See `raw_bus.rs`'s doc comment
  for the full topic list.
  **Independent of `raw_prefix` entirely**: `rusthinq-packet-parser`/`rusthinq-packet-sender`
  talk straight to the device's own `clip/message/devices/<id>` topic (what `raw/clip/tx` is
  itself a copy of) — useful when `raw` isn't configured, though as shipped they only build
  TLV frames, not AABB.
  **A write via rusthinq's own `<rusthinq_prefix>/<id>/<prop>/set` and one relayed from the
  real app through an active LG-cloud bridge session end up on the exact same wire path**
  (`ConnectedAsLocal::send_to_local` → the same `send_to_device` a script's `ctx.send_raw`
  uses) — a write that looks unacknowledged from rusthinq's own path is almost always a
  capture gap (see above) or genuine appliance-side flakiness (busy/mid-cycle; this fleet has
  precedent for an acked write the appliance still ignored), not a different code path.

## 1. Identify the frame family

| family | framing | shared module | pick when |
|---|---|---|---|
| TLV | `[hdr..] len [tag,val].. crc16` | `tlv_common.rhai` (`import "tlv_common" as c;`) | the device answers a caps/values handshake (CST_570004_WW, DHUM_056905_WW, AIR_910604_WW) |
| AABB, fixed status | `AA len inner csum BB`, inner is a flat byte record | `aabb_common.rhai` | the device pushes/answers with one fixed-layout status record (1WPU4CIGCR__2, WBEY3GT, 2RSFL2DBN3K_Z) |
| AABB, monitoring record | `AA len inner csum BB`, inner has its own sub-framing (`addr, cmd, [0, len, payload]..`) | `monitoring_common.rhai` (itself imports `aabb_common`) | washer/dryer/styler family (F24VDD, RH14_N_KR, S3BF_POD_DN4, Pd0F_F) |

For fixed-length EB/EC status bodies, unwrap and check the device class with
`aabb_common::inner(data, class_byte)`, then call
`aabb_common::common_status_offset(body, record_length)`. It returns the current
record offset (2 for EB, `2 + record_length` for EC), or `()` for other commands
or non-exact lengths. Keep model-specific command restrictions in the driver
(D140110 accepts only EC). Variable-length records and the monitoring family's
length-prefixed payloads need their own parsing.

A module cannot call back into its importer, so the device script keeps every hook
(`start`, `on_data`, `on_set_property`, ...) and delegates plain parsing/framing to the module
(`c::...`). Read the existing driver closest to the new device's family before writing
anything — copy its shape, not its bytes.

## 2. The descriptor

```rhai
fn descriptor(ctx) {
    json_stringify(#{
        il: 0,
        kind: "...",                 // section 10 of il.md if it should form a composite
        label: "...",                // the device label published by this driver
        vendor: "LG",
        model: ctx.model_id(),
        props: #{ ... }
    })
}
```

- **One property per thing the old driver published**, no more. Its name is a free
  `[a-z0-9_]+` string (`il.md` section 3); reuse the TS driver's own MQTT property name unless
  it collides with a role name below.
- **Roles** (`il.md` section 9) are what let a consumer build a composite (climate,
  humidifier, fan, ...) or a generic UI hint (`available`). Use one only when the property
  really is that thing; do not force a role to fit (a fridge's two independent setpoints get
  no `target_temperature` role — there is no composite for two thermostats, so they stay plain
  `number` properties with `class: "temperature"`).
- **`class`/`series`/`category`** (section 11) on every property where one applies — a
  consumer that does not know a class ignores it (L-1), so there is no cost to adding one.
  `series: "counter"` for a running total that resets (today's water dispensed); `category:
  "diagnostic"` for a fault code or a filter counter; `category: "config"` for a setting a
  person sets once, not an everyday control.
- **`requires`** for a control that only takes effect under a condition the device itself
  enforces (a burner ring that ignores commands unless the panel granted remote start) — the
  script calls `il::validate` to check it before building the write.
- A property the wire cannot yet confirm the meaning of is **left out**, not guessed.

## 3. The hooks

| hook | when | typical body |
|---|---|---|
| `start(ctx)` | device connected | send a status query if the device does not report on its own (`ctx.send_raw(...)`); AABB monitoring/status-pushing devices often need nothing here |
| `publish_config(ctx)` | called once right after `start`, and again on a host resync | `il::publish_il(ctx, descriptor(ctx));` — must be safe to call twice, so build the descriptor fresh from current `ctx.state_get`/`state_has`, never accumulate |
| `on_data(ctx, data)` | every frame from the device | discriminate the frame kind (first byte(s)/tag), decode, `il::publish_property(ctx, name, canonical_text)` |
| `on_set_property(ctx, prop, value)` | a command reached this device; call `il::validate(ctx, prop, value)` against the descriptor first and return if it yields `()` | build and `ctx.send_raw(...)` the write frame; `c::reject(ctx, prop, reason)` for anything the script itself must still refuse (an unknown `prop`, a value the descriptor's static range cannot express) |
| `on_drop(ctx)` | device disconnected | `il::publish_property(ctx, "available", "false")` |

Everything else (timers, `on_timer`, TLV handshake retries) is what the shared module or
`0.2-runtime.md`'s hook documentation cover; most single-status AABB devices need none of it.

## 4. Descriptor that changes after connecting

A device whose valid range or unit depends on something only known after the first frame
(a capability query's reported min/max, a display unit the appliance is currently set to)
follows this shape, used by `drivers/CST_570004_WW.rhai` (capability-driven range) and
`drivers/2RSFL2DBN3K_Z.rhai` (unit-driven range):

```rhai
import "il_common" as il;

fn unit(ctx) { let u = ctx.state_get("unit"); if u == () { "C" } else { u } }  // a sane default

fn status(ctx, r, o) {
    let u = decode_unit(r[o + N]);
    if u != unit(ctx) {
        ctx.state_set("unit", u);
        il::publish_il(ctx, descriptor(ctx));  // republish: the descriptor just changed
    }
    // ... publish values using u ...
}
```

`publish_config` still publishes a descriptor with the default eagerly at `start` — never
withhold the descriptor waiting for data the device might not send for a while.

## 5. Writes

Three shapes cover every driver so far; pick by what the appliance's own write frame turns
out to look like (verify against a captured accepted write before choosing):

1. **Tag-attach (TLV)**: `c::write(ctx, tag, value, [other_tags_to_carry])` — the shared
   TLV module handles current-value lookup and framing; the third argument is which other
   tags a write of this one must also carry (a mode write also needs power=on, for instance).
   See `drivers/CST_570004_WW.rhai`.
2. **All-`0xFF`-but-one template (AABB)**: build `[0xf0, cmd]` then push `0xFF` for
   every offset except the one being set — valid when a captured accepted write really is
   uniform apart from the one field. See `1WPU4CIGCR__2.rhai`'s `set_field`.
3. **Literal captured template (AABB)**: `hex_decode(base_hex_string())` then mutate the
   specific byte(s) as a `Blob` (`msg[offset] = value;`, works directly — `Engine::new()`'s
   default `Blob` package is loaded) — required when the real write frame carries fixed
   non-`0xFF` marker bytes elsewhere that a generic fill would lose (comment why, cite the
   capture). See `drivers/2RSFL2DBN3K_Z.rhai`'s `write_field`.

In every shape: **nothing is published from a write.** The appliance's own next status frame
is what moves the property; a rejected write just leaves it where it was.

## 6. Rhai gotchas specific to this engine

- Rhai functions cannot see a top-level `const`/`let` — write a zero-argument function
  instead (`fn record_len() { 26 }`), even for something that looks like a constant.
- `~` is not an operator here; use an explicit mask (`& 0xdf`).
- A `Blob` element (from `hex_decode`, `aabb_unwrap`, indexing a frame) compares directly
  against an int literal (`if inner[1] == 0xec`) and works in a `switch`; call `.to_int()`
  only when you need it in float arithmetic or string formatting (`(v / 10.0)`,
  `n.round().to_int()`).
- Slicing: there is no `array[a..b]`. For a `Blob`/`Array`, `x.extract(n)` drops the first
  `n` elements; most decoders instead pass the whole record plus an integer offset and index
  `r[offset + k]` throughout (see any `status(ctx, r, o)` function). For a `String`,
  `s.sub_string(start, len)`.
- `aabb_wrap`/`tlv_frame_build` accept either an `Array` of small ints or a `Blob`
  (`Vec<u8>`) — build with whichever is more convenient, no conversion needed.
- `hex_decode`/`hex_encode`/`hex_encode_upper`, `crc16`, `tlv_parse`/`tlv_build`,
  `tlv_frame_parse`/`tlv_frame_build`, `aabb_wrap`/`aabb_unwrap` are globally available, in
  drivers and in tests.

## 7. Tests (`tests/<Model>.test.rhai`)

Every `.rhai` driver needs one (`rusthinq-script-test` fails otherwise). Model
it on the closest existing test file for the same frame family. Minimum coverage:

- **A real frame becomes the right properties** — `expect_props(d, #{ prop: "value", .. })`
  against a captured frame (cite where it came from in a comment).
- **The descriptor** — `d.start(); let desc = runtime::descriptor(d);` (import `"runtime_test" as runtime`) (only valid after `start`, since
  that is what runs `publish_config`), check roles/class/range/label for at least the
  interesting properties.
- **Every write, byte for byte**, against a captured accepted write if one exists, else
  against the template the driver itself computes — `expect_eq(a::inner_hex(d, i), "...")` /
  `t::sent_tlvs(d, i)`. Compute the expected hex with a throwaway script, do not hand-derive
  checksums.
- **A bad write is rejected and nothing is sent**: `let n = d.sent().len(); d.set(prop,
  bad_value); expect_eq(d.sent().len(), n); expect(d.event("reject") != (), "...");` — call `d.start()` first so the descriptor is available to `il::validate`; use the same
  pattern for out-of-range, bad-step, wrong-type and unknown-property commands.
- **Any quirk cited in a comment gets its own test** (a wire value with two meanings, a
  field that only appears while another is true, a frame length variant).

`import "tlv_test" as t;` / `import "aabb_test" as a;` (`tests/`) hold the shared
frame-building and inspection helpers; read them before writing raw hex by hand.

## 8. Wiring it in

1. `drivers/<exact wire modelId>.rhai` — the filename is the lookup key
   (`scripting::has_script_for`), so it must match the `modelId` the device reports exactly,
   including case and underscores.
2. `tests/<Model>.test.rhai` in the shared test directory.
3. Prepare both runtimes with `python3 tools/prepare.py 0.1` and
   `python3 tools/prepare.py 0.2`, then run both matching host runners as shown in
   [README.md](../README.md#checking-a-change).
   Both runners execute the shared device assertions. The 0.1 runner also performs
   its host-side IL descriptor checks.
4. Add one row to the driver table in [README.md](../README.md#drivers) stating
   exactly what was and was not verified against a real appliance — copy the phrasing style
   of an existing row, do not oversell "tested".
5. **Never point this driver's model at a device another consumer (rusthinq-adapter, a raw-bus
   tool) is already driving** — two unaware writers on one appliance. If replacing an existing
   consumer, detach it first.

## Drivers that do not use the IL

Everything above assumes the IL because every driver in this repository uses it, and
the shared tests assert descriptors. The 0.1 runner additionally checks the IL.
rusthinq 0.2 itself does not care: a driver in your own `rhai_dir` can skip `il_common` and publish in whatever shape
its consumer wants, for example:

- **Home Assistant MQTT discovery**: publish each entity's config to
  `homeassistant/<component>/<id>/<object>/config` with
  `ctx.publish_raw(topic, json, true)` from `publish_config` (retained, so it survives
  Home Assistant restarting), and state with `ctx.publish_raw`.
- **Anything else**: `ctx.publish_raw(topic, payload, retain)` publishes to any exact topic,
  outside `rusthinq_prefix`.

Without `il_common`, your driver must validate commands itself:
`on_set_property` receives every `set` as sent and must check type, range and options itself,
and consumers that read the IL will not see the device. The frame
decoding, the shared modules and the test helpers above work the same either way. Such a
driver is yours to keep; it does not belong in this repository.

## 9. Before calling it done

- [ ] Both version-specific driver runners — new tests pass, nothing else broke, no driver check fails
- [ ] every published property/value/reject traces to a real capture or the old TS driver's
      confirmed behavior — nothing invented
- [ ] README table row added
- [ ] if the driver needs a host function or behavior newer than `RUSTHINQ_REF`, the corresponding `compat/<version>/RUSTHINQ_REF`
      is moved forward in the same change
