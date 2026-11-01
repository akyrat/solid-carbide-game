import os
import sys
import tempfile
import unittest

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import fix_power_up_icon as f  # noqa: E402


class FixPowerUpIconTest(unittest.TestCase):
    def _img(self):
        im = Image.new("RGBA", (32, 32), (5, 2, 4, 255))  # near-black background
        for y in range(8, 24):
            for x in range(8, 24):
                im.putpixel((x, y), (x * 7, y * 5, 200, 255))  # many colours
        im.putpixel((16, 16), (10, 10, 10, 255))  # dark pixel inside, not border-connected
        return im

    def test_clears_border_background_only(self):
        im = self._img()
        cleared = f.clear_border_background(im)
        self.assertEqual(cleared, 32 * 32 - 16 * 16)
        self.assertEqual(im.getpixel((0, 0))[3], 0)
        self.assertEqual(im.getpixel((16, 16)), (10, 10, 10, 255))

    def test_quantize_limits_colours_and_alpha(self):
        im = self._img()
        f.clear_border_background(im)
        out = f.quantize(im, 30)
        cols = {p for p in out.getdata() if p[3] == 255}
        self.assertLessEqual(len(cols), 30)
        self.assertTrue(all(p[3] in (0, 255) for p in out.getdata()))
        self.assertEqual(out.getpixel((0, 0)), (0, 0, 0, 0))

    def test_main_writes_rgba(self):
        with tempfile.TemporaryDirectory() as d:
            src, dst = os.path.join(d, "a.png"), os.path.join(d, "b.png")
            self._img().save(src)
            sys.argv = ["x", src, dst, "--preview", os.path.join(d, "p")]
            f.main()
            self.assertEqual(Image.open(dst).mode, "RGBA")
            self.assertTrue(os.path.exists(os.path.join(d, "p_dark.png")))


if __name__ == "__main__":
    unittest.main()
