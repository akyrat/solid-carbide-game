"""Tests for make_turn_gif.py (task T-102). Run: python -m unittest discover -s game/tools -p "test_*.py" """
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import make_turn_gif as m  # noqa: E402


class TurnGifTests(unittest.TestCase):
    def test_crop_box_is_centred_and_moved_up(self):
        self.assertEqual(m.crop_box(100, 80, 40, 20, 0), (30, 30, 70, 50))
        self.assertEqual(m.crop_box(100, 80, 40, 20, 10), (30, 20, 70, 40))
        self.assertEqual(m.crop_box(100, 80, 40, 20, 99), (30, 0, 70, 20))

    def test_make_writes_an_enlarged_looping_gif(self):
        from PIL import Image
        with tempfile.TemporaryDirectory() as d:
            for i, c in enumerate([(255, 0, 0), (0, 255, 0), (0, 0, 255)]):
                Image.new("RGB", (60, 40), c).save(Path(d) / f"turn_{i:03d}.png")
            out = Path(d) / "x.gif"
            self.assertEqual(m.make(Path(d), out, size=(20, 10), scale=3, ms=50), 3)
            with Image.open(out) as g:
                self.assertEqual(g.size, (60, 30))
                self.assertEqual(g.n_frames, 3)

    def test_glob_and_every_pick_movie_frames(self):
        from PIL import Image
        with tempfile.TemporaryDirectory() as d:
            for i in range(5):
                Image.new("RGB", (60, 40), (i * 40, 0, 0)).save(Path(d) / f"f{i:08d}.png")
            Image.new("RGB", (60, 40)).save(Path(d) / "turn_000.png")
            out = Path(d) / "x.gif"
            self.assertEqual(m.make(Path(d), out, size=(20, 10), scale=1, pattern="f*.png", every=2), 3)
            with Image.open(out) as g:
                self.assertEqual(g.n_frames, 3)


if __name__ == "__main__":
    unittest.main()
