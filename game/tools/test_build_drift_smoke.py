"""Tests for build_drift_smoke.py (task T-073). Run with the Python tool tests."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_drift_smoke as b  # noqa: E402
import check_sprite_rules as rules  # noqa: E402


class SpriteTest(unittest.TestCase):
    def setUp(self):
        self.rows = b.draw()

    def test_every_rule_passes(self):
        self.assertEqual([r for r in b.check_rows(self.rows) if not r[1]], [])

    def test_square_sprite_of_the_set_size(self):
        self.assertEqual((len(self.rows), len(self.rows[0])), (b.SIZE, b.SIZE))

    def test_only_opaque_or_transparent_pixels(self):
        self.assertTrue({p[3] for r in self.rows for p in r} <= {0, 255})

    def test_transparent_background_and_a_puff_in_the_middle(self):
        for y, x in ((0, 0), (0, b.SIZE - 1), (b.SIZE - 1, 0), (b.SIZE - 1, b.SIZE - 1)):
            self.assertEqual(self.rows[y][x][3], 0)
        self.assertEqual(self.rows[b.SIZE // 2][b.SIZE // 2][3], 255)

    def test_colours_come_from_the_palette_and_stay_few(self):
        colors = {p[:3] for r in self.rows for p in r if p[3]}
        self.assertTrue(colors <= set(b.PALETTE.values()))
        self.assertLessEqual(len(colors), 30)
        self.assertGreaterEqual(len(colors), 4, "shaded, not flat")

    def test_no_colour_reads_as_red_and_all_are_cool(self):
        for c in b.PALETTE.values():
            self.assertFalse(b.marks.is_redgull_red(c), c)
            self.assertGreater(c[2], c[0])
            self.assertGreater(c[2], c[1])

    def test_the_body_reads_on_both_grounds(self):
        for k, c in b.PALETTE.items():
            if k != "R":
                for ground in (b.ASPHALT, b.GRAVEL):
                    self.assertGreaterEqual(b.marks.luma(c) - b.marks.luma(ground), 40, (k, ground))

    def test_the_edge_is_ragged_not_a_clean_outline(self):
        # chequered outer ring: some texels next to the rim are transparent, in alternation
        gaps = sum(1 for y in range(1, b.SIZE - 1) for x in range(1, b.SIZE - 1)
                   if self.rows[y][x][3] == 0 and any(self.rows[y + dy][x + dx][3] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))))
        self.assertGreater(gaps, 20)

    def test_bands_are_dithered_not_hard_stepped(self):
        # somewhere a lighter tone alternates with a darker one along a row
        lum = lambda p: b.marks.luma(p[:3])
        swaps = sum(1 for r in self.rows for i in range(len(r) - 2)
                    if all(p[3] for p in r[i:i + 3]) and r[i] == r[i + 2] and r[i] != r[i + 1]
                    and r[i + 1] != b.PALETTE["R"] + (255,) and r[i] != b.PALETTE["R"] + (255,))
        self.assertGreater(swaps, 0)

    def test_lit_from_the_top_left(self):
        mean = lambda xs: sum(b.marks.luma(p[:3]) for p in xs) / len(xs)
        half = b.SIZE // 2
        tl = [p for r in self.rows[:half] for p in r[:half] if p[3]]
        br = [p for r in self.rows[half:] for p in r[half:] if p[3]]
        self.assertGreater(mean(tl), mean(br))


class BuildTest(unittest.TestCase):
    def test_build_is_repeatable_and_passes_its_own_check(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            png, js = b.build(d / "a.png", d / "a.json", d / "arch")
            first = png.read_bytes()
            b.build(png, js, d / "arch")
            self.assertEqual(first, png.read_bytes())
            self.assertTrue(all(r[1] for r in b.check_file(png)))
            self.assertEqual(json.loads(js.read_text(encoding="utf-8"))["task"], "T-073")
            self.assertTrue((d / "arch" / "drift_smoke_preview.png").exists())

    def test_the_committed_png_matches_the_script(self):
        _, _, rows = rules.decode_png(b.OUT_PNG.read_bytes())
        self.assertEqual([list(map(tuple, r)) for r in rows], [list(map(tuple, r)) for r in b.draw()])

    def test_check_fails_red_semi_transparent_and_dark_pixels(self):
        rows = [list(r) for r in b.draw()]
        rows[12][12] = (219, 26, 41, 255)
        self.assertTrue(any(not r[1] for r in b.check_rows(rows)))
        rows = [list(r) for r in b.draw()]
        rows[12][12] = (150, 140, 180, 128)
        self.assertTrue(any(not r[1] for r in b.check_rows(rows)))
        rows = [list(r) for r in b.draw()]
        rows[12][12] = (60, 56, 90, 255)
        self.assertTrue(any(not r[1] for r in b.check_rows(rows)))

    def test_main_check_exit_codes(self):
        self.assertEqual(b.main(["check"]), 0)


if __name__ == "__main__":
    unittest.main()
