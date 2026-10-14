---
id: T-073
title: Art: drift smoke
status: done
from: project-lead
to: asset-generation
lead:
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, game/README.md, tasks/T-121-drift-smoke.md, tasks/T-118-drift-marks-art.md, tasks/T-074-challenge-and-level-up-effects-art.md]
files_expected_to_change: [a smoke drawing script and its test, smoke sprites under game/art/ and their record, T-121's smoke scene, game/README.md]
model: sonnet
qa_rounds: 2
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

The final look of the drift smoke (Visual style, Decisions, "Drift smoke", 2026-10-13). T-121 builds the working smoke with a placeholder; this task draws the real smoke sprites and swaps them in. The tyre tracks moved to T-117 and T-118 (done).

**Branch:** create your branch `task/T-073-drift-smoke-art` from T-121's branch (not from master), in your own folder `C:\solid-carbide-worktrees\T-073`, so the board playtests both from your folder. T-121 merges first, then this task.

**No PixelLab** (board, 2026-10-13: no sample review, straight to the playtest): write a script that draws the smoke puff sprites, a few sizes or frames (for example a puff that grows, then breaks up in pixel steps), within Visual style, Decisions: pixel art, no anti-aliasing, no semi-transparent pixels (use dithering or stepped shapes for softness), a transparent background, about 30 colours or fewer, the night palette (cool grey-violet smoke, perhaps a faint neon tint from the city), not Redgull red. It must read on both the dark asphalt and the dusty gravel. Propose the shapes, colours, sizes and any retuning of T-121's settings in the result notes, and judge honestly how it reads.

Swap the sprites into T-121's smoke scene without changing when or how smoke is emitted. Keep the script and its output: game-ready art under `game/art/`, with a short record; anything unused in `art-archive/T-073/`.

## Acceptance criteria

- [x] A check script shows every new sprite has a transparent background, no semi-transparent pixels, about 30 colours or fewer, and no Redgull red (QA: pass)
- [x] The sprites are made by a committed script, with a test, and no PixelLab calls were made (QA: pass)
- [x] Screenshots of the car drifting on asphalt and on gravel show the new smoke behind the rear tyres (QA: pass)
- [x] T-121's tests still pass (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest drifting in a run and judge the smoke (together with T-121).

## Result notes

No PixelLab calls (planned cost: none, nothing spent). Branch `task/T-073-drift-smoke-art`, from T-121's branch; folder `C:\solid-carbide-worktrees\T-073`.

**Made:** `game/tools/build_drift_smoke.py` (with `game/tools/test_build_drift_smoke.py`, 14 tests) draws one sprite, `game/art/effects/drift_smoke_puff.png` (24 x 24, record `drift_smoke_puff.json`; preview over asphalt and gravel at four sizes in `art-archive/T-073/drift_smoke_preview.png`). A lumpy cloud lit from the top left: 5 colours (neon-tinted highlight (224,232,250), light, mid, dark, deep violet rim (74,68,110)), bands blended with a checkerboard dither, the outermost ring chequered away for a ragged soft edge. No semi-transparent pixels, transparent background, no red. `python game/tools/build_drift_smoke.py check` is the check script (all rules pass: body colours are +85 luma over the asphalt and +43 over the gravel).

**Why one sprite, not several frames:** the smoke script (T-121) draws one texture per puff and its size curve does the growing and shrinking; several frames would need a code change, and the task says not to change how puffs are emitted. The pixel "break up" is therefore the size curve's shrink plus the pop-out.

**Swapped in:** `scenes/driving/drift_smoke.tscn` now uses the PNG (the placeholder image is gone). Retune: the texture is 24 texels (was 16), so the size curve went from 0.6 / 2.0 / 1.0 to 0.5 / 1.3 / 0.8, which keeps the drawn size the same (a full-grown puff about 16 drawn pixels, one car width); `puff_scale` 0.5, lifetime, rate, cap, rise, spread and jitter unchanged. Nothing in the scripts changed. T-121's placeholder test was renamed and loosened (lightness now above 0.2, not 0.6, since the rim is darker) in `test_drift_smoke.gd`.

**Screenshots** (in `C:\solid-carbide-worktrees\T-073\screenshots\`, git-ignored): `drift_smoke_asphalt.png` and `drift_smoke_gravel.png`, with `_crop.png` versions enlarged 3x (nearest). Fixture `drift_smoke_demo_asphalt.tscn` is new (the demo got a `start_units` setting, as the marks demo has).

**Tests:** full GUT suite 426 / 426 passed; Python tool tests: `game/tools` 155 OK, `tools` 115 OK. Line-ending-only `.import` changes reverted.

**Honest judgement:** it reads on both grounds: the body is clearly lighter than asphalt and gravel, and the trail behind the rear tyres is easy to see. But it does not look much like smoke yet. Every puff is the same stamp in the same orientation, so the trail looks like a row of pale hexagonal gems, and the checkerboard rim shows up as a busy edge at the small sizes. The dithered highlight is a little blocky. The cheapest next steps, if the board agrees: 2 or 3 puff variants and a random rotation or flip per puff (a small change to T-121's script, which this task may not make), and fewer, bigger puffs with a longer life. The look is a proposal for the playtest together with T-121.

Documents affected, all updated: `game/README.md` ("Drift smoke", the tools list). `docs/visual-style.md` already carries the decision; nothing there changed.
**QA round 1 (qa-integration, 2026-10-13): all five criteria pass.** Judged only the diff from `task/T-121-drift-smoke`.

1. Check script: pass. `python game/tools/build_drift_smoke.py check` exits 0, all 8 rules pass (5 colours, 0 semi-transparent, corners clear, no red, body +85 luma over asphalt, +43 over gravel). Fed it broken copies of the sprite: an opaque corner, one alpha-128 pixel, a Redgull-red pixel and 40 colours each make it fail the matching rule. Note: "transparent background" itself only looks at the four corners (the shared `check_sprite_rules`), but a filled background is still caught by the 35 to 80 % coverage rule, so the gap is covered.
2. Script, test, no PixelLab: pass. `build` rewrites the PNG, its record and the archive preview byte for byte (same SHA-256, git tree clean). `test_build_drift_smoke.py`: 14 tests, OK. The script and test import no network code; the diff touches nothing PixelLab (`pixellab-generation-log.jsonl` unchanged).
3. Screenshots: pass. The agent's `drift_smoke_asphalt*.png` and `drift_smoke_gravel*.png` show the new five-tone puffs with the violet rim trailing both rear tyres, over the marks. Retook both myself from the committed scene (`screenshots/qa/qa_smoke_asphalt.png`, `qa_smoke_gravel.png`, 150 frames): same result. Reads clearly on both grounds, less strongly on the gravel. I agree with the agent's own judgement that the puffs look like a row of identical gems rather than smoke; that is for the board's playtest.
4. T-121's tests: pass. All 18 tests in `test_drift_smoke.gd` pass. The renamed puff-art test still asserts Nearest filtering, no material, alpha 0 or 1 for every pixel, the Redgull-red distance and the "not any red" rule, blue strongest and greyish; only the minimum lightness dropped from 0.6 to 0.2 (the rim is luminance about 0.28). It still guards what it should; the 0.2 floor alone is weak, but readability on the grounds is covered by the Python check's luma-gap rule.
5. Full suites: pass. GUT 426 / 426 (1 known warning: inner class TestRoom); `game/tools` 155 OK; `tools` 115 OK. Godot's line-ending-only `.import` changes left uncommitted.

- 2026-10-13, in-progress → in-qa: Smoke puff art drawn by script and swapped in; tests pass
- 2026-10-13, needs-playtest → in-progress: board playtest: smoke lasts too long; in a full-circle drift it should cover about 20 degrees of the circle, not half

### The board's playtest, 2026-10-13 (round 1): shorter smoke

Each puff lasts too long: drifting in a full circle, the smoke trail covers about half the circle. The board wants it to cover about **20 degrees** of the circle. The trail's length follows the puffs' lifetime, so cut `lifetime` in `drift_smoke.tscn` to about a ninth (from 0.7 s to roughly 0.08 s, with its randomness), measured in a real full-circle drift, and adjust the size curve and spawn rate only as needed so the short trail still reads as smoke. Report the measured arc. Nothing else changes.


## Round 2

No PixelLab calls (nothing spent). Only `scenes/driving/drift_smoke.tscn` changed (and tests, README, screenshots); `drift_smoke.gd` is untouched.

**Measured, not guessed.** Test `test_the_smoke_trail_spans_about_twenty_degrees_in_a_full_circle_drift` (`tests/unit/test_drift_smoke.gd`) drives the run car with W + D for 5 s, then 300 more physics steps; per step it takes the live puffs of the left rear tyre, oldest to newest, and measures the angle they span seen from the circle's centre (fitted from three points of the car's path), averaged over the steps. Old values (0.7 s, 30 per second): **138 degrees** (matches the board's "about half"). Cutting only the lifetime to 0.08 s gave just 7 degrees (with 30 per second, a trail of about 4 physics steps has too few puffs, so the span between oldest and newest is shorter than the life), and 9.6 degrees at 50 per second. Lifetime 0.10 gave 13.8, 0.13 gave **20.2** (20.0 to 20.2 over repeated runs), 0.15 gave 24.3.

**Changed:** `lifetime` 0.7 to **0.13 s** (randomness stays 0.25, so +-25% as before; about a fifth, not a ninth, because the measured arc, not the ratio, was the target: 0.08 s measures about 10 degrees); `puffs_per_second` 30 to **50** (one puff per tyre per physics step, so the short trail is a connected chain, not 2 or 3 stray puffs). Size curve unchanged (the puff still grows 0.5 to 1.3 then shrinks within its 0.13 s; the screenshots show a chain of overlapping puffs that reads as a short smoke trail). `max_puffs` stays 64 (a steady drift now holds about 13).

**Note on the measure:** it counts puff centres, so the visible trail is a little longer (a full-grown puff is about one car width wide).

**Tests:** new arc test (20 degrees +- 5); the "a long drift never over the cap" test now asserts a steady drift holds more than `puffs_per_second x lifetime` puffs (it used "more than half the cap", which was about the old life); other T-121 tests read `lifetime` from the scene and pass. Full GUT 427 / 427 passed; `game/tools` 155 OK; `tools` 115 OK. Screenshots retaken: `screenshots/drift_smoke_asphalt.png`, `drift_smoke_gravel.png` and their `_crop.png` (3x). Line-ending-only `.import` and `project.godot` changes reverted.

Documents affected: `game/README.md` ("Drift smoke": numbers, tests).
- 2026-10-13, in-progress → in-qa: Round 2: shorter smoke, trail measured at 20 degrees

**QA round 2 (qa-integration, 2026-10-13): all five criteria pass, and the board's request is met.** Checked again from scratch.

0. The board's request (shorter trail): pass. Round 2's commit changes only `lifetime` 0.7 → 0.13 and `puffs_per_second` 30 → 50 in `drift_smoke.tscn` (rate, cap 64, size curve, `puff_scale`, rise, spread, jitter, tyre places unchanged); `scripts/driving/drift_smoke.gd` has no diff from `task/T-121-drift-smoke`, so when and how smoke is emitted is T-121's. The new arc test passes (my run: 19.9 degrees). How it measures: drives W + D into a steady drift, then per physics step takes the left rear tyre's live puffs, oldest to newest by birth, and the angle between them seen from a circle centre fitted from three points of 300 steps of path; averaged. Sound: 300 steps is about 2.7 circles, so the three fit points are well apart. My own independent check (centre from a different fit, 600 steps): the path radius is steady (10.18 to 10.31 units), the car turns 192 degrees per second (one circle in 1.88 s), so the mean puff life spans 25 degrees; the extent of all live puffs of both tyres averages 24.3 degrees (peak 31.5). So the trail is about 20 to 25 degrees by puff centres, a little more on screen with the puffs' width: about a fifth of the old 138 degrees and close to the board's 20. The cap test still guards the cap: every step of the 30 s drift asserts the count is at most `max_puffs`, and the time-stopped loop still asserts it reaches and holds exactly 64. Only its "good amount of smoke" floor dropped (from more than 32 to more than 6, i.e. rate x life; a steady drift holds about 12 to 13); that line never guarded the cap.
1. Check script: pass. `python game/tools/build_drift_smoke.py check` exits 0, all 8 rules pass (5 colours, 0 semi-transparent, corners clear, no red, cool, 284 of 576 texels, +85 / +43 luma). The sprite is unchanged since round 1.
2. Script, test, no PixelLab: pass. Unchanged since round 1 (round 2 touched no art or tool); the tool tests pass; round 2 notes no PixelLab calls and the commit touches nothing PixelLab.
3. Screenshots: pass. The agent's `screenshots/drift_smoke_asphalt*.png` and `drift_smoke_gravel*.png` (I looked at the gravel crop too) show a short chain of puffs right behind the rear tyres, over the marks, no longer than about a car length and a half. Retook both from the committed scene (`screenshots/qa/qa2_smoke_asphalt.png`, `qa2_smoke_gravel.png`, 150 frames, with 3x `_crop` versions): same result. Reads clearly on the asphalt, a little less on the gravel, still visible. The "row of identical gems" look from round 1 remains; that is for the board's playtest.
4. T-121's tests: pass. `test_drift_smoke.gd` 19 / 19 (18 of T-121's, adapted, plus the arc test).
5. Full suites: pass. GUT 427 / 427 (1 known warning); `game/tools` 155 OK; `tools` 115 OK. Godot's line-ending-only `.import` changes left uncommitted.
- 2026-10-13, in-qa → needs-playtest: QA round 2: all criteria pass; trail about 20 to 25 degrees
- 2026-10-14, needs-playtest → done: LGTM (board playtest, 2026-10-14)
