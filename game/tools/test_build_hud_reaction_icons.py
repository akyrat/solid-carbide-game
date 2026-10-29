import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hud_reaction_icons as b  # noqa: E402
import style_rules  # noqa: E402


class ReactionIcons(unittest.TestCase):
    def test_every_icon_is_16x16_binary_alpha_and_passes_the_style_rules(self):
        with tempfile.TemporaryDirectory() as d:
            paths = b.build(Path(d))
            self.assertEqual(len(paths), 12)
            for p in paths:
                im = b.hud.Image.open(p).convert("RGBA")
                self.assertEqual(im.size, (16, 16))
                self.assertTrue(all(a in (0, 255) for *_, a in im.getdata()))
                self.assertEqual(im.getpixel((0, 0))[3], 0)
                r = subprocess.run([sys.executable, str(Path(style_rules.__file__)), "art", str(p), "--size", "16x16"],
                                   capture_output=True, text=True)
                self.assertEqual(r.returncode, 0, (p, r.stdout))
                self.assertEqual(json.loads(p.with_suffix(".json").read_text())["task"], "T-356" if p.stem.removeprefix("reaction_") in b.BAD_NAMES else "T-352")

    def test_deterministic(self):
        self.assertEqual(b.draw("star").tobytes(), b.draw("star").tobytes())


if __name__ == "__main__":
    unittest.main()
