---
id: T-195
title: Elevation sample map: the car's height across three layers, and a scripted drive from the street to 6 and off
status: open
from: project-lead
to: driving-drift
lead: Goal-G-004
epic: driving
milestone: mvp
goal: G-004
user_facing_text: no
changes_visuals: no
depends_on: [T-194, T-196]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/level-design.md, game/README.md, game/scripts/driving/car_height.gd, game/scripts/driving/car.gd, game/scripts/level/ground_height.gd, game/data/level/elevation_sample_map.json, game/tests/unit/test_car_height.gd, game/tests/unit/test_elevation_edges.gd, game/tools/check_challenge.sh]
files_expected_to_change: [game/tests/unit/test_car_height_layers.gd, game/tools/drive_elevation_sample.gd, game/tools/drive_elevation_sample.sh, game/tools/drive_elevation_sample.ps1, game/tests/unit/test_drive_elevation_sample.gd, game/scripts/driving/car_height.gd, docs/drifting.md, game/README.md]
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

Drifting, Decisions, 'Elevation', and Level design, Decisions, 'Elevation sample map' (board, 2026-10-19). The car's height (car_height.gd, T-183/T-184) was approved on the test scene's single platform. Check, and fix only where needed, that it works on the sample map's three layers (game/data/level/elevation_sample_map.json, D2) in the sample map scene (D4).

Headless GUT tests with the real car code (car.gd and car_height.gd, not a copy) on the sample map's ground, picking the areas and ramps from the file by their heights (not by hard-coded coordinates, so a layout change doesn't break them):
- driving up a 0-to-3 ramp and up a 3-to-6 ramp, the height follows the ramp;
- leaving the top of a 3-to-6 ramp at cruise speed, the car takes off with the ramp's slope (vertical speed = ramp_vertical_speed x RAMP_TAKEOFF_FACTOR);
- driving off a height-6 edge, the car lands on the height-3 area or on the street, whichever is under it (one test for each, if the layout has both; otherwise say which is missing in the result notes);
- on a height-3 rooftop, driving into the side of a height-6 area is a wall the car bounces off.
A test in the sample map scene (D4) checks the MVP map's tall buildings and boulders still block the car at every height it can reach (street, 3, 6 and in the air).

A scripted reachability drive, run headless like the challenge check (game/tools/check_challenge.sh): `game/tools/drive_elevation_sample.sh` (and .ps1) drives the car in the sample map scene with scripted inputs from the street up a 0-to-3 ramp, up a 3-to-6 ramp, then off a height-6 edge, and prints a log: each layer reached, the maximum height and the airtime of the jump. A GUT test runs the same drive and passes when all three layers are reached and the car lands. Paste its log in the result notes.

Don't change car_height.gd's constants (GRAVITY, RAMP_TAKEOFF_MIN_SPEED, RAMP_TAKEOFF_FACTOR, STEP_CLIMB_MAX) or its behaviour on the test scene. If a fix is needed for ramps whose foot is not at street level, keep it general and explain it in the result notes and in docs/drifting.md. Picture: a plot of height over time for the scripted drive (art-archive/<task id>/screenshots/).

The board's review: How the car climbs, jumps and lands across the three layers, played in the goal's final playtest.

## Acceptance criteria

- [ ] game/tests/unit/test_car_height_layers.gd uses the real car code on the sample map's ground and passes, covering: the height follows a 0-to-3 ramp and a 3-to-6 ramp; leaving a 3-to-6 ramp's top at cruise speed takes off with the ramp's slope; driving off a height-6 edge lands on the height-3 area or the street under it; on a height-3 rooftop, the side of a height-6 area is a wall the car bounces off. (QA: pass / fail)
- [ ] A test in the sample map scene shows the MVP map's tall buildings and boulders block the car at street level, on height 3, on height 6 and in the air, and it passes. (QA: pass / fail)
- [ ] `git diff master -- game/scripts/driving/car_height.gd` shows GRAVITY, RAMP_TAKEOFF_MIN_SPEED, RAMP_TAKEOFF_FACTOR and STEP_CLIMB_MAX unchanged, and test_car_height.gd and test_elevation_edges.gd pass unchanged. (QA: pass / fail)
- [ ] `game/tools/drive_elevation_sample.sh` runs headless and prints the layers reached (0, 3, 6), the maximum height and the airtime; the GUT test of the same drive passes; the log is pasted in the result notes. (QA: pass / fail)
- [ ] A plot of height over time for the scripted drive is in art-archive/<task id>/screenshots/ and listed in the result notes. (QA: pass / fail)
- [ ] docs/drifting.md and game/README.md describe the three-layer tests and the scripted drive, and how to run it. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
