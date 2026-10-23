---
id: T-270
title: The air turn upgrade in the garage
status: blocked
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

## Result notes

Written by the agent when it finishes.
