---
id: T-064
title: Art: Tokyo-style buildings for the city blocks
status: in-progress
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-128]
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

**Redesigned by the board, 2026-10-14** (Visual style, Decisions, "Buildings"). The first round (dense narrow towers, 8 generations, on this task's branch `task/T-064-building-art`) was not taken: its art stays in `art-archive/T-064/` on that branch, never deleted. The board starts this task itself (it waits in To do).

The new design:
1. **The bases of really tall skyscrapers:** drawn as if the isometric camera sees the bottom floors of towers so tall their tops are out of view, so the car is realistic in size next to them.
2. **Each block split into 2 by 2 skyscrapers** (four per 30 by 30 block, each about 15 by 15 units on the ground).
3. **6 different skyscrapers**, the same type as before (Tokyo-style towers, lit windows, vertical neon signs with Japanese-like marks that are not real words), in downtown Tokyo **under attack from the kaiju** (T-128's brief).
4. **A pavement drawn around each building asset**, inside the block (the roads stay as they are).
5. Some slots may hold T-129's shorter buildings instead; leave room for that (a slot system).
6. Keep T-034's see-through fade (each building fades when it covers the car) and the depth order with the car, boulders, drift marks and smoke; collisions and the map layout unchanged.

**The size problem to solve in the plan:** a 15 by 15 unit skyscraper base is about 960 by 480 pixels in the isometric view at the game's density, far bigger than one PixelLab image (400 px per side). Propose how (for example building each base from several generated pieces, facade tiles or isometric tiles, or a different approach), with the calls and cost, for the board before any call.

Follow Visual style, Decisions: pixel art for the isometric view at the game's pixel density (the car and ground are drawn at 32 art pixels per unit, scale 0.5), a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, the night neon palette, no Redgull red. Real-world things are inspiration only: no real logos, no copies of existing characters (the kaiju is "in the style of Godzilla", never Godzilla). Read T-128's narrative guidance first and keep the look consistent with every approved asset (car, ground, boulders, drift marks and smoke).

PixelLab: never call it without the board's go for this task. Plan first (calls, sizes, cost) in the result notes and bring it to the board; then one sample for the board's review; then the full set from the approved sample. Use `game/tools/pixellab_client.py` with a 600 s timeout, record every call with its prompt, settings and cost and the balance before and after, and do not regenerate weak results: report them. Free script fixes come before paid calls. Never delete generated art: unused versions go to `art-archive/<task>/`.

This waits for T-128 (the narrative brief).

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, about 30 colours or fewer, and no Redgull red (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; every call had the board's go (QA: pass / fail)
- [ ] Screenshots in a run show blocks of 2 by 2 skyscraper bases with pavements, the car realistic in size next to them, 6 different skyscrapers in use, and the see-through fade working (QA: pass / fail)
- [ ] Collisions and the map layout are unchanged; T-019, T-034 and T-065's tests pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest the city and judge the skyscrapers.

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

### The board's redesign, 2026-10-14

After the dense narrow towers were ready to playtest, the board redesigned the buildings (see the Description). The first round's work stays on `task/T-064-building-art` and in `art-archive/T-064/` there; the next round decides whether to start a fresh branch from master or reuse that one, and keeps the archive either way.

