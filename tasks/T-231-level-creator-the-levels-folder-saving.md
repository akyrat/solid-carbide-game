---
id: T-231
title: Level creator: the levels folder, saving, listing and loading levels, and a level validator
status: in-qa
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

- [ ] game/README.md has a 'Level creator' section naming the levels folder and the validator command; the result notes give the folder as a proposal for the board. (QA: pass)
- [ ] game/scripts/level/level_store.gd provides list_levels(), load_level(path) and save_level(path, data); a GUT test saves a level into a temporary folder, finds it in list_levels(), loads it back and gets data equal to what it saved. (QA: pass)
- [ ] python game/tools/check_level.py game/data/level/elevation_sample_map.json exits 0. (QA: pass)
- [ ] check_level.py's Python tests pass on a valid file and fail on each broken case: a building outside the map, a rooftop outside the map, a ramp outside the map, a boulder outside the map, a building, rooftop or ramp edge on an odd unit, ground_rows of the wrong size, and a height-data problem check_height_data.py already reports. (QA: pass)
- [ ] The full GUT suite and the Python tool tests pass. (QA: pass)
- [ ] The result notes say in one line that there is nothing to screenshot (tooling). (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Goal runner (G-005): started, in C:\solid-carbide-worktrees\T-231.

### 2026-10-21, In progress → In QA

Goal runner (G-005): the agent is done; QA is checking it.

## Result notes

**Levels folder (a proposal for the board):** `game/data/levels/`, read as `res://data/levels/` (`LevelStore.LEVELS_DIR`). The creator runs from the repo and is never exported. The folder itself isn't created until a level is saved (`save_level` makes it); `list_levels` returns an empty list while it is missing.

**Built:**
- `game/scripts/level/level_store.gd` (`LevelStore`): `list_levels(dir)` ([{name, path}] sorted by name then path; name = the file's `name` or its file name; skips non-JSON files and files that aren't a JSON object), `load_level(path)` (Dictionary, empty on a missing or bad file, no engine error), `save_level(path, data)` (indented JSON, creates the folder, returns OK or an Error).
- `game/tests/unit/test_level_store.gd` (6 tests, files only under `RunPaths`): save, list, load round trip with equal data; sorting; skipping other files and a missing folder; missing file; overwrite; the sample map loads with its sections.
- `game/tools/check_level.py`: runs `check_height_data.check_data`, then checks that buildings, rooftops, ramps and boulders (centre ± diameter/2) lie inside `map.rect`, that building, rooftop and ramp edges lie on multiples of 2 (`CELL`), and that `ground_rows` has map height rows of map width columns (1 tile = 1 unit; the sample map is 240 x 240). One line per problem, exit 1; `OK`, exit 0.
- `game/tools/test_check_level.py` (15 tests): valid small level, the sample map, touching the edge; rejects a building, rooftop, ramp and boulder outside the map, an odd building, rooftop and ramp edge, too few rows, a short row, a height-data problem (ramp top_height), bad JSON, one line per problem.
- `game/README.md`: new 'Level creator (T-231)' section (folder, storage, validator command), for later creator tickets to extend.

**Checks run:** `python game/tools/check_level.py game/data/level/elevation_sample_map.json` prints OK (exit 0). `python -m unittest discover -s game/tools -p "test_*.py"`: 408 tests OK. `bash game/tools/run_tests.sh`: TESTS PASSED (full GUT suite).

**Open question for the board:** the "even units" rule is checked on edges (x, y, x+w, y+h); an odd-sized rect on an odd origin passes only if both edges are even, which is what the pathfinding grid needs.

**Screenshots:** none — this is tooling (storage script and validator), nothing is on screen.

**Documents affected:** none (the folder is a proposal; `game/README.md` is the game's own readme).
