"""Tests for build_gift_package.py (T-146, Greenbull rebuild T-304).
Run: python -m unittest game/tools/test_build_gift_package.py"""
import sys, tempfile, unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import build_gift_package as b
import style_rules as rules
from PIL import Image


def colours(path):
    return {p[:3] for p in Image.open(path).convert("RGBA").getdata() if p[3]}


class T(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        b.build()

    def test_build_passes_check(self):
        self.assertEqual(b.check(), [])

    def test_sizes_and_bottom_on_ground(self):
        a = Image.open(b.OUT / "package.png")
        f = Image.open(b.OUT / "package_falling.png")
        self.assertEqual(a.size, (64, 64))
        self.assertEqual(f.size, (64, 96))
        self.assertEqual(a.getbbox()[3], 64)
        self.assertEqual(f.getbbox()[3], 96)
        self.assertLessEqual(a.getbbox()[2] - a.getbbox()[0], 42)

    def test_no_redgull_red(self):
        for name in b.NAMES:
            reds = [c for c in colours(b.OUT / name) if rules.is_redgull_red(c)]
            self.assertEqual(reds, [], name)

    def test_greenbull_colours_lead(self):
        for name in b.NAMES:
            im = Image.open(b.OUT / name).convert("RGBA")
            opaque = [p[:3] for p in im.getdata() if p[3]]
            green = [c for c in opaque if c[1] > c[0] and c[1] >= c[2]]
            self.assertGreater(len(green) / len(opaque), 0.5, name)
            self.assertIn(rules.GREENBULL_DARK_GREEN, set(opaque), name)

    def test_emblem_stamped(self):
        emblem = {p[:3] for p in Image.open(b.LOGO).convert("RGBA").getdata() if p[3]}
        small = b.small_emblem()
        used = {p[:3] for p in small.getdata() if p[3]}
        self.assertTrue(used <= emblem)
        self.assertEqual(small.width, b.LOGO_W)
        # the stamped tag carries the emblem's light green on the ground sprite
        self.assertIn(rules.GREENBULL_LIGHT_GREEN, colours(b.OUT / "package.png"))

    def test_hard_alpha_both(self):
        for name in b.NAMES:
            alphas = {p[3] for p in Image.open(b.OUT / name).convert("RGBA").getdata()}
            self.assertLessEqual(alphas, {0, 255})

    def test_piece_matches_build(self):
        with tempfile.TemporaryDirectory() as d:
            for piece, name in (("package", "package.png"), ("package_falling", "package_falling.png")):
                p = Path(d) / name
                b.PIECES[piece]().save(p)
                self.assertEqual(list(Image.open(p).getdata()), list(Image.open(b.OUT / name).getdata()))

    def test_deterministic(self):
        b.build(); x = (b.OUT / "package.png").read_bytes()
        b.build(); self.assertEqual(x, (b.OUT / "package.png").read_bytes())


if __name__ == "__main__":
    unittest.main()
