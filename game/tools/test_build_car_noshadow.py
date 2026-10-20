"""Tests for build_car_noshadow.py (task T-204). Run: python -m unittest discover -s game/tools -p "test_*.py" """
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_car_noshadow as b  # noqa: E402

SRC = b.SRC_PNG
OUT = b.DST_PNG


class CarNoShadowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.w, cls.h, cls.src = b.read_png(SRC)
        cls.rec = json.loads(SRC.with_suffix(".json").read_text(encoding="utf-8"))
        cls.fw = cls.rec["frame_width"]
        cls.out, cls.gone = b.remove_shadow(cls.src, cls.fw)

    def test_same_size_and_record_fields(self):
        w, h, _ = b.read_png(OUT)
        self.assertEqual((w, h), (self.w, self.h))
        new = json.loads(OUT.with_suffix(".json").read_text(encoding="utf-8"))
        for k, v in self.rec.items():
            if k != "file":
                self.assertEqual(new[k], v, k)
        self.assertEqual(new["file"], "car_iso_noshadow.png")

    def test_committed_sheet_matches_the_script(self):
        _, _, committed = b.read_png(OUT)
        self.assertEqual(committed, self.out)

    def test_rerun_is_byte_identical(self):
        with tempfile.TemporaryDirectory() as d:
            a, c = Path(d) / "a" / "x.png", Path(d) / "b" / "x.png"
            for p in (a, c):
                p.parent.mkdir()
                p.parent.joinpath("x.json").write_bytes(SRC.with_suffix(".json").read_bytes())
                b.build(SRC, p)
            self.assertEqual(a.read_bytes(), c.read_bytes())
            self.assertEqual(a.with_suffix(".json").read_bytes(), c.with_suffix(".json").read_bytes())
            self.assertEqual(a.read_bytes(), OUT.read_bytes())

    def test_only_removed_pixels_differ_and_become_transparent(self):
        changed = 0
        for y in range(self.h):
            for x in range(self.w):
                if self.out[y][x] != self.src[y][x]:
                    changed += 1
                    self.assertIn((x, y), self.gone)
                    self.assertEqual(self.out[y][x], (0, 0, 0, 0))
        self.assertEqual(changed, len(self.gone))
        self.assertGreater(changed, 500)

    def test_removed_pixels_are_opaque_near_black(self):
        for x, y in self.gone:
            p = self.src[y][x]
            self.assertEqual(p[3], 255)
            self.assertIn(tuple(p[:3]), b.SHADOW_COLOURS)

    def test_every_frame_loses_pixels_only_outside_its_hull(self):
        for f in range(self.rec["frame_count"]):
            x0 = f * self.fw
            lit = [(px, py) for py in range(self.h) for px in range(x0, x0 + self.fw)
                   if self.src[py][px][3] == 255 and tuple(self.src[py][px][:3]) not in b.SHADOW_COLOURS]
            hull = b.convex_hull(lit)
            for x, y in self.gone:
                if x0 <= x < x0 + self.fw:
                    self.assertFalse(b.in_hull(hull, (x, y)), (f, x, y))

    def test_non_dark_pixels_never_touched(self):
        for y in range(self.h):
            for x in range(self.w):
                p = self.src[y][x]
                if p[3] == 0 or tuple(p[:3]) not in b.SHADOW_COLOURS:
                    self.assertEqual(self.out[y][x], p)

    def test_no_new_colours(self):
        self.assertLessEqual(set(map(tuple, sum(self.out, []))), set(map(tuple, sum(self.src, []))))

    def test_no_semi_transparent_pixels(self):
        self.assertTrue(all(p[3] in (0, 255) for r in self.out for p in r))

    def test_original_sheet_unchanged_by_build(self):
        before = SRC.read_bytes()
        with tempfile.TemporaryDirectory() as d:
            (Path(d) / "x.json").write_bytes(SRC.with_suffix(".json").read_bytes())
            b.build(SRC, Path(d) / "x.png")
        self.assertEqual(SRC.read_bytes(), before)

    def test_car_body_survives_each_frame(self):
        # the shadow removal must not eat the car: at least 85% of each frame's opaque pixels stay
        for f in range(self.rec["frame_count"]):
            cols = range(f * self.fw, (f + 1) * self.fw)
            before = sum(1 for y in range(self.h) for x in cols if self.src[y][x][3])
            after = sum(1 for y in range(self.h) for x in cols if self.out[y][x][3])
            self.assertGreater(after, 0.85 * before, f)

    def test_hull_helpers(self):
        hull = b.convex_hull([(0, 0), (4, 0), (4, 4), (0, 4), (2, 2)])
        self.assertTrue(b.in_hull(hull, (2, 2)))
        self.assertTrue(b.in_hull(hull, (4, 4)))
        self.assertFalse(b.in_hull(hull, (5, 2)))


if __name__ == "__main__":
    unittest.main()
