#!/usr/bin/env python3
"""Assemble shared drivers and a version-specific adapter for rusthinq."""

import argparse
import shutil
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version", choices=("0.1", "0.2"))
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    adapter = root / "compat" / args.version
    output = root / "dist" / args.version
    output.mkdir(parents=True, exist_ok=True)

    sources = {}
    for directory in (root / "drivers", root / "modules", adapter):
        for source in directory.glob("*.rhai"):
            sources[Path(source.name)] = source
    for directory in (root / "tests", adapter / "tests"):
        for source in directory.glob("*.rhai"):
            sources[Path("tests") / source.name] = source

    # Remove only previously generated files; leave local configuration intact.
    manifest = output / ".generated-files"
    previous = manifest.read_text().splitlines() if manifest.exists() else []
    for name in previous:
        relative = Path(name)
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError(f"invalid generated path: {name}")
        if relative not in sources:
            (output / relative).unlink(missing_ok=True)
    for relative, source in sources.items():
        target = output / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    if args.version == "0.2":
        config = output / "il_config_common.rhai"
        if not config.exists():
            shutil.copyfile(adapter / "il_config_common.rhai.example", config)
    manifest.write_text("".join(f"{p.as_posix()}\n" for p in sorted(sources)))
    print(output)


if __name__ == "__main__":
    main()
