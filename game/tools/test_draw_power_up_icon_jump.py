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
V3 = os.path.join(ROOT, "art-archive", "T-465", "style-loop", "v3-2.png")
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
        px = list(jump.draw(2).getdata())
        self.assertEqual(px, list(Image.open(V2).convert("RGBA").getdata()))

    @unittest.skipUnless(os.path.exists(V3), "v3-2 not archived yet")
    def test_reproduces_archived_v3(self):
        self.assertEqual(self.px, list(Image.open(V3).convert("RGBA").getdata()))

    def test_car_outline_closed(self):
        # no car body pixel touches the transparent background directly (rule 2: closed outline)
        car_keys = set("ALGgdWwQBb")
        inv = {v: k for k, v in jump.P.items()}
        for y in range(16):
            for x in range(32):
                p = self.im.getpixel((x, y))
                if p[3] and inv.get(p[:3]) in car_keys:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        q = self.im.getpixel((x + dx, y + dy))
                        n8 = [self.im.getpixel((x + dx + ax, y + dy + ay)) for ax in (-1, 0, 1) for ay in (-1, 0, 1)
                              if 0 <= x + dx + ax < 32 and 0 <= y + dy + ay < 32]
                        if q[3] == 0:
                            self.assertTrue(any(inv.get(n[:3]) in ("#", "h") for n in n8 if n[3]), (x, y))


if __name__ == "__main__":
    unittest.main()
