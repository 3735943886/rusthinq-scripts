# Capture, control, observe

The shortest reliable way to a driver is a loop against the real appliance: capture what it
does, write down what that means, send a command and watch what comes back. This page walks
through that loop with `rusthinqctl`. [writing-a-driver.md](writing-a-driver.md) covers how to
write the driver itself.

If you have no appliance, you can still write a driver from someone else's captures. Mark it
`constructed` or `captured` in [drivers.md](drivers.md) as appropriate, and state what is
unconfirmed.

## Setup

`rusthinqctl` talks to a running rusthinq daemon through its management API. `decode` is the
exception and works offline.

```bash
export RUSTHINQ_API=http://127.0.0.1:44401/   # your daemon's management address
rusthinqctl devices                           # find the device ID and modelId
```

Set `RUSTHINQ_USER` and `RUSTHINQ_PASSWORD` if your daemon requires them.

## 1. Capture

Start a capture before touching the appliance, and leave it running through the next steps:

```bash
rusthinqctl capture DEVICE capture.jsonl
```

Type a note and press Enter each time you do something, such as `cold water, 250 mL` or
`door opened`. Notes are recorded in time order between the packets. Stop with Ctrl+C.

Capture observes only; it sends nothing to the appliance. Each line is a JSON record:

```json
{"k":"rx","t":1762300000000,"type":"packet","hex":"aa..."}
{"k":"note","t":1762300001000,"text":"door opened"}
```

`k` is `rx` (from the appliance), `tx` (to it) or `note`.

Cover a whole cycle: start, each operation, completion, power off and idle. Note what the app
and the panel show at each step, with units. Also disconnect the appliance once, because some
frames appear only on connect.

Before drawing conclusions, check that the file holds `rx` packets and no loss records.
A connected device does not prove any frames arrived.

`--cloud` adds LG notifications, if your daemon has an LG account configured, so you can compare
them with the wire traffic ([host documentation](https://github.com/3735943886/rusthinq/blob/master/docs/0.2-dashboard.md#lg-notification-observation-and-correlated-captures)).
It is not needed for a wire capture.

## 2. Read the frames

```bash
rusthinqctl decode AA...BB
```

This decodes the framing and works without a daemon. What the bytes mean is your job: change one
thing on the appliance, then compare the frames before and after. Compare with the app's values
before assigning a unit, and do not copy offsets from a similar model without checking them.
Be clear which offsets you mean: full frame, unwrapped body or payload.

An offset nothing has confirmed stays unpublished.

## 3. Write the driver and test it offline

Follow [writing-a-driver.md](writing-a-driver.md). Put the frames you relied on into
`tests/<modelId>.test.rhai`, then run the checks in the
[README](../README.md#checking-a-change). They need no appliance.

Keep full captures outside the repository, or in the ignored `docs/audits/` directory. Add only
the frames a test needs, after reviewing them.

## 4. Load it and observe

Point `[drivers] directory` at your checkout with `watch = true`, so that saving a driver reloads
it. Then watch the values on MQTT and compare them with the app and the panel:

```bash
mosquitto_sub -v -t 'rusthinq/DEVICE/#'      # your [drivers] topic_prefix and device ID
```

## 5. Control

**`set` operates the real appliance.** Stay near it, and start with something harmless such as a
display setting. Avoid anything that heats, moves or runs water until you trust the frame.

With the capture from step 1 still running:

```bash
rusthinqctl set DEVICE PROPERTY VALUE
```

Then check three separate things:

1. The `tx` record is the frame you expected. Compare it with what the LG app sends for the same
   action, if you have that captured.
2. The appliance acted on it. A sent frame does not prove this.
3. The next `rx` status moved the property. Drivers publish from status, not from writes, so the
   value should change only now.

Also try a value that should be refused, and check that nothing is sent and a reject is published.

## 6. Replay and raw packets

Both need the daemon's injection switch and an explicit `--inject-ok`:

```bash
rusthinqctl raw-inject on
rusthinqctl replay DEVICE capture.jsonl --inject-ok     # feeds rx records to the driver
rusthinqctl inject DEVICE HEX --from-device --inject-ok # feeds one frame to the driver
rusthinqctl inject DEVICE HEX --inject-ok               # SENDS one frame to the appliance
rusthinqctl raw-inject off
```

`replay` and `--from-device` run recorded frames through the driver without sending anything to
the appliance, which is a safe way to re-check a decoder, although the driver's own replies may
still go out. The driver publishes the replayed values as if they were current, so re-sync
afterwards.

Plain `inject` skips the driver's validation, and the appliance receives exactly the bytes you
typed. Use it only with a frame you captured from the LG app, for testing a write the driver does
not build yet.

## 7. Record what you verified

Set the status in [drivers.md](drivers.md) to what you actually did: `live` if you ran reads and
writes on the appliance, `captured` if tests use real frames, `constructed` otherwise. If only
part of a driver was exercised, for example the appliance was off in every capture, say so in the
driver header and the PR.

## Long captures

For a bounded background capture on a Linux host running systemd:

```bash
sudo systemd-run --unit=rusthinq-capture-example \
  --property=User=YOUR_USER --property=RuntimeMaxSec=24h \
  --setenv=RUSTHINQ_API=http://127.0.0.1:44401/ \
  /ABSOLUTE/PATH/rusthinqctl capture DEVICE /ABSOLUTE/PATH/capture.jsonl
systemctl status rusthinq-capture-example
journalctl -u rusthinq-capture-example
# End early:
sudo systemctl stop rusthinq-capture-example
```

Use a writable output directory and the actual executable path. Background captures cannot take
typed notes, so keep a separate action log. This unit does not return after a reboot. For
indefinite capture, omit `RuntimeMaxSec`; to capture across reboots, install a regular systemd
service with `Restart=always` and enable it. When finished, stop and disable it, remove its unit
file and run `systemctl daemon-reload`. Keep the capture files.
