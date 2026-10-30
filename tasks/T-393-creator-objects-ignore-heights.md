---
id: T-393
title: Bug: barriers and other objects in the level creator ignore the heights of buildings and rooftops
status: in-qa
from: project-lead
to: level-challenge
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/level-design.md, game/docs/level/]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/docs/level/level-creator.md, game/docs/level/level-creator-pieces.md, game/docs/level/elevation-sample-map.md, game/scripts/level_creator/, game/scripts/level/]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/level/, game/tests/unit/, game/docs/level/, docs/level-design.md, art-archive/]
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

The board's decision (Level design, Decisions, "Obstacles and decorations respect the buildings' and rooftops' heights", 2026-10-29; a bug the board wants fixed at once): "When I put the barriers [they] ignore heights of buildings. And I think this might be the case with other objects as well. Please look into the root cause and fix it." The board's screenshot: `C:\Users\andre\Pictures\Screenshots\Screenshot 2026-10-29 235513.png` (read it): a row of barriers on the street running towards a raised rooftop; the last barriers are drawn over the rooftop's edge and its AC units as if the rooftop weren't there, and a barrier sits where the rooftop is.

Find the root cause, for every kind of placed object (barriers, boulders, cones, crates, street lamps, AC units, water tanks, roof vents, rooftop signs), for example: the object's height not taken from what is under it (street, rooftop 3 or 6, ramp), its draw order (y-sort or z-index) not accounting for the rooftop's height, or the creator letting an object be placed half on a rooftop's edge. Fix it so each object sits at the height of what it stands on and is drawn in front of or behind buildings and rooftops correctly, in the editor and in the run; decide (and write as a proposal) what happens when an object is placed across a rooftop's edge (for example refused like a road over a building, or snapped to one side). The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked; `kaiju_city.json` is the one in the screenshot): read copies only, never write or commit them. Earlier levels and the game's own map must look as before where nothing was wrong.

The board's review: place barriers and other objects next to and on a rooftop in the creator, and press Play.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The root cause is written in the result notes for each kind of object, with a test that fails before the fix (named) for the barrier next to a rooftop. (QA: pass)
- [ ] Every kind of placed object sits at the height of what it stands on (street, rooftop 3 and 6, ramp) and draws in front of or behind buildings and rooftops correctly, in the editor and in the run (tests). (QA: pass)
- [ ] Placing an object across a rooftop's edge does what the result notes propose (test). (QA: pass)
- [ ] The game's own map and an earlier level build as before (tests), and the board's level files are unchanged and uncommitted. (QA: pass)
- [ ] Level design, Content and game/docs/level/ describe the fix and the proposal. (QA: pass; qa_check's documents line flags game/docs/level/ as a directory, but level-creator-pieces.md changed on the branch)
- [ ] Screenshots of the board's case (barriers by a rooftop) before and after, in the editor and in the run, are in `art-archive/<id>/screenshots/`. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass; qa_check ran all three sets green)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started at once on your word: the Level/Challenge Design Agent is finding why placed objects ignore buildings' and rooftops' heights.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Level/Challenge Design Agent, 2026-10-30. Commit `ee5b4a0a` on `task/T-393-creator-objects-ignore-heights`.

**The board's case, reproduced** on the copy of `kaiju_city.json`: the barriers run along y 56..57 into the low-rise `short-0` at x -42..-30, y 52..64. Barrier `prop-18` (x -48..-44) stands just west of the low-rise, so behind it, and overlaps it on screen; it had z 137 (the top of everything) instead of under the low-rise (z 116). Barrier `prop-19` (x -44..-40) stands 2 units inside the low-rise's footprint. The AC units and water tanks in the screenshot are the low-rise's own roof art, not placed props.

**Root cause, per kind of object**

- **All eight props (barrier, cones, crates, street lamp, AC unit, water tank, roof vent, rooftop sign) and boulders: drawn over a building they are behind.** On any map with rooftops or ramps, the elevation layer (`elevation_layer.gd` `restack`) gives the buildings new z_index values in one order with the areas, up to its own `top_z_index()`. The rule that places boulder and prop sprites in the depth order (`elevation_layer.gd` `boulder_z`, `mvp_map.gd` `_boulder_z`) still read "no building covers it" as "z at or above the map's own `own_top_z_index()`", which is lower than the restacked buildings' z (Kaiju City: 110, against buildings up to 131). So a covering building late in the order (the low-rise) gave a z above that line, was read as "none", and the object was put over everything. Same code path for every kind of object, in the editor and in the run (both build `mvp_map.gd` + `elevation_layer.gd`). Levels without rooftops were not affected.
- **Boulders: wrong height.** A boulder's sprite always stood at street level (`mvp_map.gd` `boulder_sprite_rect` had no height), so a boulder on a rooftop or ramp was drawn on the street under it. Props already stood at the height under their centre (`level_props.gd`).
- **Props and boulders on a rooftop: depth against areas.** The areas' depth test treated every object as standing at height 0 (`is_behind(centre, 0, 0)`), so an object on a 3 counted as under a neighbouring 3 it is level with.
- **Every object, in the editor: no rule for edges and buildings.** Nothing stopped an object being placed into a building or across a rooftop's or ramp's edge (the board's last barrier). There it has no single height and no single place in the depth order.

**The fix**

- `mvp_map.gd`: `_boulder_z_buildings(centre, outline, top)` starts from `top`. `_boulder_z(centre, outline, ground)` passes the elevation layer's `top_z_index()` when there is one, so a covering building always lowers the z. `ground_height_at(units)` reads the layout's rooftops and ramps (`ground_height.gd`). Boulder sprites carry `ground_units`, and `boulder_sprite_rect` lifts the sprite by it.
- `elevation_layer.gd`: `boulder_z` starts from its own top. `boulder_z_under_areas(z, centre, outline, ground)` compares areas with the object's own height.
- `level_props.gd`: prop sprites carry `ground_units` and pass it to the depth rule.
- `editor.gd`: the boulder preview is lifted to the height under it (props already were). `place_asset` applies the edge rule below.
- `snapping.gd`: `object_problem` and `cuts_object_problem`.

**The edge proposal (for the board's playtest).** An object stands wholly on one surface: the street, one rooftop or one ramp. A boulder or prop whose footprint would reach into a building, or across the edge of a rooftop or ramp, is not placed. Touching a building or an edge is allowed. It is refused like an overlapping rooftop, with the existing `overlap_message` ("Can't place here: it overlaps another piece."), so there is no new text. The other way round: a building placed over an object, or a rooftop or ramp whose edge would cut through one, is not placed either, and a rooftop or ramp placed wholly over an object lifts the object to its height. Because every edge is on even units, 2 x 2 props can't be cut. Only the 4-unit sides of barriers, signs and tanks can be, plus 3 x 3 boulders. Levels saved earlier keep what they have and load as before: the rule applies only when placing. For example, Kaiju City's `prop-19` stays inside its low-rise and is now drawn under it. `check_level.py` doesn't check the rule (not asked; it could be added).

**Tests.** New file `game/tests/unit/level_creator/test_creator_objects_heights.gd`, 7 tests:
- `test_a_barrier_behind_a_low_rise_is_drawn_under_it_in_the_editor_and_the_run` is the board's case. It fails before the fix: z 11, expected < 8, in both the editor and the run. Checked by stashing the fix and running it.
- `test_a_boulder_behind_a_low_rise_is_drawn_under_it`.
- `test_every_object_stands_at_the_height_of_what_it_stands_on_in_the_editor_and_the_run`: all 9 kinds on the street, on a 3 and on a 6, plus two on a ramp's slope.
- `test_objects_are_drawn_behind_or_in_front_of_rooftops_by_where_they_stand`.
- `test_an_object_across_a_rooftop_or_ramp_edge_or_into_a_building_is_not_placed`.
- `test_a_building_rooftop_or_ramp_that_would_cut_through_an_object_is_not_placed`.
- `test_the_game_map_and_a_level_without_rooftops_draw_their_objects_on_the_ground_as_before`.

**Test counts**
- `python -m unittest discover -s game/tools -p "test_*.py"`: 668 tests OK (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: 573 tests OK.
- `bash game/tools/run_tests.sh`: 1946 tests, 1945 passing, 1 failing. The failure was `tests/unit/run/test_run_likes.gd` `test_run_scene_drift_pays_its_combo_once_when_it_ends`, which waits a set number of physics frames for a drift (1.12 s measured, expected 1.5..1.7). It passes when its file is run again on its own (37/37). It looks like load-dependent timing: another Godot was running for the goal run. It doesn't touch the code changed here.

**Screenshots** in `art-archive/T-393/screenshots/`, the board's Kaiju City case:
- `before_editor.png` and `after_editor.png`: in the editor, the barrier behind the low-rise was drawn over it; now the low-rise hides it.
- `before_run.png` and `after_run.png`: the same in a run, car parked beside the barriers.

They come from the fixtures `game/tests/fixtures/creator_objects_heights_demo.tscn` and `_run.tscn`, which read the untracked copy `game/data/levels/kaiju_city.json` (not committed; the board's originals were not touched).

**Documents affected**
- `docs/level-design.md`: Content, new "Level creator: objects, heights and depth"; the Props bullet updated.
- `game/docs/level/level-creator-pieces.md`: "Heights and depth of placed objects (T-393)"; the props placement line updated.

Board review files: art-archive/T-393/screenshots/before_editor.png, art-archive/T-393/screenshots/after_editor.png, art-archive/T-393/screenshots/before_run.png, art-archive/T-393/screenshots/after_run.png
