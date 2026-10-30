"""Tests for short_platforms.py and the height checks that use it (T-405).
Run: python -m unittest discover -s game/tools -p "test_*.py"."""
import json
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import check_height_data  # noqa: E402
import short_platforms as sp  # noqa: E402

SAMPLE = os.path.join(HERE, "..", "data", "level", "elevation_sample_map.json")
MVP = os.path.join(HERE, "..", "data", "level", "mvp_map.json")

# The game's own map's short slots, as building_towers.gd make_plan gives them (the same list is checked
# on the GDScript side by tests/unit/level/test_short_platforms.gd).
SAMPLE_SHORT_IDS = ["block@12,-96/0,1", "block@12,-96/1,1", "block@-96,-42/1,1", "block@-96,12/1,1", "block@66,12/1,1"]


def level(buildings, platforms=None, ramps=None):
    return {"buildings": buildings, "platforms": platforms or [], "ramps": ramps or []}


class ShortPlatformsTest(unittest.TestCase):
    def test_which_buildings_are_platforms(self):
        for a in ("short-0", "short-3", "building-small", "building-long"):
            self.assertTrue(sp.is_platform_asset(a), a)
        for a in ("skyscraper-1", "", None, "boulder-a"):
            self.assertFalse(sp.is_platform_asset(a), a)

    def test_a_short_building_makes_a_platform_at_3_named_by_where_it_stands(self):
        d = level([{"x": -12, "y": 4, "w": 12, "h": 12, "asset": "short-1", "look": 1},
                   {"x": 20, "y": 0, "w": 12, "h": 12, "asset": "skyscraper-2", "look": 0},
                   {"x": 40, "y": 0, "w": 12, "h": 6, "asset": "building-long", "look": 0}])
        ps = sp.platforms_of(d)
        self.assertEqual([p["id"] for p in ps], ["building@-12,4", "building@40,0"])
        self.assertEqual([p["building"] for p in ps], [0, 2])
        self.assertTrue(all(p["height"] == 3.0 and p["short"] for p in ps))
        self.assertEqual((ps[1]["w"], ps[1]["h"]), (12.0, 6.0))

    def test_the_game_maps_short_slots(self):
        with open(SAMPLE, encoding="utf-8") as f:
            d = json.load(f)
        self.assertEqual([p["id"] for p in sp.platforms_of(d)], SAMPLE_SHORT_IDS)
        p = sp.platforms_of(d)[0]
        self.assertEqual((p["x"], p["y"], p["w"], p["h"]), (13.5, -79.5, 12.0, 12.0))
        # The old MVP map (no heights) keeps its whole blocks.
        with open(MVP, encoding="utf-8") as f:
            self.assertEqual(sp.platforms_of(json.load(f)), [])

    def test_a_building_with_no_asset_that_is_not_a_block_stays_a_building(self):
        d = level([{"x": -8.0, "y": -8.0, "w": 4.0, "h": 4.0}])
        self.assertEqual(sp.platforms_of(d), [])

    def test_hash_matches_building_towers(self):
        # building_towers.gd hash_of, values printed by Godot (tests/unit/level/test_short_platforms.gd).
        self.assertEqual(sp.hash_of(0, 0), 0)
        self.assertEqual(sp.hash_of(12, -96), 4282437368)
        self.assertEqual(sp.short_slots(12, -96), [(1, 1), (0, 1)])


class HeightChecksTest(unittest.TestCase):
    def test_a_ramp_may_climb_to_a_short_building(self):
        d = level([{"x": 0, "y": 0, "w": 12, "h": 12, "asset": "short-0", "look": 0}],
                  ramps=[{"id": "ramp-1", "platform": "building@0,0", "side": "west", "x": -12, "y": 2, "w": 12,
                          "h": 8, "bottom_height": 0, "top_height": 3}])
        self.assertEqual(check_height_data.check_data(d), [])
        d["ramps"][0]["platform"] = "building@4,0"
        self.assertTrue(check_height_data.check_data(d))

    def test_a_rooftop_may_stand_on_or_overlap_a_short_building(self):
        d = level([{"x": 0, "y": 0, "w": 12, "h": 12, "asset": "building-small", "look": 0}],
                  platforms=[{"id": "roof-1", "x": 2, "y": 2, "w": 4, "h": 4, "height": 6, "on": "building@0,0"},
                             {"id": "roof-2", "x": 8, "y": 8, "w": 10, "h": 10, "height": 3}])
        self.assertEqual(check_height_data.check_data(d), [])

    def test_a_ramp_over_a_short_building_is_not_refused(self):
        # A ramp whose footprint runs over a low-rise was allowed before (buildings were not checked).
        d = level([{"x": 0, "y": 0, "w": 12, "h": 12, "asset": "short-0", "look": 0}],
                  platforms=[{"id": "roof-1", "x": 20, "y": 0, "w": 10, "h": 10, "height": 3}],
                  ramps=[{"id": "ramp-1", "platform": "roof-1", "side": "west", "x": 8, "y": 0, "w": 12, "h": 6,
                          "bottom_height": 0, "top_height": 3}])
        self.assertEqual(check_height_data.check_data(d), [])


if __name__ == "__main__":
    unittest.main()
