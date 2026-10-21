---
id: T-232
title: Level creator: a catalogue of every placeable asset already in the game, built by script
status: open
from: project-lead
to: level-challenge
lead: Goal-G-005
epic: level-challenges
milestone: mvp
goal: G-005
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, game/README.md, game/art/buildings/skyscrapers.json, game/art/boulders/boulders.json, game/art/ground/ground_atlas.json, game/art/elevation_sample/roof-nw-3.json, game/art/elevation_sample/ramp-nw-0-3.json, game/scripts/level/mvp_map.gd, game/scripts/level/elevation_platform_drawing.gd, game/data/level/elevation_sample_map.json]
files_expected_to_change: [game/tools/build_creator_assets.py, game/tools/test_build_creator_assets.py, game/data/level/creator_assets.json, game/tests/unit/test_creator_assets.gd, game/README.md]
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

The level creator's side panel offers every asset already in the game (Level design, Decisions, 'Level creator', board 2026-10-21): ground tiles, roads, buildings, boulders, rooftops and ramps at heights 3 and 6. No new art is generated or drawn. Write a script, game/tools/build_creator_assets.py, that reads the existing art data (art/buildings/skyscrapers.json and the short buildings, art/boulders/boulders.json with the mirrored boulders, art/ground/ground_atlas.json and the road tile, and the elevation sample art in art/elevation_sample/: roofs nw/se at 3 and 6, ramps nw/se 0-3 and 3-6) and writes game/data/level/creator_assets.json: one entry per placeable asset with its id, kind (ground, road, building, boulder, rooftop, ramp), footprint in units, the views and mirrors the art has (only those that exist), its texture paths, and for rooftops their height (3, 6) and for ramps their heights (0 to 3, 3 to 6). Check how mvp_map.gd and elevation_platform_drawing.gd pick textures so the catalogue names exactly what the run draws. A GUT test checks every texture the catalogue names exists, and that every building, boulder, ground and elevation texture the map uses today appears in it. Add a line to game/README.md, 'Level creator', on how to rebuild the catalogue.

## Acceptance criteria

- [ ] python game/tools/build_creator_assets.py writes game/data/level/creator_assets.json; running it twice gives the same file. (QA: pass / fail)
- [ ] Each catalogue entry has an id, a kind (ground, road, building, boulder, rooftop or ramp), a footprint in units, its views and mirrors, and texture paths; rooftop entries exist at heights 3 and 6, ramp entries for 0 to 3 and 3 to 6. (QA: pass / fail)
- [ ] A GUT test passes that checks every texture the catalogue names exists under game/art/, and that every building, boulder, ground and elevation texture the map and elevation layer draw today appears in the catalogue. (QA: pass / fail)
- [ ] The script's Python tests pass. (QA: pass / fail)
- [ ] git diff shows no PNG under game/art/ added or changed. (QA: pass / fail)
- [ ] game/README.md, 'Level creator', says how to rebuild the catalogue. (QA: pass / fail)
- [ ] The result notes say in one line that there is nothing to screenshot (data). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
