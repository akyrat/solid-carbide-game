"""Tests for build_sidewalk_car_sample.py (T-397)."""
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_sidewalk_car_sample as b  # noqa: E402
import style_rules  # noqa: E402


def colours(a):
    return {tuple(int(c) for c in p) for p in a[a[..., 3] == 255][:, :3]}


class SidewalkTests(unittest.TestCase):
    def setUp(self):
        self.tile = b.draw_sidewalk()

    def test_road_tile_size_and_pixel_rules(self):
        self.assertEqual(self.tile.shape, (64, 128, 4))
        self.assertTrue(set(np.unique(self.tile[..., 3])) <= {0, 255})
        self.assertLessEqual(len(colours(self.tile)), 30)

    def test_fills_the_road_tiles_diamond(self):
        road = np.array(b.ground_tile("y_plain_a0"))
        same = (self.tile[..., 3] > 0) == (road[..., 3] > 0)
        self.assertGreater(same.mean(), 0.97)   # the same 2 x 2 unit diamond, give or take its edge pixels

    def test_curb_on_the_south_east_edge_only(self):
        face = np.all(self.tile[..., :3] == b.GUTTER, axis=2) & (self.tile[..., 3] == 255)
        ys, xs = np.nonzero(face)
        self.assertGreater(len(xs), 50)
        u, _ = b.ground_uv(xs, ys)
        self.assertTrue((u > 1.7).all())   # all along the lower-right (world +x) edge
        plain = b.draw_sidewalk(curb=False)
        self.assertNotIn(b.GUTTER, colours(plain))
        self.assertNotIn(b.CURB_TOP, colours(plain))

    def test_pavement_colours_and_no_greenbull(self):
        cs = colours(self.tile)
        self.assertIn(b.PAV, cs)
        self.assertIn(b.PAV_DARK, cs)
        self.assertFalse([c for c in cs if style_rules.greenbull_colour(c)])

    def test_same_input_same_pixels(self):
        self.assertTrue(np.array_equal(self.tile, b.draw_sidewalk()))


class CarCleanTests(unittest.TestCase):
    def test_background_specks_and_mirror(self):
        a = np.zeros((40, 60, 4), np.uint8)
        a[...] = (30, 30, 40, 255)                 # a flat opaque background
        a[10:30, 10:40] = (150, 160, 170, 255)     # the car
        a[12:14, 12:30] = (20, 20, 30, 255)
        a[2, 50] = (200, 0, 0, 255)                # a loose speck
        a[33:36, 50:53] = (90, 90, 90, 255)        # a detached blob
        with tempfile.TemporaryDirectory() as d:
            raw = Path(d) / "raw.png"
            Image.fromarray(a, "RGBA").save(raw)
            out = b.clean_car(raw)
            self.assertEqual(Image.fromarray(out).getbbox(), (10, 10, 40, 30))
            self.assertTrue(set(np.unique(out[..., 3])) <= {0, 255})
            mirrored = b.clean_car(raw, mirror=True)
            self.assertTrue(np.array_equal(mirrored, out[:, ::-1]))


class PreviewTests(unittest.TestCase):
    def test_writes_dark_light_and_side_by_side(self):
        car = np.zeros((128, 128, 4), np.uint8)
        car[50:80, 30:100] = (150, 160, 170, 255)
        with tempfile.TemporaryDirectory() as d:
            side, carp = Path(d) / "s.png", Path(d) / "c.png"
            Image.fromarray(b.draw_sidewalk(), "RGBA").save(side)
            Image.fromarray(car, "RGBA").save(carp)
            b.preview(side, carp, Path(d) / "out")
            for n in ("preview_dark.png", "preview_light.png", "preview_side_by_side.png"):
                self.assertTrue((Path(d) / "out" / n).is_file())
            with Image.open(Path(d) / "out" / "preview_dark.png") as dark:
                self.assertEqual(dark.size, (860 * 3, 640 * 3))


if __name__ == "__main__":
    unittest.main()
