"""Tests for build_creator_assets.py (T-232). Run: python -m unittest discover -s game/tools -p "test_*.py"."""
import json
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import build_creator_assets as bc  # noqa: E402

KINDS = {"ground", "road", "building", "boulder", "rooftop", "ramp"}


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
        self.assertEqual(ramps, [[0, 3], [3, 6]])

    def test_counts(self):
        count = lambda k: sum(1 for e in self.entries if e["kind"] == k)
        self.assertEqual(count("building"), 6 + 4)
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

    def test_road_pieces_come_first_among_the_roads(self):
        """T-252: corners, T-junctions, crossroads and dead ends (and the 1-tile straights) in 4
        rotations each, before the other road tiles; every piece is an atlas tile with its index."""
        roads = [e for e in self.entries if e["kind"] == "road"]
        ids = [e["id"] for e in roads]
        pieces = [i for i in ids if i.startswith("road-piece_")]
        self.assertEqual(ids[:len(pieces)], pieces)
        for kind, n in (("corner_", 4), ("t_", 4), ("dead_", 4), ("mid_", 2), ("cross", 1)):
            self.assertEqual(sum(1 for i in pieces if i.startswith("road-piece_" + kind)), n, kind)
        self.assertEqual(len(pieces), 15)
        atlas = bc.load("art/ground/ground_atlas.json")
        index = {t["name"]: t["index"] for t in atlas["tiles"]}
        for e in roads:
            if e["id"] in pieces:
                self.assertEqual(e["atlas_index"], index[e["id"][len("road-"):]])
                self.assertEqual(e["footprint_units"], [2.0, 2.0])

    def test_old_ground_tiles_keep_their_atlas_index(self):
        for e in self.entries:
            if e["kind"] in ("ground", "road") and "atlas_index" in e and not e["id"].startswith("road-piece_"):
                self.assertLess(e["atlas_index"], 87)


if __name__ == "__main__":
    unittest.main()
