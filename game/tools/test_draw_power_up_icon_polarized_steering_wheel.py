"""Tests for draw_power_up_icon_polarized_steering_wheel.py (T-502). Run:
python -m unittest discover -s game/tools -p "test_draw_power_up_icon_polarized_steering_wheel.py"
"""

import os
import sys
import unittest

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import draw_power_up_icon_polarized_steering_wheel as pw  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ICON = os.path.join(ROOT, "game", "art", "power_ups", "polarized_steering_wheel.png")
GREENBULL = {(12, 76, 44), (104, 220, 96), (247, 208, 52)}


class TestDraw(unittest.TestCase):
    def setUp(self):
        self.im = pw.draw()
        self.px = list(self.im.getdata())

    def test_size_mode_and_opaque_pixels(self):
        self.assertEqual(self.im.mode, "RGBA")
        self.assertEqual(self.im.size, (32, 32))
        self.assertLessEqual({p[3] for p in self.px}, {0, 255})
        for c in ((0, 0), (31, 0), (0, 31), (31, 31)):
            self.assertEqual(self.im.getpixel(c)[3], 0)

    def test_small_palette_without_greenbull(self):
        cols = {p[:3] for p in self.px if p[3]}
        self.assertLessEqual(len(cols), 16)
        self.assertFalse(cols & GREENBULL)

    def test_fills_the_frame_and_is_centred(self):
        x0, y0, x1, y1 = self.im.getbbox()
        self.assertGreaterEqual(x1 - x0, 28)
        self.assertGreaterEqual(y1 - y0, 28)
        self.assertLessEqual(abs((x0 + x1) - 32), 1)

    def test_a_wheel_rim_hub_and_hole(self):
        # The rim at the top, the hub in the middle, empty (or outline) between the spokes.
        self.assertEqual(self.im.getpixel((16, 3))[3], 255)
        self.assertIn(self.im.getpixel((16, 16))[:3], {pw.MAGENTA, pw.CYAN, pw.MAGENTA_DARK, pw.CYAN_DARK})
        self.assertEqual(self.im.getpixel((10, 9))[3], 0, "a hole between the spokes")

    def test_the_game_file_is_the_pixellab_icon(self):
        # T-503 swapped the placeholder drawing for the PixelLab icon (style loop v4).
        self.assertTrue(os.path.exists(ICON))
        game = Image.open(ICON)
        self.assertEqual(game.size, (32, 32))
        self.assertEqual(game.mode, "RGBA")


if __name__ == "__main__":
    unittest.main()
