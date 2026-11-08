---
id: T-601
title: Fix: the car locks against a wall with W held
status: in-progress
from: project-lead
to: driving-drift
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/scripts/driving/car.gd, game/scripts/driving/car_model.gd, game/docs/driving/]
files_expected_to_change: [game/scripts/driving/, game/data/, game/tests/, game/docs/driving/]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Fix Drifting, Decisions, "The car never locks against a wall". The board's report (2026-11-08): "if i manage to get the nose of the car close enough to the wall and then i hold acceleration, the car gets locked there and i can't escape whether i press A or D. i am forced to let go of the acceleration, and then i hold S for what feels like a very long time to start going backwards and escape." First reproduce it in a test (a wall, the nose near it at a few angles including straight on and shallow, W held, then W plus A or D; then S alone) and measure: does the car move, how long until it is off the wall, how long S takes to reverse. Then confirm or correct the Project Lead's reading in the decision (car_model.gd step 5: W snaps fwd to cruise unless _bouncing_towards_wall, and bounce_normal is set only when the bounce is above 0; car.gd _bounce/_end_drift_on_hit ends the drift every step in contact; reverse brakes positive fwd at t.ramp_delta, the top-speed ramp), and look at anything else that holds the car (the rotation set on the body without a collision check, _update_bounce_rearm, move_and_collide depenetration). Fix it so W with A or D turns the car off the wall within a short time (propose the number) and S against a wall reverses promptly, while normal driving, the T-435 bounce, the cruise jump in open space, the drift and the wall-hit trick rules stay as they are (their tests pass). Numbers in data with reasons where needed; say what each change does.

The board's review: play it from C:\solid-carbide-worktrees\T-601\game\project.godot: nose into a wall with W held, then steer away; then try S.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test reproduces the lock before the fix (shown failing in the result notes) and passes after. (QA: pass)
- [ ] With W held and A or D, the car leaves the wall within the proposed time at the tested angles (tests). (QA: pass)
- [ ] S against a wall reverses promptly (a test with the time). (QA: pass)
- [ ] Normal driving, wall bounces, the cruise jump, drifts and wall-hit tricks are unchanged (the existing tests pass). (QA: pass)
- [ ] docs/drifting.md Content and game/docs/driving/ explain the cause and the fix. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] A GIF in art-archive/T-601/screenshots/ shows the car steering off a wall with W held, taken with bash game/tools/screenshot.sh frames. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: reproduce the wall lock in a test, then fix it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

### Driving & Drift Agent, 2026-11-08

**Reproduced first.** A probe swept a raised platform's side (data/level/elevation_test.json) and a building wall (StaticBody2D), nose 0.02 or 0.3 units short, 0 to 85 degrees off straight-on, W held 0, 0.1 or 1.2 s, then W + A or W + D for 3 s. Locked (no movement and no turn over the last second): 213 of 432 cases, every one a platform case, every angle from 0 to 85 degrees; 0 building cases. The kept reproduction is `game/tests/unit/test_wall_lock.gd`: with the slide turned off (`"slide_on": false` in game/data/wall_contact.json, the old code path) it fails 5 tests: platform 0/20/45/70 degrees W+A "off the wall after -1 steps" (never), 0 degrees W+D never, and after W+D held at 70 degrees S took 1.80 s braking 12.97 units/s while the car's real speed was 0.00 (45 degrees W+A: 0.56 s; 70 degrees W+A: 1.52 s, both with real speed 0). `test_the_old_stop_locks` keeps that case as a test.

**Cause (corrects the Project Lead's reading).** It is not car_model.gd step 5, the bounce_normal rule or _end_drift_on_hit: the same model code runs at building walls, which never lock (Godot's move_and_collide lets the 1x1 body turn and slide). The lock is in `car_height.gd`, `_walk()` (T-411, the 3 x 1 drawn outline against raised areas' sides): it walks the step's move and turn together and stops the WHOLE step at the last piece before any outline point crosses a side, so the slide along the side and the turn are lost with the part going into it. Once touching, every step with any speed into the side (W, the bounce pull-back) or any turn (A or D swings a front corner of a 3-long car forward) stops on its first piece: no movement, no turn. Meanwhile the model kept W's speed (up to 16.5, the top speed) while standing still, so S first braked that phantom speed at the top-speed ramp (7.2 units/s per s, 2.3 s from top speed) before reversing: the "very long" S. The rotation set without a collision check, _update_bounce_rearm and move_and_collide's depenetration are fine (the building cases never lock).

**Fix.** `car_height.gd`, new `_slide_off_side()` (on the ground only; air and rail unchanged): from where the outline touched, the rest of the move slides along the side (its into part dropped) with the step's whole turn, the centre pushed straight out of the side by the smallest of 6 even pushes up to 0.15 units that clears it; failing that, the slide without the turn; failing that, the old stop. It still reports the wall with the same normal and area, so car.gd's bounce, hit_obstacle, re-arm and the drift ending on a hit are untouched. Numbers in the new `game/data/wall_contact.json` with reasons: pivot_max_push 0.15 (a full-rate turn swings the nose corner, 1.58 units out, about 0.11 units a step into the side; 0.15 is under a sixth of the car's width, never seen as a jump), pivot_push_tries 6, slide_on true (false = the old stop, for comparing). No change to car.gd, car_model.gd or car_tuning.gd.

**Proposed numbers and measurements** (test_wall_lock.gd, nose pressed 1 s with W, platform side and building wall):
- W + A or D: off the wall (nose no longer into it, 1 unit from where pinned) within the time the turn itself takes at the full turn rate (192 deg/s) + 0.15 s, and never over 1.0 s. Measured, platform: 0 deg 0.52 s (turn alone 0.47) both ways; 20 deg 0.64 (A, through the wall) / 0.38 (D, away); 45 deg 0.72 / 0.24; 70 deg 0.84 / 0.12. Building: 0.54, 0.68/0.42, 0.72/0.24, 0.84/0.12.
- S with the nose into the wall (0, 20, 45 deg): reversing and 0.5 units off within 0.5 s. Measured: platform 0.10, 0.12, 0.40 s; building 0.08, 0.14, 0.40 s. At 70 deg W does not hold the car on the wall (it drives along it at speed and off its end), so S brakes as on the open road from that speed: 97 steps from 13.73 units/s (open road 96), building 77 (76).
- W + A or D held 0.3 s, then S: S brakes only the speed the car really had (reverses within 0.5 s + the open road's braking from its real speed). Platform after the fix: 0.02 to 1.50 s, the longest from a real 11.3 units/s.

**Tests.** `bash game/tools/run_tests.sh -gselect=test_wall_lock.gd`: 13/13 pass (5 fail with slide_on false, above). Full Godot set (GUT_TIME_LIMIT=2400, 12 processes): 285 scripts, 3263 tests, 3262 passing, 0 failing, 1 pending/risky (TESTS PASSED, 230 s); that includes test_wall_bounce.gd (T-435), test_wall_hit_ends_drift.gd (T-438), test_car_height.gd, test_car_footprint_height.gd (T-411), the cruise jump, drift and trick tests, all unchanged. game/tools Python set (`python -m unittest discover -s game/tools -p "test_*.py"`): 1193 tests OK (4 skipped).

**Screenshots** (`bash game/tools/screenshot.sh res://tests/fixtures/t601_wall_lock_demo.tscn <abs path>/step_NNN.png 400`; the new fixture stops the car at the step named in the file name): `art-archive/T-601/screenshots/t601_steer_off_wall.gif` (the car pressed nose first on the elevation test platform's south side with W from step 52 to 70, then W + A from step 70: it turns off the side and drives away along it), `t601_steer_off_wall_strip.png` (the same 13 frames) and the frames `step_040.png` to `step_120.png`.

**Documents affected.** docs/drifting.md, Content, new "The car never locks against a wall (task T-601)" (cause, fix, what it does; Decisions left as written for the Project Lead, whose cause line there is now corrected in Content). game/docs/driving/collisions.md, Bounce, new "Against a raised area's side (T-601)".

**Files.** game/scripts/driving/car_height.gd, game/data/wall_contact.json (new), game/tests/unit/test_wall_lock.gd (new), game/tests/fixtures/t601_wall_lock_demo.gd and .tscn (new), docs/drifting.md, game/docs/driving/collisions.md, art-archive/T-601/screenshots/.
