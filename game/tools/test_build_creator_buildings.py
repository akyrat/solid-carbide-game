"""Tests for build_creator_buildings.py (T-254). Run: python -m unittest discover -s game/tools -p "test_*.py"."""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import build_creator_assets as bc  # noqa: E402
import build_creator_buildings as bb  # noqa: E402


class BuildingPiecesTest(unittest.TestCase):
    def test_data_checks_out(self):
        self.assertEqual(bb.check(), [])

    def test_footprints(self):
        data = bb.load()
        sizes = {(p["id"], t["view"]): tuple(t["footprint_units"]) for p, t in bb.textures(data)}
        self.assertEqual(sizes[("building-small", "iso")], (6, 6))
        self.assertEqual(sizes[("building-long", "ew")], (12, 6))
        self.assertEqual(sizes[("building-long", "ns")], (6, 12))

    def test_one_texture_per_view_and_mirror(self):
        for p in bb.load()["pieces"]:
            self.assertEqual(len(p["textures"]), len(p["views"]) * len(p["mirrors"]))
            self.assertEqual(len({t["texture"] for t in p["textures"]}), len(p["textures"]))

    def test_drawing_is_deterministic_and_has_no_red(self):
        img, anchor = bb.draw_box(12, 6, 4.3, 0)
        again, _ = bb.draw_box(12, 6, 4.3, 0)
        self.assertEqual(list(img.getdata()), list(again.getdata()))
        self.assertEqual(anchor[1], img.size[1])
        for r, g, b, a in set(img.getdata()):
            self.assertIn(a, (0, 255))
            self.assertFalse(a and r > 200 and g < 80 and b < 80)

    def test_looks_differ(self):
        a, _ = bb.draw_box(6, 6, 4.3, 0)
        b, _ = bb.draw_box(6, 6, 4.3, 1)
        self.assertNotEqual(list(a.getdata()), list(b.getdata()))

    def test_catalogue_has_both_with_height_and_footprints_per_texture(self):
        entries = {e["id"]: e for e in bc.build()["entries"]}
        self.assertEqual(entries["building-small"]["footprint_units"], [6.0, 6.0])
        self.assertEqual(entries["building-long"]["views"], ["ew", "ns"])
        # T-405: in the catalogue they are platforms 3 high (their data file keeps the art's own 4.3).
        self.assertEqual(entries["building-long"]["height_units"], 3.0)
        for t in entries["building-long"]["textures"]:
            self.assertIn("footprint_units", t)
            self.assertIn("anchor_art_px", t)


if __name__ == "__main__":
    unittest.main()
