"""Tests for t580_pick_stills.py (task T-580)."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import t580_pick_stills as ps  # noqa: E402
from PIL import Image  # noqa: E402


class PickStillsTest(unittest.TestCase):
    def test_stills_for_known_and_straight_cases(self):
        self.assertEqual(ps.stills_for("coast_then_throttle"), [88, 113, 138])
        self.assertEqual(ps.stills_for("straight_screen_315"), [100])

    def test_make_writes_stills_and_gif(self):
        with tempfile.TemporaryDirectory() as d:
            frames = Path(d) / "frames"
            frames.mkdir()
            for i in range(6):
                Image.new("RGB", (40, 20), (i * 40, 0, 0)).save(frames / ("f%08d.png" % i))
            out = Path(d) / "out"
            written = ps.make(frames, out, "x", steps=[1, 3, 99])
            names = sorted(p.name for p in written)
            self.assertEqual(names, ["x.gif", "x_step001.png", "x_step003.png", "x_step099.png"])
            with Image.open(out / "x_step003.png") as im:
                self.assertEqual(im.getpixel((0, 0))[0], 80)  # step 3 = frame 2
            with Image.open(out / "x.gif") as im:
                self.assertEqual(im.n_frames, 3)


if __name__ == "__main__":
    unittest.main()
