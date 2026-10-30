"""Tests for build_prop_art.py and the props in the creator's catalogue (T-253).
Run: python -m unittest discover -s game/tools -p "test_*.py"."""
import json
import os
import sys
import tempfile
import unittest

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import build_creator_assets as bc  # noqa: E402
import build_prop_art as bp  # noqa: E402

PROP_IDS = ["prop-barrier", "prop-cones", "prop-crates", "prop-ac-unit", "prop-water-tank",
            "prop-roof-vent", "prop-street-lamp", "prop-roof-sign",
            # T-398: the parked and broken cars (placeholders until T-399)
            "prop-parked-car-1", "prop-parked-car-2", "prop-parked-car-3", "prop-broken-car-1", "prop-broken-car-2"]


class PropsDataTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = bp.load()

    def test_the_props_in_four_rotations(self):
        self.assertEqual([p["id"] for p in self.data["props"]], PROP_IDS)
        self.assertEqual(self.data["rotations"], ["north", "east", "south", "west"])
        for p in self.data["props"]:
            self.assertEqual(sorted(p["textures"]), sorted(self.data["rotations"]), p["id"])
            self.assertIn(p["collision"]["shape"], ("rect", "circle"))
            if p["collision"]["shape"] == "circle":
                self.assertGreater(p["collision"]["radius"], 0)

    def test_textures_exist_and_anchors_lie_inside(self):
        for p in self.data["props"]:
            for rot, t in p["textures"].items():
                path = os.path.join(bp.GAME, t["texture"].replace("res://", ""))
                self.assertTrue(os.path.isfile(path), path)
                w, h = Image.open(path).size
                self.assertTrue(0 <= t["anchor_px"][0] < w and 0 <= t["anchor_px"][1] < h, (p["id"], rot))

    def test_labels_exist_in_creator_texts(self):
        with open(os.path.join(bp.GAME, "data", "level", "creator_texts.json"), encoding="utf-8") as f:
            texts = json.load(f)
        for p in self.data["props"]:
            self.assertIn(p["label"], texts, p["id"])

    def test_catalogue_entries(self):
        entries = [e for e in bc.build()["entries"] if e["kind"] == "prop"]
        self.assertEqual([e["id"] for e in entries], PROP_IDS)
        for e in entries:
            self.assertEqual(e["views"], ["north", "east", "south", "west"])
            self.assertEqual([t["view"] for t in e["textures"]], e["views"])
            self.assertTrue(all(bc.res_exists(t["texture"]) for t in e["textures"]))

    def test_the_committed_catalogue_has_the_props(self):
        with open(bc.OUT, encoding="utf-8") as f:
            ids = [e["id"] for e in json.load(f)["entries"] if e["kind"] == "prop"]
        self.assertEqual(ids, PROP_IDS)


class PropArtTest(unittest.TestCase):
    def test_committed_sprites_follow_the_rules(self):
        self.assertEqual(bp.check(), 0)

    def test_build_is_deterministic(self):
        data = bp.load()
        prop = data["props"][0]
        a, anchor_a = bp.draw_prop(prop, "east", 32)
        b, anchor_b = bp.draw_prop(prop, "east", 32)
        self.assertTrue(np.array_equal(a, b))
        self.assertEqual(anchor_a, anchor_b)

    def test_rotations_differ(self):
        data = bp.load()
        prop = data["props"][0]  # the barrier, 4 x 1
        north, _ = bp.draw_prop(prop, "north", 32)
        east, _ = bp.draw_prop(prop, "east", 32)
        self.assertFalse(north.shape == east.shape and np.array_equal(north, east))

    def test_a_red_sprite_fails_the_rules(self):
        with tempfile.TemporaryDirectory() as tmp:
            png = os.path.join(tmp, "red.png")
            arr = np.zeros((4, 4, 4), dtype=np.uint8)
            arr[...] = (220, 30, 30, 255)
            Image.fromarray(arr, "RGBA").save(png)
            failed = [r for r, good, _ in bp.rules(png) if not good]
            self.assertEqual(failed, ["no old-brand red"])

    def test_orange_is_not_red(self):
        with tempfile.TemporaryDirectory() as tmp:
            png = os.path.join(tmp, "orange.png")
            arr = np.zeros((4, 4, 4), dtype=np.uint8)
            arr[...] = (230, 144, 43, 255)
            Image.fromarray(arr, "RGBA").save(png)
            self.assertTrue(all(good for _, good, _ in bp.rules(png)))


if __name__ == "__main__":
    unittest.main()
