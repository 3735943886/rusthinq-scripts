// LG WashTower dryer BDH_D39302_KR: Korean domestic unit (deviceType 222).
// Port of the owner's rethink TypeScript driver (washtower_bdh_d39302_kr.ts), itself
// adapted from kjy8850/rethink's washtower.ts. The field table below is kjy's
// BDH_D39301_KR table (DRYER_PROTOCOL_EX 4.1 / DRYER_CONVERT_EX 7.8) carried over in
// full: our TS verified it against this unit's own real extended frames and its LG
// modelJSON (fetched from the running rethink server, 2026-11-04). Enum names are the
// TS driver's labels verbatim; the sibling BDH_D39301_KR.rhai uses snake_case names
// for the same wire codes and exposes only a 17-field subset of this table.
// Protocol, controls and the published surface come from washtower_kr_common.
import "washtower_kr_common";
fn model() {
    #{
        "tag": 52,
        "recordLength": 51,
        "liveRecordLength": 50,
        "deviceName": "LG WashTower Dryer",
        "fields": [
            #{ "key": "protocolVersion", "offset": 0, "length": 1 },
            #{ "key": "dryLevel", "offset": 1, "length": 1, "values": #{ "0": "Off", "1": "Delicate", "2": "Low", "3": "Standard", "4": "Standard+", "5": "Intensive" } },
            #{ "key": "ecoHybrid", "offset": 2, "length": 1, "values": #{ "0": "Off", "1": "Energy", "2": "Auto", "3": "Speed" } },
            #{ "key": "temp", "offset": 3, "length": 1, "values": #{ "0": "No temp set" } },
            #{ "key": "timeDry", "offset": 4, "length": 1, "values": #{ "0": "Off", "1": "20min", "2": "30min", "3": "40min", "4": "50min", "5": "60min", "6": "70min", "7": "80min" } },
            #{ "key": "course", "offset": 5, "length": 1, "values": #{ "0": "None", "1": "Steam Refresh", "2": "Towels", "3": "Jeans", "4": "Bedding", "5": "Shirt", "6": "Mixed garments", "7": "Standard", "8": "Functional garments", "9": "Small Quick", "10": "Delicate Dry", "11": "Wool/Delicate", "12": "Shelf Dry", "13": "Air blow", "14": "Warm air", "15": "Bedding shake", "16": "Steam Sterilize", "17": "Intensive Dry", "18": "Condenser Care", "19": "Tub Sterilize", "20": "Padding Refresh", "21": "Timed Dry", "22": "Outdoor Refresh", "23": "Baby clothes", "24": "Small Dry", "25": "Standard Plus", "26": "Wrinkle Prevent", "27": "Pet Care", "28": "Single shirt", "29": "Heavy soil", "30": "Ultra Delicate", "31": "Kids clothes", "32": "Low-temp Dry", "33": "Large Dry", "34": "Quick Dry", "35": "Air Dry", "36": "Spot clean", "37": "Steam Refresh", "38": "Steam Sterilize", "39": "Refresh", "40": "Garment Refresh", "41": "Mist Refresh", "42": "Intensive Dry", "43": "Low-temp Dry Plus", "44": "AI Dry", "45": "Quiet", "46": "Shrink ease", "47": "Wrinkle Ease", "48": "Thin bedding", "49": "Sportswear", "50": "Rainy-season Dry", "51": "Iron Dry", "52": "Duvet cover", "53": "Blanket warm", "54": "Night Dry", "55": "Half-load Dry", "56": "Full-load Dry", "57": "Room Dehumidify", "58": "Turbo Dry", "114": "Wrinkle Ease Dry", "255": "Downloaded course" } },
            #{ "key": "reserveTimeMinute", "offset": 7, "length": 2 },
            #{ "key": "remainTimeMinute", "offset": 9, "length": 2 },
            #{ "key": "initialTimeMinute", "offset": 11, "length": 2 },
            #{ "key": "state", "offset": 13, "length": 1, "values": #{ "0": "Power off", "1": "On", "2": "Drying", "3": "Pause", "4": "Dry complete", "5": "Error occurred", "6": "Smart diagnosing", "7": "Drying", "8": "Blowing", "9": "Wrinkle preventing", "11": "Detecting weight", "12": "Reserved", "14": "Detecting weight", "15": "Steaming", "16": "Recognizing garment", "17": "Condenser auto-clean running", "18": "Bedding shake running", "19": "Refreshing", "20": "Sterilizing", "21": "Condenser Care running", "22": "Dry complete", "23": "Preparing to dry", "24": "Laundry care running", "25": "Dehumidifying", "26": "Dry complete", "27": "Awaiting completion" } },
            #{ "key": "preState", "offset": 14, "length": 1, "values": #{ "0": "Power off", "1": "On", "2": "Drying", "3": "Pause", "4": "Dry complete", "5": "Error occurred", "6": "Smart diagnosing", "7": "Drying", "8": "Blowing", "9": "Wrinkle preventing", "11": "Detecting weight", "12": "Reserved", "14": "Detecting weight", "15": "Steaming", "16": "Recognizing garment", "17": "Condenser auto-clean running", "18": "Bedding shake running", "19": "Refreshing", "20": "Sterilizing", "21": "Condenser Care running", "22": "Dry complete", "23": "Preparing to dry", "24": "Laundry care running", "25": "Dehumidifying", "26": "Dry complete", "27": "Awaiting completion" } },
            #{ "key": "error", "offset": 15, "length": 1, "values": #{ "0": "No error", "1": "Temp sensor fault 1", "2": "Temp sensor fault 2", "4": "Temp sensor fault 4", "5": "Temp sensor fault 5", "6": "Temp sensor fault 6", "10": "Steam not operating", "11": "Steam water refill", "12": "Steam not operating", "14": "Not draining", "15": "Drain check notice", "16": "Door not closed", "18": "Filter installed", "20": "Drum temp fault", "21": "Compressor fault 1", "22": "Compressor fault 2", "31": "Drum motor fault", "38": "Door not closed", "40": "Fan motor fault", "43": "Door not locked", "49": "IR sensor fault", "50": "Internal fan fault", "52": "Door closed", "53": "Dehumidify kit not detected", "54": "Low-temp detected" } },
            #{ "key": "courseSpendPower", "offset": 17, "length": 2 },
            #{ "key": "buzzer", "offset": 19, "length": 1, "values": #{ "0": "Mute", "1": "Small", "2": "Normal", "3": "Large", "4": "Very large", "15": "On" } },
            #{ "key": "baseDownloadCourseData", "offset": 20, "length": 1, "values": #{ "0": "None", "1": "Steam Refresh", "4": "Bedding", "7": "Standard", "9": "Small Quick", "15": "Bedding shake", "16": "Steam Sterilize", "18": "Condenser Care", "19": "Tub Sterilize", "21": "Timed Dry", "44": "AI Dry" } },
            #{ "key": "loadItem", "offset": 21, "length": 1, "values": #{ "0": "Off", "1": "1Level", "2": "2Level", "3": "3Level", "4": "4Level", "5": "5Level", "6": "6Level" } },
            #{ "key": "ductClogging", "offset": 22, "length": 1 },
            #{ "key": "downloadCourse", "offset": 23, "length": 1, "values": #{ "0": "None", "101": "Baby clothes", "102": "Sportswear", "105": "Rainy-season Dry", "110": "Iron Dry", "114": "Wrinkle Ease Dry", "119": "Outdoor Refresh", "126": "Quiet", "129": "Functional garments", "135": "Towels", "140": "Shelf Dry", "142": "Shrink ease", "143": "Wool/Delicate", "145": "Single shirt", "146": "Shirt", "147": "Air blow", "148": "Intensive Dry", "149": "Padding Refresh" } },
            #{ "key": "handIron", "offset": 24, "length": 1, "bit": 7, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "dampDryBeep", "offset": 24, "length": 1, "bit": 6, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "drumLight", "offset": 24, "length": 1, "bit": 5, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "favorite", "offset": 24, "length": 1, "bit": 4, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "wrinkleCare", "offset": 24, "length": 1, "bit": 3, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "dnnReady", "offset": 24, "length": 1, "bit": 2, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "reduceStatic", "offset": 24, "length": 1, "bit": 1, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "antiBacterial", "offset": 24, "length": 1, "bit": 0, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "energySaver", "offset": 25, "length": 1, "bit": 7, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "energySaverDefault", "offset": 25, "length": 1, "bit": 6, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "turboSteam", "offset": 25, "length": 1, "bit": 5, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "smartGridEnable", "offset": 25, "length": 1, "bit": 4, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "ductSensingOnOff", "offset": 25, "length": 1, "bit": 3, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "steam", "offset": 25, "length": 1, "bit": 2, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "AIDDLed", "offset": 25, "length": 1, "bit": 1, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "smartPairing", "offset": 26, "length": 1, "bit": 7, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "remoteStart", "offset": 26, "length": 1, "bit": 6, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "selfCleaning", "offset": 26, "length": 1, "bit": 5, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "childLock", "offset": 26, "length": 1, "bit": 4, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "reservation", "offset": 26, "length": 1, "bit": 3, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "detectLoad", "offset": 26, "length": 1, "bit": 2, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "standby", "offset": 26, "length": 1, "bit": 1, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "doorLock", "offset": 26, "length": 1, "bit": 0, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "wifiConnected", "offset": 27, "length": 1, "bit": 7, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "wifiSetting", "offset": 27, "length": 1, "bit": 6, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "voiceState", "offset": 27, "length": 1, "bit": 5, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "addItem", "offset": 27, "length": 1, "bit": 4, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "smartCare_onOff", "offset": 27, "length": 1, "bit": 2, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "remoteMaintain", "offset": 27, "length": 1, "bit": 1, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "autoCourseArrange", "offset": 27, "length": 1, "bit": 0, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "currentDateDisplay", "offset": 28, "length": 1, "bit": 7, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "currentDisplay_12_24", "offset": 28, "length": 1, "bit": 6, "bits": 1 },
            #{ "key": "currentTimeDisplay", "offset": 28, "length": 1, "bit": 5, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "laundryCare", "offset": 28, "length": 1, "bit": 4, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "BLEOnOff", "offset": 28, "length": 1, "bit": 3, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "applyLaundryCollection", "offset": 28, "length": 1, "bit": 2, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "applyRemoteMaintain", "offset": 28, "length": 1, "bit": 1, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "applyBuzzer", "offset": 28, "length": 1, "bit": 0, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "setDownloadedCourse", "offset": 29, "length": 1, "values": #{ "0": "None", "101": "Baby clothes", "102": "Sportswear", "105": "Rainy-season Dry", "110": "Iron Dry", "114": "Wrinkle Ease Dry", "119": "Outdoor Refresh", "126": "Quiet", "129": "Functional garments", "135": "Towels", "140": "Shelf Dry", "142": "Shrink ease", "143": "Wool/Delicate", "145": "Single shirt", "146": "Shirt", "147": "Air blow", "148": "Intensive Dry", "149": "Padding Refresh" } },
            #{ "key": "masterCard", "offset": 30, "length": 1 },
            #{ "key": "cloudCourse", "offset": 31, "length": 1, "values": #{ "0": "None", "101": "Baby clothes", "102": "Sportswear", "105": "Rainy-season Dry", "110": "Iron Dry", "114": "Wrinkle Ease Dry", "119": "Outdoor Refresh", "126": "Quiet", "129": "Functional garments", "135": "Towels", "140": "Shelf Dry", "142": "Shrink ease", "143": "Wool/Delicate", "145": "Single shirt", "146": "Shirt", "147": "Air blow", "148": "Intensive Dry", "149": "Padding Refresh" } },
            #{ "key": "endMelody", "offset": 32, "length": 1, "values": #{ "0": "Default sound", "1": "Vivaldi Winter" } },
            #{ "key": "initLCD", "offset": 33, "length": 1 },
            #{ "key": "drylevelSubDamp", "offset": 34, "length": 1, "values": #{ "0": "Default", "2": "High" } },
            #{ "key": "drylevelSubLess", "offset": 35, "length": 1, "values": #{ "0": "Default", "1": "Low", "2": "High" } },
            #{ "key": "drylevelSubIron", "offset": 36, "length": 1, "values": #{ "0": "Default", "1": "Low", "2": "High" } },
            #{ "key": "drylevelSubCup", "offset": 37, "length": 1, "values": #{ "0": "Default", "1": "Low", "2": "High" } },
            #{ "key": "drylevelSubVery", "offset": 38, "length": 1, "values": #{ "0": "Default", "1": "Low" } },
            #{ "key": "moreLessTime", "offset": 39, "length": 2 },
            #{ "key": "applyExtendedIcontrol", "offset": 41, "length": 1, "bit": 6, "bits": 1 },
            #{ "key": "ushLaundryCareSettingOnOff", "offset": 41, "length": 1, "bit": 5, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "drumlightOpt", "offset": 41, "length": 1, "bit": 4, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "drumlightAutoOn", "offset": 41, "length": 1, "bit": 3, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "noti3MinEnd", "offset": 41, "length": 1, "bit": 2, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "endReserveTime", "offset": 41, "length": 1, "bit": 0, "bits": 1, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "drumlightBright", "offset": 42, "length": 2 },
            #{ "key": "drumlightOnTime", "offset": 44, "length": 2 },
            #{ "key": "laundryCareSettingTime", "offset": 46, "length": 2 },
            #{ "key": "drumlightPreview", "offset": 48, "length": 2, "values": #{ "0": "Off", "1": "On" } },
            #{ "key": "energySavingAvailable", "offset": 50, "length": 1, "bit": 0, "bits": 1 },
            #{ "key": "energySavingEnabled", "offset": 50, "length": 1, "bit": 1, "bits": 1 },
            #{ "key": "energySavingRunning", "offset": 50, "length": 1, "bit": 2, "bits": 1 },
            #{ "key": "endMelodyOnOff", "offset": 50, "length": 1, "bit": 3, "bits": 1 },
            #{ "key": "laundryCollectionPushSetting", "offset": 50, "length": 1, "bit": 4, "bits": 1 },
            #{ "key": "childSafetyModeOnOff", "offset": 50, "length": 1, "bit": 5, "bits": 1 },
            #{ "key": "smartReadyOnOff", "offset": 50, "length": 1, "bit": 6, "bits": 1 }
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
