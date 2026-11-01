---
id: T-480
title: Frame drops: trick popups build their textures while drawing
status: open
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: [T-468]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, tasks/T-468-run-performance-recorder.md, game/docs/game-loop/perf-recorder.md, game/scripts/hud/trick_popups.gd]
files_expected_to_change: [game/scripts/hud/trick_popups.gd, game/tests/unit/, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's recorded run (T-468, recording `game/perf/2026-11-01_13-13-18` in T-468's folder, 286 s, 150 frames over 25 ms): the top cause is `draw.popup` in `game/scripts/hud/trick_popups.gd` `_draw()`: 13.3 ms a call in spike frames against 0.24 ms usually, the largest part of 117 of the 150 spikes (up to 49 ms in one frame), mostly with two popups showing and often after `combo_broken`. `texture()` and `broken_textures()` appear to build the popup's textures (and the broken popup's two halves) the first time they are drawn; check it.

Make drawing a popup cheap every frame: build its textures before it is first drawn, or cache them by text and style so the same popup text never builds twice in a run (keep the cache bounded), with the popups looking exactly as they do today. Measure before and after with the recorder (`--record-perf`, `python game/tools/analyse_perf.py`, or a scripted run that shows many popups, broken ones included). Never write, move or commit anything in game/data/levels/.

The board's review: play a run with many tricks and broken combos and feel no hitch when a popup appears.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes say what made draw.popup expensive, with the evidence. (QA: pass / fail)
- [ ] A measured before/after (the recorder or a scripted benchmark) shows `draw.popup` under 1 ms a call at its worst, including a broken popup's first frame; numbers in the result notes. (QA: pass / fail)
- [ ] A test shows a popup (normal and broken) looks the same as before: same texture size and pixels as today's build for a sample of texts. (QA: pass / fail)
- [ ] A test shows the texture cache stays bounded over many different popup texts. (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content, Trick popups) notes the textures are built ahead of drawing. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
