"""Tests for build_creator_assets.py (T-232). Run: python -m unittest discover -s game/tools -p "test_*.py"."""
import json
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import build_creator_assets as bc  # noqa: E402

KINDS = {"ground", "road", "building", "boulder", "rooftop", "ramp", "prop"}


class CatalogueTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cat = bc.build()
        cls.entries = cls.cat["entries"]

    def test_deterministic(self):
        self.assertEqual(json.dumps(bc.build()), json.dumps(self.cat))

    def test_entry_fields(self):
        ids = set()
        for e in self.entries:
            self.assertNotIn(e["id"], ids)
            ids.add(e["id"])
            self.assertIn(e["kind"], KINDS)
            self.assertEqual(len(e["footprint_units"]), 2)
            self.assertTrue(e["views"])
            self.assertTrue(e["mirrors"])
            self.assertTrue(e["textures"])
            for t in e["textures"]:
                self.assertIn(t["view"], e["views"])
                self.assertIn(t["mirror"], e["mirrors"])

    def test_every_kind_present(self):
        self.assertEqual({e["kind"] for e in self.entries}, KINDS)

    def test_rooftops_and_ramps(self):
        roofs = sorted(e["height"] for e in self.entries if e["kind"] == "rooftop")
        self.assertEqual(roofs, [3, 6])
        ramps = sorted(e["heights"] for e in self.entries if e["kind"] == "ramp")
        self.assertEqual(ramps, [[0, 3], [0, 6], [3, 6]])

    def test_rooftops_and_ramps_are_resizable(self):
        # T-251: any even size from 4 x 4 for a rooftop; a ramp in four directions, its width
        # dragged from 4, its length fixed at 12 units per 3 of rise.
        for e in self.entries:
            if e["kind"] not in ("rooftop", "ramp"):
                continue
            self.assertTrue(e["resizable"], e["id"])
            self.assertTrue(bc.res_exists(e["style"]), e["style"])
            if e["kind"] == "rooftop":
                self.assertEqual(e["min_size_units"], [4.0, 4.0])
                self.assertEqual(e["views"], ["iso"])
            else:
                lo, hi = e["heights"]
                self.assertEqual(e["length_units"], 12.0 * (hi - lo) / 3)
                self.assertEqual(e["min_width_units"], 4.0)
                self.assertEqual(e["views"], ["north", "east", "south", "west"])
                sides = {t["view"]: t["side"] for t in e["textures"]}
                self.assertEqual(sides, {"north": "south", "east": "west", "south": "north", "west": "east"})

    def test_counts(self):
        count = lambda k: sum(1 for e in self.entries if e["kind"] == k)
        self.assertEqual(count("building"), 6 + 4 + 2)
        self.assertEqual(count("boulder"), 2)
        self.assertEqual(count("ground"), 3)

    def test_boulder_mirrors(self):
        for e in self.entries:
            if e["kind"] == "boulder":
                self.assertEqual(e["mirrors"], [False, True])

    def test_textures_exist(self):
        for t in bc.textures_of(self.cat):
            self.assertTrue(bc.res_exists(t), t)

    def test_building_textures_all_listed(self):
        sky = bc.load("art/buildings/skyscrapers.json")
        named = bc.textures_of(self.cat)
        for p in sky["bodies"] + sky["short"]["bodies"] + sky["pavements"]:
            self.assertIn(p, named)

    def test_road_pieces_are_2_by_2_tiles_and_come_first_among_the_roads(self):
        """T-252: one entry per piece and rotation with a 4 x 4 footprint and its four tiles
        (single-tile `part` entries, not shown in the panel); the pieces come before the other roads."""
        roads = [e for e in self.entries if e["kind"] == "road"]
        pieces = [e for e in roads if "parts" in e]
        self.assertEqual(roads[:len(pieces)], pieces)
        for kind, n in (("corner_", 4), ("t_", 4), ("dead_", 4), ("cross", 1)):
            self.assertEqual(sum(1 for e in pieces if e["id"].startswith("road-piece_" + kind)), n, kind)
        self.assertEqual(len(pieces), 13)
        by_id = {e["id"]: e for e in self.entries}
        for e in pieces:
            self.assertEqual(e["footprint_units"], [4.0, 4.0])
            self.assertEqual(sorted((p["dx"], p["dy"]) for p in e["parts"]), [(0, 0), (0, 2), (2, 0), (2, 2)])
            for p in e["parts"]:
                tile = by_id[p["tile"]]
                self.assertTrue(tile["part"])
                self.assertEqual(tile["footprint_units"], [2.0, 2.0])
                self.assertGreaterEqual(tile["atlas_index"], 87)
            self.assertEqual(e["textures"][0]["region"][2:], [256, 128])
        self.assertEqual(sum(1 for e in self.entries if e.get("part")), 52)

    def test_old_ground_tiles_keep_their_atlas_index(self):
        for e in self.entries:
            if e["kind"] in ("ground", "road") and "atlas_index" in e and not e.get("part"):
                self.assertLess(e["atlas_index"], 87)


if __name__ == "__main__":
    unittest.main()
