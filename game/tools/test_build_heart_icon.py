"""Tests for build_heart_icon.py (task T-086). Run with the Python tool tests."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_heart_icon as b  # noqa: E402


class HeartTest(unittest.TestCase):
    def test_rules_pass(self):
        self.assertEqual([r for r in b.check_rows(b.rows()) if not r[1]], [])

    def test_size_and_two_colours(self):
        icon = b.rows()
        self.assertEqual((len(icon[0]), len(icon)), (11, 10))
        self.assertEqual({p[:3] for r in icon for p in r if p[3]}, {b.RED, b.OUTLINE})
        self.assertTrue({p[3] for r in icon for p in r} <= {0, 255})

    def test_outline_surrounds_the_red(self):
        icon = b.rows()
        for y, r in enumerate(icon):
            for x, p in enumerate(r):
                if p[:3] == b.RED and p[3]:
                    for dx in (-1, 0, 1):
                        for dy in (-1, 0, 1):
                            self.assertTrue(icon[y + dy][x + dx][3], (x, y))

    def test_symmetric(self):
        for r in b.rows():
            self.assertEqual(r, r[::-1])

    def test_build_is_repeatable_and_checks(self):
        with tempfile.TemporaryDirectory() as t1, tempfile.TemporaryDirectory() as t2:
            a1, a2 = Path(t1), Path(t2)
            b.build(a1 / "o", a1 / "a")
            b.build(a2 / "o", a2 / "a")
            self.assertEqual((a1 / "o" / "likes_heart.png").read_bytes(), (a2 / "o" / "likes_heart.png").read_bytes())
            self.assertTrue(all(r[1] for r in b.check(a1 / "o" / "likes_heart.png")))

    def test_committed_png_matches_the_script(self):
        if b.PNG.exists():
            with tempfile.TemporaryDirectory() as t:
                b.build(Path(t) / "o", Path(t) / "a")
                self.assertEqual(b.PNG.read_bytes(), (Path(t) / "o" / "likes_heart.png").read_bytes())


if __name__ == "__main__":
    unittest.main()
