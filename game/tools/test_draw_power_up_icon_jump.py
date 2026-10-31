"""Tests for draw_power_up_icon_jump.py (T-465). Run:
python -m unittest discover -s game/tools -p "test_draw_power_up_icon_jump.py"
"""

import os
import sys
import unittest

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import draw_power_up_icon_jump as jump  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
V2 = os.path.join(ROOT, "art-archive", "T-465", "style-loop", "v2-2.png")
FORBIDDEN = {(104, 220, 96), (247, 208, 52)}


class TestDraw(unittest.TestCase):
    def setUp(self):
        self.im = jump.draw()
        self.px = list(self.im.getdata())

    def test_script_rules(self):
        self.assertEqual(self.im.size, (32, 32))
        self.assertLessEqual({p[3] for p in self.px}, {0, 255})
        cols = {p[:3] for p in self.px if p[3]}
        self.assertLessEqual(len(cols), 30)
        self.assertFalse(cols & FORBIDDEN)
        for c in ((0, 0), (31, 0), (0, 31), (31, 31)):
            self.assertEqual(self.im.getpixel(c)[3], 0)

    def test_fills_about_28_and_centred(self):
        x0, y0, x1, y1 = self.im.getbbox()
        self.assertGreaterEqual(x1 - x0, 26)
        self.assertGreaterEqual(y1 - y0, 26)
        self.assertLessEqual(abs((x0 + x1) / 2 - 16), 1.5)
        self.assertLessEqual(abs((y0 + y1) / 2 - 16), 1.5)

    def test_has_cyan_magenta_and_car_green(self):
        cols = {p[:3] for p in self.px if p[3]}
        for k in ("c", "m", "g", "W", "#", "h"):
            self.assertIn(jump.P[k], cols)

    def test_gap_between_streaks_and_pad(self):
        # the row just above the pad's halo is empty: the car is clearly in the air
        row = [self.im.getpixel((x, jump.PAD_TOP - 1))[3] for x in range(32)]
        self.assertEqual(sum(row), 0)

    @unittest.skipUnless(os.path.exists(V2), "v2-2 not archived yet")
    def test_reproduces_archived_v2(self):
        self.assertEqual(self.px, list(Image.open(V2).convert("RGBA").getdata()))


if __name__ == "__main__":
    unittest.main()
