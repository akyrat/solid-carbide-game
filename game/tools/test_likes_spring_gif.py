"""Tests for likes_spring_gif.py (task T-273): every frame is cropped to the
bottom centre and ends up in the GIF."""
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
import likes_spring_gif as g  # noqa: E402


def test_crop_is_the_bottom_centre():
    im = Image.new("RGB", (400, 300), (1, 2, 3))
    c = g.crop_bottom(im)
    assert c.size == (400 - 2 * (400 // 4 - 16), 190)


def test_builds_a_gif_with_every_frame(tmp_path):
    for i in range(5):
        Image.new("RGB", (400, 300), (10 * i, 0, 0)).save(tmp_path / f"f{i:08d}.png")
    out = tmp_path / "o.gif"
    assert g.build(tmp_path, out, scale=2) == 5
    gif = Image.open(out)
    assert gif.n_frames == 5
    assert gif.size == ((400 - 2 * (400 // 4 - 16)) * 2, 380)


class CropBoxTest(unittest.TestCase):
    """T-337: --box crops any rectangle (the sub goal square on the right edge)."""

    def test_crop_box_inside_the_frame(self):
        im = Image.new("RGB", (400, 300), (1, 2, 3))
        self.assertEqual(g.crop_box(im, (300, 100, 500, 350)).size, (100, 200))

    def test_build_with_a_box(self):
        with tempfile.TemporaryDirectory() as d:
            for i in range(3):
                Image.new("RGB", (400, 300), (10 * i, 0, 0)).save(Path(d) / f"f{i:08d}.png")
            out = Path(d) / "o.gif"
            self.assertEqual(g.build(d, out, scale=2, box=(200, 50, 360, 250)), 3)
            gif = Image.open(out)
            self.assertEqual(gif.size, (320, 400))
            gif.close()
