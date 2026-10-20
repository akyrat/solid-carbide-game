"""Tests for build_elevation_sample_art.py (T-198). They never call PixelLab."""
import os
import sys
import unittest

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import build_elevation_sample_art as b  # noqa: E402


def flat_tex():
    rng = np.random.RandomState(1)
    base = rng.randint(60, 140, (128, 128, 1)).astype(np.float32)
    rgb = np.repeat(base, 3, axis=2)
    return {
        "roof": rgb, "wall": rgb * 0.8, "ramp": rgb,
        "ac": np.full((8, 8, 4), 220, np.uint8), "vent": np.full((8, 8, 4), 180, np.uint8),
        "sign": np.full((8, 8, 4), 140, np.uint8),
        "parapet": np.full((b.PARAPET_PX, 128, 4), 200, np.uint8),
        "cracks": np.zeros((8, 8), bool),
    }


class SampleArtTests(unittest.TestCase):
    def setUp(self):
        self.platforms, self.ramps = b.load_data()
        self.by_id = {p["id"]: p for p in self.platforms}

    def test_mirror_tiling_is_seamless(self):
        self.assertEqual(list(b.mirror(np.arange(10), 4)), [0, 1, 2, 3, 3, 2, 1, 0, 0, 1])

    def test_each_ramp_plane_reaches_top_and_bottom_at_its_ends(self):
        for r in self.ramps:
            h0, gx, gy, base = b.piece_plane(r, "ramp", self.by_id)
            x0, y0, x1, y1 = r["x"], r["y"], r["x"] + r["w"], r["y"] + r["h"]
            top, bottom = r["top_height"], r["bottom_height"]
            self.assertEqual(base, bottom)
            ends = {"east": ((x0, y0), (x1, y0)), "west": ((x1, y0), (x0, y0)),
                    "south": ((x0, y0), (x0, y1)), "north": ((x0, y1), (x0, y0))}[r["side"]]
            (tx, ty), (bx, by) = ends
            self.assertAlmostEqual(h0 + gx * tx + gy * ty, top, msg=r["id"])
            self.assertAlmostEqual(h0 + gx * bx + gy * by, bottom, msg=r["id"])

    def test_a_stacked_rooftop_stands_on_the_one_under_it(self):
        _, _, _, base = b.piece_plane(self.by_id["roof-nw-6"], "platform", self.by_id)
        self.assertEqual(base, 3.0)
        _, _, _, base0 = b.piece_plane(self.by_id["roof-nw-3"], "platform", self.by_id)
        self.assertEqual(base0, 0.0)

    def test_render_has_all_three_faces_and_obeys_the_rules(self):
        tex = flat_tex()
        piece = self.by_id["roof-nw-6"]
        arr, origin, face = b.render(piece, "platform", tex, self.platforms, self.ramps, self.by_id)
        self.assertEqual({int(v) for v in np.unique(face)}, {0, 1, 2, 3})
        small = b.reduce_colors(arr)
        small, _ = b.crop(small, origin)
        self.assertLessEqual(len({tuple(c) for c in small[small[..., 3] == 255][:, :3].tolist()}), b.MAX_COLORS)
        self.assertEqual(int(((small[..., 3] > 0) & (small[..., 3] < 255)).sum()), 0)

    def test_a_ramp_has_no_wall_at_the_end_where_it_joins(self):
        tex = flat_tex()
        r = next(r for r in self.ramps if r["side"] == "west")   # high at its east end: no east wall
        _, _, face = b.render(r, "ramp", tex, self.platforms, self.ramps, self.by_id)
        self.assertNotIn(2, {int(v) for v in np.unique(face)})
        r = next(r for r in self.ramps if r["side"] == "north")  # high at its south end: no south wall
        _, _, face = b.render(r, "ramp", tex, self.platforms, self.ramps, self.by_id)
        self.assertNotIn(3, {int(v) for v in np.unique(face)})

    def test_details_stay_clear_of_ramps_and_higher_rooftops(self):
        for p in self.platforms:
            for kind, x, y in b.detail_spots(p, self.platforms, self.ramps):
                self.assertIn(kind, ("ac", "vent", "sign"))
                self.assertTrue(p["x"] < x < p["x"] + p["w"] and p["y"] < y < p["y"] + p["h"], p["id"])
                for r in self.ramps:
                    self.assertFalse(r["x"] - 3 <= x <= r["x"] + r["w"] + 3 and r["y"] - 3 <= y <= r["y"] + r["h"] + 3, p["id"])
                for o in self.platforms:
                    if o["height"] > p["height"]:
                        self.assertFalse(o["x"] - 3 <= x <= o["x"] + o["w"] + 3 and o["y"] - 3 <= y <= o["y"] + o["h"] + 3, p["id"])

    def test_details_are_deterministic(self):
        p = self.platforms[0]
        self.assertEqual(b.detail_spots(p, self.platforms, self.ramps), b.detail_spots(p, self.platforms, self.ramps))

    def test_parapet_has_a_gap_where_a_ramp_joins(self):
        se3 = self.by_id["roof-se-3"]
        gaps = b.blocked_intervals(se3, "platform", self.platforms, self.ramps, "north")
        self.assertTrue(any(a <= 80 < c for a, c in gaps), "the 0-to-3 ramp at x 76..86 joins the north edge")

    def test_check_passes_on_the_committed_art(self):
        self.assertEqual(b.check(), 0)

    def test_one_sprite_and_record_per_area(self):
        for _, piece in b.pieces(self.platforms, self.ramps):
            self.assertTrue(os.path.exists(os.path.join(b.OUT, piece["id"] + ".png")), piece["id"])
            self.assertTrue(os.path.exists(os.path.join(b.OUT, piece["id"] + ".json")), piece["id"])

    def test_the_rules_catch_bad_images(self):
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "bad.png")
            img = Image.new("RGBA", (4, 4), (120, 20, 20, 255))   # opaque corners, Redgull red
            img.putpixel((1, 1), (0, 0, 0, 100))                  # semi-transparent
            img.save(path)
            failed = [rule for rule, ok, _ in b.rules(path) if not ok]
            self.assertEqual(len(failed), 3)


if __name__ == "__main__":
    unittest.main()
