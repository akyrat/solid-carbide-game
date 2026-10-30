---
id: T-411
title: The car's height uses its whole footprint, not its centre
status: open
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

- [ ] Criteria to be written by the Project Lead from the assessment, before the ticket leaves planning. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → Planning

Audit epic. A Driving & Drift agent is assessing the root cause read-only; criteria follow from its findings.

### 2026-10-30, Planning → Open

Back to open: the session that started it was stopped. It overlaps T-405's altitude audit, so I'll fold it in there or start it after build E.

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
