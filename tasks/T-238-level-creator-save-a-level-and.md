---
id: T-238
title: Level creator: save a level, and reopen it
status: blocked
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

Saving in the creator (Level design, Decisions, 'Level creator', board 2026-10-21): the save button (label from creator_texts.json) writes the level, under the name in the editor's level name field, through level_store.gd's save_level into the levels folder, in the same map-file format the elevation map uses: map, legend, ground_rows, buildings, boulders as pattern_copies, platforms and ramps, so the run, the heights and enemy pathfinding read it unchanged. The saved file must pass game/tools/check_level.py. After saving, the editor shows the save confirmation from creator_texts.json, and going back to the list shows the level. Opening elevation_sample_map.json in the editor and saving it must give a file the run builds into the same buildings, boulders, platforms and ramps. Tests write only into a temporary levels folder. Add saving to game/README.md, 'Level creator'.

The board's review: In the level creator, save a level, go back to the list, find it and open it again.

## Acceptance criteria

- [ ] A unit test saves a level with one piece of every kind: the file is written to the (temporary) levels folder, has map, legend, ground_rows, buildings, pattern_copies, platforms and ramps, and passes python game/tools/check_level.py. (QA: pass / fail)
- [ ] A unit test opens elevation_sample_map.json in the editor and saves it to a temporary path; mvp_map.gd and the elevation layer built from the saved file have the same buildings, boulders, platforms and ramps as built from the original. (QA: pass / fail)
- [ ] A unit test: after saving, the list screen lists the saved level by name. (QA: pass / fail)
- [ ] The save confirmation shown is the one in creator_texts.json, and the test that scans the creator's scripts for hard-coded label strings still passes. (QA: pass / fail)
- [ ] game/README.md, 'Level creator', says how to save and where the file goes. (QA: pass / fail)
- [ ] A screenshot of the editor showing the save confirmation is in art-archive/<this task's id>/screenshots/ and listed in the result notes. (QA: pass / fail)
- [ ] The full GUT suite passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
