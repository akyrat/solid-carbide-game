---
id: T-029
title: Set the drift prototype's defaults from the board's playtest
status: needs-playtest
from: project-lead
to: driving-drift
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-012]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/drifting/unity-prototype-report.md, tasks/T-012-godot-drift-prototype.md, game/README.md]
files_expected_to_change: [game/scripts/driving/car_tuning.gd, game/scripts/driving/tuning_panel.gd, game/scripts/driving/drift_prototype.gd, game/project.godot, their tests, game/README.md]
model: sonnet
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board playtested the drift prototype (T-012) and is very happy with it. A few values change from the Unity prototype's (Drifting, Decisions, 2026-10-08). Make them the defaults:

1. **Top speed:** `top_speed_multiplier` defaults to **3.0** (Unity: 2.5). The jump to cruise speed stays at **11**. Every other driving value keeps the Unity value.
2. **Physics interpolation is on** in `game/project.godot`.
3. **The prototype starts in the isometric view.** V still switches to the flat view.
4. **The tuning panel's reset button** goes back to the game's values: these defaults, interpolation on, zoom 14.4. Each slider's tooltip may still show the Unity value for reference.

The tests from T-012 that prove the car matches the Unity prototype keep doing so: they use the Unity values explicitly instead of the defaults. Don't change the driving code's logic, only the defaults.

The camera zoom slider for players is T-015's job, not this task's.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] In `car_tuning.gd`, `top_speed_multiplier` defaults to 3.0 and `forward_speed` to 11. Every other default equals the Unity value in the Unity prototype report, section 5 (QA compares by hand) (QA: pass)
- [x] `game/project.godot` has physics interpolation on (QA: pass)
- [x] A test shows that with the default tuning, holding W from standstill reaches a top speed of 33 (3.0 × 11), within one step's rounding (QA: pass)
- [x] The T-012 tests that check the Unity behaviour (cruise, coasting, braking, rotation, drift angle) still pass, using the Unity values explicitly (QA: pass)
- [x] A screenshot taken right after the prototype starts shows the isometric view (QA: pass)
- [x] A test shows that the panel's reset button restores top speed 3.0, physics interpolation on and zoom 14.4 (QA: pass)
- [x] `game/README.md` describes the new defaults (or points to Drifting, Decisions) (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: open this folder's game/project.godot in Godot and run it. It starts in the isometric view; drive and check that top speed 3.0 and the smoother motion (physics interpolation) feel right. Tab opens the tuning panel.

Board review files: [game/project.godot, game/README.md]

## Result notes

Done on branch task/T-029-drift-defaults-after-playtest.

- `car_tuning.gd`: `top_speed_multiplier` default 3.0 (top speed 33), `forward_speed` 11, all others unchanged. New `UNITY` constant holds the Unity values (`unity_values()` and `reset_to_unity()` use it); new `default_values()` and `reset_to_defaults()`. Slider tooltip for top speed mentions both values.
- `project.godot`: physics interpolation on. `drift_prototype.gd`: starts in "iso" with interpolation on (V still toggles).
- `tuning_panel.gd`: reset button is now "Reset all to game values": defaults, interpolation on, zoom 14.4 (view left as is). Tooltips still show Unity values.
- Tests: `test_drift_model.gd` Unity tests now call `tuning.reset_to_unity()` explicitly; new test that default tuning holding W reaches 33. `test_drift_prototype.gd`: defaults test (Unity except top speed 3.0), starts-in-iso test, reset test (3.0, interpolation on, zoom 14.4), interpolation on in project settings. The camera test turns interpolation off for itself (interpolation blends the camera between steps in a test that never ticks frames).
- Screenshot of the main scene right after start (`screenshot.sh`) shows the isometric view.
- Results: GUT 56/56 pass; Python tests 115 pass.
- Documents affected: `game/README.md` updated.

### QA round 1

Checked by QA/Integration on 2026-10-09, in `C:\solid-carbide-worktrees\T-029` on branch `task/T-029-drift-defaults-after-playtest` (commit 1bdb076). All 8 criteria pass.

1. **Defaults in `car_tuning.gd`: pass.** Compared by hand with the "Value in project files (used)" column of the Unity prototype report, section 5: forward_speed 11, turn_speed 202, top_speed_multiplier **3.0** (Unity 2.5, as the task asks), time_to_top_speed 2.3, coast_decel_multiplier 0.3, steer_sensitivity 0.95, drift_factor 0.98, drift_grip_low_speed 0.98, drift_grip_high_speed 0.98, drift_speed_reference 20, drift_enter_rate 12, drift_exit_rate 3. The new `UNITY` constant holds all twelve Unity values correctly (2.5 for top speed). Physics rate stays 50 per second in `project.godot`.
2. **Physics interpolation on: pass.** `game/project.godot` has `common/physics_interpolation=true`; `drift_prototype.gd` also starts with it on.
3. **Top speed 33 test: pass.** `test_drift_model.gd::test_default_tuning_holding_w_reaches_top_speed_33` uses the untouched default tuning, checks the jump to 11 on the first step, then 33 within one step's ramp (33 / 2.3 x 0.02). It passes.
4. **T-012 Unity tests: pass.** Every test in `test_drift_model.gd` builds its car through `_new_car()` (directly or via `_car_at`/`_drift_run`), which now calls `tuning.reset_to_unity()`; the expected numbers (TOP = 27.5, cruise, coasting, braking, rotation, drift angle) are unchanged and all pass. `test_drift_prototype.gd` also checks `unity_values()` against the report's numbers.
5. **Screenshot right after start is isometric: pass.** My own screenshot of the main scene (`res://scenes/drift_prototype/drift_prototype.tscn`) after 5 frames shows the diamond isometric grid with the car centred. A second screenshot mid-drive (`drift_prototype_demo_iso.tscn`, 400 frames, interpolation on) shows the car centred on screen.
6. **Reset test: pass.** `test_drift_prototype.gd::test_reset_restores_every_game_value` sets every slider to its maximum and interpolation off, presses the reset button, and checks every value back to the game's (top speed multiplier 3.0), interpolation on (the scene's flag, the tree and the toggle) and zoom 14.4. Slider tooltips still give the Unity values.
7. **`game/README.md`: pass.** The Drift prototype section lists the new defaults (3.0 / 33, cruise 11, interpolation on, isometric start), points to Drifting, Decisions, 2026-10-08, and describes the reset button's new behaviour.
8. **Full suites: pass.** GUT: 56/56 tests, 7 scripts, `TESTS PASSED`, exit 0. Python: `game/tools` 45 tests OK, `tools` 70 tests OK (115 in total, matching the result notes).

**Other checks.**

- **Driving logic unchanged:** `git diff master...HEAD -- game/scripts/driving/car_model.gd` is empty. `car.gd` is untouched too.
- **The camera test turning interpolation off is justified.** I ran a throwaway copy of `test_camera_stays_on_the_car_and_never_rotates` with interpolation on (removed afterwards, not committed). Every placement check still passes with interpolation on: camera position equals the drawn car, sprite equals the drawn car, camera rotation 0. Only the last check (`get_screen_center_position()` equals the camera's position after `force_update_scroll()`) fails, because with interpolation on the screen centre is only updated on rendered frames, and this test steps the car directly without ticking frames. With real physics and process frames and interpolation on, the screen centre was 6 px from the drawn car, less than one step's travel, which is the interpolation itself; the camera and the car sprite are both interpolated, so the car stays centred (confirmed by the mid-drive screenshot). No hidden camera problem.
- **Minor, not a failure:** the header comment in `car_tuning.gd` dates the board's decision 2026-10-09; Drifting, Decisions dates it 2026-10-08. Cosmetic only.
