"""Tests for build_helicopter.py (tasks T-145, T-305). Run with the Python tool tests."""
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_helicopter as b  # noqa: E402
import style_rules as rules  # noqa: E402


def frames_of(sheet):
    return [sheet.crop((i * b.W, 0, (i + 1) * b.W, b.H)) for i in range(b.FRAMES)]


class HelicopterSheetTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sheet = Image.open(b.SHEET).convert("RGBA")
        cls.built = b.build_frames(b.LOGO_SPOTS)

    def test_sheet_keeps_four_frames_of_192_by_160(self):
        # gift_helicopter.tscn slices the sheet into 4 frames of 192 x 160
        self.assertEqual((b.W, b.H, b.FRAMES), (192, 160, 4))
        self.assertEqual(self.sheet.size, (b.W * 4, b.H))

    def test_each_frame_follows_the_sprite_rules(self):
        for f in frames_of(self.sheet):
            r = b.frame_report(f)
            self.assertTrue(r["transparent_corners"])
            self.assertEqual(r["semi_transparent_pixels"], 0)
            self.assertLessEqual(r["colours"], 30)

    def test_whole_sheet_has_at_most_30_colours(self):
        self.assertLessEqual(len({p[:3] for p in self.sheet.getdata() if p[3] == 255}), 30)

    def test_no_redgull_red_pixel(self):
        self.assertEqual(b.red_pixels(self.sheet), [])

    def test_greenbull_dark_green_leads_and_light_green_is_there(self):
        cols = [p[:3] for p in self.sheet.getdata() if p[3] == 255]
        self.assertIn(rules.GREENBULL_DARK_GREEN, cols)
        self.assertIn(rules.GREENBULL_LIGHT_GREEN, cols)
        greens = sum(1 for c in cols if c[1] > c[0] and c[1] > c[2])
        reds = sum(1 for c in cols if c[0] > c[1] + 20 and c[0] > c[2])
        self.assertGreater(greens, len(cols) // 3)
        self.assertGreater(greens, 10 * max(1, reds))

    def test_emblem_is_stamped_in_its_own_colours_and_the_gull_is_gone(self):
        cols = {p[:3] for p in self.sheet.getdata() if p[3] == 255}
        pal = set(b.emblem_palette())
        self.assertGreaterEqual(len(pal & cols), 3)
        self.assertIn(b.PANEL, cols)
        self.assertNotIn(rules.REDGULL_RED, cols)
        self.assertIn("greenbull_emblem", b.LOGO.name)

    def test_emblem_fits_its_spot(self):
        rows = b.emblem(18)
        self.assertEqual((len(rows), len(rows[0])), (18, 18))
        self.assertTrue(any(c is not None for r in rows for c in r))
        self.assertTrue(all(c in set(b.emblem_palette()) for r in rows for c in r if c is not None))

    def test_frames_differ_by_the_rotor(self):
        f = [list(x.getdata()) for x in frames_of(self.sheet)]
        self.assertNotEqual(f[0], f[1])

    def test_build_is_deterministic_and_matches_the_committed_sheet(self):
        a = [list(x.getdata()) for x in self.built]
        c = [list(x.getdata()) for x in b.build_frames(b.LOGO_SPOTS)]
        self.assertEqual(a, c)
        committed = [list(x.getdata()) for x in frames_of(self.sheet)]
        self.assertEqual(a, committed)

    def test_piece_writes_the_same_sheet_without_touching_the_record(self):
        before = b.RECORD.read_text()
        with tempfile.TemporaryDirectory() as d:
            out = Path(d) / "piece.png"
            b.build(out, record=False)
            self.assertEqual(list(Image.open(out).convert("RGBA").getdata()), list(self.sheet.getdata()))
        self.assertEqual(b.RECORD.read_text(), before)

    def test_old_redgull_sheet_is_archived(self):
        old = b.OLD_ARCHIVE / "helicopter_sheet.png"
        self.assertTrue(old.exists())
        with Image.open(old) as im:
            self.assertEqual(im.size, self.sheet.size)


if __name__ == "__main__":
    unittest.main()
