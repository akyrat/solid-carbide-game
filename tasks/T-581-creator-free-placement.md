---
id: T-581
title: Free placement in the level creator, Shift to snap
status: in-progress
from: project-lead
to: level-challenge
lead: Rails
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/docs/level/level-creator.md, game/docs/level/level-creator-pieces.md, game/scripts/level_creator/snapping.gd, game/scripts/level_creator/editor.gd, game/scripts/level_creator/level_document.gd, game/tools/check_level.py]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/level/, game/scripts/enemies/, game/tools/check_level.py, game/tools/check_height_data.py, game/tools/, game/tests/, game/docs/level/, docs/level-design.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Build Level design, Decisions, "Free placement in the level creator". Every piece (props and boulders, buildings, rooftops and ramps, rails, and the hint pieces once T-576 adds them) follows the mouse freely and is placed where it is dropped; holding Shift (a proposal) gives today's snapping (the 2 x 2 tile grid and the neighbour and ramp-to-rooftop snaps, snapping.gd). Rotation and views are unchanged; ground and road tiles stay painted on tiles. Moving a placed piece works the same way. Propose and explain the finest step (for example a quarter unit or one screen pixel) so saved files stay tidy. The hard part is the rest of the game: today every building, rooftop and ramp edge lies on even units because the enemies' navigation (enemy_navigation.gd, CELL 2) and check_level.py rely on it. Make collision, rooftops and ramps (the ramp still links only when its top end reaches its rooftop's side; propose how close counts without Shift), the enemies' paths, check_level.py and check_height_data.py work with pieces off the grid, and say what you changed. Levels saved before (on the grid) load and play the same; read the board's levels in game/data/levels/ only to check they still load and pass check_level.py, never write there. Rails and hint pieces already use their own positions; keep them consistent.

The board's review: play it from C:\solid-carbide-worktrees\T-581: open the level creator (`"C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" --path "C:\solid-carbide-worktrees\T-581\game" res://scenes/level_creator/level_creator.tscn`), place pieces freely and with Shift, save, press Play.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/ (the board's own levels; you may read them to check they still load). Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Without Shift, each kind of piece is placed where the mouse drops it, at the proposed step; with Shift it snaps as today (tests for each kind). (QA: pass / fail)
- [ ] A ramp off the grid links to its rooftop when its top end reaches the side, and the car drives up it (tests). (QA: pass / fail)
- [ ] Off-grid buildings and rooftops block the car and are walked round by minions; check_level.py and check_height_data.py accept a good off-grid level and still refuse bad ones (tests). (QA: pass / fail)
- [ ] Levels saved before load, pass check_level.py and play as before, including the board's levels in game/data/levels/ (read only; listed in the result notes). (QA: pass / fail)
- [ ] docs/level-design.md Content and game/docs/level/ describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots or a GIF in art-archive/T-581/screenshots/ show pieces placed off the grid, with and without Shift, and a run on that level. (QA: pass / fail)
- [ ] Added by the board, 2026-11-08 ("I want to be able to move things on the map, like obstacles that I place, and the decoration as well"): every placed piece (obstacles, paired obstacles with their pairs following, props and decorations, buildings, rooftops and ramps with their links updated) can be selected and dragged to a new place, freely or with Shift to snap, refused like a placement where it can't go; the moved piece keeps its id; tests and a screenshot or GIF for each kind. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: Level Design builds free placement with Shift to snap.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

### Level/Challenge Design Agent, 2026-11-08: free placement, Shift to snap, and moving placed pieces

**What was built**
- **Free placement (no Shift):** every piece follows the mouse: buildings (skyscrapers, low-rise, small, long), boulders, props (obstacles and decoration), meteor craters, rooftops and ramps, rails, standing kaiju alert signs and the spawn point. The piece's top-left corner (the outline's top corner on screen) goes where the mouse is, rounded to the step. A piece dropped at the map's edge is moved in so it is wholly on the map. Rooftops and ramps of any size drag to any size on the step (the top bar shows sizes such as 12.25).
- **Proposed step: a quarter unit** (`LevelDocument.FREE_STEP` = 0.25). At the creator's zoom it is finer than the eye can see. Every corner lands on whole art pixels (4 px across and 2 px down; a sixteenth, which is one map pixel, would put corners on half pixels). It is exact in binary, so the checks' "this edge lies on that side" comparisons stay exact. Saved numbers have at most two decimals (13.75).
- **Shift held (a proposal; set from every mouse event and the Shift key):** everything snaps as before: the 2 x 2 tile grid, the neighbour edges, the ramp onto its rooftop's side (4 units), rail ends on half units, the spawn on its cell's middle. Shift+click with nothing picked still picks a pair row (T-394).
- **Ramps without Shift (proposal: `LevelSnapping.FREE_RAMP_REACH` = 1 unit, half a cell):** a ramp whose top end comes within 1 unit of the side it climbs, on a rooftop at its top height, goes onto that side and links. Farther away it stays where it was dropped, unlinked, and check_level.py refuses it as before.
- **Unchanged:** rotation and the views. Ground, road and sidewalk tiles are still painted on tiles. A banner still goes on its skyscraper's wall.
- **Moving placed pieces (added scope, the board 2026-11-08):** with nothing picked, press on any placed piece and drag it, as a rail is dragged. It moves free on quarter units, or snaps with Shift. A blue outline shows where it lands, and turns grey when the move would be refused; refusals are the same as for placing (into a building, across a rooftop's edge, onto another rooftop, cutting an object, over the start, off the map). On release a refused piece stays where it was and the same message shows. A click only selects, and Esc cancels the drag. The piece keeps its id, so a paired obstacle keeps its pairs and their line follows it. A ramp's link updates: dragged off its rooftop it is unlinked, and dragged back within 1 unit of the side it links again.
  - **Proposal:** a rooftop (or a low-rise, small or long building, which are platforms) takes along what stands on it: the rooftops on it, the ramps on it or climbing it, and the objects wholly on it. A skyscraper takes its banners.
  - **No undo step:** the creator has no undo, so there is none.
  - **Hint pieces (T-576):** they are not merged yet. The move path is generic (any piece whose item is a rectangle {x, y, w, h}), so they will get it.
- **The game off the grid:**
  - The car's walls (mvp_map.gd) and the heights and rooftop edges (ground_height.gd) already use each piece's own rectangle.
  - enemy_navigation.gd keeps its 2 x 2 cells. A building closes every cell whose centre is within the body's radius. Heights are read at cell centres, and a cell an edge passes through is "rough", so line_clear checks the true ground there (built for T-405's half-unit platforms). Only the comments changed.
  - check_height_data.py needed no change (it already compares with a tolerance).
  - check_level.py now requires edges on quarter units instead of even units.
  - level_document.gd's refresh_ground_rows now marks every unit an off-grid building covers part of.

**Files:** game/scripts/level_creator/{snapping.gd, editor.gd, level_document.gd, rail_piece.gd}, game/scripts/enemies/enemy_navigation.gd (comments), game/tools/check_level.py; tests: game/tests/unit/level_creator/test_creator_free_placement.gd and test_creator_move_pieces.gd (new); the grid tests now hold Shift (snap_held = true) in test_snapping.gd, test_creator_alert_signs.gd, test_creator_pieces_any_size.gd, test_creator_props.gd and test_creator_spawn.gd; test_creator_rails.gd and test_editor_place_delete.gd check both modes; game/tools/test_check_level.py and test_check_height_data.py (TestOffTheGrid); fixture game/tests/fixtures/t581_free_placement_demo.gd/.tscn.

**Tests**
- New: every kind free and with Shift, the key and the mouse, drag sizes, rails, the spawn, a ramp linking within the reach and not beyond, the car driving up an off-grid ramp onto its rooftop, the car stopped by an off-grid skyscraper and an off-grid rooftop, minions' paths round off-grid buildings and rooftops and up an off-grid ramp, check_level.py and check_height_data.py on an off-grid level, Kaiju City and the board's levels reopening unchanged; moving each kind, Shift snapping while moving, click only selects, mouse and Esc, pairs kept, the garage carried along, the ramp unlinking and relinking, every refusal, the map edge, the banner following, and save, reopen and heights.
- check_level.py: quarter-unit edges are accepted, others refused, and an off-grid ramp that misses its rooftop's side is refused. check_height_data.py: a good off-grid level passes, and a ramp a quarter unit short, a ramp past its side's end and overlapping rooftops are refused.
- **Godot full set (`bash game/tools/run_tests.sh`): 3088 tests, 3087 passing, 0 failing, 1 pending (TESTS PASSED).** The game tools set (`python -m unittest discover -s game/tools -p "test_*.py"`): 1054 tests, OK (4 skipped).

**Levels saved before (read only, never written):**
- `C:\solid-carbide-game\game\data\levels\kaiju_city.json`: check_level.py OK.
- `level_01.json` and `mynewlevel.json`: check_level.py prints exactly the same problems with master's check_level.py and with this branch's. They are unlinked ramps, and level_01 has no spawn point. These problems were already in the files, not caused by this ticket.
- All three open in the creator with their buildings, rooftops, ramps, props, rails and boulders unchanged (test_the_boards_levels_still_open_unchanged).
- The game's own maps (kaiju_city_map.json, practice_playground.json, elevation_sample_map.json) pass check_level.py.
- On-grid levels take the same code paths in the run as before.

**Screenshots** (art-archive/T-581/screenshots/):
- free.png: pieces placed off the grid, and the preview following the mouse.
- shift.png: the same clicks with Shift held, on the grid.
- run_on_free_level.png: a run on the free level, the car up the off-grid ramp on the off-grid rooftop.
- move_before.png, move_drag.png, move_after.png, move_refused.png: before; the garage dragged with outlines for it and what it carries; every kind moved, the pair's line following; a skyscraper dragged onto an object, with a grey outline.

**Documents affected:** docs/level-design.md (Content: "Level creator: free placement (task T-581)", with moving; the rail and spawn lines), game/docs/level/level-creator.md ("Free placement (T-581)", "Moving a placed piece (T-581, added scope)", Validator, Controls, Snapping).

**For the board's playtest (proposals):** the quarter-unit step; Shift as the snap key; the 1-unit ramp reach without Shift; a rooftop carrying what stands on it.
