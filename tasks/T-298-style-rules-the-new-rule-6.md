---
id: T-298
title: Style rules: the new rule 6 (Greenbull's colours), Greenbull's logo check, and Redgull as a banned word
status: in-qa
from: project-lead
to: project-lead
lead: Goal-G-006
epic: tooling
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/tools/style_rules.py, game/tools/test_style_rules.py, game/tools/check_logo_one_colour.py, game/tools/test_check_logo_one_colour.py, game/tools/check_sprite_rules.py, tasks/T-290-style-rules-module.md, tasks/T-294-art-greenbull-emblem.md, tasks/T-295-art-greenbull-wordmark.md]
files_expected_to_change: [game/tools/style_rules.py, game/tools/test_style_rules.py, game/tools/check_logo_one_colour.py, game/tools/test_check_logo_one_colour.py, game/tools/check_sprite_rules.py, game/tools/test_check_sprite_rules.py, game/README.md]
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

The sponsor Redgull is now Greenbull (board, 2026-10-26; Visual style, Decisions, 'The rebrand', 'Greenbull's look', 'Red after the rebrand'; Content, 'Rules', rule 6 'Greenbull's colours'; Extended narrative, Decisions, 'The rebrand' and Content, 'Text rules'). The script checks in game/tools/style_rules.py (T-290) still follow the old rule 6. Bring them in line with the docs as written, without inventing anything:

- Art, rule 6: red is no longer reserved, so a sprite is never failed for red pixels. Greenbull's light green (RGB 104, 220, 96) and yellow (RGB 247, 208, 52) may appear only on Greenbull's own things: without the Greenbull flag, a sprite that uses either colour (or one that reads as it, the same way the red check measured closeness) fails rule 6; with the flag it passes. Rename the flag --redgull to --greenbull (and the art_checks keyword the same way). Keep --allow-red working, or rename it to fit the new rule, saying which in the result notes.
- Logo check: replace the one-colour Redgull logo check (--logo, check_logo, check_logo_one_colour.py) with a check that accepts Greenbull's approved emblem art-archive/T-294/greenbull_emblem_128.png, _64.png, _32.png and wordmark art-archive/T-295/greenbull_wordmark.png, following the rule that Greenbull's logo is flat brand art: exempt from rule 2, bound by rule 1 (Visual style, Content, Rules). Rename or replace check_logo_one_colour.py and its test; don't delete the old check's history (mark it as the old logo's, or rename it).
- Text: rule 2 bans 'Redgull' in any case; rule 3 becomes no 'Greenbull says ...' line; 'Greenbull' joins the proper names.
- The red-distance helpers used elsewhere (is_redgull_red, REDGULL_RED, HEART_COLOR) keep their values and behaviour here; their renaming is a later ticket of this goal. Only what rule 6 needs changes now.

Run check_sprite_rules.py over game/art on master and on your branch and compare the rule 6 results asset by asset. Update game/README.md, 'The style rules', to describe the new checks and flags. Tooling only: nothing to picture, so the result notes say so in one line instead of screenshots.

## Acceptance criteria

- [ ] style_rules.py's art check no longer fails a sprite for red pixels: a test with a pure red (255, 0, 0) sprite passes rule 6. (QA: pass: test_rule_6_red_is_not_reserved)
- [ ] Without the Greenbull flag, the art check fails rule 6 for a sprite using RGB 104, 220, 96 and for one using RGB 247, 208, 52 (one test each); with --greenbull (renamed from --redgull) the same sprites pass rule 6 (tests). (QA: pass: light green and yellow tests exist, pass)
- [ ] The logo check accepts art-archive/T-294/greenbull_emblem_128.png, _64.png, _32.png and art-archive/T-295/greenbull_wordmark.png (tests), in place of the one-colour Redgull check. (QA: pass: test_greenbull_logo_accepts_the_approved_emblem_and_wordmark, test_check_greenbull_logo)
- [ ] The text check fails rule 2 on a text containing 'Redgull', 'REDGULL' and 'redgull' (tests) and fails rule 3 on 'Greenbull says hi' (test); a text naming 'Greenbull' alone passes both rules (test). (QA: pass)
- [ ] The result notes list check_sprite_rules.py's rule 6 result over game/art on master and on the branch: every asset that passed rule 6 on master still passes, except any asset now flagged, each listed with the reason. (QA: pass: result notes list coin.png as the one new flag, with reasons; I did not rerun the report)
- [ ] `python game/tools/style_rules.py art --help` shows --greenbull and no --redgull. (QA: pass)
- [ ] game/README.md, 'The style rules', describes the new rule 6 check, the --greenbull flag, the Greenbull logo check and the Redgull ban, and doesn't say rule 6 reserves red. (QA: pass)
- [ ] game/tools/test_style_rules.py, the logo check's test (test_check_logo_one_colour.py or its renamed successor) and all the Python tool tests in game/tools pass. (QA: pass: 462 tests OK, 1 skipped)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-26, Open → In progress

Goal runner (G-006): started, in C:\solid-carbide-worktrees\T-298.

### 2026-10-26, In progress → In QA

Goal runner (G-006): the agent is done; QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**What changed** (commit ce6ba325, all in `game/tools/` and `game/README.md`):

- **Rule 6, art** (`style_rules.py`): red is no longer checked. New `GREENBULL_DARK_GREEN`, `GREENBULL_LIGHT_GREEN` (104, 220, 96), `GREENBULL_YELLOW` (247, 208, 52), `GREENBULL_MAX_DIST = 25` and `greenbull_colour(rgb)`. Without the flag, a sprite fails rule 6 when an opaque colour is closer than 25 (RGB distance, measured as the red check measured closeness to the heart's red) to the light green or the yellow. The dark green is not checked: the docs make it the car's body colour too. The flag `--redgull` is now `--greenbull`, and the `art_checks` keyword `redgull` is now `greenbull` (positional order kept, so `tools/style_loop/loop.py`'s call still works).
- **`--allow-red` renamed** `--allow-colour` (keyword `allow`), because the allowed colours are now colours near Greenbull's, a fire's yellow for example. `--allow-red` still works as an alias, so the commands already in game/README.md still run.
- **Threshold (my proposal for the playtest, the goal's open question 1):** 25 is tight. At 40 the city's amber (255, 178, 60; 32 from the yellow) failed 20 buildings, and the car's headlights (243, 180, 46; 29 away) failed too. At 25 these stay clear.
- **Logo check:** `check_logo` / `logo_checks` / `--logo` now check Greenbull's logo as flat brand art: rule 1 only (alpha 0 or 255, transparent corners, at most 30 colours, something visible). It is exempt from rule 2, and rule 6 doesn't apply. The approved emblem (`art-archive/T-294/greenbull_emblem_128.png`, `_64`, `_32`) and wordmark (`art-archive/T-295/greenbull_wordmark.png`) pass. The new command is `check_greenbull_logo.py`, with its test `test_check_greenbull_logo.py`. The old one-colour check is kept as history: it is now `check_redgull_logo`, `check_logo_one_colour.py` is marked as the old Redgull logo's check, and its test still passes.
- **Text:** "Redgull" joins the banned words of rule 2 (any case, whole word). Rule 3 is now no "Greenbull says ..." line. "Greenbull" replaces "Redgull" among the proper names a label may capitalise.
- **Unchanged as asked:** `is_redgull_red`, `REDGULL_RED`, `HEART_COLOR`, `red_distance` and `RED_MIN_DISTANCE`.
- **`check_sprite_rules.py`:** the old command now passes `--greenbull`, so it still checks only rules 1 and 3. `--rule6` adds rule 6. `--rule6-report DIR [--against REV]` prints rule 6 for every PNG under DIR, next to the result of `style_rules.py` as it is at a git revision. Tests: `test_check_sprite_rules.py`, the old tests kept and a `Rule6` class added.
- **game/README.md, "The style rules":** describes the new rule 6, `--greenbull`, `--allow-colour`, the logo check, the Redgull ban and the report. The T-014 note about the tail lights' `--allow-red` was updated too.

**Rule 6 over game/art, master against this branch** (`python game/tools/check_sprite_rules.py --rule6-report game/art --against master`, 105 PNGs):

- **Passed on master, still pass:** every asset except one.
- **Passed on master, now flagged (1):** `game/art/effects/coin.png`. The coin's gold (255, 204, 64) is 15 from Greenbull's yellow (247, 208, 52), so it reads as it. Rule 6 keeps the yellow to Greenbull's things, and the coin isn't one of them. It's left for the board: allow it on the coin (`--allow-colour 255,204,64`) or recolour the coin. No art was changed here.
- **Failed on master (old red rule), now pass (27):** the 6 kaiju banners, `car_iso.png`, `car_iso_noshadow.png`, `car_sw_front.png`, `burning_flames.png`, `exhaust_flame_sheet.png`, `health_canister.png`, `helicopter_sheet.png`, `likes_heart.png`, `button_plate.png`, `button_plate_pressed.png`, `card_frame.png`, `gift_pack_emblem.png`, `header_ribbon.png`, `sunburst.png`, `weapon_gun.png`, the 3 `redgull_logo_*.png`, `molotov_bottle.png`, `molotov_fire.png` and `molotov_fire_flip.png`.
- **Failed on master, still fail, now for Greenbull's yellow (6):**
  - `gift_pack/package.png` and `package_falling.png` (246, 213, 43): Greenbull's things, so they pass with `--greenbull`.
  - `level_up/highlight_frame.png` (255, 214, 64): level-up screen, so it passes with `--greenbull`.
  - `level_up/weapon_flamethrower.png` (254, 223, 43) and `weapon_molotov.png` (247, 187, 43): weapons, which are Greenbull's things, and fire yellow (Visual style allows yellow where the subject is fire), so they pass with `--greenbull` or `--allow-colour`.

**Tests:**
- `python -m unittest discover -s game/tools -p "test_*.py"`: 462 tests, OK (1 skipped, as before).
- `python game/tools/style_rules.py art --help` shows `--greenbull` and no `--redgull` (tested in `test_cli_art_help_names_greenbull_not_redgull`).

**Known follow-up for T-299:** `tools/style_loop/test_loop.py::test_the_script_checks_find_a_red` now fails. It expects a red sprite to fail rule 6 and the text "no Redgull red", which is exactly the old rule this ticket removes. It is outside this ticket's files, and T-299 (style loop follows the new rule 6) owns it. The other 21 style loop tests pass.

**Refusals:** one. `cd game/tools; python -m unittest ...` was refused (needs approval). I ran the same tests with the pre-approved `python -m unittest discover -s game/tools ...` instead. Nothing else was refused.

**Screenshots:** none. This is tooling only, with nothing on screen to picture.

PixelLab: 0 generations.
