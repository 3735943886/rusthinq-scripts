#!/usr/bin/env python3
"""Package the tested drivers and modules without local settings or test fixtures."""

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


def package(root, tag, host_commit, scripts_commit, output):
    validate_tag(tag)
    for commit in (host_commit, scripts_commit):
        if not re.fullmatch(r"[0-9a-f]{40}", commit):
            raise ValueError("commit must be a full 40-character Git SHA")
    files = {}
    for directory in ("drivers", "modules"):
        for source in (root / directory).glob("*.rhai"):
            files[f"{directory}/{source.name}"] = source.read_bytes()
    files["COPYING"] = (root / "COPYING").read_bytes()
    metadata = {
        "tag": tag, "runtime": "0.2", "scripts_commit": scripts_commit,
        "rusthinq_ref": (root / "RUSTHINQ_REF").read_text().strip(),
        "rusthinq_commit": host_commit,
    }
    files["RELEASE.json"] = (json.dumps(metadata, indent=2) + "\n").encode()
    files["INSTALL.txt"] = (
        f"rusthinq-scripts {tag} for rusthinq 0.2\n\n"
        "Set [drivers] directory to the absolute path of this extracted directory\n"
        "(rusthinq bfb8e77 or later). Set watch = true in the same section for\n"
        "automatic driver reload. Stop rusthinq before extracting an update over an\n"
        "existing directory. To change the descriptor prefix, copy\n"
        "modules/il_config_common.rhai to this directory and edit prefix(); a file\n"
        "here overrides drivers/ and modules/, and updates do not replace it.\n"
    ).encode()
    output.mkdir(parents=True, exist_ok=True)
    archive = output / f"rusthinq-scripts-0.2-{tag}.tar.gz"
    with archive.open("wb") as stream:
        with gzip.GzipFile(filename="", fileobj=stream, mode="wb", mtime=0) as zipped:
            with tarfile.open(fileobj=zipped, mode="w") as tar:
                for name, data in sorted(files.items()):
                    info = tarfile.TarInfo(f"rusthinq-scripts-0.2/{name}")
                    info.size = len(data)
                    info.mode = 0o644
                    tar.addfile(info, io.BytesIO(data))
    return archive


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--host-commit", required=True)
    parser.add_argument("--scripts-commit", required=True)
    parser.add_argument("--output", type=Path, default=Path("dist/releases"))
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    print(package(root, args.tag, args.host_commit,
                  args.scripts_commit, args.output))


if __name__ == "__main__":
    main()
