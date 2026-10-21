---
id: T-249
title: The drift trail changes and gains effects with the hype level
status: open
from: project-lead
to: driving-drift
lead: Coursework
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/hud-and-menus.md, game/README.md, game/scripts/driving/drift_marks.gd, game/scenes/driving/drift_marks.tscn, tasks/T-117-drift-marks.md, tasks/T-131-combo-heat-levels.md]
files_expected_to_change: [game/scripts/driving/, game/scenes/driving/, game/tools/, game/art/effects/, game/tests/unit/, game/README.md, docs/visual-style.md, art-archive/T-249/screenshots/]
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

The board's decision (Visual style, Decisions, "Hype drift trail", 2026-10-22): the drift marks (T-117, T-118) change and gain effects with the hype level, on the same combo heat steps as the HUD's combo counter and the trick popups (x2, x3, x4 and up; HUD and menus, Decisions; read the thresholds from the one place the code keeps them, don't copy the numbers). Below x2 the marks stay as they are today. Each step looks hotter than the one before. The effects are your proposal for the playtest: for example a coloured glow in the marks, sparks off the tyres, a flame trail at the top step. Keep them in the combo heat's colours (yellows, oranges, white-hot), drawn in code or by a script-made texture (no PixelLab), hard pixel edges, no semi-transparent pixels inside a sprite, never Redgull red. A mark keeps the look of the step it was laid at, so the trail shows how hot the drift was. Keep the look's settings in the drift marks' scene, as T-117 does, so the board can retune them. The drift prototype has no combo and keeps the plain marks.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a screenshot of the trail at each of the four steps, and a short GIF of a drift whose trail heats up as the combo climbs.

## Acceptance criteria

- [ ] Tests show the marks take the step of the combo's multiplier when they are laid (plain below x2, then steps 1, 2 and 3), using the combo heat's own thresholds, and keep it afterwards (QA: pass / fail)
- [ ] The drift prototype's marks are unchanged, and the drift marks' existing tests pass (QA: pass / fail)
- [ ] Screenshots of the four steps and a GIF of a trail heating up are in `art-archive/T-249/screenshots/`; no Redgull red (QA: pass / fail)
- [ ] `game/README.md`, "Drift marks", and Visual style describe each step's look; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: build a combo while drifting and watch the trail heat up.
Board review files: the screenshots and GIF in `art-archive/T-249/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
