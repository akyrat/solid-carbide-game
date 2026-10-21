import os
import sys
import unittest
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_readme_car as m


class MakeReadmeCarTest(unittest.TestCase):
    def test_scale_is_exact_nearest(self):
        src = Image.new("RGBA", (2, 2))
        src.putdata([(1, 2, 3, 255), (4, 5, 6, 0), (7, 8, 9, 128), (10, 11, 12, 255)])
        out = m.scale_nearest(src, 2)
        self.assertEqual(out.size, (4, 4))
        for y in range(4):
            for x in range(4):
                self.assertEqual(out.getpixel((x, y)), src.getpixel((x // 2, y // 2)))

    def test_committed_image_matches_source_frame(self):
        src = Image.open(m.SOURCE).convert("RGBA")
        self.assertEqual(src.size, (128, 128))
        out = Image.open(m.OUTPUT)
        self.assertEqual(out.mode, "RGBA")
        self.assertEqual(out.size, (256, 256))
        self.assertEqual(list(out.getdata()), list(m.scale_nearest(src, 2).getdata()))

    def test_source_is_frame_8_of_sheet(self):  # frame 4 of 16 until T-102 made the sheet 32 frames
        sheet = Image.open(os.path.join(m.ROOT, "game", "art", "car", "car_iso.png")).convert("RGBA")
        frame = sheet.crop((8 * 128, 0, 9 * 128, 128))
        src = Image.open(m.SOURCE).convert("RGBA")
        self.assertEqual(list(frame.getdata()), list(src.getdata()))


if __name__ == "__main__":
    unittest.main()
