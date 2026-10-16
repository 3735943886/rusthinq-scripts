// LG front-load washer Y_VB_Y___W.B32QEUK (F14R76BSTA), the ezDispense (auto-dosing) sibling of
// Y_V8_Y___W.B32QEUK: the LG cloud decodes both with one parser, so everything but the
// dispenser is inherited. Port of upstream rethink's driver (commit 0e57069). Record offsets
// beyond washer_y8_common's:
//   25 downloaded course in the slot (22 shows it only while selected)
//   32/33 detergent / softener dose level   34/35 ezDispense amounts (ml per 5 kg)
//   36 dispense type   37 0x04 dispenser drawer open
// A programme repeats the reported dose levels and type; left at zero a wash runs undosed.
import "washer_y8_common";
import "aabb_common" as c;
import "table_common" as t;
import "washer_common" as w;
import "il_common" as il;

// The V8 dial plus the dispenser nozzle clean (0x37, from a sweep of the cloud's decoder).
fn courses() {
    #{ "0": "none", "58": "ai_wash", "1": "cotton", "2": "easy_care", "4": "eco_40_60", "5": "duvet",
       "7": "mix", "8": "sportswear", "12": "speed_14", "18": "tub_clean", "27": "wool",
       "32": "delicate", "45": "allergy_spa_steam", "49": "turbo_wash_39", "14": "rinse_spin",
       "23": "spin_only", "9": "silent_wash", "48": "quick_tub_clean", "59": "microplastic_care",
       "55": "dispenser_clean" }
}

fn extra_props() {
    #{
        downloaded_program: #{ type: "select", label: "Downloaded course in the slot", options: t::options(w::smart_courses()) },
        detergent: #{ type: "select", label: "Detergent dose", options: t::options(w::doses()) },
        softener: #{ type: "select", label: "Softener dose", options: t::options(w::doses()) },
        // the range the LG app allows
        ezdispense_detergent: #{ type: "number", rw: true, unit: "ml", min: 9, max: 150, step: 1, label: "ezDispense detergent per 5 kg" },
        ezdispense_softener: #{ type: "number", rw: true, unit: "ml", min: 9, max: 150, step: 1, label: "ezDispense softener per 5 kg" },
        dispenser_drawer: #{ type: "binary", class: "opening", label: "Dispenser drawer open" }
    }
}

fn publish_extra(ctx, s) {
    c::pub_name(ctx, "downloaded_program", t::name(w::smart_courses(), s[25]));
    c::pub_name(ctx, "detergent", t::name(w::doses(), s[32]));
    c::pub_name(ctx, "softener", t::name(w::doses(), s[33]));
    il::publish_property(ctx, "ezdispense_detergent", s[34].to_string());
    il::publish_property(ctx, "ezdispense_softener", s[35].to_string());
    // bit 6 of the same byte pulses while the drawer is open, meaning unknown
    il::publish_property(ctx, "dispenser_drawer", c::bit(s[37], 0x04));
    ctx.state_set("dispense", [s[32], s[33], s[36]]);
}

fn dispense(ctx) { ctx.state_get("dispense") ?? [0, 0, 0] }

// The ezDispense amounts are set on their own: F0 24 <0D detergent | 0E softener> 01 <ml>.
fn set_extra(ctx, prop, value) {
    let parameter = switch prop { "ezdispense_detergent" => 0x0d, "ezdispense_softener" => 0x0e, _ => () };
    if parameter == () { return false; }
    ctx.send_raw(aabb_wrap([0xf0, 0x24, parameter, 0x01, value.parse_float().to_int()]));
    true
}
