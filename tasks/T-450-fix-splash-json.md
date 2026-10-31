---
id: T-450
title: Fix splash.json: the source path's backslashes break JSON and master's tests
status: in-progress
from: project-lead
to: asset-generation
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, game/art/menu/splash.json, game/tests/unit/test_pixellab_assets.gd]
files_expected_to_change: [game/art/menu/splash.json]
model: sonnet
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

T-445 (the board's splash, merged without tests as board-approved art) wrote `game/art/menu/splash.json` with the board's Windows path in its "source" field using single backslashes (`C:\Users\andre\...` written as `C:\U...` unescaped), which isn't valid JSON. On master, `res://tests/unit/test_pixellab_assets.gd` (`test_generated_pngs_load_with_recorded_size`) now fails with "Parse JSON failed ... Invalid escape sequence", so every merge stops on it.

Fix the record so it is valid JSON with the same information (escape the backslashes or use forward slashes). Change nothing else: the splash picture stays byte for byte. Check every other JSON file under game/art/ parses too (`python -c` over them, or a small loop), and list any other bad one in the result notes without fixing it.

Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `python -c "import json; json.load(open('game/art/menu/splash.json'))"` succeeds, and the record keeps its fields and the source path's meaning. (QA: pass / fail)
- [ ] game/art/menu/splash.png is unchanged (same SHA-256 as on master). (QA: pass / fail)
- [ ] The Godot test file `res://tests/unit/test_pixellab_assets.gd` passes (run with the project's test runner for that file, or the full Godot set). (QA: pass / fail)
- [ ] Every JSON file under game/art/ parses; any other bad file is listed in the result notes. (QA: pass / fail)
- [ ] The game/tools Python tests pass (`python -m unittest discover -s game/tools -p "test_*.py"`). (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Open → In progress

Started: fixing the splash record that turned master's tests red.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Fixed game/art/menu/splash.json: the "source" path now uses forward slashes (C:/Users/andre/Downloads/...); every other field is untouched. splash.png unchanged (its SHA-256 matches the record). All JSON files under game/art/ parse; no other bad one. test_pixellab_assets.gd passes (1 test, 21 asserts). game/tools Python tests: 767 OK (1 skipped). Nothing in game/data/levels/ touched.
