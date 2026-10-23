"""Tests for likes_spring_gif.py (task T-273): every frame is cropped to the
bottom centre and ends up in the GIF."""
import sys
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
