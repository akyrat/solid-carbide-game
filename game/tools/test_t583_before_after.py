"""Tests for t583_before_after.py (task T-583). Run: python -m unittest game/tools/test_t583_before_after.py"""
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import t583_before_after as ba  # noqa: E402


class BeforeAfterTest(unittest.TestCase):
    def test_makes_a_side_by_side_gif_and_stills(self):
        tmp = Path(tempfile.mkdtemp())
        try:
            for name, colour in (("a", (200, 0, 0)), ("b", (0, 0, 200))):
                (tmp / name).mkdir()
                for i in range(6):
                    Image.new("RGB", (200, 100), tuple(min(255, c + 40 * i) for c in colour)).save(tmp / name / ("f%08d.png" % i))
            out = ba.make(tmp / "a", tmp / "b", tmp / "out", "case", steps=[3])
            self.assertEqual([p.name for p in out], ["case_step003.png", "case.gif"])
            with Image.open(out[0]) as im:
                self.assertEqual(im.size, (408, 100))
                self.assertEqual(im.getpixel((5, 5)), (255, 80, 80))
                self.assertEqual(im.getpixel((260, 5)), (80, 80, 255))
            with Image.open(out[1]) as g:
                self.assertEqual(g.n_frames, 3)
        finally:
            shutil.rmtree(tmp)


if __name__ == "__main__":
    unittest.main()
