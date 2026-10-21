---
id: T-234
title: Level creator: its own launch command and the level list screen
status: blocked
from: project-lead
to: ui
lead: Goal-G-005
epic: level-challenges
milestone: mvp
goal: G-005
user_facing_text: yes
changes_visuals: yes
depends_on: [T-233, T-231]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, game/README.md, game/data/level/creator_texts.json, game/scripts/level/level_store.gd, game/scripts/menu/main_menu.gd, game/scripts/game/game_flow.gd, game/project.godot]
files_expected_to_change: [game/scenes/level_creator/level_creator.tscn, game/scripts/level_creator/level_creator.gd, game/scripts/level_creator/level_list_screen.gd, game/scenes/level_creator/editor.tscn, game/scripts/level_creator/editor.gd, game/tests/unit/level_creator/test_level_list.gd, game/tests/unit/level_creator/test_creator_texts_only.gd, game/tools/level_creator.ps1, game/tools/level_creator.sh, game/README.md]
model: sonnet
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

The level creator is a separate app (Level design, Decisions, 'Level creator', board 2026-10-21): launched like the game but not reachable from the game's menus, and not part of what players get. Build its main scene, game/scenes/level_creator/level_creator.tscn, under its own folders (scenes/level_creator/, scripts/level_creator/), opened by a documented command (tools/level_creator.ps1 and .sh running Godot on that scene; the game's main scene in project.godot stays the game). It opens on the level list: levels from level_store.gd's list_levels(), each by name with its play and edit actions; with no levels, only the new-level button. New level opens the editor scene (a stub here, an empty map, filled in by the editor ticket) and edit opens it with that level loaded; play emits a signal the play ticket wires to the run. A plain placeholder look is fine (no Redgull red). Every label comes from game/data/level/creator_texts.json, word for word: add a GUT test that scans the creator's scripts and scenes and fails on any hard-coded label string not read from that file, so later creator tickets keep it true. No game menu script references the creator; game/ has no export_presets.cfg today, so document in game/README.md, 'Level creator', that an export preset must exclude scenes/level_creator/, scripts/level_creator/ and the levels folder, and if any export_presets.cfg exists, add those exclusions to it. Screenshots of the empty and filled list in art-archive/<this task's id>/screenshots/.

The board's review: Open the level creator with the README's command and look at the empty and the filled level list.

## Acceptance criteria

- [ ] The command in game/README.md, 'Level creator', opens the creator scene; the scene runs headless (tools/run_scene_headless.py) with no errors in the log. (QA: pass / fail)
- [ ] grep finds no reference to level_creator in game/scripts/menu/, game/scripts/game/ or game/scenes/menu/; project.godot's main scene is unchanged; any export_presets.cfg excludes the creator's folders, and the README says they must be excluded. (QA: pass / fail)
- [ ] A unit test with no levels: the list screen shows only the new-level button. A unit test with two saved levels (in a temporary folder): both are listed by name, each with a play and an edit action. (QA: pass / fail)
- [ ] A unit test: pressing new level opens the editor scene with an empty map; pressing edit on a level opens the editor with that level's data loaded. (QA: pass / fail)
- [ ] Every label on the screen is from game/data/level/creator_texts.json, and the test that scans the creator's scripts for hard-coded label strings passes. (QA: pass / fail)
- [ ] Screenshots of the empty list and of a list with levels are in art-archive/<this task's id>/screenshots/ and listed in the result notes. (QA: pass / fail)
- [ ] The full GUT suite passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
