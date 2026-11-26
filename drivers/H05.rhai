// LG dishwasher H05 (KR): same 32 EC / 0x18-byte records as H11, so it uses H11's driver
// (dishwasher_h11_common). Reads (state, course time, remaining time, door) were checked against
// the LG cloud on one unit; its writes have not been exercised.
import "dishwasher_h11_common";
