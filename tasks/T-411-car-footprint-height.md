---
id: T-411
title: The car's height uses its whole footprint, not its centre
status: in-qa
from: project-lead
to: driving-drift
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/scripts/driving/car_height.gd, game/scripts/driving/car.gd, game/scripts/driving/drift_marks.gd]
files_expected_to_change: [game/scripts/driving/car_height.gd]
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

Bug. The car's height model treats the car as one point at its centre (car_height.gd _walk), while buildings stop its 1x1 body (car.gd) and it is drawn 3 units long. Against a rooftop or ramp side, the front half sits inside the raised area before it bounces; on a rooftop the car hangs up to about 1.5 units over the edge before it falls; tyre marks streak down the wall at roof edges (drift_marks.gd lifts each tyre by its own height). The board asked for an assessment of the root cause and the best approach first: a Driving & Drift agent is assessing it read-only, and its findings and the acceptance criteria are added here before work starts. Must fit the board's ramp decision of the same day (every ramp launches the car off its top, faster means higher) and short buildings as platforms (T-405).

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

QA round 1 (2026-10-30) ran with no concrete criteria written (the Project Lead's miss: the placeholder line below). Its mark is kept as the record; the criteria after it were written by the Project Lead from the assessment's proposed criteria (Result notes) after round 1, and QA round 2 checks them.

- [x] ~~Criteria to be written by the Project Lead from the assessment, before the ticket leaves planning.~~ (QA: pass - no concrete criteria were written; checked against the assessment's proposed criteria: test_car_footprint_height (11) and test_drift_marks_overhang (4) pass, the named existing suites are green, step cost 0.128 ms; three test sets re-run by QA all pass)
- [ ] The root cause is written in the result notes, with a named test that fails before the fix (checked by running it with the fix stashed or on the base commit).
- [ ] Headless tests on the real `car.gd` with a GroundHeight: driving into a height-3 side head-on and at 45°, no outline point of the 1 by 3 car ends more than 0.05 inside the side, with exactly one `hit_obstacle`; the same when steering into a side from standing.
- [ ] Ramps: the 0-to-3 ramp and the T-400 small ramp at 4, 11 and 16.5 u/s give no false wall, and the car follows the slope within 0.01; a free-standing ramp's top launches (`from_ramp=true`, vz > 0), higher at 16.5 than at 11, and its long side still lets the car fall.
- [ ] Platforms: touching T-405 platforms are crossed with no wall at height 3 ± 0.01; a height-3 platform next to a height-6 one bounces at the bumper.
- [ ] Roof edges: a car at 2 u/s takes off at the edge as today (open question (a), today's choice kept); tyre marks along a roof edge never drop below the car's height minus 0.1, and the overhanging line ends.
- [ ] Existing suites stay green: `test_car_height`, `test_car_height_layers`, `test_elevation_edges`, `test_run_elevation_map` and the T-195 drive inside GUT; `CarHeight.step` averages under 0.5 ms on the largest saved map.
- [ ] `docs/drifting.md` records the change and open questions (a) to (d) for the board, and the three test sets pass.

The board's review: in the build, drive into rooftop and ramp sides head-on, at an angle and while turning, cross joined platforms, drift along a roof edge and roll off one slowly.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → Planning

Audit epic. A Driving & Drift agent is assessing the root cause read-only; criteria follow from its findings.

### 2026-10-30, Planning → Open

Back to open: the session that started it was stopped. It overlaps T-405's altitude audit, so I'll fold it in there or start it after build E.

### 2026-10-30, Open → In progress

Build G (street) started: the driving-drift agent is on it in C:\solid-carbide-worktrees\T-411.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

### 2026-10-30, assessment (Driving & Drift, read-only, before work)

**Root cause.** The car has three sizes and only the smallest touches height. Drawn: 1x3 (`car_flat.json`), nose 1.5 ahead of the centre. Collision body: 1x1 (`car.gd:136-141`, board 2026-10-07), meets only layer-1 bodies (skyscrapers, boulders, map edge) through `move_and_collide` (`car.gd:182`). Height: one point. Raised areas (rooftops, ramps, T-405 platforms) have no body; their sides come only from `car_height.gd _walk` (`:138-168`), which walks the centre's path (step test `:152`). So the drawn front 1.5 units pass over a side before the centre stops, and turning is never checked (spinning beside a side sweeps the nose in). Falling uses the same point (`_walk:160-163`, `_step_air:183`): up to 1.5 units hang over a roof edge driving straight off. Ramps with nothing at the top: `step()` handles `walk.drop` (`:104-106`) before the ramp takeoff (`:108-115`), so the car rolls off flat. Tyre marks: `drift_marks.gd point_px` (`:198-206`) lifts each rear tyre (0.9 back, ±0.375) by its own ground height, so a tyre over the edge streaks down the wall. No doc decides the footprint (`drifting.md:114` covers depth order only).

**Approaches.** A: the drawn outline (about 8 points, old to new position and heading) for sides, the centre for falling and landing, plus a push-out after the step; medium (80-120 lines in `car_height.gd`); risks: compare each point with its own ground on ramps or slopes become false walls (T-400's steep ramp), marginal jumps onto platforms may bounce, cost per step (add a bounding-box check). B: fall on a 2-of-4-tyres rule; medium-large; landing, shadow, depth order, enemies and the challenge check would all disagree with the centre. C: a 1x3 collision body; large, reverses the 2026-10-07 decision, snags while drifting.

**Recommended: A**, plus in the same ticket the ramp launch fix (leaving through a ramp's top end launches with `ramp_vertical_speed × RAMP_TAKEOFF_FACTOR` before the drop branch; faster already means higher) and a tyre-mark fix (a tyre whose ground is more than `STEP_CLIMB_MAX` below the car lays nothing and ends its line, like T-206's no marks in the air). B is the follow-up if the board dislikes the hang after playing A.

**Board decisions needed** (drifting.md, Decisions, Elevation): (a) roof-edge hang: tip off when the middle passes the edge (today), when the front wheels leave, or as soon as the nose leaves; (b) the drawn body bounces off a rooftop's or ramp's side as soon as the bumper touches; (c) does a crawling car (under 4 u/s) launch off a ramp's top too, or is there a minimum speed; (d) optional: keep the nose entering skyscrapers by 1 unit (the 1x1 body, 2026-10-07)?

**Proposed criteria** (headless tests on the real `car.gd` with a GroundHeight): no outline point more than 0.05 inside a height-3 side, head-on and at 45°, one `hit_obstacle`; same when steering into a side from standing; roof edge at 2 u/s takes off per (a); 0-to-3 and T-400 ramps at 4, 11, 16.5 u/s give no false wall and follow the slope within 0.01; a free-standing ramp's top launches (`from_ramp=true`, vz>0), higher at 16.5 than 11, the long side still falls; touching T-405 platforms cross with no wall and height 3 ± 0.01; height 3 next to 6 bounces at the bumper; tyre marks along a roof edge never drop below the car's height minus 0.1 and the overhanging line ends; existing suites (`test_car_height`, `test_car_height_layers`, `test_elevation_edges`, `test_run_elevation_map`, the T-195 drive) stay green; `CarHeight.step` averages under 0.5 ms on the largest saved map.
- 2026-10-30, planning → open: Reset to open by Greenbull: the board stopped the Preemptive-bug-bash session (2026-10-30). Its root-cause assessment stays in the notes.

### 2026-10-30, work done (Driving & Drift)

**Root cause.** `car_height.gd _walk` treated the car as one point, its centre, but the car is drawn 1 x 3 (nose and tail 1.5 from the centre). Raised areas (rooftops, ramps, T-405 platforms) have no physics body: their sides exist only in `_walk`, which tested the centre's path and never the heading, so the drawn front 1.5 units entered a side before the centre stopped, and turning beside a side swept the nose or tail in. Tyre marks: `drift_marks.gd point_px` lifts each rear tyre by its own ground, so a tyre over a roof edge was drawn at street height (a streak down the wall).

**Test that fails before the fix:** `game/tests/unit/test_car_footprint_height.gd`. On the old code (checked before the fix): head-on the drawn car sat 1.477 inside the side (step 18 on), 45° 0.29+, steering from standing 0.18+, air spin 0.16+, height 3 next to 6 0.45+; 6 of 11 tests failed. All 11 pass after.

**Fix (approach A of the assessment):**
- `car_height.gd`: `OUTLINE`, 10 points of the drawn 1 x 3 outline; `step(prev, pos, velocity, dt, rot_prev, rot_new)` and `_walk` walk every point with the centre, the heading turning evenly, in pieces where no point moves more than 0.05. A point meets a side by the centre's rule against its own ground, compared with the car's body there (its height, along the ramp's slope when the centre is on a ramp, so the ramp under the car is never a wall). A wall also returns `rotation` (the heading before the piece that hit). Without headings (NAN) it is centre-only as before, so bare-model callers are unchanged.
- `car.gd`: passes the headings; on a wall also puts the heading back (a turn into a side stops).
- `ground_height.gd`: `areas_near`, `height_among`, `area_among` (outline points test only the areas near the move; none near, the outline is skipped). Cost: 0.128 ms per step average on the elevation sample map (criterion < 0.5).
- `drift_marks.gd`: `lay(..., car_height)` (bind passes the car's height); a rear tyre more than `STEP_CLIMB_MAX` below the car lays nothing, its mark ends, a new one starts back on the ground.
- Ramp launch off a free-standing ramp's top: already built by T-400 (`step`'s drop branch); new test confirms `from_ramp`, vz > 0, higher at 16.5 than 11.
- Kept as today (board's open questions (a)-(d), written in drifting.md, Content, "The car's footprint (task T-411)"): falling and landing go by the centre (roof-edge hang up to 1.5 stays); under 4 u/s no ramp launch; 1x1 physics body for skyscrapers and boulders.

**Behaviour changes to note for the playtest:** the car now stops with its centre up to 1.58 from a raised side (nose at the side); a side near a ramp's foot is a curb only where it is under 0.1 under every point of the car (a car 0.15 in from the foot's corner now bounces off the side with its flank). Marginal jumps whose nose meets a platform's side below its top bounce back (by design of the rule).

**Tests updated** (they encoded the centre-only stop): `test_elevation_edges.gd` (stop point, ramp-side wall height at the nose, curb test moved to x = 20.1 plus a new flank-wall test), `test_elevation_see_through.gd` and `test_elevation_sample_see_through.gd` (the centre's closest gap at a hit is now under the outline's reach 1.63, not 0.5; the depth-order checks are unchanged and pass). New: `test_car_footprint_height.gd` (11), `test_drift_marks_overhang.gd` (4).

**Test sets:** `bash game/tools/run_tests.sh`: 2039 passing, 0 failing (1262200 asserts), TESTS PASSED. `python -m unittest discover -s game/tools`: OK. `python -m unittest discover -s tools`: 579 tests OK. `test_car_height`, `test_car_height_layers`, `test_elevation_edges`, `test_run_elevation_map`, `test_drive_elevation_sample` (the T-195 drive inside GUT) all green. Note: the CLI `game/tools/drive_elevation_sample.sh` stops at `prepare` with `scene.car` null (`drive_elevation_sample.gd:89`), before any driving, so it is unrelated to this change (the same drive passes inside GUT); worth a separate small ticket.

**Screenshots** (`art-archive/T-411/screenshots/`): `compare_before_after.png` (before vs after, the car pressed against the platform's south, north and west sides and the ramp's side in the elevation test scene; the south one shows the nose inside the wall before and the bumper at it after), plus `before_*.png` and `after_*.png`. Fixtures: `game/tests/fixtures/elevation_test_footprint_{south,north,west,ramp_side}.tscn`.

**Documents affected:** `docs/drifting.md` (Content, "The car's footprint (task T-411)", with the open questions); `game/docs/level/elevation-test-scene.md` ("The car's footprint (T-411)", and the T-191 depth-rule note).

**Files changed:** `game/scripts/driving/car_height.gd`, `car.gd`, `drift_marks.gd`, `game/scripts/level/ground_height.gd`, `elevation_platform_drawing.gd` (comment only), the tests and fixtures above.
- 2026-10-30, in-progress → in-qa: Done: the car's whole drawn 1x3 outline meets raised sides (turning too); tyres over a roof edge lay no marks. Root cause and failing-before test in the result notes. All three test sets green. Open board questions (a)-(d) in drifting.md.
