---
id: T-071
title: Art: gun bullets, exhaust flames and burning
status: in-progress
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-041, T-042]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-003-pixellab-test-generation.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/weapons.md, tasks/T-041-starting-gun.md, tasks/T-042-exhaust-flamethrower.md]
files_expected_to_change: [art files under game/art/ and their records, the scenes that used the placeholders, game/README.md]
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

**Blocked until T-041 (the gun) and T-042 (the flamethrower) are done.**

The weapon effects (Visual style, Decisions): the gun's bullets, the flames out of the exhaust, and enemies burning. The weapons arrive as Redgull gift packs, so Redgull's red can be part of them where it fits; they don't need to be all red (Visual style, Decisions). Swap them in for T-041's and T-042's placeholders.

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. Real-world things are inspiration only: no real logos, no copies of existing characters. Details the docs leave open (directions, frame counts, variants, sizes) are this agent's proposal, written in the result notes for the board to judge (Visual style, Decisions).

Use the existing client, `game/tools/pixellab_client.py`. Record every call with its prompt, settings and cost, and the balance before and after. One round of generation only: don't regenerate; report problems instead. The board judges the result.

This art task swaps its art in for the placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass / fail)
- [ ] A screenshot shows the final bullets and flames, and a burning enemy (QA: pass / fail)
- [ ] T-041's and T-042's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the look. One round only, so problems are reported rather than regenerated.

## Updates

### 2026-10-21, Open → In progress

Started at the board's request, in C:\solid-carbide-worktrees$t.

### 2026-10-21, In progress → In QA

Flame sample in (1 generation). The flame is good; PixelLab added a tailpipe, which a free script can erase. Pictures: C:\solid-carbide-worktrees\T-071\art-archive\T-071\exhaust_flame_review.png

## Result notes

### Sample round (board's go 2026-10-21; sample first, nothing swapped into the game)

**Checked first (nothing made twice):** `game/art/effects/` holds boost lines, coin, drift mark, drift smoke, level-up particles; `game/art/weapons/` holds the molotov bottle and fire, underglow, wiper (T-175). No bullet, exhaust flame or burning art exists. The current placeholders are a black-and-orange `CPUParticles2D` flame cone and a cyan dot bullet (`docs/weapons.md`).

**Proposal for the whole task (free vs paid):**
- Paid, PixelLab, 1 generation each (`create-image-pixflux`, one round): (1) the exhaust flame plume (this sample), (2) the burning effect on an enemy (a small flame wrap about a minion's size, looped by script), (3) the bullet (a small glowing round, about 12 x 12; a fallback is to draw it free).
- Free, by script from those: the flame in all car directions (the plume turned in the flat world and projected by the iso transform, as T-175 did for the wiper), flicker frames (mirror, plus a one-shade palette shift), the burning sprite's frames, and the bullet's trail or spin if wanted. If the board finds the bullet fine drawn by hand, it needs no PixelLab at all.
- Expected total: about 3 generations.

**Planned call (this sample), written before calling:** one `POST /create-image-pixflux`, 128 x 96, no_background, selective outline, detailed shading, highly detailed, text guidance 8, seed 71001; prompt and negatives in `art-archive/T-071/req_exhaust_flame.json`. Expected cost 1 generation (T-175's equivalent call cost 1.0). HTTP timeout 600 s (client default). Balance before: 4860 of 5000 generations.

**Done (sample):** one call, 1 generation, no errors, no retry. Balance before 4860, after 4858 of 5000 generations (the extra 1 is probably spent elsewhere in the account at the same time). Saved `art-archive/T-071/exhaust_flame_raw.png` + `.json` (the record has the prompt, settings, usage), the request `req_exhaust_flame.json`, and the review images `exhaust_flame_review.png` (dark over light), `_dark.png`, `_light.png` (4x nearest-neighbour, next to car_iso direction 12). Row added to `art-archive/README.md`. Rules check (`check_sprite_rules.py`; its 128 x 128 size test fails only because this sprite is 128 x 96): transparent corners, alpha only 0 or 255, 18 colours.

**Problems, reported not regenerated:** (1) the model drew a grey metal pipe (a tailpipe) at the plume's base, which the game does not want (the exhaust is on the car); (2) the plume points to the upper right, not the lower left asked for, a mirror and a turn away from what the prompt said; (3) the plume is one organic shape, so the flicker will need a script (mirror and shade shift). Good: palette is orange, yellow, pale core, no red, hard edges, clean selective outline, reads well at car scale. Free fixes proposed, no PixelLab: erase the grey pipe pixels by script and give the flame's base a clean tip; turn or mirror it as needed when making the 16 directions.

- 2026-10-21, in-progress → in-qa: Flame sample ready for the board alone, no QA agent
- 2026-10-21, in-qa → in-progress: LGTM
