---
id: T-183
title: The car's real height: gravity, takeoff from the ramp's top and drop-off edges, and landing
status: blocked
from: project-lead
to: driving-drift
lead: Goal-G-003
epic: driving
milestone: mvp
goal: G-003
user_facing_text: no
changes_visuals: no
depends_on: [T-182]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/level-design.md, game/README.md, game/scripts/driving/car.gd, game/scripts/driving/car_model.gd, game/scripts/level/ground_height.gd, game/tests/unit/test_drift_model.gd]
files_expected_to_change: [game/scripts/driving/car_height.gd, game/scripts/driving/car.gd, game/tests/unit/test_car_height.gd, game/README.md]
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

docs/drifting.md, Decisions, 'Elevation' (board, 2026-10-17, go-ahead 2026-10-19): the car gets a real height above the ground, separate from where it is on the map, with gravity, a takeoff speed and a landing. This task builds the physics only; the drawing comes in a later task.

1. Add the car's height and vertical speed, separate from its flat top-down position, in a small node-free model (`game/scripts/driving/car_height.gd`) that the car (`car.gd`) steps once per physics step after its flat step, reading the ground under it from the ground-height query (`game/scripts/level/ground_height.gd`, from the ground-height task). When the car has no ground-height source (the drift prototype, the run), its height stays 0 and nothing changes.
2. On the ground (including the ramp), the car's height follows the ground under it.
3. At the ramp's top edge or a drop-off edge, with enough speed, the car leaves the ground: its takeoff vertical speed comes from its speed and the slope it was on (the ramp's slope at the ramp's top; 0 on flat platform ground going off a drop-off, so it falls).
4. In the air, gravity pulls the vertical speed down each step; the height follows it.
5. It lands when its height reaches the ground under it; its vertical speed becomes 0 and its height snaps to the ground.
6. The flat driving physics (50 steps per second, the Unity values) is not changed: the car's flat position and speed are steered exactly as before, in the air too (a proposal: the docs don't say whether the car can steer in the air; record it as a proposal).
7. Gravity and any takeoff or landing numbers live in one place (constants at the top of `car_height.gd`, or a data file) and are listed in `game/README.md`, 'Elevation test scene', as proposals for the board's playtest. How the platform's sides meet the car (driving into a drop-off edge from below, landing over the platform, the ramp's sides) is the next task's; here only the cases above are needed.

## Acceptance criteria

- [ ] The car has a height and a vertical speed separate from its flat position; with no ground-height source its height stays 0. (QA: pass / fail)
- [ ] Every existing driving test (`test_drift_model.gd`, `test_drift_prototype.gd`, `test_car_collisions.gd`, `test_tricks.gd`, `test_boost.gd`) passes unchanged. (QA: pass / fail)
- [ ] GUT test: a car driven up the ramp has, each step, a height equal to the ground height under it. (QA: pass / fail)
- [ ] GUT test: a car leaving the ramp's top, and a car leaving a drop-off edge, with enough speed, leaves the ground; the ramp takeoff's vertical speed matches the formula in the README for the car's speed and the ramp's slope. (QA: pass / fail)
- [ ] GUT test: in the air the height follows gravity (vertical speed falls by gravity x step time each step). (QA: pass / fail)
- [ ] GUT test: the car lands when its height reaches the ground under it, and its vertical speed then is 0. (QA: pass / fail)
- [ ] Gravity and every takeoff or landing number are in one place, listed in `game/README.md` as proposals for the board's playtest. (QA: pass / fail)
- [ ] The full GUT suite passes headless. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
