"""Tests for fix_kaiju_walk_e_frame5.py (T-613). Run: python -m unittest discover game/tools -p "test_fix_kaiju_walk*" """
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fix_kaiju_walk_e_frame5 as f  # noqa: E402


class FixTest(unittest.TestCase):
    def sheet(self):
        s = Image.new("RGBA", (224 * 6, 224), (0, 0, 0, 0))
        s.putpixel((3 * 224 + 160, 160), (5, 2, 2, 255))      # frame 4's far foot
        s.putpixel((4 * 224 + 100, 100), (50, 60, 70, 255))   # frame 5's own pixel
        return s

    def test_far_foot_drawn_into_frame_5_only(self):
        out = f.fix(self.sheet())
        self.assertEqual(out.getpixel((4 * 224 + 160 + f.SHIFT_X, 160 + f.SHIFT_Y)), (5, 2, 2, 255))
        self.assertEqual(out.getpixel((4 * 224 + 100, 100)), (50, 60, 70, 255))
        self.assertEqual(out.size, (224 * 6, 224))
        for i in (0, 1, 2, 3, 5):
            self.assertEqual(out.crop((i * 224, 0, i * 224 + 224, 224)).tobytes(),
                             self.sheet().crop((i * 224, 0, i * 224 + 224, 224)).tobytes())

    def test_own_pixels_stay_on_top(self):
        s = self.sheet()
        s.putpixel((4 * 224 + 160 + f.SHIFT_X, 160 + f.SHIFT_Y), (9, 9, 9, 255))
        self.assertEqual(f.fix(s).getpixel((4 * 224 + 160 + f.SHIFT_X, 160 + f.SHIFT_Y)), (9, 9, 9, 255))


if __name__ == "__main__":
    unittest.main()
