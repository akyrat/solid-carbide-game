"""Tests for build_road_tile.py (task T-063). No PixelLab calls.

Run from the repo root:  python -m unittest discover -s game/tools -p "test_*.py"
"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_road_tile as b  # noqa: E402

T = (0, 0, 0, 0)
A = (30, 30, 40, 255)
W = (240, 240, 240, 255)


def diamond(w, h, fill=A):
    rows = []
    for y in range(h):
        r = []
        for x in range(w):
            d = abs(x + 0.5 - w / 2) / (w / 2) + abs(y + 0.5 - h / 2) / (h / 2)
            r.append(fill if d <= 1 else T)
        rows.append(r)
    return rows


class TileTests(unittest.TestCase):
    def test_squash_halves_height_and_adds_no_colours(self):
        rows = diamond(128, 128)
        rows[51][60] = W
        out = b.squash_half(rows)
        self.assertEqual((len(out[0]), len(out)), (128, 64))
        self.assertLessEqual({p for r in out for p in r}, {p for r in rows for p in r})

    def test_check_passes_a_clean_diamond(self):
        res = b.check_tile(diamond(128, 64))
        self.assertTrue(all(ok for _, ok, _ in res), res)

    def test_check_fails_semi_transparent_and_too_many_colours(self):
        rows = diamond(128, 64)
        rows[32][64] = (1, 2, 3, 128)
        self.assertFalse(dict((r, ok) for r, ok, _ in b.check_tile(rows))["no semi-transparent pixels"])
        rows = diamond(128, 64)
        for i in range(40):
            rows[32][30 + i] = (i, i, i, 255)
        self.assertFalse(dict((r, ok) for r, ok, _ in b.check_tile(rows))["about 30 colours or fewer"])

    def test_check_fails_stray_pixels_outside_the_diamond(self):
        rows = diamond(128, 64)
        rows[0][0] = A
        res = dict((r, ok) for r, ok, _ in b.check_tile(rows))
        self.assertFalse(res["no opaque pixels outside the diamond"])

    def test_paint_out_removes_the_line_only(self):
        rows = diamond(128, 64)
        rows[32][60] = W
        out = b.paint_out_lines(rows)
        self.assertEqual(out[32][60], A)

    def test_footprint_tiles_the_plane_exactly(self):
        full = [[A] * 128 for _ in range(64)]
        rows = [[p if b.footprint(x, y) else T for x, p in enumerate(r)] for y, r in enumerate(full)]
        self.assertEqual(b.tiling_report(rows), (0, 0))

    def test_remove_outline_replaces_dark_edge_pixels_and_fills_holes(self):
        rows = diamond(128, 64)
        rows[10][44] = (6, 6, 9, 255)       # a dark pixel at the edge of row 10 (x from 42)
        rows[10][51] = T                      # a hole inside the footprint
        out = b.remove_outline(rows)
        self.assertEqual(out[10][44], A)
        self.assertEqual(out[10][51], A)
        self.assertEqual(b.tiling_report(out), (0, 0))

    def test_brighten_line_uses_the_tiles_own_white_only(self):
        rows = diamond(128, 64)
        rows[32][60] = W
        rows[32][61] = (150, 150, 150, 255)
        out = b.brighten_line(rows)
        self.assertEqual(out[32][61], W)
        self.assertLessEqual({p for r in out for p in r}, {p for r in rows for p in r})

    def test_mockup_has_road_and_car(self):
        tile = diamond(128, 64)
        car = [[(200, 0, 0, 255)] * 8 for _ in range(8)]
        m = b.build_mockup(tile, car, (4.0, 4.0), road_units=4, length_tiles=2, line_col=0, car_col=0)
        flat = {p for r in m for p in r}
        self.assertIn((200, 0, 0, 255), flat)
        self.assertIn(A, flat)


if __name__ == "__main__":
    unittest.main()
