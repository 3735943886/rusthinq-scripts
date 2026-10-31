// LG front-load washer F_VB_Y___W.B_2QEUK (F4WV710ATR): washer_common, with detergent and
// softener doses, no child lock, and the cloud's acks.
import "washer_common";

fn features() { ["soil", "reserve_time", "extra_rinse", "options", "doses"] }

fn acked() { true }

// 19 is AUTO_DT_OPEN_PAUSE, which the LG app shows as paused.
fn states() {
    let s = base_states();
    s["19"] = "paused";
    s
}
