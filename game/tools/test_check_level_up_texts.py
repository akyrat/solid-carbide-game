"""Tests for check_level_up_texts.py (task T-173)."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_level_up_texts as check  # noqa: E402
from style_rules import OLD_BRAND  # noqa: E402  (the old name, spelled once, T-312)

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
| TITLE | garage_screen.gd | """ + OLD_BRAND + """ Pit Stop | Greenbull pit stop | 1 round |
"""


NEW_TREES = {
    "upgrade_gun.tier2.title": "Extra Bullet",
    "upgrade_gun.tier2.desc": "+1 bullet per volley, 2 in all. A free sample, courtesy of Greenbull.",
    "upgrade_gun.tier3.title": "Another Extra Bullet",
    "upgrade_gun.tier3.desc": "+1 bullet per volley, 3 in all. Greenbull feels generous on camera.",
    "upgrade_gun.tier4.title": "Quicker Trigger",
    "upgrade_gun.tier4.desc": "Fires 20% faster. The audience is getting restless.",
    "upgrade_gun.tier5.title": "Quicker Trigger II",
    "upgrade_gun.tier5.desc": "Fires 20% faster again. Engagement waits for no one.",
    "upgrade_gun.tier6.title": "Bullet Bundle",
    "upgrade_gun.tier6.desc": "+1 bullet per volley, 4 in all. Buy more, shoot more.",
    "upgrade_gun.tier7.title": "Quicker Trigger III",
    "upgrade_gun.tier7.desc": "Fires 20% faster. Content never sleeps.",
    "upgrade_gun.tier8.title": "Exposure for Everyone",
    "upgrade_gun.tier8.desc": "Massively increased fire rate.",
    "upgrade_flamethrower.tier2.title": "Wider Burn",
    "upgrade_flamethrower.tier2.desc": "The flame area grows 20%. More reach, more views.",
    "upgrade_flamethrower.tier3.title": "Hotter Burn",
    "upgrade_flamethrower.tier3.desc": "Flame damage up 20%. Greenbull's hottest take yet, pending legal review.",
    "upgrade_flamethrower.tier4.title": "Wider Burn II",
    "upgrade_flamethrower.tier4.desc": "The flame area grows 30%. Scale your content.",
    "upgrade_flamethrower.tier5.title": "Flammable Material",
    "upgrade_flamethrower.tier5.desc": "Enemies burn for 1 second longer. Looks great on camera.",
    "upgrade_flamethrower.tier6.title": "Wider Burn III",
    "upgrade_flamethrower.tier6.desc": "The flame area grows 30%. Go big or go viral.",
    "upgrade_flamethrower.tier7.title": "Hot Stuff",
    "upgrade_flamethrower.tier7.desc": "Additional 1s burn duration.",
    "upgrade_flamethrower.tier8.title": "Lit 24/7",
    "upgrade_flamethrower.tier8.desc": "The flame never goes out, even when you aren't drifting. Spark it up.",
    "upgrade_molotov.tier2.title": "Bigger Blaze",
    "upgrade_molotov.tier2.desc": "Fire radius up 20%. Greenbull loves a big reveal.",
    "upgrade_molotov.tier3.title": "Quick Throw",
    "upgrade_molotov.tier3.desc": "Throws 20% sooner, every 2.4 seconds. Content never sleeps.",
    "upgrade_molotov.tier4.title": "Another one",
    "upgrade_molotov.tier4.desc": "Additional molotov thrown.",
    "upgrade_molotov.tier5.title": "ANOTHER ONE",
    "upgrade_molotov.tier5.desc": "Throw 3 molotovs at once. Triple the content.",
    "upgrade_molotov.tier6.title": "Quick Fire",
    "upgrade_molotov.tier6.desc": "Throws molotovs 30% faster.",
    "upgrade_molotov.tier7.title": "Bigger Blaze II",
    "upgrade_molotov.tier7.desc": "Fire radius up another 30%. Think bigger.",
    "upgrade_molotov.tier8.title": "MOREEEE",
    "upgrade_molotov.tier8.desc": "Additional Molotov.",
    "upgrade_bricks.tier2.title": "Wider Wave",
    "upgrade_bricks.tier2.desc": "Each landing's impact wave reaches further. Greenbull calls it ground-breaking content.",
    "upgrade_bricks.tier3.title": "Harder Landing",
    "upgrade_bricks.tier3.desc": "Your landing wave hits harder. Greenbull calls it a high-impact brand activation.",
    "upgrade_bricks.tier4.title": "Shove Factor",
    "upgrade_bricks.tier4.desc": "Impact waves knock minions back harder. Never the kaiju; it doesn't take feedback.",
    "upgrade_bricks.tier5.title": "Wider Wave II",
    "upgrade_bricks.tier5.desc": "Each landing's wave spreads wider again. Greenbull calls it expanding the brand footprint.",
    "upgrade_bricks.tier6.title": "Harder Landing II",
    "upgrade_bricks.tier6.desc": "Your landing wave hits harder again. Greenbull is trademarking the thud.",
    "upgrade_bricks.tier7.title": "Shove Factor II",
    "upgrade_bricks.tier7.desc": "Landing waves shove minions even further, never the kaiju. Greenbull calls it outreach.",
    "upgrade_bricks.tier8.title": "Widest Wave",
    "upgrade_bricks.tier8.desc": "Your landing wave reaches its widest yet. Brace for impact!",
    "upgrade_wiper.tier2.title": "Longer Blade",
    "upgrade_wiper.tier2.desc": "Wiper length up 20%. Clean up more of the city.",
    "upgrade_wiper.tier3.title": "Faster Sweep",
    "upgrade_wiper.tier3.desc": "Wiper sweeps 25% faster. No streaks left behind.",
    "upgrade_wiper.tier4.title": "Hard Shove",
    "upgrade_wiper.tier4.desc": "Knockback up 50%, from 6 to 9. Minions only, never the kaiju.",
    "upgrade_wiper.tier5.title": "Even Longer Blade",
    "upgrade_wiper.tier5.desc": "Blade length x1.3, stacking on the earlier x1.2. Every extra inch sold as ad space.",
    "upgrade_wiper.tier6.title": "Faster Sweep II",
    "upgrade_wiper.tier6.desc": "Wiper sweeps another 30% faster. Always in frame.",
    "upgrade_wiper.tier7.title": "Longest Blade!",
    "upgrade_wiper.tier7.desc": "Blade length x1.3 again. The longest wiper ever streamed, pending a longer one.",
    "upgrade_wiper.tier8.title": "Back Wiper",
    "upgrade_wiper.tier8.desc": "A copy of your front wiper sweeps behind, upgrades and all. Rear-view content, monetised.",
}


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

    def test_the_real_files_keep_t171s_underglow_finale_as_tier_5(self):
        # T-519 (5-tier trees): T-171's rows for the get cards and the underglow's tiers 2 to 7 were
        # rewritten (pinned in game/tools/test_four_minute_run_texts.py); the underglow's old tier 8
        # row (Blinding Glow) is now its tier 5 and stays word for word.
        rows = check.expected_rows()
        self.assertEqual(len(rows), 24)
        texts = check.gd_texts(check.TEXTS_GD.read_text(encoding="utf-8"))
        title, desc = rows["upgrade_underglow.tier8"]
        self.assertEqual(texts["upgrade_underglow.tier5.title"], title)
        self.assertEqual(texts["upgrade_underglow.tier5.desc"], desc)

    def test_the_real_file_has_the_boards_finales_as_tier_5(self):
        # T-519: the old tier 8 cards are the new tier 5 cards (Exposure for Everyone, Lit 24/7,
        # MOREEEE, Back Wiper, Widest Wave); no tier 6 to 11 card is left.
        texts = check.gd_texts(check.TEXTS_GD.read_text(encoding="utf-8"))
        for key, want in NEW_TREES.items():
            if key.endswith(".title") and key.rsplit(".", 2)[1] == "tier8":
                new_key = key.replace("tier8", "tier5")
                self.assertEqual(texts.get(new_key), want, new_key)
        for n in range(6, 12):
            self.assertNotIn("upgrade_gun.tier%d.title" % n, texts)


if __name__ == "__main__":
    unittest.main()
