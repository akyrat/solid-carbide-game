---
id: T-379
title: Minions twice as big, hitbox included
status: open
from: project-lead
to: enemy-behavior
lead: Greenbull
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/enemies.md, game/docs/enemies/]
files_to_read_first: [tasks/README.md, docs/enemies.md, game/data/enemies.json, game/scripts/enemies/minion.gd]
files_expected_to_change: [game/data/enemies.json, game/scripts/enemies/, game/scenes/, game/tests/unit/, game/docs/enemies/, docs/enemies.md, art-archive/]
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

The board's decision (Enemies, Decisions, "Minions twice as big", 2026-10-29; an MVP nice-to-have, **start only after the last MVP round**). Draw the minions twice as big as today and grow the size they hit and get hit with to match (their contact with the car, weapon hits, the pickup and coin drop spots if they depend on it, and their navigation radius so they still fit through gaps). Hard pixel edges (a whole-number scale). Numbers in `game/data/enemies.json`. The kaiju stays as it is. Check the minions still path to the car on the elevation map (rooftops and ramps) and don't get stuck more than before.

The board's review: play a run and see the bigger minions.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Minions are drawn at twice today's size with hard pixel edges, from a number in game/data/enemies.json (test and screenshot). (QA: pass / fail)
- [ ] Their collision with the car and the weapons' hits grow to match the new size (tests). (QA: pass / fail)
- [ ] Minions still reach the car on the elevation map, rooftops and ramps included (test). (QA: pass / fail)
- [ ] Enemies, Content and the game docs give the new size. (QA: pass / fail)
- [ ] A screenshot of a run with the bigger minions next to the car is in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
