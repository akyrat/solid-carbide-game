import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_garage_icon_damage_bonus as b  # noqa: E402
import style_rules  # noqa: E402


class DamageBonusIcon(unittest.TestCase):
    def test_icon_is_16x16_binary_alpha_and_passes_the_style_rules(self):
        with tempfile.TemporaryDirectory() as d:
            p = b.build(Path(d))
            self.assertEqual(p.name, "damage_bonus.png")
            im = b.hud.Image.open(p).convert("RGBA")
            self.assertEqual(im.size, (16, 16))
            self.assertTrue(all(a in (0, 255) for *_, a in im.getdata()))
            r = subprocess.run([sys.executable, str(Path(style_rules.__file__)), "art", str(p), "--size", "16x16"],
                               capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, r.stdout)
            self.assertEqual(json.loads(p.with_suffix(".json").read_text())["task"], "T-368")

    def test_deterministic_and_outline_fits_inside_the_canvas(self):
        self.assertEqual(b.draw().tobytes(), b.draw().tobytes())
        im = b.draw()
        for x, y in ((0, 0), (15, 0), (0, 15), (15, 15)):
            self.assertEqual(im.getpixel((x, y))[3], 0)
        # every red or white pixel is wrapped by the dark outline or other fill, never on the canvas edge
        for y in range(16):
            for x in range(16):
                if x in (0, 15) or y in (0, 15):
                    self.assertIn(im.getpixel((x, y)), ((0, 0, 0, 0), b.hud.OUT))


if __name__ == "__main__":
    unittest.main()
