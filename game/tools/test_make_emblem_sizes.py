import unittest
from PIL import Image

import make_emblem_sizes as m

DARK = (12, 76, 44, 255)


def master():
    """A 128 px test emblem: outlined dark square, light stripe, a small yellow eye."""
    im = Image.new("RGBA", (128, 128), m.CLEAR)
    for y in range(16, 112):
        for x in range(16, 112):
            edge = x < 18 or x > 109 or y < 18 or y > 109
            im.putpixel((x, y), m.OUTLINE if edge else DARK)
    for y in range(30, 90):
        for x in range(60, 66):
            im.putpixel((x, y), m.LIGHT)
    for y in range(40, 43):
        for x in range(30, 37):
            im.putpixel((x, y), m.YELLOW)
    return im


class SizesTest(unittest.TestCase):
    def test_palette_kept_and_hard_alpha(self):
        big = master()
        palette = {c for _, c in big.getcolors(1 << 16)}
        for size in (64, 32):
            small, _ = m.make_size(big, size)
            self.assertEqual(small.size, (size, size))
            cols = {c for _, c in small.getcolors(1 << 16)}
            self.assertTrue(cols <= palette, cols - palette)
            self.assertTrue(all(p[3] in (0, 255) for p in small.getdata()))

    def test_small_yellow_survives_at_32(self):
        small, _ = m.make_size(master(), 32)
        self.assertIn(m.YELLOW, {c for _, c in small.getcolors(1 << 16)})

    def test_close_outline_rings_fill(self):
        im = Image.new("RGBA", (5, 5), m.CLEAR)
        im.putpixel((2, 2), DARK)
        self.assertEqual(m.close_outline(im), 4)
        self.assertEqual(im.getpixel((2, 1)), m.OUTLINE)
        self.assertEqual(im.getpixel((1, 1)), m.CLEAR)
        self.assertEqual(m.close_outline(im), 0)  # outline never grows around outline

    def test_rejects_non_multiple(self):
        with self.assertRaises(ValueError):
            m.downscale(Image.new("RGBA", (100, 100)), 32)


if __name__ == "__main__":
    unittest.main()
