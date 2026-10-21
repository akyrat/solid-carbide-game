---
id: T-235
title: Level creator: the editor's map canvas, the side panel, placing and deleting pieces
status: blocked
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

The editor where the board builds a level (Level design, Decisions, 'Level creator', board 2026-10-21). It holds the level as data in the map-file format (map, legend, ground_rows, buildings, pattern_copies, platforms, ramps) and draws it in the game's isometric view with the game's own drawing code: mvp_map.gd built from the level's data and the elevation layer (elevation_layer.gd) for rooftops and ramps, the same scripts the run uses, rebuilt or updated when a piece changes. A new level starts as an empty map (the size of today's map, all ground tiles a single plain kind from the catalogue; the result notes give this as a proposal). A side panel lists every asset in game/data/level/creator_assets.json, grouped by kind with the category names from creator_texts.json. Pick one, click the map to place it (into the level data and the drawing), and delete a placed piece (the delete label from creator_texts.json). The camera can pan and zoom over the map. Rotate, mirror, heights and snapping come in the next tickets; here pieces go at the clicked tile. All labels from creator_texts.json. Add the editor's controls to game/README.md, 'Level creator'. Screenshot of the editor with the panel and placed pieces in art-archive/<this task's id>/screenshots/.

The board's review: Open the level creator, make a new level and place and delete a few pieces of each kind.

## Acceptance criteria

- [ ] The editor draws the level with mvp_map.gd and elevation_layer.gd (the run's scripts), not a copy: a test or the code shows both are instantiated by the editor. (QA: pass / fail)
- [ ] The side panel shows every asset in creator_assets.json, grouped by kind, with the category names from creator_texts.json (a unit test compares the panel's entries with the catalogue). (QA: pass / fail)
- [ ] A scripted unit test places one ground tile, one road, one building, one boulder, one rooftop and one ramp: the level data then holds each; deleting one removes it from the data and from the drawing. (QA: pass / fail)
- [ ] The test that scans the creator's scripts for hard-coded label strings still passes. (QA: pass / fail)
- [ ] game/README.md, 'Level creator', lists the editor's controls (pick, place, delete, pan, zoom). (QA: pass / fail)
- [ ] A screenshot of the editor with the side panel and placed pieces is in art-archive/<this task's id>/screenshots/ and listed in the result notes. (QA: pass / fail)
- [ ] The full GUT suite passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
