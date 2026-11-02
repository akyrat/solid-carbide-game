"""Tests for build_rain_drops_v3.py (T-509, style loop version 3)."""
import os
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, os.path.dirname(__file__))
import build_rain_drops_v3 as brd  # noqa: E402


class RainDropsV3Test(unittest.TestCase):
    def setUp(self):
        self.sheet = brd.build_sheet()

    def frame(self, i):
        return self.sheet.crop((i * 8, 0, i * 8 + 8, 16))

    def opaque(self, i):
        f = self.frame(i)
        return [(x, y, f.getpixel((x, y))) for y in range(16) for x in range(8) if f.getpixel((x, y))[3]]

    def test_size_alpha_colours(self):
        self.assertEqual(self.sheet.size, (24, 16))
        self.assertEqual(self.sheet.mode, "RGBA")
        self.assertTrue(all(a in (0, 255) for a in self.sheet.getchannel("A").getdata()))
        self.assertLessEqual(len({p for p in self.sheet.getdata() if p[3]}), 12)

    def test_corners_transparent(self):
        for i in range(3):
            for c in [(0, 0), (7, 0), (0, 15), (7, 15)]:
                self.assertEqual(self.frame(i).getpixel(c)[3], 0, (i, c))

    def test_continuous_and_lean(self):
        for i, (min_rows, lean) in enumerate([(15, 5), (15, 5), (8, 3)]):
            px = self.opaque(i)
            rows = sorted({y for _, y, _ in px})
            self.assertEqual(rows, list(range(rows[0], rows[-1] + 1)))  # no gaps
            self.assertGreaterEqual(len(rows), min_rows)
            top_x = max(x for x, y, _ in px if y == rows[0])
            bot_x = min(x for x, y, _ in px if y == rows[-1])
            self.assertEqual(top_x - bot_x, lean)
            self.assertLessEqual(max(sum(1 for _, y, _ in px if y == r) for r in rows), 2)  # slim

    def test_head_bright_tail_not_too_dark(self):
        for i in range(3):
            px = self.opaque(i)
            head, tail = px[0][2], px[-1][2]
            self.assertGreater(sum(head[:3]), 700)
            self.assertGreater(sum(head[:3]), sum(tail[:3]))
            self.assertGreaterEqual(min(sum(p[:3]) for _, _, p in px), 300)

    def test_never_overwrites(self):
        out = Path(tempfile.mkdtemp()) / "v.png"
        self.assertEqual(brd.main([str(out)]), 0)
        self.assertEqual(brd.main([str(out)]), 1)


if __name__ == "__main__":
    unittest.main()
