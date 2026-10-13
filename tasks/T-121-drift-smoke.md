---
id: T-121
title: Drift smoke: the rear tyres puff smoke while drifting (placeholder)
status: in-progress
from: project-lead
to: driving-drift
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/drifting.md, game/README.md, tasks/T-117-drift-marks.md, tasks/T-112-level-up-particles-placeholder.md]
files_expected_to_change: [a new drift smoke scene and script, the run scene and the drift prototype scene, their tests, game/README.md]
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

The board wants drift smoke (Visual style, Decisions, "Drift smoke", 2026-10-13): while the car drifts, puffs of smoke come off its two rear tyres. This task builds the working effect with a placeholder look; T-073 draws the final smoke sprites by script and swaps them in, built on this task's branch. The board playtests both together from T-073's folder (no separate sample review).

1. **When:** smoke only while the car is drifting (the car's own drift state, as the drift marks use, T-117). None while driving straight or standing still.
2. **Where:** from each rear tyre's position (reuse T-117's tyre positions). Puffs are left behind in the world (they don't move with the car), drift up or outward a little, grow, then shrink and pop out. Drawn above the ground, the drift marks and the boulders, below the HUD; in the depth order T-034 set up, so a building covering the car also covers the smoke near the car.
3. **No semi-transparent pixels in the sprites** (Visual style, Decisions); puffs shrink and pop out rather than fading per pixel. Whether whole puffs may also fade as objects (allowed by the "See-through rule") is your proposal.
4. **Placeholder look:** small plain light grey-violet squares or circles, not Redgull red, nearest filtering. Keep the texture(s), amount, lifetime, speed, size curve and colour in one scene, so T-073 can swap the art and retune without touching code.
5. Keep it cheap: a capped number of puffs at once.
6. Works in the run (including from the main menu) and in the drift prototype.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Do not merge.

## Acceptance criteria

- [ ] GUT tests show smoke is emitted from both rear tyres while the car drifts and not while it drives straight or stands still (QA: pass / fail)
- [ ] GUT tests show puffs stay where they were left in the world, end within their lifetime, and never exceed the cap during a long drift (QA: pass / fail)
- [ ] A GUT test or a check on the scene shows the depth order (above ground, marks and boulders; below the HUD; covered by a building that covers the car), nearest filtering, no semi-transparent pixels in the placeholder and no Redgull red (QA: pass / fail)
- [ ] A screenshot of the car drifting in a run shows smoke behind the rear tyres, and one of driving straight shows none (QA: pass / fail)
- [ ] game/README.md says how the smoke works and which scene and settings T-073 changes (QA: pass / fail)
- [ ] The drift, drift marks and car tests, the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest drifting in a run (from T-073's folder, together with the final smoke) and judge the smoke.

## Result notes

Written by the Driving & Drift Agent, 2026-10-13, on `task/T-121-drift-smoke` in `C:\solid-carbide-worktrees\T-121`.

**Built:** the drift smoke scene `game/scenes/driving/drift_smoke.tscn` (a `Node2D`, script `game/scripts/driving/drift_smoke.gd`). The run (`run.drift_smoke`, `game/scripts/run/run.gd`) and the drift prototype (`drift_prototype.drift_smoke`, `game/scripts/driving/drift_prototype.gd`) each add one and call `bind(car, drift_marks)`, which makes smoke after every car physics step.

- **When:** only while `car.model.is_drifting` is on (the drift marks' and likes' drift state). A drift starts with one puff per tyre at once, then 30 per second per tyre. Nothing while driving straight or standing still (also steering on the spot).
- **Where:** at each rear tyre's place from the drift marks' `rear_tyres()` (T-117), plus up to 0.15 units of random jitter. A puff keeps its spot in flat world pixels (it does not move with the car) and is drawn at the view's projection of that spot, drifting on screen by itself: up 10 px/s plus up to 8 px/s outward in a random direction. One node draws all puffs (`_draw`), upright in screen pixels.
- **Life:** 0.7 s +-25%. Size follows a curve in the scene: 0.6 at birth, 2.0 at 40% of the life, 1.0 at the end, then the puff pops out. My proposal on the fade: **no fade, not even as a whole object**; the pop-out keeps the pixel look crisp, as the level-up burst does. Colour, modulate and texture pixels all stay at alpha 1 (or fully clear). If the board wants a whole-puff fade, it is a small code change.
- **Cap:** 64 puffs at once (both tyres); a new puff past the cap replaces the oldest. A steady drift keeps about 2 x 30 x 0.7 = 42, so the cap is a safety net.
- **Depth order:** in the run the node is a child of the run's `View`, before the car sprite. It is drawn with the car, under the car sprite, and shares the car's place in T-034's depth order (`View.z_index` = `map.car_z_index()`, always 1 or more). That puts it over the map's ground, drift marks and boulders (z 0, drawn before `View`) and under the HUD (a CanvasLayer), and a building that covers the car covers the smoke too. One known limit: puffs left far behind take the car's current depth, so for their short life they can show over or under a building they are not next to. In the prototype it comes after the ground, marks and test room and before the car sprite, and `set_view()` updates its `view_transform`. A new run empties it and binds it to the new car and the new map's marks.
- **Placeholder:** a 16 x 16 round puff in one light grey-violet, (196, 188, 214), with fully clear corners, stored in the scene as an `ImageTexture` (no file under `game/art/`); `puff_scale` 0.5 (the car art's density, so a size-1 puff is half a unit and a full-grown one about the car's width); root `texture_filter` Nearest; not Redgull red.
- **For T-073:** every look and tuning value is an exported setting in the scene: `puff_texture`, `puff_color`, `puff_scale`, `size_curve`, `lifetime`, `lifetime_randomness`, `puffs_per_second`, `max_puffs`, `rise_speed`, `spread_speed`, `spawn_jitter_units`. `game/README.md`, "Drift smoke", says which to change and what to keep.

**Proposed numbers (for the board's playtest):** 30 puffs/s per tyre, lifetime 0.7 s +-25%, cap 64, size curve 0.6 / 2.0 / 1.0, scale 0.5, rise 10 px/s, spread up to 8 px/s, jitter 0.15 units, no fade. A first try at 14 puffs/s and 0.8 s gave separate dots trailing well behind the car at drift speed, so I raised the rate.

**Tests:** `game/tests/unit/test_drift_smoke.gd`, 18 tests: smoke from both rear tyres on the marks' tyre places while drifting; none while driving straight, standing still or after the drift ends; the tyre places following the drift marks; puffs staying where they were left while the car drives away (only drifting by their own small speed); growing, shrinking and popping out at the end of their life; every puff gone once the longest life has passed; a 30-second drift never over the cap, and reaching and holding the cap with time stopped; no aging while paused; the depth order in the run (in `View` under the car sprite, `View` z over the map's z-0 ground, marks and boulders, the HUD a CanvasLayer above, under T-034's block when the car is behind it and over it in the open) and in the prototype (and the view switch); the placeholder (nearest, no semi-transparent pixels, light grey-violet, far from `Hud.HEART_COLOR` and not any red, no fading tint, no material); the settings stored in the scene; a new run starting empty; a run started from the main menu.

**Results:** full GUT suite 426 of 426 pass (`TESTS PASSED`, 42 scripts, 53343 asserts; includes `test_drift_smoke.gd`, `test_drift_marks.gd`, `test_drift_marks_art.gd`, `test_drift_model.gd`, `test_drift_prototype.gd`, `test_car_collisions.gd`, `test_tricks.gd`, `test_see_through_map.gd` and the run tests). Python tool tests: `game/tools` 141 tests OK, `tools` 115 tests OK. Godot's line-ending-only `.import` changes were reverted, not committed; `project.godot` unchanged. No PixelLab calls.

**Screenshots** (git-ignored, in `C:\solid-carbide-worktrees\T-121\screenshots\`), from a run started from the main menu with the car driven by script:
- `T-121-drift-smoke-drifting.png` (and `-zoom.png`, a 3x nearest-neighbour crop around the car): the car in a W + D drift on the gravel, light grey-violet puffs coming off behind the rear tyres along the two drift marks, small at the tyres and larger further back.
- `T-121-drift-smoke-straight.png` (and `-zoom.png`): the car driving straight with W only, no smoke.
Retake: `bash game/tools/screenshot.sh res://tests/fixtures/drift_smoke_demo_drift.tscn screenshots/T-121-drift-smoke-drifting.png 150` and `... res://tests/fixtures/drift_smoke_demo_straight.tscn screenshots/T-121-drift-smoke-straight.png 90` (fixture `game/tests/fixtures/drift_smoke_demo.gd`).

**Documents updated:** `game/README.md` (folder layout; the drift prototype's file list; the run scene's children; a new section, "Drift smoke": when, where, life, cap, depth order, proposed numbers, placeholder, what T-073 changes in the scene, screenshots, tests).
