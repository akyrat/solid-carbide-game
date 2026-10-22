---
id: T-258
title: The car's shadow shows on raised ground while the car is in the air
status: in-progress
from: project-lead
to: driving-drift
lead: Coursework
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/level-design.md, game/README.md, game/scripts/driving/car_shadow.gd, game/scripts/driving/elevation_test.gd, game/scripts/level/elevation_layer.gd, game/scripts/run/run.gd, tasks/T-185-elevation-test-scene-the-car-s.md, tasks/T-192-elevation-round-shadow-no-bigger-option.md]
files_expected_to_change: [game/scripts/driving/, game/scripts/level/elevation_layer.gd, game/scripts/run/, game/tests/, game/README.md, art-archive/T-258/screenshots/]
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

A bug the board found in a playtest (2026-10-22): while the car is in the air over raised ground (a rooftop or a ramp), its round shadow (T-192) is not shown at all. Over the street it shows. The shadow must always show on the ground right under the car, at that ground's height, whether that is the street, a height 3 or a height 6 rooftop or a ramp, including when the car flies from one to another or off an edge. Find the cause (for example the shadow's depth putting it under the raised area it lies on, or its height not following the ground under it) and fix it, in the run, the level creator's runs (same code) and the elevation test scene. Nothing else about the car or its drawing changes.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the shadow under the airborne car over the street, a height 3 rooftop, a height 6 rooftop and a ramp, and a short GIF of a jump from a 6 down to a 3 with the shadow following.

## Acceptance criteria

- [ ] Tests show the shadow is visible and drawn above the raised area it lies on (depth order) and at that ground's height, while the car is airborne over the street, a height 3, a height 6 and a ramp (QA: pass / fail)
- [ ] The existing elevation, depth order and see-through tests pass unchanged (QA: pass / fail)
- [ ] Screenshots and the GIF are in `art-archive/T-258/screenshots/`; `game/README.md` notes the fix; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: jump between rooftops and watch the shadow.
Board review files: the screenshots and GIF in `art-archive/T-258/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Open → In progress

Started at the board's report: the airborne car's shadow must show on rooftops and ramps too.

## Result notes

**Cause.** The shadow's depth (`shadow.z_index`) was `z_for(units, rot, ground_h) - 1`, computed on its own from the ground's height. A car in the air that is drawn over a rooftop or ramp (flying in from behind it, or off its edge) is over that area, but its shadow, on lower ground behind the area, was drawn under the area and lost behind it. A sweep of the old code found such spots, for example (-88, -64) with ramp-nw-0-3 and (-52, -88) with ramp-nw-3-6, at lifts 3 and 8.

**Fix.** `elevation_layer.gd`: `z_for` takes `include_areas` (default true, so every existing caller is unchanged) and the new `shadow_z_for(units, rot, height, ground_h)` returns the lower of the car's depth minus 1 and the ground's depth without areas minus 1: the shadow is under the car, under buildings and boulders that cover it, and under a rooftop or ramp only while the car itself is. Used by `run.gd` (`_sync_view_elevation`, so the level creator's runs too) and `elevation_sample_map.gd` (`update_depth`).

**Elevation test scene (board's decision).** `elevation_test.gd` `update_depth` now sets the shadow just under the car (`z_for(units, car.height, 1) - 1`): under an area only while the car is, the same result as the run's rule. The one existing assertion that encoded the bug, `test_elevation_drawing.gd` (renamed `test_the_car_above_the_platform_behind_it_is_over_it_and_so_is_its_shadow`), was changed to expect the shadow over the platform and under the car. Every other existing test is unchanged.

**Tests.** New `game/tests/unit/run/test_run_shadow_on_raised_ground.gd` (6 tests): shadow visible, at the ground's height, over the area it lies on and under the car, with the car airborne over the street, a height 3, a height 6 and a ramp; over every area across its whole top; and a regression test (fails on the old code, passes now) that the shadow is never under an area the car is drawn over. Existing tests pass unchanged. Full GUT suite and both Python tool test sets were run at the end.

**Screenshots** in `art-archive/T-258/screenshots/`: `shadow_air_street.png`, `shadow_air_roof3.png`, `shadow_air_roof6.png`, `shadow_air_ramp.png` (car 3 units up, shadow on the ground under it) and `shadow_jump_6_to_3.gif` (a jump from the height 6 rooftop down to the 3, the shadow following). Fixtures: `tests/fixtures/run_shadow_air_*.tscn`, `run_shadow_jump_6_to_3.tscn`. Documents: `game/README.md` (the T-192 section).

No actions were refused.
