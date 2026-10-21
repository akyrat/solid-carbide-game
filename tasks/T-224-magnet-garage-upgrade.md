---
id: T-224
title: The pickup magnet's radius as a garage upgrade
status: blocked
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

The board's decision (Garage design, Decisions, "Pickup magnet upgrade", 2026-10-21): the magnet's radius (T-222) is a garage upgrade, starting at 1 car length. Add it to `game/data/garage.json` beside the three existing upgrades, with T-223's text word for word, so the garage screen lists it like the others, and make the run's magnet radius come from the bought level. Propose its levels (about 10, like the others), each level's radius and price, in the data and in the result notes, as the Game Data Agent did for the first three. Saving and loading work like the other upgrades.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the garage screen with the new row.

## Acceptance criteria

- [ ] The garage screen lists the magnet upgrade with T-223's text word for word, its level and next price, and buying it raises its level and is saved (tests, screenshot) (QA: pass / fail)
- [ ] A run uses the radius of the bought level: level 0 is 1 car length, and each level's radius comes from `game/data/garage.json` (tests) (QA: pass / fail)
- [ ] The proposed levels, radii and prices are in the data and the result notes (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: buy the magnet upgrade in the garage and feel the bigger radius in a run.
Board review files: the screenshots in `art-archive/T-224/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
