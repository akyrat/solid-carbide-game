---
id: T-269
title: The car spins half as fast in the air
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
files_to_read_first: [tasks/README.md, docs/drifting.md, game/README.md, game/scripts/driving/car_tuning.gd, tasks/T-219-aerial-tricks-180-and-360.md]
files_expected_to_change: [game/scripts/driving/, game/tests/, docs/drifting.md, game/README.md]
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

The board's decision (Drifting, Decisions, "Slower air turn, upgradable", 2026-10-22): halve the car's turn rate in the air: `air_turn_multiplier` from 2.5 to **1.25** (about 240 degrees a second). Keep it the base value, with a clear way for a garage bonus to raise it (a multiplier or added amount the run sets at its start, like the other garage upgrades do), so T-270 can add the upgrade without touching the driving code again. Note in the result notes whether an air 360 is still reachable off the tallest rooftop at 1.25 (today's longest airtime is about 1 second) and at what multiplier it becomes reachable, so the upgrade's levels can be chosen with that in mind. Update the drift prototype's tuning slider default and Drifting, Content ("Faster turning in the air").

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing new to picture beyond the existing tests; one short GIF of a jump spin at 1.25 if it's quick.

## Acceptance criteria

- [ ] `air_turn_multiplier` is 1.25 and a test shows the air turn rate is half of before; the ground rate is unchanged (QA: pass / fail)
- [ ] A test shows a garage bonus set at the run's start raises the air turn rate (the hook T-270 uses) (QA: pass / fail)
- [ ] The result notes say whether an air 360 is reachable at 1.25 and from which multiplier; Drifting, Content and `game/README.md` give the new number; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: jump off a rooftop and spin.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
