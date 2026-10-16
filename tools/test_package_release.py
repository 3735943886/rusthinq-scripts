import json
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest
from pathlib import Path

from package_release import package, validate_tag


class ReleaseTests(unittest.TestCase):
    def test_tag_format_and_calendar(self):
        for tag in ("2026.10.08", "2026.10.08.1", "2024.02.29.12"):
            self.assertEqual(validate_tag(tag), tag)
        for tag in ("v2026.10.08", "2026.2.01", "2026.02.29", "2026.10.08.0", "../release"):
            with self.assertRaises(ValueError):
                validate_tag(tag)

    def test_archive_contains_tested_drivers_and_no_local_settings(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = Path(__file__).resolve().parent.parent
            for name in ("drivers", "modules", "tests", "tools"):
                shutil.copytree(source / name, root / name)
            for name in ("COPYING", "RUSTHINQ_REF"):
                shutil.copyfile(source / name, root / name)
            subprocess.run([sys.executable, str(root / "tools/prepare.py")],
                           check=True, capture_output=True)
            (root / "dist/0.2/il_config_common.rhai").write_text("PRIVATE SETTINGS")
            archive = package(root, "2026.10.08", "a" * 40, "b" * 40, root / "out")
            self.assertEqual(archive.name, "rusthinq-scripts-0.2-2026.10.08.tar.gz")
            original = archive.read_bytes()
            self.assertEqual(package(root, "2026.10.08", "a" * 40,
                                     "b" * 40, root / "out").read_bytes(), original)
            with tarfile.open(archive) as tar:
                prefix = "rusthinq-scripts-0.2/"
                names = tar.getnames()
                self.assertNotIn(prefix + "il_config_common.rhai", names)
                self.assertFalse(any("/tests/" in n or ".generated-files" in n for n in names))
                self.assertIn(prefix + "il_config_common.rhai.example", names)
                metadata = json.load(tar.extractfile(prefix + "RELEASE.json"))
                self.assertEqual(metadata["rusthinq_commit"], "a" * 40)
                self.assertEqual(metadata["scripts_commit"], "b" * 40)
                self.assertEqual(metadata["runtime"], "0.2")
                for driver in (root / "drivers").glob("*.rhai"):
                    self.assertEqual(tar.extractfile(prefix + driver.name).read(), driver.read_bytes())

if __name__ == "__main__":
    unittest.main()
