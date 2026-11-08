"""Tests for dump_pixels.py (T-587)."""

import tempfile
import unittest
from pathlib import Path

from PIL import Image

import dump_pixels


class DumpTests(unittest.TestCase):
    def test_dump_grid_and_legend(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "a.png"
            im = Image.new("RGBA", (3, 2), (0, 0, 0, 0))
            im.putpixel((0, 0), (10, 20, 30, 255))
            im.putpixel((1, 0), (10, 20, 30, 255))
            im.putpixel((2, 1), (200, 0, 0, 255))
            im.save(p)
            text = dump_pixels.dump(p, None, True)
            lines = text.splitlines()
            self.assertEqual(lines[1], " 0   0  0 ..")
            self.assertEqual(lines[2], " 1  .. ..  1")
            self.assertIn("0  (10, 20, 30)  x2", text)
            self.assertIn("1  (200, 0, 0)  x1", text)

    def test_box(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "a.png"
            Image.new("RGBA", (4, 4), (5, 5, 5, 255)).save(p)
            text = dump_pixels.dump(p, (2, 2, 4, 4), False)
            self.assertEqual(len(text.splitlines()), 3)


if __name__ == "__main__":
    unittest.main()
