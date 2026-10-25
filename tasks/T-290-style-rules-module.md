---
id: T-290
title: "One style rules module: the script checks of the style guide, in one place"
status: in-progress
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md, tasks/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/tools/check_sprite_rules.py, game/tools/check_logo_one_colour.py, game/tools/reduce_palette.py]
files_expected_to_change: [game/tools/, game/README.md, tasks/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

First of three tickets for the style loop (`tasks/README.md`, "The style loop"; T-291 builds the loop, T-292 enforces it). The board wants this to simplify what it touches, not add another layer.

The style guide is now two numbered rule lists: Visual style, Content, "Rules" and Extended narrative, Content, "Text rules". Rules marked *(script)* are checked by a script. Today those checks are scattered:
- `check_sprite_rules.py` (size, RGBA, transparency, colour count) and `check_logo_one_colour.py` are separate scripts;
- about 22 build scripts in `game/tools/` each carry their own "not Redgull red" check (`grep -il "redgull red\|HEART_COLOR\|135, *17, *27" game/tools/*.py`);
- nothing checks text.

This ticket makes **one module, `game/tools/style_rules.py`**, the only place these checks live:
- **Art:** Visual style rules 1, 3 and 6: every pixel alpha 0 or 255, transparent background, at most 30 colours, the expected size (whole image or each frame of a one-row sheet), and no Redgull red (RGB 135, 17, 27, with the same distance threshold the code uses today), unless the asset is one of Redgull's own things (a flag). The logo's one-colour check moves in too.
- **Text:** Text rules 2 and 4: banned words ("XP", "points", "Godzilla", the form "Redgull says"), and format and length by kind of text (popup: capitals ending in "!"; card title 30 and description 90; garage name 25 and description 80 with no digits; label).
- Each result names the rule number it checks, so the Style Evaluator (T-291) can quote it.

Then the old copies go: `check_sprite_rules.py` and `check_logo_one_colour.py` are removed or become two-line wrappers, and every build script that has its own red check imports it from `style_rules.py` instead. Behaviour stays the same: no committed art changes.

## Acceptance criteria

- [ ] `game/tools/style_rules.py` exists with a command line: `art <png> [--size WxH] [--frames N] [--redgull]` and `text "<text>" --kind popup|card_title|card_desc|garage_name|garage_desc|label`. Each prints JSON: a list of checks, each with the rule number, ok true/false and a detail, and exits 1 when any check fails. (QA: pass / fail)
- [ ] Unit tests for `style_rules.py` cover each art check and each text check, with a passing and a failing example (for example COMBO BROKEN! passes as a popup, "combo broken" fails; "Gain more XP" fails rule 2). (QA: pass / fail)
- [ ] No Python file in `game/tools/` other than `style_rules.py` defines its own Redgull red constant or red-distance check: `grep -n "135, *17, *27" game/tools/*.py` matches only `style_rules.py` and tests. (QA: pass / fail)
- [ ] `check_sprite_rules.py` and `check_logo_one_colour.py` are gone or are thin wrappers calling `style_rules.py`, and every caller and doc mention still works. (QA: pass / fail)
- [ ] `git status` shows no changed files under `game/art/` (no art was rebuilt differently). (QA: pass / fail)
- [ ] All three test sets pass: `python -m unittest discover -s tools -p "test_*.py"`, `python -m unittest discover -s game/tools -p "test_*.py"` and `bash game/tools/run_tests.sh`. (QA: pass / fail)
- [ ] `game/README.md` describes `style_rules.py` in place of the old checkers, and `tasks/README.md`, "The style loop", names it as the script check. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-25, Open → In progress

Started: one style rules module for the style guide's script checks, replacing the scattered checkers. Opus agent in C:\solid-carbide-worktrees\T-290.

## Result notes

**What changed (2026-10-25):**
- New `game/tools/style_rules.py`, the one place for the style guide's script checks. Command line `art <png> [--size WxH] [--frames N] [--redgull] [--allow-red R,G,B] [--max-colors N] [--logo]` and `text "<text>" --kind popup|card_title|card_desc|garage_name|garage_desc|label`; each prints a JSON list of `{rule, check, ok, detail}` and exits 1 on any fail. Art: Visual style rule 1 (transparent corners, alpha 0 or 255, at most 30 colours, has opaque pixels), rule 3 (size of the image, or of each frame with `--frames`; skipped without `--size`), rule 6 (no red that reads as Redgull red; skipped with `--redgull`; `--allow-red` for the three other allowed reds, the kaiju sign's, the canister's, the combo popup's), and `--logo` for the logo's one-colour check (reported as rule 6). Text: rule 2 (whole words "XP", "points", "Godzilla", any case), rule 3 (no "Redgull says"; the task listed it with the banned words, but Extended narrative writes it in rule 3, so the result says 3), rule 4 (popup: one line, capitals, ends with "!"; card title 30, card description 90, garage name 25, garage description 80 with no digits; label: one line, sentence case, proper names Redgull, Stunt, Driver, Tokyo allowed capitalised).
- The red check kept today's threshold: `is_redgull_red` (the shared check of drift marks, level-up particles, smoke, placeholders, banners and the coin effects: within 128/255 of `HEART_COLOR` (219, 26, 41), or a saturated red hue), `red_distance` + `RED_MIN_DISTANCE` 0.5 (buildings, skyscrapers, trick popup, boost lines), `rgb_distance` for the two build steps with their own distances to the logo's red (weapon art's unred step, 60; the canister's 45). `REDGULL_RED` (135, 17, 27, the logo's) and `HEART_COLOR` are defined only here.
- `check_sprite_rules.py` and `check_logo_one_colour.py` are now thin wrappers: they re-export `decode_png`/`check`/`check_rows`/`split_sheet`/`check_sheet` and `check_logo` from `style_rules.py`, and their old command lines run `style_rules.py art ... --redgull` (sprite rules only, as before; output is now JSON) and `art ... --logo`. Their tests pass unchanged.
- Scripts now importing `style_rules` (no own Redgull red constant, distance or red check left): build_boost_lines, build_buildings, build_skyscrapers, build_drift_mark, build_drift_smoke, build_level_up_particles, build_hit_coin_damage_effects, build_gift_placeholders, build_heart_icon, build_kaiju_banners, build_trick_popup, build_weapon_art (build_weapon_effects through it), build_health_canister, build_gift_package, build_helicopter, make_logo_sizes, build_elevation_art, build_elevation_sample_art, build_meteor_fx. Also switched from `check_sprite_rules` to `style_rules` for the PNG reader: build_car_sheet, build_car_sheet32, build_car_inbetween_sample, build_level_up_art, build_road_tile, remove_car_shadow, and their tests. The three scripts with a crude "R > 110/150, G and B low" red count (elevation art, elevation sample art, meteor effects) now use `is_redgull_red`; their checks still pass on the committed art.
- Behaviour: every build script's `check` gives the same verdict as before (15 checks run before and after). One readout moved: build_boost_lines' `closest_to_redgull_red` is 0.742 instead of 0.757, because its own copy of the heart red was (0.86, 0.08, 0.16) instead of hud.gd's (0.86, 0.1, 0.16); its palette is unchanged (every colour is far above 0.5), so a rebuild would draw the same PNG and change only that number in `boost_lines.json`. No art was rebuilt; `git status` shows nothing under `game/art/`.
- Tests: new `game/tools/test_style_rules.py` (17 tests: each art and text check with a passing and a failing example, both CLI commands). The red-function tests that `test_build_drift_mark.py` and `test_build_level_up_particles.py` kept on their own copies moved into it (3 removed there).
- Docs: `game/README.md` ("The style rules (T-290)" under Generating art; the car, minion and logo check commands now use `style_rules.py`), `tasks/README.md` ("The style loop" names `style_rules.py` as the script check).
- Found while checking: the approved car (car_sw_front, car_iso, the T-101 sheet) has a pale tail-light red (230, 110, 102) that rule 6's check flags (it is within 0.5 of the heart red). The README's car commands pass `--allow-red 230,110,102`. Question for the board: should Visual style rule 6 list the car's tail lights as an allowed red, or should the check be narrower?
- Test counts: `python -m unittest discover -s tools -p "test_*.py"`: 451 OK. `python -m unittest discover -s game/tools -p "test_*.py"`: 409 OK (1 skipped; 395 before). GUT (`bash game/tools/run_tests.sh`): 1419 of 1419 passing (118 scripts). The GUT run's line-ending-only `.import` rewrites were reverted, not committed.
- Screenshots: none (tooling).
