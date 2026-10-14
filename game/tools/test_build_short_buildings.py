"""Tests for build_short_buildings.py (T-129): roof, shear columns, prop cutting, body rules."""
import unittest

import numpy as np

import build_short_buildings as sb
import build_skyscrapers as bs


def flat(h, colour):
    a = np.zeros((h, sb.WALL_W, 4), dtype=np.uint8)
    a[..., :3] = colour
    a[..., 3] = 255
    return a


class T(unittest.TestCase):
    def setUp(self):
        self.pal = bs.load_palette()

    def test_body_size_and_rules(self):
        body = sb.build_body(flat(134, (32, 31, 45)), flat(134, (41, 39, 54)), self.pal, [])
        self.assertEqual(body.shape, (134 + 384, 768, 4))
        r = bs.sprite_rules(body)
        self.assertEqual(r["semi_transparent"], 0)
        self.assertTrue(r["colors_ok"] and r["red_ok"] and r["has_transparent"])

    def test_walls_are_sheared_columns_not_resampled(self):
        fl = flat(40, (32, 31, 45))
        fl[..., :3][:, :, 0] = np.arange(sb.WALL_W)[None, :] % 50 + 24
        body = sb.build_body(fl, flat(40, (41, 39, 54)), self.pal, [])
        # an interior column keeps the flat column's pixels in order, starting at its own offset
        x = 100
        col = body[sb.wall_top(x) + 2: sb.wall_top(x) + 38, x, :3]
        self.assertTrue((col[:, 0] == fl[2:38, x, 0]).all())
        # the base falls 1 px per 2 px on the left wall and rises on the right
        self.assertEqual(sb.wall_top(2) - sb.wall_top(0), 1)
        self.assertEqual(sb.wall_top(sb.BODY_W - 3) - sb.wall_top(sb.BODY_W - 1), 1)

    def test_roof_is_the_whole_diamond_and_visible(self):
        body = np.zeros((134 + 384, 768, 4), dtype=np.uint8)
        sb.draw_roof(body, self.pal)
        self.assertEqual(body[0:3, 380:388, 3].max(), 255)      # back corner
        self.assertEqual(body[192, 2, 3], 255)                    # left corner
        self.assertEqual(int(body[383, :, 3].max()), 255)         # front corner row

    def test_prop_cut_removes_the_plate_and_trims(self):
        a = np.zeros((20, 20, 4), dtype=np.uint8)
        a[2:18, 2:18] = [100, 100, 100, 255]
        out = sb.clean_prop(a, self.pal, polygon=[(2, 2), (10, 2), (10, 10), (2, 10)])
        self.assertLessEqual(out.shape[0], 10)
        self.assertTrue(set(np.unique(out[..., 3]).tolist()) <= {0, 255})

    def test_palette_b_recolour_keeps_rules_and_avoids_boulder_colours(self):
        body = sb.build_body(flat(134, (52, 28, 112)), flat(134, (100, 50, 190)), self.pal, [])
        b = sb.recolor_b(body)
        self.assertTrue(bs.sprite_rules(b)["colors_ok"])
        cols = {tuple(p[:3]) for p in b.reshape(-1, 4).tolist() if p[3] == 255}
        self.assertNotIn((52, 28, 112), cols)


if __name__ == "__main__":
    unittest.main()
