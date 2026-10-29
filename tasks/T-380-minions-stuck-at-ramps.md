---
id: T-380
title: Bug: minions get stuck on walls at the bottom end of ramps
status: open
from: project-lead
to: enemy-behavior
lead: Greenbull
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/enemies.md, game/docs/enemies/]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/level-design.md, game/docs/level/elevation-sample-map.md, game/scripts/enemies/]
files_expected_to_change: [game/scripts/enemies/, game/scripts/level/, game/data/, game/tests/unit/, game/docs/enemies/, docs/enemies.md]
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

The board's decision (Enemies, Decisions, "Minions don't get stuck on ramps", 2026-10-29; an MVP nice-to-have, **start only after the last MVP round**; a bug). The board: enemies get stuck on walls when they try to come to the car and go round a corner, mostly "on like the beginning of the ramp ... the bottom end of the ramp". Reproduce it on the elevation map (a scripted run with the car on a rooftop or past a ramp and minions chasing it), find why (for example the navigation or the ramp's wall at its tall end, a corner the path cuts, or a minion's radius against the ramp's side), fix it so they find their way round, and keep the fix general (any level from the level creator). Coordinate with the minions-twice-as-big ticket if it is in the same build: test with the bigger radius too.

The board's review: play a run on the elevation map and watch minions chase you round ramps.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test reproduces a minion stuck at the bottom end of a ramp before the fix (named in the result notes) and passes after it. (QA: pass / fail)
- [ ] Over a scripted chase on the elevation map, no minion stays stuck against a wall for more than 2 seconds (test). (QA: pass / fail)
- [ ] Enemies, Content and the game docs describe the cause and the fix. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the fix has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
