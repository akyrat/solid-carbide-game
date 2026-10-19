"""Tests for build_elevation_art.py (T-186). They never call PixelLab."""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import build_elevation_art as b  # noqa: E402


class ElevationArtTests(unittest.TestCase):
    def test_mirror_tiling_is_seamless(self):
        self.assertEqual([b.mirror(i, 4) for i in range(10)], [0, 1, 2, 3, 3, 2, 1, 0, 0, 1])

    def test_ramp_plane_rises_to_the_platform(self):
        ramp = {"x": 8.0, "w": 12.0, "top_height": 3.0, "bottom_height": 0.0}
        h0, gx, gy = b.corner_plane(ramp, "ramp")
        self.assertAlmostEqual(h0 + gx * 8.0, 3.0)
        self.assertAlmostEqual(h0 + gx * 20.0, 0.0)
        self.assertAlmostEqual(h0 + gx * 14.0, 1.5)

    def test_committed_images_follow_the_rules(self):
        for name in ("platform", "ramp"):
            for rule, ok, detail in b.rules(os.path.join(b.OUT, name + ".png")):
                self.assertTrue(ok, "%s: %s (%s)" % (name, rule, detail))

    def test_sizes_match_the_pieces(self):
        from PIL import Image
        self.assertEqual(Image.open(os.path.join(b.OUT, "platform.png")).size, (1024, 608))
        self.assertEqual(Image.open(os.path.join(b.OUT, "ramp.png")).size, (640, 416))


if __name__ == "__main__":
    unittest.main()
