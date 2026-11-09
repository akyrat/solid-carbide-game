"""Tests for fit_kaiju_death_e.py (T-613). Run: python -m unittest discover game/tools -p "test_fit_kaiju_death*" """
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fit_kaiju_death_e as f  # noqa: E402


class FitTest(unittest.TestCase):
    def sheet(self, n=12):
        s = Image.new("RGBA", (224 * n, 224), (0, 0, 0, 0))
        for i in range(n):
            s.putpixel((i * 224 + 50, 150 + i), (9, 9, 9, 255))
        return s

    def test_sixteen_frames_with_the_last_repeated(self):
        out = f.fit(self.sheet())
        self.assertEqual(out.size, (224 * 16, 224))
        for i in (12, 15):
            self.assertEqual(out.crop((i * 224, 0, i * 224 + 224, 224)).tobytes(), out.crop((11 * 224, 0, 12 * 224, 224)).tobytes())

    def test_lying_frames_rest_on_the_ground_and_standing_ones_stay(self):
        out = f.fit(self.sheet())
        self.assertEqual(out.getpixel((0 * 224 + 50, 150))[3], 255)
        last = out.crop((15 * 224, 0, 16 * 224, 224)).getchannel("A").getbbox()
        self.assertEqual(last[3], f.GROUND_END_Y)


if __name__ == "__main__":
    unittest.main()
