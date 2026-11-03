"""Tests for text_layout.py (task T-524): matching, templates, coverage, fonts and the manifest checker, without Godot.
The last class checks the real output folder (screenshots/text-editor) when a capture has been run there."""
import json
import struct
import sys
import tempfile
import unittest
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import text_layout as tl  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]


def png(path, w=1280, h=720):
    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))
    raw = b"".join(b"\x00" + b"\x00\x00\x00" * w for _ in range(h))
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def inv_row(source, key, text, origin="text_files", screen="s", note=""):
    return {"source": source, "key": key, "text": text, "screen": screen, "note": note, "origin": origin}


INVENTORY = {
    "text_files": [
        inv_row("data/screen_texts.json", "missions.goals.alternate_drift", "Alt drifts {done}/{total}"),
        inv_row("data/screen_texts.json", "missions.goals.three_sixty", "Full 360s {done}/{total}"),
        inv_row("data/screen_texts.json", "power_ups.names.jump", "Jump"),
        inv_row("data/screen_texts.json", "power_ups.descriptions.jump", "Press Space to hop. Next hop in {cooldown_seconds} s."),
        inv_row("data/screen_texts.json", "power_ups.descriptions_last_tier.jump", "Hop higher."),
        inv_row("data/tutorial_text.json", "button.skip", "Skip"),
        inv_row("data/tutorial_text.json", "kicker.pattern", "{n} / {total} - {topic}"),
        inv_row("data/tutorial_text.json", "kicker.loop", "The loop"),
        inv_row("data/tutorial_text.json", "slide1.controls", "old text", note="UNUSED since T-484 (gone). Was: x"),
        inv_row("data/runs_list_text.json", "title", "Past streams", screen="Runs list (not in the game yet)"),
        inv_row("scripts/ui/level_up_texts.gd", "get_wiper.title", "Wiper Blade"),
        inv_row("scripts/ui/level_up_texts.gd", "get_wiper.desc", "Sweeps a half circle."),
        inv_row("scripts/ui/level_up_texts.gd", "levelup.title", "Greenbull sent a gift pack!"),
    ],
    "code": [
        inv_row("scripts/menu/main_menu.gd:11", "TITLE", "SOLID CARBIDE", origin="code"),
        inv_row("scripts/hud/trick_popups.gd:31", "TEXTS.three_sixty", "FULL 360!", origin="code"),
    ],
}


def node(screen, path, cls, text, **kw):
    r = {"screen": screen, "path": path, "class": cls, "kind": "control", "text": text, "rect": [10, 20, 100, 30], "font": "",
         "font_size": 16, "color": "ffffffff", "outline_size": 0, "outline_color": "00000000", "h_align": "left", "autowrap": "off"}
    r.update(kw)
    return r


class MatchTest(unittest.TestCase):
    def setUp(self):
        self.inv = tl.inventory_rows(INVENTORY)

    def keys(self, text):
        return [r["key"] for r in tl.match_row(text, self.inv)]

    def test_exact_text_matches(self):
        self.assertEqual(self.keys("Skip"), ["button.skip"])

    def test_placeholders_stand_for_any_text(self):
        self.assertIn("missions.goals.alternate_drift", self.keys("Alt drifts 5/10"))
        self.assertIn("kicker.pattern", self.keys("2 / 4 - How you get stronger"))

    def test_case_is_ignored_as_a_second_try(self):
        self.assertEqual(self.keys("SKIP"), ["button.skip"])

    def test_whitespace_and_escaped_newlines_are_normal(self):
        self.assertEqual(self.keys("Sweeps  a half\ncircle."), ["get_wiper.desc"])

    def test_no_match_for_other_text_or_empty(self):
        self.assertEqual(self.keys("Something else"), [])
        self.assertEqual(self.keys(""), [])


class TemplateTest(unittest.TestCase):
    def setUp(self):
        self.inv = tl.inventory_rows(INVENTORY)

    def keys_of(self, row):
        t = tl.template_for(row)
        self.assertIsNotNone(t, row["path"])
        return t["id"], [k["key"] for k in tl.template_keys(t, self.inv)]

    def test_missions_line_lists_every_goal_key(self):
        tid, keys = self.keys_of(node("hud_mission_page", "Game/Run/Hud/Scaled/MissionPage/Goal0/Text", "Label", "x"))
        self.assertEqual(tid, "missions_note_line")
        self.assertEqual(keys, ["missions.goals.alternate_drift", "missions.goals.three_sixty"])

    def test_level_up_card_title_and_description(self):
        base = "Game/Run/LevelUpScreen/Cards/Card_get_wiper/Body/M/V/"
        tid, keys = self.keys_of(node("level_up_gift_pack", base + "Title", "Label", "Wiper Blade"))
        self.assertEqual((tid, keys), ("level_up_weapon_card_title", ["get_wiper.title"]))
        tid, keys = self.keys_of(node("level_up_gift_pack", base + "Description", "Label", "x"))
        self.assertEqual((tid, keys), ("level_up_weapon_card_description", ["get_wiper.desc"]))

    def test_power_up_card_takes_both_tiers_of_description(self):
        base = "Game/Run/PowerUpScreen/Cards/Card_jump/Body/M/V/"
        self.assertEqual(self.keys_of(node("power_up_overlay", base + "Name", "Label", "Jump"))[0], "power_up_card_name")
        tid, keys = self.keys_of(node("power_up_overlay", base + "Description", "Label", "x"))
        self.assertEqual(tid, "power_up_card_description")
        self.assertEqual(keys, ["power_ups.descriptions.jump", "power_ups.descriptions_last_tier.jump"])

    def test_trick_popup_lists_trick_names(self):
        row = node("hud_trick_popup", "Game/Run/View/TrickPopups/@Node2D@1", "PopupText", "FULL 360!", kind="baked_popup")
        tid, keys = self.keys_of(row)
        self.assertEqual((tid, keys), ("trick_popup", ["TEXTS.three_sixty"]))

    def test_card_in_the_wrong_screen_is_not_the_other_template(self):
        row = node("level_up_gift_pack", "Game/Run/LevelUpScreen/Cards/Card_x/Body/M/V/Name", "Label", "x")
        self.assertIsNone(tl.template_for(row))

    def test_plain_label_is_no_template(self):
        self.assertIsNone(tl.template_for(node("main_menu", "Game/MainMenu/Title", "Label", "SOLID CARBIDE")))


class BuildTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.out = Path(self.tmp.name) / "out"
        self.out.mkdir()
        self.game = Path(self.tmp.name) / "game"
        (self.game / "fonts").mkdir(parents=True)
        (self.game / "fonts" / "Bangers.ttf").write_bytes(b"font bytes")
        for name in ("a", "a_blank"):
            png(self.out / f"{name}.png")
        self.raw = {"size": [1280, 720], "screens": [{"name": "a", "file": "a.png", "blank_file": "a_blank.png", "how": "x", "rows": 3,
                                                       "text_nodes_still_showing_in_blank": 0, "pixels_changed_outside_text": 0}],
                    "rows": [node("a", "Game/Menu/Skip", "Button", "SKIP", font="res://fonts/Bangers.ttf", font_name="Bangers"),
                             node("a", "Game/Run/Hud/MissionPage/Goal0/Text", "Label", "Alt drifts 5/10"),
                             node("a", "Game/Menu/Odd", "Label", "Not in any file", font_extracted="fonts/Default.ttf")],
                    "not_capturable": [{"screen": "a", "source": "key_pad.gd (draw_string)", "text": "W A S D", "rect": [0, 0, 5, 5], "why": "y"}]}
        (self.out / "fonts").mkdir()
        (self.out / "fonts" / "Default.ttf").write_bytes(b"x")

    def make(self):
        return tl.build(self.raw, INVENTORY, self.game, self.out)

    def test_rows_get_inventory_templates_and_ids(self):
        m = self.make()
        skip, goal, odd = m["rows"]
        self.assertEqual(skip["inventory"]["key"], "button.skip")
        self.assertEqual(goal["template"], "missions_note_line")
        self.assertEqual(len(goal["template_keys"]), 2)
        self.assertNotIn("inventory", odd)
        self.assertEqual([r["id"] for r in m["rows"]], ["a#0", "a#1", "a#2"])

    def test_fonts_are_copied_and_listed(self):
        m = self.make()
        self.assertTrue((self.out / "fonts" / "Bangers.ttf").is_file())
        self.assertEqual(m["rows"][0]["font_file"], "fonts/Bangers.ttf")
        self.assertEqual(sorted(f["file"] for f in m["fonts"]), ["fonts/Bangers.ttf", "fonts/Default.ttf"])

    def test_coverage_counts_matches_templates_and_gives_reasons(self):
        m = self.make()
        tf = m["coverage"]["text_files"]
        self.assertEqual(tf["total"], 13)
        covered = {u["key"]: u["reason"] for u in tf["unmatched"]}
        self.assertNotIn("button.skip", covered)
        self.assertNotIn("missions.goals.three_sixty", covered)  # by the missions template
        self.assertIn("title", covered)
        self.assertIn("not in the game yet", covered["title"])
        self.assertTrue(covered["slide1.controls"].startswith("unused"))
        self.assertTrue(all(u["reason"] for u in tf["unmatched"]))

    def test_composed_kicker_topic_counts_as_shown(self):
        self.raw["rows"].append(node("a", "Game/Slide/Kicker", "Label", "2 / 4 - The loop"))
        keys = {u["key"] for u in self.make()["coverage"]["text_files"]["unmatched"]}
        self.assertNotIn("kicker.loop", keys)

    def test_baked_rows_are_listed_as_not_capturable(self):
        self.raw["rows"].append(node("a", "Game/Run/Hud/Clock", "ClockDigits", "4:00", kind="art_digits", note="art"))
        m = self.make()
        sources = [n["source"] for n in m["not_capturable"]]
        self.assertIn("key_pad.gd (draw_string)", sources)
        self.assertIn("ClockDigits (art_digits)", sources)

    def test_a_good_folder_passes_the_checker(self):
        m = self.make()
        (self.out / "text_layout.json").write_text(json.dumps(m), encoding="utf-8")
        self.assertEqual(tl.check_layout(self.out), [])

    def test_checker_finds_the_problems(self):
        m = self.make()
        del m["rows"][0]["font_size"]
        m["rows"][1]["rect"] = [0, 0, 0, 5]
        m["rows"][2]["screen"] = "ghost"
        m["rows"][1]["template_keys"] = []
        (self.out / "text_layout.json").write_text(json.dumps(m), encoding="utf-8")
        (self.out / "a_blank.png").unlink()
        text = "\n".join(tl.check_layout(self.out))
        for piece in ("a_blank.png is not on disk", "missing font_size", "bad rect", "ghost", "no template_keys"):
            self.assertIn(piece, text)

    def test_checker_needs_the_manifest(self):
        self.assertEqual(tl.check_layout(self.out), ["no text_layout.json"])

    def test_summary_prints_counts(self):
        text = tl.summary(self.make())
        self.assertIn("1 screens, 3 text rows", text)
        self.assertIn("coverage: text_files", text)


class RealOutputTest(unittest.TestCase):
    """The schema on the real capture, when screenshots/text-editor has one (run screen_gallery.py --text-layout)."""
    folder = ROOT / "screenshots" / "text-editor"

    def setUp(self):
        if not (self.folder / "text_layout.json").exists():
            self.skipTest("no capture in screenshots/text-editor")

    def test_real_manifest_passes_the_checker(self):
        self.assertEqual(tl.check_layout(self.folder), [])

    def test_real_rows_have_the_fields_and_the_blank_is_clean(self):
        m = json.loads((self.folder / "text_layout.json").read_text(encoding="utf-8"))
        self.assertGreater(len(m["rows"]), 100)
        for r in m["rows"]:
            for f in tl.REQUIRED_ROW_FIELDS:
                self.assertIn(f, r)
        for s in m["screens"]:
            self.assertEqual(s["text_nodes_still_showing_in_blank"], 0, s["name"])

    def test_real_coverage_is_over_the_bar(self):
        m = json.loads((self.folder / "text_layout.json").read_text(encoding="utf-8"))
        self.assertGreaterEqual(m["coverage"]["text_files"]["percent"], tl.COVERAGE_MIN)
        for tid in ("level_up_weapon_card_title", "power_up_card_name", "missions_note_line", "trick_popup"):
            self.assertIn(tid, m["templates"])
            self.assertGreater(m["templates"][tid]["keys"], 0)


if __name__ == "__main__":
    unittest.main()
