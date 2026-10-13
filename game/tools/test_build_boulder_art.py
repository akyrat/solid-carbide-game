"""Tests for build_boulder_art.py (T-065). Run: python -m unittest discover -s game/tools -p "test_*.py"."""
import json
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PIL import Image  # noqa: E402

import build_boulder_art as ba  # noqa: E402


class HullTest(unittest.TestCase):
    def test_square_hull(self):
        pts = [(0, 0), (2, 0), (2, 2), (0, 2), (1, 1)]
        self.assertEqual(sorted(ba.convex_hull(pts)), [(0, 0), (0, 2), (2, 0), (2, 2)])

    def test_opaque_hull_covers_a_pixel_block(self):
        img = Image.new("RGBA", (6, 6), (0, 0, 0, 0))
        for x in range(1, 4):
            for y in range(2, 5):
                img.putpixel((x, y), (9, 9, 9, 255))
        self.assertEqual(sorted(tuple(p) for p in ba.opaque_hull(img)), [(1, 2), (1, 5), (4, 2), (4, 5)])


class BuildTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.files = ba.build(mirrors=True)
        cls.manifest = json.loads(cls.files[ba.MANIFEST])

    def test_committed_files_are_a_fresh_build(self):
        self.assertEqual(ba.differences(self.files), [])

    def test_four_variants_with_mirrors_two_without(self):
        self.assertEqual([v["id"] for v in self.manifest["variants"]], ["a", "a_mirror", "b", "b_mirror"])
        plain = json.loads(ba.build(mirrors=False)[ba.MANIFEST])
        self.assertEqual([v["id"] for v in plain["variants"]], ["a", "b"])

    def test_variant_a_is_the_approved_sample_pixel_for_pixel(self):
        src = Image.open(os.path.join(ba.REPO, "art-archive", "T-065", "boulder_sample_nobase.png")).convert("RGBA")
        self.assertEqual(list(self.files["boulder_a.png"].getdata()), list(src.getdata()))

    def test_variant_b_is_the_approved_sample_padded_on_top(self):
        src = Image.open(os.path.join(ba.REPO, "art-archive", "T-065", "boulder_sample2.png")).convert("RGBA")
        out = self.files["boulder_b.png"]
        self.assertEqual(out.size, (ba.FRAME, ba.FRAME))
        crop = out.crop((0, ba.PAD_TOP, ba.FRAME, ba.FRAME))
        self.assertEqual(list(crop.getdata()), list(src.getdata()))
        top = out.crop((0, 0, ba.FRAME, ba.PAD_TOP))
        self.assertTrue(all(p[3] == 0 for p in top.getdata()))

    def test_mirrors_are_flipped_copies(self):
        for v in ("a", "b"):
            flipped = self.files["boulder_%s.png" % v].transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            self.assertEqual(list(self.files["boulder_%s_mirror.png" % v].getdata()), list(flipped.getdata()))

    def test_sprite_rules(self):
        for name, img in self.files.items():
            if isinstance(img, str):
                continue
            alphas = {p[3] for p in img.getdata()}
            self.assertLessEqual(alphas, {0, 255}, name)
            self.assertLessEqual(ba.colours(img), 30, name)
            self.assertEqual(img.getpixel((0, 0))[3], 0, name)

    def test_manifest_bbox_and_hull_match_the_pixels(self):
        for v in self.manifest["variants"]:
            img = self.files[os.path.basename(v["texture"])]
            self.assertEqual(tuple(v["bbox"]), ba.opaque_bbox(img))
            xs = [p[0] for p in v["hull"]]
            ys = [p[1] for p in v["hull"]]
            self.assertEqual((min(xs), min(ys), max(xs), max(ys)), tuple(v["bbox"]))

    def test_records_name_their_sources(self):
        for name, v in self.files.items():
            if name.endswith(".json") and name != ba.MANIFEST:
                rec = json.loads(v)
                self.assertTrue(rec["source"].startswith("art-archive/T-065/"))
                self.assertTrue(any("PixelLab" in h for h in rec["history"]))


if __name__ == "__main__":
    unittest.main()
