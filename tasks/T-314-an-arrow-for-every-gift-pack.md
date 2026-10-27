---
id: T-314
title: An arrow for every gift pack on the map
status: open
from: project-lead
to: game-loop
lead: Greenbull
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/README.md, game/scripts/run/gift_arrows.gd, game/scripts/run/gift_drops.gd, game/scripts/run/gift_package.gd]
files_expected_to_change: [game/scripts/run/gift_arrows.gd, game/scripts/run/gift_drops.gd, game/tests/unit/run/, game/README.md, docs/game-loop-architecture.md]
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

The board's decision (Game loop architecture, Decisions, "An arrow for every gift pack on the map", 2026-10-28): every gift pack on the map gets its own arrow, the same arrow that already points at a landed package off screen (`scripts/run/gift_arrows.gd`, `game/README.md`, "The gift pack drop", "Off-screen arrow"), so several arrows show at once when several packages are out.

Today the arrow is drawn only for a package that has **landed** and whose centre is **off screen**. Extend it to every package on the map: a package still falling (or carried by the helicopter, once it is over the map) gets its arrow too, as soon as it is dropped. Keep the arrow's look, its track along the screen's edges and its clearance from the HUD exactly as they are; several arrows that would overlap are slid apart along the track so each stays readable (your proposal for the spacing). Whether an arrow also shows while its package is on screen is the agents' proposal for the playtest (the board said "the same one that appears today at the edge of the screen", so the proposal is: edge arrows for packages off screen, none on screen); write the proposal in the result notes and in Game loop architecture, Content, "The gift pack drop".

The board's review: play a run, level up two or three times without picking the packages up, and drive away from them: one arrow per package.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] With two or more packages on the map at once (falling or landed) and off screen, one arrow per package is drawn at the screen's edge, each pointing at its own package (a test with two and with three packages). (QA: pass / fail)
- [ ] A package that is still falling, off screen, has its arrow from the moment it is dropped (test). (QA: pass / fail)
- [ ] Arrows that would overlap are moved apart along the track, and none overlaps the HUD (test with two packages in the same direction). (QA: pass / fail)
- [ ] Picking a package up removes its arrow only; the others stay (test). (QA: pass / fail)
- [ ] Game loop architecture, Content, "The gift pack drop" and game/README.md describe the new arrows, including the on-screen proposal. (QA: pass / fail)
- [ ] Screenshots (or a GIF for anything that moves) of the change in a run are in `art-archive/T-314/screenshots/`, as `tasks/README.md`, "Screenshots", asks. One shows two arrows at once. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
