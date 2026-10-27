---
id: T-306
title: Code comments, tests, tool names and game/README.md say Greenbull, behaviour unchanged
status: in-qa
from: project-lead
to: qa-integration
lead: Goal-G-006
epic: tooling
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: no
depends_on: [T-298, T-299, T-302, T-303, T-304, T-305]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/tools/style_rules.py, game/scripts/hud/hud.gd, game/tools/make_logo_sizes.py]
files_expected_to_change: [game/scripts/, game/tests/, game/tools/, game/README.md]
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

After the rebrand tickets of this goal, code comments, tests, tool names and game/README.md still say Redgull in many places (for example 'never Redgull red' in game/scripts comments, REDGULL_RED and is_redgull_red in style_rules.py, HEART_COLOR's comment in hud.gd, make_logo_sizes.py, draw_gull_silhouette.py). Make them follow the new name and the docs (Visual style, Decisions, 'Red after the rebrand': red is no longer Greenbull's, the likes heart stays red), without changing behaviour:

- Rename constants, flags and functions named after Redgull to names that say what they are now (for example the heart's red, or the red check), with every caller; values and checks unchanged.
- Rewrite comments and test messages that say Redgull to what is true now; keep historical facts in art records as they are.
- Redgull-only tools (make_logo_sizes.py, draw_gull_silhouette.py, flatten_logo.py if Redgull-only) are renamed or marked as the old logo's history, never deleted.
- game/README.md says Greenbull where it describes the sponsor, and the old Redgull logo as history.

Show in the result notes that the diff touches only names, comments and strings. Nothing to picture: the result notes say so in one line.

## Acceptance criteria

- [ ] `git grep -i redgull game/scripts game/tests game/tools game/README.md` finds nothing except history in art records or in tools marked as the old logo's history, each match listed in the result notes. (QA: pass; all matches are listed and are record strings, archive/logo paths or HISTORY-marked tools; BANNED_WORDS and its tests keep the name on purpose, a Project Lead call noted in the result notes)
- [ ] REDGULL_RED, is_redgull_red, the --redgull flag and any other name after Redgull are renamed, with every caller; the result notes show the diff touches only names, comments and strings, and the constants' values are unchanged. (QA: pass; no REDGULL_RED/is_redgull_red/--redgull left, result notes list renames and values; all three test sets pass)
- [ ] make_logo_sizes.py and any other Redgull-only tool is renamed or marked as the old logo's history; none is deleted (git log shows no deletion). (QA: pass; make_logo_sizes.py and 4 others marked HISTORY, no deletions in git log)
- [ ] The likes heart's colour (hud.gd HEART_COLOR) is unchanged. (QA: pass; diff changes only its comment)
- [ ] All three test sets pass. (QA: pass; game/tools 490 OK, tools 501 OK, GUT 1419/1419)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Blocked → In progress

Goal runner (G-006): started, in C:\solid-carbide-worktrees\T-306.

### 2026-10-27, In progress → In QA

Goal runner (G-006): the agent is done; QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

### 2026-10-27, game-loop agent run (goal G-006)

Two commits: code, tests and tools; then `game/README.md`. 97 files changed, 430 insertions and 298 deletions (`git diff --stat HEAD~2 HEAD`). 119 of the added lines are the one-off rename script. No art, scene, data or `.import` file changed. Godot's `.import` line-ending noise is left uncommitted.

**How:** `game/tools/_t306_rename.py`, a one-off script run once, did the mechanical renames: identifiers in every file, then prose rules for comments and strings. It skips lines that write art records. The rest was done by hand. The script is committed, marked HISTORY at its top, as the record of the rename. I had meant to leave it uncommitted, but unstaging it (`git reset`) was refused, so it went in openly.

**Renames (every caller, values and checks unchanged):**
- `style_rules.REDGULL_RED` → `OLD_LOGO_RED`, still `(135, 17, 27)`. `HEART_COLOR` is still `(219, 26, 41)`.
- `is_redgull_red` → `reads_as_red`, same body, same `max_dist=128, hue_deg=25`.
- `check_redgull_logo` → `check_old_logo`.
- `build_weapon_art.near_redgull` → `near_old_logo_red`.
- `build_health_canister.MIN_REDGULL_DISTANCE` → `MIN_OLD_LOGO_RED_DISTANCE`, still 45.0.
- `build_meteor_fx._redgull_pixels` → `_red_pixels`.
- In the GUT tests:
  - `REDGULL_RED` (test_exhaust_flamethrower) → `HEART_RED`, still `Color(0.86, 0.1, 0.16)`.
  - `REDGULL_REDS` → `HEART_AND_OLD_LOGO_REDS`, still `[Color(0.86, 0.1, 0.16), Color8(135, 17, 27)]`.
  - `_is_redgull_red` → `_reads_as_red`.
  - `_far_from_redgull` → `_far_from_heart_red`.
  - Local `redgull` variables → `heart_red` or `old_logo_red`, same values.
  - Test functions named `*_redgull_red*` → `*_heart_red*` or `*_old_logo_red*` in GDScript, `*_red*` in Python.
- The `--redgull` flag had already gone in T-298. Nothing else was named after the old sponsor.

**What the diff touches:**
- Every changed line in `game/scripts` is a `##` comment. hud.gd `HEART_COLOR := Color(0.86, 0.1, 0.16)` is unchanged; only its comment now says it is the likes heart's red, kept red (Visual style, "Red after the rebrand").
- In the tests and tools, the changes are identifiers (listed above), comments, docstrings and check-label strings. Example: `"no Redgull red (nor any red)"` → `"no red"`, with the matching `assertIn` updated.
- No number, condition or call changed.

**What the comments say now:**
- GDScript comments say "the heart's red" (`HEART_COLOR`), which is what the tests check against.
- Python checks built on `reads_as_red` say "red".
- Checks against (135, 17, 27) say "the old logo's red".
- `game/README.md` says Greenbull for the sponsor. Its T-075 paragraph is now "The old Redgull logo (T-075), history", and it lists the history-marked tools.

**Old-logo tools (none deleted):** `make_logo_sizes.py`, `draw_gull_silhouette.py`, `flatten_logo.py`, `check_logo_one_colour.py` and `test_check_logo_one_colour.py` each now start with "HISTORY: the old logo's tool".

**What `git grep -i redgull game/scripts game/tests game/tools game/README.md` still finds (as of the second commit):**
- History in art records:
  - Record-writing strings and keys whose text is in the committed art records. They are left as they are, so a rebuild still reproduces those records byte for byte. Records: `game/art/effects/boost_lines.json`, `drift_mark.json`, `drift_smoke_puff.json`, `health_canister.json`, `level_up_particles.json`, `game/art/gift_pack/helicopter_sheet.json`, `game/art/hud/likes_heart.json`, `game/art/banners/banners.json`.
    - `build_boost_lines.py:169` and `build_buildings.py:309`: `closest_to_redgull_red`.
    - `build_drift_mark.py:163`, `build_drift_smoke.py:188` and `build_level_up_particles.py:186`: `"rules"`.
    - `build_health_canister.py:113`, `114` and `117`: the key, the `"notes"` and the print that reads the key.
    - `build_heart_icon.py:113` and `118`: `"what"` and `"references"`.
    - `build_helicopter.py:364` and `376`: `"task"` and `redgull_red_pixels`.
    - `build_kaiju_banners.py:356`: `"red_note"`.
    - `test_build_boost_lines.py:20`: reads that record key.
  - Paths of kept art:
    - `art-archive/T-304/redgull/` (`build_gift_package.py:19`, `38`, `177`) and `art-archive/T-305/redgull/` (`build_helicopter.py:19`, `44`, `347`).
    - `game/art/logo/redgull_logo_*.png` (`test_build_level_up_art.py:96`, `test_style_rules.py:133`).
    - In README:1101, the two archive paths.
- Tools and tests marked as the old logo's history:
  - `make_logo_sizes.py:2`, `5`, `86`, `90`.
  - `draw_gull_silhouette.py:2`, `flatten_logo.py:2`, `check_logo_one_colour.py:2`.
  - `test_check_logo_one_colour.py:1`, `25`, `29`, `33`.
  - `_t306_rename.py:2`, `12`, `58`.
  - The README:1177 history paragraph.
- **Not history. Kept because changing them would change behaviour. The Project Lead should decide whether this passes:**
  - `style_rules.py:269` `BANNED_WORDS` keeps the old name. Text rule 2 still bans it.
  - Its tests: `test_style_rules.py:172`, `179`, `180`, and `:160`, which checks that the old `--redgull` flag stays gone.
  - `test_check_level_up_texts.py:26`, a fixture row quoting an old text record ("Redgull Pit Stop" → "Greenbull pit stop").

**Tests:**
- `python -m unittest discover -s game/tools -p "test_*.py"`: Ran 490, OK (skipped=1).
- `python -m unittest discover -s tools -p "test_*.py"`: Ran 501, OK.
- GUT (`bash game/tools/run_tests.sh`): 118 scripts, 1419/1419 tests passing, "All tests passed!". This ran on the working tree just before the two commits, with the same content apart from README wording.

**Screenshots:** none. Comments, names and docs only; nothing on screen changed.

**Refusals:** `git reset -q game/tools/_t306_rename.py`, to unstage the one-off script, was refused. It was not essential; the script is committed instead, marked HISTORY.

PixelLab: 0 generations. Documents affected: `game/README.md` (updated).
