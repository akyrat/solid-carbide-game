"""Tests for check_level_up_texts.py (task T-173)."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_level_up_texts as check  # noqa: E402

TABLE = """| Key | Title | Description |
|---|---|---|
| get_wiper | Wiper Blade | Sweeps. Very clean. |
| upgrade_wiper.tier2 | Longer Blade | Wiper length up 20%. |
"""

GD = '''const TEXTS := {
	"get_wiper.title": "Wiper Blade",
	"get_wiper.desc": "Sweeps. Very clean.",
	"upgrade_wiper.tier2.title": "Longer Blade",
	"upgrade_wiper.tier2.desc": "Wiper length up 20%.",
}
'''

NEWER = """| Key | File / where it appears | Old | New (final) | Rounds, score |
|---|---|---|---|---|
| upgrade_wiper.tier2.desc | level_up_texts.gd | Wiper length up 20%. | Wiper length up 20%. Greenbull approves. | 1 round |
| TITLE | garage_screen.gd | Redgull Pit Stop | Greenbull pit stop | 1 round |
"""


class CheckLevelUpTextsTest(unittest.TestCase):
    def test_reads_the_table_without_its_header(self):
        rows = check.table_rows(TABLE)
        self.assertEqual(rows, {"get_wiper": ("Wiper Blade", "Sweeps. Very clean."),
                                "upgrade_wiper.tier2": ("Longer Blade", "Wiper length up 20%.")})

    def test_matching_texts_have_no_problems(self):
        self.assertEqual(check.compare(check.table_rows(TABLE), check.gd_texts(GD)), [])

    def test_a_changed_word_and_a_missing_key_are_reported(self):
        gd = GD.replace("Very clean.", "Very  clean.").replace('\t"upgrade_wiper.tier2.desc": "Wiper length up 20%.",\n', "")
        problems = check.compare(check.table_rows(TABLE), check.gd_texts(gd))
        self.assertEqual(len(problems), 2)
        self.assertTrue(problems[0].startswith("differs: get_wiper.desc"))
        self.assertEqual(problems[1], "missing: upgrade_wiper.tier2.desc")

    def test_newer_texts_replace_only_the_keys_they_name(self):
        newer = check.newer_texts(NEWER)
        self.assertEqual(newer, {"upgrade_wiper.tier2.desc": "Wiper length up 20%. Greenbull approves.",
                                 "TITLE": "Greenbull pit stop"})
        rows = check.apply_newer(check.table_rows(TABLE), newer)
        self.assertEqual(rows["upgrade_wiper.tier2"], ("Longer Blade", "Wiper length up 20%. Greenbull approves."))
        self.assertEqual(rows["get_wiper"], ("Wiper Blade", "Sweeps. Very clean."))
        self.assertNotIn("TITLE", rows)

    def test_the_real_files_match_t171s_table_with_t301s_texts(self):
        rows = check.expected_rows()
        self.assertEqual(len(rows), 24)
        self.assertEqual(rows["upgrade_molotov.tier2"][1], "Fire radius up 20%. Greenbull loves a big reveal.")
        texts = check.gd_texts(check.TEXTS_GD.read_text(encoding="utf-8"))
        self.assertEqual(check.compare(rows, texts), [])


if __name__ == "__main__":
    unittest.main()
