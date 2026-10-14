---
id: T-074
title: Art: the level-up effect
status: done
from: project-lead
to: asset-generation
lead:
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-112]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, docs/game-loop-architecture.md, tasks/T-112-level-up-particles-placeholder.md]
files_expected_to_change: [a particle-drawing script and its test, particle sprites under game/art/ and their record, T-112's effect scene, game/README.md]
model: sonnet
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The level-up effect (Visual style, Decisions, "Level-up effect"): when the player levels up, the car gives off a burst of pixel-art particles. T-112 builds the working effect with plain placeholder squares; this task draws the final particle art and swaps it in. The challenge completed effect moved to T-100, after the MVP (2026-10-11).

**No PixelLab** (board, 2026-10-13): the particles are small enough to draw with a script. Write a script that draws the particle sprites (for example sparks, stars, small diamonds or pixel crosses, a few pixels across, with a frame or two of twinkle if it helps), within Visual style, Decisions: the night neon palette, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, about 30 colours or fewer. Not Redgull red (red belongs to Redgull only). The shapes, colours, count, sizes, speed, spread and lifetime are your proposal, written in the result notes for the board to judge (Visual style, Decisions).

Swap the art into T-112's effect scene and retune its settings there (`tasks/README.md`, "Art replaces placeholders"), without changing when or how the effect plays. Particles do not fade by alpha: they pop out or shrink.

Keep the script and its output: game-ready sprites under `game/art/`, with a short record of how they were made; anything not used goes in `art-archive/T-074/`.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer, and none uses Redgull red (QA: pass)
- [x] The sprites are made by a committed script, with a test, and no PixelLab calls were made (QA: pass)
- [x] A screenshot shows the effect around the car at a level-up (QA: pass)
- [x] T-112's tests still pass, and the particles still have no alpha fade and use nearest-neighbour filtering (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest the level-up effect in the run and judge the look.

## Result notes

- 2026-10-13, planning → blocked: waits for T-112 (placeholder particles)

Written by the Asset Generation Agent, 2026-10-13, on `task/T-074-level-up-particles-art` in `C:\solid-carbide-worktrees\T-074`. **No PixelLab calls** (board, 2026-10-13): nothing was generated or paid for; every pixel is drawn by a script.

**Made:** `game/art/effects/level_up_particles.png`, one row of six 11 x 11 frames, and its record `game/art/effects/level_up_particles.json` (shapes, palette, how it was made). Drawn by `game/tools/build_level_up_particles.py build` (byte-identical every run). Nothing unused, so nothing in `art-archive/T-074/`.

**Proposal for the board (shapes, colours, tuning):**

- **Shapes:** a cyan four-point star, a pink four-point star, a pink diamond, a cyan diamond, a violet pixel cross (a plus with four diagonal dots) and a small cyan spark. Each particle gets one shape at random for its whole life, so the burst mixes them.
- **Colours:** 13 in all, night neon: a white-hot core, then for each of cyan, pink and violet a light core shade, the neon, a mid shade and a dark halo shade, so the glow steps down into the night (glow in the pixels, no engine bloom). No outline: the darkest halo shade edges each particle. No red: every colour is more than 0.5 (0..1 RGB distance) from Redgull red and none has a red hue.
- **Tuning** (all in `game/scenes/run/level_up_burst.tscn`): `amount` 40 (was 32), `lifetime` 0.8 s (was 0.7) with `lifetime_randomness` 0.35 so they pop out at slightly different times, `emission_sphere_radius` 24 (was 40, so they start on the car's body), `spread` 180 (all around), `initial_velocity` 180 to 320 (was 180 to 280), `damping` 180 to 240 (was 200 to 260). `scale_amount` 0.5 draws the art at the car's own pixel density (32 art pixels per unit, as the car), and particles are never rotated, so they stay crisp pixel art.
- **No fade:** `scale_amount_curve` keeps full size until 65% of the life, steps to half size (a smaller twinkle), and pops out at 86%. The colour ramp and `color` stay white at alpha 1.
- **How the sheet is read:** a `CanvasItemMaterial` with particles animation, 6 horizontal frames; `anim_offset` 0 to 1 with `anim_speed` 0 picks one frame per particle. `texture_filter` Nearest, `one_shot`, `explosiveness` 1 and `process_mode` Always are unchanged; when and how the burst plays (`scripts/run/run.gd`) is untouched.
- **Honest look:** in the screenshot the stars and diamonds read clearly as neon sparkles around the car; the violet pixel cross is the weakest shape (its thin arms break up at this zoom). Cheapest change if the board wants: drop it, or give it a solid core like the stars (a script edit, free). If the burst feels too small or too subtle at play zoom, `initial_velocity` and `amount` are the first two knobs; drawing the particles bigger than the car's density (`scale_amount` 1.0) is possible but breaks the one-scale rule.

**Check script:** `python game/tools/build_level_up_particles.py check` (or `check --png OTHER.png`): for every frame, transparent background, no semi-transparent pixels, about 30 colours or fewer (each frame 4 to 5); for the whole sheet, 13 colours, no semi-transparent pixels, no Redgull red nor any red. Output ends `ALL RULES PASS`, exit 0.

**Tests:**
- Python: `game/tools/test_build_level_up_particles.py`, 14 tests (the rules, the palette, no red, the red check catching red and semi-transparent pixels and an opaque corner, the committed PNG and record up to date, the record is not a PixelLab record).
- GUT: new `game/tests/unit/run/test_level_up_particles_art.gd`, 5 tests (the scene uses the sheet, the sheet matches its record, one random shape per particle, the car's density and no rotation, the stepped shrink without fade).
- T-112's `test_level_up_burst.gd`: 10 of its 11 tests are unchanged. Its placeholder test (`test_placeholder_is_a_small_light_square_not_redgull_red`: a 2 to 4 px square of one light colour) could not hold once the placeholder was replaced, so it became `test_particle_art_is_not_redgull_red`, which applies the same red rule (distance from `Hud.HEART_COLOR` more than 0.5, and not a red) to every opaque pixel of the sheet and checks `color` stays white. The nearest-neighbour and no-alpha-fade test (every texture pixel alpha 0 or 1, colour ramp alpha 1) is unchanged and passes.

**Results:** full GUT suite 323 of 323 pass (34 scripts, `TESTS PASSED`, exit 0). Python tool tests: `game/tools` 125 tests OK, `tools` 115 tests OK.

**Screenshots** (git-ignored `screenshots/` folder): `C:\solid-carbide-worktrees\T-074\screenshots\T-074-level-up-burst.png` (the burst around the car at a level-up, HUD at Hype Lv 2, in a run from the main menu), `T-074-level-up-burst-zoom.png` (a 220 x 200 crop around the car, enlarged 4 times, nearest-neighbour) and `T-074-particle-sheet-x12.png` (the six sprites enlarged 12 times on a dark and a light background). Retake with T-112's fixture: `bash game/tools/screenshot.sh res://tests/fixtures/level_up_burst_demo.tscn screenshots/T-074-level-up-burst.png 40`. The particles are random, so each take differs a little.

**Documents updated:** `game/README.md` ("The run", "The level-up effect": the particle art, how it is built and checked, how the scene reads it, the tuning, the tests). No game area doc changed: the shapes and tuning are a proposal; if the board approves them, the Project Lead can record them in Visual style, Decisions. Also `agent-notes/asset-generation.md` (working notes).

**Branch housekeeping:** the Project Lead's status change to in-progress was uncommitted on `master`; it was committed on this branch (first commit) and `master`'s working copy put back, so the task file now lives only on the branch.

**QA round 1** (QA/Integration Agent, 2026-10-13, on `task/T-074-level-up-particles-art` in `C:\solid-carbide-worktrees\T-074`): every criterion passes.

1. **Check script: pass.** `python game/tools/build_level_up_particles.py check` prints `ALL RULES PASS`, exit 0. Read the code: per frame it checks transparent corners, no alpha strictly between 0 and 255, and at most 30 opaque colours (4 to 5 each); for the whole sheet 13 colours, no semi-transparent pixels, and no colour within 128 (0.5) RGB distance of Redgull red (219, 26, 41, the HUD heart) nor any saturated red hue. Independently, the PNG (66 x 11) has only alpha 0 and 255. Its tests show the check really fails a sheet with a Redgull-red pixel, a semi-transparent pixel and an opaque corner. Note: the background check looks at each frame's corners, not every edge pixel; enough for these centred shapes.
2. **Committed script, test, no PixelLab: pass.** Rebuilt PNG and JSON into a scratch folder with the committed script: both byte-identical to the committed files. Test `game/tools/test_build_level_up_particles.py` (14 tests) passes and also fails if the committed files go stale. No PixelLab: the script imports only local modules (`check_sprite_rules`, `remove_car_shadow`), no network; the branch diff has no PixelLab client call, no PixelLab record (no `endpoint`), no `art-archive/` files; every "PixelLab" mention in the diff says it was not used.
3. **Screenshot: pass.** `screenshots/T-074-level-up-burst.png` shows a run (HUD at Hype Lv 2) with the burst around the car; the 4x zoom shows the cyan and pink stars and diamonds and the violet crosses spread around the car, crisp, no blur. `T-074-particle-sheet-x12.png` shows the six sprites on dark and light, hard edges, no red. Looks match the result notes, including the violet cross being the weakest shape.
4. **T-112's tests, nearest filtering, no alpha fade: pass.** `-gselect=test_level_up`: 2 scripts, 16 of 16 pass. The scene keeps `texture_filter = 1` (Nearest), `color` and the colour ramp white at alpha 1, and the shrink curve steps 1 -> 0.5 -> 0 (scale, not alpha). `test_pixel_rules_nearest_no_alpha_fade` is unchanged. The replaced placeholder test: the old one checked a 2-4 px single-colour light square, opaque, far from Redgull red and not a red. The size, single-colour and lightness parts described the placeholder only and cannot apply to the final art; the rule that matters (distance from `Hud.HEART_COLOR` > 0.5 and not a red) is kept, now over every opaque pixel of the sheet, plus `color` staying white; opacity is covered by the unchanged pixel-rules test. Judged as still covering the same rule.
5. **Full GUT suite and Python tool tests: pass.** `bash game/tools/run_tests.sh`: 34 scripts, 323 of 323, `TESTS PASSED`, exit 0 (1 warning, the existing `TestRoom` inner class notice). `game/tools`: 125 tests OK. `tools`: 115 tests OK.

The worktree's line-ending-only `.import` changes from Godot were left uncommitted.
- 2026-10-13, in-qa → needs-playtest: QA round 1: all five criteria pass
- 2026-10-13, needs-playtest → done: LGTM (board, playtest 2026-10-13); violet cross kept as is
