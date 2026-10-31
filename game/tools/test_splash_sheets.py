import tempfile
import unittest
from pathlib import Path

from PIL import Image

import splash_sheets


class SplashSheetsTest(unittest.TestCase):
    def test_makes_enlarged_and_grid(self):
        with tempfile.TemporaryDirectory() as d:
            paths = []
            for i in range(3):
                p = Path(d) / ("v%d.png" % i)
                Image.new("RGB", (32, 18), (i * 50, 0, 0)).save(p)
                paths.append(str(p))
            big, grid = splash_sheets.sheets(Path(d) / "out", paths)
            self.assertEqual(Image.open(big).size, (128, 72))
            self.assertEqual(Image.open(grid).size, (128, 72))


if __name__ == "__main__":
    unittest.main()
