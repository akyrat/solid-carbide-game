"""Tests for build_hit_coin_damage_effects.py (task T-072). Run with the Python tool tests."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hit_coin_damage_effects as b  # noqa: E402


class EffectsArtTest(unittest.TestCase):
    def test_every_frame_passes_the_rules(self):
        for name, rows in b.sheets().items():
            bad = [r for r in b.check_sheet_rows(name, rows) if not r[1]]
            self.assertEqual(bad, [], name)

    def test_sheet_sizes(self):
        for name, rows in b.sheets().items():
            frames, (fw, fh) = b.SETS[name]
            self.assertEqual((len(rows[0]), len(rows)), (frames * fw, fh), name)

    def test_no_frame_is_empty(self):
        for name, rows in b.sheets().items():
            frames, (fw, _) = b.SETS[name]
            for i in range(frames):
                self.assertTrue(any(p[3] for r in rows for p in r[i * fw:(i + 1) * fw]), (name, i))

    def test_coin_has_a_dark_outline_all_round(self):
        coin = b.coin_rows()
        for y, r in enumerate(coin):
            for x, p in enumerate(r):
                if p[3] and p[:3] != b.OUTLINE:
                    for dx in (-1, 0, 1):
                        for dy in (-1, 0, 1):
                            self.assertTrue(coin[y + dy][x + dx][3], (x, y))

    def test_build_is_repeatable_and_checks(self):
        with tempfile.TemporaryDirectory() as t1, tempfile.TemporaryDirectory() as t2:
            a1, a2 = Path(t1), Path(t2)
            b.build(a1 / "o", a1 / "a")
            b.build(a2 / "o", a2 / "a")
            for name in b.SETS:
                self.assertEqual((a1 / "o" / f"{name}.png").read_bytes(), (a2 / "o" / f"{name}.png").read_bytes())
            self.assertTrue(all(r[1] for r in b.check(a1 / "o")))


if __name__ == "__main__":
    unittest.main()
