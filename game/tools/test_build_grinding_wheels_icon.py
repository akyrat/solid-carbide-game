"""Tests for build_grinding_wheels_icon.py (T-587)."""

import tempfile
import unittest
from pathlib import Path

from PIL import Image

import build_grinding_wheels_icon as bg

GREENBULL = ((104, 220, 96), (247, 208, 52))


def near(a, b, d=40):
    return all(abs(a[i] - b[i]) <= d for i in range(3))


class IconTests(unittest.TestCase):
    def setUp(self):
        self.im = bg.draw()
        self.px = self.im.load()

    def test_size_alpha_and_palette(self):
        self.assertEqual(self.im.size, (32, 32))
        cols = set()
        for p in self.im.getdata():
            self.assertIn(p[3], (0, 255))
            if p[3]:
                cols.add(p[:3])
        self.assertLessEqual(len(cols), 26)
        for c in cols:
            for g in GREENBULL:
                self.assertFalse(near(c, g), f"{c} is near Greenbull's {g}")
        for corner in ((0, 0), (31, 0), (0, 31), (31, 31)):
            self.assertEqual(self.px[corner][3], 0)
        # No lone pixel on the tyre's top row.
        top = min(y for y in range(32) for x in range(32) if self.px[x, y][3] and x < 20)
        self.assertGreaterEqual(sum(1 for x in range(32) if self.px[x, top][3]), 3)

    def test_composition(self):
        bbox = self.im.getbbox()
        self.assertGreaterEqual(bbox[2] - bbox[0], 28)   # fills about 28 x 28
        self.assertGreaterEqual(bbox[3] - bbox[1], 28)
        # The tyre's bottom touches the rail's top outline row.
        self.assertEqual(self.px[bg.CX, bg.RAIL_Y0][:3], bg.OUTLINE)        # the rail's top outline
        self.assertEqual(self.px[bg.CX, bg.RAIL_Y0 - 1][:3], bg.OUTLINE)    # the tyre's own outline, on it
        self.assertEqual(self.px[bg.CX, bg.RAIL_Y0 - 2][:3], bg.TYRE_DARK)
        # Hub centre is steel, lug nuts are dark, the rail's top-left is highlighted.
        self.assertEqual(self.px[bg.CX, bg.CY][:3], bg.HUB_LIT)
        self.assertEqual(self.px[bg.CX, round(bg.CY - bg.LUG_RY)][:3], bg.LUG)
        # The rail: a lit top face over a darker side face, highlighted top-left; the hub's rim is bevelled.
        self.assertEqual(self.px[bg.RAIL_X0 + 2, bg.RAIL_Y0 + 1][:3], bg.RAIL_HI)
        self.assertEqual(self.px[15, bg.RAIL_Y0 + 2][:3], bg.RAIL_TOP)
        self.assertEqual(self.px[15, bg.RAIL_Y0 + 3][:3], bg.RAIL_SIDE)
        self.assertEqual(self.px[bg.CX - bg.HUB_RX, bg.CY][:3], bg.HUB_LIT)
        self.assertEqual(self.px[bg.CX + bg.HUB_RX, bg.CY][:3], bg.HUB_DARK)
        self.assertEqual(self.px[bg.CX - 3, bg.CY - 9][:3], bg.TYRE_HI)

    def test_sparks_only_on_the_right_with_halos(self):
        spark_cols = set(bg.SPARK) | {bg.CYAN, bg.MAGENTA}
        xs = [x for y in range(32) for x in range(32) if self.px[x, y][3] and self.px[x, y][:3] in spark_cols]
        self.assertTrue(xs)
        self.assertGreaterEqual(min(xs), bg.CX + bg.SIDE + 4)
        # A white spark has an orange halo pixel next to it somewhere.
        x, y, _ = bg.SPARKS[0]
        halo = {self.px[x + dx, y + dy][:3] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))}
        self.assertTrue(halo & set(bg.SPARK[1:]))

    def test_main_never_overwrites(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d) / "icon.png"
            self.assertEqual(bg.main([str(out)]), 0)
            with Image.open(out) as saved:
                self.assertEqual(saved.mode, "RGBA")
            self.assertEqual(bg.main([str(out)]), 1)


if __name__ == "__main__":
    unittest.main()
