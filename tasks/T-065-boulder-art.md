---
id: T-065
title: Art: crashed meteor boulders
status: done
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

**Blocked until T-019 (the map's placeholder boulders) is done.**

The boulders that make up the obstacle patterns, as Visual style, Decisions describes them: dark rock with glowing cracks, 3 units across (Level design, Decisions). Make a few variants and swap them in for T-019's placeholders. The kaiju's landed meteors use the same boulders (T-035).

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. Real-world things are inspiration only: no real logos, no copies of existing characters. Details the docs leave open (directions, frame counts, variants, sizes) are this agent's proposal, written in the result notes for the board to judge (Visual style, Decisions).

**Sample first (board's go for one sample, 2026-10-13):** generate **one** boulder (one variant, one PixelLab call or the fewest calls one sprite needs) and stop. Before calling, write the planned call(s), settings and expected cost in the result notes, and the balance. After the sample, report back with the sprite (enlarged, on dark and light backgrounds) and wait: the Project Lead shows it to the board. Only after the board approves the sample, and gives the go for the rest, do you make the remaining variants from it and swap them in. Free script fixes (cleanup, palette, outline) come before any extra paid call.

Use the existing client, `game/tools/pixellab_client.py`. Record every call with its prompt, settings and cost, and the balance before and after. One round of generation only: don't regenerate; report problems instead. The board judges the result.

This art task swaps its art in for the placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass)
- [x] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass)
- [x] A screenshot shows the final boulders in the obstacle patterns (QA: pass)
- [x] The drawn boulders match their 3-unit collision circles: T-019's tests still pass (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

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
- **Problem 1, the shape:** it came out as a tall, smooth **egg** rather than a crashed, jagged meteor boulder. It is about as tall as it is wide (the rock alone is about 100 px tall, on a 126 px wide footprint), so in the game it would stand high above the car and could hide it more than a low rock.
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

**Asset Generation Agent, 2026-10-13: the second sample (the board's go for exactly one more call)**

The board judged the first sample's shape weak (a tall smooth egg on a stone disc with a magenta edge, few cracks) but liked the colours and technique, and gave the go for exactly **one** more PixelLab call: a low, wide, jagged crashed meteor rock lying directly on the ground, no base, more and finer glowing cracks. No other variants, no swap into the game yet.

### Planned call (written before calling)

- **Endpoint:** `POST /create-image-bitforge` (direct). PixelLab's OpenAPI schema confirms it takes a `style_image` with a `style_strength` (0 to 100) and a `negative_description`, up to 200 x 200. The cleaned first sample (`art-archive/T-065/boulder_sample.png`, 30 colours) goes in as the style image, so its colours and pixel technique carry over. Style strength **35** (my choice: enough to carry the palette, low enough not to copy the egg shape and disc). No `color_image` (a forced palette could also pull back the disc's colours; `reduce_palette.py` handles the colour count for free afterwards).
- **Canvas (my proposal):** 160 x 128. A 3-unit footprint at about 40 px per unit is about 120 x 60 px in the 2:1 isometric view; a low rock needs much less height than the 160 x 160 frame gave the egg.
- **Prompt:** "a low wide jagged crashed meteor rock lying directly on the ground, a flat irregular slab of broken dark navy-purple and charcoal rock, much wider than tall, sharp angular edges and chipped facets, split open by heat with many fine branching glowing neon magenta-pink cracks with white-hot cores and small stepped glow, isometric 3/4 view from above, no base, no platform, no pedestal, no disc, no ground shadow, no text, night-time neon cyberpunk game sprite, retro pixel art, hard pixel edges"
- **Negative description:** "base, pedestal, platform, plinth, disc, stone ring, crater rim, pebbles, tall, egg, smooth round boulder, ground shadow, text"
- **Settings:** `image_size` 160 x 128, `isometric: true`, `no_background: true`, `view: "high top-down"`, `outline: "selective outline"`, `shading: "detailed shading"`, `detail: "highly detailed"`, `text_guidance_scale: 8`, `style_strength: 35`, `style_image` = the first sample (base64 PNG). HTTP read timeout 600 s (the client's `HTTP_TIMEOUT_SECONDS`).
- **Expected cost:** about 1 generation.
- **Balance before:** 4955 of 5000 subscription generations, USD credits $0.00.
- Output: `art-archive/T-065/boulder_sample2_raw.png` (+ record), cleaned to `boulder_sample2.png`. One call only; not regenerated whatever comes out.

**Rejected request (no image, not charged):** the first submission at 20:54 UTC was refused by PixelLab's input check, HTTP 500 `style_image must be size (128, 160), not torch.Size([160, 160])`: bitforge needs the style image the same size as the canvas. No image came back, `usage` null (logged in `game/art/pixellab-generation-log.jsonl` as `result: error`), balance still 4955 right after. Fix (free): the first sample cropped to 160 x 128 by removing only empty rows (rows 0 to 11 and 140 to 159 are fully transparent; no pixels lost): `art-archive/T-065/boulder_sample2_style_input.png`. The same request is then sent once with that style image; everything else unchanged. This is still the board's one generation, since the refused request produced nothing and cost nothing.

### The call made

| # | Endpoint | Prompt and settings | Cost (`usage`) | Output |
| --- | --- | --- | --- | --- |
| - | `POST /create-image-bitforge` (20:54 UTC) | As planned, style image 160 x 160 | refused (HTTP 500 input check), `usage` null, 0 generations | none |
| 2 | `POST /create-image-bitforge` (direct, job id `null`) | Exactly the prompt, negative description and settings planned above, style image `boulder_sample2_style_input.png` (record: `art-archive/T-065/boulder_sample2_raw.json`; log: `game/art/pixellab-generation-log.jsonl`) | 1 generation | `art-archive/T-065/boulder_sample2_raw.png`, 160 x 128 RGBA |

- **Balance:** before 4955 of 5000; after the refused request 4955; right after the call 4955 (lag); about a minute later **4954**. USD credits $0.00 throughout. Cost of this round: **1 generation**. Task total so far: **2 generations** (4956 to 4954). Nothing regenerated.
- **Resources consulted:** `docs/visual-style.md`, `docs/extended-narrative.md`, `docs/level-design.md`, this task (the board's feedback on the first sample), the first sample itself, PixelLab's OpenAPI schema for `/create-image-bitforge` (`style_image`, `style_strength`, `negative_description`, 200 x 200 maximum).

### Free cleanup

- Raw: transparent background, 0 semi-transparent pixels, **37 colours**, plus two thin 1-pixel dark lines running out left and right from the rock (like a ground line) and five small loose bits (floating magenta specks, grey pebbles) not touching the rock, which widened the sprite to the canvas edge (bounding box 0,10 to 157,115).
- A one-off cleanup peeled the thin lines away (41 pixels) and removed the five detached bits (157 pixels), then `reduce_palette.py reduce` cut the palette to **30**: `art-archive/T-065/boulder_sample2.png` (+ `.json`, which describes each step). No new pixels drawn, no new colours. The raw file is kept for comparison.
- Sprite check, `python game/tools/check_sprite_rules.py art-archive/T-065/boulder_sample2.png --size 160`: PASS transparent corners, PASS 0 semi-transparent, PASS 30 colours, 8185 opaque pixels, bounding box 22,10 to 145,105 (124 x 96 px). The frame-size line reports FAIL only because the tool checks square frames and this canvas is 160 x 128 as planned.

### Previews (for the board)

- `art-archive/T-065/boulder_sample2_preview.png`: the cleaned second sample, 4x nearest-neighbour, dark and light side by side.
- `art-archive/T-065/boulder_sample2_raw_preview.png`: the raw second sample the same way.
- `art-archive/T-065/boulder_samples_compare.png`: first sample (left) and second (right), 4x, dark row on top, light row below, bottoms lined up.

### Honest judgement (the board decides)

- **Fixed:** no disc, pedestal or plinth; the rock stands directly on the ground. Same dark navy-purple rock and magenta crack hue, clean hard pixels, dark selective outline.
- **Problem 1, the shape:** it came out as a **boxy block**, like a loaf or a stone crate with rounded corners, not a jagged crashed meteor. It is somewhat lower than the egg (about 124 x 96 px against the egg's rock at about 126 x 100 on a disc), but still far from "low and wide": the box's vertical faces take most of its height, so it could still hide the car behind it.
- **Problem 2, the cracks are worse, not better:** only one branching crack on one face, flat magenta with no white-hot core and no stepped glow. The first sample's glowing cracks, which the board liked, did not carry over; the style image carried the rock colours but not the glow. The surface is mostly grey speckle texture.
- **Problem 3, footprint:** its ground outline is a skewed rectangle rather than a roughly round 3-unit footprint, so it would match the round collision circle less well than the first sample's disc did.
- Overall I think it is **weaker than the first sample**: it fixed the base but lost the glow, and the shape is a block rather than a rock.
- Not fixable for free without redrawing. Cheapest options for the board: (a) keep the first sample and accept the egg and its disc; (b) a hand edit of the first sample by the board (for example removing the disc), which costs nothing; (c) another paid call only on the board's explicit go, for example pixflux (which drew the better glow) with this round's no-base wording, instead of bitforge with a style image.

### Files (this round)

- Created: `art-archive/T-065/boulder_sample2_style_input.png`, `boulder_sample2_raw.png` + `.json`, `boulder_sample2.png` + `.json`, `boulder_sample2_preview.png`, `boulder_sample2_raw_preview.png`, `boulder_samples_compare.png`
- Changed: `game/art/pixellab-generation-log.jsonl` (2 entries: the refused request and the call), `art-archive/README.md` (T-065 rows), this task file
- No other variants made, nothing swapped into the game. Status stays `in-progress`. No code changed this round. Documents affected: none beyond the earlier `game/README.md` note.

**Asset Generation Agent, 2026-10-13: free fix of the first sample (no PixelLab call)**

The board prefers the first sample and rejected the second. It asked for a free script fix only: remove the first sample's stone disc, pebbles and magenta edge, keep only the rock, and give its bottom a clean dark outline. No PixelLab call was made (balance unchanged at 4954 of 5000; task total still 2 generations). No other variants, nothing swapped into the game.

### How it was made

- Tool: `python game/tools/remove_boulder_base.py build` (new; tests `game/tools/test_remove_boulder_base.py`; `check` confirms the committed sprite matches a fresh build).
- Rows 0 to 80 (above the disc) are kept byte-identical. From row 81 down, the rock's lower edge is traced along its own dark outline (colour 3,3,2) with rays guided by a rounded curve; points that land on disc tile lines or cracks fall back to their neighbours, and the lower right edge (rows 87 to 99), where the disc behind hides the outline, follows the rock's own dark rim pixels read off the sample. Everything outside the traced edge (the disc, its pebbles, the magenta rim) becomes fully transparent: 3020 pixels.
- New bottom edge: every rock pixel below row 81 that touches the outside is set to the sprite's own outline colour (3,3,2): 64 pixels; 2 single-pixel spurs removed. Where the bottom crack used to run on into the disc, the edge is closed with a short curve in that same outline colour.
- Colours: 30 before, 30 after, 0 new. Canvas **kept at 160 x 160**, with the rock where it was (bounding box 32,16 to 130,119, 99 x 104 px), so it lines up with the first sample. Record: `art-archive/T-065/boulder_sample_nobase.json`.
- Sprite check, `python game/tools/check_sprite_rules.py art-archive/T-065/boulder_sample_nobase.png --size 160`: all PASS (160 x 160, transparent corners, 0 semi-transparent, 30 colours, 7693 opaque pixels).
- Python tool tests: 156 OK.

### Previews (for the board)

- `art-archive/T-065/boulder_sample_nobase_preview.png`: the cleaned rock, 4x nearest-neighbour, dark and light side by side.
- `art-archive/T-065/boulder_sample_nobase_compare.png`: original first sample (left) and cleaned (right), 4x, dark row on top, light row below.
- `art-archive/T-065/boulder_sample_nobase_car_scale.png`: the cleaned rock next to the final car (frame 4 of `game/art/car/car_iso.png`) at the car's game scale (32 art px per unit), both 3x. The rock's width is fitted to the 3-unit collision circle in the isometric view (3 x 32 x sqrt 2, about 136 car px; the rock is drawn at 1.37x its own pixels, so its enlarged pixels are slightly uneven in this picture only). The thin cyan ellipse is the 3-unit footprint. This draw scale is my proposal; it is set for real at the swap-in.

### Honest judgement (the board decides)

- **Good:** the disc, pebbles and magenta rim are fully gone; the bottom reads as a clean rounded dark edge matching the rest of the outline; the glowing cracks, colours and shading are untouched. It reads as one solid glowing rock on both backgrounds, and without the disc it no longer looks like a plinth.
- **Still there:** it is the same tall egg shape. At game scale, with its width matched to the 3-unit circle, the rock stands about as tall as it is wide (about 143 car px), roughly twice the car's on-screen height, so it would hide a car driving behind it. If that is too tall, a free option is to draw it smaller than the collision circle, or, at a cost, a new shape.
- **Small flaws:** the first sample already had 57 fully transparent pixels inside the rock (mostly in the crack glow; PixelLab's background removal), which show as dark or light specks against the ground. Left as they were, since the board asked for everything else to stay identical; filling them with their neighbours' colours would be a free fix if the board wants it. There is also a tiny chip in the lower left edge (around x 35, y 96) where the original outline steps in.

### Files (this round)

- Created: `game/tools/remove_boulder_base.py`, `game/tools/test_remove_boulder_base.py`, `art-archive/T-065/boulder_sample_nobase.png` + `.json`, `boulder_sample_nobase_preview.png`, `boulder_sample_nobase_compare.png`, `boulder_sample_nobase_car_scale.png`
- Changed: `art-archive/README.md` (T-065 rows), `game/README.md` (tool note), this task file
- Status stays `in-progress`. Documents affected: `game/README.md` (tool note). Visual style unchanged.

**Asset Generation Agent, 2026-10-13: the two approved variants, swapped in (no PixelLab call)**

The board approved two samples as the boulder variants: `art-archive/T-065/boulder_sample_nobase.png` (the first sample without its disc) and `art-archive/T-065/boulder_sample2.png` (the low, boxy second sample). No PixelLab call this round: balance unchanged at **4954 of 5000**, task total **2 generations** (one per sample the board allowed).

Before starting, current `master` was merged into the branch (`git merge master`): automatic, **no conflicts** (it brought T-034's see-through buildings, T-117's drift marks, T-119 and others).

### Game-ready art (`game/art/boulders/`)

| File | Made from | How |
| --- | --- | --- |
| `boulder_a.png` (+ `.json`) | `art-archive/T-065/boulder_sample_nobase.png` | Pixel for pixel the approved sprite (160 x 160). History: PixelLab `/create-image-pixflux` (1 generation) -> `reduce_palette.py` (48 -> 30 colours) -> `remove_boulder_base.py` (disc removed) |
| `boulder_b.png` (+ `.json`) | `art-archive/T-065/boulder_sample2.png` | The approved sprite with 32 fully transparent rows added on top (160 x 128 -> 160 x 160, so every boulder frame is the same size and passes the sprite check); no rock pixel changed. History: PixelLab `/create-image-bitforge` with style image (1 generation) -> one-off stray-pixel cleanup -> `reduce_palette.py` (37 -> 30) |
| `boulder_a_mirror.png`, `boulder_b_mirror.png` (+ `.json`) | the two above | **Extra variants (free):** the same pixels flipped left to right. The board can drop them: `python game/tools/build_boulder_art.py build --no-mirrors` rewrites `boulders.json` with only a and b (then delete the two mirror files) |
| `boulders.json` | all four | The variant list the map reads: texture, opaque box and convex outline of each |

- Made by `python game/tools/build_boulder_art.py build` (new; `check` confirms the committed files match a fresh build; tests `game/tools/test_build_boulder_art.py`, 10). Each `.json` record names its archive source, the PixelLab call and every cleanup script. The archive copies are kept unchanged (`art-archive/README.md` has a row saying they are now the sources of game art).
- **Sprite check**, `python game/tools/check_sprite_rules.py game/art/boulders/<file>.png --size 160`, all four: **all PASS** (160 x 160, transparent corners, 0 semi-transparent pixels, 30 colours; a and a_mirror 7693 opaque pixels, b and b_mirror 8185).

### Swapped in

- `scripts/level/mvp_map.gd`: in the isometric view (the run) every boulder, the pattern copies' **and** the kaiju's landed meteor boulders (`add_meteor_boulder`, T-097) and the meteor challenge boulders (T-035, off in the MVP), is a `Sprite2D` under the map's new `BoulderSprites` node, nearest filtering, drawn in screen pixels like the ground tiles. The flat view keeps the placeholder circles. Bodies, collision circles, sizes, placement and the placement checks are untouched.
- **Variant per boulder:** a hash of the boulder's centre (to a hundredth of a unit), so the same boulder always gets the same variant, every map and every run. The 96 map boulders use all four variants, roughly evenly (the demo run counted a 27, a_mirror 22, b 22, b_mirror 26, with one meteor boulder added).
- **Size (my proposal, as before):** each sprite's opaque width equals the 3-unit collision circle's on-screen width (3 x 16 x sqrt 2 = 67.9 screen px), centred on the circle, with its lowest opaque pixel on the circle's front edge. Variant a: scale 0.686, about 68 x 71 screen px (as tall as it is wide). Variant b: scale 0.547, about 68 x 52 screen px.
- **Depth order:** buildings are now spaced 3 apart in z (`BUILDING_Z_STEP`, was 2), so each gap has two levels. A boulder gets a z once, when placed: under the lowest building that covers it (behind it and overlapping on screen), else over every building. The car (`car_z_index`) goes under any boulder it is behind (smaller x + y) and overlaps on screen, and otherwise over boulders at the same level (tree order). Drift marks stay at z 0 under the boulders (T-117's tests pass). `map_building.gd` got `iso_silhouette()` (the outline whatever the view) so boulders can be ordered at build time; its behaviour is unchanged. Boulders do not fade (only buildings do; nothing asked for it).

### Screenshots (repo-root `screenshots/` in the worktree, git-ignored)

- `C:\solid-carbide-worktrees\T-065\screenshots\T-065_boulders_behind.png`: a run started from the main menu (zoom 20, the widest), the boulders in the obstacle patterns around the crossing at 27, -54, one meteor boulder, a boulder correctly hidden behind a building at the bottom right; the car just behind a variant-b boulder (car z 37, under the boulder at 38).
- `C:\solid-carbide-worktrees\T-065\screenshots\T-065_boulders_front.png`: the same with the car in front of the pattern.
- `C:\solid-carbide-worktrees\T-065\screenshots\T-065_boulders_behind_crop3x.png`, `..._front_crop3x.png` and `T-065_boulders_crops_side_by_side.png`: 220 x 150 crops around the car, enlarged 3x nearest-neighbour (behind left, in front right).
- Fixtures: `game/tests/fixtures/boulder_art_behind.tscn`, `boulder_art_front.tscn` (`boulder_art_demo.gd`); commands in `game/README.md`.

### Tests

- New `tests/unit/test_boulder_art.gd` (10 tests): one sprite per boulder, art files 160 x 160, variants stable and all used, drawn width and place against the collision circle, nearest filtering and the flat view, collision circles unchanged (radius 1.5 units), meteor boulders and meteor challenge boulders get sprites, a boulder behind a building drawn under it, the car under a boulder it is behind and still over the buildings below.
- T-019's tests (`test_mvp_map.gd`, `test_mvp_map_no_challenges.gd`, `test_mvp_map_ground.gd`), the collision tests (`test_car_collisions.gd`), T-034's (`test_see_through_map.gd`) and T-117's (`test_drift_marks.gd`): pass unchanged.
- Full GUT suite: **418 of 418 pass** (42 scripts; the one warning, "Ignoring Inner Class TestRoom", was there before). Python tool tests: `game/tools` **166 OK**, `tools` **115 OK**.

### Honest judgement (the board decides)

- **Works:** the boulders read as dark rocks with glowing magenta cracks on the asphalt, clearly better than the placeholders; four variants break up the repetition; the depth order looks right in the screenshots (a boulder behind a building is hidden by it, the car behind a boulder is hidden by it).
- **Variant a** still stands tall (as tall as wide), so it hides the car more than b; at its 0.69 scale it keeps its glow well.
- **Variant b** is drawn at 0.55 of its pixels, the smallest scale; with nearest filtering some art pixels are dropped, so its grey speckle texture looks noisy and its single crack is thin. Its flat magenta crack glows less than a's, so a and b look like two different kinds of rock. Free options if that bothers the board: draw b a little larger than its circle, or drop b (and its mirror) from `boulders.json`.
- **Mirrors:** mirrored shading puts the light on the other side; Visual style fixes no light direction, so I think it passes, but it is the board's call.
- The 57 transparent specks inside variant a (from the first sample) are still there, as before.
- The drift prototype's test room boulder (T-033) keeps its placeholder circle: it is not on the MVP map and this task did not ask for it.

### Files (this round)

- Created: `game/art/boulders/` (4 sprites, their `.import` files, 4 records, `boulders.json`), `game/tools/build_boulder_art.py`, `game/tools/test_build_boulder_art.py`, `game/tests/unit/test_boulder_art.gd`, `game/tests/fixtures/boulder_art_demo.gd`, `boulder_art_behind.tscn`, `boulder_art_front.tscn`
- Changed: `game/scripts/level/mvp_map.gd` (boulder sprites, z step 3, the car under covering boulders), `game/scripts/level/map_building.gd` (`iso_silhouette()`), `game/README.md` (new section "The boulders (T-065)", the draw order, the tool note), `art-archive/README.md`, this task file
- Documents affected: `game/README.md`. Visual style unchanged (the variants and sizes are proposals in these notes for the board to judge).
- 2026-10-13, in-progress → in-qa: Both approved variants (plus free mirrored copies) game-ready and swapped in; no PixelLab call (4954 of 5000, task total 2). Sprite check PASS on all four; GUT 418/418; Python 166 + 115 OK.

**QA/Integration Agent, 2026-10-13: QA round 1, all criteria pass**

1. **Sprites: pass.** `python game/tools/check_sprite_rules.py game/art/boulders/<file>.png --size 160` on all four (`boulder_a`, `boulder_a_mirror`, `boulder_b`, `boulder_b_mirror`): all PASS (160 x 160, transparent corners, 0 semi-transparent, 30 colours). A separate check of every pixel (not only the corners): alpha only 0 or 255, every edge pixel transparent, 30 opaque colours each. `build_boulder_art.py check` and `remove_boulder_base.py check`: the committed files match a fresh build.
2. **Record: pass.** `game/art/pixellab-generation-log.jsonl` has three T-065 entries: the pixflux sample (20:01 UTC, 1 generation), the refused bitforge request (20:54, HTTP 500 input check, `usage` null) and the bitforge call (20:55, 1 generation), each with its prompt. The raw records (`art-archive/T-065/boulder_sample_raw.json`, `boulder_sample2_raw.json`) hold the full request settings (size, isometric, view, outline, shading, detail, guidance, style strength, negative description) and `usage`; the game-ready records name their source, the call and every cleanup script. The result notes give the plan, cost and balance before and after each call (4956 -> 4955 -> 4954 of 5000, $0.00). Exactly two paid calls, matching the board's go for one sample (timeline on `master`, 2026-10-13, "T-065 ... gets the PixelLab go for one sample boulder") and its go for exactly one more call (same day, "the board also gave the go for one more PixelLab call on T-065"); the later rounds (disc removal, swap-in) made no call. Nothing was regenerated beyond what the board allowed.
3. **Screenshot: pass.** `C:\solid-carbide-worktrees\T-065\screenshots\T-065_boulders_behind.png` and `_front.png` show a run's isometric view with the final sprites in the obstacle patterns (both variant a, the tall glowing rock, and variant b, the boxy one), the car behind and in front of a boulder, and a boulder behind a building drawn under it; the 3x crops show the depth order up close. Looks: variant b's single thin crack and grey speckle read noisy at its 0.55 scale, and a and b look like two different rocks, as the agent's notes say; that is for the board to judge, not a fail.
4. **Collision circles: pass.** On the branch (diff against the merge base with `master`), no layout data, scene or existing test changed; in `mvp_map.gd` the only removed lines are the old z-step comment and the two `2 *` z expressions (now `BUILDING_Z_STEP`, 3). Bodies, radii and placement code untouched. `test_boulder_art.gd` checks each sprite's opaque width equals the circle's on-screen width (3 x 16 x sqrt 2), centred, standing on the circle's front edge, and collision radius 1.5 units. T-019's tests (`test_mvp_map.gd`, `test_mvp_map_no_challenges.gd`, `test_mvp_map_ground.gd`) and `test_car_collisions.gd` pass unchanged. The z-step change: T-034's `test_see_through_map.gd` and T-117's `test_drift_marks.gd` pass unchanged; with 12 buildings the top z is 38, well inside Godot's range, and the only fixed z elsewhere (trick popups, 100) is relative to the car's view, so it is not affected.
5. **Tests: pass.** Full GUT suite, `bash game/tools/run_tests.sh`: 418 of 418 pass, 42 scripts, `TESTS PASSED`, exit 0 (the one warning, "Ignoring Inner Class TestRoom", was there before). Python: `game/tools` 166 OK, `tools` 115 OK.

Also checked: the branch merges into current `master` (with T-120) without conflicts (`git merge-tree`). Godot's line-ending-only `.import` changes in the worktree were left uncommitted.
- 2026-10-13, in-qa → needs-playtest: QA round 1: all five criteria pass (sprites, record, screenshot, collision circles, GUT 418/418, Python 166 + 115 OK).
- 2026-10-13, needs-playtest → done: LGTM (board playtest, 2026-10-13)
