"""Tests for build_street_pieces.py (T-398). Run: python -m unittest discover -s game/tools -p "test_*.py"."""
import os
import sys
import unittest

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import build_street_pieces as bs  # noqa: E402


class StreetPiecesTest(unittest.TestCase):
    def test_committed_files_match_a_build_and_follow_the_rules(self):
        self.assertEqual(bs.check(), 0)

    def test_every_curb_piece_once(self):
        vs = bs.variants()
        names = [bs.tile_name(e, c) for e, c in vs]
        self.assertEqual(len(names), len(set(names)))
        self.assertEqual(len(vs), 47)
        self.assertEqual(names[0], "sidewalk")
        for edges, corners in vs:
            for c in corners:
                self.assertNotIn(c[0], edges)
                self.assertNotIn(c[1], edges)

    def test_names(self):
        self.assertEqual(bs.tile_name("", []), "sidewalk")
        self.assertEqual(bs.tile_name("es", []), "sidewalk-es")
        self.assertEqual(bs.tile_name("n", ["se", "sw"]), "sidewalk-n-in_se_sw")
        self.assertEqual(bs.tile_name("", ["ne"]), "sidewalk-in_ne")

    def test_a_curb_changes_the_tile(self):
        plain = bs.draw_tile("", [])
        for edges, corners in (("e", []), ("s", []), ("n", []), ("w", []), ("", ["se"])):
            self.assertFalse(np.array_equal(plain, bs.draw_tile(edges, corners)), (edges, corners))

    def test_the_tile_is_the_road_tile_diamond(self):
        a = bs.draw_tile("es", [])
        self.assertEqual(a.shape, (64, 128, 4))
        self.assertEqual(a[0, 0, 3], 0)
        self.assertEqual(a[32, 64, 3], 255)

    def test_craters(self):
        images, rec = bs.build_craters()
        self.assertEqual(len(rec["craters"]), 3)
        for c in rec["craters"]:
            self.assertEqual(c["label"], "piece_meteor_crater")
            self.assertEqual(c["footprint_units"], [2.0, 2.0])
        arrays = list(images.values())
        self.assertFalse(np.array_equal(arrays[0], arrays[1]))
        self.assertFalse(np.array_equal(arrays[1], arrays[2]))


if __name__ == "__main__":
    unittest.main()
