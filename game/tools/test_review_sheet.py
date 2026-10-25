import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image
import review_sheet


class ReviewSheetTest(unittest.TestCase):
    def test_frames_and_scale(self):
        with tempfile.TemporaryDirectory() as d:
            strip = os.path.join(d, "strip.png")
            im = Image.new("RGBA", (20, 10), (0, 0, 0, 0))
            im.paste((255, 0, 0, 255), (10, 0, 20, 10))
            im.save(strip)
            whole = os.path.join(d, "whole.png")
            Image.new("RGBA", (6, 6), (0, 255, 0, 255)).save(whole)
            out = os.path.join(d, "out.png")
            review_sheet.main([out, strip + ":1:10", whole, "--bg", "light", "--scale", "3"])
            res = Image.open(out)
            self.assertEqual(res.size, ((10 + 6 + 24) * 3, (10 + 16) * 3))
            self.assertEqual(res.getpixel((8 * 3 + 3, 10 * 3 + 3))[:3], (255, 0, 0))
            self.assertEqual(res.getpixel((1, 1))[:3], (225, 225, 230))


if __name__ == "__main__":
    unittest.main()
