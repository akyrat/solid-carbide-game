"""Tests for build_rain_drops.py (T-509)."""

import tempfile
import unittest
from pathlib import Path

from PIL import Image

import build_rain_drops as brd


def _fake_src(path: Path) -> None:
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for i, xy in enumerate(brd.SAMPLES.values()):
        im.putpixel(xy, (100 + i * 10, 120 + i * 10, 200, 255))
    im.save(path)


class RainDropsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.src = self.tmp / "src.png"
        _fake_src(self.src)
        self.sheet = brd.build(self.src)

    def test_size_and_mode(self):
        self.assertEqual(self.sheet.size, (24, 16))
        self.assertEqual(self.sheet.mode, "RGBA")

    def test_alpha_binary_and_colours(self):
        px = list(self.sheet.getdata())
        self.assertTrue(all(p[3] in (0, 255) for p in px))
        self.assertLessEqual(len({p for p in px if p[3]}), 12)

    def test_corners_transparent_and_each_frame_drawn(self):
        for f in range(3):
            x0 = f * 8
            for x, y in ((0, 0), (7, 0), (0, 15), (7, 15)):
                self.assertEqual(self.sheet.getpixel((x0 + x, y))[3], 0)
            frame = self.sheet.crop((x0, 0, x0 + 8, 16))
            self.assertIsNotNone(frame.getbbox())

    def test_top_leans_right(self):
        for f in range(3):
            frame = self.sheet.crop((f * 8, 0, f * 8 + 8, 16))
            rows = [y for y in range(16) if any(frame.getpixel((x, y))[3] for x in range(8))]
            top_x = min(x for x in range(8) if frame.getpixel((x, rows[0]))[3])
            bot_x = min(x for x in range(8) if frame.getpixel((x, rows[-1]))[3])
            self.assertGreater(top_x, bot_x)

    def test_never_overwrites(self):
        out = self.tmp / "v.png"
        brd.main(["--src", str(self.src), "--out", str(out)])
        with self.assertRaises(SystemExit):
            brd.main(["--src", str(self.src), "--out", str(out)])


if __name__ == "__main__":
    unittest.main()
