"""Tests for build_gift_package.py (T-146). Run: python -m unittest game/tools/test_build_gift_package.py"""
import sys, unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import build_gift_package as b
from PIL import Image


class T(unittest.TestCase):
    def test_build_passes_check(self):
        b.build()
        self.assertEqual(b.check(), [])

    def test_sizes_and_bottom_on_ground(self):
        b.build()
        a = Image.open(b.OUT / "package.png")
        f = Image.open(b.OUT / "package_falling.png")
        self.assertEqual(a.size, (64, 64))
        self.assertEqual(f.size, (64, 96))
        self.assertEqual(a.getbbox()[3], 64)
        self.assertEqual(f.getbbox()[3], 96)
        self.assertLessEqual(a.getbbox()[2] - a.getbbox()[0], 42)

    def test_logo_red_present(self):
        b.build()
        a = Image.open(b.OUT / "package.png").convert("RGBA")
        self.assertIn(b.LOGO_RED, set(a.getdata()))

    def test_deterministic(self):
        b.build(); x = (b.OUT / "package.png").read_bytes()
        b.build(); self.assertEqual(x, (b.OUT / "package.png").read_bytes())


if __name__ == "__main__":
    unittest.main()
