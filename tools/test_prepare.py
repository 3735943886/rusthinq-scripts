import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


class PrepareTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        source = Path(__file__).resolve().parent.parent
        for name in ("drivers", "modules", "tests", "tools"):
            shutil.copytree(source / name, self.root / name)

    def prepare(self):
        subprocess.run(
            [sys.executable, str(self.root / "tools/prepare.py")],
            check=True, capture_output=True,
        )
        return self.root / "dist" / "0.2"

    def test_sources_are_copied_flat(self):
        output = self.prepare()
        for directory in ("drivers", "modules"):
            for source in (self.root / directory).glob("*.rhai"):
                self.assertEqual(source.read_bytes(), (output / source.name).read_bytes())
        for source in (self.root / "tests").glob("*.rhai"):
            self.assertEqual(source.read_bytes(), (output / "tests" / source.name).read_bytes())

    def test_preparation_preserves_local_config_and_is_repeatable(self):
        output = self.prepare()
        config = output / "il_config_common.rhai"
        self.assertEqual(
            config.read_bytes(),
            (self.root / "modules/il_config_common.rhai.example").read_bytes(),
        )
        config.write_text('fn prefix() { "custom" }\n')
        self.prepare()
        self.assertEqual(config.read_text(), 'fn prefix() { "custom" }\n')

    def test_removed_sources_are_removed_without_deleting_local_files(self):
        output = self.prepare()
        source = next((self.root / "drivers").glob("*.rhai"))
        source.unlink()
        local = output / "local.txt"
        local.write_text("keep")
        self.prepare()
        self.assertFalse((output / source.name).exists())
        self.assertEqual(local.read_text(), "keep")


if __name__ == "__main__":
    unittest.main()
