"""Tests for build_prop_final_art.py (T-256). Run: python -m unittest discover -s game/tools -p "test_*.py"."""
import json
import os
import sys
import tempfile
import unittest

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import build_prop_final_art as bf  # noqa: E402


class FinalPropArtTest(unittest.TestCase):
    def test_committed_final_art_follows_the_rules(self):
        self.assertEqual(bf.check(), 0)

    def test_textures_use_the_final_art_and_anchors_lie_inside(self):
        with open(bf.PROPS_JSON, encoding="utf-8") as f:
            data = json.load(f)
        for p in data["props"]:
            if p["id"][len("prop-"):].replace("-", "_") not in bf.SPECS:
                continue  # T-398: the cars stay placeholders until T-399
            self.assertEqual(sorted(p["textures"]), sorted(data["rotations"]))
            for rot, t in p["textures"].items():
                self.assertTrue(t["texture"].endswith("_%s_art.png" % rot), t["texture"])
                w, h = Image.open(os.path.join(bf.GAME, t["texture"].replace("res://", ""))).size
                self.assertTrue(0 <= t["anchor_px"][0] < w and 0 <= t["anchor_px"][1] < h, (p["id"], rot))

    def test_east_is_the_mirror_of_north(self):
        arr = np.zeros((6, 8, 4), dtype=np.uint8)
        arr[1:5, 1:4] = (50, 60, 70, 255)
        rots = bf.make_rotations(arr, [2, 4])
        self.assertTrue(np.array_equal(rots["east"][0], arr[:, ::-1]))
        self.assertTrue(np.array_equal(rots["south"][0], arr))
        self.assertEqual(rots["east"][1], [5, 4])

    def test_clean_pushes_red_to_orange_and_caps_colours(self):
        rng = np.random.RandomState(1)
        arr = np.zeros((20, 20, 4), dtype=np.uint8)
        arr[..., :3] = rng.randint(0, 255, (20, 20, 3))
        arr[..., 3] = 255
        arr[0, 0] = (220, 20, 20, 255)
        out = bf.clean(arr)
        cols = {tuple(c[:3]) for c in out[out[..., 3] == 255]}
        self.assertLessEqual(len(cols), bf.MAX_COLORS)
        self.assertFalse(any(bf.is_red(c) for c in cols))

    def test_a_wide_sprite_is_scaled_down_only(self):
        wide = np.zeros((10, 400, 4), dtype=np.uint8)
        wide[..., 3] = 255
        out, f = bf.fit_width(wide, [2, 2])
        self.assertLess(out.shape[1], 400)
        small = np.zeros((10, 20, 4), dtype=np.uint8)
        out, f = bf.fit_width(small, [2, 2])
        self.assertEqual(out.shape[1], 20)

    def test_build_is_deterministic(self):
        with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
            bf.build(out_dir=a, props_json=bf.PROPS_JSON, write_json=False)
            bf.build(out_dir=b, props_json=bf.PROPS_JSON, write_json=False)
            for fn in os.listdir(a):
                with open(os.path.join(a, fn), "rb") as x, open(os.path.join(b, fn), "rb") as y:
                    self.assertEqual(x.read(), y.read(), fn)
                with open(os.path.join(bf.OUT, fn), "rb") as z, open(os.path.join(a, fn), "rb") as x:
                    self.assertEqual(x.read(), z.read(), fn)


if __name__ == "__main__":
    unittest.main()
