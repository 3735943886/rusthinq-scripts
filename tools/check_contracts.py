#!/usr/bin/env python3
"""Run repository-wide contracts with the production host, without editing sources."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

PUBLISH_PROPERTY = "fn publish_property(ctx, prop, value) {\n"
# il.md V-3, added to a temporary il_common only: any frame a model test feeds fails on a value
# the current descriptor does not offer. Production keeps publishing without this check.
SELECT_VALUE_CHECK = """    let __descriptor = ctx.state_get("__il_descriptor");
    if __descriptor != () && __descriptor.props != () {
        let __def = __descriptor.props[prop];
        if __def != () && __def.type == "select" && __def.options != () && !__def.options.contains(value) {
            throw "il.md V-3: " + prop + " = '" + value + "' is not in options";
        }
    }
"""


def copy_checkout(root, target):
    # Preserve runtime root overrides, just as the production loader does.
    for directory in ("drivers", "modules", "tests"):
        shutil.copytree(root / directory, target / directory)
    for source in root.glob("*.rhai"):
        shutil.copy2(source, target / source.name)


def run_select_values(root, runner):
    """Run the model tests themselves, with published select values checked against options."""
    with tempfile.TemporaryDirectory(prefix="rusthinq-select-values-") as temporary:
        target = Path(temporary)
        copy_checkout(root, target)
        override = target / "il_common.rhai"
        module = override if override.exists() else target / "modules/il_common.rhai"
        text = module.read_text()
        if PUBLISH_PROPERTY not in text:
            raise SystemExit("il_common.publish_property changed; update SELECT_VALUE_CHECK")
        module.write_text(text.replace(PUBLISH_PROPERTY, PUBLISH_PROPERTY + SELECT_VALUE_CHECK, 1))
        return subprocess.run([str(runner), str(target)], check=False).returncode


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("runner", type=Path, help="rusthinq-script-test executable")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    runner = args.runner.resolve()
    declarations = json.loads((root / "tests/contracts.json").read_text())
    models = {p.stem for p in (root / "drivers").glob("*.rhai")}
    if models != set(declarations):
        raise SystemExit(f"Contract declarations mismatch: missing={models - set(declarations)}, stale={set(declarations) - models}")
    with tempfile.TemporaryDirectory(prefix="rusthinq-contracts-") as temporary:
        target = Path(temporary)
        copy_checkout(root, target)
        for model, declaration in declarations.items():
            contract = declaration["contract"]
            transport = declaration["transport"]
            if contract not in ("il", "raw") or transport not in ("thinq1", "thinq2"):
                raise SystemExit(f"Invalid contract declaration for {model}")
            constructor = "device_t1" if transport == "thinq1" else "device"
            text = 'import "contract_test" as contract;\n'
            text += f"fn test_common_lifecycle() {{ contract::lifecycle({constructor}()); }}\n"
            if contract == "il":
                text += f"fn test_il_contract() {{ contract::il_contract({constructor}()); }}\n"
            (target / "tests" / f"{model}.test.rhai").write_text(text)
        contracts = subprocess.run([str(runner), str(target)], check=False).returncode
    # Run both, so a contract failure does not hide a select value failure.
    select_values = run_select_values(root, runner)
    return contracts or select_values


if __name__ == "__main__":
    sys.exit(main())
