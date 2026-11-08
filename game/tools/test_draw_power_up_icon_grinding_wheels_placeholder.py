"""Tests for draw_power_up_icon_grinding_wheels_placeholder.py (T-586). Run:
python -m unittest discover -s game/tools -p "test_draw_power_up_icon_grinding_wheels_placeholder.py"
"""

import os
import sys
import unittest

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import draw_power_up_icon_grinding_wheels_placeholder as gw  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ICON = os.path.join(ROOT, "game", "art", "power_ups", "grinding_wheels.png")
FORBIDDEN = {(12, 76, 44), (104, 220, 96), (247, 208, 52)}


class TestDraw(unittest.TestCase):
    def test_hard_pixels_32_and_no_greenbull(self):
        im = gw.draw()
        self.assertEqual(im.size, (32, 32))
        px = list(im.getdata())
        self.assertLessEqual({p[3] for p in px}, {0, 255})
        cols = {p[:3] for p in px if p[3]}
        self.assertFalse(cols & FORBIDDEN)
        self.assertTrue(cols & set(gw.SPARKS), "has sparks")

    def test_committed_icon_is_still_a_32x32_icon(self):
        # T-587's PixelLab art replaced this placeholder in game/art/power_ups/, so the test no
        # longer pins the committed pixels to the script's output.
        self.assertTrue(os.path.exists(ICON))
        a = Image.open(ICON).convert("RGBA")
        self.assertEqual(a.size, (32, 32))


if __name__ == "__main__":
    unittest.main()
