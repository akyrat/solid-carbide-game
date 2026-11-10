"""Tests for build_kaiju_anim_sheet.py (T-613). Run: python -m unittest discover game/tools -p "test_build_kaiju_anim*" """
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_kaiju_anim_sheet as b  # noqa: E402

PAL = [(0, 0, 0), (100, 200, 50)]


def frame(x=10, y=10, colour=(100, 200, 50), alpha=255):
    im = Image.new("RGBA", (224, 224), (0, 0, 0, 0))
    im.putpixel((x, y), (*colour, alpha))
    return im


class SheetTest(unittest.TestCase):
    def test_snap_to_nearest_and_binarise_alpha(self):
        self.assertEqual(b.snap_frame(frame(colour=(110, 190, 60), alpha=200), PAL).getpixel((10, 10)), (100, 200, 50, 255))
        self.assertEqual(b.snap_frame(frame(alpha=100), PAL).getpixel((10, 10))[3], 0)

    def test_sheet_is_one_row_of_224(self):
        sheet = b.build_sheet([frame() for _ in range(6)], PAL)
        self.assertEqual(sheet.size, (224 * 6, 224))
        self.assertEqual(sheet.getpixel((224 * 3 + 10, 10)), (100, 200, 50, 255))

    def test_hold_repeats_frame_before(self):
        fs = [frame(colour=(0, 0, 0))] * 3 + [frame()] + [frame(colour=(0, 0, 0))] * 2
        sheet = b.build_sheet(fs, PAL, hold=2)
        for i in (3, 4, 5):
            self.assertEqual(sheet.getpixel((224 * i + 10, 10)), (100, 200, 50, 255))

    def test_align_moves_feet_to_the_still_ground_point(self):
        sheet = b.build_sheet([frame(50, 100)] * 3, PAL, ref=frame(60, 120))
        self.assertEqual(sheet.getpixel((60, 120))[3], 255)
        self.assertEqual(sheet.getpixel((50, 100))[3], 0)

    def test_wrong_size_and_bad_hold_refused(self):
        with self.assertRaises(ValueError):
            b.build_sheet([Image.new("RGBA", (48, 48))], PAL)
        with self.assertRaises(ValueError):
            b.build_sheet([frame()] * 2, PAL, hold=2)

    def test_real_stills_have_at_most_30_colours_and_frame0_size(self):
        for d in b.DIRS:
            self.assertLessEqual(len(b.palette_of(d)), 30)
            self.assertEqual(b.still_frame0(d).size, (224, 224))


class QuantizeTest(unittest.TestCase):
    def test_quantized_palette_has_at_most_n_colours(self):
        fs = [frame(x, 10, (x * 5 % 256, 100, 200 - x)) for x in range(1, 40)]
        pal = b.quantized_palette(fs, 8)
        self.assertLessEqual(len(pal), 8)
        self.assertGreater(len(pal), 0)


if __name__ == "__main__":
    unittest.main()
