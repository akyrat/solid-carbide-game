#!/usr/bin/env python3
"""The text layout capture (task T-524), the Python half. Standard library only.

screen_gallery.py --text-layout runs Godot (screen_gallery.gd and text_layout.gd), which saves a
`<screen>.png` and a `<screen>_blank.png` per screen and a raw `text_layout_nodes.json` (one row per visible
text node, as Godot resolves it). This module turns that into `text_layout.json`:

  screens          per screen: file, blank_file, how, rows, and two checks on the blank picture
                   (text_nodes_still_showing_in_blank, pixels_changed_outside_text)
  rows             one per text node: screen, path, class, kind (control / baked_popup / art_digits), text, bbcode,
                   rect [x, y, w, h] in screenshot pixels, scale, rotation_deg, font (repo path) and font_file
                   (the copy in fonts/), font_size, font_px (size in screenshot pixels), color, outline_size,
                   outline_color, shadow_*, h_align, v_align, autowrap, uppercase, line_spacing, max_lines,
                   overrun, clip, padding, and "inventory" (source, key, screen of the matching text inventory
                   row) when the text matches one; "template" and "template_keys" for a node that many texts render into
  templates        template id -> description and the number of keys
  fonts            the font files copied into fonts/
  not_capturable   player-facing text not drawn by a Control (draw_string, art, baked pictures), with screen and source
  coverage         text inventory rows (text_files and code) matched to a node or a template, and the unmatched
                   ones with a reason

The text inventory is text_inventory.py's. A node's text matches an inventory row when it equals the row's text, with
{placeholders} and %d/%s standing for any text (case ignored as a second try).
"""
import json
import re
import shutil
from pathlib import Path

REQUIRED_ROW_FIELDS = ("screen", "path", "class", "text", "rect", "font", "font_size", "color", "outline_size",
                       "outline_color", "h_align", "autowrap")
ROW_LIMIT_MATCHES = 5
COVERAGE_MIN = 80.0  # percent of the text_files rows that must be matched or covered by a template

# Components that show many texts in the same place. Each: id, what it is, a test on the node (path regex and
# class) and a test on an inventory row (source regex, key regex). One instance is a row; the row lists every key.
TEMPLATES = [
    {"id": "level_up_weapon_card_title", "what": "Level-up screen weapon card: title line",
     "path": r"Card_[^/]+/Body/.*/Title$", "screen_has": "level_up", "source": r"level_up_texts\.gd$", "key": r"^(?!levelup\.).*\.title$"},
    {"id": "level_up_weapon_card_description", "what": "Level-up screen weapon card: description",
     "path": r"Card_[^/]+/Body/.*/Description$", "screen_has": "level_up", "source": r"level_up_texts\.gd$", "key": r"^(?!levelup\.).*\.desc$"},
    {"id": "power_up_card_name", "what": "Driving power-up card: name",
     "path": r"Card_[^/]+/Body/.*/Name$", "screen_has": "power_up", "source": r"screen_texts\.json$", "key": r"^power_ups\.names\."},
    {"id": "power_up_card_description", "what": "Driving power-up card: description (every tier)",
     "path": r"Card_[^/]+/Body/.*/Description$", "screen_has": "power_up", "source": r"screen_texts\.json$", "key": r"^power_ups\.descriptions(_last_tier)?\."},
    {"id": "missions_note_line", "what": "Mission notebook page: one goal line",
     "path": r"MissionPage/Goal\d+/Text$", "source": r"screen_texts\.json$", "key": r"^missions\.goals\."},
    {"id": "trick_popup", "what": "Trick popup over the car (baked bubble): trick name and multiplier add",
     "class": "PopupText", "not_broken": True, "source": r"(trick_popups\.gd:\d+|multiplier_text\.json)$", "key": r"^(TEXTS\.|gain$)"},
    {"id": "recap_enemy_name", "what": "Recap takedowns: enemy name",
     "path": r"Enemy_[^/]+/Name$", "source": r"recap_text\.json$", "key": r"^enemy\."},
    {"id": "recap_weapon_name", "what": "Recap weapons: weapon name",
     "path": r"Weapon_[^/]+/Name$", "source": r"recap_text\.json$", "key": r"^weapon\."},
    {"id": "recap_weapon_tier", "what": "Recap weapons: tier line",
     "path": r"Weapon_[^/]+/Tier$", "source": r"recap_text\.json$", "key": r"^tier$"},
    {"id": "recap_trick_name", "what": "Recap tricks: trick name",
     "path": r"Trick_[^/]+/Name$", "source": r"recap_text\.json$", "key": r"^trick\."},
    {"id": "trick_list_row", "what": "Trick list (tutorial slide 2 and pause screen): a trick's name, rule and recipe",
     "path": r"TrickList|trick_list|Trick_|Row_", "screen_has": "trick_list", "source": r"tutorial_text\.json$", "key": r"^(trick|trick_rule|trick_recipe)\."},
]


def placeholder_regex(text):
    """A regex that matches `text` with {name}, %d, %s, %.1f standing for any text."""
    parts = re.split(r"(\{[a-z_0-9]*\}|%[0-9.]*[dsf])", normal(text))
    return re.compile("".join(".+?" if i % 2 else re.escape(p) for i, p in enumerate(parts)), re.S)


def normal(text):
    return re.sub(r"\s+", " ", str(text).replace("\\n", " ")).strip()


def inventory_rows(inv):
    rows = []
    for origin in ("text_files", "code"):
        for r in inv[origin]:
            rows.append(dict(r, origin=origin, _re=placeholder_regex(r["text"]), _plain=normal(r["text"]), _slots="{" in r["text"] or "%" in r["text"]))
    return rows


def match_row(text, inv_rows):
    """The inventory rows whose text this node text is, best first: exact, then pattern, then case-insensitive."""
    t = normal(text)
    if not t:
        return []
    exact = [r for r in inv_rows if r["_plain"] == t]
    pattern = [r for r in inv_rows if r["_slots"] and r not in exact and r["_re"].fullmatch(t)]
    pattern.sort(key=lambda r: -len(r["_plain"]))
    fold = [r for r in inv_rows if r not in exact and r not in pattern and r["_plain"].casefold() == t.casefold()]
    return exact + pattern + fold


def brief(r):
    return {"source": r["source"], "key": r["key"], "screen": r["screen"], "origin": r["origin"]}


def template_for(row, templates=TEMPLATES):
    for t in templates:
        if t.get("class") and row["class"] != t["class"]:
            continue
        if t.get("not_broken") and row.get("broken"):
            continue
        if t.get("path") and not re.search(t["path"], row["path"]):
            continue
        if t.get("screen_has") and t["screen_has"].replace("_", "") not in (row["screen"] + row["path"]).lower().replace("_", ""):
            continue
        return t
    return None


def template_keys(t, inv_rows):
    return [{"source": r["source"], "key": r["key"], "text": r["text"]} for r in inv_rows
            if re.search(t["source"], r["source"]) and re.search(t["key"], r["key"])]


def reason_for(r):
    """Why an inventory row has no captured node, as far as the tables know."""
    scr = r["screen"].lower()
    if "not in the game yet" in scr:
        return "the screen is not in the game yet"
    note = r.get("note", "")
    if note.startswith("UNUSED"):
        return "unused: " + note.split(".")[0].lower()
    if r["key"].startswith("arrow."):
        return "a tooltip: shown only while the pointer rests on the arrow, which the capture cannot do"
    if "unused" in scr:
        return "unused (the thing it labelled is gone)"
    if r["origin"] == "code" and "()" in r["key"]:
        return "a key into a text file built at run time (the pattern %d is filled in); the texts it shows are matched under their own keys"
    return "no captured screen shows this text (a state the gallery does not reach, or a text that changes with game state)"


def build(raw, inventory, game_dir, out_dir):
    """The final manifest from Godot's raw capture: match to the inventory, templates, fonts, coverage."""
    out_dir = Path(out_dir)
    inv = inventory_rows(inventory)
    rows, used_templates = [], {}
    matched_keys = set()
    for i, r in enumerate(raw["rows"]):
        row = dict(r)
        row["id"] = f"{r['screen']}#{i}"
        row["font_file"] = row.get("font_extracted") or ""
        hits = match_row(r["text"], inv)
        if hits:
            row["inventory"] = brief(hits[0])
            if len(hits) > 1:
                row["inventory_also"] = [brief(h) for h in hits[1:1 + ROW_LIMIT_MATCHES]]
            for h in hits:
                matched_keys.add((h["source"], h["key"]))
        t = template_for(row)
        if t:
            keys = template_keys(t, inv)
            row["template"] = t["id"]
            row["template_keys"] = keys
            used_templates[t["id"]] = {"what": t["what"], "keys": len(keys)}
            for k in keys:
                matched_keys.add((k["source"], k["key"]))
        rows.append(row)
    # A text composed into a longer one ("2 / 4 · {topic}": the kicker topics) counts as shown when a node's text holds it.
    shown = [normal(r["text"]).casefold() for r in rows]
    for r in inv:
        if r["key"].startswith("kicker.") and r["key"] != "kicker.pattern" and any(r["_plain"].casefold() in t for t in shown):
            matched_keys.add((r["source"], r["key"]))
    fonts = copy_fonts(rows, Path(game_dir), out_dir)
    cover = coverage(inventory, inv, matched_keys)
    return {"size": raw["size"], "screens": raw["screens"], "rows": rows, "templates": used_templates, "fonts": fonts,
            "not_capturable": dedupe(raw.get("not_capturable", []) + baked_entries(rows)), "coverage": cover}


def dedupe(entries):
    seen, out = set(), []
    for e in entries:
        k = (e["screen"], e["source"], e.get("text", ""))
        if k not in seen:
            seen.add(k)
            out.append(e)
    return out


def baked_entries(rows):
    """Rows whose text is a picture (baked popups, the time's up card, the clock's art digits): they have a row, with its rect,
    but the page cannot redraw the text in place; listed so the board knows."""
    out = []
    for r in rows:
        if r.get("kind", "control") != "control":
            out.append({"screen": r["screen"], "path": r["path"], "source": r["class"] + " (" + r["kind"] + ")", "text": r["text"],
                        "rect": r["rect"], "why": r.get("note", ""), "has_row": True})
    return out


def copy_fonts(rows, game_dir, out_dir):
    """Copy every font file the rows use into out_dir/fonts and set each row's font_file; returns the list."""
    fonts = {}
    dest_dir = out_dir / "fonts"
    for row in rows:
        src = row.get("font", "")
        if src.startswith("res://"):
            path = game_dir / src[len("res://"):]
            dest = dest_dir / path.name
            if path.is_file():
                dest_dir.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(path, dest)
                row["font_file"] = f"fonts/{path.name}"
        if row.get("font_file"):
            fonts.setdefault(row["font_file"], {"file": row["font_file"], "repo_path": src, "name": row.get("font_name", ""), "rows": 0})["rows"] += 1
    return sorted(fonts.values(), key=lambda f: f["file"])


def coverage(inventory, inv_rows, matched_keys):
    def part(origin):
        rows = [r for r in inv_rows if r["origin"] == origin]
        hit = [r for r in rows if (r["source"], r["key"]) in matched_keys]
        miss = [{"source": r["source"], "key": r["key"], "text": r["text"], "screen": r["screen"], "reason": reason_for(r)}
                for r in rows if (r["source"], r["key"]) not in matched_keys]
        pct = round(100.0 * len(hit) / len(rows), 1) if rows else 100.0
        return {"total": len(rows), "matched": len(hit), "percent": pct, "unmatched": miss}
    return {"text_files": part("text_files"), "code": part("code")}


def check_layout(out_dir, size=(1280, 720)):
    """Problems with a text layout folder: [] when the manifest, the pictures and the fonts are all as described."""
    import screen_gallery  # the PNG header reader lives there
    out_dir = Path(out_dir)
    path = out_dir / "text_layout.json"
    if not path.exists():
        return ["no text_layout.json"]
    m = json.loads(path.read_text(encoding="utf-8"))
    problems = []
    names = set()
    for s in m.get("screens", []):
        names.add(s["name"])
        for key in ("file", "blank_file"):
            p = out_dir / s.get(key, "")
            if not p.is_file():
                problems.append(f"{s['name']}: {s.get(key)} is not on disk")
            elif screen_gallery.png_size(p) != tuple(size):
                problems.append(f"{s['name']}: {s.get(key)} is {screen_gallery.png_size(p)}, not {tuple(size)}")
    for r in m.get("rows", []):
        for f in REQUIRED_ROW_FIELDS:
            if f not in r:
                problems.append(f"{r.get('id', '?')}: missing {f}")
        if r.get("screen") not in names:
            problems.append(f"{r.get('id', '?')}: screen {r.get('screen')} is not in screens")
        rect = r.get("rect", [])
        if len(rect) != 4 or rect[2] <= 0 or rect[3] <= 0:
            problems.append(f"{r.get('id', '?')}: bad rect {rect}")
        if r.get("font_file") and not (out_dir / r["font_file"]).is_file():
            problems.append(f"{r.get('id', '?')}: font {r['font_file']} not copied")
        if r.get("template") and not r.get("template_keys"):
            problems.append(f"{r.get('id', '?')}: template {r['template']} has no template_keys")
    for key in ("fonts", "not_capturable", "coverage", "templates"):
        if key not in m:
            problems.append(f"no {key} in the manifest")
    return problems


def summary(m):
    c = m["coverage"]
    lines = [f"{len(m['screens'])} screens, {len(m['rows'])} text rows, {len(m['fonts'])} font files, {len(m['not_capturable'])} not capturable",
             f"coverage: text_files {c['text_files']['matched']}/{c['text_files']['total']} ({c['text_files']['percent']}%), "
             f"code {c['code']['matched']}/{c['code']['total']} ({c['code']['percent']}%)"]
    for part in ("text_files", "code"):
        for u in c[part]["unmatched"]:
            lines.append(f"  unmatched {part}: {u['source']} {u['key']}: {u['reason']}")
    return "\n".join(lines)
