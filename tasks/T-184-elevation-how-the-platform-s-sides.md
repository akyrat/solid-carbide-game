---
id: T-184
title: Elevation: how the platform's sides meet the car (drop-off edge from below, landing on top or beside, the ramp's sides)
status: done
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

The docs (Drifting, Decisions, 'Elevation'; Level design, Decisions, 'Raised areas and ramps') say the car drives up the ramp and jumps off the drop-off edges, but not what happens when the car on the ground drives into a drop-off edge from below, or drives off the ramp's sides. These are open questions; settle them as proposals for the board's playtest, building on the existing collisions (docs/drifting.md, 'Collisions (task T-033)'; `game/README.md`, 'Car collisions').

Proposals to build (record them in docs/drifting.md, Content, the elevation section, each marked as a proposal for the board's playtest):
1. **A drop-off edge from the ground below** acts as a wall for a car lower than the platform's top: it bounces off it like any wall (the same 'Wall bounce' share and the hit signal) unless the car is high enough to clear it.
2. **Landing:** when a jump ends over the platform's top the car lands on the top; when it ends off it, on the ground. The car never ends a physics step inside the platform (lower than the top while inside the outline): a car in the air that would enter the platform's outline below its top meets its side as a wall.
3. **The ramp's sides** (not its climbing end and not its top): proposed the same as a drop-off edge, a step of the ramp's height there: from on the ramp, driving off a side drops the car to the ground (it falls with gravity); from the ground beside the ramp, the side is a wall as high as the ramp at that point.

GUT tests in `game/tests/unit/test_elevation_edges.gd` for each case.

## Acceptance criteria

- [ ] docs/drifting.md records the proposals for a drop-off edge met from the ground below, landing over or beside the platform, and the ramp's sides, each marked as a proposal for the board's playtest. (QA: pass)
- [ ] GUT test: a car on the ground driving into a drop-off edge from below behaves as recorded (it bounces like off a wall and stays on the ground). (QA: pass)
- [ ] GUT test: a jump ending over the platform's top lands the car on the top (height = platform height, vertical speed 0); a jump ending off it lands on the ground. (QA: pass)
- [ ] GUT test: over a range of jumps toward the platform, no physics step ends with the car inside the platform's outline below its top. (QA: pass)
- [ ] GUT test: driving off the ramp's sides behaves as recorded (from the ramp: falls to the ground; from the ground beside it: meets it as a wall). (QA: pass)
- [ ] Every existing driving test passes unchanged, and the full GUT suite passes headless. (QA: pass: 996/996, 0 failing)

QA round 1 (2026-10-19): all criteria pass. Tests are in test_elevation_edges.gd (14); docs/drifting.md lines 92-97 mark each as a proposal.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-19, Blocked → In progress

Goal runner (G-003): started, in C:\solid-carbide-worktrees\T-184.

### 2026-10-19, In progress → In QA

Goal runner (G-003): the agent is done; QA is checking it.

### 2026-10-19, In QA → Done

Goal runner (G-003): QA passed; merged into playtest/G-003.

## Result notes

Driving & Drift Agent, 2026-10-19.

**What was built (all proposals for the board's playtest):**
- `car_height.gd`: `step()` now walks each move in 0.05-unit pieces with the car's height along it and returns what the ground's sides did. A step up of the ground larger than `STEP_CLIMB_MAX` (0.1 units, new proposal: curbs that small are driven over) to more than that above the car is a **wall**: the walk stops at the last piece outside it. On the ground, a step down larger than that is a **drop**: the car takes off at its height before the step and falls. So: a drop-off edge from below is a wall; a car in the air below the top meets the side as a wall and keeps falling beside it; a car above the top clears it; driving off a ramp's side falls with gravity; a ramp's side from the ground is a wall as high as the ramp there. Landing is unchanged (on the top over the platform, on the street beside it).
- `car.gd`: on a wall, moves the car to the stop point, bounces with the same `wall_bounce` maths as physics walls (shared `_reflect`), and emits `hit_obstacle(ground, area index, normal, impact)`, once per side until the car is 0.25 units away (as for walls).
- `ground_height.gd`: `area_index_at`, `area_rect`, `side_normal`. `edge_between` is unchanged (the car no longer uses it).
- No visuals change (nothing draws the height yet), so no screenshots.

**Tests:** `game/tests/unit/test_elevation_edges.gd`, 14 tests: drop-off edge from below (bounce share, stays on the ground, one hit while pressed, re-arm), clearing it from above, meeting it in the air below the top, landing on the top (ramp jump and a direct jump) and on the ground (off the west edge, beside the platform), a sweep of 280 jumps (5 approaches × 7 heights × 4 vertical speeds × 2 steerings, ~42,000 steps) checking no step ends with the car below the ground under it or inside the platform below its top, the ramp's sides from the ramp (falls, no snap) and from the ground (wall at the ramp's height), the curb near the ramp's foot, and climbing/going down the ramp. Full GUT suite headless: 996/996 passed (`test_car_height.gd`, including `test_flat_driving_unchanged_by_height`, unchanged and passing). The one orphan reported is in `test_player_progress.gd`, not touched here.

**Documents updated:** `docs/drifting.md` (Content, new "Elevation: the platform's sides (task T-184)", each point marked as a proposal), `game/README.md` ("The car's height (T-183)" updated, new "The platform's sides (T-184)").

**Open for the board's playtest:** the curb height 0.1; a fall off a ramp's side starts with vertical speed 0 (it doesn't keep the ramp's climb); the hit signal's collider for a side is the `GroundHeight` object (the combo ignores the collider today).

Refusals: none. PixelLab: none used.
- 2026-10-19, in-qa → done: QA passed every criterion (goal G-003).
