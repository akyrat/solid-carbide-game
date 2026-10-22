---
id: T-275
title: The car goes faster the higher the hype level
status: open
from: project-lead
to: driving-drift
lead:
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, game/README.md, game/scripts/driving/car_tuning.gd, tasks/T-131-combo-heat-levels.md, tasks/T-249-hype-drift-trail.md]
files_expected_to_change: [game/scripts/driving/, game/scripts/run/, game/data/combo.json, game/tests/, docs/drifting.md, game/README.md, art-archive/T-275/screenshots/]
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

The board's decision (Drifting, Decisions, "Hype speed boost", 2026-10-22): the higher the hype level, the faster the car. On the combo heat steps (x2, x3, x4 and up; read the thresholds from `ComboHeat`, as T-249 does, don't copy them), the car's top speed rises by a step each (and its acceleration too if that feels right; your call, say so), and falls back as the combo drops, easing so the change isn't a jolt. Propose the amounts as tuning numbers (for example +5%, +10%, +15% at the three steps) with their reasons in the result notes and Drifting, Content. Drift handling stays the same otherwise; it applies in the run only (the drift prototype has no combo); the garage's speed upgrades still multiply as before. Mind that faster cars reach farther off ramps: say how far a jump off the tallest rooftop goes at the top step.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a short GIF of the car getting faster as the combo heats up.

## Acceptance criteria

- [ ] Tests show the top speed at each heat step is the data's amount above the base, uses ComboHeat's thresholds, and eases back when the combo drops; the drift prototype is unchanged (QA: pass / fail)
- [ ] The numbers and reasons are in the data and Drifting, Content, with the top-step jump distance noted (QA: pass / fail)
- [ ] The GIF is in `art-archive/T-275/screenshots/`; `game/README.md` describes it; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: build a combo and feel the car speed up.
Board review files: the GIF in `art-archive/T-275/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
