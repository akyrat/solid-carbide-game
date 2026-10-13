---
id: T-123
title: Camera options: smoothing and the dynamic camera (zoom follows speed)
status: in-progress
from: project-lead
to: driving-drift
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/hud-and-menus.md, game/README.md, game/scripts/ui/game_settings.gd, game/scripts/ui/pause_screen.gd, game/scripts/run/run.gd, game/scripts/driving/drift_prototype.gd]
files_expected_to_change: [game/scripts/ui/game_settings.gd, the run's and the drift prototype's camera code (or a new camera script), their tests, game/README.md, docs/drifting.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board wants to try two camera options (Drifting, Decisions, 2026-10-13), each switched on and off by a checkbox on the pause screen (T-124 adds the checkboxes; this task builds what they switch). Both are off by default, so the camera stays as it is now (exactly on the car, no smoothing) unless the player turns them on.

1. **Camera smoothing:** when on, the camera follows the car with a short smooth lag instead of sitting exactly on it. Propose the amount (for example Godot's position smoothing with a speed you pick) and keep it in one tunable place.
2. **Dynamic camera:** when on, the zoom follows the car's speed between a **min** and a **max** zoom: at very low speed the camera is zoomed in to the min; at 100% of the car's top forward speed it is zoomed out to the max; linear in between (a curve is fine if you say why). The zoom moves there smoothly with a short delay, never jumping (for example easing toward the target over about half a second to a second; propose the value). While it is on, it replaces the zoom slider's fixed zoom.
3. **The min and max are the board's to tune** in playtests: store them, with both checkbox states, in the saved settings (`game_settings.gd`, `user://settings.cfg`, next to the zoom), with proposed defaults within the slider's range (6 to 20; larger means more zoomed out), and give T-124 what it needs to set them: functions to set the min and the max from the current slider zoom, and to read them back. Also write the saved min and max to a small readable file or print them, so the Project Lead can copy the board's values into the game's defaults later.
4. Works in the run (including runs started from the main menu) and in the drift prototype; the pause screen's zoom slider keeps working when the dynamic camera is off.
5. Expose a clear API for T-124 (the checkbox states, set min, set max, read min and max) and describe it in game/README.md.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Do not merge: T-124 builds the pause screen controls on top of this task's branch, and the board playtests both together from T-124's folder.

## Acceptance criteria

- [ ] GUT tests show that with both options off the camera sits exactly on the car with the slider's zoom, as before (QA: pass / fail)
- [ ] GUT tests show smoothing on makes the camera lag behind a moving car and catch up when it stops (QA: pass / fail)
- [ ] GUT tests show the dynamic camera's target zoom is the min at standstill and the max at top forward speed, in between at half speed, and that the actual zoom eases toward the target rather than jumping (QA: pass / fail)
- [ ] GUT tests show both checkbox states, the min and the max are saved and loaded with the settings, and setting the min or max from the current zoom works (QA: pass / fail)
- [ ] docs/drifting.md (Content) and game/README.md describe both options, the defaults and the API (QA: pass / fail)
- [ ] The drift prototype, run and settings tests, the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest both options from T-124's folder, tune the dynamic camera's min and max with T-124's buttons, and judge the feel.

## Result notes

Driving & Drift Agent, 2026-10-13. Branch `task/T-123-camera-options`, folder `C:\solid-carbide-worktrees\T-123`. Not merged (T-124 builds on this branch).

**What was built**

- `game/scripts/driving/camera_follow.gd` (new, no nodes): both options, their maths and the API for T-124. The drift prototype and the run each own one, `camera_follow`; after every car physics step they call `step()` and put its position and size on their Camera2D. A new run, a view switch (V) and outside `sync_view()` calls snap it. With both options off, `step()` puts the camera exactly on the drawn car with the slider's zoom, as before (Godot's own `position_smoothing_enabled` stays off; the smoothing is done per physics step in this script, so it is deterministic, testable, and works with physics interpolation).
- `game/scripts/ui/game_settings.gd`: `smoothing`, `dynamic`, `dynamic_min`, `dynamic_max` in `user://settings.cfg` (section `camera`, next to `zoom`), with load/save functions and `dynamic_zoom_report()`. Saving the min or max prints the min, max and the file's full path to Godot's output.
- `game/scripts/run/run.gd`, `game/scripts/driving/drift_prototype.gd`: use `camera_follow` (`sync_view(snap_camera := true)`, `_apply_zoom()` uses the camera's current size). `game/scripts/game/game_flow.gd`: a run started from the main menu reads the options right after the zoom (`run.load_camera_options()`). The drift prototype reads them at start.

**Proposed numbers (all in one place)**

- Camera smoothing: `CameraFollow.SMOOTHING_RATE` = 8 per second (each step closes 1 - e^(-8 dt) of the gap). Lag at the game's top speed (33 units/s): about 4 units, under a third of the default half-height 14.4; catches up within about half a second after the car stops.
- Dynamic camera easing: `CameraFollow.ZOOM_EASE_RATE` = 3 per second (63% of a change in 0.33 s, 95% in 1 s). No jumps: at most about 0.35 of zoom per physics step for the full min-to-max change.
- Min and max: `GameSettings.DEFAULT_DYNAMIC_ZOOM_MIN` = 11.0 (standstill), `DEFAULT_DYNAMIC_ZOOM_MAX` = 17.0 (top speed), around the default 14.4, inside 6 to 20.
- Target zoom: linear from min to max over the car's speed in any direction divided by its top forward speed (capped at 1), so half speed gives the halfway zoom. I used the speed in any direction rather than only the forward component, so a fast slide (where the forward part drops) or a fast reverse does not zoom in; the board can ask for forward-only.

**Choices to flag**

- While the dynamic camera is on, moving the zoom slider shows that zoom at once (a preview, so the board sees the value it is about to set as min or max with T-124's buttons); the camera eases back to the speed's zoom once the car moves. Turning the dynamic camera off goes straight back to the slider's zoom; turning it on eases from the current zoom.
- Min greater than max is allowed (it would zoom in with speed); nothing forces min under max.
- A run scene opened on its own (F6 on run.tscn) starts with both options off, like it starts with zoom 14.4; runs from the main menu and the drift prototype read the saved options.

**API for T-124** (on `target.camera_follow`, where `target` is the pause screen's scene; each setter saves and applies at once, also while paused): `set_smoothing(on)`, `is_smoothing()`, `set_dynamic(on)`, `is_dynamic()`, `set_dynamic_min_from_current() -> float`, `set_dynamic_max_from_current() -> float` (take the slider's current zoom, `target.zoom`), `get_dynamic_min()`, `get_dynamic_max()`, signal `changed`. Described in `game/README.md`, "Camera options".

**Reading the board's values later:** the Godot output line `Dynamic camera zoom: min X, max Y (saved in ...)` on every save, or the file `%APPDATA%\Godotpp_userdata\Solid Carbide\settings.cfg`, keys `dynamic_min` and `dynamic_max`.

**Tests:** `game/tests/unit/test_camera_options.gd` (20 tests): both off = exactly on the car with the slider zoom (model, drift prototype, run, run from the main menu); smoothing lags behind a moving car (about speed / 8) and catches up when it stops (model, prototype, run, and off again snaps back); dynamic target is min at standstill, max at top speed, halfway at half speed, eases without jumps step by step and settles (model, prototype, run); turning it off goes back to the slider zoom; the slider still zooms with it off; all four settings saved and loaded (also by a new scene and a run from the main menu), saving keeps the other settings, bad values fall back or clamp, set min/max from the current zoom, and the readable report and file. Full GUT suite: 428 passing, 0 failing, TESTS PASSED. Python tool tests: `game/tools` 141 OK, `tools` 121 OK. Godot's line-ending-only `.import` changes were reverted, not committed; `project.godot` was not changed.

**Documents affected:** `docs/drifting.md` (Content, Godot drift prototype, "Camera options (task T-123)"), `game/README.md` ("Camera options" with the API, plus pointers in "Pause screen" and "The run"). Both updated.
