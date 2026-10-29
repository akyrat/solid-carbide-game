import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_garage_icon_pickup_magnet as b  # noqa: E402
import style_rules  # noqa: E402


class PickupMagnetIcon(unittest.TestCase):
    def test_icon_is_16x16_binary_alpha_and_passes_the_style_rules(self):
        with tempfile.TemporaryDirectory() as d:
            p = b.build(Path(d))
            self.assertEqual(p.name, "pickup_magnet.png")
            im = b.hud.Image.open(p).convert("RGBA")
            self.assertEqual(im.size, (16, 16))
            self.assertTrue(all(a in (0, 255) for *_, a in im.getdata()))
            self.assertEqual(im.getpixel((0, 0))[3], 0)
            r = subprocess.run([sys.executable, str(Path(style_rules.__file__)), "art", str(p), "--size", "16x16"],
                               capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, r.stdout)
            self.assertEqual(json.loads(p.with_suffix(".json").read_text())["task"], "T-369")

    def test_deterministic(self):
        self.assertEqual(b.draw().tobytes(), b.draw().tobytes())


if __name__ == "__main__":
    unittest.main()
