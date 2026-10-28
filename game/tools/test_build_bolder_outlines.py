"""Tests for build_bolder_outlines.py (T-340)."""
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
import build_bolder_outlines as b  # noqa: E402


def sprite():
    im = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
    for x in range(3, 5):
        for y in range(3, 5):
            im.putpixel((x, y), (200, 10, 10, 255))
    for x in range(2, 6):          # a thin dark outline round the body
        for y in (2, 5):
            im.putpixel((x, y), (5, 5, 5, 255))
    for y in range(2, 6):
        for x in (2, 5):
            im.putpixel((x, y), (5, 5, 5, 255))
    return im


class BolderOutlines(unittest.TestCase):
    def test_outline_colour_is_the_dark_one(self):
        self.assertEqual(b.outline_colour(sprite()), (5, 5, 5))

    def test_grows_one_pixel_in_the_outline_colour(self):
        g = b.grow(sprite(), (5, 5, 5))
        self.assertEqual(g.getpixel((1, 1)), (5, 5, 5, 255))
        self.assertEqual(g.getpixel((6, 6)), (5, 5, 5, 255))
        self.assertEqual(g.getpixel((0, 0))[3], 0)
        self.assertEqual(g.getpixel((3, 3)), (200, 10, 10, 255))

    def test_no_new_colours_and_alpha_binary(self):
        g = b.grow(sprite(), (5, 5, 5))
        self.assertEqual({p[:3] for p in g.getdata() if p[3]}, {(5, 5, 5), (200, 10, 10)})
        self.assertTrue(all(p[3] in (0, 255) for p in g.getdata()))

    def test_frames_stay_apart(self):
        sheet = Image.new("RGBA", (16, 8), (0, 0, 0, 0))
        sheet.paste(sprite(), (0, 0))
        sheet.paste(sprite(), (8, 0))
        out = b.bolder_sheet(sheet, 8, 2)
        self.assertEqual(out.size, (16, 8))
        for x in (7, 8):                       # frame edges stay clear
            self.assertEqual(out.getpixel((x, 4))[3], 0)

    def test_rerunnable(self):
        sheet = sprite()
        self.assertEqual(list(b.bolder_sheet(sheet, 8, 1).getdata()), list(b.bolder_sheet(sheet, 8, 1).getdata()))

    def test_game_sheets_pass_the_rules(self):
        self.assertEqual(b.check(), 0)


if __name__ == "__main__":
    unittest.main()
