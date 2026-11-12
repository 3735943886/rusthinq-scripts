// LG humidifying air purifier HUM_056905_WW: hum_common, plus the appliance's own start/stop
// reservations. First ported from anszom/rethink PR #114 (5898c3b6c2407c71281d8ef6e6caffb036a82b22),
// then brought to a private rethink fork driver running on installed units, checked against live
// capability/value replies from two units (2026-11-10).
//
// Reservations (start_time 0x35a, stop_time 0x35b, HHMM, 0 = none, 2400 = midnight) travel in
// private command 03, not as TLV writes, which the appliance acknowledges without effect. Every
// values query is followed by GET `00ff..65fd02 0001 03`; the reply `..87fd03 000d 03` carries both
// times as little-endian uint32. SET is `0102..65fd01 0009 03`, a big-endian uint32 selector (1 =
// start, 2 = stop) and value. The appliance answers 02 (ACK) or 03 (NACK), and also pushes a
// `..6501 04` notification of the two tags. A set, readback and clear were captured on two units.
// Writes wait until this session has read the time back, and nothing is published from them: an
// ACK re-queries once, a NACK rejects the pending property. Every private frame's CRC is checked.
//
// Not ported: rethink's Home Assistant entity layout and Korean labels.
import "hum_common";

fn native_reservations() { true }

fn valid_hhmm(v) { v >= 0 && v <= 2400 && (v == 2400 || v % 100 < 60) }

fn reservation_query(ctx) { ctx.send_raw(hex_decode("00ff0400000065fd02000103413a")); }
fn after_values_query(ctx) { reservation_query(ctx); }
// A new session must read the times back before writing them.
fn on_capabilities(ctx) { for key in ["t858", "t859", "res_pending"] { ctx.state_remove(key); } }

fn u32le(b, at) { b[at].to_int() | (b[at + 1].to_int() << 8) | (b[at + 2].to_int() << 16) | (b[at + 3].to_int() << 24) }

fn publish_time(ctx, tag, v) {
    let prop = if tag == 0x35a { "start_time" } else { "stop_time" };
    c::put(ctx, tag, v);
    if publishable(ctx, prop, v.to_string()) { il::publish_property(ctx, prop, v.to_string()); }
}

fn crc_ok(data) {
    let n = data.len();
    let body = blob(); for i in 2..(n - 2) { body.push(data[i]); }
    crc16(body) == ((data[n - 2].to_int() << 8) | data[n - 1].to_int())
}

// A private reservation frame (consumed, even when malformed), or false for anything else.
fn reservation_frame(ctx, data) {
    let n = data.len();
    if n < 13 || data[2] != 0x04 || data[3] != 0 || data[4] != 0 || data[5] != 0 { return false; }
    // GET reply: [00 ff 04 00 00 00 87 fd 03 00 0d] 03 start(LE32) stop(LE32) 00 00 00 00 crc16.
    if data[1] == 0xff && data[6] == 0x87 && data[7] == 0xfd && data[8] == 0x03 && data[10] == n - 13 {
        if n - 13 == 13 && data[11] == 0x03 && crc_ok(data) {
            let start = u32le(data, 12);
            let stop = u32le(data, 16);
            if valid_hhmm(start) && valid_hhmm(stop) { publish_time(ctx, 0x35a, start); publish_time(ctx, 0x35b, stop); }
        }
        return true;
    }
    // Command response: 02 = ACK, 03 = NACK, [.. 87 fd 10 00 05 fe] cmd.
    if (data[0] == 0x02 || data[0] == 0x03) && data[6] == 0x87 && data[7] == 0xfd && data[8] == 0x10
        && data[9] == 0 && data[10] == 0x05 && data[11] == 0xfe {
        let pending = ctx.state_get("res_pending");
        if data[12] == 0x03 && pending != () && crc_ok(data) {
            ctx.state_remove("res_pending");
            if data[0] == 0x02 { reservation_query(ctx); }
            else { c::reject(ctx, pending, "the appliance refused the reservation"); }
        }
        return true;
    }
    // Notification after a reservation write: [.. 65 01 04 seq len] TLVs crc16.
    if data[6] == 0x65 && data[7] == 0x01 && data[8] == 0x04 && data[10] == n - 13 {
        if !crc_ok(data) { return true; }
        let tlvs = blob(); for i in 11..(n - 2) { tlvs.push(data[i]); }
        for e in tlv_parse(tlvs) {
            if (e.t == 0x35a || e.t == 0x35b) && valid_hhmm(e.v) { publish_time(ctx, e.t, e.v); }
        }
        return true;
    }
    false
}

fn receive_frame(ctx, data) {
    if reservation_frame(ctx, data) { return (); }
    hum_receive_frame(ctx, data)
}

fn write_reservation(ctx, prop, value) {
    let tag = if prop == "start_time" { 0x35a } else { 0x35b };
    if ctx.state_get("t" + tag) == () { c::reject(ctx, prop, "reservation not read back yet"); return; }
    let v = c::to_number(value).to_int();
    if !valid_hhmm(v) { c::reject(ctx, prop, "not a time of day (HHMM)"); return; }
    let mask = if tag == 0x35a { 1 } else { 2 };
    let frame = blob();
    for b in [0x01, 0x02, 0x04, 0, 0, 0, 0x65, 0xfd, 0x01, 0, 0x09, 0x03] { frame.push(b); }
    for x in [mask, v] { for s in [24, 16, 8, 0] { frame.push((x >> s) & 0xff); } }
    let crc = crc16(frame.extract(2));
    frame.push(crc >> 8); frame.push(crc & 0xff);
    ctx.send_raw(frame);
    ctx.state_set("res_pending", prop);
    reservation_query(ctx);
}
