---
id: T-270
title: The air turn upgrade in the garage
status: in-progress
from: project-lead
to: game-data
lead: Coursework
epic: garage
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: []
documents_affected: [docs/garage-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, docs/drifting.md, game/data/garage.json, game/README.md, tasks/T-224-magnet-garage-upgrade.md, tasks/T-269-halve-air-turn.md]
files_expected_to_change: [game/data/garage.json, game/scripts/, game/tests/, docs/garage-design.md, game/README.md, art-archive/T-270/screenshots/]
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

The board's decision (Garage design, Decisions, "Air turn upgrade", 2026-10-22): a fifth garage upgrade that raises how fast the car spins in the air, from T-269's base of 1.25 times the ground rate. Add it the way T-224 added the pickup magnet: its levels and prices in `game/data/garage.json` (your proposal; the Project Lead suggests 10 levels back up to today's 2.5 at the top, about +0.125 a level, with the magnet's price curve, and keeping in mind from which multiplier an air 360 becomes reachable, from T-269's notes), its row in the garage with T-268's name and description word for word, saved like the other upgrades, and applied at the start of every run through T-269's hook. Write the numbers and their reasons in Garage design, Decisions.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. The Project Lead makes your folder on T-269's branch. End with a screenshot of the garage with the new row.

## Acceptance criteria

- [ ] `garage.json` has the air turn upgrade's levels and prices; tests show buying a level saves it and the next run's air turn rate is the base times the level's value (QA: pass / fail)
- [ ] The garage shows the row with T-268's name and description word for word (screenshot) (QA: pass / fail)
- [ ] Garage design gives the numbers and reasons; the screenshot is in `art-archive/T-270/screenshots/`; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: buy a few levels and spin in the air.
Board review files: the screenshot in `art-archive/T-270/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-23, Blocked → In progress

Started: the air turn upgrade (Spin Doctor) in the garage, on top of T-269's hook and T-268's text.

## Result notes

Written by the agent when it finishes.


Game Data Agent, 2026-10-23. Built the fifth upgrade `air_turn` ("Spin Doctor", T-268's name and description word for word) in `game/data/garage.json`, `GarageData.UPGRADES`, the garage screen's names and descriptions, and `GameFlow.start_run()`, which calls the new `CarTuning.apply_air_turn_upgrade(progress)` (the bought value minus the 1.25 base, passed to T-269's `apply_air_turn_bonus()`). Saving and loading come from the shared upgrade list. The drift prototype never gets it.

Proposed levels (10), value = total multiplier of the ground turn rate, price in coins (+0.125 a level, 2.5 at the top; prices as the acceleration and magnet upgrades):

| Level | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Multiplier | 1.25 | 1.375 | 1.5 | 1.625 | 1.75 | 1.875 | 2.0 | 2.125 | 2.25 | 2.375 | 2.5 |
| Price | - | 40 | 50 | 60 | 80 | 100 | 120 | 155 | 190 | 240 | 300 |

The air 360 off the tallest rooftop becomes reachable at level 6 (2.0; the threshold is about 1.9, and level 5's 1.875 is just short). The air 180 is reachable from level 0. Reasons are in Garage design, Decisions, "Air turn upgrade".

Tests: GUT 1376/1376 pass (new `tests/unit/game/test_air_turn_upgrade.gd`: data steps and base, every level sets the next run's air rate, a bought level is saved and reaches the next run, ground rate unchanged, prototype unaffected; garage data and garage screen tests extended); tools unittest 451 OK; game/tools unittest 395 OK (1 skipped). Screenshot (looked at: five rows fit, Spin Doctor at level 6, price 155, text matches): `art-archive/T-270/screenshots/garage_air_turn.png`. Documents updated: docs/garage-design.md, game/README.md. Nothing refused. Note: `run_tests.sh` needs GODOT_BIN in the environment in this worktree, which has no `.env`; I passed it from the main checkout's `.env` without copying it.
