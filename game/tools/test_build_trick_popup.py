"""Tests for build_trick_popup.py (task T-084). Run with the Python tool tests (needs Pillow)."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_trick_popup as b  # noqa: E402
import style_rules as rules  # noqa: E402

TEXTS = [
    ("FULL 360! +0.25", "normal"),
    ("ALT DRIFT! +0.5", "normal"),
    ("LONG DRIFT! +0.05", "small"),
    ("Trending! +120 Likes", "normal"),
    ("FULL 360!", "normal"),
]


class FontTest(unittest.TestCase):
    def test_font_and_licence_are_in_the_project(self):
        self.assertTrue(b.FONT_PATH.is_file())
        self.assertEqual(b.FONT_PATH.read_bytes()[:4], b"\x00\x01\x00\x00")
        licence = (b.FONT_PATH.parent / "OFL.txt").read_text(encoding="utf-8")
        self.assertIn("SIL OPEN FONT LICENSE Version 1.1", licence)


class PopupTest(unittest.TestCase):
    def test_every_rule_passes_for_each_text(self):
        for text, size in TEXTS:
            rows = b.build_popup(text, size)[0]
            failed = [r for r in b.check_popup(rows) if not r[1]]
            self.assertEqual(failed, [], text)

    def test_only_palette_colours_and_no_redgull_red(self):
        allowed = set(b.PALETTE.values())
        for c in allowed:
            self.assertGreater(b.red_distance(c), b.MIN_RED_DISTANCE, c)
        for c in b.PREVIEW_BG.values():
            self.assertGreater(b.red_distance(c), b.MIN_RED_DISTANCE, c)
        for text, size in TEXTS:
            rows = b.build_popup(text, size)[0]
            self.assertTrue({p[:3] for r in rows for p in r if p[3]} <= allowed, text)
            self.assertTrue({p[3] for r in rows for p in r} <= {0, 255}, text)

    def test_burst_fits_around_the_text_with_a_margin(self):
        for text, size in TEXTS:
            rows, (ox, oy, tw, th), inner = b.build_popup(text, size)
            for y in range(oy - 1, oy + th + 1):
                for x in range(ox - 1, ox + tw + 1):
                    self.assertTrue(inner[y][x], "%s: (%d, %d) not inside the burst fill" % (text, x, y))

    def test_name_is_pink_and_amount_is_cyan(self):
        letters, _ = b.letter_text("FULL 360! +0.25", "normal")
        w = len(letters[0])
        left = {c for r in letters for c in r[:w // 2] if c}
        right = {c for r in letters for c in r[w * 3 // 4:] if c}
        self.assertIn("name", left)
        self.assertIn("name_top", left)
        self.assertNotIn("amount", left)
        self.assertIn("amount", right)
        self.assertNotIn("name", right)

    def test_small_is_smaller_and_wider_text_gives_wider_burst(self):
        normal = b.build_popup("LONG DRIFT! +0.05", "normal")[0]
        small = b.build_popup("LONG DRIFT! +0.05", "small")[0]
        self.assertLess(len(small), len(normal))
        self.assertLess(len(small[0]), len(normal[0]))
        short = b.build_popup("FULL 360!", "normal")[0]
        self.assertLess(len(short[0]), len(normal[0]))

    def test_deterministic(self):
        self.assertEqual(b.build_popup("FULL 360! +0.25")[0], b.build_popup("FULL 360! +0.25")[0])

    def test_split_text(self):
        self.assertEqual(b.split_text("FULL 360! +0.25"), ("FULL 360!", "+0.25"))
        self.assertEqual(b.split_text("FULL 360!"), ("FULL 360!", ""))
        self.assertEqual(b.split_text("Trending! +120 Likes"), ("Trending!", "+120 Likes"))


class SampleTest(unittest.TestCase):
    def test_preview_is_both_backgrounds_side_by_side_and_clean(self):
        rows = b.build_sample()
        w = len(rows[0])
        self.assertEqual(w % 2, 0)
        self.assertEqual(rows[0][0][:3], b.PREVIEW_BG["dark"])
        self.assertEqual(rows[0][w // 2][:3], b.PREVIEW_BG["light"])
        self.assertTrue(all(p[3] == 255 for r in rows for p in r))

    def test_nearest_scale(self):
        src = [[(1, 2, 3, 255), (4, 5, 6, 0)]]
        self.assertEqual(b.scale_nearest(src, 2), [[src[0][0]] * 2 + [src[0][1]] * 2] * 2)

    def test_committed_sample_is_up_to_date(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d) / "s.png"
            b.write_rows(b.build_sample(), out)
            self.assertEqual(out.read_bytes(), b.SAMPLE_PNG.read_bytes())
        with open(b.SAMPLE_PNG, "rb") as f:
            _, _, rows = rules.decode_png(f.read())
        self.assertEqual(rows, b.build_sample())


if __name__ == "__main__":
    unittest.main()
