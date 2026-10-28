#!/usr/bin/env python3
"""Writes the json record beside each of T-339's livestream HUD PNGs in game/art/hud/ (how it was made).

  python game/tools/write_hud_livestream_records.py

For each asset in ASSETS whose PNG exists, it reads the PNG's size, the style loop's kept version and score from
the task's Style review (the run whose brief is the asset's), and the PixelLab calls made in that run from
game/art/pixellab-generation-log.jsonl, and writes <name>.json next to the PNG. Records carry no `endpoint` key
(test_pixellab_assets.gd treats a json with `endpoint` and `image` as a PixelLab client record).
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[2]
HUD = REPO / "game" / "art" / "hud"
TASK = REPO / "tasks" / "T-339-art-the-livestream-hud.md"
LOG = REPO / "game" / "art" / "pixellab-generation-log.jsonl"

COMMON_REFS = ["docs/visual-style.md (Content, Rules)", "docs/hud-and-menus.md (Decisions, The HUD looks like a livestream)",
               "docs/extended-narrative.md", "the board's HUD layout page (sizes, at 1152 x 648)",
               "game/art/hud/likes_heart.png", "game/scripts/hud/likes_fire.gd (PALETTE)"]

# name: (brief, what it is, frames, frame size or None)
ASSETS = {
    "clock_digits": ("clock_digits", "The clock's digits: one row of 12 greyscale frames (0-9, colon, unlit 8) for the game to tint green, yellow, orange and red; white centre line, light grey sides, a two-step grey halo (the drawn glow).", 12),
    "clock_panel": ("clock_panel", "The digital clock's dark panel: steel bezel lit from the top left, screws, black screen with scanlines and a glare.", 0),
    "viewers_panel": ("viewers_panel", "The live viewers counter's panel: the clock panel's housing with a cyan inner rim (the viewers colour).", 0),
    "live_badge": ("live_badge", "The red LIVE badge: a white dot and LIVE in bold white pixel letters on a red plate.", 0),
    "viewers_fire": ("viewers_fire", "The viewers counter's fire over a million: 12 looping frames (12 a second) of flames round the viewers panel, which sits at (8, 24) in each frame and is left clear.", 12),
    "subgoal_frame": ("subgoal_frame", "The sub goal square's frame: dark outline, white ring, black inside from (4, 4) to (59, 59) with rounded inner corners.", 0),
    "heart_full": ("heart_full", "The full heart of the row of 5 hearts.", 0),
    "heart_empty": ("heart_empty", "The empty (lost) heart, made from the kept full heart by script.", 0),
    "eye_icon": ("eye_icon", "The viewers' eye icon (on the viewers counter and on the trick popups).", 0),
    "subs_icon": ("subs_icon", "The subs icon, the proposal instead of the star: a subscriber with a pink plus badge.", 0),
}
MADE_BY = {
    "heart_empty": "game/tools/build_hud_livestream_art.py heart-empty --from game/art/hud/heart_full.png (script)",
    "eye_icon": "game/tools/build_hud_livestream_art.py eye (script); the style loop's generator made one PixelLab "
                "candidate (not kept: the script version read better at this size)",
    "subs_icon": "game/tools/build_hud_livestream_art.py subs (script, version 3 at 22 x 22); one PixelLab candidate "
                 "was made in version 1 and not kept",
}
SPLITS = {"clock_digits": [f"clock_digit_{c}" for c in "0123456789"] + ["clock_digit_colon", "clock_digit_off"],
          "viewers_fire": [f"viewers_fire_{i:02d}" for i in range(12)]}


def runs(review):
    """The Style review's runs as {brief name: (text of the run)}."""
    parts = re.split(r"^### Run \d+\s*$", review, flags=re.M)
    out = {}
    for p in parts:
        m = re.search(r"brief `art-archive/T-339/briefs/([a-z_]+)\.md`", p)
        if m:
            out[m.group(1)] = p
    return out


def kept(run_text):
    m = re.search(r"\*\*Kept:\*\* version (\d+), score (\d+)/10 \(`([^`]+)`", run_text)
    if not m:
        return None
    rounds = re.findall(r"- Score: (\d+)/10", run_text)
    return {"version": int(m.group(1)), "score": int(m.group(2)), "file": m.group(3),
            "round_scores": [int(s) for s in rounds]}


def pixellab_calls(names):
    calls = []
    if not LOG.exists():
        return calls
    for line in LOG.read_text(encoding="utf-8").splitlines():
        r = json.loads(line)
        if r.get("task") == "T-339" and any(str(r.get("name", "")).startswith(n) for n in names):
            calls.append({"name": r.get("name"), "result": r.get("result"), "usage": r.get("usage"),
                          "prompt": r.get("prompt"), "time": r.get("time")})
    return calls


def main():
    review = TASK.read_text(encoding="utf-8").split("## Style review", 1)[1].split("## Result notes", 1)[0]
    by_brief = runs(review)
    for name, (brief, what, frames) in ASSETS.items():
        png = HUD / f"{name}.png"
        if not png.exists():
            print(f"skip {name}: no PNG yet")
            continue
        w, h = Image.open(png).size
        loop = kept(by_brief.get(brief, "")) if brief in by_brief else None
        calls = pixellab_calls([name])
        rec = {
            "task": "T-339",
            "what": what,
            "size": [w, h],
            "frames": frames or 1,
            "frame_size": [w // frames, h] if frames else [w, h],
            "shown_at_scale": 2,
            "made_by": MADE_BY.get(name, "game/tools/build_hud_livestream_art.py (script); the style loop kept the "
                                             "script version"),
            "style_loop": {"brief": f"art-archive/T-339/briefs/{brief}.md", "kept": loop,
                           "versions": "art-archive/T-339/style-loop/", "review": "tasks/T-339-art-the-livestream-hud.md, Style review"},
            "pixellab_generations": sum(int((c.get("usage") or {}).get("generations", 0) or 0) for c in calls),
            "pixellab_candidates_not_kept": calls,
            "references": COMMON_REFS,
        }
        if name in SPLITS:
            rec["split_into"] = [f"game/art/hud/{n}.png" for n in SPLITS[name]]
        (HUD / f"{name}.json").write_text(json.dumps(rec, indent=1) + "\n", encoding="utf-8")
        print(HUD / f"{name}.json")
        for i, part in enumerate(SPLITS.get(name, [])):
            if (HUD / f"{part}.png").exists():
                pw, ph = Image.open(HUD / f"{part}.png").size
                sub = {"task": "T-339", "what": f"Frame {i} of game/art/hud/{name}.png, as its own PNG.",
                       "size": [pw, ph], "shown_at_scale": 2, "frame_of": f"game/art/hud/{name}.png", "frame": i,
                       "made_by": "game/tools/build_hud_livestream_art.py split (a crop of the kept sheet, no new pixels)",
                       "style_loop": rec["style_loop"], "references": COMMON_REFS}
                (HUD / f"{part}.json").write_text(json.dumps(sub, indent=1) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
