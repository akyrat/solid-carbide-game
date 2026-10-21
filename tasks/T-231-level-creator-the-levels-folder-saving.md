---
id: T-231
title: Level creator: the levels folder, saving, listing and loading levels, and a level validator
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
files_to_read_first: [tasks/README.md, docs/level-design.md, game/README.md, game/tools/check_height_data.py, game/tools/test_check_height_data.py, game/data/level/elevation_sample_map.json, game/scripts/level/mvp_map.gd, game/scripts/enemies/enemy_navigation.gd]
files_expected_to_change: [game/scripts/level/level_store.gd, game/tests/unit/test_level_store.gd, game/tools/check_level.py, game/tools/test_check_level.py, game/README.md]
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

Storage for the level creator (Level design, Decisions, 'Level creator', board 2026-10-21). Levels are saved in the same map-file format the elevation sample map uses (map, legend, ground_rows, buildings, pattern_copies for the boulders, platforms, ramps), so the run, the heights and the enemies' pathfinding read them unchanged. 1) Choose the levels folder: the docs don't say where; propose one (for example game/data/levels/, which the run reads as res://data/levels/ when the project is opened from the repo; the creator is never exported) and write it in the result notes as a proposal for the board. 2) A script, game/scripts/level/level_store.gd, with list_levels() (each level's name and path, sorted), load_level(path) -> Dictionary and save_level(path, data); tests write only under the per-run test folder (game/README.md, 'Per-run test files'), never into the real levels folder. 3) A level validator, game/tools/check_level.py, that calls check_height_data.py's check_data and also checks: every building, rooftop (platform), ramp and boulder lies inside the map's rect; the edges of buildings, rooftops and ramps lie on even units (enemy_navigation.gd's CELL = 2); ground_rows has as many rows and columns as the map's size in tiles. Python tests pass on a valid file and fail on each broken case. 4) game/README.md gets a 'Level creator' section (created here, filled in by the later creator tickets) saying where levels are saved and how to run the validator.

## Acceptance criteria

- [ ] game/README.md has a 'Level creator' section naming the levels folder and the validator command; the result notes give the folder as a proposal for the board. (QA: pass / fail)
- [ ] game/scripts/level/level_store.gd provides list_levels(), load_level(path) and save_level(path, data); a GUT test saves a level into a temporary folder, finds it in list_levels(), loads it back and gets data equal to what it saved. (QA: pass / fail)
- [ ] python game/tools/check_level.py game/data/level/elevation_sample_map.json exits 0. (QA: pass / fail)
- [ ] check_level.py's Python tests pass on a valid file and fail on each broken case: a building outside the map, a rooftop outside the map, a ramp outside the map, a boulder outside the map, a building, rooftop or ramp edge on an odd unit, ground_rows of the wrong size, and a height-data problem check_height_data.py already reports. (QA: pass / fail)
- [ ] The full GUT suite and the Python tool tests pass. (QA: pass / fail)
- [ ] The result notes say in one line that there is nothing to screenshot (tooling). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
