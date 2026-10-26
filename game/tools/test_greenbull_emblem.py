import unittest
from PIL import Image

import greenbull_emblem as g


class DrawTest(unittest.TestCase):
    def test_size_palette_margin(self):
        im = g.draw()
        self.assertEqual(im.size, (128, 128))
        colours = {c for _, c in im.getcolors(1 << 16)}
        self.assertTrue(colours <= set(g.PALETTE) | {g.CLEAR})
        l, t, r, b = im.getbbox()
        self.assertGreaterEqual(min(l, t, 128 - r, 128 - b), 4)

    def test_dark_green_leads_and_yellow_is_small(self):
        counts = {c: n for n, c in g.draw().getcolors(1 << 16)}
        greens = {c: counts.get(c, 0) for c in (g.DARK, g.LIGHT, g.YELLOW)}
        self.assertEqual(max(greens, key=greens.get), g.DARK)
        self.assertLess(counts[g.YELLOW], counts[g.DARK] // 5)


class RemapTest(unittest.TestCase):
    def test_snaps_and_clears(self):
        im = Image.new("RGBA", (3, 3), (100, 210, 90, 255))
        im.putpixel((0, 0), (10, 70, 40, 60))
        out = g.remap(im)
        self.assertEqual(out.getpixel((0, 0)), g.CLEAR)
        self.assertEqual(out.getpixel((1, 1)), g.LIGHT)

    def test_lone_speck_removed(self):
        im = Image.new("RGBA", (3, 3), g.DARK)
        im.putpixel((1, 1), g.YELLOW)
        self.assertEqual(g.remap(im).getpixel((1, 1)), g.DARK)


if __name__ == "__main__":
    unittest.main()
