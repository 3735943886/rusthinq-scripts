import "runtime_test" as runtime;
import "tlv_test" as t;

// Tests of AIR_2C0001_WW (air purifier, KR) on air_910604_common. Both frames are real captures
// from one unit's reconnect (2026-11-26, rusthinqctl capture --cloud): the capability frame and
// the first state frame. The LG cloud report of the same moment had operation 0, windStrength 8,
// quality PM1 4 / PM2 5 / PM10 6, overall 1, odor 1, filter useTime 89 / useTimeTop 93 of 100.

fn caps() { "000004000000A70201E68EB01018B060E000526001009670BE0000B0A001D4B300B340B4E05000B5B0010004B55090B6A05813B6E05439B700B770D8019FBC701C02C1B3C0B42001D4B441BD206004BD7002CC9FD3C1D401CA40B7E00602B25020704164006450406C80DD00FA01FB0BF840795010BC202000EA20100051D03FB5D061B600B648B5CDB600B648B5CFB600B648B5CEB600B648774B" }
fn values() { "000004000000A70204E8AA7DC07E4D7E887F007F807F40868086C087008980D7C0D800A88158409380CD46CD05CCC490419001CD901E8840D55059D59064D8D05DD91064CE80AB00C988C9C0E000CA00F14087D0A07CC1ED40700083406946EE405A815AC15B0147815B8147C15CF0610D0F5D300EFFFF5EB0FFFFFF688069008B903C8F41E800B5D061B600B648B5CDB600B648B5CFB600B648B5CEB600B648FA805030AC67EA5040508050E001016242E480CDC1FD7F" }

fn running() { t::running(device(), caps(), values()) }

fn test_the_captured_state_matches_the_cloud() {
    let d = running();
    expect_props(d, #{
        available: "true", power: "false", fan: "auto",
        pm1: "4", "pm2.5": "5", pm10: "6", air_quality: "1", odor: "1",
        filter_life: "89", top_filter_life: "93", error: "0"
    });
    expect_eq(d.script_error(), ());
}
