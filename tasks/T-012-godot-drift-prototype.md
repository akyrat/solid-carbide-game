---
id: T-012
title: Godot drift prototype: copy the Unity car, with tuning sliders and a flat/isometric view switch
status: needs-playtest
from: project-lead
to: driving-drift
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-013, T-018]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/drifting.md, tasks/T-013-placeholder-car-sprites.md, docs/drifting/unity-prototype-report.md, game/README.md, .claude/agents/driving-drift.md, docs/extended-narrative.md, docs/visual-style.md]
files_expected_to_change: [the drift prototype scene, the car's script and settings, the tuning panel, their tests, project.godot (physics rate, input map), docs/drifting.md, game/README.md]
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The car is drawn with simple placeholder sprites (T-013 made the script and layout, T-018 redrew them at 3:1 with 80 by 80 frames, and both are done; the sheets and their layout are documented in `game/README.md`, "Placeholder car sprite sheets").

The first playable piece of Solid Carbide: the car, driving and drifting exactly like the board's Unity prototype, so the board can playtest it. The decisions are in Drifting, Decisions; how the Unity car works, with every value, is in the Unity prototype report (`docs/drifting/unity-prototype-report.md`), especially sections 4 (step by step), 5 (values) and 8 (porting to Godot). Copy it faithfully: do not improve or redesign the handling. Where the report and a decision disagree, the decision wins; where something is unclear, ask through the result notes rather than guess. The Unity project itself is not needed; if consulted, it is read-only.

**What to build: a drift prototype scene**

- **The car:** drawn with the simple placeholder sprites from T-018 (plain 3:1 rectangles, made with T-013's script; 16 directions, one sheet for the flat view and one for the isometric view). Show the frame closest to the car's heading, reading the layout from the JSON file next to each sheet, so the full pixel-art sheets (T-014) drop in later with no code change. The car's physics body stays a 1 by 1 unit square, as the report describes; the drawn car is 1 unit wide and 3 long, centred on it, so it sticks out at the front and back (Drifting, Decisions).
- **The ground:** flat and empty, like the Unity Grass stage (no off-road slowdown, no obstacles), with a simple grid or markers so movement and speed are visible.
- **Controls:** W forward, S brake and reverse, A and D steer, exactly as the report's section 2 describes for the keyboard. Tab opens and closes the tuning panel. Escape is not used here: it pauses the game, built separately in T-015. Not in this task: the jump on Space, the arrow keys, the gamepad. They stay open questions for the board.
- **Movement:** the report's section 4, step by step, at **50 physics steps per second** (Drifting, Decisions). Include the coded drift amount, the one-step lag between rotation and velocity, the instant jump to cruise, braking, the snap into reverse, and coasting. Expose a clear signal when W makes the car jump to cruise speed, for the boost effect in T-008 (do not build the effect here).
- **Tuning panel:** sliders for every setting in the report's section 8 list ("Proposed settings for the Godot prototype"), except off-road damping and the physics rate. Each slider has the plain-language label from that list, starts at the Unity value, applies live, and there is one button to reset all to the Unity values. Explain each slider in a short tooltip.
- **Camera:** like the Unity camera (report section 7): sits exactly on the car, never rotates, no smoothing, no look-ahead. A **zoom slider** from 6 to 20, starting at 14.4 (the Unity default, until the board decides in T-010). Physics interpolation off by default, matching Unity's stepped motion; give the board an on/off toggle for it in the panel, since the report notes it is a visible difference.
- **View switch (flat / isometric):** the physics always runs in a flat top-down world (Drifting, Decisions). One key and one panel toggle switch only how it is drawn: **flat top-down**, as in Unity, or **isometric**, with a standard 2:1 isometric projection of the same world. Switching never changes the car's position, speed or rotation, and can be done mid-drive. Use the pixel scale that matches T-013's sprites, and document it; the board judges the look in playtest.

**Tests (GUT):** check the movement against the numbers in the report, which `python tools/unity_drift_charts.py --summary` also prints. Use those as the reference values.

**Documentation:**
- `game/README.md`: how to open and run the drift prototype, and its keys.
- `docs/drifting.md`: a `### Godot drift prototype` subsection in Content: where it is, how to run it, the view switch and the panel. Facts only; follow `docs/README.md`. Do not change Summary, Decisions or Open questions.

## Acceptance criteria

- [x] `game/project.godot` sets 50 physics ticks per second, and the input map binds W, S, A and D to the car's actions (QA: pass)
- [x] GUT tests show the speed profile matches the report: W from standstill gives 11 on the first step, top speed 27.5 is reached 69 steps after cruise, coasting from 27.5 reaches 0 in 3.33 s (27.5 / 8.25; ±1 step), S from 27.5 reaches 0 in 2.3 s (±1 step) and then snaps to -11, and W while reversing snaps to +11 (QA: pass)
- [x] GUT tests show the rotation rate is 191.9 degrees per second both at standstill and at top speed (QA: pass)
- [x] GUT tests of W + A held from top speed show the drift angle passing 45 degrees at 0.28 s (±0.04 s), and settling at a total speed of 33.9 (±0.5) and a drift angle of 75 degrees (±2), matching `tools/unity_drift_charts.py --summary` (QA: pass)
- [x] The car's default values equal the "Value in project files (used)" column of the report's section 5, checked for every slider setting (QA: pass)
- [x] Every setting in the report's section 8 list, except off-road damping and the physics rate, has a slider; a test shows changing a slider changes the movement, and the reset button restores every Unity value (QA: pass)
- [x] A test shows switching between flat and isometric view, mid-drive, leaves the car's position, velocity and rotation identical to a run without switching (QA: pass)
- [x] Screenshots (with the T-001 screenshot tool) of the prototype in flat view and in isometric view each show the ground grid and the car drawn with the matching T-013 sheet, facing its heading (QA: pass)
- [x] The camera stays centred on the car and never rotates while the car turns, shown by a test or by two screenshots at different car rotations; the zoom slider covers 6 to 20 and starts at 14.4 (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)
- [x] `game/README.md` explains how to run the prototype and its keys; `docs/drifting.md` has a `### Godot drift prototype` subsection in Content, still follows the five-section structure, and its Summary, Decisions and Open questions are unchanged (QA: pass)

**The board's playtest:** drive it in flat view and compare the feel with the Unity prototype on Grass, then switch to isometric and judge whether it feels the same (Drifting, Open questions).

## Result notes

**Driving & Drift Agent, 2026-10-08.**

**What was built.** A drift prototype scene in which the car drives and drifts like the board's Unity prototype, on a flat, empty ground with a grid. It has a tuning panel and a flat / isometric view switch. The movement is the Unity prototype report's section 4, step by step, at 50 physics steps per second, with the Unity values. No PixelLab call was made, and no walls or collisions were built.

**How to run it.** It is the project's main scene. Open `game/` in Godot 4.6.2 and press F5, or open `scenes/drift_prototype/drift_prototype.tscn` and press F6. Without the editor, from the repo root: `"$GODOT_BIN" --path game`.

**Keys:** W forward (jumps to cruise, then climbs to top speed); S brakes, then reverses; A / D rotate left / right; **Tab** opens and closes the tuning panel; **V** switches between the flat and isometric views. Escape is not used. There is no jump, no arrow-key steering and no gamepad. A one-line key hint is shown at the top left.

**Pixel scale:** 16 pixels per unit in the flat world, the scale of the T-013/T-018 sheets, so the sheets are drawn at scale 1. The car is drawn 16 x 48 pixels (1 x 3 units), centred on its 16 x 16 pixel (1 x 1 unit) physics body. The camera zoom is Unity's orthographic size: Godot zoom = window height / (2 x size x 16). At 14.4 that shows 28.8 units from top to bottom, and the same formula is used in both views. The isometric view draws the flat world through screen = (x - y, (x + y) / 2), the projection the isometric sheet uses.

**Tuning panel (Tab).** It has a live readout (total, forward and sideways speed, drift angle, drift amount), a "Reset all to Unity values" button, an "Isometric view (V)" toggle and a "Physics interpolation" toggle (off by default). Below those are the sliders. Each slider shows the plain-language label from the report's section 8 and has a tooltip with the setting's name, its Unity value and a short explanation. Every slider applies live. Nothing is saved between runs.

| Slider (setting) | Default (Unity) | Range | Step |
|---|---|---|---|
| Camera zoom (orthographic size) | 14.4 units | 6 to 20 | 0.1 |
| Cruise speed | 11 units/s | 4 to 25 | 0.1 |
| Top speed multiplier | 2.5 | 1 to 4 | 0.05 |
| Time to top speed | 2.3 s | 0.5 to 5 | 0.05 |
| Coast slowdown | 0.3 | 0 to 1.5 | 0.01 |
| Turn speed | 202 deg/s | 60 to 360 | 1 |
| Steering sensitivity | 0.95 | 0.5 to 1.5 | 0.01 |
| Base sideways grip (drift factor) | 0.98 per step | 0.80 to 1.00 | 0.001 |
| Drift grip, low speed | 0.98 per step | 0.80 to 1.00 | 0.001 |
| Drift grip, high speed | 0.98 per step | 0.80 to 1.00 | 0.001 |
| Drift speed reference | 20 units/s | 5 to 40 | 0.5 |
| Drift enter rate | 12 per s | 1 to 30 | 0.5 |
| Drift exit rate | 3 per s | 1 to 30 | 0.5 |

The reset button puts every slider (zoom included) back to its Unity value and turns physics interpolation off. It does not change the view.

**Boost signal for T-008.** The car emits `cruise_jump(from_speed, w_just_pressed)` (on `car.gd`, relayed from `car_model.gd`) whenever W makes the forward speed jump up to cruise speed: from a standstill, from coasting below cruise, or from reversing.

**Test results against the report** (`python tools/unity_drift_charts.py --summary`), measured in Godot:

- W from standstill: 11.0 on the first step. Cruise to top speed (27.5) takes 69 steps, so W from rest reaches top speed at 1.40 s.
- Coasting from 27.5 reaches 0 in 167 steps = 3.34 s. Braking with S from 27.5 reaches 0 in 115 steps = 2.30 s, the next step snaps to -11, and reverse climbs to -27.5 in 69 more steps. W while reversing snaps to +11.
- Rotation rate: 191.9 deg/s (3.838 deg per step) at standstill and at top speed. A turns counter-clockwise on screen, D clockwise.
- W + A held from top speed: the drift angle passes 45 degrees at 0.28 s (60 at 0.38, 70 at 0.52). At 3 s: total speed 33.874, drift angle 74.89 degrees, forward 8.831, sideways 32.703. The summary gives 33.87, 74.9, 8.83 and 32.70. Releasing A with W held gives a drift angle of 9.0 degrees and forward speed 27.50 after 2 s, as in the summary.
- Drift amount: full after 5 steps (0.08 s), back to 0 after about 17 steps (0.33 s).
- Full GUT suite: TESTS PASSED, 7 scripts, 54 tests, 14226 asserts (17 in `test_drift_model.gd` and 14 in `test_drift_prototype.gd` are new). Python tool tests: `game/tools` 45 OK, root `tools/` 50 OK.

**Screenshots** (T-001 screenshot tool, saved in the worktree's git-ignored `screenshots/`, outside `game/`), using the fixtures that drive W and then W + A:

- `screenshots/t012_flat_150.png` (nose pointing left) and `t012_flat_400.png` (nose pointing right and slightly up): flat view, flat sheet, grid. The car is at the screen centre both times and the grid stays square to the screen.
- `screenshots/t012_iso_150.png` and `t012_iso_400.png`: isometric view, isometric sheet, projected grid, car centred.
- `screenshots/t012_flat_panel.png` and `t012_iso_panel.png`: the same drives with the panel open (readout shows about 69 degrees of drift).

Command: `bash game/tools/screenshot.sh res://tests/fixtures/drift_prototype_demo_iso.tscn screenshots/t012_iso_400.png 400` (likewise `_flat`, `_flat_panel`, `_iso_panel`).

**Files created:**

- `game/scripts/driving/`: `car_model.gd`, `car_tuning.gd`, `car.gd`, `car_sprite.gd`, `ground_grid.gd`, `tuning_panel.gd`, `drift_prototype.gd` (each with `.uid`).
- `game/scenes/drift_prototype/drift_prototype.tscn`.
- `game/tests/unit/test_drift_model.gd` and `test_drift_prototype.gd` (with `.uid`).
- `game/tests/fixtures/drift_prototype_demo.gd` (+ `.uid`) and `drift_prototype_demo_{flat,iso,flat_panel,iso_panel}.tscn`.

**Files changed:**

- `game/project.godot`: 50 physics ticks per second, physics interpolation off, the input map (`car_accelerate` W, `car_reverse` S, `car_steer_left` A, `car_steer_right` D, `toggle_tuning_panel` Tab, `toggle_view` V; physical keys), and the drift prototype as the main scene.
- `game/README.md`: new section "Drift prototype" and folder table notes.
- `docs/drifting.md`: new `### Godot drift prototype` in Content and one line in References. Summary, Decisions and Open questions are unchanged.
- `agent-notes/driving-drift.md`: working notes.
- This task file.

**Documents affected:** `docs/drifting.md` and `game/README.md`, both updated.

**Differences from the report, and why:**

1. **Rounding guard on the cruise snap.** Before W snaps to cruise speed, the code checks `forward < cruise`. The reverse snap checks `forward > -cruise` the same way. My version ignores differences under 0.000000001 units/s (`CRUISE_EPSILON` in `car_model.gd`). Without this guard, W gets stuck at cruise speed at some headings: after the speed is set to 11, it reads back as 10.999999999999998 because of rounding, so W snaps to 11 again on every step and never climbs. With the report's own formulas, W from rest stays stuck at 11 at 47 of 400 test headings. The Unity build may or may not hit this (it uses 32-bit floats). The guard changes no number in the report, and a test checks that W reaches top speed at every heading. The board should know about this; `tools/unity_drift_charts.py` still uses the exact comparison.
2. **The body is not moved by `move_and_slide`.** The car is a `CharacterBody2D` with a 1 x 1 unit collision square, but this task has no collisions. So the position is stepped by the model in 64-bit maths (Godot's `Vector2` is 32-bit), which keeps it exactly on the report's numbers. The collision response belongs with the walls and boulders task.
3. **Steering sensitivity label.** It reads "Multiplier on turn speed". I left out the report's remark "(the prototype kept both; they could share one slider)". The tooltip says that Unity kept both values.

**Choices not fixed by the task** (the board or the Project Lead may want them changed):

- **V** is the view switch key. The task asks for "one key" without naming it.
- The drift prototype is set as the project's main scene, so F5 runs it.
- The screen shows a one-line key hint, and the panel shows a live readout. Both are playtest aids, not game text (`user_facing_text: no`).
- Ground colours are a dark navy ground with purple grid lines (from the Visual style palette) and a pink marker at the start point. Grid lines are drawn every unit, with a stronger line every 5 units.

**Problems and open questions:**

- **Criterion 2, coasting time:** coasting from 27.5 to 0 takes 167 steps = 3.34 s. The exact value is 27.5 / 8.25 = 3.333 s; the report rounds it to 3.3 s. 3.34 s is within one step of 3.333 s, but two steps from a literal 3.30 s. The test checks against 3.333 s plus or minus one step. QA may want the Project Lead to confirm that reading.
- **Boost signal during drifts:** while W and A or D are held, the slide pulls the forward speed under cruise speed on most steps. That is how the Unity code works: 129 of the first 150 steps of a held drift from top speed. Each of those steps snaps back to 11, so `cruise_jump` fires too, with `w_just_pressed` false. Which jumps should play the boost effect is for T-008 or the board to decide. The signal gives both pieces of information.
- **Physics interpolation on:** the toggle works, and the tests check it, but I could only look at still screenshots. Whether the motion looks smooth with it on is for the playtest.
- On the worktree's first Godot import, the committed `.import` files were rewritten with LF line endings but their content did not change. They were not committed; `git add` cleared the false status.
- No command was blocked.

**Self-check per criterion** (QA boxes left for QA):

1. 50 ticks per second and WASD in the input map: yes (`project.godot`; tests `test_project_runs_physics_at_50_ticks`, `test_input_map_binds_wasd_and_tab`).
2. Speed profile: yes. 11 on the first step, top speed 69 steps after cruise, brake 2.30 s then -11, W while reversing gives +11. Coasting takes 3.34 s; see the note above.
3. Rotation 191.9 deg/s at standstill and at top speed: yes.
4. W + A from top speed: 45 degrees at 0.28 s, settling at 33.87 total speed and 74.9 degrees: yes.
5. Defaults equal section 5 for every slider setting: yes (`test_defaults_equal_unity_values`, and slider start values in `test_every_section_8_setting_has_a_slider_starting_at_unity_value`).
6. A slider for every section 8 setting except off-road damping and physics rate, with the report's ranges; changing one changes the movement; reset restores every value: yes (three tests).
7. Switching views mid-drive (every 17 steps over a 200-step drive) gives a position, velocity, rotation and drift amount identical to a run without switching: yes (`assert_eq`, exact equality).
8. Screenshots in both views show the grid and the car drawn with the matching sheet, facing its heading: yes (files listed above; a test also checks the sheet per view and the frame per heading).
9. The camera stays centred and never rotates: yes. This is shown by a test (three car rotations in each view, camera position equals the drawn car, rotation 0, no smoothing) and by the screenshot pairs. The zoom slider is 6 to 20 and starts at 14.4.
10. Full GUT suite and all Python tool tests pass: yes.
11. `game/README.md` explains how to run the prototype and its keys. `docs/drifting.md` has the subsection in Content and keeps its five sections, with Summary, Decisions and Open questions unchanged: yes (`git diff master -- docs/drifting.md` shows only additions in Content and References).

### Criterion clarified by the Project Lead before QA (2026-10-08)

Criterion 2 said coasting reaches 0 in "3.3 s (±1 step)". The report rounds the exact value, 27.5 / 8.25 = 3.333 s, to 3.3 s; the criterion means the exact value. It now reads "3.33 s (27.5 / 8.25; ±1 step)". The measured 3.34 s (167 steps) is within one step of it.

### QA round 1

**QA/Integration Agent, 2026-10-08.** All 11 criteria pass. Checked in `C:\solid-carbide-worktrees\T-012` on `task/T-012-godot-drift-prototype`; the agent's result notes were not relied on.

**Commands and outcomes:**

- `bash game/tools/run_tests.sh`: TESTS PASSED, 7 scripts, 54/54 tests, 14226 asserts (`test_drift_model.gd` 17/17, `test_drift_prototype.gd` 14/14).
- `python -m unittest discover -p "test_*.py"` in `game/tools` (45 OK) and in `tools` (50 OK).
- `python tools/unity_drift_charts.py --summary`: top 27.5, ramp 0.23913 and coast 0.165 per step, 191.90 deg/s, W from rest at top at 1.40 s, W + A from top at 3 s forward 8.83 / sideways 32.70 / slip 74.9 / total 33.87, slip 45/60/70 deg at 0.28/0.38/0.52 s, 9.0 deg and 27.50 two seconds after releasing A. The GUT tests assert these same numbers (most to 0.01 or tighter). Coast 27.5 / 0.165 = 166.7, so 167 steps = 3.34 s, within one step of 3.333 s; brake 27.5 / 0.23913 = 115 steps = 2.30 s. The script rewrote no chart (`git status` clean afterwards).
- `bash game/tools/screenshot.sh` with `drift_prototype_demo_{flat,iso}.tscn` at 120 and 300 frames, `drift_prototype_demo_iso_panel.tscn` at 200 and the main scene at 30, saved in the git-ignored `screenshots/qa/`.

**Per criterion:**

1. `project.godot`: `common/physics_ticks_per_second=50`, `physics_interpolation=false`; `car_accelerate`/`car_reverse`/`car_steer_left`/`car_steer_right` on physical W/S/A/D (87/83/65/68), plus Tab and V. No Escape.
2. `test_w_from_standstill_gives_cruise_on_first_step`, `test_top_speed_reached_69_steps_after_cruise`, `test_coasting_from_top_speed_reaches_zero_in_3_3_s` (167 steps, against 3.333 s ± 1 step, as clarified), `test_braking_..._then_snaps_to_reverse` (2.30 s, then -11), `test_w_while_reversing_snaps_to_cruise`.
3. `test_rotation_rate_at_standstill` and `_at_top_speed`: 191.9 deg/s to 1e-6.
4. `test_drift_angle_passes_45_degrees_at_0_28_s` (± 0.04) and `test_held_drift_settles_at_33_9_and_75_degrees` (also 33.87 / 74.9 to 0.01 / 0.05).
5. `car_tuning.gd` defaults compared by hand with section 5: 11, 202, 2.5, 2.3, 0.3, 0.95, 0.98, 0.98, 0.98, 20, 12, 3. All equal; `test_defaults_equal_unity_values` checks the same.
6. `CarTuning.SETTINGS` has the 12 section 8 settings with the section 8 labels and ranges, plus the zoom slider; off-road damping and physics rate left out. Tests: changing cruise speed and turn speed changes the movement; reset puts every slider and value back.
7. `test_view_switch_mid_drive_leaves_the_car_unchanged`: exact `assert_eq` on x, y, vx, vy, rotation and drift amount over a 200-step route, switching every 17 steps. `set_view` never touches the car.
8. My screenshots: flat view shows the square grid and the flat sheet (blue body, yellow nose, nose up at rest, turning with the drift); isometric view shows the projected grid and the isometric sheet. The frame is picked from the JSON layout (`car_sprite.gd`), checked by `test_sprite_frame_follows_heading`.
9. In all my screenshots the car is at the screen centre and the grid stays square to the screen (flat) or fixed in its 2:1 projection (iso), with the car at different headings. `test_camera_stays_on_the_car_and_never_rotates` (both views, three rotations each) and `test_zoom_slider_range_and_default` (6 to 20, starts at 14.4) pass.
10. See the commands above.
11. `game/README.md`, "Drift prototype", has how to run it (editor F5/F6, command line in Git Bash and PowerShell) and a key table. `git diff master...HEAD -- docs/drifting.md` shows only additions: the `### Godot drift prototype` subsection in Content and one References line. Still five `##` sections; Summary, Decisions and Open questions unchanged.

**`car_model.gd` against the report's section 4:** steps 1 to 7 match line by line: S ignored while W held; drifting = (W or S) and |steer| > 0.01; rotation built but applied only after the velocity (the one-step lag); forward/sideways split on the old heading; the step 5 branches; grip from the new forward speed with the three grips clamped to 0..1 (as the chart script does); velocity written back on the old heading; position += velocity * dt. Step 8's damping is left out, which is correct for Grass (damping 0). **`CRUISE_EPSILON` (1e-9):** I reproduced the problem in Python with the report's formulas in 64-bit floats: W from rest stayed stuck at 11 at 39 of the same 400 test headings without the guard, and at none with it. The guard only matters when the forward speed is within 1e-9 of cruise, where the exact maths would have it equal to cruise, so it changes none of the report's behaviour. Real drops under cruise (in a drift, or coasting) are far larger and still snap.

**Observations for the playtest:**

- `cruise_jump` fires on most steps of a held W + A/D drift (the forward speed keeps dropping under cruise, as in Unity), with `w_just_pressed` false. T-008 will need to choose which jumps play the boost.
- The isometric car is a flat parallelogram (no box height), as T-018 drew it, and its screen angle is unevenly spaced between frames: worth judging in the iso playtest.
- V as the view key, the drift prototype as the main scene and the on-screen key hint are the agent's choices, not fixed by the task.
- Physics interpolation could only be checked in tests and stills; whether motion looks smoother with it on is for the playtest.
- No command was blocked. The Godot imports left no `.import` changes in this round.
