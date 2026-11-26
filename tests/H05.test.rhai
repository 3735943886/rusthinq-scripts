import "runtime_test" as runtime;
import "aabb_test" as a;

// Tests of H05 (dishwasher) on dishwasher_h11_common. The EC frame is a real capture from one
// unit (2026-11-25 20:54 KST, rusthinqctl capture) taken mid-cycle; the LG cloud reported
// rinsing, total time 152 min, about 121 min remaining and the door closed at the time.

fn ec() { "AA6232EC001802030002201201020100001008020059566200E20818000808050D00080103CE003E0103CE003E0103CE003E001802030002201201020000001008020059566200E20818000808050D00080103CE003E0103CE003E0103CE003EB4BB" }

fn test_the_captured_ec_matches_the_cloud() {
    let d = device();
    d.feed(ec());
    expect_props(d, #{
        available: "true",
        status: "running",
        process: "rinsing",
        initial_time: "152",
        remaining_time: "120",
        door: "false"
    });
    expect_eq(d.script_error(), ());
}
