---
id: T-269
title: The car spins half as fast in the air
status: needs-playtest
from: project-lead
to: driving-drift
lead: Coursework
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

The board's decision (Drifting, Decisions, "Slower air turn, upgradable", 2026-10-22): halve the car's turn rate in the air: `air_turn_multiplier` from 2.5 to **1.25** (about 240 degrees a second). Keep it the base value, with a clear way for a garage bonus to raise it (a multiplier or added amount the run sets at its start, like the other garage upgrades do), so T-270 can add the upgrade without touching the driving code again. Note in the result notes whether an air 360 is still reachable off the tallest rooftop at 1.25 (today's longest airtime is about 1 second) and at what multiplier it becomes reachable, so the upgrade's levels can be chosen with that in mind. Update the drift prototype's tuning slider default and Drifting, Content ("Faster turning in the air").

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing new to picture beyond the existing tests; one short GIF of a jump spin at 1.25 if it's quick.

## Acceptance criteria

- [ ] `air_turn_multiplier` is 1.25 and a test shows the air turn rate is half of before; the ground rate is unchanged (QA: pass; multiplier 1.25, tests check the base, half of the old 2.5 rate, ground 191.9 unchanged)
- [ ] A test shows a garage bonus set at the run's start raises the air turn rate (the hook T-270 uses) (QA: pass; apply_air_turn_bonus tests on the model and the real car show the air rate rises, ground unchanged)
- [ ] The result notes say whether an air 360 is reachable at 1.25 and from which multiplier; Drifting, Content and `game/README.md` give the new number; the full GUT suite and all Python tool tests pass (QA: pass; notes say no air 360 at 1.25, reachable from about 1.9; drifting.md and game/README.md updated; GUT 1369/1369, Python 451 and 395 OK)

The board's review: jump off a rooftop and spin.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Open → In progress

Started at the board's request: the car spins half as fast in the air.

### 2026-10-23, In progress → In QA

Air turn halved (2.5 to 1.25); garage hook ready for T-270. At 1.25 only the air 180 is reachable off the tallest roof; the 360 needs about 1.9 total. Sent to QA.

### 2026-10-23, Needs playtest

QA passed all 3. Ready to play in the game build: air turn halved; air 360 off the tallest roof returns with the garage upgrade.

## Result notes

Driving & Drift Agent:

- `air_turn_multiplier` is now 1.25 (239.9 deg/s; the ground rate 191.9 is unchanged). Slider tip text updated (range 1 to 4 kept).
- The garage hook for T-270: `CarTuning.air_turn_bonus` (0 by default), set with `tuning.apply_air_turn_bonus(added)`; the air rate is `turn_rate() * (air_turn_multiplier + air_turn_bonus)`. T-270 calls it in `GameFlow.start_run()` next to `apply_acceleration_upgrade()` (game/scripts/game/game_flow.gd, line 78). The bonus is the amount ADDED to 1.25, so T-270 passes the upgrade's value minus 1.25 (or writes garage.json values as added amounts). The drift prototype never calls it.
- Air 360 off the tallest rooftop (a fall counts 49 steps, 0.98 s): NOT reachable at 1.25 (needs about 76 steps); the 180 is (38 steps). A 360 becomes reachable from a total multiplier of about 1.9 (tests: 1.85 gives only the 180, 1.95 the 360, 2.0 both ways), so a bonus of about +0.65 or more; +0.75 (total 2.0) leaves a margin. The old 2.5 had 0.2 s to spare.
- Tests (`tests/unit/test_air_tricks.gd`): base is 1.25 and half of before; ground rate unchanged; bonus raises the air rate only (model and real car); negative bonus clamped to 0; base gives only the 180 off a height-6 rooftop; the 1.85/1.95/2.0 thresholds. The existing timing tests give the test car a 1.25 bonus (total 2.5) so they keep their numbers.
- Full GUT suite: 1369 of 1369 pass. All Python tool tests (tools/ and tools/goal_agent/) pass.
- Docs: Drifting, Content ("Faster turning in the air") and game/README.md give the new number and the hook. docs/long-gdd.md is regenerated by the Project Lead at merge. No GIF made.
