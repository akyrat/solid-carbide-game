---
id: T-184
title: Elevation: how the platform's sides meet the car (drop-off edge from below, landing on top or beside, the ramp's sides)
status: blocked
from: project-lead
to: driving-drift
lead: Goal-G-003
epic: driving
milestone: mvp
goal: G-003
user_facing_text: no
changes_visuals: no
depends_on: [T-182, T-183]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/level-design.md, game/README.md, game/scripts/driving/car.gd, game/scripts/driving/car_height.gd, game/scripts/level/ground_height.gd]
files_expected_to_change: [game/scripts/driving/car_height.gd, game/scripts/driving/car.gd, game/scripts/level/ground_height.gd, game/tests/unit/test_elevation_edges.gd, docs/drifting.md, game/README.md]
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

The docs (Drifting, Decisions, 'Elevation'; Level design, Decisions, 'Raised areas and ramps') say the car drives up the ramp and jumps off the drop-off edges, but not what happens when the car on the ground drives into a drop-off edge from below, or drives off the ramp's sides. These are open questions; settle them as proposals for the board's playtest, building on the existing collisions (docs/drifting.md, 'Collisions (task T-033)'; `game/README.md`, 'Car collisions').

Proposals to build (record them in docs/drifting.md, Content, the elevation section, each marked as a proposal for the board's playtest):
1. **A drop-off edge from the ground below** acts as a wall for a car lower than the platform's top: it bounces off it like any wall (the same 'Wall bounce' share and the hit signal) unless the car is high enough to clear it.
2. **Landing:** when a jump ends over the platform's top the car lands on the top; when it ends off it, on the ground. The car never ends a physics step inside the platform (lower than the top while inside the outline): a car in the air that would enter the platform's outline below its top meets its side as a wall.
3. **The ramp's sides** (not its climbing end and not its top): proposed the same as a drop-off edge, a step of the ramp's height there: from on the ramp, driving off a side drops the car to the ground (it falls with gravity); from the ground beside the ramp, the side is a wall as high as the ramp at that point.

GUT tests in `game/tests/unit/test_elevation_edges.gd` for each case.

## Acceptance criteria

- [ ] docs/drifting.md records the proposals for a drop-off edge met from the ground below, landing over or beside the platform, and the ramp's sides, each marked as a proposal for the board's playtest. (QA: pass / fail)
- [ ] GUT test: a car on the ground driving into a drop-off edge from below behaves as recorded (it bounces like off a wall and stays on the ground). (QA: pass / fail)
- [ ] GUT test: a jump ending over the platform's top lands the car on the top (height = platform height, vertical speed 0); a jump ending off it lands on the ground. (QA: pass / fail)
- [ ] GUT test: over a range of jumps toward the platform, no physics step ends with the car inside the platform's outline below its top. (QA: pass / fail)
- [ ] GUT test: driving off the ramp's sides behaves as recorded (from the ramp: falls to the ground; from the ground beside it: meets it as a wall). (QA: pass / fail)
- [ ] Every existing driving test passes unchanged, and the full GUT suite passes headless. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
