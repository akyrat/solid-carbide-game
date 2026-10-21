---
id: T-230
title: The run can play any map file, with the elevation sample map as the default
status: in-progress
from: project-lead
to: game-loop
lead: Goal-G-005
epic: game-loop
milestone: mvp
goal: G-005
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/game-loop-architecture.md, game/README.md, game/scripts/run/run.gd, game/scripts/level/mvp_map.gd, game/scripts/level/elevation_layer.gd, game/scripts/enemies/enemy_navigation.gd, game/data/level/elevation_sample_map.json, game/tests/unit/run/test_run_elevation_map.gd]
files_expected_to_change: [game/scripts/run/run.gd, game/tests/unit/run/test_run_layout_path.gd, game/README.md]
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

The level creator (Level design, Decisions, 'Level creator', board 2026-10-21) plays custom levels as full runs, so the run must accept a map file path instead of the constant ELEVATION_LAYOUT_PATH. Today run.gd's _build_world() sets map.layout_path = ELEVATION_LAYOUT_PATH and calls elevation.setup(map, ELEVATION_LAYOUT_PATH). Add a layout path the run reads (for example a `layout_path` variable set before the run is added to the tree, or an argument to start_run()), used for both the map and the elevation layer, so the map's buildings, boulders, ground, the platforms and ramps, and the enemies' navigation (built from the map) all come from the same file. With no path given, the run uses res://data/level/elevation_sample_map.json exactly as today, so the game's main menu run is unchanged. The path may be a res:// or a user:// path (the creator's levels folder is decided in the storage ticket). Tests: start a run on a copy of elevation_sample_map.json written to a temporary path (user:// under the per-run test folder) with one building and one platform removed, and check the run's map and elevation layer read it; on the same copy, check enemy navigation finds a path from a street cell to a rooftop cell through a ramp. Document in game/README.md, 'The run', how to start a run on another map file.

## Acceptance criteria

- [ ] run.gd (or its start function) accepts a layout file path, used for both the map and the elevation layer; with none given it uses res://data/level/elevation_sample_map.json, and the existing run tests (tests/unit/run/) pass unchanged. (QA: pass / fail)
- [ ] A unit test starts a run on a copy of elevation_sample_map.json saved under another path with one building and one platform removed: the run's map has one building and one platform fewer than a default run, and the elevation layer was set up with the copied file's path (not the constant). (QA: pass / fail)
- [ ] A unit test on that copied file: enemy navigation builds for the run's map and find_path from a street cell to a rooftop cell returns a non-empty path whose points pass over a ramp's rectangle. (QA: pass / fail)
- [ ] game/README.md, 'The run', says how to start a run on another map file. (QA: pass / fail)
- [ ] The full GUT suite passes headless. (QA: pass / fail)
- [ ] The result notes say in one line that there is nothing to screenshot (no visible change). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Goal runner (G-005): started, in C:\solid-carbide-worktrees\T-230.

## Result notes

Game Loop Agent, 2026-10-21.

- **run.gd:** new `var layout_path: String = ELEVATION_LAYOUT_PATH` (set before the run enters the tree, or before `start_run()`), and `start_run(path: String = "")` sets it when a path is given (later `start_run()` calls keep that map). `current_layout_path()` returns it, or `ELEVATION_LAYOUT_PATH` when it is empty. `_build_world()` uses that one path for `map.layout_path` and `elevation.setup(map, path)`; the enemies' navigation (`enemy_navigation.gd`, `for_map`) is built from that map, so all come from the same file. res:// and user:// both work (FileAccess). With nothing set, the run is exactly as before (constant and `USE_ELEVATION_MAP` unchanged; the MVP switch still wins).
- **Tests:** `game/tests/unit/run/test_run_layout_path.gd` (9 tests, 41 asserts, pass). It writes a copy of `elevation_sample_map.json` to `RunPaths.file("t230_custom_map.json")` (user://test_runs/<pid>/) with the first building (12, -96) removed and the rooftop `roof-se-6` removed (with `ramp-se-3-6`, the ramp up to it, so no ramp leads to a missing rooftop). Checks: default run uses the sample map; empty path falls back; a run set before the tree has one building fewer on the map and one platform fewer in the elevation layer's `ground_height` (the layer keeps no path, so the platform count and ids prove it read the copy); `start_run(path)` switches maps; the MVP switch still builds the MVP map; enemy navigation (`for_map(run.map)`) uses the copy's heights and `find_path((-60,-48) street, (-80,-80) on roof-nw-3)` is non-empty, has a segment passing over a ramp's rectangle, and ends on the rooftop; the removed building's cells are open in the navigation grid.
- **Existing run tests** (`tests/unit/run/`) unchanged and passing in the full suite.
- **game/README.md**, "The run", "The run's map (T-206)": new bullet "Another map file (T-230)" saying how to start a run on another map file.
- **Full GUT suite:** `bash game/tools/run_tests.sh` passes headless: 108 scripts, 1311/1311 tests, 314 s.
- **Screenshots:** nothing to screenshot: no visible change (the default run looks exactly as before; the change is a path the run reads).
- PixelLab: 0 generations. Refusals: none.
