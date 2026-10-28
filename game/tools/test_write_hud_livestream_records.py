"""Tests for write_hud_livestream_records.py (T-339)."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import write_hud_livestream_records as rec  # noqa: E402

REVIEW = """
### Run 1

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-339/briefs/clock_digits.md`. Generator...

#### Round 1

- Score: 8/10

**Kept:** version 1, score 8/10 (`art-archive/T-339/style-loop/v1.png`, copied to `game/art/hud/clock_digits.png`): ok.

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-339/briefs/viewers_fire.md`. Generator...

#### Round 1

- Score: 7/10

#### Round 2

- Score: 6/10

**Kept:** version 1, score 7/10 (`art-archive/T-339/style-loop/v1-5.png`, copied to `game/art/hud/viewers_fire.png`): flagged.
"""


class Records(unittest.TestCase):
    def test_runs_by_brief(self):
        runs = rec.runs(REVIEW)
        self.assertEqual(set(runs), {"clock_digits", "viewers_fire"})

    def test_kept(self):
        runs = rec.runs(REVIEW)
        self.assertEqual(rec.kept(runs["viewers_fire"]),
                         {"version": 1, "score": 7, "file": "art-archive/T-339/style-loop/v1-5.png",
                          "round_scores": [7, 6]})
        self.assertIsNone(rec.kept("no kept line"))

    def test_every_asset_is_listed_with_its_brief(self):
        for name, (brief, what, frames) in rec.ASSETS.items():
            self.assertEqual(name, brief)
            self.assertTrue(what)
        self.assertEqual(len(rec.SPLITS["clock_digits"]), 12)
        self.assertEqual(len(rec.SPLITS["viewers_fire"]), 12)


if __name__ == "__main__":
    unittest.main()
