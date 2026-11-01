"""Tests for build_power_up_icon_jump.py (T-465). Run: python -m unittest game/tools/test_build_power_up_icon_jump.py"""

import os
import sys
import tempfile
import unittest

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import build_power_up_icon_jump as jump  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RAW = os.path.join(ROOT, "art-archive", "T-465", "pixellab", "jump_v1_raw.png")
V1 = os.path.join(ROOT, "art-archive", "T-465", "style-loop", "v1-2.png")


class TestHelpers(unittest.TestCase):
    def test_outline_and_glow_are_not_car(self):
        self.assertFalse(jump.is_car_body((10, 12, 20), 5))       # near-black outline
        self.assertFalse(jump.is_car_body((40, 230, 250), 5))     # bright cyan glow
        self.assertFalse(jump.is_car_body((90, 120, 130), 20))    # below the car rows
        self.assertTrue(jump.is_car_body((70, 110, 120), 5))      # teal-grey paint

    def test_to_green_is_green_and_not_greenbull(self):
        out = jump.to_green((70, 110, 120))
        self.assertGreater(out[1], out[0])
        self.assertGreater(out[1], out[2])
        self.assertNotIn(out, jump.GREENBULL_FORBIDDEN)

    def test_merge_colours_caps_count(self):
        im = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
        for i in range(40):
            im.putpixel((i % 8, i // 8), (i * 6, 100, 200 - i * 4, 255))
        self.assertEqual(jump.merge_colours(im, 10), 10)
        cols = {p for p in im.getdata() if p[3]}
        self.assertEqual(len(cols), 10)


@unittest.skipUnless(os.path.exists(RAW), "raw PixelLab picture not present")
class TestBuild(unittest.TestCase):
    def test_build_meets_script_rules(self):
        with tempfile.TemporaryDirectory() as d:
            out = os.path.join(d, "j.png")
            info = jump.build(RAW, out, 30)
            im = Image.open(out).convert("RGBA")
            self.assertEqual(im.size, (32, 32))
            alphas = {p[3] for p in im.getdata()}
            self.assertLessEqual(alphas, {0, 255})
            cols = {p[:3] for p in im.getdata() if p[3]}
            self.assertLessEqual(len(cols), 30)
            self.assertFalse(cols & jump.GREENBULL_FORBIDDEN)
            self.assertGreater(info["car_pixels_recoloured"], 50)

    @unittest.skipUnless(os.path.exists(V1), "v1-2 not archived yet")
    def test_reproduces_archived_v1(self):
        with tempfile.TemporaryDirectory() as d:
            out = os.path.join(d, "j.png")
            jump.build(RAW, out, 30)
            self.assertEqual(list(Image.open(out).convert("RGBA").getdata()),
                             list(Image.open(V1).convert("RGBA").getdata()))


if __name__ == "__main__":
    unittest.main()
