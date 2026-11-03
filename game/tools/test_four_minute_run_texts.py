"""Tests for T-519's texts: the 5-tier level-up cards, the 2-tier power-up cards, the heal popup,
and no player-facing text naming the old 8-minute run.

Run from the repo root: python -m unittest game.tools.test_four_minute_run_texts
"""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "game" / "data"
CARDS = ROOT / "game" / "scripts" / "ui" / "level_up_texts.gd"
ENTRY = re.compile(r'^\s*"([^"]+)":\s*"((?:[^"\\]|\\.)*)",?\s*$')
WEAPONS = ["gun", "flamethrower", "underglow", "molotov", "wiper", "bricks"]
GET_CARDS = ["get_flamethrower", "get_underglow", "get_molotov", "get_wiper", "get_bricks"]


def cards() -> dict:
    out = {}
    for line in CARDS.read_text(encoding="utf-8").splitlines():
        m = ENTRY.match(line)
        if m:
            out[m.group(1)] = m.group(2)
    return out


class CardTexts(unittest.TestCase):
    def test_every_weapon_has_text_for_tiers_2_to_5_and_none_beyond(self):
        t = cards()
        weapons_json = json.loads((DATA / "weapons.json").read_text(encoding="utf-8"))
        for w in WEAPONS:
            self.assertIn(w, weapons_json)
            card = "upgrade_" + w
            for tier in range(2, 6):
                for part in ("title", "desc"):
                    self.assertTrue(t.get(f"{card}.tier{tier}.{part}"), f"{card}.tier{tier}.{part}")
            for tier in range(6, 12):
                self.assertNotIn(f"{card}.tier{tier}.title", t, "the 8-tier trees are gone")

    def test_every_new_weapon_has_a_get_card(self):
        t = cards()
        for card in GET_CARDS:
            self.assertTrue(t.get(card + ".title") and t.get(card + ".desc"), card)

    def test_the_merged_numbers_are_on_the_cards(self):
        # docs/weapons.md, Decisions, "Shorter trees: 5 tiers": tier 2 / 3 / 4 / 5.
        t = cards()
        want = {
            "upgrade_gun.tier2.desc": ["+2 bullets", "3 in all"],
            "upgrade_gun.tier3.desc": ["x1.44"],
            "upgrade_gun.tier4.desc": ["+1 bullet", "x1.2"],
            "upgrade_gun.tier5.desc": ["x4"],
            "upgrade_flamethrower.tier2.desc": ["x1.56"],
            "upgrade_flamethrower.tier3.desc": ["20%", "30%"],
            "upgrade_flamethrower.tier4.desc": ["2 seconds"],
            "upgrade_underglow.tier2.desc": ["x1.5"],
            "upgrade_underglow.tier3.desc": ["x2.25"],
            "upgrade_underglow.tier4.desc": ["twice as fast"],
            "upgrade_molotov.tier2.desc": ["x1.56"],
            "upgrade_molotov.tier3.desc": ["2 more molotovs"],
            "upgrade_molotov.tier4.desc": ["x0.56"],
            "upgrade_molotov.tier5.desc": ["+1", "4 per throw"],
            "upgrade_wiper.tier2.desc": ["x1.56"],
            "upgrade_wiper.tier3.desc": ["x1.625"],
            "upgrade_wiper.tier4.desc": ["x1.5", "x1.3"],
            "upgrade_bricks.tier2.desc": ["x2.1"],
            "upgrade_bricks.tier3.desc": ["x2.25"],
            "upgrade_bricks.tier4.desc": ["x2.25"],
        }
        for key, parts in want.items():
            for p in parts:
                self.assertIn(p, t[key], key)

    def test_lengths_follow_text_rule_4(self):
        for key, text in cards().items():
            if key.endswith(".title") and key.startswith(("get_", "upgrade_")):
                self.assertLessEqual(len(text), 30, key)
            if key.endswith(".desc"):
                self.assertLessEqual(len(text), 90, key)


class PowerUpAndHealTexts(unittest.TestCase):
    def setUp(self):
        self.screen = json.loads((DATA / "screen_texts.json").read_text(encoding="utf-8"))

    def test_every_power_up_has_a_tier_1_and_a_last_tier_text(self):
        ids = json.loads((DATA / "power_ups.json").read_text(encoding="utf-8"))["power_ups"].keys()
        p = self.screen["power_ups"]
        for pid in ids:
            self.assertTrue(p["descriptions"].get(pid), pid)
            self.assertTrue(p["descriptions_last_tier"].get(pid), pid)

    def test_the_heal_popup_is_a_one_line_capitals_exclamation(self):
        text = self.screen["heal"]["popup"]
        self.assertEqual(text, text.upper())
        self.assertTrue(text.endswith("!"))
        self.assertNotIn("\n", text)


class NoOldRunLength(unittest.TestCase):
    OLD = re.compile(r"\b(8|7|eight|seven)[ -]minutes?\b|\b[78]:00\b", re.I)

    def test_no_player_facing_text_names_the_8_minute_run(self):
        files = list(DATA.glob("*_text.json")) + list(DATA.glob("*_texts.json")) + [CARDS]
        for f in files:
            for line in f.read_text(encoding="utf-8").splitlines():
                parts = line.strip().split('"')
                key = parts[1] if line.strip().startswith('"') and len(parts) > 1 else ""
                if key.endswith("comment"):
                    continue
                self.assertIsNone(self.OLD.search(line), f"{f.name}: {line.strip()[:80]}")


if __name__ == "__main__":
    unittest.main()
