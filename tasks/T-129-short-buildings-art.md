---
id: T-129
title: Art: shorter buildings whose roofs show
status: in-progress
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-128]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/level-design.md, game/README.md, tasks/T-128-narrative-tokyo-under-attack.md, tasks/T-064-building-art.md]
files_expected_to_change: [art under game/art/ and its records, the map's building drawing, tests, game/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board wants shorter buildings alongside the skyscrapers (Visual style, Decisions, 2026-10-14): low enough that the isometric view shows their **roofs** (rooftop units, water tanks, signs, maybe damage from the attack), in the same downtown Tokyo look, **with a pavement drawn around them**. They fill some of the blocks' quarter slots instead of a skyscraper (T-064 splits each block into 2 by 2 slots), so the city mixes tall and short.

Propose how many variants and how they mix with T-064's skyscrapers (which slots, how often), in the plan. Build on T-064's layout (the slot system and the see-through fade per building), so this task waits for T-064's approved layout; coordinate through the Project Lead.

Follow Visual style, Decisions: pixel art for the isometric view at the game's pixel density (the car and ground are drawn at 32 art pixels per unit, scale 0.5), a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, the night neon palette, no Redgull red. Real-world things are inspiration only: no real logos, no copies of existing characters (the kaiju is "in the style of Godzilla", never Godzilla). Read T-128's narrative guidance first and keep the look consistent with every approved asset (car, ground, boulders, drift marks and smoke).

PixelLab: never call it without the board's go for this task. Plan first (calls, sizes, cost) in the result notes and bring it to the board; then one sample for the board's review; then the full set from the approved sample. Use `game/tools/pixellab_client.py` with a 600 s timeout, record every call with its prompt, settings and cost and the balance before and after, and do not regenerate weak results: report them. Free script fixes come before paid calls. Never delete generated art: unused versions go to `art-archive/<task>/`.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Do not merge.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, about 30 colours or fewer, and no Redgull red (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; every call had the board's go (QA: pass / fail)
- [ ] Screenshots in a run show short buildings with visible roofs and their pavements among the skyscrapers, and the see-through fade still working on them (QA: pass / fail)
- [ ] Collisions and the map layout are unchanged, and T-019, T-034 and T-064's tests pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest the city and judge the short buildings.

## Result notes

- 2026-10-14, open → blocked: waits for T-128 and T-064's layout
- 2026-10-14, open → in-progress: board started it (2026-10-15): plan first

### Plan (2026-10-14, planning round: no PixelLab call made, no game file changed)

Assumes T-064's redesign: 2 by 2 slots per 30 by 30 block, each slot 15 by 15 units (a 960 by 480 px diamond at 32 art px per unit), a pavement around each building inside its slot, and T-034's fade per building node. Geometry used below: in the isometric view 1 unit of ground along x or y is 32 px across and 16 px down, and 1 unit of height is 32 px up.

**1. The size problem (pieces assembled by a free script).** A short building is built from three parts; PixelLab only draws parts that fit its limit (at most 400 px a side; transparent background only up to about 200 px):
- **Two facades** (the left and the right wall), each a flat front-on rectangle 352 px wide (11 units) by 128 to 192 px tall (4 to 6 units), made by `/create-image-pixflux`, `view` side, `direction` south, opaque (no `no_background`, so the 200 px limit does not apply). A script shears each one exactly 2:1 (left wall steps down going right, right wall steps up), column by column, with no resampling, so vertical neon signs stay vertical and pixels stay crisp. A sheared wall is 352 by (176 + height) px.
- **The roof** is drawn by a script directly in isometric space (an 11 by 11 unit diamond, 704 by 352 px): dark tar, a parapet lip, panel seams, vent lines, light cracks. No PixelLab, no resampling.
- **Rooftop props** (water tank, air-conditioning units, sign board, antenna mast, vents with a satellite dish, rubble heap): small isometric props, 96 by 96 px, `no_background` (under 200 px), placed on the roof by the script at fixed spots per variant. The prompts say "low, wide, lying directly on the roof, no base, no platform" (T-065's lesson). Props are reused across variants, so the roofs differ for few calls.
- **Assembly:** the script stacks left wall, right wall (the right one about 20% darker through palette mapping so the corner reads), and roof, with a 1-px selective outline along the corner and roof edge, inside a slot-sized sprite: the 11 by 11 unit body is centred in the 15 by 15 slot, leaving a 2-unit (64 px) pavement ring. One finished sprite is about 960 by 640 px (480 slot diamond + up to 192 px of height), far past PixelLab's limit, but every generated part is at most 352 px.

**2. How short, and what the roofs carry.** Heights of 4, 5, 6 and 5 units (128 to 192 px), against 15 units for a skyscraper, so the whole roof diamond is visible from the camera. Roof loads per variant: A, air-conditioning units and a water tank; B, a sign board and an antenna mast; C, vents with a satellite dish and a rubble heap; D, a water tank and an antenna, with a cracked parapet. Damage per the City brief, light to medium: cracks, a few broken or dark windows, a little rubble, no fires or collapse. Facades: dark navy and purple, mostly dim windows, a ground-floor neon shop sign (Japanese-like marks that are not real words), pink and cyan glow drawn in pixels, no Redgull red, no real brands. The same palette image as T-064 (`art-archive/T-064/palette.png`, passed as `color_image`) so the two sets match; each sprite cut to 30 colours by `game/tools/reduce_palette.py`.

**3. The pavement.** Reuse T-064's pavement exactly (same tile or script, same ring, same kerb on the road side), so tall and short buildings sit on the same ground. If T-064 draws it by script, call that script with this task's body size (11 by 11 in the 15 by 15 slot); if T-064 generates it, take its art. Either way 0 generations here. Light cracks and a bit of rubble are added by the same script. Recommendation: keep the pavement as its own sprite at ground depth, so a faded building does not fade the pavement (the car never drives there; collisions stay the layout's).

**4. Variants and mix.** 4 short variants (A to D), plus mirrored and neon-colour-swapped (pink-led or cyan-led) script versions: 16 looks from 4 sets of calls. In the slot system the nearest slot to the camera is (1,1), then (1,0) and (0,1), then (0,0): a tall tower in front hides part of a roof behind it, so shorts go in front. Rule: slot (1,1) is short with 50% chance, one of (1,0) or (0,1) with 25%, and (0,0) never. About 0.9 shorts per block, about 11 of the 48 slots, so each variant appears about 3 times and no block has more than two. Chosen by a stable hash like T-064's (a run always shows the same city), never two of the same variant touching. The share is one number and easy to change after the board's playtest.

**5. See-through fade.** T-034's mechanism stays as is: the short building is its own node with `height_units` 4 to 6 and its footprint, so the fade works unchanged. It will rarely trigger: the car can only be behind it on the road within about 5 to 6 units (about 192 px), versus 15 units for skyscrapers. I will check by a screenshot that it still fades; no new fade work is planned.

**6. Exact calls and cost.** All `POST /create-image-pixflux` through `game/tools/pixellab_client.py`, timeout 600 s, one try each, no resend. T-064's 384 by 400 calls cost 1 generation each; I expect 1 each here, and will stop and report if any call costs more than 2.
- **Sample (needs the board's go): variant A only, 5 calls.** Left facade 352 by 160 (5 units), right facade 352 by 160, water tank prop 96 by 96, air-conditioning units prop 96 by 96, rubble heap prop 96 by 96. Settings: `text_guidance_scale` 8, selective outline, detailed shading, highly detailed, `color_image` palette, seeds 129001 and up, negative description "text, letters, logo, red, perspective, gradient, blur". Example prompt: "front view of the left wall of a five-floor Tokyo-style cyberpunk shop building at night, dark navy concrete, rows of mostly dim windows, a few broken, light cracks, a pink and cyan neon shop sign on the ground floor with abstract marks and no letters, glow drawn in pixels, retro pixel art". Free steps first: shear, roof, assembly, pavement via T-064's script, the check script, dark and light previews, and an in-game screenshot among skyscrapers. Expected cost: 5 generations.
- **Full set (after the board approves the sample): variants B, C, D = 6 facades (heights 128, 192, 160) plus 3 more props (sign board, antenna mast, vents with satellite dish) = 9 calls.** Expected cost: 9 generations. Total with the sample: 14 calls, about 14 generations (last recorded balance 4946 of 5000, subscription, 0.00 USD credits). No spare calls in the budget.
- Records: every call with its prompt, settings, cost and the balance before and after, in `game/art/pixellab-generation-log.jsonl` and `art-archive/T-129/`; raw pieces in `art-archive/T-129/raw/`; build script `game/tools/build_short_buildings.py` with tests; a check script for the sprite rules (transparent background, no semi-transparent pixels, about 30 colours, no Redgull red).

**7. Risks.**
- PixelLab may not draw a flat, evenly lit front elevation (perspective, a floor, a sky), or the window rows may not line up with floors. Mitigation: crop and fill by script; no regeneration, report it.
- The sheared facades may look like paper cut-outs and the two walls may not match at the corner. Mitigation: the corner outline and the darker right wall by script. Cheap fallback: one facade per variant, mirrored (4 fewer calls).
- Props may come with a plinth or base plate (T-065, T-064). Mitigation: the prompt, and the script removes base pixels.
- A roof drawn by script may look plain next to generated walls; the props carry the detail.
- A tall tower in front can still hide part of a roof behind it; the front-slot rule reduces it.
- The pavement and slot size depend on T-064's final layout. If its slots or pavement change, only the assembly numbers change, not the calls. If T-064 builds its bases differently, I align pieces and palette with it before the sample.
- Sprites of about 960 by 640 px are large; 16 looks in one atlas would be big. Pack tightly, or store 4 sets and do the mirror and palette swap in the game.
- Pixel density: facades drawn at 32 px per unit must read as the same pixel size as the skyscrapers and the car. I will compare against an approved T-064 sprite before the sample is judged.

**Recommended:** the piece-based approach above, sample first (5 generations), then the full set (9 more), 14 in all, with nothing called until the board gives the go.
- 2026-10-14, in-progress → planning: board: hold until the skyscraper sample (T-064) is approved; it reuses its wall method
- 2026-10-14, planning → in-progress: board: go for the sample (5 generations), palette B, built on T-064's branch
