"""Tests for build_drift_mark.py (task T-118). Run with the Python tool tests."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_drift_mark as b  # noqa: E402


class TileTest(unittest.TestCase):
    def setUp(self):
        self.rows = b.draw()

    def test_every_rule_passes(self):
        failed = [r for r in b.check_rows(self.rows) if not r[1]]
        self.assertEqual(failed, [])

    def test_only_opaque_or_transparent_pixels(self):
        self.assertTrue({p[3] for r in self.rows for p in r} <= {0, 255})

    def test_colours_come_from_the_palette_and_stay_few(self):
        colors = {p[:3] for r in self.rows for p in r if p[3]}
        self.assertTrue(colors <= set(b.PALETTE.values()))
        self.assertLessEqual(len(colors), 30)
        self.assertGreater(len(colors), 1, "a tread pattern, not a flat line")

    def test_no_colour_reads_as_red_and_all_are_darker_than_both_grounds(self):
        for c in b.PALETTE.values():
            self.assertFalse(b.is_redgull_red(c), c)
            self.assertLess(b.luma(c), b.luma(b.ASPHALT), c)
            self.assertLess(b.luma(c), b.luma(b.GRAVEL), c)

    def test_transparent_only_in_the_shoulder_rows(self):
        for y, r in enumerate(self.rows):
            if 0 < y < len(self.rows) - 1:
                self.assertTrue(all(p[3] == 255 for p in r), "row %d" % y)
        self.assertTrue(any(p[3] == 0 for p in self.rows[0]))
        self.assertTrue(any(p[3] == 0 for p in self.rows[-1]))

    def test_the_tread_has_grooves_in_every_inner_row(self):
        for line in b.TREAD[1:-1]:
            self.assertIn("G", line)
            self.assertIn("K", line)

    def test_the_tread_is_a_symmetric_chevron(self):
        self.assertEqual(b.TREAD, b.TREAD[::-1], "same across both halves of the mark")
        starts = [line.index("G") for line in b.TREAD[1:-1]]
        half = len(starts) // 2
        self.assertEqual(starts[:half], sorted(starts[:half], reverse=True), "grooves slant one way, then back")


class CheckTest(unittest.TestCase):
    def test_redgull_red_and_reds_are_caught(self):
        self.assertTrue(b.is_redgull_red(b.REDGULL_RED))
        self.assertTrue(b.is_redgull_red((255, 0, 0)))

    def test_check_fails_red_semi_transparent_and_light_pixels(self):
        rows = [list(r) for r in b.draw()]
        rows[2][1] = b.REDGULL_RED + (255,)
        rows[3][1] = (12, 10, 20, 128)
        rows[4][1] = (200, 200, 220, 255)
        failed = {r[0] for r in b.check_rows(rows) if not r[1]}
        self.assertIn("no Redgull red (nor any red)", failed)
        self.assertIn("no semi-transparent pixels", failed)
        self.assertIn("every colour darker than the asphalt and the gravel", failed)

    def test_check_fails_a_gap_inside_the_mark_and_an_opaque_corner(self):
        rows = [list(r) for r in b.draw()]
        rows[3][0] = (0, 0, 0, 0)
        rows[0][0] = b.PALETTE["E"] + (255,)
        failed = {r[0] for r in b.check_rows(rows) if not r[1]}
        self.assertIn("rows inside the mark fully opaque (no gap at the tile join)", failed)
        self.assertIn("transparent background (corners)", failed)

    def test_long_shoulder_gap_across_the_join_fails(self):
        rows = [list(r) for r in b.draw()]
        rows[0] = [(0, 0, 0, 0)] * 2 + rows[0][2:-2] + [(0, 0, 0, 0)] * 2
        rows[0][2] = (0, 0, 0, 0)
        failed = {r[0] for r in b.check_rows(rows) if not r[1]}
        self.assertIn("shoulder gaps at most 2 texels, also across the join", failed)

    def test_wrapped_gap(self):
        t, o = (0, 0, 0, 0), (1, 1, 1, 255)
        self.assertEqual(b._longest_wrapped_gap([t, o, o, t]), 2)
        self.assertEqual(b._longest_wrapped_gap([t, t, t]), 3)


class FilesTest(unittest.TestCase):
    def test_committed_files_are_up_to_date(self):
        with tempfile.TemporaryDirectory() as d:
            png, js = b.build(Path(d) / "m.png", Path(d) / "m.json", Path(d) / "archive")
            self.assertEqual(png.read_bytes(), b.OUT_PNG.read_bytes(), "run the build command")
            self.assertEqual(js.read_text(encoding="utf-8"), b.OUT_JSON.read_text(encoding="utf-8"))
            for f in (Path(d) / "archive").iterdir():
                self.assertEqual(f.read_bytes(), (b.ARCHIVE / f.name).read_bytes(), f.name)

    def test_committed_png_passes_the_check(self):
        self.assertTrue(all(r[1] for r in b.check_file(b.OUT_PNG)))
        self.assertEqual(b.main(["check"]), 0)

    def test_record_is_not_a_pixellab_record(self):
        rec = json.loads(b.OUT_JSON.read_text(encoding="utf-8"))
        self.assertNotIn("endpoint", rec)
        self.assertEqual(rec["tread"], b.TREAD)

    def test_preview_shows_both_grounds(self):
        rows = b.preview(tiles=2, scale=1)
        flat = {p[:3] for r in rows for p in r}
        self.assertIn(b.ASPHALT, flat)
        self.assertIn(b.GRAVEL, flat)


if __name__ == "__main__":
    unittest.main()
