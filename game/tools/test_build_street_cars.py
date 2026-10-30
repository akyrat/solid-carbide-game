"""Tests for build_street_cars.py (T-399). Run: python -m unittest discover -s game/tools -p "test_*.py"."""
import base64
import json
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import build_street_cars as bc  # noqa: E402


def car(nose_right=True):
    """A small fake car picture in a 128 x 128 frame: a grey body, a 'nose' block on one side."""
    a = np.zeros((bc.FRAME, bc.FRAME, 4), np.uint8)
    a[50:80, 30:100] = (150, 160, 170, 255)
    if nose_right:
        a[55:75, 90:100] = (20, 20, 30, 255)
    else:
        a[55:75, 30:40] = (20, 20, 30, 255)
    return a


class StripTest(unittest.TestCase):
    def test_strip_order_and_mirrors(self):
        top_right, bottom_left = car(True), car(False)
        bottom_left[78:80, 30:100] = (90, 60, 40, 255)   # make the bottom picture different from the top
        s = bc.make_strip(top_right, True, bottom_left, True)
        self.assertEqual(s.shape, (bc.FRAME, bc.FRAME * 4, 4))
        f = bc.split_strip(s)
        self.assertTrue(np.array_equal(f["west"], f["north"][:, ::-1]))
        self.assertTrue(np.array_equal(f["east"], f["south"][:, ::-1]))
        self.assertTrue(np.array_equal(f["north"], top_right))
        self.assertTrue(np.array_equal(f["south"], bottom_left))

    def test_a_top_left_picture_is_mirrored_to_north(self):
        top_left, bottom_right = car(False), car(True)
        f = bc.split_strip(bc.make_strip(top_left, False, bottom_right, False))
        self.assertTrue(np.array_equal(f["west"], top_left))
        self.assertTrue(np.array_equal(f["east"], bottom_right))
        self.assertTrue(np.array_equal(f["north"], top_left[:, ::-1]))

    def test_one_shared_palette_of_at_most_30(self):
        rng = np.random.default_rng(1)
        a, b = car(), car(False)
        a[50:80, 30:100, :3] = rng.integers(0, 255, (30, 70, 3))
        b[50:80, 30:100, :3] = rng.integers(0, 255, (30, 70, 3))
        s = bc.make_strip(a, True, b, True)
        self.assertEqual(bc.rules(s), [])

    def test_a_small_picture_is_centred(self):
        small = np.zeros((100, 120, 4), np.uint8)
        small[40:60, 10:110] = (100, 110, 120, 255)
        self.assertEqual(bc.fit_frame(small).shape, (bc.FRAME, bc.FRAME, 4))
        with self.assertRaises(ValueError):
            bc.fit_frame(np.zeros((130, 128, 4), np.uint8))
        with self.assertRaises(ValueError):
            bc.split_strip(np.zeros((128, 300, 4), np.uint8))


class InstallTest(unittest.TestCase):
    def test_install_crops_writes_and_points_textures(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            props = d / "props.json"
            shutil.copyfile(bc.PROPS_JSON, props)
            strip = d / "strip.png"
            Image.fromarray(bc.make_strip(car(True), True, car(False), True), "RGBA").save(strip)
            t = bc.install("broken_car_2", strip, props_json=props, out_dir=d / "out")
            self.assertEqual(sorted(t), sorted(bc.ROTATIONS))
            data = json.loads(props.read_text(encoding="utf-8"))
            prop = next(p for p in data["props"] if p["id"] == "prop-broken-car-2")
            self.assertEqual(prop["textures"]["north"]["texture"], "res://art/props/broken_car_2_north_art.png")
            img = np.array(Image.open(d / "out" / "broken_car_2_north_art.png"))
            self.assertEqual(img.shape[:2], (30, 70))      # cropped to the car
            self.assertEqual(prop["textures"]["north"]["anchor_px"], [34, max(0, 29 - bc.BASE_UP)])
            # the other props are untouched
            before = json.loads(bc.PROPS_JSON.read_text(encoding="utf-8"))
            for a, b in zip(before["props"], data["props"]):
                if a["id"] != "prop-broken-car-2":
                    self.assertEqual(a, b)
            with self.assertRaises(ValueError):
                bc.install("bus", strip, props_json=props, out_dir=d / "out")

    def test_anchor_is_above_the_lowest_row(self):
        a = np.zeros((80, 100, 4), np.uint8)
        a[10:76, 5:95] = (1, 2, 3, 255)
        self.assertEqual(bc.anchor_for(a), [49, 75 - bc.BASE_UP])

    def test_check_fails_without_the_kept_strips(self):
        with tempfile.TemporaryDirectory() as d:
            kept = {m: Path(d) / ("%s.png" % m) for m in bc.MODELS}
            self.assertEqual(bc.check(kept=kept), 1)


class RequestTest(unittest.TestCase):
    def test_rotate_request_carries_the_picture_and_its_palette(self):
        with tempfile.TemporaryDirectory() as d:
            png = Path(d) / "c.png"
            Image.fromarray(car(), "RGBA").save(png)
            req = bc.rotate_request(png, seed=7)
            self.assertEqual(base64.b64decode(req["from_image"]["base64"]), png.read_bytes())
            self.assertEqual(req["color_image"], req["from_image"])
            self.assertEqual((req["from_direction"], req["to_direction"]), ("north-east", "south-west"))
            self.assertTrue(req["isometric"])
            self.assertEqual(req["image_size"], {"width": 128, "height": 128})
            self.assertEqual(req["seed"], 7)
            self.assertNotIn("description", req)
            r8 = bc.rotations_request(png, "a car")
            self.assertEqual(base64.b64decode(r8["first_frame"]["base64"]), png.read_bytes())
            self.assertEqual((r8["description"], r8["no_background"]), ("a car", True))


class PreviewTest(unittest.TestCase):
    def test_preview_files(self):
        with tempfile.TemporaryDirectory() as d:
            strip = Path(d) / "s.png"
            Image.fromarray(bc.make_strip(car(True), True, car(False), True), "RGBA").save(strip)
            bc.preview(strip, Path(d) / "p")
            for f in ("preview_side_by_side.png", "preview_dark.png", "preview_light.png", "footprints.png",
                      "strip_4x.png"):
                self.assertTrue((Path(d) / "p" / f).is_file(), f)


if __name__ == "__main__":
    unittest.main()
