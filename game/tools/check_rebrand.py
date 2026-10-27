#!/usr/bin/env python3
"""Rebrand sweep (T-307): no old sponsor name, logo or brand red in what the game loads.

Lists every PNG that game/scenes and game/scripts load (res:// paths in .tscn, .tres and .gd
files; a path with %s or * stands for every file it matches, a path without an extension for
every PNG starting with it, a folder for every PNG in it) and reports:

  red     a loaded PNG with an opaque pixel within BRAND_THRESHOLD of one of the old sponsor's
          brand colours (BRAND_COLOURS below, from the archived old sponsor's art), unless the
          file is one of the subjects whose red the docs keep (KEPT_RED below). Other reds
          (fire, wood) are not flagged: Visual style says red is no longer reserved;
  name    a loaded file whose name contains the old brand name in lower case
          (style_rules.OLD_BRAND, T-312);
  text    player-facing text containing the old brand name in game/scripts, game/scenes and
          game/data (quoted strings and JSON values; comment lines and identifiers are not text).

Findings are only reported, nothing is fixed. Exit code 1 when there is any finding.

  python game/tools/check_rebrand.py [--game-dir game] [--json]
"""
import argparse
import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import style_rules  # noqa: E402

# Visual style, Decisions, "Red after the rebrand" (line 36), and "Health drop" (line 50): the
# subjects whose red the docs keep. Keys are res:// path prefixes (relative to the game folder),
# values the doc's words.
KEPT_RED = {
    "art/hud/likes_heart": 'Red after the rebrand: "The HUD\'s likes heart stays red, as a social-media heart."',
    "art/banners/": 'Red after the rebrand: "the kaiju alert signs\' traffic-sign red outline"',
    "art/effects/car_tail": 'Red after the rebrand: "the car\'s pale tail lights (RGB 230, 110, 102)"',
    "art/car/": 'Red after the rebrand: "the car\'s pale tail lights (RGB 230, 110, 102)"',
    "art/placeholders/car/": 'Red after the rebrand: "the car\'s pale tail lights (RGB 230, 110, 102)"',
    "art/minion/": 'Red after the rebrand: "the minion\'s dull pink mouth (RGB 147, 93, 93)"',
    "art/effects/health_canister": 'Red after the rebrand: "the health canister ... warning red"; Health drop: "a red gas canister"',
    "art/effects/combo_broken": 'Red after the rebrand: "the combo broken popup\'s warning red"',
}

# The old sponsor's brand reds (T-308): the colours of the old sponsor's art, taken from the
# archived originals. A loaded PNG is flagged when an opaque pixel is within BRAND_THRESHOLD
# (RGB distance, 0..441) of one of them. Fire oranges and wood browns are not brand colours.
# They now live in style_rules.py (T-309); these names are kept for the tests.
BRAND_THRESHOLD = style_rules.BRAND_THRESHOLD
BRAND_COLOURS = style_rules.BRAND_COLOURS
# The old name, lower case, as file names and the text check compare it (T-312).
OLD_NAME = style_rules.OLD_BRAND.lower()

PATH_RE = re.compile(r"res://[A-Za-z0-9_./%*{}-]+")
STRING_RE = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
RED_FLOOR_ALPHA = 255


def kept_reason(rel):
    for prefix, why in KEPT_RED.items():
        if rel.startswith(prefix):
            return why
    return None


def resolve(token, game_dir):
    """The PNG files (paths relative to game_dir, forward slashes) a res:// token stands for."""
    rel = token[len("res://"):].rstrip(".,:;`")
    if not rel.startswith("art/"):
        return []
    pattern = re.sub(r"%[sd]|\{[^}]*\}", "*", rel)
    full = os.path.join(game_dir, pattern)
    if pattern.endswith(".png"):
        hits = glob.glob(full)
    elif pattern.endswith("/"):
        hits = glob.glob(os.path.join(full, "**", "*.png"), recursive=True)
    elif os.path.splitext(pattern)[1]:
        return []
    else:
        hits = glob.glob(full + "*.png")
    return sorted(os.path.relpath(h, game_dir).replace("\\", "/") for h in hits)


def loaded_pngs(game_dir):
    """Returns {png path relative to game_dir: [source files that load it]}."""
    out = {}
    for sub in ("scenes", "scripts"):
        for root, _, files in os.walk(os.path.join(game_dir, sub)):
            for name in files:
                if not name.endswith((".gd", ".tscn", ".tres")):
                    continue
                src = os.path.join(root, name)
                with open(src, encoding="utf-8", errors="replace") as f:
                    text = f.read()
                for tok in set(PATH_RE.findall(text)):
                    for png in resolve(tok, game_dir):
                        out.setdefault(png, []).append(os.path.relpath(src, game_dir).replace("\\", "/"))
    return out


def red_pixels(path):
    """The distinct opaque colours of a PNG within BRAND_THRESHOLD of an old brand colour;
    [] if unreadable."""
    try:
        with open(path, "rb") as f:
            _, _, rows = style_rules.decode_png(f.read())
    except (ValueError, OSError):
        return []
    colours = {p[:3] for r in rows for p in r if p[3] == RED_FLOOR_ALPHA}
    return sorted(c for c in colours if style_rules.is_old_brand_red(c))


def check_pngs(game_dir):
    """Red and name findings for the loaded PNGs. Returns (findings, kept)."""
    findings, kept = [], []
    for png, sources in sorted(loaded_pngs(game_dir).items()):
        if OLD_NAME in os.path.basename(png).lower():
            findings.append({"kind": "name", "file": png, "detail": "file name contains '%s'" % OLD_NAME,
                             "loaded_by": sources[:3]})
        reds = red_pixels(os.path.join(game_dir, png))
        if not reds:
            continue
        why = kept_reason(png)
        if why:
            kept.append({"file": png, "colours": [list(c) for c in reds[:5]], "kept_because": why})
        else:
            findings.append({"kind": "red", "file": png, "detail": "red pixels %s" % [list(c) for c in reds[:5]],
                             "loaded_by": sources[:3]})
    return findings, kept


def _text_candidates(path, text):
    """(line number, text) pairs of player-facing text in a file."""
    if path.endswith(".json"):
        for n, line in enumerate(text.splitlines(), 1):
            for m in re.finditer(r':\s*"((?:[^"\\]|\\.)*)"|^\s*"((?:[^"\\]|\\.)*)"\s*,?\s*$', line):
                yield n, m.group(1) or m.group(2) or ""
        return
    for n, line in enumerate(text.splitlines(), 1):
        if path.endswith(".gd") and line.lstrip().startswith("#"):
            continue
        if path.endswith((".tscn", ".tres")) and not line.lstrip().startswith(("text", "title", "tooltip", "placeholder", "button")):
            continue
        for m in STRING_RE.finditer(line):
            s = m.group(1)
            if s.startswith("res://"):
                continue
            yield n, s


def check_text(game_dir):
    """Findings for the old brand name in player-facing text in scripts, scenes and data."""
    findings = []
    for sub in ("scripts", "scenes", "data"):
        for root, _, files in os.walk(os.path.join(game_dir, sub)):
            for name in files:
                if not name.endswith((".gd", ".tscn", ".tres", ".json")):
                    continue
                path = os.path.join(root, name)
                with open(path, encoding="utf-8", errors="replace") as f:
                    text = f.read()
                for n, s in _text_candidates(path, text):
                    if re.search(re.escape(OLD_NAME), s, re.IGNORECASE) and " " in s.strip():
                        findings.append({"kind": "text", "file": os.path.relpath(path, game_dir).replace("\\", "/"),
                                         "detail": "line %d: %r" % (n, s[:80])})
    return findings


def run(game_dir):
    findings, kept = check_pngs(game_dir)
    findings += check_text(game_dir)
    return {"loaded_pngs": len(loaded_pngs(game_dir)), "findings": findings, "kept_red": kept}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--game-dir", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args(argv)
    rep = run(a.game_dir)
    if a.json:
        print(json.dumps(rep, indent=1))
    else:
        print("loaded PNGs checked: %d" % rep["loaded_pngs"])
        print("kept red (named in Visual style): %d" % len(rep["kept_red"]))
        for k in rep["kept_red"]:
            print("  kept  %s  (%s)" % (k["file"], k["kept_because"][:70]))
        print("findings: %d" % len(rep["findings"]))
        for f in rep["findings"]:
            print("  %-5s %s  %s" % (f["kind"], f["file"], f["detail"]))
    return 1 if rep["findings"] else 0


if __name__ == "__main__":
    sys.exit(main())
