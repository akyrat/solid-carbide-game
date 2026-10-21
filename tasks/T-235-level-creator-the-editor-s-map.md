---
id: T-235
title: Level creator: the editor's map canvas, the side panel, placing and deleting pieces
status: needs-playtest
from: project-lead
to: level-challenge
lead: Goal-G-005
epic: level-challenges
milestone: mvp
goal: G-005
user_facing_text: yes
changes_visuals: yes
depends_on: [T-233, T-231, T-232, T-234]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/data/level/creator_texts.json, game/data/level/creator_assets.json, game/scripts/level/level_store.gd, game/scripts/level_creator/editor.gd, game/scripts/level/mvp_map.gd, game/scripts/level/elevation_layer.gd, game/scripts/level/elevation_platform_drawing.gd, game/data/level/elevation_sample_map.json]
files_expected_to_change: [game/scenes/level_creator/editor.tscn, game/scripts/level_creator/editor.gd, game/scripts/level_creator/asset_panel.gd, game/scripts/level_creator/level_document.gd, game/tests/unit/level_creator/test_editor_place_delete.gd, game/README.md]
model: opus
qa_rounds: 1
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

The editor where the board builds a level (Level design, Decisions, 'Level creator', board 2026-10-21). It holds the level as data in the map-file format (map, legend, ground_rows, buildings, pattern_copies, platforms, ramps) and draws it in the game's isometric view with the game's own drawing code: mvp_map.gd built from the level's data and the elevation layer (elevation_layer.gd) for rooftops and ramps, the same scripts the run uses, rebuilt or updated when a piece changes. A new level starts as an empty map (the size of today's map, all ground tiles a single plain kind from the catalogue; the result notes give this as a proposal). A side panel lists every asset in game/data/level/creator_assets.json, grouped by kind with the category names from creator_texts.json. Pick one, click the map to place it (into the level data and the drawing), and delete a placed piece (the delete label from creator_texts.json). The camera can pan and zoom over the map. Rotate, mirror, heights and snapping come in the next tickets; here pieces go at the clicked tile. All labels from creator_texts.json. Add the editor's controls to game/README.md, 'Level creator'. Screenshot of the editor with the panel and placed pieces in art-archive/<this task's id>/screenshots/.

The board's review: Open the level creator, make a new level and place and delete a few pieces of each kind.

## Acceptance criteria

- [ ] The editor draws the level with mvp_map.gd and elevation_layer.gd (the run's scripts), not a copy: a test or the code shows both are instantiated by the editor. (QA: pass)
- [ ] The side panel shows every asset in creator_assets.json, grouped by kind, with the category names from creator_texts.json (a unit test compares the panel's entries with the catalogue). (QA: pass)
- [ ] A scripted unit test places one ground tile, one road, one building, one boulder, one rooftop and one ramp: the level data then holds each; deleting one removes it from the data and from the drawing. (QA: pass)
- [ ] The test that scans the creator's scripts for hard-coded label strings still passes. (QA: pass)
- [ ] game/README.md, 'Level creator', lists the editor's controls (pick, place, delete, pan, zoom). (QA: pass)
- [ ] A screenshot of the editor with the side panel and placed pieces is in art-archive/<this task's id>/screenshots/ and listed in the result notes. (QA: pass)
- [ ] The full GUT suite passes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Blocked → In progress

Goal runner (G-005): started, in C:\solid-carbide-worktrees\T-235.

### 2026-10-21, In progress → In QA

Goal runner (G-005): the agent is done; QA is checking it.

### 2026-10-21, In QA → Needs playtest

Goal runner (G-005): QA passed; merged into playtest/G-005.

## Result notes

Level/Challenge Design Agent, 2026-10-21.

**Built**
- `game/scripts/level_creator/level_document.gd` (`LevelDocument`): the level as data in the map-file format, plus a `ground` section (the ground or road tile per 2 x 2 unit cell: `tiles` = catalogue ids used, `cells` = index per cell). `place(asset_id, units)`, `piece_at(units)`, `delete(piece)`, `map_layout()` / `ground_layout()` for the drawing. `ground_rows` and `legend` stay in step (G/R/B, one letter per unit), so the file keeps check_level.py's size rule. What each kind writes is in game/README.md, "Level creator", "The editor (T-235)".
- `game/scripts/level_creator/asset_panel.gd` (`LevelCreatorAssetPanel`): the side panel. Every catalogue entry is a button showing its art, under the six category names from creator_texts.json. Rooftops and ramps also show their height labels. Click to pick, click again to drop the pick.
- `game/scripts/level_creator/editor.gd`: the editor. The map is drawn in a SubViewport by **`mvp_map.gd` (instantiated from `scenes/level/mvp_map.tscn`) and `elevation_layer.gd`**, the run's own scripts, rebuilt when a piece changes (ground and road tiles only redraw the ground). It has the Delete button, Back button, controls hint, the pick/place/select/delete controls, pan and zoom, and an overlay with the picked asset's footprint under the mouse and the selected piece's outline. `editor.tscn` is unchanged (the script builds the nodes).
- Small additions to the run's scripts, so they can draw a creator level. Each is off unless the new data is present, and the default run is unchanged (full suite green):
  - `ground_height.gd` gets `load_data(dict)`.
  - `elevation_layer.gd` gets `setup_data(map, dict)`.
  - `mvp_map.gd` reads a boulder's optional `variant`, draws the ground layout's optional `extra` textures (for `road_tile.png`, which isn't in the atlas), and has an `alert_signs_enabled` switch (the editor turns it off).
  - `building_towers.gd` gets `single_of(entry)` and a `single` setup: a building entry with `asset`/`look` is drawn as that one tower on its 12 x 12 footprint, with no pavement.
- Tests: `game/tests/unit/level_creator/test_editor_place_delete.gd` (13 tests). They cover:
  - the map and elevation scripts are mvp_map.gd and elevation_layer.gd;
  - the panel matches the catalogue by category;
  - height labels, button and hint labels;
  - placing by a click;
  - one ground tile, road, building, boulder, rooftop and ramp placed, each checked in the data and in the drawing, then each deleted, gone from both;
  - select + Delete button;
  - the road tile shown as an extra;
  - unique ids, and nothing placed outside the map;
  - opening the sample map draws it and leaves its data alone;
  - `single_of`;
  - pan and zoom.

  The label scan test still passes. Full GUT suite: 111 scripts, 1335/1335 passed.

**Proposals for the board's playtest**
- A new level is 240 x 240 units (today's map), with every ground tile `ground-gravel0`.
- **Controls:**
  - Left-click places the picked asset. With nothing picked, left-click selects.
  - Right-click selects and drops the pick.
  - Del or the Delete button deletes. Deleting a ground or road tile puts back the plain ground.
  - Esc drops the pick and the selection.
  - Pan with the middle mouse button or the arrow keys. Zoom with the wheel: starts at 0.2, range 0.05 to 3.
- A building is placed as one tower of the catalogue's 12 x 12 footprint, not today's 30 x 30 block of four.
- Ids: `roof-N`, `ramp-N`, `boulder-N` (one pattern copy per boulder).

**For the later tickets**
- T-236: a placed ramp has `platform: ""` until the heights ticket links it, so check_height_data.py may refuse such a file. Placed rooftops and ramps get the elevation layer's script drawing: the sample's rooftop art is one image per sample area, at that area's place.
- T-238/T-239: the run still takes its ground art from `mvp_ground.json`. To play a custom level's ground tiles, the run can set `map.ground_layout = LevelDocument.new(data).ground_layout()` and `alert_signs_enabled = false`.
- The controls hint text mentions R and M, which come with T-236.

**Screenshots** (`art-archive/T-235/screenshots/`, from `tests/fixtures/level_creator_editor_demo.tscn` and `level_creator_editor_panel_end.tscn`):
- `editor.png`: the editor with the side panel (Ground, Roads), and placed pieces: roads with a zebra, gravel patches, two skyscrapers and a short building, two boulders, a rooftop and a ramp. It also shows a picked boulder's blue outline and a selected building's yellow outline.
- `editor-panel-end.png`: the same with the panel scrolled to Buildings, Boulders, Rooftops (Height 3/6) and Ramps (Ramp 0 to 3 / 3 to 6).

**Documents affected:** none. `game/README.md`, "Level creator", got the editor and its controls; it is the game's own readme.

PixelLab: 0 generations. Refusals: one `sed` command to print parts of the sibling task files was refused (it needed approval). It wasn't essential: I read the files with the file reader instead. Godot's line-ending-only `.import` changes in the working copy were left uncommitted.
- 2026-10-21, in-qa → needs-playtest: QA passed every criterion (goal G-005).
