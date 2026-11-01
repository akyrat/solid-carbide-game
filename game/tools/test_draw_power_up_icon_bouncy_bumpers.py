"""Tests for draw_power_up_icon_bouncy_bumpers.py (T-465). Run:
python -m unittest discover -s game/tools -p "test_draw_power_up_icon_bouncy_bumpers.py"
"""

import os
import sys
import tempfile
import unittest

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import draw_power_up_icon_bouncy_bumpers as bb  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
V2 = os.path.join(ROOT, "art-archive", "T-465", "style-loop", "v2-3.png")
V3 = os.path.join(ROOT, "art-archive", "T-465", "style-loop", "v3-3.png")
V4 = os.path.join(ROOT, "art-archive", "T-465", "style-loop", "v4-3.png")
FORBIDDEN = {(104, 220, 96), (247, 208, 52)}


class TestDraw(unittest.TestCase):
    def setUp(self):
        self.im = bb.draw_v4()
        self.px = list(self.im.getdata())

    def test_script_rules(self):
        self.assertEqual(self.im.mode, "RGBA")
        self.assertEqual(self.im.size, (32, 32))
        self.assertLessEqual({p[3] for p in self.px}, {0, 255})
        cols = {p[:3] for p in self.px if p[3]}
        self.assertLessEqual(len(cols), 30)
        self.assertFalse(cols & FORBIDDEN)
        for c in ((0, 0), (31, 0), (0, 31), (31, 31)):
            self.assertEqual(self.im.getpixel(c)[3], 0)

    def test_fills_about_28_and_centred(self):
        x0, y0, x1, y1 = self.im.getbbox()
        self.assertGreaterEqual(x1 - x0, 26)
        self.assertGreaterEqual(y1 - y0, 26)
        self.assertLessEqual(abs((x0 + x1) / 2 - 16), 1.5)
        self.assertLessEqual(abs((y0 + y1) / 2 - 16), 1.5)

    def test_magenta_spring_and_cyan_star_present(self):
        cols = [p[:3] for p in self.px if p[3]]
        self.assertGreater(cols.count(bb.P["M"]) + cols.count(bb.P["m"]), 10)
        self.assertEqual(self.im.getpixel((24, 17))[:3], bb.P3["W"])
        self.assertGreater(cols.count(bb.P["C"]) + cols.count(bb.P["c"]), 10)

    def test_outline_has_highlight_breaks(self):
        cols = [p[:3] for p in self.px if p[3]]
        self.assertGreater(cols.count(bb.P["#"]), 40)
        self.assertGreater(cols.count(bb.P3["h"]), 8)

    def test_main_writes_png_and_preview(self):
        with tempfile.TemporaryDirectory() as d:
            out, prev = os.path.join(d, "o.png"), os.path.join(d, "p.png")
            self.assertEqual(bb.main(["x", out, "--preview", prev]), 0)
            with Image.open(out) as im:
                self.assertEqual(list(im.convert("RGBA").getdata()), self.px)
            with Image.open(prev) as im:
                self.assertEqual(im.size, (32 * 8 * 2 + 16, 32 * 8))

    def test_v3_has_stepped_magenta_glow_and_highlights(self):
        cols = [p[:3] for p in bb.draw_v3().getdata() if p[3]]
        self.assertGreater(cols.count(bb.P3["n"]), 10)
        self.assertGreater(cols.count(bb.P3["h"]), 8)
        self.assertGreater(cols.count(bb.P3["u"]), 10)   # the wall's lit face

    def test_v4_cushion_is_ribbed_and_lit(self):
        cells = bb._cushion_v4()
        self.assertGreater(sum(1 for c in cells.values() if c == "M"), 8)
        self.assertGreater(sum(1 for c in cells.values() if c == "p"), 8)   # rib grooves
        xs = [x for x, _ in cells]
        ys = [y for _, y in cells]
        self.assertEqual((min(xs), max(xs), min(ys), max(ys)), (14, 23, 12, 23))

    def _same(self, path, im):
        with Image.open(path) as a:
            self.assertEqual(list(a.convert("RGBA").getdata()), list(im.getdata()))

    @unittest.skipUnless(os.path.exists(V2), "v2-3.png not archived")
    def test_archived_v2_reproduces(self):
        self._same(V2, bb.draw_v2())

    @unittest.skipUnless(os.path.exists(V3), "v3-3.png not archived")
    def test_archived_v3_reproduces(self):
        self._same(V3, bb.draw_v3())

    @unittest.skipUnless(os.path.exists(V4), "v4-3.png not archived yet")
    def test_archived_v4_reproduces(self):
        self._same(V4, self.im)


if __name__ == "__main__":
    unittest.main()
