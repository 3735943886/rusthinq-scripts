#!/usr/bin/env python3
"""Run repository-wide contracts with the production host, without editing sources."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


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
        # Preserve runtime root overrides, just as the production loader does.
        for directory in ("drivers", "modules", "tests"):
            shutil.copytree(root / directory, target / directory)
        for source in root.glob("*.rhai"):
            shutil.copy2(source, target / source.name)
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
        return subprocess.run([str(runner), str(target)], check=False).returncode


if __name__ == "__main__":
    sys.exit(main())
