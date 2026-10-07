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
        for name in ("drivers", "modules", "compat", "tests", "tools"):
            shutil.copytree(source / name, self.root / name)

    def prepare(self, version):
        subprocess.run(
            [sys.executable, str(self.root / "tools/prepare.py"), version],
            check=True, capture_output=True,
        )
        return self.root / "dist" / version

    def test_versions_share_drivers_and_select_adapters(self):
        outputs = [self.prepare(v) for v in ("0.1", "0.2")]
        for directory in ("drivers", "modules"):
            for source in (self.root / directory).glob("*.rhai"):
                for output in outputs:
                    self.assertEqual(source.read_bytes(), (output / source.name).read_bytes())
        for version, output in zip(("0.1", "0.2"), outputs):
            for relative in ("il_common.rhai", "tests/runtime_test.rhai"):
                self.assertEqual(
                    (self.root / "compat" / version / relative).read_bytes(),
                    (output / relative).read_bytes(),
                )

    def test_preparation_preserves_local_config_and_is_repeatable(self):
        output = self.prepare("0.2")
        config = output / "il_config_common.rhai"
        config.write_text('fn prefix() { "custom" }\n')
        self.prepare("0.2")
        self.assertEqual(config.read_text(), 'fn prefix() { "custom" }\n')

    def test_removed_sources_are_removed_without_deleting_local_files(self):
        output = self.prepare("0.1")
        source = next((self.root / "drivers").glob("*.rhai"))
        source.unlink()
        local = output / "local.txt"
        local.write_text("keep")
        self.prepare("0.1")
        self.assertFalse((output / source.name).exists())
        self.assertEqual(local.read_text(), "keep")


if __name__ == "__main__":
    unittest.main()
