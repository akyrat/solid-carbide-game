---
id: T-224
title: The pickup magnet's radius as a garage upgrade
status: done
from: project-lead
to: game-data
lead: Coursework
epic: garage
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-222, T-223]
documents_affected: [docs/garage-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, docs/game-loop-architecture.md, game/README.md, game/data/garage.json, tasks/T-222-pickup-magnet.md, tasks/T-223-text-magnet-upgrade.md]
files_expected_to_change: [game/data/garage.json, game/scripts/, game/tests/unit/, game/README.md, docs/garage-design.md, art-archive/T-224/screenshots/]
model: sonnet
qa_rounds: 1
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

The board's decision (Garage design, Decisions, "Pickup magnet upgrade", 2026-10-21): the magnet's radius (T-222) is a garage upgrade, starting at 1 car length. Add it to `game/data/garage.json` beside the three existing upgrades, with T-223's text word for word, so the garage screen lists it like the others, and make the run's magnet radius come from the bought level. Propose its levels (about 10, like the others), each level's radius and price, in the data and in the result notes, as the Game Data Agent did for the first three. Saving and loading work like the other upgrades.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the garage screen with the new row.

## Acceptance criteria

- [ ] The garage screen lists the magnet upgrade with T-223's text word for word, its level and next price, and buying it raises its level and is saved (tests, screenshot) (QA: pass; screenshot shows Brand Magnet, Level 3, Price 80, text matches the T-223 entry word for word; garage screen tests pass)
- [ ] A run uses the radius of the bought level: level 0 is 1 car length, and each level's radius comes from `game/data/garage.json` (tests) (QA: pass; test_magnet_upgrade.gd checks level 0 = 3.0 and every level against the data)
- [ ] The proposed levels, radii and prices are in the data and the result notes (QA: pass; 10 levels 3.6-9.0 and prices 40-300 in garage.json match the notes table)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass; run_tests.sh TESTS PASSED, tools unittest 439 OK, game/tools 387 OK skipped=1)

The board's review: buy the magnet upgrade in the garage and feel the bigger radius in a run.
Board review files: the screenshots in `art-archive/T-224/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Blocked → In progress

Started: Brand Magnet in the garage.

### 2026-10-21, In progress → In QA

Built: Brand Magnet in the garage, 10 levels from 3 to 9 units. Sent to QA.

### 2026-10-21, In QA → Needs playtest

QA passed all 4. Ready for the board: C:\solid-carbide-worktrees\T-224\game\project.godot; buy Brand Magnet in the garage, then play a run.

### 2026-10-21, Needs playtest → Done

The board approved Brand Magnet. Merged into master.

## Result notes

Written by the agent when it finishes.

Game Data Agent, 2026-10-21. Built the fourth upgrade `pickup_magnet` ("Brand Magnet", T-223's description word for word) in `game/data/garage.json`, `GarageData.UPGRADES`, the garage screen's names and descriptions, and `RunState.start_run()` (the bought level sets `pickup_magnet_radius_units`; level 0 is run.json's 3.0, 1 car length). Saving and loading come from the shared upgrade list.

Proposed levels (10), radius in units, price in coins (the radius is a fifth of a car length more per level; prices follow the acceleration upgrade's curve):

| Level | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Radius | 3.0 | 3.6 | 4.2 | 4.8 | 5.4 | 6.0 | 6.6 | 7.2 | 7.8 | 8.4 | 9.0 |
| Price | - | 40 | 50 | 60 | 80 | 100 | 120 | 155 | 190 | 240 | 300 |

Tests: GUT 1237/1237 pass (new `tests/unit/run/test_magnet_upgrade.gd`; garage screen and garage data tests extended); tools unittest 439 OK; game/tools unittest 387 OK (1 skipped). Screenshot: `art-archive/T-224/screenshots/garage_magnet.png` (garage_screen_demo fixture, magnet at level 3). Four rows fit the 1152x648 window. Documents updated: docs/garage-design.md, game/README.md. Nothing refused.
- 2026-10-21, needs-playtest → done: Board: T-224 LGTM
