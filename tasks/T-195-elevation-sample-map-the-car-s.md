---
id: T-195
title: Elevation sample map: the car's height across three layers, and a scripted drive from the street to 6 and off
status: in-progress
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

### 2026-10-20, Blocked → In progress

Goal runner (G-004): started, in C:\solid-carbide-worktrees\T-195.

## Result notes

Driving & Drift Agent, 2026-10-20.

**No fix was needed.** `car_height.gd` is unchanged (no diff against master; GRAVITY, RAMP_TAKEOFF_MIN_SPEED, RAMP_TAKEOFF_FACTOR and STEP_CLIMB_MAX untouched). The car's height already works on the three layers: the walk, the ramp takeoff and the landing all read the ground's height under the car, so a ramp whose foot is on a height-3 rooftop needs no special case. `test_car_height.gd` and `test_elevation_edges.gd` are unchanged and pass.

**What was built**
- `game/tests/unit/test_car_height_layers.gd` (8 tests, real `car.gd` and `car_height.gd` on `data/level/elevation_sample_map.json`'s ground; ramps and areas picked from the file by their heights, never by coordinates):
  - up a 0-to-3 ramp and up a 3-to-6 ramp the height is the ground's on every ramp step, climbing to the top;
  - off the 3-to-6 ramp's top at cruise speed (11 to 12 units/s: W snaps to 11 and climbs a little before the top): vertical speed = `ramp_vertical_speed(r, v) x RAMP_TAKEOFF_FACTOR`, height along the slope's line, above 6, `took_off(true, ...)`;
  - off a height-6 edge onto the height-3 area under it, and off another height-6 edge onto the street (the layout has both: a side found by searching the height-6 areas for flat 6 inside and flat 3, or 0, outside, no ramp); a fall (`took_off(false, 0)`), one landing, no wall;
  - on a height-3 rooftop, driving into the side of a height-6 area: one hit with the `GroundHeight` as collider, the area's index and the side's normal, bounce = impact x wall_bounce, the car stays at height 3 and never enters the area;
  - in the sample map scene (T-196): all 8 tall buildings and 88 boulders (every boulder with a clear 6-unit straight approach) block the car on the street, on height 3, on height 6 and in the air (at 8 units, rising): 96 of 96 at each height. The layout keeps rooftops away from buildings and boulders (T-194), so the car can't actually stand on 3 or 6 next to one; for those two heights the test raises a temporary rooftop under the approach and the obstacle. The obstacles are the map's own bodies (`map.walls`, `map.boulder_bodies`).
- `game/tools/drive_elevation_sample.gd` with `drive_elevation_sample.sh` and `.ps1`: the scripted reachability drive (route from the file by heights; W held, A/D steering toward waypoints; W released once off the edge), with a log, `--csv` and `--plot`. Exit 0 = PASS.
- `game/tests/unit/test_drive_elevation_sample.gd` (4 tests): the route, the same drive passing (0, 3, 6 in order, then back on the street, every waypoint, the edge jump a fall from 6 landing on the street in about 1 s, no wall before the edge), the log's lines, the CSV and the plot.
- Screenshot fixtures `game/tests/fixtures/elevation_sample_drive_demo.gd` and `elevation_sample_drive_{height_3,ramp_jump,off_edge,plot,plot_light}.tscn`.

**The drive's log** (from the GUT run of the same drive, and the plot fixture's output, which print the same lines):

```
Elevation sample drive (T-195): from the street (-81.0, -50.0) up ramp-nw-0-3 onto roof-nw-3, up ramp-nw-3-6 onto roof-nw-6, then off its edge
Layers reached, in order: 0 at 0.00 s, 3 at 1.82 s, 6 at 5.30 s, 0 at 7.32 s
Waypoints: the 0-to-3 ramp's foot 0.22 s; on the height-3 rooftop 1.20 s; the run-up to the 3-to-6 ramp 3.18 s; the 3-to-6 ramp's foot 3.74 s; the 3-to-6 ramp's top 4.54 s; the height-6 edge 6.26 s; past the edge 7.08 s
Jump 1, off a ramp's top at 1.10 s: from height 3.08, takeoff vertical speed 4.13 units/s, max height 3.75, airtime 0.70 s, landed on height 3.0 at 1.80 s (impact -4.28 units/s)
Jump 2, off a ramp's top at 4.52 s: from height 6.04, takeoff vertical speed 4.62 units/s, max height 6.89, airtime 0.76 s, landed on height 6.0 at 5.28 s (impact -4.50 units/s)
Jump 3, off the height-6 edge at 6.30 s: from height 6.00, takeoff vertical speed 0.00 units/s, max height 6.00, airtime 1.00 s, landed on the street (0) at 7.30 s (impact -12.00 units/s)
Maximum height: 6.89 units, at 4.92 s
Airtime of the jump off the height-6 edge: 1.00 s
Wall and obstacle hits: 0
Ended at (6.4, -82.3), height 0.00, after 7.82 s
PASS: the street, height 3 and height 6 reached, and the car landed off the height-6 edge
```

Worth knowing for the playtest: just past the edge the car lands on the road between two boulders 4 units apart (copy-12). In an earlier version of the drive, with no steering after the edge, it clipped one in the air. That was correct: boulders block at every height. The drive now keeps steering straight.

**The command line: not run by me.** `bash game/tools/drive_elevation_sample.sh ...` was refused (it is not on the pre-approved command list). I skipped it, and QA should run it. It runs the same `drive()` as the GUT test and the plot fixture, both of which ran and passed.

**Screenshots** (`art-archive/T-195/screenshots/`, taken with `bash game/tools/screenshot.sh` on the fixtures):
- `height-over-time.png` and `height-over-time-light.png`: the plot of height over time for the scripted drive (dark and light backgrounds). The blue line is the car's height and the brown line the ground under it. Shaded areas are time in the air. The axis has lines at 0, 3 and 6 and a tick every second.
- `drive-height-3.png`: the car on the height-3 rooftop at 2.5 s, heading for the 3-to-6 ramp.
- `drive-ramp-3-6-jump.png`: the hop off the 3-to-6 ramp's top at 4.72 s, over the height-6 rooftop.
- `drive-off-height-6-edge.png`: falling off the height-6 edge at 6.7 s (height 5.1), with its shadow on the street.

**Tests run:** `bash game/tools/run_tests.sh` passed 1083 of 1083 tests. `python -m unittest discover -s game/tools -p "test_*.py"` and `python -m unittest discover -s tools -p "test_*.py"` each ran 331 tests, OK.

**Documents affected:** `docs/drifting.md` (Content, "Elevation: the three layers of the sample map (task T-195)") and `game/README.md` ("The car's height on the three layers (T-195)").

**Refusals:** `bash game/tools/drive_elevation_sample.sh --plot=... --csv=...` needed an approval I couldn't get. I skipped it because it wasn't essential (see above). PixelLab: none used.
