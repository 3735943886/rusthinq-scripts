// LG washer WTWN3 (F4J7TN1W, 8 kg, TITAN2 platform), ThinQ1: washer_t1_common without the dryer,
// with the soil level, rinse, delay start, option bits, child lock and standby. Offsets and codes
// from LG's modelJson for WTWN3, as upstream rethink's WTWN3.ts; upstream confirmed power, state,
// door lock and the tub clean counter on a real F4J7TN1W.
import "washer_t1_common";

fn features() { ["soil", "rinse", "reserve_time", "options", "child_lock", "standby"] }

// Course (byte 5) and downloaded courses (byte 20) share one label space.
fn courses() {
    #{ "1": "cotton", "2": "easy_care", "4": "cotton_plus", "5": "duvet", "6": "stain_care",
       "7": "mix", "8": "sportswear", "9": "silent_wash", "11": "gentle_care", "12": "speed_14",
       "18": "tub_clean", "32": "delicate", "44": "baby_steam_care", "45": "allergy_spa_steam",
       "52": "kids_wear", "53": "school_uniform", "54": "swimming_wear", "55": "rainy_season",
       "56": "gym_clothes", "57": "jeans", "58": "blanket", "59": "sweat_stain",
       "62": "single_garment", "63": "colour_protection", "64": "noise_minimize", "73": "small_load",
       "74": "lingerie", "75": "wool", "77": "cold_wash", "100": "rinse_spin",
       "101": "lightly_soiled_items", "102": "minimize_detergent_residue", "103": "one_hour_wash",
       "107": "sleeve_hems_collars", "108": "juice_food_stains", "111": "minimize_wrinkles" }
}
