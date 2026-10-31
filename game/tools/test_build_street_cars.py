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


class TouchUpTest(unittest.TestCase):
    def test_dull_paint_greys_pale_paint_only(self):
        a = car()
        a[50:60, 30:90] = (250, 245, 205, 255)                 # warm cream
        out, n = bc.dull_paint(a, lum_min=200.0)
        self.assertEqual(n, 10 * 60)
        r, g, b = (int(v) for v in out[52, 40, :3])
        self.assertLess(r - b, 250 - 205)                       # less yellow
        self.assertTrue(np.array_equal(out[70, 50], a[70, 50]))  # mid grey untouched
        self.assertTrue(np.array_equal(out[..., 3], a[..., 3]))

    def test_dark_outline_on_light_silhouette_edge(self):
        a = car()
        a[50, 30:100] = (240, 240, 230, 255)
        out, n = bc.dark_outline(a)
        self.assertGreater(n, 0)
        self.assertEqual(tuple(out[50, 60, :3]), bc.OUTLINE)
        self.assertTrue(np.array_equal(out[60, 60], a[60, 60]))  # inside stays

    def test_rear_lamps_red_inside_box_not_on_edge(self):
        a = car()
        out, n = bc.paint_rear_lamps(a, [(29, 60, 34, 64)])
        self.assertTrue(bc.lamp_red(out)[62, 32])
        self.assertFalse(bc.lamp_red(out)[62, 30])              # the silhouette edge stays
        self.assertFalse(bc.lamp_red(out)[70, 60])
        self.assertEqual(n, 4 * 5)

    def test_flatten_makes_one_colour(self):
        a = car()
        a[60:64, 50:54] = [[(i * 30, 0, 0, 255) for i in range(4)]] * 4
        out = bc.flatten(a, [(50, 60, 53, 63)])
        self.assertEqual(len({tuple(c) for c in out[60:64, 50:54].reshape(-1, 4).tolist()}), 1)

    def test_strip_keeps_red_lamps_through_the_palette(self):
        rng = np.random.default_rng(2)
        a, b = car(), car(False)
        a[50:80, 30:100, :3] = rng.integers(0, 255, (30, 70, 1))   # many greys, no reds
        a[60:62, 31:33] = (196, 52, 52, 255)
        s = bc.make_strip(a, True, b, True)
        self.assertEqual(bc.rules(s), [])
        self.assertEqual(tuple(bc.split_strip(s)["north"][60, 31, :3]), (196, 52, 52))


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

    def test_committed_cars_match_their_kept_strips(self):
        self.assertEqual(bc.check(), 0)

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


class RepaintFrontTest(unittest.TestCase):
    def test_front_lamps_turn_grey_and_rear_lamps_stay_red(self):
        a = np.zeros((40, 80, 4), np.uint8)
        a[10:30, 10:70] = (150, 160, 170, 255)
        a[26:29, 12:16] = (140, 30, 84, 255)    # lower left: the front, nose bottom-left
        a[11:14, 64:68] = (140, 30, 84, 255)    # upper right: the rear
        out, n = bc.repaint_front(a, "bottom-left")
        self.assertEqual(n, 12)
        self.assertFalse(bc.lamp_red(out[24:30, 10:18]).any())
        self.assertTrue(bc.lamp_red(out[11:14, 64:68]).all())
        r, g, b = (int(v) for v in out[27, 13, :3])
        self.assertTrue(abs(r - g) <= 10 and abs(g - b) <= 10, (r, g, b))
        self.assertTrue(np.array_equal(out[15, 40], a[15, 40]))
        out2, n2 = bc.repaint_front(a, "top-right")
        self.assertEqual(n2, 12)
        self.assertTrue(bc.lamp_red(out2[26:29, 12:16]).all())


class WreckTest(unittest.TestCase):
    def picture(self):
        a = np.zeros((60, 80, 4), np.uint8)
        a[10:50, 10:70] = (226, 232, 214, 255)        # pale paint
        a[14:26, 40:64] = (60, 74, 120, 255)          # glass (blue)
        a[42:50, 14:24] = (30, 30, 40, 255)           # tyre
        a[44:47, 17:21] = (150, 160, 180, 255)        # hub
        return a

    def test_dusty_paint_is_darker_warmer_and_leaves_glass(self):
        a = self.picture()
        out, n = bc.dusty_paint(a)
        self.assertGreater(n, 0)
        r, g, b = (int(v) for v in out[30, 30, :3])
        self.assertLess(r, 226)
        self.assertTrue(r >= g >= b, (r, g, b))
        self.assertTrue(np.array_equal(out[20, 50], a[20, 50]))

    def test_dark_grey_paint_is_dull_dark_and_leaves_glass_and_red_lamps(self):
        a = self.picture()
        a[30:33, 12:15] = (196, 52, 52, 255)          # a red rear lamp
        a[35, 35] = (110, 170, 190, 255)               # teal mid paint
        a[14:26, 40:64] = (30, 34, 70, 255)            # dark glass
        a[45, 60] = (40, 60, 110, 255)                 # navy body shadow: painted, not glass
        out, n = bc.dark_grey_paint(a)
        r, g, b = (int(v) for v in out[45, 60, :3])
        self.assertLessEqual(b - r, 12)                # a cool steel grey at most, not navy
        self.assertGreater(n, 0)
        r, g, b = (int(v) for v in out[30, 30, :3])
        self.assertLessEqual(max(r, g, b), 160)        # pale highlight capped: dull, not lit
        self.assertLessEqual(max(r, g, b) - min(r, g, b), 12)   # nearly no colour: grey
        r, g, b = (int(v) for v in out[35, 35, :3])
        self.assertLessEqual(max(r, g, b) - min(r, g, b), 14)
        self.assertLess(0.299 * r + 0.587 * g + 0.114 * b, 110)  # darker than the teal it was
        self.assertTrue(np.array_equal(out[20, 50], a[20, 50]))  # glass stays
        self.assertTrue(np.array_equal(out[31, 13], a[31, 13]))  # red lamp stays
        self.assertTrue(np.array_equal(out[..., 3], a[..., 3]))

    def test_missing_wheel_leaves_a_dark_arch_and_a_drum(self):
        a = self.picture()
        out, n = bc.missing_wheel(a, (14, 42, 23, 49))
        self.assertGreater(n, 0)
        self.assertFalse(np.all(out[44:47, 17:21, :3] == (150, 160, 180), axis=2).any())   # the rim is gone
        cols = {tuple(c) for c in out[42:50, 14:24, :3].reshape(-1, 3).tolist()}
        self.assertIn(bc.OUTLINE, cols)
        self.assertTrue(cols & set(bc.DRUM))
        self.assertTrue(np.array_equal(out[:, 30:], a[:, 30:]))                            # only the box

    def test_paste_copies_rubble_onto_the_car(self):
        a = self.picture()
        a[52:56, 60:64] = (90, 90, 96, 255)            # a rubble lump on the ground
        out, n = bc.paste(a, (60, 52, 63, 55), (30, 12))
        self.assertEqual(n, 16)
        self.assertTrue(np.all(out[12:16, 30:34, :3] == (90, 90, 96)))
        self.assertTrue(np.array_equal(out[52:56, 60:64], a[52:56, 60:64]))               # the source stays
        _, n2 = bc.wreck(a, dusty=False, missing=[(14, 42, 23, 49)], rubble=[(60, 52, 63, 55, 30, 12)])
        self.assertIn("missing", n2)
        self.assertIn("rubble", n2)

    def test_clear_rubble_and_neutral_shadow(self):
        a = self.picture()
        a[50:58, 10:70] = (40, 26, 52, 255)            # purple ground shadow
        a[52:56, 60:64] = (180, 170, 200, 255)         # a lilac rubble lump on it
        a[52:56, 2:6] = (180, 170, 200, 255)           # a lump off the shadow
        out, n = bc.clear_rubble(a, a, (60, 52, 63, 55), shadow=True)
        self.assertEqual(n, 16)
        self.assertTrue(np.all(out[53, 61, :3] == (40, 26, 52)))
        out, _ = bc.clear_rubble(out, a, (2, 52, 5, 55))
        self.assertEqual(int(out[53, 3, 3]), 0)
        self.assertTrue(np.array_equal(out[30, 30], a[30, 30]))    # the car stays
        out, k = bc.neutral_shadow(out)
        self.assertGreater(k, 0)
        r, g, b = (int(v) for v in out[54, 30, :3])
        self.assertTrue(r <= g <= b and b - r <= 8, (r, g, b))    # neutral blue-grey, not purple
        _, n2 = bc.wreck(a, dusty=False, clears=[(60, 52, 63, 55, 1)], neutral=True)
        self.assertIn("clear", n2)
        self.assertIn("neutral", n2)

    def test_wreck_paint_option(self):
        a = self.picture()
        out, n = bc.wreck(a, paint="dark-grey")
        self.assertIn("dark-grey", n)
        self.assertNotIn("dusty", n)
        _, n2 = bc.wreck(a)
        self.assertIn("dusty", n2)
        _, n3 = bc.wreck(a, dusty=False)
        self.assertEqual(n3, {})

    def test_wreck_is_seeded_and_marks_only_inside_its_boxes(self):
        a = self.picture()
        kw = dict(crushes=[(12, 30, 36, 40)], cracks=[(40, 14, 63, 25)], scorches=[(44, 30, 60, 40)],
                  rusts=[(12, 12, 36, 28)], flats=[(14, 42, 23, 49)], dusty=False, seed=3)
        out, n = bc.wreck(a, **kw)
        out2, _ = bc.wreck(a, **kw)
        self.assertTrue(np.array_equal(out, out2))
        for kind in ("crush", "crack", "scorch", "rust", "flat"):
            self.assertGreater(n.get(kind, 0), 0, kind)
        changed = np.any(out != a, axis=2)
        self.assertFalse(changed[0:10].any())          # nothing above the car
        self.assertEqual(int(out[..., 3].max()), 255)
        self.assertTrue(set(np.unique(out[..., 3])) <= {0, 255})
        self.assertEqual(int(out[49, 12, 3]), 255)    # the bulge

    def test_flat_tyre_squashes_the_wheel_down(self):
        a = self.picture()
        out, n = bc.flat_tyre(a, (14, 38, 23, 49))
        self.assertGreater(n, 0)
        hub_rows = lambda p: {int(y) for y in np.nonzero(np.all(p[38:50, 14:24, :3] == (150, 160, 180), axis=2)
                                                          .any(axis=1))[0]}
        self.assertGreater(min(hub_rows(out)), min(hub_rows(a)))   # the hub comes out lower
        self.assertEqual(int(out[49, 11, 3]), 255)

    def test_dent_darkens_and_lights_the_panel_only_in_its_box(self):
        a = self.picture()
        out, n = bc.dent(a, (12, 28, 36, 40), np.random.default_rng(0))
        self.assertGreater(n, 0)
        changed = np.any(out != a, axis=2)
        self.assertFalse(changed[:, 45:].any())
        lum = bc._lum(out)[28:41, 12:37]
        self.assertLess(lum.min(), bc._lum(a)[30, 30] * 0.6)

    def test_rust_comes_in_clumps(self):
        a = self.picture()
        out, n = bc.rust(a, (12, 28, 60, 48), np.random.default_rng(0))
        self.assertGreater(n, 0)
        rusty = np.any(out != a, axis=2)
        ys, xs = np.nonzero(rusty)
        neighbours = sum(rusty[y, x + 1] or rusty[y + 1, x] for y, x in zip(ys, xs) if x + 1 < 80 and y + 1 < 60)
        self.assertGreater(neighbours / len(ys), 0.5)

    def test_crack_changes_only_glass(self):
        a = self.picture()
        out, n = bc.crack_glass(a, (10, 10, 69, 49), np.random.default_rng(1))
        self.assertGreater(n, 0)
        changed = np.any(out != a, axis=2)
        self.assertFalse((changed & ~bc._glass(a)).any())


if __name__ == "__main__":
    unittest.main()
