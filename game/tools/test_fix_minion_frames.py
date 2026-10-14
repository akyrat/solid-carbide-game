import unittest

from PIL import Image

import fix_minion_frames as fm


class FixMinionFramesTest(unittest.TestCase):
    def test_copy_patch_copies_inclusive_box(self):
        src = Image.new("RGBA", (6, 6), (1, 2, 3, 255))
        dst = Image.new("RGBA", (6, 6), (0, 0, 0, 0))
        fm.copy_patch(dst, src, (1, 1, 2, 2))
        self.assertEqual(dst.getpixel((2, 2)), (1, 2, 3, 255))
        self.assertEqual(dst.getpixel((3, 3)), (0, 0, 0, 0))

    def test_recolor_makes_pixels_opaque(self):
        img = Image.new("RGBA", (3, 3), (0, 0, 0, 0))
        fm.recolor(img, [(1, 1)], (9, 8, 7))
        self.assertEqual(img.getpixel((1, 1)), (9, 8, 7, 255))

    def test_apply_fixes(self):
        good = Image.new("RGBA", (50, 50), (5, 5, 5, 255))
        bad = Image.new("RGBA", (50, 50), (6, 6, 6, 255))
        frames = [good, bad]
        fm.apply_fixes(frames, [("eye", 1, 0, (1, 1, 2, 2)), ("recolor", 1, [(0, 0)], (7, 7, 7))])
        self.assertEqual(frames[1].getpixel((1, 1)), (5, 5, 5, 255))
        self.assertEqual(frames[1].getpixel((0, 0)), (7, 7, 7, 255))
        self.assertEqual(frames[1].getpixel((9, 9)), (6, 6, 6, 255))


if __name__ == "__main__":
    unittest.main()
