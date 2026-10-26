"""Tests for greenbull_wordmark.py (task T-295). Run with the Python tool tests."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import greenbull_wordmark as w  # noqa: E402


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


if __name__ == "__main__":
    unittest.main()
