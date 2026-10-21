import tempfile
import unittest
from pathlib import Path

from PIL import Image

import build_kaiju_sheets as b


class BuildKaijuSheetsTest(unittest.TestCase):
    def test_sheet_is_a_row_of_frames(self):
        with tempfile.TemporaryDirectory() as t:
            paths = []
            for i in range(3):
                p = Path(t) / f"{i}.png"
                Image.new("RGBA", (224, 224), (i * 10, 0, 0, 255)).save(p)
                paths.append(p)
            sheet = b.build_sheet(paths)
        self.assertEqual(sheet.size, (672, 224))
        self.assertEqual(sheet.getpixel((224 + 5, 5)), (10, 0, 0, 255))

    def test_palette_is_cut_to_the_limit_without_new_colours(self):
        with tempfile.TemporaryDirectory() as t:
            p = Path(t) / "a.png"
            im = Image.new("RGBA", (224, 224), (0, 0, 0, 0))
            for x in range(40):
                im.putpixel((x, 0), (x * 5, 10, 10, 255))
            im.save(p)
            sheet = b.build_sheet([p], max_colors=30)
        colours = {px[:3] for px in sheet.getdata() if px[3]}
        self.assertLessEqual(len(colours), 30)
        self.assertTrue(all(c[1:] == (10, 10) for c in colours))

    def test_wrong_size_is_refused(self):
        with tempfile.TemporaryDirectory() as t:
            p = Path(t) / "x.png"
            Image.new("RGBA", (10, 10)).save(p)
            with self.assertRaises(ValueError):
                b.build_sheet([p])


if __name__ == "__main__":
    unittest.main()
