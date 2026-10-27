---
id: T-238
title: Level creator: save a level, and reopen it
status: done
from: project-lead
to: level-challenge
lead: Goal-G-005
epic: level-challenges
milestone: mvp
goal: G-005
user_facing_text: yes
changes_visuals: yes
depends_on: [T-233, T-231, T-235, T-236, T-237]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/data/level/creator_texts.json, game/scripts/level/level_store.gd, game/tools/check_level.py, game/scripts/level_creator/editor.gd, game/scripts/level_creator/level_document.gd, game/scripts/level_creator/level_list_screen.gd, game/scripts/level/mvp_map.gd, game/data/level/elevation_sample_map.json]
files_expected_to_change: [game/scripts/level_creator/editor.gd, game/scripts/level_creator/level_document.gd, game/tests/unit/level_creator/test_editor_save.gd, game/README.md]
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

Saving in the creator (Level design, Decisions, 'Level creator', board 2026-10-21): the save button (label from creator_texts.json) writes the level, under the name in the editor's level name field, through level_store.gd's save_level into the levels folder, in the same map-file format the elevation map uses: map, legend, ground_rows, buildings, boulders as pattern_copies, platforms and ramps, so the run, the heights and enemy pathfinding read it unchanged. The saved file must pass game/tools/check_level.py. After saving, the editor shows the save confirmation from creator_texts.json, and going back to the list shows the level. Opening elevation_sample_map.json in the editor and saving it must give a file the run builds into the same buildings, boulders, platforms and ramps. Tests write only into a temporary levels folder. Add saving to game/README.md, 'Level creator'.

The board's review: In the level creator, save a level, go back to the list, find it and open it again.

## Acceptance criteria

- [ ] A unit test saves a level with one piece of every kind: the file is written to the (temporary) levels folder, has map, legend, ground_rows, buildings, pattern_copies, platforms and ramps, and passes python game/tools/check_level.py. (QA: pass)
- [ ] A unit test opens elevation_sample_map.json in the editor and saves it to a temporary path; mvp_map.gd and the elevation layer built from the saved file have the same buildings, boulders, platforms and ramps as built from the original. (QA: pass)
- [ ] A unit test: after saving, the list screen lists the saved level by name. (QA: pass)
- [ ] The save confirmation shown is the one in creator_texts.json, and the test that scans the creator's scripts for hard-coded label strings still passes. (QA: pass)
- [ ] game/README.md, 'Level creator', says how to save and where the file goes. (QA: pass)
- [ ] A screenshot of the editor showing the save confirmation is in art-archive/<this task's id>/screenshots/ and listed in the result notes. (QA: pass)
- [ ] The full GUT suite passes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Blocked → In progress

Goal runner (G-005): started, in C:\solid-carbide-worktrees\T-238.

### 2026-10-22, In progress → In QA

Goal runner (G-005): the agent is done; QA is checking it.

### 2026-10-22, In QA → Needs playtest

Goal runner (G-005): QA passed; merged into playtest/G-005.

## Result notes

Written by the agent when it finishes.

**Level/Challenge Design Agent, 2026-10-22 (goal G-005).** Done; commit `776f6bb` on this branch.

What was built:
- `scripts/level_creator/editor.gd`: the top bar now has the **Level name** label and field (`name_field_label`) and a **Save** button (`save_label`). `save()` writes `LevelDocument.file_data(level_name())` with `LevelStore.save_level` to `save_path()` and shows `save_confirmation` in the top bar's message label; it emits `saved(path)`. The editor has a `levels_dir` (default `LevelStore.LEVELS_DIR`), which `level_creator.gd` now passes on from the creator, so the list and the editor use the same folder.
- `scripts/level_creator/level_document.gd`: `file_data(name)` (sets `name`, makes sure `map` with width/height/rect, `legend`, `ground_rows`, `buildings`, `pattern_copies`, `platforms`, `ramps` are there, returns a deep copy; an opened file keeps its keys unchanged) and `file_stem(name)` (the file name).
- **Which file (proposals for the board's playtest, the docs don't say):** a level opened from the levels folder is saved over its own file; a new level, or a file opened from elsewhere (the game's own `elevation_sample_map.json`, never overwritten), gets a new file in the levels folder named after the level (lower case, spaces as `_`), with `-2`, `-3`... when that file already exists; later saves go to that file. An empty name saves under the default name ("New level"). Renaming an already-saved level changes its `name` but keeps its file name. A failed save shows nothing (creator_texts.json has no failure text; no placeholder text added).
- Also writes the creator's `ground` key (the ground and road tiles), which the run ignores, so reopening keeps the tiles.

Tests: `tests/unit/level_creator/test_editor_save.gd` (7 tests, all files in a temporary `RunPaths` folder):
- AC1 `test_save_writes_every_kind_in_the_map_format_and_passes_check_level`: ground, road, building, boulder, rooftops 3 and 6, ramps 0-3 and 3-6; the file has every format key and passes `check_level.py` (run with `OS.execute`).
- AC2 `test_the_sample_map_opened_and_saved_builds_the_same`: mvp_map.gd (`layout_path`) and the elevation layer (`setup`) built from the original and the saved file have the same building footprints, boulders, platforms, ramps and area count.
- AC3 `test_after_saving_the_list_shows_the_level_and_edit_reopens_it`.
- AC4 `test_saving_shows_the_confirmation_from_the_texts`; `test_creator_texts_only.gd` still passes.
- Plus: same file on a second save / a second level of the same name gets its own file; empty name; `file_stem`.
- Full GUT suite: 1373/1373 passed (`bash game/tools/run_tests.sh`).

README: `game/README.md`, "Level creator", new bullet "Saving (T-238)".

Screenshots: `art-archive/T-238/screenshots/saved.png` (the editor after Save: name field "Rooftop corner", "Level saved." on the top bar), from the new fixture `tests/fixtures/level_creator_save_demo.tscn` (saves into a temporary folder, never `data/levels/`).

PixelLab: 0 generations. Refusals: none. Documents affected: none (game/README.md only).
- 2026-10-22, in-qa → needs-playtest: QA passed every criterion (goal G-005).
- 2026-10-27, needs-playtest → done: The board's playtest of the creator build (playtest/creator-set, 2026-10-28): every check ticked on the playtest page, everything works fine.
