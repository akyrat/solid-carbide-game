import unittest

from PIL import Image

import reduce_palette as rp


def colours(im):
    return {p[:3] for p in im.getdata() if p[3] > 0}


class ReducePaletteTest(unittest.TestCase):
    def make(self):
        im = Image.new("RGBA", (10, 10), (0, 0, 0, 0))
        data = []
        for i in range(100):
            if i < 10:
                data.append((0, 0, 0, 0))
            else:
                data.append(((i % 9) * 25, (i % 7) * 30, 100, 255))
        im.putdata(data)
        return im

    def test_limits_colours_and_adds_none(self):
        im = self.make()
        before = colours(im)
        self.assertGreater(len(before), 30)
        out = rp.reduce_image(im, 30)
        after = colours(out)
        self.assertLessEqual(len(after), 30)
        self.assertTrue(after <= before)

    def test_alpha_unchanged_and_deterministic(self):
        im = self.make()
        out = rp.reduce_image(im, 20)
        self.assertEqual([p[3] for p in im.getdata()], [p[3] for p in out.getdata()])
        self.assertEqual(list(out.getdata()), list(rp.reduce_image(im, 20).getdata()))

    def test_already_small_palette_unchanged(self):
        im = self.make()
        self.assertEqual(list(rp.reduce_image(im, 500).getdata()), list(im.convert("RGBA").getdata()))

    def test_merges_least_used_into_nearest(self):
        m = rp.reduce_mapping({(0, 0, 0): 10, (250, 0, 0): 5, (10, 0, 0): 1}, 2)
        self.assertEqual(m[(10, 0, 0)], (0, 0, 0))
        self.assertEqual(m[(250, 0, 0)], (250, 0, 0))

    def test_preview_size_and_backgrounds(self):
        im = self.make()
        pv = rp.preview_image(im, 3)
        self.assertEqual(pv.size, (30 * 2 + 24, 30 + 12))
        self.assertEqual(pv.getpixel((0, 0)), rp.DARK_BG)
        self.assertEqual(pv.getpixel((pv.width - 1, 0)), rp.LIGHT_BG)


if __name__ == "__main__":
    unittest.main()
