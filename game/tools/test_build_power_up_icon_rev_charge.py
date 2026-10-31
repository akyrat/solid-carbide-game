import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import build_power_up_icon_rev_charge as b  # noqa: E402
import ascii_sprite  # noqa: E402

GREENBULL = {(104, 220, 96), (247, 208, 52)}


class RevChargeIconTest(unittest.TestCase):
    def setUp(self):
        self.im = b.draw()
        self.px = list(self.im.getdata())

    def test_size_alpha_colours(self):
        self.assertEqual(self.im.size, (32, 32))
        self.assertTrue(all(p[3] in (0, 255) for p in self.px))
        cols = {p[:3] for p in self.px if p[3]}
        self.assertLessEqual(len(cols), 30)
        self.assertFalse(cols & GREENBULL)

    def test_transparent_corners_and_fill(self):
        for c in ((0, 0), (31, 0), (0, 31), (31, 31)):
            self.assertEqual(self.im.getpixel(c)[3], 0)
        x0, y0, x1, y1 = self.im.getbbox()
        self.assertGreaterEqual(x1 - x0, 24)
        self.assertGreaterEqual(y1 - y0, 20)

    def test_needle_cyan_and_outline_highlights_present(self):
        cols = {p[:3] for p in self.px if p[3]}
        for k in ("needle", "needle_tip", "cy", "cy_hi", "out", "out_hi", "halo_amber", "halo_cyan"):
            self.assertIn(b.P[k], cols, k)

    def test_main_refuses_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            out = os.path.join(d, "v.png")
            self.assertEqual(b.main([out]), 0)
            self.assertEqual(b.main([out]), 1)

    def test_v2_layout_reproduces_archived_v2(self):
        from PIL import Image
        here = os.path.dirname(__file__)
        v2 = os.path.join(here, "..", "..", "art-archive", "T-465", "style-loop", "v2.png")
        if not os.path.exists(v2):
            self.skipTest("archived v2 not present")
        self.assertEqual(list(Image.open(v2).convert("RGBA").getdata()), list(b.draw(b.V2).getdata()))

    def test_v3_reproduces_archived_v3(self):
        from PIL import Image
        here = os.path.dirname(__file__)
        v3 = os.path.join(here, "..", "..", "art-archive", "T-465", "style-loop", "v3.png")
        if not os.path.exists(v3):
            self.skipTest("archived v3 not present")
        self.assertEqual(list(Image.open(v3).convert("RGBA").getdata()), self.px)

    def test_v3_fills_about_28(self):
        x0, y0, x1, y1 = self.im.getbbox()
        self.assertGreaterEqual(x1 - x0, 27)
        self.assertGreaterEqual(y1 - y0, 23)
        for k in ("needle_glow", "fl_ember", "halo_amber2"):
            self.assertIn(b.P[k], {p[:3] for p in self.px if p[3]}, k)

    def test_v4_tail_rules_and_archive(self):
        from PIL import Image
        im = b.draw(b.V4)
        px = list(im.getdata())
        cols = {p[:3] for p in px if p[3]}
        self.assertTrue(all(p[3] in (0, 255) for p in px))
        self.assertLessEqual(len(cols), 30)
        self.assertFalse(cols & GREENBULL)
        for c in ((0, 0), (31, 0), (0, 31), (31, 31)):
            self.assertEqual(im.getpixel(c)[3], 0)
        for k in ("fl_core", "ring_hi", "fl", "fl_ember", "halo_cyan", "cy_hi", "needle", "out_hi", "halo_amber2"):
            self.assertIn(b.P[k], cols, k)
        x0, y0, x1, y1 = im.getbbox()
        self.assertGreaterEqual(x1 - x0, 28)
        here = os.path.dirname(__file__)
        v4 = os.path.join(here, "..", "..", "art-archive", "T-465", "style-loop", "v4.png")
        if os.path.exists(v4):
            self.assertEqual(list(Image.open(v4).convert("RGBA").getdata()), px)

    def test_ascii_map(self):
        rows, idx = ascii_sprite.char_map(self.im)
        self.assertEqual(len(rows), 32)
        self.assertEqual(rows[0], "." * 32)


if __name__ == "__main__":
    unittest.main()
