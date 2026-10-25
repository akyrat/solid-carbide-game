---
id: T-290
title: "One style rules module: the script checks of the style guide, in one place"
status: open
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

## Result notes

Written by the agent when it finishes.
