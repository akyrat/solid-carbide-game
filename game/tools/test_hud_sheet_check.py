"""Tests for hud_sheet_check.py (T-430, the HUD style sheet's art checks)."""
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hud_livestream_art as art  # noqa: E402
import hud_sheet_check as sheet  # noqa: E402


class Checks(unittest.TestCase):
    def test_panels_have_the_sheets_corner(self):
        for im in (art.panel(100, 36), art.panel(120, 36, rim=art.VIEWERS), art.subgoal_frame(64), art.live_badge()):
            self.assertEqual(sheet.corner_radius(im), 2)
            self.assertTrue(sheet.corner_ok(im))

    def test_the_old_radius_3_corner_fails(self):
        self.assertFalse(sheet.corner_ok(art.subgoal_frame(64, radius=3)))

    def test_outline_breaks_are_counted(self):
        im = art.subgoal_frame(64)
        self.assertEqual(sheet.outline_breaks(im), [])
        im.putpixel((20, 0), (255, 255, 255, 255))
        self.assertEqual(sheet.outline_breaks(im), [(20, 0)])

    def test_every_kept_hud_piece_passes_the_sheet(self):
        for path in sheet.hud_files():
            with self.subTest(piece=path.name):
                self.assertEqual(sheet.check(path), [])

    def test_greenbull_is_found(self):
        im = Image.new("RGBA", (4, 4), (0, 0, 0, 0))
        im.putpixel((1, 1), (104, 220, 96, 255))
        self.assertTrue(sheet.greenbull_pixels(im))


if __name__ == "__main__":
    unittest.main()
