---
id: T-103
title: Art: the full ground set for the MVP map, put into the map (PixelLab)
status: needs-playtest
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

**Waits for the board's review of T-063's first road tile (2026-10-12).** Split from T-063. Don't start until the board has approved that tile; the board may add notes from its review here.

The rest of the MVP map's ground, matching the approved tile, as Visual style, Decisions ("Ground") describes it: asphalt roads with white lane lines, **zebra crossings** at the junctions, light cracks, the road around the map's edge, and the dusty gravel centre, with a few cracked variants so the roads don't look repeated. Then swap them in for the map's flat placeholder colours (T-019, T-097), so a run started from the main menu shows the final ground.

No pavements in the MVP (board, 2026-10-12): the roads meet the building blocks directly. The approved road tile is in `game/art/ground/`; the other T-063 tiles are in `art-archive/T-063/` and may be used to break up the repeating cracks.

The board approves the generations this task needs. Plan the calls first and write the plan and its expected cost in the result notes before calling; check the balance before and after; use a long HTTP timeout. One round: don't regenerate tiles you don't like; report them. Every generation that isn't used as-is goes to `art-archive/T-103/` with its record and a row in `art-archive/README.md`; nothing generated is deleted, and `game/art/` holds only game-ready art.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] Every ground tile is under `game/art/` with its record, and a check script shows each follows Visual style's technical rules (QA: pass)
- [x] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass)
- [x] In a run started from the main menu, the map shows the final ground (roads, white lines, zebra crossings, the edge road, gravel centre) with no gaps or seams, lined up with the map's layout and collisions (screenshots) (QA: pass)
- [x] T-019's and T-097's map tests still pass: the layout and boulders are unchanged (QA: pass)
- [x] Every unused or raw generation is in `art-archive/T-103/` with its record and listed in `art-archive/README.md` (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

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

### Result (Asset Generation Agent, 2026-10-12)

**Cost and balance.** One PixelLab call, as planned: `/create-tiles-pro`, style image `road_tile.png`, job `f6cf663e-3d60-472a-b5df-b03c6d79fc71`, **15 generations** ($0.00, subscription). Balance before **4971**, after **4956** of 5000 (checked read-only after the call). One round: nothing regenerated. Prompt and settings: the call's line in `game/art/pixellab-generation-log.jsonl`, each raw record in `art-archive/T-103/raw/`, and `pixellab_calls` in `game/art/ground/ground_atlas.json`. The call returned 10 tiles (128 x 64, already the game's 2:1 diamond): 0-3 dusty gravel, 4-9 plain asphalt.

**Chosen from the call.** Gravel 0, 1, 2; asphalt 4, 5, 6, 7, 9. Not used: 3 (gravel with long tyre-mark stripes in one direction, would repeat visibly over the 84 x 84 gravel square) and 8 (asphalt with big pale patches, reads as a different surface). All 10 raw tiles stay in `art-archive/T-103/raw/` with their records, listed in `art-archive/README.md`.

**Made by script, no generation** (`game/tools/build_ground_tiles.py`): `game/art/ground/ground_atlas.png` (87 tiles) + `ground_atlas.json` (how each tile was made) and `game/data/level/mvp_ground.json` (the tile on each 2 x 2 unit cell). The dark outline along the generated tiles' diamond edge removed (mirrored from further in); plain asphalt from the approved tile with its line painted out (and mirrored); the centre line as two half tiles (the approved tile's own line moved 1 unit, so it sits on the 24-unit road's centre, a tile edge); zebra crossings (0.5-unit white stripes in the approved tile's white, cracks kept over the paint) one tile deep, 2 units before every box where 3 or 4 roads meet, with edge pieces at both road edges; roads along world x are the along-y tiles mirrored. Seven asphalt bases mixed by a fixed hash. No new colours (tested: every atlas pixel comes from the approved tile or the raw tiles). `game/art/ground/` holds only `road_tile.png` and the atlas, with their records.

**In the map.** `scripts/level/mvp_map.gd`: in the isometric view (the run's), a `GroundTiles` node draws the atlas tiles in screen pixels (the view's projection undone), between the outside colour and the buildings; the road and gravel placeholder colours are then not drawn. The flat view, the buildings and the outside keep the placeholders. Physics, layout and boulders unchanged (`mvp_map.json` not touched).

**Check script.** `python game/tools/build_ground_tiles.py check`: ALL PASS for all 87 tiles (128 x 64, no semi-transparent pixels, transparent outside the diamond, 30 colours or fewer, exact tiling footprint).

**Tests.** New: `game/tools/test_build_ground_tiles.py` (14: grid covers the map; every cell matches the layout, no gaps; zebra at every arm of all 4 four-way, 4 three-way inner and 12 edge junctions; centre line on the road centre; exact footprint; technical rules; no new colours; mirroring; committed files up to date) and `game/tests/unit/test_mvp_map_ground.gd` (7: layout covers the map, atlas size, tiles line up with buildings/collisions and the gravel square, iso draws the art and flat the placeholders, tile positions match the projection, draw order). Full GUT suite: **307 of 307 passing**, TESTS PASSED (T-019's and T-097's map tests included). Python tool tests: game/tools **111 OK**, tools **75 OK**.

**Screenshots** (a run from the main menu, `tests/fixtures/ground_from_menu_demo.tscn`; in the git-ignored `screenshots/` of this branch's folder):
- `screenshots/t103_straight.png`: road between two junctions (-54, -81), centre line and zebra crossings at both ends;
- `screenshots/t103_junction.png`: 4-way junction (-54, -54), zebra crossings on all four arms;
- `screenshots/t103_edge_road.png`: the edge road (-108, -81), the map's edge and a T-junction crossing;
- `screenshots/t103_gravel.png`: the gravel centre (-30, -30) meeting the roads;
- `screenshots/t103_overview.png`: zoomed out (orthographic size 45): blocks, roads, crossings and gravel lined up.
No gaps or seams between tiles seen; the ground meets the building blocks and the map edge where the collisions are.

**Problems the board should know (not regenerated: one round).**
- The **gravel shows a patchwork**: the three gravel tiles differ in brightness and have streaks, so the 2 x 2 unit grid is visible as lighter and darker diamonds across the gravel square (clearest zoomed out).
- The **centre line is thin and faint** at game scale (the approved tile's own dashed line, 1 to 2 art pixels wide), much weaker than the zebra crossings.
- Faint crack patterns of the same base still repeat here and there, though mixing seven bases breaks up the regular repeat.
- The buildings, the outside of the map and the flat view still use placeholder colours (out of scope).

**Documents affected.** `game/README.md` (new section "The map's ground (T-103)"), `art-archive/README.md` (T-103 rows). Files: `game/art/ground/ground_atlas.png` (+ `.json`, `.import`), `game/data/level/mvp_ground.json`, `game/tools/build_ground_tiles.py`, `game/tools/test_build_ground_tiles.py`, `game/scripts/level/mvp_map.gd`, `game/tests/unit/test_mvp_map_ground.gd`, `game/tests/fixtures/ground_from_menu_demo.gd`/`.tscn`, `game/art/pixellab-generation-log.jsonl`, `art-archive/T-103/raw/`, this task file.

### QA round 1

**QA/Integration Agent, 2026-10-12.** Checked on `task/T-103-ground-full-set` at 2ef75da. No PixelLab calls made. **All 6 criteria pass.** Status set to needs-playtest.

1. **Tiles under `game/art/` with records, check script: pass.** `game/art/ground/` holds only `road_tile.png` (+ `.json`) and `ground_atlas.png` (+ `ground_atlas.json`), each with its `.import`. `python game/tools/build_ground_tiles.py check`: ALL PASS for all 87 atlas tiles. The approved `road_tile.png` and its record are byte-identical to master (`git diff master..HEAD` is empty for both).
2. **PixelLab record, one round: pass.** The branch adds exactly one line to `game/art/pixellab-generation-log.jsonl`: `/create-tiles-pro`, task T-103, job `f6cf663e-...`, full prompt, 15 generations, 10 files. Settings (style image `road_tile.png`, tile_type, size and view) are in each raw record's `request_params` and in `pixellab_calls` in `ground_atlas.json`, which also gives the cost (15 generations, $0.00) and the balance from 4971 to 4956. There are no other T-103 calls, and the plan was written before the call (commit 34598c2, before 2b3854b).
3. **Final ground in a run from the main menu, lined up, no gaps or seams: pass.** These are my own screenshots, taken with a scratch fixture that starts `game.tscn`, presses Start, places the car and holds W. The fixture was deleted afterwards and not committed. The screenshots are in the git-ignored `screenshots/qa/` of the branch folder:
   - `qa_straight.png`, at (0, -70): a straight road with its centre line and zebra crossings at both junctions;
   - `qa_junction.png`, at (50, 58): a 4-way junction with zebra crossings on all four arms;
   - `qa_edge_road.png`, at (108, 20): the edge road meeting the map edge cleanly, and a T-junction crossing;
   - `qa_gravel.png`, at (20, 15): the gravel centre;
   - `qa_overview.png`, zoomed out to 45: the blocks, roads, crossings, boulders and gravel lined up;
   - `qa_collision.png`: the car driven at a block stops at x = -11.5, which is the block edge (-12) plus half the car's width. On screen it stops at the drawn block edge.
   I saw no gaps or seams between tiles. The ground meets the blocks and the map edge where the collisions are. The car drives normally on the art: at full throttle its speed rises from 213 to 305 over 20 frames.
4. **T-019 and T-097 map tests, layout and boulders unchanged: pass.** `game/data/level/mvp_map.json` is untouched. `test_mvp_map.gd` and `test_mvp_map_no_challenges.gd` are unchanged and pass. The flat view still works: with `map.set_view("flat")` the run draws the placeholder colours and `uses_ground_art()` is false (screenshot `qa_flat.png`), and the GUT test for it passes.
5. **Archive: pass.** All 10 raw tiles are in `art-archive/T-103/raw/`, each with its `.json` record. `art-archive/README.md` has 4 T-103 rows covering tiles 0-9 (used as sources: 0-2, 4-7, 9; not used: 3, 8, with reasons). `git log --diff-filter=D master..HEAD` lists nothing, so nothing was deleted. There are no `.import` files under `art-archive/`.
6. **Full GUT suite and Python tool tests: pass.** `bash game/tools/run_tests.sh`: 307 of 307 passing, TESTS PASSED, exit code 0. Its 1 warning is GUT ignoring an inner class, which is not a failure. `python -m unittest discover -s tools -p "test_*.py"`: 75 OK. `-s game/tools`: 111 OK.

**For the board's review, not QA failures.** The gravel shows a clear light/dark diamond grid, most visible in `qa_gravel.png` and `qa_overview.png`. The centre line is thin and faint next to the zebra crossings. The buildings and the outside of the map are still placeholder colours, which is out of scope.
