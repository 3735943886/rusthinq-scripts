#!/usr/bin/env python3
"""Assemble drivers, modules and tests into a flat rusthinq 0.2 runtime directory."""

import argparse
import shutil
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    output = root / "dist" / "0.2"
    output.mkdir(parents=True, exist_ok=True)

    sources = {}
    for directory in (root / "drivers", root / "modules"):
        for source in directory.glob("*.rhai"):
            sources[Path(source.name)] = source
    for source in (root / "tests").glob("*.rhai"):
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
    config = output / "il_config_common.rhai"
    if not config.exists():
        shutil.copyfile(root / "modules" / "il_config_common.rhai.example", config)
    manifest.write_text("".join(f"{p.as_posix()}\n" for p in sorted(sources)))
    print(output)


if __name__ == "__main__":
    main()
