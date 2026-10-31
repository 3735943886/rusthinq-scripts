// LG washer-dryer F_V__F___W.B_1QEUK and its alias F_VA_F___W.B__QEUK (FV1413H2BA):
// washer_common's common fields plus the drying mode.
import "washer_common";

fn features() { ["drying_mode"] }

// 14 and 15 are WASH_REFRESHING and REFRESHING.
fn states() {
    let s = base_states();
    s["15"] = "refreshing";
    s
}
