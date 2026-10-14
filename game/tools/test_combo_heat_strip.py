"""Tests for combo_heat_strip.py (task T-131): the four step screenshots end up
one under the other, enlarged 2x with nearest neighbour."""
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
import combo_heat_strip as strip  # noqa: E402


def test_builds_the_strip(tmp_path):
    colours = [(10, 0, 0), (0, 20, 0), (0, 0, 30), (40, 40, 0)]
    for step, c in zip(strip.STEPS, colours):
        Image.new("RGB", (400, 300), c).save(tmp_path / f"combo_heat_{step}.png")
    out = strip.build(tmp_path)
    assert out == tmp_path / "combo_heat_steps.png"
    img = Image.open(out)
    part_w = 400 - 2 * (400 // 4 - 16)
    assert img.size == (part_w * 2, (150 * 4 + 6 * 3) * 2)
    # Each step's colour in its own band, in order, top to bottom.
    for i, c in enumerate(colours):
        assert img.getpixel((5, (i * 156 + 75) * 2)) == c
