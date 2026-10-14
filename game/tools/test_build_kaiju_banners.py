"""Tests for build_kaiju_banners.py (task T-130). Run with the Python tool tests."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_kaiju_banners as b  # noqa: E402
import check_sprite_rules as rules  # noqa: E402


class SpriteTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sprites = b.sprites()

    def test_twelve_sprites_four_designs_two_colours(self):
        self.assertEqual(len(self.sprites), 12)
        infos = [i for _, i in self.sprites.values()]
        self.assertEqual({(i["design"], i["kind"]) for i in infos}, {(d, k) for d in ("head", "body") for k in ("building", "pavement")})
        self.assertEqual({i["colour"] for i in infos}, {"cyan", "pink"})

    def test_every_rule_passes_for_every_sprite(self):
        for name, (rows, _) in self.sprites.items():
            self.assertEqual([r for r in b.check_rows(rows) if not r[1]], [], name)

    def test_sizes(self):
        for name, (rows, _) in self.sprites.items():
            self.assertEqual((len(rows[0]), len(rows)), b.expected_size(name), name)

    def test_only_opaque_or_transparent_and_transparent_corners(self):
        for name, (rows, _) in self.sprites.items():
            self.assertTrue({p[3] for r in rows for p in r} <= {0, 255}, name)
            self.assertEqual(rows[0][0][3], 0, name)
            self.assertEqual(rows[-1][0][3], 0, name)

    def test_colours_few_and_far_from_redgull_red(self):
        for name, (rows, _) in self.sprites.items():
            colors = {p[:3] for r in rows for p in r if p[3]}
            self.assertLessEqual(len(colors), 30, name)
            for c in colors:
                self.assertFalse(b.marks.is_redgull_red(c), (name, c))
                dist = sum((x / 255 - y) ** 2 for x, y in zip(c, b.HEART_COLOR)) ** 0.5
                self.assertGreaterEqual(dist, 0.5, (name, c))

    def test_colourways_differ_and_do_not_mix(self):
        cyan = {p[:3] for r in self.sprites["kaiju_head_building_cyan_front.png"][0] for p in r if p[3]}
        pink = {p[:3] for r in self.sprites["kaiju_head_building_pink_front.png"][0] for p in r if p[3]}
        self.assertTrue(set(b.COLOURWAYS["cyan"].values()) & cyan)
        self.assertFalse(set(b.COLOURWAYS["pink"].values()) & cyan)
        self.assertFalse(set(b.COLOURWAYS["cyan"].values()) & pink)

    def test_designs_differ(self):
        self.assertNotEqual(self.sprites["kaiju_head_sign_cyan.png"][0], self.sprites["kaiju_body_sign_cyan.png"][0])
        self.assertNotEqual(self.sprites["kaiju_head_building_cyan_front.png"][0], self.sprites["kaiju_body_building_cyan_front.png"][0])


class ShearTest(unittest.TestCase):
    def test_columns_slide_down_one_pixel_per_two_across(self):
        rows = [[(1, 1, 1, 255)] * 8 for _ in range(4)]
        out = b.shear(rows)
        self.assertEqual(len(out), 4 + 3)
        for x in range(8):
            ys = [y for y in range(len(out)) if out[y][x][3]]
            self.assertEqual(ys, list(range(x // 2, x // 2 + 4)))

    def test_shear_keeps_the_pixels(self):
        rows = b.sprites()["kaiju_body_building_pink_front.png"][0]
        wall = b.shear(rows)
        count = lambda r: sum(1 for row in r for p in row if p[3])
        self.assertEqual(count(rows), count(wall))


class BuildTest(unittest.TestCase):
    def test_build_is_deterministic_and_checks_pass(self):
        with tempfile.TemporaryDirectory() as t1, tempfile.TemporaryDirectory() as t2:
            b.build(Path(t1), None)
            b.build(Path(t2), None)
            for name in b.sprites():
                self.assertEqual((Path(t1) / name).read_bytes(), (Path(t2) / name).read_bytes())
            ok, lines = b.check_dir(Path(t1))
            self.assertTrue(ok, lines)
            rec = json.loads((Path(t1) / "banners.json").read_text(encoding="utf-8"))
            self.assertEqual(rec["pixellab_calls"], 0)
            self.assertEqual(len(rec["files"]), 12)

    def test_check_fails_on_a_semi_transparent_pixel(self):
        rows = [r[:] for r in b.sprites()["kaiju_head_sign_cyan.png"][0]]
        rows[10][10] = (10, 10, 10, 128)
        self.assertTrue([r for r in b.check_rows(rows) if not r[1]])

    def test_check_fails_on_redgull_red(self):
        rows = [r[:] for r in b.sprites()["kaiju_head_sign_cyan.png"][0]]
        rows[10][10] = (219, 26, 41, 255)
        self.assertTrue([r for r in b.check_rows(rows) if not r[1]])

    def test_previews_are_written(self):
        with tempfile.TemporaryDirectory() as t:
            b.previews(None, Path(t))
            self.assertEqual(len(list(Path(t).glob("*.png"))), 3)


if __name__ == "__main__":
    unittest.main()
