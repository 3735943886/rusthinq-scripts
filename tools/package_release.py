#!/usr/bin/env python3
"""Package a tested runtime without local settings or test fixtures."""

import argparse
import datetime
import gzip
import io
import json
import re
import tarfile
from pathlib import Path


def validate_tag(tag):
    if not re.fullmatch(r"\d{4}\.\d{2}\.\d{2}(?:\.[1-9]\d*)?", tag):
        raise ValueError("tag must be yyyy.mm.dd or yyyy.mm.dd.N (N >= 1)")
    datetime.datetime.strptime(tag[:10], "%Y.%m.%d")
    return tag


def package(root, version, tag, host_commit, scripts_commit, output):
    validate_tag(tag)
    for commit in (host_commit, scripts_commit):
        if not re.fullmatch(r"[0-9a-f]{40}", commit):
            raise ValueError("commit must be a full 40-character Git SHA")
    runtime = root / "dist" / version
    adapter = root / "compat" / version
    names = set()
    for directory in (root / "drivers", root / "modules", adapter):
        names.update(p.name for p in directory.glob("*.rhai"))
    files = {name: (runtime / name).read_bytes() for name in sorted(names)}
    if version == "0.2":
        files["il_config_common.rhai.example"] = (
            adapter / "il_config_common.rhai.example"
        ).read_bytes()
    files["COPYING"] = (root / "COPYING").read_bytes()
    metadata = {
        "tag": tag, "runtime": version, "scripts_commit": scripts_commit,
        "rusthinq_ref": (adapter / "RUSTHINQ_REF").read_text().strip(),
        "rusthinq_commit": host_commit,
    }
    files["RELEASE.json"] = (json.dumps(metadata, indent=2) + "\n").encode()
    setting = ("[scripting] rhai_dir" if version == "0.1" else "[drivers] directory")
    instructions = (
        f"rusthinq-scripts {tag} for rusthinq {version}\n\n"
        f"Set {setting} to the absolute path of this extracted directory.\n"
        "Set watch = true in the same section for automatic driver reload.\n"
        "Stop rusthinq before extracting an update over an existing directory.\n"
    )
    if version == "0.2":
        instructions += (
            "On first installation, copy il_config_common.rhai.example to\n"
            "il_config_common.rhai and edit prefix(). Preserve that local file on updates.\n"
        )
    else:
        instructions += "Set [scripting] il_prefix in the host configuration (for example, il).\n"
    files["INSTALL.txt"] = instructions.encode()
    output.mkdir(parents=True, exist_ok=True)
    archive = output / f"rusthinq-scripts-{version}-{tag}.tar.gz"
    with archive.open("wb") as stream:
        with gzip.GzipFile(filename="", fileobj=stream, mode="wb", mtime=0) as zipped:
            with tarfile.open(fileobj=zipped, mode="w") as tar:
                for name, data in sorted(files.items()):
                    info = tarfile.TarInfo(f"rusthinq-scripts-{version}/{name}")
                    info.size = len(data)
                    info.mode = 0o644
                    tar.addfile(info, io.BytesIO(data))
    return archive


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, choices=("0.1", "0.2"))
    parser.add_argument("--tag", required=True)
    parser.add_argument("--host-commit", required=True)
    parser.add_argument("--scripts-commit", required=True)
    parser.add_argument("--output", type=Path, default=Path("dist/releases"))
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    print(package(root, args.version, args.tag, args.host_commit,
                  args.scripts_commit, args.output))


if __name__ == "__main__":
    main()
