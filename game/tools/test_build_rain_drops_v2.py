"""Tests for build_rain_drops_v2.py (T-509), versions 2 and 3."""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import build_rain_drops_v2 as brd  # noqa: E402


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


class RainDropsTest(unittest.TestCase):
    version = 2
    min_lum = 100

    def setUp(self):
        self.sheet = brd.build_sheet(self.version)

    def frame(self, i):
        return self.sheet.crop((i * 8, 0, i * 8 + 8, 16))

    def opaque(self, i):
        f = self.frame(i)
        return [((x, y), f.getpixel((x, y))) for y in range(16) for x in range(8) if f.getpixel((x, y))[3]]

    def mean_lum(self, i):
        px = self.opaque(i)
        return sum(lum(c) for _, c in px) / len(px)

    def test_size_alpha_colours(self):
        self.assertEqual(self.sheet.size, (24, 16))
        self.assertTrue(all(a in (0, 255) for a in self.sheet.getchannel("A").getdata()))
        self.assertLessEqual(len({p for p in self.sheet.getdata() if p[3]}), 12)

    def test_corners_clear(self):
        for i in range(3):
            for c in [(0, 0), (7, 0), (0, 15), (7, 15)]:
                self.assertEqual(self.frame(i).getpixel(c)[3], 0, (i, c))

    def test_long_streaks_span_15_rows_with_5px_lean(self):
        for i in (0, 1):
            px = self.opaque(i)
            ys = [p[1] for p, _ in px]
            self.assertGreaterEqual(max(ys) - min(ys) + 1, 15)
            top = max(p[0] for p, _ in px if p[1] == min(ys))
            bot = min(p[0] for p, _ in px if p[1] == max(ys))
            self.assertEqual(top - bot, 5)

    def test_at_most_two_wide(self):
        for i in range(3):
            px = self.opaque(i)
            for y in range(16):
                self.assertLessEqual(sum(1 for p, _ in px if p[1] == y), 2)

    def test_heads_near_white(self):
        for i in range(3):
            self.assertGreater(lum(self.opaque(i)[0][1]), 240)

    def test_distinct_variants(self):
        n = [len(self.opaque(i)) for i in range(3)]
        self.assertGreater(n[1], n[0])
        self.assertLess(n[2], n[0])
        self.assertEqual(max(range(3), key=self.mean_lum), 2)  # frame 3 brightest

    def test_no_colour_too_dark_for_the_streets(self):
        for i in range(3):
            for _, c in self.opaque(i):
                self.assertGreater(lum(c), self.min_lum)

    def test_no_greenbull_colours(self):
        banned = {(12, 76, 44), (104, 220, 96), (247, 208, 52)}
        self.assertFalse({p[:3] for p in self.sheet.getdata() if p[3]} & banned)


class RainDropsV3Test(RainDropsTest):
    version = 3
    min_lum = 125
    max_short_rows = 6

    def test_variant_3_clearly_brighter_and_shorter(self):
        self.assertGreater(self.mean_lum(2), self.mean_lum(0) + 30)
        ys = [p[1] for p, _ in self.opaque(2)]
        self.assertLessEqual(max(ys) - min(ys) + 1, self.max_short_rows)

    def test_tail_still_darker_than_head(self):
        for i in range(3):
            px = self.opaque(i)
            self.assertGreater(lum(px[0][1]), lum(px[-1][1]))


class RainDropsV4Test(RainDropsV3Test):
    version = 4
    max_short_rows = 7

    def test_variant_2_slim(self):
        px = self.opaque(1)
        wide_rows = [y for y in range(16) if sum(1 for p, _ in px if p[1] == y) == 2]
        self.assertLessEqual(len(wide_rows), 7)
        self.assertLessEqual(len(px), 23)

    def test_every_variant_has_a_ramp_of_4_or_more(self):
        for i in range(3):
            self.assertGreaterEqual(len({c for _, c in self.opaque(i)}), 4)


if __name__ == "__main__":
    unittest.main()
