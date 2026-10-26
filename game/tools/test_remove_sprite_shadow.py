import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image
import remove_sprite_shadow as r

S = (70, 90, 109, 255)
B = (10, 200, 10, 255)


class RemoveShadowTest(unittest.TestCase):
    def test_only_connected_shadow_removed(self):
        im = Image.new("RGBA", (5, 3), (0, 0, 0, 0))
        for x in range(5):
            im.putpixel((x, 1), S)       # shadow touching background
        im.putpixel((2, 0), B)           # body above
        im.putpixel((2, 2), B)
        # enclosed shadow-coloured pixel inside the body
        im.putpixel((0, 0), B)
        out, n = r.remove_shadow(im, [S[:3]])
        self.assertEqual(n, 5)
        self.assertEqual(out.getpixel((2, 0)), B)
        self.assertEqual(out.getpixel((2, 1))[3], 0)

    def test_enclosed_kept(self):
        im = Image.new("RGBA", (3, 3), B)
        im.putpixel((1, 1), S)
        out, n = r.remove_shadow(im, [S[:3]])
        self.assertEqual(n, 0)
        self.assertEqual(out.getpixel((1, 1)), S)


if __name__ == "__main__":
    unittest.main()
