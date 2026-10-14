---
id: T-072
title: Art: enemy hits and deaths, coins, and car damage
status: in-progress
from: project-lead
to: asset-generation
lead: Enemies
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-044, T-036]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-003-pixellab-test-generation.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/enemies.md, tasks/T-044-minions.md, tasks/T-036-run-scene-and-state.md]
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

**Blocked until T-044 (minions and coins) and T-036 (the run, where the car takes damage) are done.**

Effects from Visual style, Decisions: an enemy being hit, an enemy dying, the coins enemies drop, and the car taking damage. Hook each to the moment it belongs to (T-044's hit, death and coin drop, the run's damage function) and swap in for any placeholders.

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. Real-world things are inspiration only: no real logos, no copies of existing characters. Details the docs leave open (directions, frame counts, variants, sizes) are this agent's proposal, written in the result notes for the board to judge (Visual style, Decisions).

Use the existing client, `game/tools/pixellab_client.py`. Record every call with its prompt, settings and cost, and the balance before and after. One round of generation only: don't regenerate; report problems instead. The board judges the result.

This art task swaps its art in for the placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass / fail)
- [ ] A screenshot sequence shows a minion being hit, dying and dropping a coin, and the car taking damage (QA: pass / fail)
- [ ] T-044's and T-036's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the look. One round only, so problems are reported rather than regenerated.

## Result notes

Written by the agent when it finishes.

### Sample round (coin only; board's go for the sample, 2026-10-14)

**Proposal for the full set (not generated):**

| Effect | Frames and size | How | Cost |
|---|---|---|---|
| Coin | 1 still, 32x32 (opaque about 16x21); the placeholder's bob stays in code | PixelLab, the sample below | 1 generation (spent) |
| Enemy hit | 4 frames, 16x16 each, one row: white-hot flash, cyan/pink spark burst, spreading shards, gone. Pop or shrink, no fade | Free script (same method as T-074's particles) | 0 |
| Enemy death | 6 frames, 32x32 each: puff of dust and sparks growing then breaking up into pixels, with a small flash | Free script first; if the board finds it too plain, 1 PixelLab call (pixflux) for a 32x32 key frame, 1 generation | 0 (or 1) |
| Car damage | 4 frames, 48x48 each, over the car: red-free cyan/white spark burst plus a few debris pixels (no Redgull red) | Free script | 0 |

Why script: these are short, abstract shapes with a few colours, and a script keeps the exact palette, no anti-aliasing and no semi-transparent pixels, as with the heart, drift smoke and level-up particles. PixelLab is best at objects with detail (the coin). Full-set estimate: 1 generation spent, 0 more planned (at most 1 more for the death key frame). Nothing hooked into the game yet.

**Planned call for the sample (written before calling):** one `/create-image-pixflux`, 32x32, no background, selective outline, detailed shading, seed 7207, view "high top-down", isometric true, direction south. Cost 1 generation. The balance before was 4919.

**Sample call made (T-072):**
- Prompt: "single gold coin standing upright on its edge seen from a 3/4 isometric angle, round gold disc with a thick dark outline, bright pale yellow shine pixels and darker amber rim, small stepped warm glow, simple pixel art game pickup, no text, no symbols"
- Negative: "text, letters, red, ground, shadow, hand, stack, background". Request: `art-archive/T-072/coin_request.json`.
- Result: `art-archive/T-072/sample/coin_sample.png` and `.json`. Logged in `game/art/pixellab-generation-log.jsonl`.
- Cost: 1 generation. Balance before 4919, after 4918. One call only, no regeneration.
- Check (`game/tools/check_sprite_rules.py ... --size 32`): all PASS: transparent corners, 0 semi-transparent pixels, 23 colours, opaque bounding box (8,6)-(23,26).
- Review image: `art-archive/T-072/coin_review_dark_light_placeholder_left_sample_right.png` (12x, nearest, dark and light backgrounds, placeholder left, sample right).

**Problems seen (not regenerated):**
- No dark outline: the rim is brown/amber, so it will be weaker against the grey asphalt than the placeholder.
- The coin is tilted diagonally and is about 16x21 px, roughly twice the placeholder's size (about 9x11); it needs scaling in the game, or a smaller 16x16 redraw.
- A few grey pixel fragments at the bottom (a stray shadow remnant) that do not belong to the coin. A free script could remove them.
- It is not a clear upright edge-on coin; it reads as a tilted disc, acceptable but not the standing coin the placeholder shows.
- Free fixes before any more paid calls: delete the grey fragments, add a dark outline pass, and downscale or redraw by script.

Status stays in-progress; nothing swapped into the game.

### Final round (board agreed: no more PixelLab calls)

- Total PixelLab use for T-072: the one coin sample call above (1 generation; balance 4919 to 4918). No other call.
- Coin: the sample was fixed by redrawing, not downscaling (a tilted 16x21 coin shrunk to 8x10 turned to mush). `game/art/effects/coin.png`, 10x12, an 8x10 hand-drawn fill in the sample's gold palette plus a dark outline, no grey strays. The old sample stays in `art-archive/T-072/sample/`. Note: art at the game's 32 px per unit is drawn at 0.5, so the sample's 16x21 was in fact close to the placeholder's on-screen size. The 10x12 coin is drawn at scale 1, like the placeholder, so its pixels look chunkier than the world's. If the board wants it consistent, redraw it at about 16x20 and draw it at 0.5.
- Hit (4 frames, 16x16), death (6 frames, 32x32, the minion's light green puff with a white core), car damage (4 frames, 48x48, white/cyan flash, cyan and pink sparks, yellow debris): scripted by `game/tools/build_hit_coin_damage_effects.py`. No red at all (the amber and brown of the coin were nudged until the Redgull-red check passed).
- Hooks (small changes): `Minion.hurt` signal (emitted when a hit leaves it alive); `MinionSpawner` plays the hit and death effects (`play_effect`); `RunState.car_damaged` signal, and `run.gd` plays the car damage effect in the view over the car; `coin_sprite.gd` draws the art. New `scripts/enemies/effect_flipbook.gd`. Behaviour unchanged: effects are visual only and pause with the tree.
- Checks: `python game/tools/build_hit_coin_damage_effects.py check` passes every frame (size, transparent corners, 0 semi-transparent pixels, colours under 30, no Redgull red). GUT: 583 of 583 pass; Python tool tests: 246 OK (1 skipped, pre-existing).
- Review images (enlarged, dark and light): `art-archive/T-072/coin_dark_light_x16.png`, `enemy_hit_dark_light_x10.png`, `enemy_death_dark_light_x6.png`, `car_damage_dark_light_x4.png`. Screenshot sequence (hit, death and coin drop, car damage): `art-archive/T-072/screenshot_sequence_hit_death_coin_damage.png`, frames in `art-archive/T-072/screenshots/`.
- Things to judge: the hit is small (16 px at scale 1, about one unit across) and quick; the death puff is the biggest effect; the car damage flash is big and cyan, covering the car's roof for about 0.1 s.
