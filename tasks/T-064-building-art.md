---
id: T-064
title: Art: Tokyo-style buildings for the city blocks
status: in-qa
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-019, T-034]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-003-pixellab-test-generation.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/level-design.md, tasks/T-019-build-mvp-map.md, tasks/T-034-buildings-see-through.md]
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

**Blocked until T-019 (the map) and T-034 (the see-through fade) are done.**

The city's buildings, as Visual style, Decisions describes them: Tokyo-style towers with vertical signs and lit windows, night neon in pink and cyan. They carry none of Redgull's colours or branding. Signs carry no readable words (words would need a text task first). Make enough variants that the blocks don't look repeated, and swap them in for T-019's placeholder buildings. They must keep fading with T-034's see-through behaviour.

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. Real-world things are inspiration only: no real logos, no copies of existing characters. Details the docs leave open (directions, frame counts, variants, sizes) are this agent's proposal, written in the result notes for the board to judge (Visual style, Decisions).

Use the existing client, `game/tools/pixellab_client.py`. Record every call with its prompt, settings and cost, and the balance before and after. One round of generation only: don't regenerate; report problems instead. The board judges the result.

This art task swaps its art in for the placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass / fail)
- [ ] A screenshot of the map shows the final buildings on every block (QA: pass / fail)
- [ ] T-034's tests still pass, and a screenshot with the car behind a building shows the final building faded (QA: pass / fail)
- [ ] No building shows Redgull's red, logo or name (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the look. One round only, so problems are reported rather than regenerated.

## Result notes

### Plan (2026-10-13, planning round: no PixelLab call made, no game file changed)

**The size problem in numbers.** The game's art density is 32 art pixels per unit, drawn at scale 0.5 (the car sheet and the ground atlas both use it; Visual style says "about 40"). With the map's iso projection (`ISO_TRANSFORM`: 1 unit along x or y = 32 x 16 art px, 1 unit up = 32 art px), one 30 x 30 block is a 1920 x 960 px diamond, and the 15-unit placeholder box is 1920 x 1440 px. PixelLab's limits (OpenAPI spec, read 2026-10-13): `/create-image-pixflux` at most 400 px per side (area 400 x 400), transparent background only up to a 200 x 200 area (a blank background above that); `/map-objects` 32 to 400 px per side; `/create-image-pixen` area 512 x 512; `/generate-image-v2` up to 512 x 512 (Pro, cost not published). So one image covers at most about a 6 x 6 unit footprint at the game's density: footprint width + depth <= 12.5 units for a 400 px wide image.

**Options looked at**

1. *One image per block, scaled up* (about 5x): breaks "drawn at its final size, never scaled up"; the buildings would be blurry blocks of 5 x 5 px next to the car. Rejected.
2. *Half density (16 px per unit, drawn at scale 1)*: still 960 px wide per block, too big for one image, and twice as chunky as the car and the ground. Rejected.
3. *Flat front-on facade panels, sheared onto the two visible walls and tiled by a script*: keeps the density and fits any size in 3 or 4 calls, but PixelLab never sees the building in 3D: corners, roofs and vertical signs would be script-drawn and the result looks procedural; seamless tiling of PixelLab facades is not guaranteed. Second choice.
4. **Recommended: several small towers per block, each one PixelLab image at the game's density, assembled by a script.**

**Recommended plan**

- **How a block is filled:** a 4 x 4 grid of towers, each on a **6 x 6 unit** footprint, with 2-unit dark alleys between them (4 x 6 + 3 x 2 = 30), so 16 towers per block and 192 on the map. Each tower is one isometric image at 32 art px per unit, drawn at scale 0.5 like the car and the ground: the 40 (in practice 32) px per unit rule holds exactly; nothing is scaled. The alleys show the dark night colour under the blocks (no ground tiles there, T-103) and absorb PixelLab's imprecise footprints.
- **Generation size:** 384 x 400 px per tower (a 6 x 6 footprint is 384 px wide; the image holds a tower about 6.5 units tall).
- **Height:** a free script makes towers taller by repeating a band of whole floors from the middle of the walls (an isometric tower's walls look the same when moved straight up, so a band of rows can be repeated without new pixels). Proposed heights: **9, 12 or 15 units**, never over 15, so no tower hides more of the road than the placeholder boxes the board has already played with. The fade is unchanged: each block stays one building node, its towers are child sprites (drawn back to front, `texture_filter` nearest, inverse iso transform like the ground tiles), they fade together through the node's `modulate`, `draw_placeholder = false`, and `height_units` = the block's tallest tower. The fade may start slightly early when the car is behind a low tower next to a tall one; `custom_silhouette` (the outline of the block's towers) can tighten that if the board wants. No change to the map's layout data or collisions.
- **How many distinct sprites:** **8 base towers** from PixelLab. Free script variations multiply them: mirroring (x2), a neon swap of the sign and window colours, pink-led or cyan-led (x2; a colour mapping, no new pixels, never towards red), and 3 heights (x3): 96 versions for 192 places. A fixed hash picks them so no two neighbouring towers and no two blocks are the same.
- **Endpoint and settings:** `/create-image-pixflux` (direct; the client already supports it; 1 generation per call at 128 x 128 in T-003, T-014). `image_size` 384 x 400, `isometric: true`, `view: high top-down`, `direction: south-east` (both visible walls toward the viewer, as the placeholder), `outline: selective outline`, `shading: detailed shading`, `detail: highly detailed`, `no_background: true`, `text_guidance_scale` 8, `color_image`: a forced palette of up to 30 colours made by script from approved art only (the ground atlas's navy and purple, the level-up particles' pink, cyan and violet; no Redgull red), `negative_description`: text, letters, words, logo, red, ground, street, car. Prompt along the lines of "narrow Tokyo-style cyberpunk tower at night, lit windows, vertical neon signs with abstract glyph shapes, dark navy and purple walls, pink and cyan neon glow drawn in pixels", varied per base tower only in things the docs allow (sign placement, window pattern, roof equipment). The 7 later calls also use the approved sample's palette as `color_image`.
- **Scripts (free, tested):** a build script that removes the blank background above 200 x 200 (flood fill of the exact border colour from the edges), maps every pixel to the forced palette (<= 30 colours), measures each tower's footprint and wall band, stretches heights, makes the mirrored and colour-swapped versions, lays out all 12 blocks and checks the sprite rules and the not-Redgull-red rule (more than 0.5 from `Hud.HEART_COLOR`, as T-074).
- **Calls and generations:**
  - Sample: **1 call**, one base tower, expected **1 generation** (cost at 384 x 400 is not published; the sample's record shows it). From it the script makes, for free, a mock-up of one whole block (16 towers, heights, mirror, colour swap) for the board's review.
  - Full set after the board approves the sample: **7 more calls**, expected **7 generations**. Total **8 calls, about 8 generations**. Balance recorded before and after each step. If the sample costs more than 2 generations, I stop and report before the full set.

**Risks**

- PixelLab's isometric flag only weakly guides the angle: T-101 found its diagonals flatter than the game's 2:1, and the footprint may not be exactly 6 x 6. The script places each tower by its measured base; the alleys hide small errors, but some towers may look slightly off-angle.
- Background removal above 200 x 200: if PixelLab's blank background matches the outline colour, the flood fill can eat outline pixels; the check and a preview show it.
- Repeating a floor band works only if the wall is regular; a sign that changes along the band repeats visibly (it just reads as a longer sign). If a tower has no clean band, it keeps its generated height.
- Readable words: PixelLab likes to draw letters or kanji-like marks on signs. The prompt and negative prompt ask for abstract shapes, but only the board can judge this; no regeneration in this round.
- Mirroring flips the light side of a tower. If the board dislikes it, drop mirroring (48 versions instead of 96).
- 16 small towers per block reads as dense and grid-like; the alternative (option 3) gives one large building per block but a more procedural look.
- The game uses 32 art px per unit, Visual style says "about 40". This plan keeps 32 so the buildings match the car and ground already in the game.

Nothing is generated until the board gives the go for the sample.

### Sample round, planned call (2026-10-13, written before calling)

The board gave the go for the sample only: exactly one PixelLab call for one tower, plus the free whole-block mock-up. Nothing goes into the game in this round.

- **Balance before:** 4954 of 5000 generations (subscription), 0.00 USD credits.
- **Call:** `POST /create-image-pixflux` (direct) through `game/tools/pixellab_client.py` (HTTP timeout 600 s), output `art-archive/T-064/raw/tower_01.png` with its record JSON. Request body: `art-archive/T-064/tower_01_request.json` (made by `python game/tools/build_buildings.py request`).
- **Prompt:** "a single narrow Tokyo-style cyberpunk skyscraper tower at night, isometric, square footprint, dark navy and purple concrete walls, rows of small lit windows, tall vertical neon sign boards on the corners with abstract glowing shapes and stripes, no letters, pink and cyan neon glow drawn in pixels, rooftop air conditioning units and an antenna, retro pixel art"
- **Negative prompt:** "text, letters, words, kanji, numbers, logo, red, ground, street, road, car, people, sky, background" (the API marks this field deprecated; sent anyway, it may be ignored).
- **Settings:** `image_size` 384 x 400, `text_guidance_scale` 8, `outline` selective outline, `shading` detailed shading, `detail` highly detailed, `view` high top-down, `direction` south-east, `isometric` true, `no_background` true (PixelLab gives a blank, not transparent, background above 200 x 200; the clean script removes it), `seed` 64064.
- **Palette image (`color_image`):** `art-archive/T-064/palette.png`, 29 colours made by `python game/tools/build_buildings.py palette` from approved art only: the 16 navy, purple and grey night shades of `game/art/ground/ground_atlas.png` and the 13 pink, cyan and violet neon colours of `game/art/effects/level_up_particles.png`. Every colour is more than 0.5 from Redgull red.
- **Expected cost:** about 1 generation (the cost at 384 x 400 is not published). If it costs more than 2, I stop and report before anything else.

### Sample round, result (2026-10-13)

**Call made: 1** (`/create-image-pixflux`, request exactly as planned above, first try, no resend). **Cost: 1 generation.** Balance before 4954, after 4953 of 5000 (`GET /balance` showed 4954 straight after the call and 4953 a few minutes later: the known lag). Record: `art-archive/T-064/raw/tower_01.json`, and a line in `game/art/pixellab-generation-log.jsonl`. No further call was made. Nothing was swapped into the game.

**What came back.** One tower, 2 x 2 units of footprint and about 8.6 units of wall, on a flat opaque grey-purple background (as the API documents above 200 x 200). The forced palette held: the raw image already used only the 29 palette colours. The iso angle is the game's 2:1 (the base corners drop 32 px over 64 px), so it lines up with the ground.

**Free steps** (`game/tools/build_buildings.py build`, tests in `game/tools/test_build_buildings.py`, all 151 Python tool tests pass):

- Clean: flood fill of the border background from the edges, palette mapping, specks removed, cropped. `art-archive/T-064/tower_01_clean.png`, 131 x 350: transparent corners, 0 semi-transparent pixels, 29 colours, closest colour to Redgull red 0.535 (> 0.5). `python game/tools/build_buildings.py check` passes; `check_sprite_rules.py` passes every rule except its fixed square frame size, which does not apply to a 131 x 350 building.
- Measured: footprint 2.0 units, wall 8.62 units, floors repeat every 20 px (band rows 178 to 198 used for height changes).
- Variants: 12 versions (mirror x pink/cyan swap x 9, 12, 15 units), all pass the same checks (27 to 29 colours): `tower_01_variants.png`.
- Mock-ups (still images, at the game's art density, nothing scaled): `block_mockup_plan*.png` (the plan's 4 x 4 grid, 6 x 6 cells, 2-unit alleys) and, because the tower came out 2 x 2 instead of 6 x 6, a free alternative `block_mockup_dense*.png` (7 x 7 grid on 4.5-unit pitch, about 2.5-unit alleys). The `_with_car` versions put the game's car sprite on the street in front of the block's south-west side.
- Previews: `tower_01_preview_2x.png` and `tower_01_preview_4x.png`, dark and light backgrounds side by side.

**Problems to report (not regenerated):**

1. **The signs show kanji- and katakana-like marks** on all four panels, despite "no letters" in the prompt and "text, letters, words, kanji" in the (deprecated, probably ignored) negative prompt. They are not readable words as far as I can tell, but they clearly read as Japanese writing. The board decides whether that is acceptable or needs a text task / a script edit of the sign panels.
2. **The footprint is 2 x 2 units, not the planned 6 x 6.** PixelLab drew the "narrow" tower at a third of the planned width, so in the plan's 4 x 4 layout each tower stands alone in a 6 x 6 cell: the block reads as sparse, not too dense. A dense layout of the same tower (49 per block) reads much more like a Tokyo block. For the full set, either prompt for a wide, chunky building (still unproven) or keep 2 x 2 towers and pack them closer; the mock-ups show both.
3. Repeating the floor band also repeats the sign's glyph panels, which shows on the 15-unit versions; mirroring moves the sign to the other wall and flips the lit side.
4. The bottom rows are a little ragged where PixelLab's base shadow met the background; on the dark alley colour it does not show.

Status stays in-progress: waiting for the board's judgement of the sample and its decision on the layout before the 7 remaining calls.

### Full set, planned calls (2026-10-14, written before calling)

The board approved the sample (narrow towers, dense layout of about 49 per block, kanji-like sign marks accepted) and gave the go for up to 7 more calls, one per new base tower.

- **Balance before:** 4953 of 5000 generations (subscription), 0.00 USD credits.
- **Calls:** 7 x `POST /create-image-pixflux` through `game/tools/pixellab_client.py` (timeout 600 s), one per base tower 2 to 8, same settings as the sample (384 x 400, `text_guidance_scale` 8, selective outline, detailed shading, highly detailed, high top-down, south-east, isometric, `no_background`, same negative prompt, same `art-archive/T-064/palette.png` as `color_image`), seed 64064 + tower number. Request bodies: `art-archive/T-064/tower_02_request.json` ... `tower_08_request.json` (made by `python game/tools/build_buildings.py requests`). One round: no resend, no regeneration.
- **Prompts** (each is "a single narrow Tokyo-style cyberpunk skyscraper tower at night, isometric, square footprint, " + the part below + "pink and cyan neon glow drawn in pixels, retro pixel art"):
  2. flat roof with a water tank and a small antenna, dark navy concrete walls, narrow vertical columns of small lit windows, one very tall vertical neon sign board along the left edge with abstract glowing stripes and shapes, no letters
  3. stepped setback roof with a tall radio mast, dark purple concrete walls, wide horizontal bands of lit windows, vertical neon sign boards stacked on the right corner with abstract glowing shapes, no letters
  4. slanted roof with rooftop air conditioning units, dark navy and grey walls, a checkerboard pattern of lit and dark windows, a big vertical neon sign board hanging from the front corner with abstract glowing marks, no letters
  5. roof garden with a small glowing billboard on top, dark purple walls, tall arched windows in rows, two thin vertical neon signs on the left wall with abstract glowing stripes, no letters
  6. flat roof with a helipad circle and antennas, dark navy walls with horizontal ribs, dense rows of tiny lit windows, a vertical neon sign board on the right wall with abstract glowing shapes, no letters
  7. pointed spire roof with a blinking light, dark violet concrete walls, tall windows in pairs, vertical neon sign boards on both corners with abstract glowing stripes, no letters
  8. boxy roof with ventilation pipes and a satellite dish, dark navy walls with balconies, irregular scattered lit windows, a glowing vertical neon sign board on the left corner with abstract shapes, no letters
- **Expected cost:** 1 generation per call (the sample cost 1 at this size), 7 in all. If any call costs more than 2 generations I stop and report.

### Full set, result (2026-10-14)

**Calls made: 7** (`/create-image-pixflux`, base towers 2 to 8, requests exactly as planned above, first try, no resend, none regenerated). **Cost: 1 generation each, 7 in all.** Balance before 4953, after 4947 of 5000 (0.00 USD credits). Together with the sample round: 8 calls, 8 generations. Records: `art-archive/T-064/raw/tower_02.json` ... `tower_08.json` and `game/art/pixellab-generation-log.jsonl`.

**What was done (free steps):**

- Cleaned each tower (`game/tools/build_buildings.py`: background flood fill, forced 29-colour palette, specks and stray marks dropped by the new `keep_main`; PixelLab had drawn 6 tiny stray letters beside tower 7, now removed). All 8 pass the check (transparent corners, 0 semi-transparent pixels, 25 to 29 colours, closest to Redgull red 0.535 or more, above the 0.5 limit): `art-archive/T-064/clean/`.
- Made the script versions with `game/tools/build_building_atlas.py` (tests `game/tools/test_build_building_atlas.py`): mirrored or not, pink-led or cyan-led neon, and for the six towers with a plain wall (1, 2, 4, 5, 6, 8) also +3 units taller by repeating a band of whole floors, picked where the wall repeats best and holds the fewest neon pixels. +6 units was dropped by the 15.5-unit cap. 56 versions in one atlas, `game/art/buildings/buildings_atlas.png` (2048 x 2432) with `buildings.json`; every version passes the sprite checks, the atlas has 0 semi-transparent pixels.
- Swapped them into the game: each block's building node has a `Towers` child with 49 sprites (7 x 7, pitch 4.5 units, scale 0.5, nearest filter), picked by a stable hash (neighbouring towers are always different base towers; no two blocks are the same). `draw_placeholder` false in the isometric view, `height_units` = tallest tower, `custom_silhouette` = outline of the block's towers. Layout data, collisions, depth order and fade untouched. Details: `game/README.md`, "See-through buildings".

**Tests:** full GUT suite 446 of 446 pass (including the new `test_building_art.gd`, 9 tests, and T-019's, T-034's and T-065's); Python tool tests: `game/tools` 196 pass, `tools` 121 pass. One existing T-034 test checks the placeholder box's own outline, so it now builds its map with `building_art_enabled = false` (new map flag); nothing else in the older tests changed.

**Screenshots** (`art-archive/T-064/screenshots/`, taken in a run from the main menu): `t064_open.png` (a block next to the car, opaque), `t064_behind.png` (the car behind the block: the whole block faded, the car and boulders visible through it), `t064_junction.png` (the road between two blocks) and `t064_overview.png` (the whole map, all 12 blocks). Also `art-archive/T-064/clean/all_towers.png` and `heights_strip.png`.

**Honest judgement (the board decides):**

- The 8 towers do look different (roof shapes, sign placement, window patterns) and the blocks read as a dense, neon Tokyo district at the game's density. In the screenshots the signs are the strongest look; they show kanji- and katakana-like marks, which the board accepted.
- Weak points: (1) the 8 base towers repeat 49 times per block, so with 56 versions the repetition shows when you look for it; the mirror and neon swap help, but not a lot. (2) Stretched towers repeat floors, and tall sign panels on towers 1, 2 and 6 repeat their glyphs (I could only reduce this by choosing the least neon band, not remove it). (3) Towers 2 and 7 come with a flat base plate that sticks out under the neighbours' bases. (4) The block's fade outline is the convex hull of all towers, so it can start fading slightly early at the sides. (5) The cyan neon glow of some towers is a flat coloured bar on the ground at the base, which looks slightly odd in the alleys. (6) The atlas is 2048 x 2432, larger than needed (not tightly packed).
- Not done: dropping repeated sign panels on stretched floors (only minimised); more than 8 base towers (the board gave 8).
