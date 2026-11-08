"""Tests for png_rule_check.py: python game/tools/test_png_rule_check.py"""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import png_rule_check  # noqa: E402


def _png(path: Path, pixels: list[tuple[int, int, int, int]], size=(2, 2)) -> Path:
    im = Image.new("RGBA", size)
    im.putdata(pixels)
    im.save(path)
    return path


class TestCheck(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def test_clean_sprite_passes(self):
        p = _png(self.dir / "a.png", [(1, 2, 3, 255), (0, 0, 0, 0), (9, 9, 9, 255), (1, 2, 3, 255)])
        report, problems = png_rule_check.check(p, (2, 2))
        self.assertEqual(problems, [])
        self.assertEqual(report["colours"], 2)
        self.assertEqual(report["half_alpha"], 0)

    def test_half_alpha_size_and_greenbull_fail(self):
        p = _png(self.dir / "b.png", [(12, 76, 44, 255), (0, 0, 0, 128), (9, 9, 9, 255), (1, 2, 3, 255)])
        _, problems = png_rule_check.check(p, (4, 4), max_colours=2)
        self.assertEqual(len(problems), 4)

    def test_diff_counts_pixels(self):
        a = _png(self.dir / "a.png", [(1, 2, 3, 255)] * 4)
        b = _png(self.dir / "b.png", [(1, 2, 3, 255)] * 3 + [(0, 0, 0, 255)])
        report, _ = png_rule_check.check(a, diff=b)
        self.assertEqual(report["diff"], 1)

    def test_main_exit_code(self):
        p = _png(self.dir / "a.png", [(1, 2, 3, 255)] * 4)
        self.assertEqual(png_rule_check.main([str(p), "--size", "2x2"]), 0)
        self.assertEqual(png_rule_check.main([str(p), "--size", "3x3"]), 1)


if __name__ == "__main__":
    unittest.main()
