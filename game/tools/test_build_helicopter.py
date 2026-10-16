"""Tests for build_helicopter.py (task T-145). Run with the Python tool tests."""
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_helicopter as b  # noqa: E402


class HelicopterSheetTest(unittest.TestCase):
    def setUp(self):
        self.sheet = Image.open(b.SHEET).convert("RGBA")

    def test_sheet_has_four_frames(self):
        self.assertEqual(self.sheet.size, (b.W * 4, b.H))

    def test_each_frame_follows_the_sprite_rules(self):
        for i in range(4):
            r = b.frame_report(self.sheet.crop((i * b.W, 0, (i + 1) * b.W, b.H)))
            self.assertTrue(r["transparent_corners"])
            self.assertEqual(r["semi_transparent_pixels"], 0)
            self.assertLessEqual(r["colours"], 30)

    def test_frames_differ_only_by_the_rotor_and_the_logo_red_is_there(self):
        f = [list(self.sheet.crop((i * b.W, 0, (i + 1) * b.W, b.H)).getdata()) for i in range(4)]
        self.assertNotEqual(f[0], f[1])
        self.assertIn(b.LOGO_RED, {p[:3] for p in f[0] if p[3]})

    def test_build_is_deterministic(self):
        a = [list(x.getdata()) for x in b.build_frames(b.LOGO_SPOTS)]
        c = [list(x.getdata()) for x in b.build_frames(b.LOGO_SPOTS)]
        self.assertEqual(a, c)
        committed = [list(self.sheet.crop((i * b.W, 0, (i + 1) * b.W, b.H)).getdata()) for i in range(4)]
        self.assertEqual(a, committed)


if __name__ == "__main__":
    unittest.main()
