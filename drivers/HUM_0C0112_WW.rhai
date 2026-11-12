// LG humidifying air purifier HUM_0C0112_WW (the "MAX"): hum_common. Its fields and enums match
// HUM_056905_WW's; its capability reply adds the AI (108) and cozy (109) humidify modes and the
// aurora, bonfire and ripples mood colours. Behavior follows a private rethink fork driver running
// on an installed unit; the tests replay live capability/value captures from 2026-11-10.
//
// Reservations are not available: the appliance answers HUM_056905_WW's private-command GET with
// zeros but NACKs its SET, and LG's separate advanced schedule has no wire evidence. The descriptor
// has no start_time/stop_time and 0x35a/0x35b are never published. For a timed start or stop, use a
// Home Assistant time automation on `power`.
import "hum_common";
