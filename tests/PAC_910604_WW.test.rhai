import "runtime_test" as runtime;
// BEGIN PR VECTORS
// Regression vectors from rethink PR #170 (7109e55b741593f7ff0e411c38d28cf795a2cbe8).
// Original test names are retained below. Expected TX bytes come from executing the TS driver.

// discovery is immediate and a delta-first connection publishes state
fn test_pr_170_1() {
    let d = device();
    d.feed("000004000000a702047b0f92c17e417f90307ea00202d201c48d320c");
    expect_props(d, #{"mode": "dry", "target": "24", "fan": "low"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// constructor and start() send nothing (never polled)
fn test_pr_170_2() {
    let d = device();
    d.start();
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// base frame publishes config: command topics only on controls
fn test_pr_170_3() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// base frame publishes expected state
fn test_pr_170_4() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// air quality grade decodes and is read-only
fn test_pr_170_5() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204f80d9004ccd01dcd106ecd5091c48bfb58");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "very_bad", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "29", "pm25": "110", "pm10": "145", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("air_quality", "good");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "very_bad", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "29", "pm25": "110", "pm10": "145", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// power-off frame reports off
fn test_pr_170_6() {
    let d = device();
    d.feed("000004000000a70204448491009283918091c09300a300a3407dc07e407f90247ea006067f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409000d20089408840acc08e808e408e0090c0ccc0cd00cd40cd9039d5a002d0d54ccdc0c8c08f808fc08f40ab40ab00d1009780c49081a551");
    expect_props(d, #{"power": "false", "target": "18", "fan": "high", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "dry_remain": "0", "error": "0", "power_draw": "0", "pm1": "0", "pm25": "0", "pm10": "0", "humidity": "57", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// fan levels decode (low/auto/turbo/max)
fn test_pr_170_7() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702047b0f92c17e417f90307ea00202d201c48d320c");
    expect_props(d, #{"power": "true", "mode": "dry", "target": "24", "fan": "low", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204520c92c27ea0080882018180c48a1d97");
    expect_props(d, #{"power": "true", "mode": "dry", "target": "24", "fan": "auto", "temperature": "25", "human_sense": "direct", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204cd1492c27f90247ea0070781a001018d81cd48c490118313");
    expect_props(d, #{"power": "true", "mode": "dry", "target": "18", "fan": "turbo", "temperature": "25", "human_sense": "direct", "swing_v": "off", "swing_h": "both", "wind_mode": "coolpower", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "8", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204d20e92c27ea00909818082418d80c48c1be5");
    expect_props(d, #{"power": "true", "mode": "dry", "target": "18", "fan": "max", "temperature": "25", "human_sense": "direct", "swing_v": "off", "swing_h": "off", "wind_mode": "longpower", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "8", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// eco override flag still reads the fan level
fn test_pr_170_8() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702045f0d92c27f90347ea0ff048341c48b622a");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "true", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702049c0a92c27ea004ff8341c4881a00");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "true", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// swing states decode onto the climate entity
fn test_pr_170_9() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204b50692c18141c484d7fc");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "on", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702041a0892c281a00100c486d0a6");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "on", "swing_h": "left", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702042e0692c28181c4840943");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "on", "swing_h": "right", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204f70892c281a00101c486c08e");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "on", "swing_h": "both", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702041e0692c28180c48478af");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "on", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// human sense states decode
fn test_pr_170_10() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204520c92c27ea0080882018180c48a1d97");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "auto", "temperature": "25", "human_sense": "direct", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204660692c28202c484189f");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "auto", "temperature": "25", "human_sense": "indirect", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// function toggles decode
fn test_pr_170_11() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702043f0c92c283418c90298cd05ac48aa44b");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "true", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204150692c283c1c48469f5");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "true", "autodry": "true", "airclean": "true", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204740a92c2cd4b8fe01000c48839f2");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "true", "autodry": "true", "airclean": "true", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "11", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204b01492c17f90247ea0070781a0010182408d81c49011475a");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "18", "fan": "turbo", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "both", "wind_mode": "coolpower", "eco": "true", "autodry": "true", "airclean": "true", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "11", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "true"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// smart care tags decode (delta-only tags)
fn test_pr_170_12() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204a91492c27f90327ea0080881a001018f819782c4901142d5");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "25", "fan": "auto", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "both", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "true", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204b80e92c27ea0040481808f809780c48cf29b");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "25", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// timer sensors decode (minutes)
fn test_pr_170_13() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204a70892c286a0012cc4862ad4");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "300", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204e205895019c4839773");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "300", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "25", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// timer numbers decode minutes (sleep/reservations)
fn test_pr_170_14() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204630e92c18140818086a001a48f40c48cf807");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "420", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702043f0792c187103cc485187b");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "420", "stop_timer": "0", "start_timer": "60", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204500892c186e005a0c48640bb");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "420", "stop_timer": "1440", "start_timer": "60", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// wind mode derives from both power tags
fn test_pr_170_15() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204b01492c17f90247ea0070781a0010182408d81c49011475a");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "18", "fan": "turbo", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "both", "wind_mode": "coolpower", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204d20e92c27ea00909818082418d80c48c1be5");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "18", "fan": "max", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "longpower", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// switch writes reproduce the captured app frames
fn test_pr_170_16() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("airclean", "true");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "010104000000650201010283c12599");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("airclean", "false");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[1]), "010104000000650201010283c035b8");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// switch writes reproduce the captured app frames
fn test_pr_170_17() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("eco", "true");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020101028341b411");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("eco", "false");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[1]), "01010400000065020101028340a430");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// switch writes reproduce the captured app frames
fn test_pr_170_18() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("smartcare", "true");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020101028f812830");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("smartcare", "false");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[1]), "01010400000065020101028f803811");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
}

// human sense select writes reproduce the captured app frames
fn test_pr_170_19() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("human_sense", "direct");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020101028201cfe4");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("human_sense", "indirect");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[1]), "01010400000065020101028202ff87");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("human_sense", "off");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[2]), "01010400000065020101028200dfc5");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// timer number writes reproduce the captured app frames
fn test_pr_170_20() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("sleep_timer", "420");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "010104000000650201010486a001a4f047");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("sleep_timer", "0");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[1]), "010104000000650201010286808289");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("start_timer", "60");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[2]), "010104000000650201010387103c967a");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("start_timer", "0");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[3]), "010104000000650201010287002030");
    expect_eq(d.sent().len(), 4);
    expect_eq(d.script_error(), ());
    d.set("stop_timer", "1440");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[4]), "010104000000650201010486e005a061aa");
    expect_eq(d.sent().len(), 5);
    expect_eq(d.script_error(), ());
    d.set("stop_timer", "0");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[5]), "010104000000650201010286c0ca4d");
    expect_eq(d.sent().len(), 6);
    expect_eq(d.script_error(), ());
}

// wind mode writes reproduce the captured app frames
fn test_pr_170_21() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("wind_mode", "coolpower");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020101028d814e52");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("wind_mode", "longpower");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[1]), "01010400000065020101097e407ea009097f90340c54");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("wind_mode", "off");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[2]), "01010400000065020101097e407ea006067f9034bd43");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// climate writes reproduce the frames the app itself sent
fn test_pr_170_22() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("mode", "cool");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "010104000000650201010b7e407dc17ea004047f9034f441");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// climate writes reproduce the frames the app itself sent
fn test_pr_170_23() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("fan", "high");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "010104000000650201010b7ea006067dc17e407f90340534");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// climate writes reproduce the frames the app itself sent
fn test_pr_170_24() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("mode", "dry");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "010104000000650201010b7e417dc17ea004047f90349b04");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("fan", "low");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[1]), "010104000000650201010b7ea002027dc17e417f9034e002");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("target", "24");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[2]), "01010400000065020101097f90307e417ea002027b45");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
}

// power on restores mode, fan and setpoint in one frame; off sends power alone
fn test_pr_170_25() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("fan", "high");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "010104000000650201010b7ea006067dc17e407f90340534");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
    d.set("target", "18");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[1]), "01010400000065020101097f90247e407ea00606abe9");
    expect_eq(d.sent().len(), 2);
    expect_eq(d.script_error(), ());
    d.set("power", "true");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[2]), "010104000000650201010b7dc17e407ea006067f90242b06");
    expect_eq(d.sent().len(), 3);
    expect_eq(d.script_error(), ());
    d.set("power", "false");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[3]), "01010400000065020101027dc00576");
    expect_eq(d.sent().len(), 4);
    expect_eq(d.script_error(), ());
}

// HA's 'off' climate mode powers the unit down instead of writing a wire mode
fn test_pr_170_26() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("power", "false");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020101027dc00576");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// swing writes reproduce the captured vertical frame; horizontal writes echo the driven states
fn test_pr_170_27() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("swing_v", "on");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "01010400000065020101028141d273");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// swing writes reproduce the captured vertical frame; horizontal writes echo the driven states
fn test_pr_170_28() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("swing_h", "left");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "010104000000650201010481a001005404");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// swing writes reproduce the captured vertical frame; horizontal writes echo the driven states
fn test_pr_170_29() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("swing_h", "off");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "010104000000650201010281801b1e");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// swing writes reproduce the captured vertical frame; horizontal writes echo the driven states
fn test_pr_170_30() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("swing_h", "right");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "010104000000650201010281810b3f");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// swing writes reproduce the captured vertical frame; horizontal writes echo the driven states
fn test_pr_170_31() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("swing_h", "both");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(hex_encode(d.sent()[0]), "010104000000650201010481a001014425");
    expect_eq(d.sent().len(), 1);
    expect_eq(d.script_error(), ());
}

// power draw is published in watts and reads zero while off
fn test_pr_170_32() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702040004ace0024260bf");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "578", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702040002acc06075");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "0", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// auto-dry enable state round trips on the owner-captured frames
fn test_pr_170_33() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204c80492c28380647f");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "false", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204df0692c28381c484ee75");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// filter counters expose used, rated and remaining hours
fn test_pr_170_34() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702040004d56001683a9c");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "360", "filter_life_time": "720", "filter_remaining": "360", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702040002d5809a70");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "360", "filter_life_time": "720", "filter_remaining": "360", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702040004d5600190548b");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "360", "filter_life_time": "720", "filter_remaining": "360", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a702040003d590640b16");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "400", "filter_life_time": "100", "filter_remaining": "0", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// sensor writes still send nothing
fn test_pr_170_35() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("pm1", "10");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.set("humidity", "50");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// appliance status is diagnostic; controls and room readings stay primary
fn test_pr_170_36() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// malformed frames are ignored
fn test_pr_170_37() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204f48591009280");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("000004000000a70204ff8591009280918091c09300a300a3407dc17e407f90347ea004047f503282008140818080808080c082408d8082c083008340838183c0");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
    d.feed("00010203");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

// climate swing and human sense options match the published contract
fn test_pr_170_38() {
    let d = device();
    d.feed("000004000000a70204f48591009280918091c09300a300a3407dc17e407f90347ea004047f5032820081408180808080c082408d8082c083008340838183c09080868086c087009f4087c38780938193c094029440948090409001d20089408840acd0208e808e408e0090c0ccc8cd08cd4acd903ed5a002d0d54ccdc1c8c08f808fc08f41ab40ab00d1009780c4908241ad");
    expect_props(d, #{"power": "true", "mode": "cool", "target": "26", "fan": "medium", "temperature": "25", "human_sense": "off", "swing_v": "off", "swing_h": "off", "wind_mode": "off", "eco": "false", "autodry": "true", "airclean": "false", "sleep_timer": "0", "stop_timer": "0", "start_timer": "0", "air_quality": "good", "dry_remain": "0", "error": "0", "power_draw": "32", "pm1": "8", "pm25": "8", "pm10": "10", "humidity": "62", "filter_used_time": "12", "filter_life_time": "720", "filter_remaining": "708", "smartcare": "false", "smartguide": "false"});
    expect_eq(d.sent().len(), 0);
    expect_eq(d.script_error(), ());
}

fn test_passive_driver_has_complete_climate_descriptor() {
 let d=device();d.start();let doc=runtime::descriptor(d);
 expect_eq(doc.kind,"climate");expect_eq(doc.props.target.role,"target_temperature");
 expect_eq(doc.props.target.min,18);expect_eq(doc.props.target.max,30);
 expect_eq(doc.props.power_draw["class"],"power");expect_eq(doc.props.humidity.unit,"%");
 expect_eq(doc.props.wind_mode.options,["off","coolpower","longpower"]);
 expect_eq(d.timers(),[]);expect_eq(d.sent().len(),0);expect_eq(d.script_error(),());
}
