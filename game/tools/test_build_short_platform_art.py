"""Tests for build_short_platform_art.py (T-405). Run: python -m unittest discover -s game/tools -p "test_*.py"."""
import json
import os
import sys
import unittest

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_short_platform_art as bpa  # noqa: E402

GAME = os.path.join(HERE, "..")


def img(res):
    return np.array(Image.open(os.path.join(GAME, res.replace("res://", ""))).convert("RGBA"))


class PlatformArtTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(os.path.join(GAME, "art", "buildings", "platforms", "platforms.json"), encoding="utf-8") as f:
            cls.rec = json.load(f)

    def test_every_short_texture_has_four_images_of_one_size(self):
        self.assertEqual(len(self.rec["textures"]), 14)  # 8 low-rise bodies, 6 small and long textures
        for src, t in self.rec["textures"].items():
            sizes = {img(t[k]).shape for k in ("full", "clean", "ns", "ew")}
            self.assertEqual(len(sizes), 1, src)
            h, w = sizes.pop()[:2]
            A, B = t["footprint_units"]
            # The box fills the footprint: as wide as its diamond, the anchor on its front corner.
            self.assertEqual(w, (A + B) * 32, src)
            self.assertEqual(t["anchor_art_px"], [A * 32, h], src)
            self.assertGreaterEqual(h, (A + B) * 16 + 96, src)

    def test_the_walls_are_3_units_high(self):
        # The front corner's column: opaque from the roof's front corner (96 rows up) down to the bottom.
        for src, t in self.rec["textures"].items():
            full = img(t["full"])
            h = full.shape[0]
            x = t["anchor_art_px"][0]
            col = full[:, x - 1, 3]
            self.assertTrue((col[h - 96:] > 0).all(), src)
            # The roof's back corner (column B * 32) is (A + B) * 16 rows above the roof's front corner.
            A, B = t["footprint_units"]
            self.assertGreater(full[h - 96 - (A + B) * 16 + 2, B * 32, 3], 0, src)

    def test_the_roof_pieces_have_no_walls_and_no_pavement(self):
        for src, t in self.rec["textures"].items():
            full, clean = img(t["full"]), img(t["clean"])
            h = full.shape[0]
            x = t["anchor_art_px"][0]
            self.assertTrue((full[h - 40, x - 1, 3] > 0), src)
            self.assertEqual(clean[h - 40, x - 1, 3], 0, src)   # no wall in the clean roof
            self.assertEqual(full[h - 1, 0, 3], 0, src)         # the left corner is bare: no pavement

    def test_the_props_are_kept_whole_in_every_piece(self):
        # The rooftop props' pixels are the same in all four images (the parapets never cut them).
        for res, footprint, box, corner, wall_rows, art, bare in bpa.sources():
            t = self.rec["textures"][res]
            ims = [img(t[k]) for k in ("full", "clean", "ns", "ew")]
            ox, oy = bpa.props_offset(t["anchor_art_px"], footprint, box, corner, wall_rows)
            ys, xs = np.nonzero((art != bare).any(-1) & (art[..., 3] > 0))
            self.assertGreater(len(ys), 100, res)  # every building has props on its roof
            for im in ims:
                self.assertTrue(np.array_equal(im[ys + oy, xs + ox], art[ys, xs]), res)

    def test_the_files_are_what_the_script_builds(self):
        self.assertEqual(bpa.check(), [])


if __name__ == "__main__":
    unittest.main()
