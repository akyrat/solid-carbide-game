import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_garage_icon_acceleration as b  # noqa: E402
import style_rules  # noqa: E402


class AccelerationIcon(unittest.TestCase):
    def test_16x16_binary_alpha_passes_style_rules_and_has_record(self):
        with tempfile.TemporaryDirectory() as d:
            p = b.build(Path(d) / "acceleration.png")
            im = b.hud.Image.open(p).convert("RGBA")
            self.assertEqual(im.size, (16, 16))
            self.assertTrue(all(a in (0, 255) for *_, a in im.getdata()))
            self.assertEqual(im.getpixel((0, 0))[3], 0)
            self.assertGreater(sum(1 for *_, a in im.getdata() if a), 80)
            r = subprocess.run([sys.executable, str(Path(style_rules.__file__)), "art", str(p), "--size", "16x16"],
                               capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, r.stdout)
            self.assertEqual(json.loads(p.with_suffix(".json").read_text())["task"], "T-366")

    def test_deterministic_and_refuses_overwrite(self):
        self.assertEqual(b.draw().tobytes(), b.draw().tobytes())
        with tempfile.TemporaryDirectory() as d:
            p = b.build(Path(d) / "a.png")
            with self.assertRaises(SystemExit):
                b.build(p)


if __name__ == "__main__":
    unittest.main()
