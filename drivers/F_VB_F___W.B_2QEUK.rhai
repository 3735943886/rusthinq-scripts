// LG washer-dryer F_VB_F___W.B_2QEUK (CV74J7S2QA): washer_common, with drying mode, Eco Hybrid
// and doses, no soil level.
import "washer_common";

fn features() {
    ["drying_mode", "reserve_time", "extra_rinse", "options", "eco_hybrid", "child_lock", "doses"]
}

// 19 is AUTO_DT_OPEN_PAUSE, which the LG app shows as paused; 15 is REFRESHING (14 is
// WASH_REFRESHING).
fn states() {
    let s = base_states();
    s["15"] = "refreshing";
    s["19"] = "paused";
    s
}
