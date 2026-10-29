"""Tests for build_trick_illustrations.py (task T-383). Run: python -m unittest discover game/tools -p "test_build_trick_illustrations.py" """
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_trick_illustrations as b  # noqa: E402
import style_rules  # noqa: E402

TRICKS_MD = Path(__file__).resolve().parents[1] / "docs" / "driving" / "tricks.md"


class TrickIllustrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.paths = b.build(Path(cls.tmp.name))

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_ids_match_tricks_doc(self):
        text = TRICKS_MD.read_text(encoding="utf-8")
        for tid in b.TRICK_IDS:
            self.assertIn("`%s`" % tid, text)
        self.assertEqual(len(b.TRICK_IDS), 7)

    def test_seven_files_same_size(self):
        self.assertEqual(sorted(p.stem for p in self.paths), sorted(b.TRICK_IDS))
        for p in self.paths:
            self.assertEqual(Image.open(p).size, (64, 48))

    def test_style_rules_pass(self):
        for p in self.paths:
            im = Image.open(p).convert("RGBA")
            rows = [[im.getpixel((x, y)) for x in range(im.width)] for y in range(im.height)]
            results = style_rules.art_checks(rows, size=(64, 48))
            bad = [r for r in results if not r["ok"]]
            self.assertEqual(bad, [], p.name)

    def test_has_a_path_and_differs(self):
        seen = set()
        for p in self.paths:
            im = Image.open(p).convert("RGBA")
            self.assertGreater(sum(1 for px in im.getdata() if px[3]), 150, p.name)
            seen.add(im.tobytes())
        self.assertEqual(len(seen), 7)

    def test_deterministic(self):
        a = b.draw("three_sixty").tobytes()
        self.assertEqual(a, b.draw("three_sixty").tobytes())

    def test_refuses_overwrite(self):
        with self.assertRaises(SystemExit):
            b.build(Path(self.tmp.name), only="airtime")

    def test_sheet(self):
        out = b.sheet(Path(self.tmp.name), Path(self.tmp.name) / "s.png", (24, 26, 40), scale=2)
        self.assertTrue(out.exists())


if __name__ == "__main__":
    unittest.main()
