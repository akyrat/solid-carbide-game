---
id: T-065
title: Art: crashed meteor boulders
status: in-progress
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-019]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-003-pixellab-test-generation.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/level-design.md, tasks/T-019-build-mvp-map.md]
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

**Blocked until T-019 (the map's placeholder boulders) is done.**

The boulders that make up the obstacle patterns, as Visual style, Decisions describes them: dark rock with glowing cracks, 3 units across (Level design, Decisions). Make a few variants and swap them in for T-019's placeholders. The kaiju's landed meteors use the same boulders (T-035).

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. Real-world things are inspiration only: no real logos, no copies of existing characters. Details the docs leave open (directions, frame counts, variants, sizes) are this agent's proposal, written in the result notes for the board to judge (Visual style, Decisions).

**Sample first (board's go for one sample, 2026-10-13):** generate **one** boulder (one variant, one PixelLab call or the fewest calls one sprite needs) and stop. Before calling, write the planned call(s), settings and expected cost in the result notes, and the balance. After the sample, report back with the sprite (enlarged, on dark and light backgrounds) and wait: the Project Lead shows it to the board. Only after the board approves the sample, and gives the go for the rest, do you make the remaining variants from it and swap them in. Free script fixes (cleanup, palette, outline) come before any extra paid call.

Use the existing client, `game/tools/pixellab_client.py`. Record every call with its prompt, settings and cost, and the balance before and after. One round of generation only: don't regenerate; report problems instead. The board judges the result.

This art task swaps its art in for the placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass / fail)
- [ ] A screenshot shows the final boulders in the obstacle patterns (QA: pass / fail)
- [ ] The drawn boulders match their 3-unit collision circles: T-019's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the look. One round only, so problems are reported rather than regenerated.

## Result notes

**Asset Generation Agent, 2026-10-13: the sample (one boulder)**

### Planned call (written before calling)

The board's go covers one sample boulder only. Plan: **one** PixelLab call, `POST /create-image-pixflux` (direct endpoint, the same one that made the approved car), saved to `art-archive/T-065/` (not game-ready until the board approves it).

- **Size proposal (mine, for the board to judge):** a 160 x 160 canvas. A 3-unit circle seen in the game's 2:1 isometric view is about 136 x 68 art pixels at the car art's density (32 art px per unit, `car_iso.json`), or about 170 x 85 at 40 px per unit; the rock rises above its footprint, so 160 x 160 leaves room for the rock's height. The exact draw scale is fitted to the 3-unit collision circle when the art is swapped in (as the car's 32 px per unit was), not now.
- **Crack colour proposal (mine):** the docs say only "glowing cracks"; I ask for neon magenta-pink cracks with a white-hot core (the palette's pink accent, not Redgull red).
- **Prompt:** "a large crashed meteor boulder, a chunky rounded lump of dark charcoal and deep navy-purple rock, cracked all over with bright glowing neon magenta-pink cracks with white-hot cores and small stepped glow around them, sitting on the ground, roughly round footprint, seen from above in isometric 3/4 view, no ground shadow, no text, night-time neon cyberpunk game sprite, retro pixel art, hard pixel edges"
- **Settings:** `image_size` 160 x 160, `isometric: true`, `no_background: true`, `view: "high top-down"`, `outline: "selective outline"`, `shading: "detailed shading"`, `detail: "highly detailed"`, `text_guidance_scale: 8` (as the approved car, minus `direction`, which a round rock does not need). HTTP read timeout 600 s (the client's).
- **Expected cost:** 1 generation (the 128 x 128 car cost 1; the larger canvas could cost a little more).
- **Balance before:** 4956 of 5000 subscription generations (Tier 2: Pixel Artisan), USD credits $0.00.

### The call made

| # | Endpoint | Prompt and settings | Cost (`usage`) | Output |
| --- | --- | --- | --- | --- |
| 1 | `POST /create-image-pixflux` (direct, job id `null`) | Exactly the prompt and settings planned above (record: `art-archive/T-065/boulder_sample_raw.json`; log: `game/art/pixellab-generation-log.jsonl`) | 1 generation | `art-archive/T-065/boulder_sample_raw.png`, 160 x 160 RGBA |

- **Balance:** before 4956 of 5000 generations; right after the call 4956 (PixelLab's balance lags); a minute later **4955**. USD credits $0.00 throughout. Total cost: **1 generation**. One round only; nothing regenerated.
- **Resources consulted:** `docs/visual-style.md`, `docs/extended-narrative.md`, `docs/level-design.md`, this task, `tasks/T-019-build-mvp-map.md`, the approved car's record and sheet layout (`game/art/car/car_sw_front.json`, `car_iso.json`), plus `tasks/README.md`, `tasks/T-003...`, `tasks/T-014...` and `game/README.md`.

### Free script cleanup

- Raw sprite: transparent background, 0 semi-transparent pixels, but **48 colours**. `python game/tools/reduce_palette.py reduce` (new, tested: `game/tools/test_reduce_palette.py`) merged the least-used colours into their nearest neighbours down to **30**, no new colours, shape and alpha unchanged: `art-archive/T-065/boulder_sample.png` (+ `.json`). Side by side the two look the same.
- Sprite check: `python game/tools/check_sprite_rules.py art-archive/T-065/boulder_sample.png --size 160`: all PASS (160 x 160, transparent corners, 0 semi-transparent, 30 colours, 10713 opaque pixels, bounding box 17,16 to 142,137). The raw file fails only the colour line (48).
- No outline or stray-pixel fix was needed.

### Previews (for the board)

- `art-archive/T-065/boulder_sample_preview.png`: the cleaned sample, 4x nearest-neighbour, dark and light background side by side.
- `art-archive/T-065/boulder_sample_raw_preview.png`: the raw generation the same way.

### Honest judgement (the board decides)

- **Good:** right palette (dark navy-purple rock, neon magenta-pink cracks with white-hot cores and stepped glow, nothing near Redgull red), clean hard pixels, a dark selective outline on the rock, detailed shading. It reads clearly on both backgrounds.
- **Problem 1, the shape:** it came out as a tall, smooth **egg** rather than a crashed, jagged meteor boulder. It is about as tall as it is wide (the rock alone is about 95 px tall), so in the game it would stand high above the car and could hide it more than a low rock.
- **Problem 2, the base:** PixelLab added a flat stone **disc with pebbles** under the rock, like a pedestal or a crater rim, with a thin magenta edge instead of the dark outline. On the asphalt it would look like a round plinth. The disc is about 126 x 52 px, which happens to be close to the 3-unit collision circle at about 42 px per unit, so it does show the footprint; whether that is wanted is the board's call.
- **Problem 3, the cracks:** a few big branching cracks with a lot of plain rock between them; fine, but more like a cracked egg than a rock split open by heat.
- Not fixable for free without inventing new pixels: removing the disc or flattening the rock would mean redrawing. Cheapest next steps if the board wants changes: (a) accept as is; (b) the board's go for one more pixflux call with a prompt asking for a low, wide, jagged rock with no base (for example "low wide jagged irregular rock lying directly on the ground, no base, no platform"), possibly at 160 x 128; or (c) use this sprite as the style reference (`create-image-bitforge` style image) for that new call so the colours and cracks carry over.
- **Size proposal:** keep the 160 x 160 frame; when swapped in, draw it at the scale where the disc (or the rock's footprint) matches the 3-unit circle, about 42 art px per unit, like the car's sheet was fitted to 32.

### Files

- Created: `art-archive/T-065/boulder_sample_raw.png` + `.json` (PixelLab record), `boulder_sample.png` + `.json`, `boulder_sample_preview.png`, `boulder_sample_raw_preview.png`
- Created: `game/tools/reduce_palette.py`, `game/tools/test_reduce_palette.py` (Python tool tests: 146 OK)
- Changed: `game/art/pixellab-generation-log.jsonl` (1 entry), `art-archive/README.md` (T-065 rows), `game/README.md` (the palette tool, in "Generating art with PixelLab"), this task file
- Not done yet (waiting for the board): the other variants, the swap into the game, the screenshot. Status left `in-progress`.
- Documents affected so far: `game/README.md` (tool note). Visual style unchanged.
