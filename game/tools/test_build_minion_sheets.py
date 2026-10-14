import tempfile
import unittest
from pathlib import Path

from PIL import Image

import build_minion_sheets as b


class BuildMinionSheetsTest(unittest.TestCase):
    def test_sheet_is_a_row_of_frames(self):
        with tempfile.TemporaryDirectory() as t:
            paths = []
            for i in range(3):
                p = Path(t) / f"{i}.png"
                Image.new("RGBA", (48, 48), (i * 10, 0, 0, 255)).save(p)
                paths.append(p)
            sheet = b.build_sheet(paths)
        self.assertEqual(sheet.size, (144, 48))
        self.assertEqual(sheet.getpixel((48 + 5, 5)), (10, 0, 0, 255))

    def test_wrong_size_is_refused(self):
        with tempfile.TemporaryDirectory() as t:
            p = Path(t) / "x.png"
            Image.new("RGBA", (10, 10)).save(p)
            with self.assertRaises(ValueError):
                b.build_sheet([p])


if __name__ == "__main__":
    unittest.main()
