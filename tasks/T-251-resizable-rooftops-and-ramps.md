---
id: T-251
title: "Level creator: rooftops of any size, and ramps in every direction"
status: in-progress
from: project-lead
to: level-challenge
lead: Coursework
epic: level-challenges
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-250]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, game/README.md, game/scripts/level/elevation_layer.gd, game/scripts/level/elevation_platform_drawing.gd, game/tools/build_elevation_sample_art.py, game/tools/build_creator_assets.py, game/tools/check_height_data.py, game/scripts/level_creator/, tasks/T-198-art-rooftops-and-parking-garage-ramps.md]
files_expected_to_change: [game/scripts/level/, game/scripts/level_creator/, game/scenes/level_creator/, game/tools/, game/data/level/creator_assets.json, game/tests/, game/README.md, docs/level-design.md, art-archive/T-251/screenshots/]
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

The board's decision (Level design, Decisions, "Level creator piece set", 2026-10-22). Today a rooftop or ramp in the creator is one fixed picture from the sample map (`art/elevation_sample/`), so there are only two rooftop sizes (84 x 30 at height 3, 30 x 30 at height 6) and two ramps. Make them free-sized so the board can build a multi-layer world:

1. **Rooftops of any size:** pick a rooftop (height 3 or 6), then drag on the map to size it (even units, at least 4 x 4, up to the map's size), with the size shown on the top bar (T-250's text). A height 6 can stand on a height 3 (`on`, as today) or straight on the ground. Snapping (T-237) and the overlap refusal still apply.
2. **Ramps in all four climb directions** (north, east, south, west) at 0 to 3 and 3 to 6, plus 0 to 6 if the height data allows it (your call; say so). Rotate (R) steps through the four directions. A ramp's width along the rooftop's side can be dragged too (at least 4 units); its length stays a fixed proposal per height step.
3. **Drawn in the engine, not as fixed pictures:** the new pieces are drawn from tileable textures projected onto each face (the top, and the east and south walls, which are the visible ones), the same projection `build_elevation_sample_art.py` uses (`screen x = (x-y)*32`, `screen y = (x+y)*16 - h*32`), nearest filtering, hard pixel edges, with a dark outline on the edges as the sample art has. For now use the T-198 textures in `art-archive/T-198/` (or the sample art's) as placeholders; T-255 swaps in new textures, so keep each texture (roof top, wall, ramp surface, ramp side, edge or parapet strip) a setting in one scene or resource. The fade and depth order (`silhouette`, `covers`) keep working.
4. **The game's own map is unchanged:** pieces with `art` (the sample map's) still draw as today; only pieces without it use the new drawing. Saved levels pass `python game/tools/check_level.py`, and enemies find their way up and down the new ramps (their pathfinding reads the same data).
5. **Catalogue:** `build_creator_assets.py` writes the resizable rooftop and ramp entries (rebuild `creator_assets.json`).

Built on the level creator's build: the Project Lead makes your folder from `playtest/G-005`, not `master`. Every label comes from `creator_texts.json` (T-250). End with screenshots of a small multi-layer level built in the creator (rooftops of three sizes, a 6 on a 3, ramps in all four directions) and a short GIF of the car driving up and down it in a run.

## Acceptance criteria

- [ ] Tests show a rooftop can be placed at any even size from 4 x 4 up, at heights 3 and 6 (on a 3 and on the ground), and ramps in all four directions at 0 to 3 and 3 to 6, with the saved level passing `check_level.py` (QA: pass / fail)
- [ ] Tests show the game's own map and its pieces draw and play as before, and enemies path up a new ramp (QA: pass / fail)
- [ ] Textures are settings in one place; labels come from `creator_texts.json`; no Redgull red (QA: pass / fail)
- [ ] Screenshots and a GIF of the car driving the built level are in `art-archive/T-251/screenshots/`; `game/README.md` "Level creator" describes the new pieces; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: build a level with rooftops of several sizes and ramps in every direction, and drive it.
Board review files: the screenshots and GIF in `art-archive/T-251/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Blocked → In progress

Started: rooftops of any size and ramps in all four directions, drawn in the engine.

## Result notes

Level/Challenge Design Agent, 2026-10-22. Built on the branch's G-005 creator plus T-250's text.

**What was built**
- **Rooftops of any size** (`rooftop-3`, `rooftop-6`): pick, press on the map, drag, release; the piece covers the dragged cells (even units, at least 4 x 4, at most the map). A click without a drag places the default size. A 6 stands on a 3 (`on`) or on the street. Snapping (T-237) and the overlap refusal apply to the dragged rectangle; a piece that would reach out of the map is not placed.
- **Ramps in four directions** (`ramp-0-3`, `ramp-3-6`, and **`ramp-0-6`**, which the height data allows): R steps north, east, south, west (the direction it climbs; `side` is the rooftop's opposite side). The drag sets only the width along the rooftop's side (at least 4); the length is fixed.
- **Drawn in the engine:** `elevation_platform_drawing.gd` textured mode. It draws the top and the east and south walls as textured polygons in the sample art's projection, mirror-tiled, with nearest filtering. Walls start on what the piece stands on. It adds a dark outline and a parapet on the back edges, with gaps where ramps meet an edge or a higher rooftop stands on it. A ramp has no wall at its top end. Depth order, fade, ground height and enemy pathfinding read the same data, unchanged.
- **Textures in one place:** `game/art/creator_pieces/piece_style.tres` (`scripts/level/piece_style.gd`): roof top, wall, ramp top, ramp side, parapet, plus the shades and the outline. The placeholders are T-198's textures with the sample art's colour fix, and the panel icons are rendered from them. `game/tools/build_creator_piece_art.py` makes both (build / check). T-255 swaps in new textures by editing the .tres only.
- **The game's own map is unchanged:** pieces with art (the sample map's, and creator pieces saved before T-251 with `art`) draw as before.
- **Catalogue:** `build_creator_assets.py` `elevation_entries` now writes the five resizable entries (`resizable`, `style`, `min_size_units` or `length_units`/`width_units`/`min_width_units`). `creator_assets.json` is rebuilt. T-252's catalogue changes should merge by re-running the builder.
- **Top bar:** `size_hint` while a resizable piece is picked, and `size_readout` during a drag. A picked ramp shows `ramp_dir_*` and its height label, with `ramp_height_0_6` for the new ramp. The bottom line is `controls_hint_sizing`. The bar now wraps onto a second line (HFlowContainer) so the extra labels fit.

**Proposals for the playtest** (Level design, Content, "Level creator: rooftops of any size and ramps in every direction")
- Default size on a click: the sample map's, 84 x 30 at 3 and 30 x 30 at 6.
- Ramp length is fixed at the sample map's slope, 12 units per 3 of rise: 12 for 0 to 3 and 3 to 6, 24 for 0 to 6. The default width is 10; the minimum width is 4.
- A 0 to 6 ramp is added. It works from the street to a 6 on the street, or to a 6 on a 3 whose edge it shares; elsewhere it is refused as an overlap.
- The rooftop panel icons are 12 x 12 pieces rendered with the placeholder textures; the ramp icons climb north.
- The T-198 extras (AC units, vents, sign, cracks) are not drawn on pieces of any size. Neither is the sample art's lighter rim: only the dark outline is.

**Tests**
- New: `game/tests/unit/level_creator/test_creator_pieces_any_size.gd` covers:
  - sizes from 4 x 4, at 3 and 6, on a 3 and on the street
  - every direction at 0 to 3, 3 to 6 and 0 to 6
  - dragging, and the labels from the texts
  - textures only from the one style, with no Redgull red
  - the game map keeping its art
  - enemies pathing up the new 0 to 6 and 3 to 6 ramps
  - `check_level.py` passing on the saved levels
- New: `game/tools/test_build_creator_piece_art.py`.
- Updated: the T-236, T-237 and T-238 creator tests (new view semantics), `test_creator_assets.gd`, `test_build_creator_assets.py`.
- Full GUT suite (`bash game/tools/run_tests.sh`): 1386 of 1386 passed. Python: `game/tools` 423 tests OK, `tools` 439 tests OK.

**Screenshots** (`art-archive/T-251/screenshots/`)
- `creator.png`: the multi-layer test level in the editor (rooftops 48 x 32 and 16 x 16 at 3, 14 x 12 on the 3 and 16 x 16 on the street at 6, ramps in all four directions).
- `creator_close.png`: close-up.
- `drag_rooftop.png`: a rooftop being dragged, "Size: 32 x 18".
- `drag_ramp.png`: a ramp snapped onto a side, "Climbs north", "Size: 10 x 12".
- `drive.gif`: the level played in a run, with the car driving up each ramp direction and off the rooftops' edges, including a 6 drop.
- `drive_end.png`: the last frame of that run.

**Refusals:** one. A standalone `timeout ... godot --headless --import` was refused by the ticket-guard hook. I skipped it; the test runner and `screenshot.sh` import first anyway.

**Documents affected:** `docs/level-design.md` (new Content section), `game/README.md` (Level creator: catalogue line, the T-236 note, the new "Rooftops and ramps of any size (T-251)" point).
