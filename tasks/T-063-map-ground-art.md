---
id: T-063
title: Art: the first ground tile, a stretch of asphalt road (PixelLab)
status: done
from: project-lead
to: asset-generation
lead:
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-019, T-097]
documents_affected: [game/README.md, art-archive/README.md]
files_to_read_first: [art-archive/README.md, tasks/T-101-car-sprites-remaining-directions.md, tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-003-pixellab-test-generation.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/level-design.md, tasks/T-019-build-mvp-map.md]
files_expected_to_change: [a ground tile PNG and its record under game/art/, a mock-up image, the PixelLab generation log, game/README.md]
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

**Scoped down by the board (2026-10-12): one road tile first,** as with the car (T-014). The rest of the ground set and putting it into the map moved to T-103, which waits for the board's review of this tile.

Generate **one** ground tile with PixelLab: a plain stretch of **asphalt road** for the MVP map, as Visual style, Decisions ("Ground") describes it, with the board's answers of 2026-10-12:
- asphalt with a **white** lane line (dashed or solid is your proposal; say which and why);
- **light cracks** from the disaster, nothing heavier;
- no zebra crossing and no pavement on this tile (they come with the full set in T-103), unless the tile you propose needs a pavement edge to read as a road; then say so.

**Fit the game:** drawn for the game's 2:1 isometric view (the projection the map and the car use: `game/README.md`) at about 40 pixels per unit, like the car (`game/art/car/car_iso.png`), and under the night palette (Visual style, Decisions). Roads are 24 units wide (Level design, Decisions), so one tile will be a piece of road, repeated: propose the tile's size in units and pixels and how it repeats along the road, and say so in the result notes. Show it next to the car at the same scale (a mock-up image is enough) so the board can judge the scale.

**PixelLab:** re-check the API docs first (https://www.pixellab.ai/llms.txt, https://api.pixellab.ai/v2/openapi.json) and pick the endpoint that best makes one isometric ground tile at this size (T-003 tried `/create-isometric-tile`; read its notes); say why. Use `game/tools/pixellab_client.py` with a long HTTP timeout, record every call with its prompt, settings and cost, and check the balance before and after. **One round only:** don't regenerate; report problems. If one call returns several images, keep them all for the board to choose from. Anything not chosen goes to `art-archive/T-063/` with its record (Visual style, Decisions); delete nothing.

**Don't put it into the map yet:** save it under `game/art/` without changing any scene or script. T-103 does the swap.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] The tile is a PNG under `game/art/`, and the result notes give its size in units and pixels and how it repeats along a road (QA: pass)
- [x] A check script shows it follows Visual style's technical rules: no semi-transparent pixels, about 30 colours or fewer, and a transparent background outside the tile's shape (QA: pass)
- [x] A mock-up image shows the tile repeated as a road with the final car on it at the game's scale (QA: pass)
- [x] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass)
- [x] `git diff master...HEAD` shows no change to scenes or game scripts (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: judge the road tile's look (asphalt, the white line, the light cracks, the scale next to the car); one round only, so problems are reported rather than regenerated.
Board review files: the tile PNG under `game/art/` and the mock-up image.

## Result notes

Written by the agent when it finishes.

**Asset Generation Agent, 2026-10-12**

**Endpoint, and why.** Re-checked https://api.pixellab.ai/v2/openapi.json and llms.txt. I used `POST /create-tiles-pro` (`tile_type: isometric`, `tile_size: 128`, `tile_view: top-down`, no `tile_feature`), not T-003's `/create-isometric-tile`. Why: `/create-isometric-tile` has a 64 x 64 canvas limit and a 16 or 32 pixel tile, so a tile would cover 1 unit at the car's density, too small for a lane line and cracks; `/create-tiles-pro` goes to 128 pixels and has a no-depth "top-down" view for a flat surface. The `roads` autotile feature was not used (it makes 18 junction pieces, which is T-103's scope). One call, prompt asked for "1). ..." one tile. Full prompt and settings: `game/art/ground/road_tiles.json`, each raw record in `art-archive/T-063/raw/`, and the log `game/art/pixellab-generation-log.jsonl`.

**Cost and balance.** One call, **15 generations** ($0.00, subscription). Balance before 4986 of 5000, after **4971**. The call returned **six tile variations**, all kept. One round only: no regeneration. The log has two entries for the call: the first run ended in an error because the client could not find the images (the result holds download URLs, not image data); the job had finished and was charged once, so I fixed the client and saved the images by a free `GET /tiles-pro/{tile_id}` (second log entry says so). No second generation.

**What I made.** `game/art/ground/road_tile_0.png` to `road_tile_5.png` (the board picks one), `road_tiles.json`, mock-ups `road_mockup_0.png` to `road_mockup_5.png`. Dark navy-purple asphalt, a white dashed lane line, light cracks, no pavement or crossing. Each has 9 to 18 colours.

**Size and repeat.** The diamond is **128 x 64 pixels, 2 x 2 units** at the car art's density (32 art pixels per unit; the game draws art at scale 0.5, so 64 x 32 screen pixels). Neighbours sit at (+64, +32) across the road (world x) and (-64, +32) along it (world y). A 24-unit road is **12 tiles across**; the lane line runs along the road in the tile's middle, so it repeats as a dashed line down the road. Dashed (not solid) because the dashes show direction and motion at drift speed, and PixelLab made them.

**Processing (no generation).** PixelLab returned a **128 x 128 canvas with a 1:1 diamond**, not the game's 2:1. I kept every second pixel row to make 128 x 64 (`game/tools/build_road_tile.py process`; no new pixels or colours; a top-down square seen at 45 degrees squashed 2:1 is the isometric projection). The raw 128 x 128 images are in `art-archive/T-063/raw/` and listed in `art-archive/README.md`.

**Check script.** `python game/tools/build_road_tile.py check game/art/ground/road_tile_N.png`: all six pass (size 128 x 64, no semi-transparent pixels, transparent outside the diamond, 30 colours or fewer, diamond filled). Python tool tests: 94 OK. GUT: 300 passing, TESTS PASSED. No scene or script changed.

**Mock-up.** Each `road_mockup_N.png` shows the tile as a road 24 units wide and 16 long, with the final car (frame 4) on it at the same art scale, so the tile-to-car scale is as in the game. The line is in column 6 of 12, so it is **one unit off the road's centre**: a tile whose line is centred cannot centre a 12-tile road (a double line or a centre-line piece would solve it in T-103). The side lanes in the mock-up are the same tile with the white pixels painted out by script, a stand-in because there is no plain tile yet.

**Problems the board should know (not regenerated).**
- Every tile has a **dotted dark outline along its diamond edge**, so the repeat shows a visible grid; the cracks at the corners meet as small star shapes where four tiles join. They do not tile seamlessly.
- The tiles are **dark and low contrast** (near-black purple), and the white dashes are thin and broken, so the line is faint at game scale.
- **Tile 5's line runs along the other axis** (world x), so it does not line up with the mock-up's road.
- The line does not always run exactly through the edge midpoints, so dashes do not always meet across a join.
- No plain asphalt tile (needed for the side lanes): for T-103.
- PixelLab's `tile_view: top-down` gave a 1:1 diamond; a 2:1 one needs the squash above (or another view setting, a new generation).

**Files.** New: `game/art/ground/` (tiles, mock-ups, `road_tiles.json`, Godot `.import` files), `art-archive/T-063/raw/` (6 raw PNGs and records), `game/tools/build_road_tile.py` and its tests. Changed: `game/tools/pixellab_client.py` (+ `create-tiles-pro`, URL download with a user agent, 2 tests), `game/art/pixellab-generation-log.jsonl`, `game/README.md` (new section), `art-archive/README.md`.

### Board review

2026-10-12: the board saw the six tiles and mock-ups (the Project Lead's view: the dotted diamond edges make the road read as a grid, the asphalt is very dark and the white line faint). The board chose to try a **script fix first, no generation**: take tile 1, remove the dotted outline along its diamond edge so repeated tiles join without a visible grid, and brighten the white line a little so it reads clearly against the asphalt. Keep the original six tiles as they are; save the fixed tile as a new file with a record saying how it was made. Make a new mock-up with it. Pixels and colours must come from the tile's own palette (no new colours, unless the line needs one brighter white; then say so).

### Script fix of tile 1 (Asset Generation Agent, 2026-10-12, after the board's review)

No PixelLab call, no cost (balance still 4971). `game/art/ground/road_tile_1_fixed.png` (+ `road_tile_1_fixed.json`) and the mock-up `road_mockup_1_fixed.png`, made by `python game/tools/build_road_tile.py fix` from `road_tile_1.png`; `road_tile_0..5` are unchanged. Steps: the tile is cut to the exact tiling footprint (the raw edge made 67 gaps and some overlaps when tiled; now 0 and 0); dark edge pixels become the tile's own colours from further in; a few transparent holes are filled; every line pixel becomes the tile's own brightest white (223, 221, 218), so **no new colour** (9 colours). Check script: all pass. Python tool tests and GUT pass (see below).

**What I see in the mock-up at full size:** the grid is gone; the road reads as one asphalt surface, and the line is clearly brighter. Still visible: (1) the same faint crack streaks repeat in every tile in a regular pattern; (2) the white line has a small "+" mark where each tile joins (the line's end dashes and the corner pixels meet); (3) the dashes are still short and broken, and the line is still one unit off centre; (4) the asphalt is still very dark; (5) the lane lines' dash gaps are uneven. The side lanes are the same stand-in as before.

2026-10-12, second note: the board fixed the white line of `road_tile_1_fixed.png` by hand, saved as `road_tile_1_board.png` (it removed the "+" marks at the tile joins; saved by the board's editor as an indexed-colour PNG). The board **approved this tile** as the road tile. Finish: save it as an 8-bit RGBA PNG (same pixels), with a record saying the board edited the line by hand from `road_tile_1_fixed.png`; make its mock-up. Per the archive rule, `game/art/ground/` keeps only the approved tile and its record: move every other tile (0 to 5, `road_tile_1_fixed`), every mock-up and the board's indexed original to `art-archive/T-063/` with their records and rows in `art-archive/README.md`. T-103 may take tiles from the archive to break up the repeating cracks.

### The board's approved tile (Asset Generation Agent, 2026-10-12)

No PixelLab call, no cost (balance 4971). The approved tile is `game/art/ground/road_tile.png` with `road_tile.json`: the board's hand-edited `road_tile_1_board.png` (indexed colour) saved as 8-bit RGBA, **identical pixel for pixel** (checked: same pixel list, 9 colours, alpha 0 or 255 only). Check script: all pass. **Size and repeat:** 128 x 64 pixels, 2 x 2 units, neighbours at (+64, +32) and (-64, +32), exact footprint (0 gaps, 0 overlaps); a 24-unit road is 12 tiles across. Mock-up with the car: `art-archive/T-063/road_mockup.png` (the line is clean, the "+" marks are gone; the faint cracks still repeat in every tile, and the line is one unit off the road's centre in a 12-tile road).

**Archive rule applied:** `game/art/ground/` holds only the approved tile and its record. Tiles 0 to 5, `road_tile_1_fixed.png` (+ record), the board's indexed original, every mock-up (including the new one) and `road_tiles.json` are in `art-archive/T-063/` (with the six raw 128 x 128 originals in `raw/`), listed in `art-archive/README.md`; their Godot `.import` files were removed. Nothing deleted. **T-103 can take tiles from the archive** (for example other crack variations to break up the repeat).

Tests: Python tool tests and GUT pass. Files changed this step: `game/art/ground/road_tile.png`, `road_tile.json` (+ `.import`), the moves above, `art-archive/README.md`, `game/README.md`, this task file.

### QA round 1

QA/Integration Agent, 2026-10-12, on branch task/T-063-first-road-tile at 0ca2d59. All criteria pass.

- Tile is a PNG under game/art/ with size and repeat in the notes: PASS. game/art/ground/road_tile.png, 128 x 64 px, 2 x 2 units, neighbours (+64,+32) and (-64,+32), 12 tiles across a 24-unit road; stated in the notes and road_tile.json. Tiled 8 x 8 in a QA script: 0 gaps, 0 overlaps.
- Check script: PASS. `build_road_tile.py check` passes all six checks (128 x 64, 0 semi-transparent, transparent corners, no stray pixels, 9 colours, diamond filled).
- Mock-up with the final car: PASS. art-archive/T-063/road_mockup.png (1328 x 728) exists (archived, which is fine).
- Record: PASS. One /create-tiles-pro call, 15 generations, balance 4986 to 4971, with prompt and settings in game/art/pixellab-generation-log.jsonl and art-archive/T-063/road_tiles.json; second log entry is a free GET recovery. The board's hand edit is recorded on road_tile.json ("made_by").
- Approved tile identical to the board's indexed original: PASS. Both converted to RGBA, the difference image is empty (identical).
- Archive rule: PASS. game/art/ground/ holds only road_tile.png, .json and .import; every other tile, mock-up and raw original is in art-archive/T-063/ with rows in art-archive/README.md (T-063 rows list them all); the only files deleted on the branch are .import files; no .import files under art-archive/.
- No scene or game script changed: PASS. `git diff master...HEAD` touches only docs/README, art, art-archive, the log, game/tools Python files and the task file.
- Tests: PASS. Full GUT suite 300 of 300 passing (TESTS PASSED); tools tests 75 OK; game/tools tests 97 OK. (GUT's re-import touched addons .import files; reverted, not committed.)

