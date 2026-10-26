"""Tests for greenbull_wordmark.py (task T-295). Run with the Python tool tests."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import greenbull_wordmark as w  # noqa: E402
import art_preview  # noqa: E402
from PIL import Image  # noqa: E402


@unittest.skipUnless(w.EMBLEM.exists(), "T-295 emblem not in art-archive")
class WordmarkTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.img, cls.emblem, cls.word_size = w.render()

    def test_size_mode_and_checks(self):
        self.assertEqual(self.img.size, w.CANVAS)
        self.assertEqual(self.img.mode, "RGBA")
        self.assertEqual(w.check(self.img, self.emblem), [])

    def test_emblem_pasted_unchanged(self):
        oy = (w.CANVAS[1] - self.emblem.height) // 2
        crop = self.img.crop((0, oy, self.emblem.width, oy + self.emblem.height))
        self.assertEqual(list(crop.getdata()), list(self.emblem.getdata()))

    def test_letters_same_height(self):
        heights = {len({y for _, y in w.glyph_mask(ch)}) for ch in set(w.WORD)}
        self.assertEqual(heights, {w.GLYPH_H})

    def test_face_fully_outlined(self):
        px = w.word_layer(w.WORD)
        for (x, y), c in px.items():
            if c != w.OUTLINE:
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        self.assertIn((x + dx, y + dy), px)

    def test_no_yellow_in_letters(self):
        self.assertNotIn(w.YELLOW, set(w.word_layer(w.WORD).values()))

    def test_refuses_overwrite_and_is_repeatable(self):
        with tempfile.TemporaryDirectory() as t:
            out = Path(t) / "v.png"
            self.assertEqual(w.main(["x", str(out)]), 0)
            first = out.read_bytes()
            self.assertEqual(w.main(["x", str(out)]), 1)
            self.assertEqual(out.read_bytes(), first)
            out2 = Path(t) / "v2.png"
            w.main(["x", str(out2)])
            self.assertEqual(out2.read_bytes(), first)


@unittest.skipUnless(w.EMBLEM.exists(), "T-295 emblem not in art-archive")
class DarkSchemeTest(unittest.TestCase):
    """Run 2: dark green must lead in the letters."""

    def test_checks_pass(self):
        img, emblem, _ = w.render(scheme="dark")
        self.assertEqual(w.check(img, emblem), [])

    def test_dark_green_leads(self):
        cols = list(w.word_layer(w.WORD, "dark").values())
        self.assertGreater(cols.count(w.DARK), cols.count(w.LIGHT))
        self.assertGreater(cols.count(w.LIGHT), 0)
        self.assertNotIn(w.YELLOW, cols)

    def test_same_shape_as_light_scheme(self):
        self.assertEqual(set(w.word_layer(w.WORD, "dark")), set(w.word_layer(w.WORD, "light")))

    def test_bad_scheme_refused(self):
        with tempfile.TemporaryDirectory() as t:
            out = Path(t) / "v.png"
            self.assertEqual(w.main(["x", "--scheme", "nope", str(out)]), 2)
            self.assertFalse(out.exists())


ROOT_T295 = w.ROOT / "art-archive" / "T-295"


@unittest.skipUnless(w.EMBLEM.exists(), "T-295 emblem not in art-archive")
class BothSchemesTest(unittest.TestCase):
    """Both variants: 256 x 64, only the emblem's 5 colours, no semi-transparent pixels."""

    def test_size_palette_and_alpha(self):
        for scheme in w.SCHEMES:
            with self.subTest(scheme=scheme):
                img, emblem, _ = w.render(scheme=scheme)
                self.assertEqual(img.size, (256, 64))
                emblem_cols = {c for c in emblem.getdata() if c[3] == 255}
                self.assertEqual(len(emblem_cols), 5)
                opaque = {c for c in img.getdata() if c[3] == 255}
                self.assertEqual(opaque, emblem_cols)
                self.assertFalse([c for c in img.getdata() if 0 < c[3] < 255])

    def test_yellow_smallest(self):
        for scheme in w.SCHEMES:
            img, _, _ = w.render(scheme=scheme)
            cols = list(img.getdata())
            self.assertLess(cols.count(w.YELLOW), min(cols.count(w.DARK), cols.count(w.LIGHT)))

    def test_rebuilds_kept_versions(self):
        kept = {"light": ROOT_T295 / "greenbull_wordmark.png",
                "dark": ROOT_T295 / "greenbull_wordmark_run2.png"}
        for scheme, path in kept.items():
            if path.exists():
                img, _, _ = w.render(scheme=scheme)
                self.assertEqual(list(img.getdata()),
                                 list(Image.open(path).convert("RGBA").getdata()))


class ArtPreviewTest(unittest.TestCase):
    def test_preview_size_and_counts(self):
        im = Image.new("RGBA", (4, 2), (0, 0, 0, 0))
        im.putpixel((3, 0), w.DARK)
        im.putpixel((0, 1), w.LIGHT)
        out = art_preview.preview(im, scale=3, gap=8)
        self.assertEqual(out.size, (12, 2 * 6 + 8))
        self.assertEqual(out.getpixel((0, 0)), art_preview.DARK_BG)
        self.assertEqual(out.getpixel((9, 0)), w.DARK)
        self.assertEqual(out.getpixel((0, 6 + 8)), art_preview.LIGHT_BG)
        self.assertEqual(art_preview.colour_counts(im), {w.DARK: 1, w.LIGHT: 1})
        self.assertEqual(art_preview.colour_counts(im, from_x=2), {w.DARK: 1})


if __name__ == "__main__":
    unittest.main()
