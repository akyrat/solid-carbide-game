---
id: T-580
title: Investigate: the car points one way but moves another at some angles
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
files_to_read_first: [tasks/README.md, docs/drifting.md, game/docs/driving/, game/scripts/driving/car.gd, game/scripts/driving/car_tuning.gd, game/scripts/driving/car_sprite.gd]
files_expected_to_change: [game/tests/, game/tools/, art-archive/T-580/, docs/drifting.md]
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

An investigation, not a fix: change no gameplay code. The board's report, word for word: "today at certain angles the car is pointing towards a direction, but it's not actually moving towards that direction. And I think it has something to do with like how the acceleration when going in a different direction than that of the existing coasting speed is added on top of that. It feels like sometimes I'm going, for example, diagonally, and the car is just sitting at like the wrong angle than it should have. Can you confirm if this actually could exist from the code, and then if you can through screenshots?"

(1) From the code, explain how the car's heading, its velocity and the drawn sprite direction relate: how throttle adds to existing velocity in another direction, how grip pulls velocity toward the heading (outside a drift), and how the heading is turned into one of the sprite's 32 directions (and the isometric projection). Name every place where the drawn direction and the actual direction of travel can differ, and by how much: for example a slow grip that leaves sideways velocity after a turn, acceleration added to a coasting velocity, the snapping to 32 sprite directions, the isometric screen angle versus the world angle, a drift's intended slip. Say which of these match the board's description (diagonals especially) and which are intended (drifting).
(2) Measure it: a test or a scripted drive that logs heading, velocity direction and the sprite's drawn direction over time for a few cases (coasting along one diagonal then throttling toward another; turning onto a diagonal; straight along each of the 8 main directions), with the angle between where the car points and where it goes, on screen and in the world.
(3) Show it: screenshots or a GIF with an overlay drawn only in the fixture (an arrow for the facing and one for the actual movement) in art-archive/T-580/screenshots/, for the cases where they differ most.
(4) Conclude in the result notes: does the issue exist, which cause(s), how big, and the options to fix each (no fix built here). Add a short Content note in docs/drifting.md with the findings.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes explain from the code every way the drawn direction and the travel direction can differ, with sizes, and say which match the board's description. (QA: pass / fail)
- [ ] A test or scripted drive measures the angle between facing and travel for the listed cases, and its numbers are in the result notes (it passes). (QA: pass / fail)
- [ ] Screenshots or a GIF with facing and travel arrows are in art-archive/T-580/screenshots/. (QA: pass / fail)
- [ ] No gameplay code is changed (diff). (QA: pass / fail)
- [ ] docs/drifting.md Content has the findings. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: Driving & Drift investigates facing versus travel.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

**Driving & Drift Agent, 2026-11-08.** Investigation only: no gameplay code changed (the diff touches only game/tests/, game/tools/, art-archive/T-580/ and docs/drifting.md).

**Verdict: the issue exists, with two independent causes that add up.**

(1) How heading, velocity and the drawing relate (from the code)
- `car_model.gd` `update_velocity`: the velocity is split along the old heading into forward and sideways parts. W only changes the forward part (snaps it to cruise 11 if below, then ramps to top 16.5); S and coasting likewise. The sideways part is only ever multiplied by `sideways_grip()`, which is 0.98 per physics step at every drift amount (base `drift_factor` and both drift grips are 0.98, the Unity values). So a slide halves every 35 steps (0.70 s) and is a tenth after 2.28 s, and W never removes it: throttle after a turn is added along the new nose on top of the old sideways motion. That is the board's "acceleration added on top of the coasting speed".
- Steering turns the body at 191.9 deg/s; the new heading applies after the step's velocity is built (Unity order), so velocity lags the body one step while steering: 3.8 degrees, negligible.
- `car_sprite.gd` `frame_for_rotation`: the frame is `round(heading / 11.25) mod 32` from the world heading. The world is drawn with the run's 2:1 projection (`run.gd` ISO_TRANSFORM, screen = (x - y, (x + y)/2)). Heading and velocity go through the same projection, so the projection adds no error itself, but it stretches gaps up to 2x near world 45/225 and squeezes them to 0.5x near 135/315.
- Places the drawn direction and the travel differ, with sizes:
  a. **The art of some frames (matches the diagonals, even driving straight).** `car_iso.json` records, per frame, where the nose should point on screen (`nose_screen_angle_deg`) and where T-102 measured the drawing pointing (`seen_nose_screen_angle_deg_approx`); confirmed by eye in `frames_vs_ideal_arrow.png`. Frames 20 to 23 (world 225 to 258.75) all draw the car pointing straight up; 21, 22, 23 should be 22, 40 and 50 degrees right of up (gaps -26, -40, -50). Frame 19 -21, frame 2 +20, frame 3 +14, frames 8/12/14/20/24 10 to 13. Over every heading in a straight line: mean 10.5, worst 55.5 degrees (world 264.25). Driving straight along the screen's up-right diagonal (world 251.6): frame 22, drawn straight up, **45 degrees off**; along the down-right diagonal (world 18.4): frame 2, **25 off**; down-left 15 off, up-left 7 off.
  b. **Slow sideways grip after any turn (matches "acceleration added on top").** See the case numbers below: 40 to 52 degrees right after a turn, fading over 1 to 2+ s. Partly intended: it is the Unity drift handling.
  c. Snap to 32 frames: at most 5.6 degrees in the world, 10.9 on screen (world 219.5). Small.
  d. Side slip out of a drift (T-278): about 14 degrees extra body turn, intended.
  e. Drift itself (W + A/D): the intended slip.

(2) Measurements: `game/tests/unit/test_t580_facing_vs_travel.gd` (4 tests, all pass; it prints every row with "T580"), with the shared driver `game/tests/helpers/facing_travel_probe.gd` (game's model, default tuning, 50 steps/s).
- Straight, W held 2 s, all 8 world and 8 screen directions: world gap 0.0 and screen gap 0.0 every time (the physics drives where it points); snap gap 0 or 5.4; drawn gap as in (a): world 0 -1.6, 45 0, 90 +9.6, 135 -10, 180 -6.6, 225 -10, 270 -13.4, 315 0; screen 45 +25, 135 -15, 225 -7, 315 -45.
- Gap at the step W takes over after a turn (world / screen / drawn sprite vs travel), time to halve, time to fall under 5 degrees:
  - coast_then_throttle (W 1.5 s along world 0, let go, A alone 46 degrees, then W): 42.3 / 24.2 / -23.7; halves 0.56 s; under 5 after 1.92 s.
  - coast_long_then_throttle (same with 1 s coast before and 0.3 s after the turn): 24.8 / 12.9 / -12.4; 0.48 s; 1.26 s.
  - drift_turn_onto_diagonal (W + A 46 degrees, then W): 40.0 / 22.4 / -21.6; 0.74 s; still over 5 after 2 s.
  - turn_onto_screen_up_right (W along screen right, W + A 65 degrees onto world 250, then W): 52.0 / 41.5 / **-82.7**; 0.84 s; over 5 after 2 s.
  - coast_turn_onto_screen_up_right (same turn while coasting): 46.9 / 37.9 / **-80.6**; 0.58 s; over 5 after 2 s.
- Grip: 0.98 per step, half-life 35 steps (0.70 s), a tenth after 2.28 s.

(3) Screenshots and GIFs, `art-archive/T-580/screenshots/` (fixture `game/tests/fixtures/t580_facing_demo.tscn`: real iso car sprite, game model; GREEN = body heading, ORANGE = travel, WHITE = where the drawing's nose points; the arrows exist only in the fixture):
- `frames_vs_ideal_arrow.png`: all 32 frames, green = where each should point, orange = where it is drawn; gaps of 15+ in red.
- `straight_screen_315_step100.png` / `.gif`: straight up-right, car drawn straight up (45 off). `straight_screen_45_step100.png` / `.gif`: straight down-right (25 off).
- `coast_turn_onto_screen_up_right_step093/118/143.png` / `.gif` and `turn_onto_screen_up_right_*`: both causes together (about 80 off at W).
- `coast_then_throttle_step088/113/138.png` / `.gif` and `drift_turn_onto_diagonal_*`: the grip alone (frame 28 is drawn right).
- Rebuild: `bash game/tools/record_t580_facing.sh` (records each case, then `game/tools/t580_pick_stills.py`); `python game/tools/t580_frame_arrows.py` for the sheet.

(4) Fix options (none built; the board chooses):
- Art, free (code only): choose each heading's frame by where its drawing actually points (the `seen` angles) instead of by its index: worst straight-line gap 55 -> 23 degrees, mean 10.5 -> 4.3; but frames 21 to 23 would go unused, so the turn looks steppier between up and up-right.
- Art, paid: redraw frames 19 to 23 (and 2, 3) through the style loop (PixelLab generations, the board's go), then re-measure with this test.
- Grip: raise the grip outside a drift (`drift_factor`, already a slider; e.g. 0.9 halves a slide in 0.13 s) so the car straightens to its nose quickly after a turn while drifts keep 0.98; or make W bleed sideways speed; both change the Unity feel, so a playtest decides. Drawing-only alternative: draw the sprite part way between heading and travel (hides the intended drift too, so not recommended).
- The two causes are independent; the art fix alone removes the straight-line diagonal problem, the grip change alone the after-turn one.

Tests run: `bash game/tools/run_tests.sh -gselect=test_t580_facing_vs_travel` 4/4 passed; `python -m unittest game/tools/test_t580_frame_arrows.py` 2 OK; `python -m unittest game/tools/test_t580_pick_stills.py` 2 OK.

Documents affected: docs/drifting.md (Content, "Facing versus travel (task T-580, investigation)").
