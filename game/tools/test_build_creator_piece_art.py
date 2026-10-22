"""Tests for build_creator_piece_art.py (T-251). They never call PixelLab."""
import os
import sys
import tempfile
import unittest

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_creator_piece_art as b  # noqa: E402
import build_creator_assets as cat  # noqa: E402


class PieceArtTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp()
        b.build(cls.tmp)

    def test_the_five_face_textures_are_written(self):
        for name in b.TEXTURES:
            with Image.open(os.path.join(self.tmp, name + ".png")) as im:
                self.assertEqual(im.mode, "RGBA")
                self.assertEqual(im.size[0], 128)
        with Image.open(os.path.join(self.tmp, "parapet.png")) as im:
            self.assertEqual(im.size, (128, 20))

    def test_the_face_textures_are_opaque_tiles(self):
        for name in ["roof_top", "wall", "ramp_top", "ramp_side"]:
            a = np.array(Image.open(os.path.join(self.tmp, name + ".png")))
            self.assertTrue((a[..., 3] == 255).all(), name)

    def test_every_file_follows_the_sprite_rules(self):
        self.assertEqual(b.check(self.tmp), 0)

    def test_the_build_is_the_same_every_time(self):
        other = tempfile.mkdtemp()
        b.build(other)
        for f in sorted(os.listdir(self.tmp)):
            self.assertTrue(np.array_equal(np.array(Image.open(os.path.join(self.tmp, f))),
                                           np.array(Image.open(os.path.join(other, f)))), f)

    def test_an_icon_for_every_resizable_catalogue_entry(self):
        sample = cat.load("data/level/elevation_sample_map.json")
        for e in cat.elevation_entries(sample):
            self.assertIn(e["id"], b.ICONS)
            self.assertTrue(e["textures"][0]["texture"].endswith(b.icon_name(e["id"]) + ".png"))

    def test_the_committed_files_pass_the_check(self):
        self.assertEqual(b.check(), 0)


if __name__ == "__main__":
    unittest.main()
