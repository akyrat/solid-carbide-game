---
id: T-391
title: Bug: roads painted in the level creator don't show up when the level is played
status: done
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
files_to_read_first: [tasks/README.md, docs/level-design.md, game/docs/level/level-creator.md, game/docs/level/level-creator-pieces.md, game/scripts/level_creator/, game/scripts/level/]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/level/, game/scripts/run/, game/tests/unit/, game/docs/level/, docs/level-design.md, art-archive/]
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

The board's decision (Level design, Decisions, "Roads painted in the creator show in the run", 2026-10-29; a bug the board wants fixed at once): "when I place roads on the ground, they don't show up in the playable level." Reproduce it: paint roads with the creator's road brush (each road kind, junctions, a crossing) in a new level, save it, press Play, and see which roads the run draws. The board's own levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked): read them to reproduce (copy a file into a test folder; never change or commit the board's files). Find the cause (for example the saved ground data, the run's ground layer, the catalogue's tile ids, a draw order, or the ground under the roads) and fix it so every road painted in the editor is drawn in the run, on the street and next to rooftops and ramps. Earlier levels and the game's own map must look as before.

The board's review: paint some roads in the creator, press Play and drive on them.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test paints roads of every kind (with a junction and a crossing) in a level, saves it, builds the run from it and checks each painted cell is drawn with its road tile (it fails before the fix, named in the result notes). (QA: pass: the 6-test file covers every road kind, junction and crossing, and fails before the fix per the notes)
- [ ] The cause is written in the result notes, and the board's levels in game/data/levels/ are unchanged and uncommitted. (QA: pass: cause written; game/data/levels/ is untracked)
- [ ] The game's own map and an earlier level still build the same ground as before (tests). (QA: pass: tests for the game's own map and an earlier level are green)
- [ ] Level design, Content and game/docs/level/ describe the fix. (QA: pass: level-design.md and level/level-creator.md changed and committed; qa_check's documents line flagged only the folder name)
- [ ] A screenshot of a run on a level with painted roads is in `art-archive/<id>/screenshots/`. (QA: pass: run_painted_roads.png shows painted roads, rooftop and ramp)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass: qa_check ran all three sets green; counts 668 / 573 / 1939 in the notes)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started at once on your word: the Level/Challenge Design Agent is finding why painted roads don't show in the run.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

### Level/Challenge Design Agent, 2026-10-29

**The cause.** The run's map (`game/scripts/level/mvp_map.gd`, `_ready`) always loaded the game's own ground, `data/level/mvp_ground.json`, and never read the level file's `ground` (the tiles the creator saves). Only the editor turned a level's `ground` into a ground layout (`LevelDocument.ground_layout`, set on the map by `editor.gd`). So every road, junction and crossing painted in the editor was saved correctly but missing in the run, where the game's own streets and gravel were drawn instead. The saved data, the catalogue's tile ids and the draw order were fine: all the tile ids in the board's three levels (`kaiju_city`, `level_01`, `mynewlevel`, read only) are in the catalogue with an atlas index.

**The fix.** One place builds the ground layout from a level: new `game/scripts/level/level_ground.gd` (`LevelGround`: `layout_of(level)`, `layout_from_ids(rows, origin)`, `values()`, `EXTRA_BASE`). It is under `scripts/level/`, not `scripts/level_creator/`, because the run uses it and the creator's scripts are to be left out of an export. `mvp_map.gd` now draws `LevelGround.layout_of(layout)` when the layout has the creator's `ground`, and `GROUND_PATH` otherwise; `LevelDocument.ground_layout()` calls `LevelGround.layout_from_ids`, so the editor and the run draw the same layout.

**What changes for levels.** Every level saved by the creator now plays on its own ground. Note for the board: `level_01` (all gravel) used to show the game's streets in the run; it now shows plain gravel, as in the editor. The game's own map (`elevation_sample_map.json`, no `ground`) and any level file without the creator's ground draw `mvp_ground.json` exactly as before.

**Tests.** `game/tests/unit/level_creator/test_creator_roads_in_run.gd` (6 tests): paints Road (crossroads, dead ends), Centre line (crossroads, T-junction, corner), Cracked road with a zebra crossing, and a rooftop and ramp beside a road, saves into a RunPaths folder, starts a run on it (`GameFlow.add_run`, the creator's Play path) and checks every painted cell is drawn with its road tile and that the run's layout equals the editor's; the game's own map and the MVP map draw `mvp_ground.json`; a level without `ground` plays on `mvp_ground.json`; the earlier saved level `tests/fixtures/t262_level_saved_before.json` draws its saved ground; `LevelGround` unit checks. **Fails before the fix:** with the old `mvp_map.gd`, `test_every_painted_road_cell_is_drawn_in_the_run_with_its_tile` (261 painted cells drawn with another tile) and `test_a_level_saved_before_draws_its_own_saved_ground` fail.

**Board's levels.** `C:\solid-carbide-game\game\data\levels\` was only read (tile ids checked with a Python one-liner); nothing was written there or copied into the repo, and nothing from it is committed.

**Screenshots.** `art-archive/T-391/screenshots/run_painted_roads.png` (a run on a level with painted roads: centre-line road crossing a plain road, rooftop and ramp beside it; `bash game/tools/screenshot.sh res://tests/fixtures/level_creator_roads_run_demo.tscn art-archive/T-391/screenshots/run_painted_roads.png 120`) and `editor_painted_roads.png` (the same level in the editor, `level_creator_roads_run_demo_editor.tscn`).

**Docs.** `docs/level-design.md`, Content, "Level creator: the road brush" ("In the run (T-391)" and the screenshot); `game/docs/level/level-creator.md`, "Painted roads in the run (T-391)".

**Test counts (run once at the end, foreground).** `python -m unittest discover -s game/tools -p "test_*.py"`: 668 tests, OK (1 skipped). `python -m unittest discover -s tools -p "test_*.py"`: 573 tests, OK. `bash game/tools/run_tests.sh`: 1939 tests, 1939 passing, 1246782 asserts, TESTS PASSED.

Documents affected: `docs/level-design.md`, `game/docs/level/level-creator.md`.

### QA, 2026-10-29

All six criteria pass. qa_check: tests PASS (three sets), screenshots PASS; its documents line failed only because the ticket lists the folder game/docs/level/ and not a file (the file in it changed and is committed). The board played it and approved ("road fix lgtm").
- 2026-10-29, needs-playtest → done: The board played it: road fix lgtm (2026-10-29).
