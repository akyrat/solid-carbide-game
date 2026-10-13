---
id: T-117
title: Drift marks: the rear tyres leave marks on the ground while drifting (placeholder)
status: done
from: project-lead
to: driving-drift
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/drifting.md, game/README.md, tasks/T-112-level-up-particles-placeholder.md]
files_expected_to_change: [the car's scripts or a new drift marks scene and script, the run scene and the drift prototype scene, their tests, game/README.md]
model: opus
qa_rounds: 1
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

The board wants drift marks (Visual style, Decisions, "Drift marks", 2026-10-13): while the car drifts, its two rear tyres leave marks on the ground. This task builds the working effect with a placeholder look; T-118 draws the final mark texture and swaps it in, built on this task's branch, and the board playtests both together from T-118's folder.

1. **When:** marks are laid only while the car is drifting, using the car's own drift state (the same one that gives likes for drifting). No marks while driving straight or standing still. A new mark starts each time a drift starts, so separate drifts leave separate marks.
2. **Where:** one mark per rear tyre, following where each rear tyre actually is on the ground as the car turns and slides (work it out from the car's position, heading and size, Drifting, Decisions). Drawn on the ground: over the road and gravel, under the car, enemies, buildings and the HUD. They stay where they were laid when the camera or car moves.
3. **How long:** each mark stays fully visible for about 6 seconds after it was laid, then fades out as a whole and is removed (Visual style, Decisions, "See-through rule": the game may fade a whole object; no semi-transparent pixels inside the texture itself). Cap the number of mark segments kept at once so long runs stay fast; propose the numbers in the result notes.
4. **Placeholder look:** a plain dark line about one tyre wide, drawn by code or a tiny script-made texture, not Redgull red, nearest-neighbour filtering. Keep the texture, width, lifetime and fade time in one scene or resource, so T-118 can swap the art and retune without touching the code.
5. Works in the run (including runs started from the main menu) and in the drift prototype.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Do not merge: per the board's rule, nothing user-facing merges before the board has played it; the board plays it together with T-118.

## Acceptance criteria

- [x] GUT tests show marks are laid while the car drifts and not while it drives straight or stands still, one per rear tyre, and that a new drift starts a new mark (QA: pass)
- [x] GUT tests show a mark stays for its lifetime, then fades as a whole and is removed, and that the number of segments never exceeds the cap during a long drift (QA: pass)
- [x] A GUT test or a check on the scene shows the marks are drawn above the ground and below the car, and the placeholder uses nearest-neighbour filtering and is not Redgull red (QA: pass)
- [x] A screenshot of the car drifting in a run shows two marks behind the rear tyres, and a screenshot of driving straight shows none being laid (QA: pass)
- [x] game/README.md says how the marks work and which scene and settings T-118 changes to swap the art (QA: pass)
- [x] The drift and car tests, the full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest drifting in a run (from T-118's folder, together with the final marks) and judge the marks.

## Result notes

Written by the Driving & Drift Agent, 2026-10-13, on `task/T-117-drift-marks` in `C:\solid-carbide-worktrees\T-117`.

**Built:** the drift marks scene `game/scenes/driving/drift_marks.tscn` (a `Node2D`, script `game/scripts/driving/drift_marks.gd`). The run (`run.drift_marks`, `game/scripts/run/run.gd`) and the drift prototype (`drift_prototype.drift_marks`, `game/scripts/driving/drift_prototype.gd`) each add one and call `bind(car)`, which lays marks after every car physics step.

- **When:** only while `car.model.is_drifting` is on (the drift state the run's likes use). Driving straight or standing still (also steering on the spot) lays nothing. Each drift start begins a new mark per rear tyre; straight driving in between ends them.
- **Where:** each rear tyre's real place from the car's position, heading and size: 0.9 units behind the centre, 0.375 units to each side (the car is 1 x 3 units). Points are in flat world pixels and drawn through the view's projection. In the run the node sits inside the map's drawing (`map.view_root`), right after the ground tiles and before the buildings, arrows and boulders; the car (`View`) and the HUD come after the map. Enemies do not exist yet; when they are drawn with the car (the run's `View`) or anywhere after the map, they are over the marks. In the prototype it is right after the ground grid, under the test room and the car, following the view switch.
- **How long:** a mark is a chain of `Line2D` pieces (16 segments each, joined end to start). A piece starts its lifetime when it closes (16 segments laid, or the drift ends), stays fully visible for 6 s, fades as a whole through the node's `modulate` alpha over 1 s, and is removed. The texture's pixels stay opaque. Time runs in `_process` with the pausable default, so marks do not age on the pause screen.
- **Placeholder:** a 4 x 4 opaque `ImageTexture` of one dark colour, (18, 15, 23), stored in the scene (no file under `game/art/`), tiled along the line; nearest-neighbour filtering, no anti-aliasing; not Redgull red.
- **For T-118:** every look and tuning value is an exported setting in the scene: `mark_texture`, `texture_mode`, `mark_color`, `width_units`, `lifetime`, `fade_time`, `max_segments`, `piece_segments`, `min_segment_units`, `rear_axle_units`, `half_track_units`. `game/README.md`, "Drift marks", says which to change and which to keep.

**Proposed numbers (for the board's playtest):** lifetime 6 s, fade 1 s, width 0.25 units (4 flat pixels, about one tyre), cap 800 segments (both tyres), pieces of 16 segments (about 0.3 s of drift), a new point every 0.1 units or more, rear axle 0.9 units back, tyres 0.375 units out. At drift speed a point is laid every physics step (50 per second per tyre), so a nonstop drift keeps about 7 s x 100 = 700 segments alive. The cap of 800 sits above that as a safety net. If the board makes the lifetime longer, the cap trims the oldest pieces first.

**Tests:** `game/tests/unit/test_drift_marks.gd`, 18 tests: marks while drifting with one per rear tyre on the tyre's place; none while driving straight or standing still; a new mark per drift; the tyre geometry; stays for the lifetime, then fades as a whole (half way through the fade both pieces are at alpha 0.5, colour opaque, no gradient) and is removed and freed; the lifetime counting from when a piece was laid; a 30-second drift never over the cap and reaching it; the cap with only open pieces; pieces staying joined; no aging while paused; the drawing order in the run (over ground and ground tiles, under buildings, boulders, the car's View and the HUD) and in the prototype (over the grid, under the test room and car, following the view switch); the prototype laying marks; the placeholder (nearest, no anti-aliasing, opaque, dark, far from `Hud.HEART_COLOR` and not any red); the settings stored in the scene; a new run starting with no marks; a run started from the main menu.

**Results:** full GUT suite 379 of 379 pass (`TESTS PASSED`, exit 0, 38 scripts; includes `test_drift_model.gd`, `test_drift_prototype.gd`, `test_car_collisions.gd`, `test_tricks.gd` and the run tests). Python tool tests: `game/tools` 125 tests OK, `tools` 115 tests OK. Godot's line-ending-only `.import` changes were reverted, not committed. No PixelLab calls.

**Screenshots** (git-ignored, in `C:\solid-carbide-worktrees\T-117\screenshots\`), from a run started from the main menu with the car driven by script:
- `T-117-drift-marks-drifting.png` (and `-zoom.png`, a 3x nearest-neighbour crop around the car): the car in a W + D drift with two dark marks curving away behind its rear tyres.
- `T-117-drift-marks-straight.png` (and `-zoom.png`): the car driving straight with W only, no marks.
Retake: `bash game/tools/screenshot.sh res://tests/fixtures/drift_marks_demo_drift.tscn screenshots/T-117-drift-marks-drifting.png 150` and `... res://tests/fixtures/drift_marks_demo_straight.tscn screenshots/T-117-drift-marks-straight.png 90` (fixture `game/tests/fixtures/drift_marks_demo.gd`).

**Documents updated:** `game/README.md` (folder layout; the drift prototype's file list; the run scene's children; a new section, "Drift marks": when, where, how long, the cap, the proposed numbers, the placeholder, what T-118 changes in the scene, screenshots, tests).

## QA round 1

QA/Integration Agent, 2026-10-13, in `C:\solid-carbide-worktrees\T-117` on `task/T-117-drift-marks`. All six criteria pass.

1. **Pass.** `test_drift_marks.gd` drives the real run car: W + D for 40 steps gives `is_drifting` true and exactly two marks, tyres 0 and 1, each mark's newest point equal to `rear_tyres(position, rotation)` (0.9 units back, 0.375 to each side; geometry tested separately for two headings). W only for 100 steps (car moving faster than 5) and standing still (also steering on the spot) give no pieces and no segments. Drift, straight, drift gives four marks, the first two kept, `marks_started` 4, and no segments added while straight. The code keys on `car.model.is_drifting` through `bind(car)` on the car's `stepped` signal.
2. **Pass.** Closed pieces stay at alpha 1 until `lifetime` (6 s), are at alpha 0.5 half way through the 1 s fade on the Line2D's `modulate` (colour and `self_modulate` stay opaque, no gradient), then are removed and freed. A 30-second drift of the run car checks the count every step against the cap of 800, reaches it exactly and never exceeds it, and the count matches the lines' points; a second test holds the cap with only open pieces. Note: a piece's 6 s counts from when the piece closes (at most 16 segments, about 0.3 s, after its first point), which is within "about 6 seconds".
3. **Pass.** Run: the node is a child of `map.view_root` (the map's isometric projection, identity transform, z 0), after the ground and ground tiles, before buildings and boulders; the map is before the run's `View` (car) and the HUD. Prototype: after the ground grid, before the test room and car sprite, and its transform follows the flat/iso view switch. Placeholder: the scene's 4 x 4 opaque ImageTexture (18, 15, 23), root `texture_filter` Nearest, each Line2D Nearest with anti-aliasing off; the test checks every pixel is opaque, dark and far from `Hud.HEART_COLOR`. I read the scene file and confirmed the same values.
4. **Pass.** `T-117-drift-marks-drifting.png` (and `-zoom.png`): a run with the HUD, two dark parallel marks curving away and ending at the car's two rear wheels, drawn under the car. `T-117-drift-marks-straight.png` (and `-zoom.png`): the car driving straight, no marks on the ground.
5. **Pass.** `game/README.md`, "Drift marks", covers when, where, how long, the cap, the proposed numbers and the placeholder, and says T-118 changes only `scenes/driving/drift_marks.tscn` and lists the settings (`mark_texture`, `texture_mode`, `mark_color`, `width_units`, `lifetime`, `fade_time`, and if needed the cap and geometry values), keeping the root's filter Nearest. The run and prototype sections were updated too.
6. **Pass.** Run by QA: full GUT suite 379 of 379 tests pass (49253 asserts, `TESTS PASSED`, exit 0), with `test_drift_marks.gd` 18 of 18 and the drift model, prototype, car collision, tricks and run tests in that run. Python: `game/tools` 125 tests OK, `tools` 115 tests OK. No `.import` changes left in the folder.
- 2026-10-13, in-qa → needs-playtest: QA round 1: all six criteria pass (QA/Integration Agent).
- 2026-10-13, needs-playtest → done: LGTM (board playtest, 2026-10-13)
