---
id: T-263
title: "Level creator: paint roads with a brush that joins them itself"
status: in-qa
from: project-lead
to: level-challenge
lead: Coursework
epic: level-challenges
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-261]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, game/README.md, game/scripts/level_creator/, game/tools/build_ground_tiles.py, game/art/ground/ground_atlas.json, tasks/T-252-road-junction-tiles.md, tasks/T-262-creator-panel-grouped.md]
files_expected_to_change: [game/scripts/level_creator/, game/tools/, game/art/ground/, game/data/level/, game/tests/, game/README.md, docs/level-design.md, art-archive/T-263/screenshots/]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's decision (Level design, Decisions, "Level creator rework", 2026-10-22): roads are painted with a brush. Pick Road, Centre line, Zebra crossing or Cracked road (T-262's Roads group), then press and drag across the map: the road is laid along the drag at the full road width (today's two-tile-wide road, with a centre line in its middle for Centre line, never two half tiles the board has to pair up), and wherever painted roads meet, the editor picks the right piece itself: straights in both directions, corners, T-junctions, crossroads and dead ends at the open ends (T-252's pieces and today's straight tiles; draw by script any piece still missing, for example a centre-line corner or junction, no PixelLab). Painting over a road changes its kind; the delete key (or a right-drag, your proposal) erases road along the drag and the neighbours re-join. Zebra crossing is placed across a road where you click. A road never paints over a building, platform or ramp. Saved levels write the same ground data as today, so they play unchanged, and earlier levels still open. The panel's old separate road tiles are no longer needed (keep them in the data so old levels draw).

Built on T-262's branch (the Project Lead makes your folder). Labels from `creator_texts.json` (T-261). End with screenshots of a street grid painted in a few drags with every junction kind, and a short GIF of painting one.

## Acceptance criteria

- [ ] Tests show a drag paints a full-width road along it, and that meeting roads become the right straight, corner, T-junction, crossroads or dead end, for each road kind; erasing re-joins the neighbours (QA: pass; test_road_brush.gd 13 tests in the full GUT run cover drag, kinds, pieces, erase)
- [ ] The centre line runs in the middle of the road and joins across every piece without gaps (tests on the tile data and the screenshot) (QA: pass; BrushTileTests pixel checks pass, and street_grid_close.png shows the line continuous through junctions)
- [ ] A painted level saves, passes `check_level.py` and plays; earlier levels open unchanged (tests) (QA: pass; saves, check_level and play tests plus old-level test pass)
- [ ] Screenshots and the GIF are in `art-archive/T-263/screenshots/`; `game/README.md` describes the brush; the full GUT suite and all Python tool tests pass (QA: pass; GUT 1539/1539 on rerun after one exit 139 on the combo popup test, game/tools 483 OK, tools 451 OK, 4 files incl. GIF present, README documents the brush)

The board's review: paint a street grid with the brush.
Board review files: the screenshots and GIF in `art-archive/T-263/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-23, Blocked → In progress

Started on T-262's branch: paint roads with a brush that joins them itself.

### 2026-10-23, In progress → In QA

Built: drag to paint whole roads that join into corners, T-junctions, crossroads and dead ends; right-drag erases. Sent to QA.

## Result notes

Level/Challenge Design Agent, 2026-10-23. No PixelLab call.

**Built.**
- **Painting:** pick Road, Centre line or Cracked road and drag with the left button. Each 2 x 2 tile block (4 x 4 units, today's two-tile road) the mouse passes over becomes road, and the blocks in between are filled in, so a diagonal drag leaves no gap.
- **Joining:** the brush picks every tile itself from the road blocks next to each block: straights along y and x, corners, T-junctions, crossroads, and a dead end with its kerb at each open end.
  - **Centre line:** the line runs on through every piece.
  - **Road and Cracked road:** a junction is the plain asphalt.
- **Looks:** V picks the asphalt. Road and Centre line: a0 (M: a0m), g6, g9. Cracked road: g4, g5, g7. R does nothing.
- **Painting over** a road changes its kind and asphalt.
- **Erasing:** a right-drag erases along the drag, and Del erases the block under the mouse. The neighbours join again.
- **Zebra crossing:** a click on a straight road lays a crossing across it, on the row of tiles clicked.
- **Never over:** a road is never painted over a building, platform or ramp.
- **On screen:** the top bar shows `road_brush_hint`. A blue outline marks the block under the mouse, red while erasing.
- **Code:**
  - `game/scripts/level_creator/road_brush.gd` (`RoadBrush`)
  - the editor's stroke functions in `editor.gd`
  - `LevelDocument.set_cells`
  - the brush families in `build_creator_assets.py` (`ROAD_BRUSHES`: `"brush"` and per member `"asphalt"`)

**Tiles drawn by script:**
- `build_ground_tiles.py` `brush_tiles` appends 268 tiles after T-252's (indexes 139 to 406):
  - T-252's 13 centre-line pieces on a0m, g6 and g9
  - the four dead ends without a line on all seven asphalts
- Every earlier tile keeps its index. The game's ground cells are unchanged (the hash test passes). `mvp_ground.json` only lists the new names.

**Saved data:** a road tile per cell, as before. A painted level passes `check_level.py` and plays, and the board's earlier level opens unchanged. The old single road tiles and T-252 pieces are no longer panel looks. They stay in the catalogue, so old levels draw and `place_asset` still places them.

**Proposals for the playtest:**
- Roads lie on a 4-unit grid of blocks. Every road block joins every road block next to it, so two roads painted side by side merge into one wide road.
- A lone block is plain asphalt.
- Where a centre-line road meets a road without a line, the line stops at its own block's edge.
- Zebra crossing:
  - It is the full zebra tile on both tiles across the road: four stripes. The map's edge tiles (e0, e1) would leave only two on a road this narrow.
  - It stays when the road is repainted with another kind, takes the road's asphalt, and goes when its block becomes a junction.
  - It has no top-bar hint, because no text exists for one.
- Right-drag and Del for erasing.
- Older roads join a painted one only when their tiles fill whole blocks of the grid.

**Tests:**
- New `game/tests/unit/level_creator/test_road_brush.gd` (13 tests):
  - a drag along y and along x for each kind
  - a diagonal drag leaves no gap
  - the mouse: left-drag paints, right-drag and Del erase, and the hint shows
  - a plus, an L and a T for each kind give the right piece and tiles
  - the street grid has every junction kind
  - the centre line joins on every open side
  - pieces on the other asphalts
  - erasing joins the neighbours again
  - repainting changes the kind
  - zebra crossings
  - never over a building or platform
  - a painted level saves, passes `check_level.py` and plays
  - the earlier level opens unchanged
- `tools/test_build_ground_tiles.py` `BrushTileTests`: the line pixels on each open side are the straight tiles' own, pixel for pixel. The plain dead ends have the kerb and no line, and pass the sprite rules.
- `tools/test_build_creator_assets.py` `test_road_brushes`.
- T-262's tests updated for the brush: `test_creator_families.gd`, `test_road_pieces.gd`, `test_editor_rotate_heights.gd`, `FamilyTest`.
- The T-262 panel screenshot fixture now paints its roads.

**Results:**
- Full GUT suite: 1539 of 1539 passed. The first run exited 139; the rerun passed.
- `python -m unittest discover -s game/tools`: 483 OK (1 skipped).
- `python -m unittest discover -s tools`: 451 OK.

**Screenshots** in `art-archive/T-263/screenshots/`:
- `street_grid.png`: the grid painted in 6 drags with 4 crossings. It has every corner, all four T-junctions, two crossroads, dead ends and straights, in all three kinds.
- `street_grid_close.png`: the centre line's junctions up close.
- `paint.gif`: painting it one block at a time.
- `paint_end.png`: its last frame.
- Fixtures: `game/tests/fixtures/level_creator_road_brush_grid.gd`, `_demo.tscn`, `_close.tscn`, `_paint.tscn`.

**Seen, not this ticket's:** the Zebra crossing and Cracked road buttons' icons are drawn much smaller than Road's. This was already the case in T-262's `panel.png`.

**Documents updated:**
- `game/README.md`, "Level creator", "The road brush (T-263)", and two T-262 lines
- `docs/level-design.md`, Content, "Level creator: the road brush", and one T-262 line
