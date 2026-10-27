"""HISTORY: tests for the old logo's tool. Tests for the old logo's one-colour check (T-075), kept as its history (T-298)."""
import sys, unittest
from pathlib import Path
from PIL import Image
sys.path.insert(0, str(Path(__file__).parent))
import check_logo_one_colour as c, flatten_logo as f
from style_rules import OLD_BRAND

ROOT = Path(__file__).resolve().parents[2]
# The old logo files moved from game/art/logo/ to art-archive/T-075/ (T-312).
OLD_LOGO_DIR = ROOT / "art-archive/T-075"
OLD_LOGO_NAMES = [f"{OLD_BRAND.lower()}_logo_{n}.png" for n in (128, 32, 64)]


class T(unittest.TestCase):
    def test_flatten_makes_it_pass(self):
        im = Image.new("RGBA", (4, 4), (0, 0, 0, 0))
        im.putpixel((1, 1), (215, 62, 63, 255)); im.putpixel((2, 1), (104, 40, 37, 255)); im.putpixel((2, 2), (1, 1, 1, 90))
        self.assertTrue(c.check(im))
        self.assertEqual(c.check(f.flatten(im)), [])

    def test_two_colours_fail(self):
        im = Image.new("RGBA", (4, 4), (0, 0, 0, 0))
        im.putpixel((1, 1), (150, 24, 28, 255)); im.putpixel((2, 1), (10, 200, 10, 255))
        self.assertTrue(c.check(im))

    def test_sample(self):
        for n in (128, 64, 32):
            p = OLD_LOGO_DIR / f"{OLD_BRAND.lower()}_logo_{n}.png"
            self.assertEqual(c.check(Image.open(p)), [], p.name)

    def test_only_final_files(self):
        # game/art/logo/ keeps only Greenbull's approved emblem and wordmark (T-300); the three
        # old logo files are in art-archive/T-075/ (T-312).
        names = sorted(p.name for p in (ROOT / "game/art/logo").glob("*.png"))
        self.assertEqual(names, ["greenbull_emblem_128.png", "greenbull_emblem_32.png", "greenbull_emblem_64.png",
                                 "greenbull_wordmark.png"])
        for name in OLD_LOGO_NAMES:
            self.assertTrue((OLD_LOGO_DIR / name).is_file(), name)


if __name__ == "__main__":
    unittest.main()
