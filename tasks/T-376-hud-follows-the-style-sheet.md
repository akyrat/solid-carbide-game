---
id: T-376
title: The HUD's code follows the HUD style sheet (fonts, colours, outlines)
status: open
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-375]
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md, game/scripts/hud/]
files_expected_to_change: [game/scripts/hud/, game/scripts/ui/, game/scenes/, game/data/hud.json, game/tests/unit/, game/docs/hud-and-menus/, docs/hud-and-menus.md, art-archive/]
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

The board's decision (HUD and menus, Decisions, "A consistent HUD", 2026-10-29). The art ticket (T-375) wrote the HUD style sheet in Visual style and listed, piece by piece, the code changes it needs (fonts, colours, outline widths). Make them, so every HUD piece follows the sheet. Positions, sizes and behaviour stay as they are (the HUD scaling is another ticket). No new text.

The board's review: play a run and see one consistent HUD.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every code change T-375's result notes list is made (a check list in the result notes), and the HUD's layout and behaviour tests still pass. (QA: pass / fail)
- [ ] HUD and menus, Content and the game docs describe the style each piece now uses. (QA: pass / fail)
- [ ] A screenshot of a run with the whole HUD is in `art-archive/<id>/screenshots/`, next to T-375's before shot. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
