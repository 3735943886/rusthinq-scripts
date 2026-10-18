// Korean WashTower: anszom/rethink PR #117, 3b1942c1411931f5e007b0d86e8bb38e06be2018.
// Fixtures and controls: tests/cloud/devices/washtower.test.ts.
import "washtower_kr_common";
fn model() {
    #{
        "tag": 52,
        "recordLength": 51,
        "liveRecordLength": 50,
        "deviceName": "LG WashTower Dryer",
        "fields": [
            #{
                "key": "dryLevel",
                "offset": 1,
                "length": 1,
                "values": #{ "0": "off", "1": "delicate", "2": "low", "3": "standard", "4": "standard_plus", "5": "intensive" }
            },
            #{
                "key": "ecoHybrid",
                "offset": 2,
                "length": 1,
                "values": #{ "0": "off", "1": "energy", "2": "auto", "3": "speed" }
            },
            #{
                "key": "course",
                "offset": 5,
                "length": 1,
                "values": #{
                    "0": "none",
                    "1": "steam_refresh",
                    "2": "towels",
                    "3": "jeans",
                    "4": "bedding",
                    "5": "shirt",
                    "6": "mixed_garments",
                    "7": "standard",
                    "8": "functional_garments",
                    "9": "small_quick",
                    "10": "delicate_dry",
                    "11": "wool_delicate",
                    "12": "shelf_dry",
                    "13": "air_blow",
                    "14": "warm_air",
                    "15": "bedding_shake",
                    "16": "steam_sterilize",
                    "17": "intensive_dry",
                    "18": "condenser_care",
                    "19": "tub_sterilize",
                    "20": "padding_refresh",
                    "21": "timed_dry",
                    "22": "outdoor_refresh",
                    "23": "baby_clothes",
                    "24": "small_dry",
                    "25": "standard_plus",
                    "26": "wrinkle_prevent",
                    "27": "pet_care",
                    "28": "single_shirt",
                    "29": "heavy_soil",
                    "30": "ultra_delicate",
                    "31": "kids_clothes",
                    "32": "low_temp_dry",
                    "33": "large_dry",
                    "34": "quick_dry",
                    "35": "air_dry",
                    "36": "spot_clean",
                    "37": "steam_refresh",
                    "38": "steam_sterilize",
                    "39": "refresh",
                    "40": "garment_refresh",
                    "41": "mist_refresh",
                    "42": "intensive_dry",
                    "43": "low_temp_dry_plus",
                    "44": "ai_dry",
                    "45": "quiet",
                    "46": "shrink_ease",
                    "47": "wrinkle_ease",
                    "48": "thin_bedding",
                    "49": "sportswear",
                    "50": "rainy_season_dry",
                    "51": "iron_dry",
                    "52": "duvet_cover",
                    "53": "blanket_warm",
                    "54": "night_dry",
                    "55": "half_load_dry",
                    "56": "full_load_dry",
                    "57": "room_dehumidify",
                    "58": "turbo_dry",
                    "114": "wrinkle_ease_dry",
                    "255": "downloaded_course"
                }
            },
            #{ "key": "reserveTimeMinute", "offset": 7, "length": 2 },
            #{ "key": "remainTimeMinute", "offset": 9, "length": 2 },
            #{ "key": "initialTimeMinute", "offset": 11, "length": 2 },
            #{
                "key": "state",
                "offset": 13,
                "length": 1,
                "values": #{
                    "0": "power_off",
                    "1": "on",
                    "2": "drying",
                    "3": "pause",
                    "4": "dry_complete",
                    "5": "error_occurred",
                    "6": "smart_diagnosing",
                    "7": "drying",
                    "8": "blowing",
                    "9": "wrinkle_preventing",
                    "11": "detecting_weight",
                    "12": "reserved",
                    "14": "detecting_weight",
                    "15": "steaming",
                    "16": "recognizing_garment",
                    "17": "condenser_auto_clean_running",
                    "18": "bedding_shake_running",
                    "19": "refreshing",
                    "20": "sterilizing",
                    "21": "condenser_care_running",
                    "22": "dry_complete",
                    "23": "preparing_to_dry",
                    "24": "laundry_care_running",
                    "25": "dehumidifying",
                    "26": "dry_complete",
                    "27": "awaiting_completion"
                }
            },
            #{
                "key": "error",
                "offset": 15,
                "length": 1,
                "values": #{
                    "0": "no_error",
                    "1": "temp_sensor_fault_1",
                    "2": "temp_sensor_fault_2",
                    "4": "temp_sensor_fault_4",
                    "5": "temp_sensor_fault_5",
                    "6": "temp_sensor_fault_6",
                    "10": "steam_not_operating",
                    "11": "steam_water_refill",
                    "12": "steam_not_operating",
                    "14": "not_draining",
                    "15": "drain_check_notice",
                    "16": "door_not_closed",
                    "18": "filter_installed",
                    "20": "drum_temp_fault",
                    "21": "compressor_fault_1",
                    "22": "compressor_fault_2",
                    "31": "drum_motor_fault",
                    "38": "door_not_closed",
                    "40": "fan_motor_fault",
                    "43": "door_not_locked",
                    "49": "ir_sensor_fault",
                    "50": "internal_fan_fault",
                    "52": "door_closed",
                    "53": "dehumidify_kit_not_detected",
                    "54": "low_temp_detected"
                }
            },
            #{
                "key": "baseDownloadCourseData",
                "offset": 20,
                "length": 1,
                "values": #{
                    "0": "none",
                    "1": "steam_refresh",
                    "4": "bedding",
                    "7": "standard",
                    "9": "small_quick",
                    "15": "bedding_shake",
                    "16": "steam_sterilize",
                    "18": "condenser_care",
                    "19": "tub_sterilize",
                    "21": "timed_dry",
                    "44": "ai_dry"
                }
            },
            #{
                "key": "downloadCourse",
                "offset": 23,
                "length": 1,
                "values": #{
                    "0": "none",
                    "101": "baby_clothes",
                    "102": "sportswear",
                    "105": "rainy_season_dry",
                    "110": "iron_dry",
                    "114": "wrinkle_ease_dry",
                    "119": "outdoor_refresh",
                    "126": "quiet",
                    "129": "functional_garments",
                    "135": "towels",
                    "140": "shelf_dry",
                    "142": "shrink_ease",
                    "143": "wool_delicate",
                    "145": "single_shirt",
                    "146": "shirt",
                    "147": "air_blow",
                    "148": "intensive_dry",
                    "149": "padding_refresh"
                }
            },
            #{
                "key": "wrinkleCare",
                "offset": 24,
                "length": 1,
                "bit": 3,
                "bits": 1,
                "values": #{ "0": "off", "1": "on" }
            },
            #{
                "key": "steam",
                "offset": 25,
                "length": 1,
                "bit": 2,
                "bits": 1,
                "values": #{ "0": "off", "1": "on" }
            },
            #{
                "key": "remoteStart",
                "offset": 26,
                "length": 1,
                "bit": 6,
                "bits": 1,
                "values": #{ "0": "off", "1": "on" }
            },
            #{
                "key": "childLock",
                "offset": 26,
                "length": 1,
                "bit": 4,
                "bits": 1,
                "values": #{ "0": "off", "1": "on" }
            },
            #{
                "key": "doorLock",
                "offset": 26,
                "length": 1,
                "bit": 0,
                "bits": 1,
                "values": #{ "0": "off", "1": "on" }
            },
            #{
                "key": "remoteMaintain",
                "offset": 27,
                "length": 1,
                "bit": 1,
                "bits": 1,
                "values": #{ "0": "off", "1": "on" }
            },
            #{ "key": "moreLessTime", "offset": 39, "length": 2 }
        ]
    }
}
fn settings() { ["course", "ecoHybrid", "wrinkleCare", "steam", "dryLevel"] }
fn rules() {
    #{
        "1": #{ "ecoHybrid": [3], "dryLevel": [0], "steam": [1], "wrinkleCare": [0, [0, 1]], "moreLessTime": [0] },
        "4": #{ "ecoHybrid": [2], "dryLevel": [0], "steam": [0], "wrinkleCare": [0, [0, 1]], "moreLessTime": [0] },
        "7": #{
            "ecoHybrid": [2, [1, 2, 3]],
            "dryLevel": [3, [1, 2, 3, 4, 5]],
            "steam": [0, [0, 1]],
            "wrinkleCare": [0, [0, 1]],
            "moreLessTime": [0]
        },
        "9": #{ "ecoHybrid": [3], "dryLevel": [0], "steam": [0], "wrinkleCare": [0, [0, 1]], "moreLessTime": [0] },
        "15": #{
            "ecoHybrid": [2],
            "dryLevel": [0],
            "steam": [0, [0, 1]],
            "wrinkleCare": [0, [0, 1]],
            "moreLessTime": [0]
        },
        "16": #{
            "ecoHybrid": [3],
            "dryLevel": [0],
            "steam": [1, [0, 1]],
            "wrinkleCare": [0, [0, 1]],
            "moreLessTime": [0]
        },
        "18": #{ "ecoHybrid": [3], "dryLevel": [0], "steam": [0], "wrinkleCare": [0], "moreLessTime": [0] },
        "19": #{ "ecoHybrid": [3], "dryLevel": [0], "steam": [1], "wrinkleCare": [0], "moreLessTime": [0] },
        "21": #{ "ecoHybrid": [2], "dryLevel": [0], "steam": [0], "wrinkleCare": [0, [0, 1]], "moreLessTime": [30] },
        "44": #{ "ecoHybrid": [2], "dryLevel": [0], "steam": [0], "wrinkleCare": [0, [0, 1]], "moreLessTime": [0] }
    }
}
