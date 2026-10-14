---
id: T-068
title: Art: the minion (light green lizard), walking
status: in-progress
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-044]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-003-pixellab-test-generation.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/enemies.md, tasks/T-044-minions.md]
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

**Blocked until T-044 (the minions, with placeholders) is done.**

**The board's review of the sample (board, 2026-10-14):** the board likes the sample lizard (`art-archive/T-068/raw/minion_se_sample.png`): keep it, colours and all, as the base for everything. It wants it walking on all fours, animated, in 8 directions (5 drawn, 3 mirrored), with **7 walk frames** per direction instead of 4. Next step, with the board's go: the 8 rotations from the sample plus the 7-frame walk in one direction, for the board's review (about 9 generations). Only after the board approves that: the walk in the other 4 drawn directions (about 28 more), then into the game for a playtest. The sample-round "one round only" rule is replaced by these steps; report problems rather than regenerating, unless the board says so.

The MVP minion, as Visual style, Decisions describes it: a light green (not too bright) scaled lizard walking on four legs towards the player. Propose how many directions and walk frames it needs. Swap it in for T-044's placeholder, facing the way it walks.

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. Real-world things are inspiration only: no real logos, no copies of existing characters. Details the docs leave open (directions, frame counts, variants, sizes) are this agent's proposal, written in the result notes for the board to judge (Visual style, Decisions).

Use the existing client, `game/tools/pixellab_client.py`. Record every call with its prompt, settings and cost, and the balance before and after. One round of generation only: don't regenerate; report problems instead. The board judges the result.

This art task swaps its art in for the placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass / fail)
- [ ] A screenshot of a run shows the final minions walking towards the car, facing the way they move (QA: pass / fail)
- [ ] T-044's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the look. One round only, so problems are reported rather than regenerated.

## Result notes

Written by the Asset Generation Agent (2026-10-14). Round 1: SAMPLE ONLY; the board reviews it before the full set.

### Proposal (for the board to judge)

- **Size:** 48 by 48 pixel frames. At 32 art pixels per unit and scale 0.5 the minion is about 1 unit (the car's width) across, so the body is about 30 to 36 art pixels long and fits in 48.
- **Directions:** 8 directions (the 4 screen axes and 4 diagonals) built from **5 drawn** ones: south, south-east, east, north-east, north. The other three (south-west, west, north-west) are mirrors, made by flipping in the game or a free script. A lizard is symmetric, so mirroring is safe.
- **Walk frames:** 4 per direction (two leg-pair swings and two mid-stance frames), looped at about 8 frames per second. 5 x 4 = 20 drawn frames, 32 with mirrors.
- **Method:** the board approves the sample (south-east, one frame). Then one call to /generate-8-rotations-v3 from it gives the other directions of the standing pose; then walk frames per direction by /create-image-pixflux with the approved frame as `color_image`/init image (one call per frame). Check script on each, and free palette reduction if over 30 colours.
- **Planned full set calls and cost (estimate, 1 generation each unless noted):** 1 rotations call (about 2 generations, as the car's was) + 19 pixflux frames (19 generations) = about 21 generations, of the plan's 5000 (usd credits stay 0). Walk-frame consistency may need more; the board decides then.

### Sample: planned call and cost

- 1 call, /create-image-pixflux, 48x48, south-east, view "high top-down" with isometric true, outline "selective outline", shading "detailed shading", detail "highly detailed", no_background, seed 68001. Params file: art-archive/T-068/sample_req.json. Planned cost: 1 generation.

### Sample: result

- Call: /create-image-pixflux, params art-archive/T-068/sample_req.json (prompt and settings inside; record art-archive/T-068/raw/minion_se_sample.json; logged in game/art/pixellab-generation-log.jsonl). Cost 1 generation. Balance before 4919 of 5000, after 4918. One call only.
- File: art-archive/T-068/raw/minion_se_sample.png (48x48). Check script (game/tools/check_sprite_rules.py --size 48): all pass, 21 colours, 0 semi-transparent pixels, transparent corners. No fix needed.
- Review images: art-archive/T-068/sample_review_dark.png, sample_review_light.png, sample_review_dark_light_vs_placeholder.png (8x nearest; the placeholder is cropped from T-044's screenshot, so at the screenshot's scale).
- Problems seen (reported, not regenerated): the green is a saturated yellow-lime, brighter than "light green, not too bright"; it looks like it is rearing on two legs and a front arm, so the four-legged walk does not read; there is no dark selective outline; it faces west-south-west more than south-east. Cheapest next step: a free palette shift towards a softer green, or one more sample with a rewritten prompt, on the board's say-so.
