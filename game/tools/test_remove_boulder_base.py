"""Tests for remove_boulder_base.py (T-065). Run: python -m unittest discover -s game/tools -p "test_*.py"."""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PIL import Image  # noqa: E402

import remove_boulder_base as rb  # noqa: E402


class GeometryTest(unittest.TestCase):
    def test_point_in_polygon(self):
        square = [(0, 0), (10, 0), (10, 10), (0, 10)]
        self.assertTrue(rb.point_in_polygon(5, 5, square))
        self.assertFalse(rb.point_in_polygon(11, 5, square))

    def test_guide_radius_axes(self):
        a, b, _ = rb.GUIDE
        self.assertAlmostEqual(rb.guide_radius(0), a)
        self.assertAlmostEqual(rb.guide_radius(90), b)

    def test_anchors_replace_points_in_their_angle_range(self):
        edge = [(d, 10.0) for d in range(0, 91, 10)]
        cx, cy = rb.CENTER
        # One anchor straight to the right of the centre (angle 0) and one straight below (angle 90).
        anchors = [(int(cx + 19.5), int(cy - 0.5)), (int(cx - 0.5), int(cy + 19.5))]
        out = rb.apply_anchors(edge, anchors)
        self.assertEqual(len(out), 2)
        self.assertTrue(all(abs(r - 20.0) < 1.0 for _, r in out))


class CleanedSpriteTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.src, cls.out, cls.stats, cls.info = rb.build_all()

    def test_committed_file_is_a_fresh_build(self):
        committed = Image.open(rb.OUT).convert("RGBA")
        self.assertEqual(committed.size, self.out.size)
        self.assertEqual(committed.tobytes(), self.out.tobytes())

    def test_sprite_rules(self):
        self.assertEqual(self.out.size, (160, 160))
        alphas = {p[3] for p in self.out.getdata()}
        self.assertLessEqual(alphas, {0, 255})
        self.assertLessEqual(len(rb.colours(self.out)), 30)
        self.assertEqual(rb.colours(self.out) - rb.colours(self.src), set())
        px = self.out.load()
        for c in ((0, 0), (159, 0), (0, 159), (159, 159)):
            self.assertEqual(px[c][3], 0)

    def test_rows_above_the_disc_unchanged(self):
        s, o = self.src.load(), self.out.load()
        for y in range(rb.SPLIT_ROW):
            for x in range(160):
                self.assertEqual(s[x, y], o[x, y], (x, y))

    def test_below_the_split_only_original_pixels_or_outline(self):
        s, o = self.src.load(), self.out.load()
        for y in range(rb.SPLIT_ROW, 160):
            for x in range(160):
                if o[x, y][3] == 0:
                    continue
                self.assertEqual(s[x, y][3], 255, (x, y))
                self.assertIn(o[x, y], (s[x, y], rb.OUTLINE + (255,)), (x, y))

    def test_disc_is_gone(self):
        # The disc reached x 17..142 and y down to 137; the rock alone ends near row 119 and x 32..130.
        x0, y0, x1, y1 = rb.bbox(self.out)
        self.assertGreaterEqual(x0, 30)
        self.assertLessEqual(x1, 132)
        self.assertLessEqual(y1, 121)
        self.assertGreater(self.stats["removed_pixels"], 2500)

    def test_lower_edge_is_outline(self):
        o = self.out.load()
        keep = {(x, y) for y in range(160) for x in range(160) if o[x, y][3] == 255}
        # Every opaque pixel below the split whose 4-neighbour is outside (reachable from the border) is outline.
        outside, stack = set(), [(0, 0)]
        while stack:
            p = stack.pop()
            if p in outside or p in keep or not (0 <= p[0] < 160 and 0 <= p[1] < 160):
                continue
            outside.add(p)
            x, y = p
            stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
        for (x, y) in keep:
            if y >= rb.SPLIT_ROW and any(q in outside for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
                self.assertEqual(o[x, y][:3], rb.OUTLINE, (x, y))

    def test_one_connected_piece(self):
        o = self.out.load()
        keep = {(x, y) for y in range(160) for x in range(160) if o[x, y][3] == 255}
        start = next(iter(keep))
        seen, stack = {start}, [start]
        while stack:
            x, y = stack.pop()
            for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1), (x + 1, y + 1), (x - 1, y - 1), (x + 1, y - 1), (x - 1, y + 1)):
                if q in keep and q not in seen:
                    seen.add(q)
                    stack.append(q)
        self.assertEqual(len(seen), len(keep))


if __name__ == "__main__":
    unittest.main()
