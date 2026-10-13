---
id: T-073
title: Art: drift smoke
status: needs-playtest
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, game/README.md, tasks/T-121-drift-smoke.md, tasks/T-118-drift-marks-art.md, tasks/T-074-challenge-and-level-up-effects-art.md]
files_expected_to_change: [a smoke drawing script and its test, smoke sprites under game/art/ and their record, T-121's smoke scene, game/README.md]
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
