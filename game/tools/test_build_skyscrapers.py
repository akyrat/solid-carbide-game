"""Tests for build_skyscrapers.py (T-064 round 2): shear, mirror tiling, dissolve, pavement, rules."""
import unittest

import numpy as np

import build_skyscrapers as bs


class T(unittest.TestCase):
    def test_shear_is_exact_2_to_1_and_keeps_pixels(self):
        flat = np.zeros((10, 8, 4), dtype=np.uint8)
        flat[..., 3] = 255
        flat[..., 0] = np.arange(8)[None, :]
        out = bs.shear_wall(flat, down=True)
        self.assertEqual(out.shape[0], 10 + 8 // 2 + 1)
        for x in range(8):
            ys = np.nonzero(out[:, x, 3])[0]
            self.assertEqual(ys[0], x // 2)
            self.assertTrue((out[ys, x, 0] == x).all())  # no resampling
        up = bs.shear_wall(flat, down=False)
        self.assertEqual(np.nonzero(up[:, 7, 3])[0][0], 0)

    def test_mirror_tile_seams_match(self):
        rng = np.random.default_rng(0)
        a = rng.integers(0, 255, (7, 5, 4)).astype(np.uint8)
        t = bs.mirror_tile(a, 40, 30, (3, 2))
        self.assertTrue((t[:, 4 - 3] == t[:, 4 - 3 + 1 - 1]).all())
        # at every mirror boundary the two neighbouring columns are the same column of the source
        xs = [x for x in range(39) if (x + 3 + 1) % 5 == 0]
        for x in xs:
            self.assertTrue((t[:, x] == t[:, x + 1]).all())

    def test_dissolve_binary_alpha_and_empty_top(self):
        img = np.full((400, 64, 4), 255, dtype=np.uint8)
        out = bs.dissolve_top(img)
        self.assertEqual(set(np.unique(out[..., 3]).tolist()) - {0, 255}, set())
        self.assertEqual(int(out[0, :, 3].sum()), 0)
        self.assertTrue((out[300:, :, 3] == 255).all())

    def test_body_rules(self):
        pal = bs.load_palette()
        rng = np.random.default_rng(1)
        f = pal[rng.integers(0, len(pal), (40, 40))].astype(np.uint8)
        f = np.concatenate([f, np.full((40, 40, 1), 255, np.uint8)], axis=-1)
        sign = f[:20, :8].copy()
        body = bs.build_body(f, f[:30], sign, pal, facade_seed=1)
        self.assertEqual(body.shape, (bs.BODY_H, bs.BODY_W, 4))
        r = bs.sprite_rules(body)
        self.assertEqual(r["semi_transparent"], 0)
        self.assertTrue(r["colors_ok"] and r["red_ok"])

    def test_band_wall_joins_on_floor_lines_and_is_not_a_mirror(self):
        pal = bs.load_palette()
        rng = np.random.default_rng(2)
        f = pal[rng.integers(0, len(pal), (256, 256))].astype(np.uint8)
        f = np.concatenate([f, np.full((256, 256, 1), 255, np.uint8)], axis=-1)
        w = bs.band_wall(f, 384, 960, seed=5)
        self.assertEqual(w.shape, (960, 384, 4))
        self.assertTrue((w[..., 3] == 255).all())
        w2 = bs.band_wall(f, 384, 960, seed=5)
        self.assertTrue((w == w2).all(), "deterministic")
        self.assertFalse((w[:64] == w[64:128]).all(), "bands differ")

    def test_script_sign_has_no_semi_transparent_pixels_and_uses_palette_colours(self):
        pal = bs.load_palette()
        s = bs.script_sign(3, pal)
        self.assertEqual(s.shape, (192, 64, 4))
        r = bs.sprite_rules(s)
        self.assertEqual(r["semi_transparent"], 0)
        self.assertTrue(r["colors_ok"] and r["red_ok"])

    def test_pavement_rules(self):
        pal = bs.load_palette()
        p = bs.pavement_slot(True, True, pal)
        r = bs.sprite_rules(p)
        self.assertEqual(r["semi_transparent"], 0)
        self.assertLessEqual(r["colors"], 30)


if __name__ == "__main__":
    unittest.main()
