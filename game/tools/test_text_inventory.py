"""Tests for text_inventory.py (task T-479): the inventory of a small fixture game folder."""
import csv
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import text_inventory as inv  # noqa: E402

PAUSE = {"_comment": "ignored", "hud_size_label": "HUD size", "hud_size_label_comment": "The slider label.",
         "hud_layout_done": "Done"}
RECAP = {"title": {"win": "Kaiju sunsetted"}, "tier": "Tier {tier}"}
MENU_GD = '''extends Control
const TITLE := "SOLID CARBIDE"
const START_TEXT := "Start"
const SPEED := 3.0
const PATH_TEXT := "res://data/x.json"
const NAMES := {
	"a": "Alpha car",
	"b": "Beta car",
}
func _ready() -> void:
	label.text = "Press any key"
	_make_button("StartButton", "Go live now")
	_label("Title", TITLE)
	print("debug only message")
'''
TABLE_GD = '''const TEXTS := {
	"levelup.title": "Gift pack!",
	"get_gun.title": "Promo pistol",
}
'''


def make_game(root):
    game = Path(root) / "game"
    (game / "data").mkdir(parents=True)
    (game / "data" / "pause_text.json").write_text(json.dumps(PAUSE), encoding="utf-8")
    (game / "data" / "recap_text.json").write_text(json.dumps(RECAP), encoding="utf-8")
    (game / "data" / "weapons.json").write_text(json.dumps({"gun": {"name_id": "gun"}}), encoding="utf-8")
    files = {"scripts/menu/main_menu.gd": MENU_GD, "scripts/ui/level_up_texts.gd": TABLE_GD,
             "scripts/level_creator/editor.gd": 'const TITLE := "Creator"\n'}
    for rel, body in files.items():
        p = game / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(body, encoding="utf-8")
    return game


class TextInventoryTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.out = inv.build(make_game(self.tmp.name))

    def test_text_files_list_each_string_with_key_text_and_screen(self):
        rows = {r["key"]: r for r in self.out["text_files"] if r["source"] == "data/pause_text.json"}
        self.assertEqual(set(rows), {"hud_size_label", "hud_layout_done"})  # comments left out
        self.assertEqual(rows["hud_size_label"]["text"], "HUD size")
        self.assertEqual(rows["hud_size_label"]["note"], "The slider label.")
        self.assertEqual(rows["hud_layout_done"]["screen"], "Pause screen, HUD layout editor")
        self.assertEqual(rows["hud_size_label"]["screen"], "Pause screen (settings)")

    def test_nested_keys_are_dotted_and_data_files_without_text_in_the_name_are_skipped(self):
        keys = {r["key"] for r in self.out["text_files"]}
        self.assertIn("title.win", keys)
        self.assertNotIn("gun.name_id", keys)

    def test_the_level_up_table_kept_in_code_counts_as_a_text_file(self):
        rows = [r for r in self.out["text_files"] if r["source"].endswith("level_up_texts.gd")]
        self.assertEqual([(r["key"], r["text"]) for r in rows],
                         [("levelup.title", "Gift pack!"), ("get_gun.title", "Promo pistol")])
        self.assertEqual(rows[0]["screen"], "Level-up gift pack screen")
        self.assertFalse([r for r in self.out["code"] if "level_up_texts" in r["source"]])

    def test_code_strings_are_listed_separately_with_file_and_line(self):
        got = {(r["key"], r["text"]) for r in self.out["code"]}
        self.assertEqual(got, {("TITLE", "SOLID CARBIDE"), ("START_TEXT", "Start"), ("NAMES.a", "Alpha car"),
                               ("NAMES.b", "Beta car"), ("text", "Press any key"), ("_make_button()", "Go live now")})
        title = next(r for r in self.out["code"] if r["key"] == "TITLE")
        self.assertEqual(title["source"], "scripts/menu/main_menu.gd:2")
        self.assertEqual(title["screen"], "Main menu")

    def test_paths_numbers_and_prints_are_not_text_and_dev_tools_are_not_scanned(self):
        texts = {r["text"] for r in self.out["code"]}
        self.assertNotIn("res://data/x.json", texts)
        self.assertNotIn("debug only message", texts)
        self.assertNotIn("Creator", texts)
        self.assertEqual(self.out["not_scanned"], ["scripts/level_creator/editor.gd"])

    def test_counts_add_up(self):
        c = self.out["counts"]
        self.assertEqual(c["text_files"], len(self.out["text_files"]))
        self.assertEqual(c["code"], len(self.out["code"]))
        self.assertEqual(c["total"], c["text_files"] + c["code"])

    def test_write_makes_json_and_csv_with_the_same_rows(self):
        path = Path(self.tmp.name) / "out" / "inventory.json"
        inv.write(self.out, path)
        data = json.loads(path.read_text(encoding="utf-8"))
        self.assertEqual(data["counts"], self.out["counts"])
        with open(path.with_suffix(".csv"), encoding="utf-8-sig", newline="") as f:
            rows = list(csv.reader(f))
        self.assertEqual(rows[0], ["origin", "source", "key", "text", "screen", "note"])
        self.assertEqual(len(rows) - 1, self.out["counts"]["total"])

    def test_the_real_game_has_text_in_both_lists_and_every_screen_is_listed(self):
        real = inv.build(inv.ROOT / "game")
        self.assertGreater(real["counts"]["text_files"], 100)
        self.assertGreater(real["counts"]["code"], 20)
        unlisted = {r["source"] for r in real["text_files"] + real["code"] if r["screen"] == "(unlisted)"}
        self.assertEqual(unlisted, set())


if __name__ == "__main__":
    unittest.main()
