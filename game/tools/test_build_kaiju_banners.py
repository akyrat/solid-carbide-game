"""Tests for build_kaiju_banners.py (task T-130, road-sign version). Run with the Python tool tests."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_kaiju_banners as b  # noqa: E402


def colours(rows):
    return {p[:3] for r in rows for p in r if p[3]}


class SpriteTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sprites = b.sprites()

    def test_six_sprites_two_designs_three_forms(self):
        self.assertEqual(len(self.sprites), 6)
        infos = [i for _, i in self.sprites.values()]
        self.assertEqual({(i["design"], i["shape"]) for i in infos}, {("head", "triangle"), ("body", "circle")})
        self.assertEqual({i["kind"] for i in infos}, {"building", "pavement"})
        self.assertEqual(len([i for i in infos if i["form"].startswith("sheared")]), 2)

    def test_every_rule_passes_for_every_sprite(self):
        for name, (rows, _) in self.sprites.items():
            self.assertEqual([r for r in b.check_rows(rows) if not r[1]], [], name)

    def test_sizes(self):
        for name, (rows, _) in self.sprites.items():
            self.assertEqual((len(rows[0]), len(rows)), b.expected_size(name), name)

    def test_only_opaque_or_transparent_and_transparent_corners(self):
        for name, (rows, _) in self.sprites.items():
            self.assertTrue({p[3] for r in rows for p in r} <= {0, 255}, name)
            for y, x in ((0, 0), (0, len(rows[0]) - 1)):
                self.assertEqual(rows[y][x][3], 0, name)

    def test_only_five_allowed_colours_and_the_sign_red_is_the_only_red(self):
        for name, (rows, _) in self.sprites.items():
            cs = colours(rows)
            self.assertTrue(cs <= b.ALLOWED, name)
            self.assertIn(b.SIGN_RED, cs, name)
            for c in cs - {b.SIGN_RED}:
                self.assertFalse(b.marks.is_redgull_red(c), (name, c))

    def test_building_signs_are_only_red_white_and_black(self):
        for name, (rows, info) in self.sprites.items():
            if info["kind"] == "building":
                self.assertEqual(colours(rows), {b.SIGN_RED, b.WHITE, b.BLACK}, name)

    def test_silhouette_is_black_inside_white_and_never_touches_the_red(self):
        for design in b.SHAPES:
            for kind in ("building", "pavement"):
                cells, w, h = b.board(design, kind)
                black = {p for p, v in cells.items() if v == "K"}
                self.assertTrue(black)
                for x, y in black:
                    for dx in (-1, 0, 1):
                        for dy in (-1, 0, 1):
                            self.assertNotEqual(cells.get((x + dx, y + dy)), "R", (design, kind, x, y))

    def test_designs_differ(self):
        self.assertNotEqual(self.sprites["kaiju_head_triangle_sign.png"][0], self.sprites["kaiju_body_circle_sign.png"][0])


class ShearTest(unittest.TestCase):
    def test_columns_slide_down_one_pixel_per_two_across(self):
        rows = [[(1, 1, 1, 255)] * 8 for _ in range(4)]
        out = b.shear(rows)
        self.assertEqual(len(out), 4 + 3)
        for x in range(8):
            ys = [y for y in range(len(out)) if out[y][x][3]]
            self.assertEqual(ys, list(range(x // 2, x // 2 + 4)))

    def test_shear_keeps_the_pixels(self):
        s = b.sprites()
        count = lambda r: sum(1 for row in r for p in row if p[3])
        self.assertEqual(count(s["kaiju_body_circle_building_front.png"][0]), count(s["kaiju_body_circle_building_wall.png"][0]))


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
            self.assertEqual(len(rec["files"]), 6)

    def test_check_fails_on_a_semi_transparent_pixel(self):
        rows = [r[:] for r in b.sprites()["kaiju_head_triangle_sign.png"][0]]
        rows[40][24] = (10, 10, 10, 128)
        self.assertTrue([r for r in b.check_rows(rows) if not r[1]])

    def test_check_fails_on_redgull_red_and_on_a_neon_colour(self):
        for bad in ((219, 26, 41, 255), (40, 190, 220, 255)):
            rows = [r[:] for r in b.sprites()["kaiju_head_triangle_sign.png"][0]]
            rows[40][24] = bad
            self.assertTrue([r for r in b.check_rows(rows) if not r[1]], bad)

    def test_previews_are_written(self):
        with tempfile.TemporaryDirectory() as t:
            b.previews(None, Path(t))
            self.assertEqual(len(list(Path(t).glob("*.png"))), 3)


if __name__ == "__main__":
    unittest.main()
