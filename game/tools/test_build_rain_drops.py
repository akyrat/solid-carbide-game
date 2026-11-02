"""Tests for build_rain_drops.py (T-509)."""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import build_rain_drops as brd  # noqa: E402


class RainDropsTest(unittest.TestCase):
    def setUp(self):
        self.sheet = brd.build_sheet()

    def frame(self, i):
        return self.sheet.crop((i * 8, 0, i * 8 + 8, 16))

    def test_size_and_mode(self):
        self.assertEqual(self.sheet.size, (24, 16))
        self.assertEqual(self.sheet.mode, "RGBA")

    def test_alpha_is_binary(self):
        self.assertTrue(all(a in (0, 255) for a in self.sheet.getchannel("A").getdata()))

    def test_corners_transparent_and_each_frame_has_a_drop(self):
        for i in range(3):
            f = self.frame(i)
            for c in [(0, 0), (7, 0), (0, 15), (7, 15)]:
                self.assertEqual(f.getpixel(c)[3], 0, (i, c))
            self.assertIsNotNone(f.getbbox())

    def test_colour_count(self):
        cols = {p for p in self.sheet.getdata() if p[3] == 255}
        self.assertLessEqual(len(cols), 12)

    def test_top_leans_right(self):
        for i in range(3):
            f = self.frame(i)
            rows = [y for y in range(16) if any(f.getpixel((x, y))[3] for x in range(8))]
            top_x = max(x for x in range(8) if f.getpixel((x, rows[0]))[3])
            bot_x = min(x for x in range(8) if f.getpixel((x, rows[-1]))[3])
            self.assertGreater(top_x, bot_x)
            self.assertLessEqual(top_x - bot_x, 6)

    def test_variant_shapes(self):
        def count(i):
            return sum(1 for p in self.frame(i).getdata() if p[3])
        self.assertGreater(count(1), count(0))  # thicker, longer
        self.assertLess(count(2), count(0))     # short

    def test_head_lighter_than_tail(self):
        for i in range(3):
            f = self.frame(i)
            px = [(y, f.getpixel((x, y))) for y in range(16) for x in range(8) if f.getpixel((x, y))[3]]
            head, tail = px[0][1], px[-1][1]
            self.assertGreater(sum(head[:3]), sum(tail[:3]))

    def test_no_greenbull_colours(self):
        banned = {(12, 76, 44), (104, 220, 96), (247, 208, 52)}
        self.assertFalse({p[:3] for p in self.sheet.getdata() if p[3]} & banned)


if __name__ == "__main__":
    unittest.main()
