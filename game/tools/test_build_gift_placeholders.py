"""Tests for build_gift_placeholders.py (task T-144). Run with the Python tool tests."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_gift_placeholders as b  # noqa: E402


class GiftPlaceholdersTest(unittest.TestCase):
    def test_rules_pass_for_both(self):
        self.assertEqual([r for r in b.check_rows(b.helicopter_rows(), b.HELICOPTER_SIZE) if not r[1]], [])
        self.assertEqual([r for r in b.check_rows(b.package_rows(), b.PACKAGE_SIZE) if not r[1]], [])

    def test_no_red_in_the_palette(self):
        for c in (b.OUTLINE, b.DARK, b.BODY, b.BODY_DARK, b.WINDOW, b.BOX, b.BOX_DARK, b.LID, b.RIBBON):
            self.assertFalse(b.marks.is_redgull_red(c), c)

    def test_check_finds_a_red_pixel(self):
        img = b.package_rows()
        img[8][8] = (219, 26, 41, 255)
        failed = [r[0] for r in b.check_rows(img, b.PACKAGE_SIZE) if not r[1]]
        self.assertIn("no Redgull red, no red", failed)

    def test_build_is_byte_identical_and_matches_the_committed_pngs(self):
        with tempfile.TemporaryDirectory() as d:
            b.build(d)
            for name in (b.HELICOPTER_PNG.name, b.PACKAGE_PNG.name):
                new = (Path(d) / name).read_bytes()
                self.assertEqual(new, (b.OUT_DIR / name).read_bytes(), name + " is out of date: run build")

    def test_committed_pngs_pass_check(self):
        self.assertEqual([r for r in b.check() if not r[1]], [])


if __name__ == "__main__":
    unittest.main()
