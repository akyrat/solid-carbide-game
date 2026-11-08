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

    def test_committed_icon_is_the_script_output(self):
        self.assertTrue(os.path.exists(ICON))
        a = Image.open(ICON).convert("RGBA")
        self.assertEqual(list(a.getdata()), list(gw.draw().getdata()))


if __name__ == "__main__":
    unittest.main()
