"""Tests for level_up_flash_strip.py (task T-139): the key-frame screenshots
end up one under the other, enlarged 2x with nearest neighbour."""
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
import level_up_flash_strip as strip  # noqa: E402


def test_builds_the_strip(tmp_path):
    colours = [(10 * (i + 1), 0, 5 * i) for i in range(len(strip.FRAMES))]
    for name, c in zip(strip.FRAMES, colours):
        Image.new("RGB", (400, 300), c).save(tmp_path / f"level_up_flash_{name}.png")
    out = strip.build(tmp_path)
    assert out == tmp_path / "level_up_flash_frames.png"
    img = Image.open(out)
    part_w = 400 - 2 * (400 // 4 - 16)
    n = len(strip.FRAMES)
    assert img.size == (part_w * 2, (150 * n + 6 * (n - 1)) * 2)
    for i, c in enumerate(colours):
        assert img.getpixel((5, (i * 156 + 75) * 2)) == c
