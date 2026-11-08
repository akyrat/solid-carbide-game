---
id: T-583
title: The car points where it goes: frame remap and more grip outside a drift, compared
status: done
from: project-lead
to: driving-drift
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/scripts/driving/car.gd, game/scripts/driving/car_tuning.gd, game/scripts/driving/car_sprite.gd, game/tests/unit/test_t580_facing_vs_travel.gd]
files_expected_to_change: [game/scripts/driving/, game/data/, game/tests/, game/docs/driving/, docs/drifting.md]
model: opus
qa_rounds: 1
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

Build fixes A and C of Drifting, Decisions, "The car points where it goes", each switchable in data so they can be compared. A: draw each heading with the frame whose drawing really points that way (T-580's measured drawn angles), for the car sheet and the tilt sheet (car_iso_tilt), so the worst on-screen gap drops (T-580 estimated 55 to 23 degrees). It must still work when T-584 redraws frames 19 to 23, 2 and 3: keep the measured angles in data, with a script that re-measures a sheet so T-584 can refresh them. C: more grip outside a drift (drift_factor or a separate non-drift grip), so after a turn the car straightens within a short time while drifts, the alt drift and the drift tests stay as they are; propose the number with its reason. Then measure with T-580's test every combination (none, A, C, A+C) for its cases (straight along each diagonal, coasting then throttling onto another, turning onto the up-right diagonal) and give a table in the result notes, with your recommendation. Set the data to your recommended combination. Things that depend on the grip (drift tests, tricks, the challenge checks, the tutorial's practice drives) must still pass or be updated with reasons.

The board's review: play it from C:\solid-carbide-worktrees\T-583\game\project.godot, driving along the up-right diagonal and turning onto it; the result notes say how to switch A and C on and off in data to compare.

Read T-580's result notes first (tasks/T-580-facing-vs-velocity-investigation.md on branch task/T-580-facing-vs-velocity-investigation, already merged into your branch) and its measurement test, game/tests/unit/test_t580_facing_vs_travel.gd. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A is built and switchable: with it on, each heading uses the frame that points closest to it, measured (tests). (QA: pass)
- [ ] C is built and switchable: with it on, the car straightens after a turn faster outside a drift, and drifts and alt drifts behave as before (tests). (QA: pass)
- [ ] The result notes have a table of T-580's measurements for none, A, C and A+C, and a recommendation, and the data is set to it. (QA: pass)
- [ ] The drift, trick, challenge and tutorial tests pass, updated with reasons where the grip changed them. (QA: pass)
- [ ] docs/drifting.md Content and game/docs/driving/ describe it. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] A GIF in art-archive/T-583/screenshots/ shows the up-right diagonal before and after. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: Driving & Drift builds A and C and compares them.

### 2026-11-08, In progress → In QA

Built A and C, switchable; data set to A+C. QA now.

### 2026-11-08, In QA → Needs playtest

QA passed (7/7). Play A+C: C:\solid-carbide-worktrees\T-583\game\project.godot

### 2026-11-08, Needs playtest → Done

Approved by the board; merging after the current batch. Redraw (T-584) starts now.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

**Driving & Drift Agent, 2026-11-08.** Fixes A and C built, each switchable in `game/data/car_facing.json`; measured with T-580's cases for none, A, C and A+C; data set to **A+C** (recommended). How it is built: `game/docs/driving/facing.md`; Content: docs/drifting.md, "The car points where it goes (task T-583)".

**How to switch them for the board's comparison** (edit `game/data/car_facing.json` in C:\solid-carbide-worktrees\T-583, then restart the game; it is read once at start):
- A off: `"frame_remap": false`. C off: `"straight_grip_on": false`. C's strength: `"straight_grip"` (0.9; 0.98 = the Unity grip, lower = grippier).

**A, the frame remap** (`game/scripts/driving/car_facing.gd`, used by `car_sprite.gd frame_for_rotation()` and `car_outline.gd frame_for()`): each heading is drawn with the frame whose drawing points closest on screen to where the heading points in the run's 2:1 projection, from each frame's measured angle (`seen_nose_screen_angle_deg_approx` in `game/art/car/car_iso.json`). The shadowless and tilt sheets (car_iso_tilt; its columns are the same directions) use the same frame, and so does the rail snap's outline, so a rail catches the drawing the player sees. A sheet without angles (flat placeholder) keeps frame = heading / 11.25. `index_frame_for_rotation()` keeps the old rule.
- For T-584's redraw: `python game/tools/measure_car_facing.py --frames 19-23,2,3 --write` re-measures those frames from the PNG (long axis of the car's pixels without its shadow, calibrated by every other frame's recorded angle; leave-one-out on today's sheet: mean error 3.2 degrees, worst 13) and writes them with a `seen_source`; no options = report only; `--set 22=300 --write` for an angle read by eye. Tests: `game/tools/test_measure_car_facing.py`.

**C, the straight grip** (`car_model.gd sideways_grip()`, `car_tuning.gd straight_grip_on / straight_grip` from the data): on a step with W held and no A or D (driving straight under power, not a drift), the car keeps 0.9 of its sideways speed per step instead of 0.98: a slide halves in 0.13 s instead of 0.7 s. A held drift (its start included) and a coast (no W, steering or not) are bit-for-bit as before (tests). Out of a drift with W held, the grip comes in as the drift amount falls (0.33 s). `reset_to_unity()` turns it off.
- **Proposed 0.9, reason** (`test_grip_candidates`, seconds until the world gap is under 5 degrees after W, per case coast_then_throttle / coast_long / drift_turn / turn_onto_up_right / coast_turn_onto_up_right): 0.98: 1.92 / 1.26 / >2 / >2 / >2; 0.95: 0.76 / 0.54 / 0.94 / 1.06 / 0.82; 0.93: 0.56 / 0.40 / 0.72 / 0.82 / 0.60; **0.90: 0.40 / 0.28 / 0.54 / 0.64 / 0.42**; 0.85: 0.26 / 0.18 / 0.42 / 0.48 / 0.28; 0.80: 0.20 / 0.14 / 0.36 / 0.40 / 0.20. 0.9 straightens within about half a second, even after a drift; going lower gains about 0.1 s and starts to make W feel like rails.
- **Changed during the work, with the reason:** the first version applied C whenever the car was not drifting, coasting included. The full run then failed 2 tests of `test_polarized_steering_wheel.gd`: the Polarized Steering Wheel needs a coast and steer to swing the nose 60+ degrees off the travel, and with grip while coasting it could not get there. So C now applies only with W held; the wheel's tests pass unchanged and `test_coast_is_unchanged` pins it. That first version also made `test_challenge_checker.gd test_impossibly_tight_turn_fails_and_says_where` fail (the grippier coasting car got further round the impossible U-turn); with C on W only, it passes unchanged.

**Measurements** (`game/tests/unit/test_t583_facing_fixes.gd test_compare_every_combination`, search the output for "T583"; drawn gap = where the drawing's nose points minus where the car moves, on screen, degrees):

Straight lines (W held): worst over every heading (world heading) | mean | screen up-right | down-right | down-left | up-left | up
- none: 55.5 (264.25) | 10.5 | -45 | +25 | -15 | -7 | -10
- A: 23.5 (239.00) | 4.3 | +5 | +2 | +9 | +2 | 0
- C: 55.5 (264.25) | 10.5 | -45 | +25 | -15 | -7 | -10
- A+C: 23.5 (239.00) | 4.3 | +5 | +2 | +9 | +2 | 0

Cases: world gap at W | drawn gap at W, +0.5 s, +1 s, +2 s | slide halves in s | under 5 degrees in the world after s (-1 = not within 2 s)
- coast_then_throttle: none 42.3 | -23.7 -11.1 -5.8 -1.8 | 0.56 | 1.92; A same as none; C 39.9 | -21.9 -0.8 +0.4 +0.5 | 0.16 | 0.40; A+C same as C
- coast_long_then_throttle: none 24.8 | -12.4 -5.4 -2.7 -0.7 | 0.48 | 1.26; A same; C 22.9 | -11.4 -0.1 +0.5 +0.5 | 0.14 | 0.28; A+C same as C
- drift_turn_onto_diagonal: none 40.0 | -21.6 -21.5 -16.1 -11.3 | 0.74 | -1; A 40.0 | -21.6 -9.5 -4.1 +0.7 | 0.74 | -1; C 39.9 | -21.5 -11.4 -8.5 -8.3 | 0.30 | 0.54; A+C 39.9 | -21.5 +0.6 +3.5 +3.7 | 0.30 | 0.54
- turn_onto_screen_up_right: none 52.0 | -82.7 -73.3 -57.7 -41.3 | 0.84 | -1; A 52.0 | -32.7 -66.3 -50.7 -34.3 | 0.84 | -1; C 51.8 | -82.6 -45.6 -30.5 -29.5 | 0.34 | 0.64; A+C 51.8 | -32.6 -38.6 -23.5 -22.5 | 0.34 | 0.64
- coast_turn_onto_screen_up_right: none 46.9 | -80.6 -67.7 -58.6 -49.4 | 0.58 | -1; A 46.9 | -30.6 -17.7 -8.6 +0.6 | 0.58 | -1; C 44.5 | -79.3 -46.5 -42.9 -42.7 | 0.16 | 0.42; A+C 44.5 | -29.3 +3.5 +7.1 +7.3 | 0.16 | 0.42
(The world gap at W differs a little between C and none because the step W is pressed already uses the new grip.)

**Recommendation: A+C** (data set to it). They fix independent causes: A the drawing (straight-line worst 55.5 -> 23.5, mean 10.5 -> 4.3, the screen's up-right diagonal 45 -> 5 degrees), C the slide after a turn (under 5 degrees within 0.3 to 0.65 s of W instead of 1.3 s to never within 2 s). What is left is the art: around world heading 239 the nearest drawings are 23 degrees off (between frames 20 and 24; frames 21 to 23 all point straight up), which is why turn_onto_screen_up_right still ends 22 degrees off with A+C. Only T-584's redraw closes that; re-measure with the script afterwards.

**Tests that depended on the grip or the frame:** drift, alternate drift, trick, challenge and tutorial tests pass unchanged with A+C (C does not touch a held drift or a coast). Updated with reasons: `test_drift_prototype.gd test_sprite_frame_follows_heading` (the index checks now use `index_frame_for_rotation()`, and the start frame is `frame_for_rotation(270)`: with the remap, heading 270 draws frame 25, whose drawing points closer to 270's screen angle than frame 24's). `tests/helpers/facing_travel_probe.gd` gained `set_combo()` / `car()`; T-580's own test still measures "none" and passes unchanged.

**GIF:** `art-archive/T-583/screenshots/` side by side, left no fix, right A+C: `straight_screen_315.gif` (straight up the screen's up-right diagonal; stills `_step100.png`), `coast_turn_onto_screen_up_right.gif`, `turn_onto_screen_up_right.gif`, `drift_turn_onto_diagonal.gif` (each with stills). Rebuild: `bash game/tools/record_t583_facing.sh` (`AFTER=A` or `C` for the single fixes), which records the T-580 fixture with `T583_COMBO` and assembles with `game/tools/t583_before_after.py` (tests: `game/tools/test_t583_before_after.py`).

**Tests run (agent):** `bash game/tools/run_tests.sh -gselect=test_t583_facing_fixes` 11/11 passed; `-gselect=test_t580_facing_vs_travel` 4/4; `-gselect=test_drift_prototype` 15/15; `-gselect=test_polarized_steering_wheel` 16/16; `-gselect=test_challenge_checker` 10/10. Full Godot set (asked by the Project Lead): 3069 passing, 0 failing, 1 pending, of 3070 (270 scripts, 275 s). `python -m unittest discover -s game/tools -p "test_*.py"`: 1057 tests, OK (4 skipped), including `test_measure_car_facing.py` (5) and `test_t583_before_after.py` (1). Nothing written in game/data/levels/.

Documents affected: docs/drifting.md (Content, "The car points where it goes (task T-583)"); game/docs/driving/facing.md (new).
- 2026-11-08, needs-playtest → done: Board: played A+C, LGTM
