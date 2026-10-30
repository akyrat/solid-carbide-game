---
id: T-403
title: The car flashes red when it takes damage
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
documents_affected: [docs/game-loop-architecture.md, game/docs/game-loop/the-run.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/docs/game-loop/the-run.md, game/data/run.json, game/scripts/data/run_data.gd]
files_expected_to_change: [game/scripts/, game/data/run.json, game/tests/unit/, game/docs/game-loop/the-run.md, docs/game-loop-architecture.md, art-archive/]
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

The board's decision (Game loop architecture, Decisions, "A red flash when the car takes damage", 2026-10-30): "add a red effect on the player when they take damage." When the car loses a heart (a minion, a meteor, the kaiju), it flashes red. It must read clearly together with the existing 1-second invulnerability blink (for example red on the first visible phases, then the plain blink), and must not fire on hits ignored during the invulnerability. Write the flash as one small reusable helper (a shader or modulate tween) that T-404 reuses for the enemies, so both look the same; its length and colour go in `game/data/run.json` as proposals. Code only, no new art. Don't touch the goal G-007's areas (tutorial slides, pause screen).

The board's review: play a run, take hits from minions and a meteor, and watch the car.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] When the car loses a heart it flashes red, with the length and colour read from `game/data/run.json` (tests). (QA: pass / fail)
- [ ] A hit ignored during the invulnerability does not flash (test), and the blink still works as before (existing tests). (QA: pass / fail)
- [ ] The flash is a reusable helper, named in the result notes for T-404. (QA: pass / fail)
- [ ] Game loop architecture (Content) and game/docs/game-loop/the-run.md describe it and its numbers. (QA: pass / fail)
- [ ] A GIF of the car taking a hit is in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
