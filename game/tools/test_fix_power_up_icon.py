"""Tests for fix_power_up_icon.py (T-587)."""

import tempfile
import unittest
from pathlib import Path

from PIL import Image

import fix_power_up_icon as fpi


def make_icon() -> Image.Image:
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = im.load()
    for y in range(4, 28):
        for x in range(4, 28):
            px[x, y] = (60, 80, 110, 255)
    px[10, 10] = (250, 190, 60, 255)     # near Greenbull yellow
    px[11, 10] = (100, 215, 100, 255)    # near Greenbull light green
    px[0, 31] = (4, 3, 2, 255)           # stray corner speck
    px[12, 12] = (200, 200, 200, 120)    # semi-transparent
    return im


class FixTests(unittest.TestCase):
    def test_fix_cleans_everything(self):
        with tempfile.TemporaryDirectory() as d:
            src, dst = Path(d) / "raw.png", Path(d) / "v1.png"
            make_icon().save(src)
            report = fpi.fix(src, dst)
            out = Image.open(dst).convert("RGBA")
            self.assertEqual(out.mode, "RGBA")
            self.assertEqual(out.getpixel((0, 31)), (0, 0, 0, 0))
            self.assertEqual(report["strays_cleared"], 1)
            self.assertEqual(out.getpixel((10, 10)), fpi.YELLOW_TO + (255,))
            self.assertEqual(out.getpixel((11, 10)), fpi.GREEN_TO + (255,))
            self.assertEqual(out.getpixel((12, 12)), (0, 0, 0, 0))   # alpha 120 cut to 0
            self.assertTrue(all(p[3] in (0, 255) for p in out.getdata()))
            self.assertFalse([c for c in fpi.palette(out) if fpi.near_greenbull(c)])

    def test_fix_never_overwrites(self):
        with tempfile.TemporaryDirectory() as d:
            src, dst = Path(d) / "raw.png", Path(d) / "v1.png"
            make_icon().save(src)
            make_icon().save(dst)
            with self.assertRaises(FileExistsError):
                fpi.fix(src, dst)

    def test_reduce_colors_merges_closest(self):
        im = Image.new("RGBA", (4, 1), (0, 0, 0, 0))
        px = im.load()
        px[0, 0] = (10, 10, 10, 255)
        px[1, 0] = (10, 10, 10, 255)
        px[2, 0] = (12, 10, 10, 255)
        px[3, 0] = (200, 50, 50, 255)
        merges = fpi.reduce_colors(im, 2)
        self.assertEqual(merges, 1)
        self.assertEqual(px[2, 0], (10, 10, 10, 255))   # the rarer merged into the commoner
        self.assertEqual(px[3, 0], (200, 50, 50, 255))

    def test_margin_and_clear(self):
        with tempfile.TemporaryDirectory() as d:
            src, dst = Path(d) / "raw.png", Path(d) / "v1.png"
            im = Image.new("RGBA", (6, 6), (0, 0, 0, 0))
            px = im.load()
            for y in range(6):
                for x in range(6):
                    px[x, y] = (100, 120, 150, 255)
            px[3, 3] = (4, 3, 2, 255)          # already outline-dark: left alone
            im.save(src)
            report = fpi.fix(src, dst, keep_strays=True, margin=1, clears=[(2, 2)])
            out = Image.open(dst).convert("RGBA")
            self.assertEqual(report["margin_cleared"], 20)
            self.assertEqual(report["cleared"], 1)
            self.assertEqual(out.getpixel((0, 0)), (0, 0, 0, 0))
            self.assertEqual(out.getpixel((2, 2)), (0, 0, 0, 0))
            self.assertEqual(out.getpixel((1, 1)), (4, 3, 2, 255))     # cut edge gets the outline
            self.assertEqual(out.getpixel((1, 3)), (4, 3, 2, 255))
            self.assertEqual(out.getpixel((3, 3)), (4, 3, 2, 255))
            self.assertEqual(out.getpixel((2, 3)), (100, 120, 150, 255))  # interior untouched

    def test_recolor_map_and_inspect(self):
        with tempfile.TemporaryDirectory() as d:
            src = Path(d) / "raw.png"
            im = make_icon()
            fpi.recolor_map(im, {(60, 80, 110): (1, 2, 3)})
            im.save(src)
            info = fpi.inspect(src, Path(d) / "prev")
            self.assertEqual(info["size"], (32, 32))
            self.assertEqual(info["semi_transparent"], 1)
            self.assertEqual(len(info["near_greenbull"]), 2)
            self.assertEqual(info["stray_groups"], [[(0, 31)]])
            self.assertTrue((Path(d) / "prev" / "raw_prev_dark.png").is_file())
            self.assertIn((1, 2, 3), fpi.palette(Image.open(src).convert("RGBA")))


if __name__ == "__main__":
    unittest.main()
