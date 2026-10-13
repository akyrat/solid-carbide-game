---
id: T-112
title: Level-up particles from the car (placeholder squares)
status: done
from: project-lead
to: game-loop
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-037]
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/game-loop-architecture.md, tasks/T-037-likes-and-levels.md, tasks/T-074-challenge-and-level-up-effects-art.md, game/README.md]
files_expected_to_change: [the run's scripts and scenes, a new level-up effect scene, their tests, game/README.md, docs/game-loop-architecture.md]
model: sonnet
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

The functional side of the level-up effect (Visual style, Decisions, "Level-up effect"): when the player levels up, the car gives off a burst of pixel-art particles. T-074 then swaps in the final particle art and tunes the look; this task only builds the working effect with placeholder particles.

1. Make one level-up effect scene (a Godot particle node, `CPUParticles2D` or `GPUParticles2D`, your choice) that plays a single burst around the car when started. Keep it easy to retune: the particle texture(s), count, speed, spread and lifetime are set in the scene, not hard-coded in scripts, so T-074 can change them without touching code.
2. Play it on T-037's "level up" signal, on the car, following the car while it plays. Several level-ups at once may play it once per level-up or once in total; write which in the result notes.
3. It must play before the level-up screen (T-052) once that exists; for now the run carries on, so it just plays while driving. Make sure it still plays (is not frozen) if the run is paused for the level-up screen later: set its process mode accordingly and say so in the result notes.
4. Placeholder particles: small plain squares (2 to 4 pixels) drawn by a script or built in code, in one light colour, **not Redgull red**. Nearest-neighbour filtering, no smoothing.
5. Pixel rules for the effect itself: no semi-transparent pixels and no anti-aliasing, so particles do not fade by alpha; they pop out or shrink instead (Visual style, Decisions, "See-through rule").

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. No playtest for this task: the board playtests once T-074's final particles are in.

## Acceptance criteria

- [x] A GUT test shows that emitting T-037's "level up" signal starts the level-up effect on the car, and that it is not playing before (QA: pass)
- [x] A GUT test or a check on the scene shows the particles use nearest-neighbour filtering, have no alpha fade (colour ramp / modulate alpha stays 1) and are not Redgull red (QA: pass)
- [x] A screenshot shows the placeholder burst around the car at a level-up in the run scene (QA: pass)
- [x] game/README.md says how the effect is triggered and which scene and settings T-074 changes to swap the art; Game loop architecture says the run plays it on a level-up (QA: pass)
- [x] T-037's tests, the full GUT suite and all Python tool tests pass (QA: pass)

## Result notes

Written by the Game Loop Agent, 2026-10-13, on `task/T-112-level-up-particles-placeholder` in `C:\solid-carbide-worktrees\T-112`.

**Built:** the level-up effect scene `game/scenes/run/level_up_burst.tscn` (a `CPUParticles2D`, script `game/scripts/run/level_up_burst.gd` with only `play()` and `is_playing()`), added by the run scene (`game/scripts/run/run.gd`) as `run.level_up_burst` under `View`, drawn over the car. The run connects the state's `level_up` signal (T-037) to it; `sync_view()` keeps it on the drawn car every step, and `local_coords` is on, so the particles move with the car while they play.

- **Settings in the scene, not in code:** texture, `amount` 32, `lifetime` 0.7 s, `explosiveness` 1 (all at once), `one_shot`, `spread` 180 (all around), `emission_sphere_radius` 40, `initial_velocity` 180 to 280, `damping` 200 to 260, `scale_amount_curve` (full size until 60% of the life, then shrinks to a quarter). T-074 changes only this scene to swap the art and retune; `game/README.md`, "The run", "The level-up effect", lists exactly what to change and what to keep.
- **Placeholder:** a 4 x 4 pixel square in one light colour, pale cyan (204, 242, 255), fully opaque, stored in the scene as an `ImageTexture` sub-resource (built by a script, no file under `game/art/`). `color` and the colour ramp are white with alpha 1. Not Redgull red.
- **Pixel rules:** `texture_filter` Nearest; no alpha fade (colour, colour ramp, modulate all alpha 1; the texture has no semi-transparent pixels). Particles shrink instead of fading.
- **Several level-ups at once:** one burst in total. One gain that gives two levels sends `level_up` twice in the same moment; each call restarts the same burst, so they show as one.
- **Paused run:** the scene sets `process_mode` to Always, so the burst keeps playing while the tree is paused for the level-up screen (T-052). Tested with the T-037 pause switch on: the run pauses and the burst still processes.
- A new run does not clear a burst in progress; it finishes on its own within 0.7 s.

**Tests:** `game/tests/unit/run/test_level_up_burst.gd`, 11 tests: not playing before a level-up; the `level_up` signal emitted by hand starts it on the car; a real level-up starts it; it follows the car; two level-ups at once; one burst that ends on its own; still playing while paused; the settings live in the scene; nearest-neighbour and no alpha fade; a 2 to 4 px light square of one colour, far from Redgull red (`Hud.HEART_COLOR`) and not any red; a run started from the main menu.

**Results:** full GUT suite 318 of 318 pass (`TESTS PASSED`, exit 0, includes T-037's `test_run_likes.gd`). Python tool tests: `game/tools` 111 tests OK, `tools` 115 tests OK. No PixelLab calls.

**Screenshot:** `C:\solid-carbide-worktrees\T-112\screenshots\T-112-level-up-burst.png` (git-ignored), and an enlarged crop around the car, `T-112-level-up-burst-zoom.png` in the same folder: the placeholder burst around the car at a level-up (HUD shows Lv 2) in a run started from the main menu. Retake it with `bash game/tools/screenshot.sh res://tests/fixtures/level_up_burst_demo.tscn screenshots/T-112-level-up-burst.png 40` (fixture `game/tests/fixtures/level_up_burst_demo.tscn`).

**Documents updated:** `game/README.md` ("The run": "The level-up effect": trigger, scene, settings T-074 changes, screenshot, tests), `docs/game-loop-architecture.md` (Content, "Likes and levels": the run plays the level-up effect on every level-up).

## QA notes

QA round 1, QA/Integration Agent, 2026-10-13, in `C:\solid-carbide-worktrees\T-112` on `task/T-112-level-up-particles-placeholder`. All five criteria pass.

1. **Level-up signal starts the effect: pass.** `tests/unit/run/test_level_up_burst.gd` checks the burst is in the run and not emitting before a level-up, that `state.level_up.emit(2)` starts it at the car's drawn position, and that a real level-up from `add_xp()` starts it. All pass in the full suite run below.
2. **Nearest, no alpha fade, not red: pass.** Read `game/scenes/run/level_up_burst.tscn`: `texture_filter = 1` (Nearest), `color` and both `color_ramp` stops are alpha 1, no modulate set, the texture is a 4 x 4 opaque RGBA8 square of one colour (204, 242, 255), pale cyan, not Redgull red. Shrinks through `scale_amount_curve` instead of fading. `process_mode = 3` (Always). The GUT tests `test_pixel_rules_nearest_no_alpha_fade` and `test_placeholder_is_a_small_light_square_not_redgull_red` check the same and pass.
3. **Screenshot: pass.** `screenshots/T-112-level-up-burst.png` and `-zoom.png` show square pale-cyan particles all around the car, HUD at Hype Lv 2, in the run scene with the HUD. QA retook it with the documented command (`game/tools/screenshot.sh res://tests/fixtures/level_up_burst_demo.tscn ...`) and got the same picture (retake deleted afterwards).
4. **Documents: pass.** `game/README.md`, "The run", "The level-up effect", says it is triggered by the run state's `level_up` signal, names `scenes/run/level_up_burst.tscn` and lists the settings T-074 changes and the ones to keep. `docs/game-loop-architecture.md`, "Likes and levels", has the line that the run plays the level-up effect on every level-up.
5. **Tests: pass.** `bash game/tools/run_tests.sh`: 318 of 318, 33 scripts, `TESTS PASSED`, exit 0 (includes T-037's `test_run_likes.gd` and the 11 tests of `test_level_up_burst.gd`; the one warning is GUT ignoring an inner class, not a failure). `python -m unittest discover -s game/tools -p "test_*.py"`: 111 tests OK. `python -m unittest discover -s tools -p "test_*.py"`: 115 tests OK.
- 2026-10-13, in-qa → done: QA round 1: all five criteria pass
