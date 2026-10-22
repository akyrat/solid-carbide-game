"""Tests for build_creator_textures_t255.py (T-255). They never call PixelLab."""
import os
import sys
import tempfile
import unittest

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_creator_textures_t255 as b  # noqa: E402


class T255TextureTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp()
        b.build(cls.tmp)

    def test_every_texture_is_written_at_the_right_size(self):
        for name in b.NAMES:
            with Image.open(os.path.join(self.tmp, name + ".png")) as im:
                self.assertEqual(im.mode, "RGBA")
                self.assertEqual(im.size, (128, 20) if name == "parapet" else (128, 128), name)

    def test_the_face_textures_are_opaque(self):
        for name in b.NAMES[:-1]:
            a = np.array(Image.open(os.path.join(self.tmp, name + ".png")))
            self.assertTrue((a[..., 3] == 255).all(), name)

    def test_the_sprite_rules_hold(self):
        self.assertEqual(b.check(self.tmp), 0)

    def test_the_build_is_the_same_every_time(self):
        other = tempfile.mkdtemp()
        b.build(other)
        for name in b.NAMES:
            self.assertEqual(open(os.path.join(self.tmp, name + ".png"), "rb").read(),
                             open(os.path.join(other, name + ".png"), "rb").read(), name)

    def test_the_committed_files_pass_the_rules(self):
        self.assertEqual(b.check(), 0)

    def test_the_wrapped_low_pass_removes_a_vignette(self):
        y, x = np.mgrid[0:128, 0:128]
        vignette = 120 + 80 * np.exp(-(((x - 64) ** 2 + (y - 64) ** 2) / 1500.0))
        a = np.repeat(vignette[..., None], 3, axis=2).astype(np.float32)
        flat = b.flatten(a, 20)
        self.assertLess(flat[..., 0].std(), a[..., 0].std() / 2)

    def test_the_mirrored_tile_has_no_seam(self):
        t = b.tile_mirror2(np.random.RandomState(1).rand(64, 64, 3).astype(np.float32) * 255)
        self.assertEqual(t.shape, (128, 128, 3))
        self.assertTrue(np.array_equal(t[:, 0], t[:, -1]))
        self.assertTrue(np.array_equal(t[0], t[-1]))

    def test_the_ramp_textures_tile_plainly_without_a_seam(self):
        for name in ["ramp_top", "ramp_side", "roof_top"]:
            wrap, inner = b.seam_score(os.path.join(self.tmp, name + ".png"))
            self.assertLessEqual(wrap, inner, name)

    def test_the_textures_stay_in_the_city_colours(self):
        for name in b.NAMES[:-1]:
            a = np.array(Image.open(os.path.join(self.tmp, name + ".png")).convert("RGB"), dtype=float)
            red = ((a[..., 0] > 110) & (a[..., 1] < 60) & (a[..., 2] < 70)).sum()
            self.assertEqual(red, 0, name)


if __name__ == "__main__":
    unittest.main()
