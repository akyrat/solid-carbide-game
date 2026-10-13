---
id: T-073
title: Art: drift smoke
status: in-qa
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
qa_rounds: 0
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

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, about 30 colours or fewer, and no Redgull red (QA: pass / fail)
- [ ] The sprites are made by a committed script, with a test, and no PixelLab calls were made (QA: pass / fail)
- [ ] Screenshots of the car drifting on asphalt and on gravel show the new smoke behind the rear tyres (QA: pass / fail)
- [ ] T-121's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

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
- 2026-10-13, in-progress → in-qa: Smoke puff art drawn by script and swapped in; tests pass
