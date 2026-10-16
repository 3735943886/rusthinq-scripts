// Shared by the AABB (`AA len .. checksum BB`) device drivers: `import "aabb_common" as c;`.
// A module cannot call back into its importer, so each device script keeps its hooks and
// its tables and delegates the plain helpers here. AABB appliances report on their own, so
// there is no handshake to share, only framing and value helpers.

// The inner body of an `AA..BB` frame whose first byte is `first`, or `()` for anything else
// (a frame of another kind, an unframed buffer). The checksum is not validated, as elsewhere.
import "il_common" as il;

fn inner(data, first) {
    let body = aabb_unwrap(data);
    if body == () || body.len() < 2 || body[0] != first { return (); }
    body
}

// Offset of the current fixed-length status record in an already unwrapped body.
// EB carries one record; EC carries the previous record followed by the current one.
// Exact lengths keep unrelated, truncated and extended formats out of this helper.
fn common_status_offset(body, status_length) {
    if body == () || body.len() < 2 || status_length <= 0 { return (); }
    if body[1] == 0xeb && body.len() == 2 + status_length { return 2; }
    if body[1] == 0xec && body.len() == 2 + status_length * 2 {
        return 2 + status_length;
    }
    ()
}

// The current record of an enveloped status frame, or `()` for anything else. Some appliances
// wrap their EB/EC records in an envelope (upstream aabb_device.ts, processEnvelopedStatus):
//   <class> 0A <len16> <seq16> .. .. .. <EB|EC> <records len16> <records>
// An AA FF frame's 16-bit checksum leaves one byte after the records; any other excess means
// the layout is not what it seems.
fn enveloped_status(data, class, status_length) {
    let body = inner(data, class);
    if body == () || body.len() < 13 || body[1] != 0x0a { return (); }
    let n = body[11] * 256 + body[12];
    let trailing = body.len() - 13 - n;
    if trailing != 0 && trailing != 1 { return (); }
    if body[10] == 0xeb && n == status_length { return body.extract(13, status_length); }
    if body[10] == 0xec && n == 2 * status_length { return body.extract(13 + status_length, status_length); }
    ()
}

// Acks a received frame as the LG cloud does (upstream aabb_device.ts), for drivers whose
// appliance repeats unacked frames: F0 00 <type> 04, plus the sequence number for an
// envelope (0x0A). The appliance's own acks (0x00), 0xC3 heartbeats and plain EB/EC status
// records are not acked.
fn ack(ctx, data) {
    let body = aabb_unwrap(data);
    if body == () || body.len() < 2 { return; }
    let t = body[1];
    if t == 0x00 || t == 0xc3 || t == 0xeb || t == 0xec { return; }
    let msg = [0xf0, 0x00, t, 0x04];
    if t == 0x0a {
        // AA FF frames carry a 16-bit checksum, which leaves one byte at the end of the body.
        if body.len() - (if data[1] == 0xff { 1 } else { 0 }) < 13 { return; }
        msg.push(body[5]);
        msg.push(body[6]);
    }
    ctx.send_clip("ack", 1, "\"" + hex_encode_upper(aabb_wrap(msg)) + "\"");
}

fn pad2(n) { if n < 10 { "0" + n } else { n.to_string() } }

// Publish `name` unless it is `()` (a wire code the table does not know is left unpublished
// rather than published as a made-up value).
fn pub_name(ctx, prop, name) {
    if name != () { il::publish_property(ctx, prop, name); }
}

// A binary property from a wire number that is 1 when on.
fn on_off(v) { if v == 1 { "true" } else { "false" } }

// A binary property from a bit of a flags byte.
fn bit(v, mask) { if (v & mask) != 0 { "true" } else { "false" } }

fn to_bool(text) {
    let t = text.to_lower();
    t == "true" || t == "on" || t == "1"
}

// A number from text, or `()` if it is not one.
fn to_number(text) {
    try { text.parse_float() } catch { () }
}

fn reject(ctx, prop, reason) {
    il::publish_event(ctx, "reject", json_stringify(#{ prop: prop, reason: reason }));
}
