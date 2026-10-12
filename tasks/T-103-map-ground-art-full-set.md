---
id: T-103
title: Art: the full ground set for the MVP map, put into the map (PixelLab)
status: in-progress
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-063]
documents_affected: [game/README.md, art-archive/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/level-design.md, tasks/T-063-map-ground-art.md, tasks/T-019-build-mvp-map.md, tasks/T-097-mvp-map-without-challenges.md, tasks/T-101-car-sprites-remaining-directions.md, art-archive/README.md, game/README.md]
files_expected_to_change: [art files under game/art/ and their records, the map's scenes and drawing code, tests, art-archive/, game/README.md]
model: opus
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

**Waits for the board's review of T-063's first road tile (2026-10-12).** Split from T-063. Don't start until the board has approved that tile; the board may add notes from its review here.

The rest of the MVP map's ground, matching the approved tile, as Visual style, Decisions ("Ground") describes it: asphalt roads with white lane lines, **zebra crossings** at the junctions, light cracks, the road around the map's edge, and the dusty gravel centre, with a few cracked variants so the roads don't look repeated. Then swap them in for the map's flat placeholder colours (T-019, T-097), so a run started from the main menu shows the final ground.

No pavements in the MVP (board, 2026-10-12): the roads meet the building blocks directly. The approved road tile is in `game/art/ground/`; the other T-063 tiles are in `art-archive/T-063/` and may be used to break up the repeating cracks.

The board approves the generations this task needs. Plan the calls first and write the plan and its expected cost in the result notes before calling; check the balance before and after; use a long HTTP timeout. One round: don't regenerate tiles you don't like; report them. Every generation that isn't used as-is goes to `art-archive/T-103/` with its record and a row in `art-archive/README.md`; nothing generated is deleted, and `game/art/` holds only game-ready art.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] Every ground tile is under `game/art/` with its record, and a check script shows each follows Visual style's technical rules (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass / fail)
- [ ] In a run started from the main menu, the map shows the final ground (roads, white lines, zebra crossings, the edge road, gravel centre) with no gaps or seams, lined up with the map's layout and collisions (screenshots) (QA: pass / fail)
- [ ] T-019's and T-097's map tests still pass: the layout and boulders are unchanged (QA: pass / fail)
- [ ] Every unused or raw generation is in `art-archive/T-103/` with its record and listed in `art-archive/README.md` (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest a run and judge the ground's look; one round only, so problems are reported rather than regenerated.
Board review files: the ground art under `game/art/` and the screenshots.

## Result notes

Written by the agent when it finishes.

**Asset Generation Agent, 2026-10-12**

### Plan and expected cost (written before any PixelLab call)

API re-checked (https://api.pixellab.ai/v2/openapi.json, https://www.pixellab.ai/llms.txt). `/create-tiles-pro` now takes **`style_images`**: reference tiles whose style, palette and *shape* the new tiles copy (tile_type, size and view are then ignored). Passing the approved `road_tile.png` (128 x 64) should give tiles in its 2:1 diamond and night palette directly.

Tiles the map needs (2 x 2 units each, the approved tile's grid; every map edge, block, road and the gravel square sits on even units, so the grid fits the layout exactly):

| Tile | How it is made | Cost |
|---|---|---|
| Plain asphalt (road without a line; junction boxes) | Script: the approved tile with its white line pixels replaced by the asphalt beside them | 0 |
| Crack variants of the asphalt (to break up the repeat) | Script: the plain tile mirrored and shifted by whole units on its own seamless repeat (cracks land elsewhere), plus any plain asphalt the generation call gives | 0 |
| Centre line of a 24-unit road (centred: the line falls on a tile edge) | Script: the approved tile's own line moved by 1 unit, split into a left-half and a right-half tile, over the plain asphalt | 0 |
| Roads along world x | Script: every along-y tile mirrored left-right (swapping world x and y is a left-right flip of the 2:1 diamond) | 0 |
| Zebra crossings at junctions | Script: white stripes (the approved tile's own white) drawn as simple shapes on the plain asphalt; cracks kept over the paint | 0 |
| Dusty gravel centre (84 x 84 units) | **PixelLab**: one `/create-tiles-pro` call | ~15 generations |

**The one call:** `/create-tiles-pro`, `style_images: [road_tile.png]` (128 x 64), no `tile_feature` (it cannot be combined with style images), description numbering the variations: mostly dusty gravel, plus plain cracked asphalt without lines in the same call (extra variants at no extra cost). T-063's call of the same endpoint at 128 px cost 15 generations for 6 tiles, so **expected cost: about 15 generations** (subscription; balance before: **4971** of 5000). Raw output to `art-archive/T-103/raw/`; tiles used in the game are processed by script (palette check, exact footprint) into `game/art/ground/`. One round only: whatever comes back is used or archived, not regenerated.
