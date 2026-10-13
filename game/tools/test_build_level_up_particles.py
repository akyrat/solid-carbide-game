"""Tests for build_level_up_particles.py (task T-074). Run with the Python tool tests."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_level_up_particles as b  # noqa: E402
import check_sprite_rules as rules  # noqa: E402


class SheetTest(unittest.TestCase):
    def setUp(self):
        self.rows = b.build_sheet()

    def test_sheet_size_is_one_row_of_frames(self):
        self.assertEqual(len(self.rows), b.FRAME)
        self.assertEqual(len(self.rows[0]), b.FRAME * len(b.SHAPES))

    def test_every_rule_passes(self):
        results = b.check_rows(self.rows, len(b.SHAPES))
        failed = [r for r in results if not r[1]]
        self.assertEqual(failed, [])

    def test_only_opaque_or_transparent_pixels(self):
        alphas = {p[3] for r in self.rows for p in r}
        self.assertTrue(alphas <= {0, 255})

    def test_colours_come_from_the_palette_and_stay_few(self):
        colors = {p[:3] for r in self.rows for p in r if p[3]}
        self.assertTrue(colors <= set(b.PALETTE.values()))
        self.assertLessEqual(len(colors), 30)

    def test_no_colour_reads_as_red(self):
        for c in b.PALETTE.values():
            self.assertFalse(b.is_redgull_red(c), c)

    def test_every_frame_has_a_white_hot_core_and_a_clear_corner(self):
        for i, fr in enumerate(rules.split_sheet(self.rows, len(b.SHAPES))):
            self.assertIn(b.PALETTE["W"] + (255,), [p for r in fr for p in r], "frame %d" % i)
            self.assertEqual(fr[0][0][3], 0)
            self.assertEqual(fr[b.FRAME // 2][b.FRAME // 2], b.PALETTE["W"] + (255,), "core in the centre, frame %d" % i)

    def test_shapes_are_symmetric(self):
        for name, grid in b.SHAPES:
            self.assertEqual(grid, grid[::-1], name)
            self.assertEqual(grid, [r[::-1] for r in grid], name)


class RedCheckTest(unittest.TestCase):
    def test_redgull_red_and_reds_are_caught(self):
        self.assertTrue(b.is_redgull_red(b.REDGULL_RED))
        self.assertTrue(b.is_redgull_red((255, 0, 0)))
        self.assertTrue(b.is_redgull_red((200, 40, 60)))

    def test_neon_pink_cyan_violet_pass(self):
        for c in [(255, 64, 200), (0, 229, 255), (160, 90, 255), (255, 255, 255)]:
            self.assertFalse(b.is_redgull_red(c), c)

    def test_check_fails_a_sheet_with_red_or_semi_transparent_pixels(self):
        rows = [list(r) for r in b.build_sheet()]
        rows[5][5] = b.REDGULL_RED + (255,)
        rows[5][16] = (0, 229, 255, 128)
        failed = {r[0] for r in b.check_rows(rows, len(b.SHAPES)) if not r[1]}
        self.assertIn("no Redgull red (nor any red)", failed)
        self.assertIn("whole sheet: no semi-transparent pixels", failed)

    def test_check_fails_an_opaque_corner(self):
        rows = [list(r) for r in b.build_sheet()]
        rows[0][0] = (0, 229, 255, 255)
        failed = [r[0] for r in b.check_rows(rows, len(b.SHAPES)) if not r[1]]
        self.assertTrue(any("frame 0" in f and "transparent background" in f for f in failed), failed)


class FilesTest(unittest.TestCase):
    def test_committed_files_are_up_to_date(self):
        with tempfile.TemporaryDirectory() as d:
            png, js = b.build(Path(d) / "p.png", Path(d) / "p.json")
            self.assertEqual(png.read_bytes(), b.OUT_PNG.read_bytes(), "run the build command")
            self.assertEqual(js.read_text(encoding="utf-8"), b.OUT_JSON.read_text(encoding="utf-8"))

    def test_committed_png_passes_the_check(self):
        self.assertTrue(all(r[1] for r in b.check_file(b.OUT_PNG)))
        self.assertEqual(b.main(["check"]), 0)

    def test_record_is_not_a_pixellab_record(self):
        rec = json.loads(b.OUT_JSON.read_text(encoding="utf-8"))
        self.assertNotIn("endpoint", rec)
        self.assertEqual(len(rec["frames"]), len(b.SHAPES))


if __name__ == "__main__":
    unittest.main()
