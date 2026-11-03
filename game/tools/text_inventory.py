#!/usr/bin/env python3
"""The text inventory (task T-479): every player-facing string the game can show, in one file.

  python game/tools/text_inventory.py [--game-dir game] [--out screenshots/mvp-gallery/text_inventory.json]

Writes the JSON and, next to it, a CSV with the same rows (open it in a spreadsheet). The JSON has

  counts        {"text_files": N, "code": N, "total": N}
  text_files    one row per string in the game's text files (game/data/*_text.json and
                *_texts.json, plus the level-up cards' table level_up_texts.gd, which is a
                text table kept in code), with
                  source  the file, key  the dotted key, text  the string, screen  where it
                  appears, note  the file's own "<key>_comment" line when it has one
  code          strings found in the game's scripts instead of a text file, found by reading
                the .gd files: constants whose name says text (TEXT_*, *_TEXT, TITLE, NAMES,
                DESCRIPTIONS, ...) and labels, buttons and tooltips set from a literal. Each
                row has source (file:line), key (the constant's name, or the call), text,
                screen. Found by pattern, so a string built another way can be missed:
                the board's pass is the check.
  not_scanned   developer tools (the level creator, tuning panel, test rooms) whose text the
                player never meets.

Standard library only. The screen of a string comes from the tables SCREEN_BY_PREFIX (text
files, by key prefix) and SCREEN_BY_FILE (code, by script); a string whose file is in neither
says "(unlisted)", which the board sees and the table gets a line for.
"""
import argparse
import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# Scripts the player never meets: developer tools and demos.
NOT_PLAYER_FACING = ("level_creator/", "driving/tuning_panel.gd", "driving/test_room.gd",
                     "driving/drift_prototype.gd", "driving/elevation_test.gd",
                     "level/see_through_demo.gd", "level/elevation_sample_map.gd",
                     "level/map_overview.gd")

# The text tables kept in code: scanned as text files (key = the dict key), not as code.
CODE_TEXT_TABLES = {"scripts/ui/level_up_texts.gd": "TEXTS"}

# Text files: the screen of a key, by the longest matching "file-stem:prefix" (prefix "" = rest).
SCREEN_BY_PREFIX = {
    "pause_text:": "Pause screen (settings)",
    "pause_text:hud_layout": "Pause screen, HUD layout editor",
    "recap_text:peak_value": "End-of-run recap (peak combo)",
    "multiplier_text:multiplier": "HUD, combo multiplier beside the car",
    "multiplier_text:gain": "Trick popups (multiplier added)",
    "multiplier_text:loss": "HUD, combo multiplier beside the car (crash loss)",
    "multiplier_text:unused": "Unused (live viewers counter, gone)",
    "recap_text:title": "End-of-run recap",
    "recap_text:heading": "End-of-run recap",
    "recap_text:button": "End-of-run recap",
    "recap_text:tier": "End-of-run recap (weapons section)",
    "recap_text:enemy": "End-of-run recap (takedowns section)",
    "recap_text:weapon": "End-of-run recap (weapons section)",
    "recap_text:trick": "End-of-run recap (tricks section)",
    "runs_list_text:": "Runs list (not in the game yet)",
    "screen_texts:time_up": "Time's up screen",
    "screen_texts:heal": "HUD, popup when a full sub goal heals the car (all 3 weapons maxed)",
    "screen_texts:missions": "HUD, mission notebook page",
    "screen_texts:power_ups": "Driving power-up overlay",
    "tutorial_text:slide1": "Tutorial slide 1 (controls)",
    "tutorial_text:kicker": "Tutorial slides (kicker above each headline)",
    "tutorial_text:slide4": "Tutorial slide 4 (the goal)",
    "tutorial_text:button.skip": "Tutorial slides (Skip control)",
    "tutorial_text:slide2": "Tutorial slide 2 (the loop)",
    "tutorial_text:slide3": "Tutorial slide 3 (the goal)",
    "tutorial_text:trick": "Tutorial slide 2 and the pause screen's trick list",
    "tutorial_text:button.start": "Tutorial slide 3",
    "tutorial_text:button.trick_list": "Pause screen",
    "tutorial_text:button.back": "Pause screen, trick list",
    "tutorial_text:checkbox": "Tutorial slide 3",
    "tutorial_text:arrow": "Tutorial slides (arrow tooltips)",
    "level_up_texts:levelup": "Level-up gift pack screen",
    "level_up_texts:": "Level-up gift pack screen (weapon cards)",
}

# Code strings: the screen of a script.
SCREEN_BY_FILE = {
    "scripts/menu/main_menu.gd": "Main menu",
    "scripts/menu/garage_screen.gd": "Garage",
    "scripts/menu/tutorial_slides.gd": "Tutorial slides",
    "scripts/menu/trick_list.gd": "Tutorial slide 2 and pause screen's trick list",
    "scripts/ui/pause_screen.gd": "Pause screen",
    "scripts/ui/hud_layout_editor.gd": "Pause screen, HUD layout editor",
    "scripts/ui/level_up_screen.gd": "Level-up gift pack screen",
    "scripts/ui/power_up_screen.gd": "Driving power-up overlay",
    "scripts/ui/recap_screen.gd": "End-of-run recap",
    "scripts/ui/time_up_screen.gd": "Time's up screen",
    "scripts/hud/hud.gd": "HUD",
    "scripts/hud/timer_clock.gd": "HUD (clock)",
    "scripts/hud/trick_popups.gd": "HUD (popups over the car)",
    "scripts/hud/weapon_icons.gd": "HUD (weapon icons)",
    "scripts/hud/mission_page.gd": "HUD, mission notebook page",
    "scripts/hud/multiplier_tag.gd": "HUD (multiplier beside the car)",
    "scripts/hud/sub_goal.gd": "HUD (sub goal)",
    "scripts/hud/kaiju_health_bar.gd": "HUD (kaiju health bar)",
    "scripts/hud/airtime_counter.gd": "HUD (airtime counter)",
    "scripts/hud/drift_counter.gd": "HUD (drift counter)",
    "scripts/run/gift_arrows.gd": "Run (gift arrows)",
    "scripts/run/gift_drops.gd": "Run (gift drops)",
}

# A constant says "text" in its name.
TEXT_NAME = re.compile(r"(^|_)(TEXT|TEXTS|NAMES|DESCRIPTIONS|TITLE|HEADLINE|HINT|LABEL|MESSAGE|BADGE|UNIT|CAPTION|SUBTITLE)(_|$)")
CONST = re.compile(r"^(?:const|static var|var)\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?::[^=]*)?:?=\s*(.*)$")
STRING = re.compile(r'"((?:[^"\\]|\\.)*)"')
# Calls and assignments that put a literal on screen.
TEXT_ASSIGN = re.compile(r'\b(text|tooltip_text|placeholder_text)\s*=\s*"((?:[^"\\]|\\.)*)"')
TEXT_CALL = re.compile(r"\b(_label|_make_label|_make_button|_make_game_button|_make_check|_text_label|_button|add_label)\(")
# A literal that reads as words (not a node name or a path or an id).
WORDS = re.compile(r"[A-Za-z]{2,}")
SENTENCE = re.compile(r"[ !?.,:'%{]")


def flatten(obj, path=()):
    """(dotted key, string) for every string leaf of a JSON value, in file order."""
    if isinstance(obj, dict):
        for k, v in obj.items():
            yield from flatten(v, path + (str(k),))
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            yield from flatten(v, path + (str(i),))
    elif isinstance(obj, str):
        yield ".".join(path), obj


def screen_for(stem, key):
    """The screen of a text-file key: the longest matching prefix, else '(unlisted)'."""
    best, best_len = "(unlisted)", -1
    for rule, screen in SCREEN_BY_PREFIX.items():
        s, _, prefix = rule.partition(":")
        if s == stem and key.startswith(prefix) and len(prefix) > best_len:
            best, best_len = screen, len(prefix)
    return best


def is_comment_key(key):
    last = key.split(".")[-1]
    return key.startswith("_") or last.startswith("_") or last.endswith("_comment") or last == "comment"


def json_text_files(game_dir):
    """The text files in game/data: *_text.json and *_texts.json."""
    data = Path(game_dir) / "data"
    return sorted(p for p in data.glob("*.json") if re.search(r"_texts?$", p.stem))


def rows_from_json(path):
    stem = path.stem
    data = json.loads(path.read_text(encoding="utf-8"))
    flat = list(flatten(data))
    comments = {k: v for k, v in flat if is_comment_key(k)}
    rows = []
    for key, text in flat:
        if is_comment_key(key):
            continue
        rows.append({"source": f"data/{path.name}", "key": key, "text": text,
                     "screen": screen_for(stem, key), "note": comments.get(key + "_comment", "")})
    return rows


def dict_entries(lines, start):
    """(key, text, line number) for the "key": "text" entries of the dict starting at lines[start]."""
    depth, out, i = 0, [], start
    entry = re.compile(r'^\s*"([^"]+)"\s*:\s*"((?:[^"\\]|\\.)*)"\s*,?\s*(?:#.*)?$')
    while i < len(lines):
        line = lines[i]
        depth += line.count("{") - line.count("}")
        m = entry.match(line)
        if m:
            out.append((m.group(1), unescape(m.group(2)), i + 1))
        if depth <= 0 and i >= start:
            break
        i += 1
    return out


def unescape(s):
    return s.replace('\\"', '"').replace("\\n", "\n").replace("\\\\", "\\")


def rows_from_code_table(path, rel, const_name):
    lines = path.read_text(encoding="utf-8").splitlines()
    stem = path.stem
    for i, line in enumerate(lines):
        if re.match(rf"^const\s+{const_name}\b", line):
            return [{"source": rel, "key": k, "text": t, "screen": screen_for(stem, k),
                     "note": f"kept in code, line {n}"} for k, t, n in dict_entries(lines, i)]
    return []


# A key into a text file ("slide1.controls", "title.", "pause_text"), not words.
KEY_LIKE = re.compile(r"^[a-z0-9_]+(\.[a-z0-9_]*)*$")


def looks_like_words(text):
    return bool(WORDS.search(text)) and not KEY_LIKE.match(text) and not text.startswith(("res://", "user://")) and not text.endswith((".json", ".png", ".gd", ".tscn", ".ogg", ".wav"))


def code_rows(path, rel):
    """Strings put on screen from a script: text-named constants, and literals in text calls."""
    screen = SCREEN_BY_FILE.get(rel, "(unlisted)")
    lines = path.read_text(encoding="utf-8").splitlines()
    rows, seen = [], set()

    def add(line_no, key, text):
        if (line_no, text) in seen or not looks_like_words(text):
            return
        seen.add((line_no, text))
        rows.append({"source": f"{rel}:{line_no}", "key": key, "text": unescape(text), "screen": screen, "note": ""})

    i = 0
    while i < len(lines):
        line = lines[i]
        m = CONST.match(line)
        if m and TEXT_NAME.search(m.group(1)):
            name, rest = m.group(1), m.group(2)
            if rest.lstrip().startswith("{"):  # a dict constant: "key": "text" entries
                for k, t, n in dict_entries(lines, i):
                    add(n, f"{name}.{k}", t)
            else:
                for s in STRING.finditer(rest.split("#")[0]):
                    add(i + 1, name, s.group(1))
        code = line.split("#")[0]
        for a in TEXT_ASSIGN.finditer(code):
            add(i + 1, a.group(1), a.group(2))
        if TEXT_CALL.search(code):
            call = TEXT_CALL.search(code).group(1)
            for s in STRING.finditer(code):
                if SENTENCE.search(s.group(1)) and s.group(1) != "":
                    add(i + 1, call + "()", s.group(1))
        i += 1
    return rows


def build(game_dir):
    """The whole inventory for a game folder: {counts, text_files, code, not_scanned}."""
    game = Path(game_dir)
    text_rows = []
    for p in json_text_files(game):
        text_rows += rows_from_json(p)
    tables = {}
    for rel, const in CODE_TEXT_TABLES.items():
        p = game / rel
        if p.exists():
            text_rows += rows_from_code_table(p, rel, const)
            tables[rel] = const
    code, skipped = [], []
    for p in sorted((game / "scripts").rglob("*.gd")):
        rel = p.relative_to(game).as_posix()
        sub = p.relative_to(game / "scripts").as_posix()
        if sub.startswith(NOT_PLAYER_FACING):
            skipped.append(rel)
            continue
        rows = code_rows(p, rel)
        if rel in tables:  # its table is already in text_files
            rows = [r for r in rows if not r["key"].startswith(tables[rel] + ".")]
        code += rows
    return {"counts": {"text_files": len(text_rows), "code": len(code), "total": len(text_rows) + len(code)},
            "text_files": text_rows, "code": code, "not_scanned": skipped}


def write(inventory, json_path):
    json_path = Path(json_path)
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(inventory, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    with open(json_path.with_suffix(".csv"), "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow(["origin", "source", "key", "text", "screen", "note"])
        for origin in ("text_files", "code"):
            for r in inventory[origin]:
                w.writerow([origin, r["source"], r["key"], r["text"], r["screen"], r["note"]])


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--game-dir", default=str(ROOT / "game"))
    ap.add_argument("--out", default=str(ROOT / "screenshots" / "mvp-gallery" / "text_inventory.json"))
    args = ap.parse_args(argv)
    inv = build(args.game_dir)
    write(inv, args.out)
    unlisted = sorted({r["source"].split(":")[0] for r in inv["text_files"] + inv["code"] if r["screen"] == "(unlisted)"})
    print(f"text inventory: {inv['counts']} -> {args.out} (+ .csv)")
    if unlisted:
        print("screen not listed for:", ", ".join(unlisted))
    return 0


if __name__ == "__main__":
    sys.exit(main())
