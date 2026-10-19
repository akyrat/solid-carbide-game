---
id: T-187
title: Elevation test scene: an option to draw the car slightly bigger when high (off by default)
status: in-progress
from: project-lead
to: driving-drift
lead: Goal-G-003
epic: driving
milestone: mvp
goal: G-003
user_facing_text: no
changes_visuals: yes
depends_on: [T-185]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/scripts/driving/elevation_test.gd, game/scripts/driving/car_sprite.gd]
files_expected_to_change: [game/scripts/driving/car_sprite.gd, game/scripts/driving/elevation_test.gd, game/tests/unit/test_elevation_drawing.gd, docs/drifting.md, game/README.md]
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

docs/drifting.md, Decisions, 'Elevation': drawing the car slightly bigger when high is an option for the board's playtest. Add a switch, off by default, that makes the car's drawing scale up with its height in the elevation test scene. The switch is an exported property or a constant on the scene (no new on-screen text or menu); the scale per unit of height is a proposal, recorded with the switch in `game/README.md`, 'Elevation test scene', and in docs/drifting.md's elevation section. The shadow keeps its size.

The board's review: Play the elevation test scene with the switch on and off, and judge whether the car looks better drawn bigger when high.

## Acceptance criteria

- [ ] A switch, off by default, makes the car's drawing scale grow with its height; how to switch it and the proposed scale per unit of height are in `game/README.md`. (QA: pass / fail)
- [ ] GUT test: with the switch on, the drawing's scale is 1 at height 0 and larger than 1 at a known height (matching the README's formula); with it off, the scale is 1 at every height. (QA: pass / fail)
- [ ] The full GUT suite passes headless and the test scene runs headless without errors. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-19, Blocked → In progress

Goal runner (G-003): started, in C:\solid-carbide-worktrees\T-187.

## Result notes

Written by the agent when it finishes.
