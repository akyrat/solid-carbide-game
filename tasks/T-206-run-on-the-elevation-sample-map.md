---
id: T-206
title: A run plays on the elevation sample map
status: in-qa
from: project-lead
to: game-loop
lead: Coursework
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/level-design.md, docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/game-loop-architecture.md, docs/drifting.md, game/README.md, game/scripts/run/run.gd, game/scripts/level/elevation_sample_map.gd, game/data/level/elevation_sample_map.json, tasks/T-196-elevation-sample-map.md, tasks/T-197-elevation-sample-depth-order.md]
files_expected_to_change: [game/scripts/run/run.gd, game/scenes/run/run.tscn, game/tests/unit/, game/README.md, art-archive/T-206/screenshots/]
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

The board played the elevation sample map (G-004) and wants it to become the game's map: a run started from the main menu (Start) plays on the elevation sample map's layout as the full game, with enemies, weapons, the timer, likes and levels, gift drops and the kaiju, so the board can see how the enemies behave on it (Level design, Decisions, "The elevation sample map becomes the run's map", 2026-10-20).

Today `run.gd` builds `mvp_map.tscn` with the MVP layout. `elevation_sample_map.gd` builds the same map script from `data/level/elevation_sample_map.json`, with the raised areas, the ramps, the car's height (`car_height.gd`, GroundHeight), its round shadow, the shadowless frames in the air, see-through and the depth order (T-196, T-197, T-205). Make the run use that layout and everything elevation brings, reusing the sample map's code rather than copying it. The run's other parts keep working on it: enemies spawning from the screen edges, weapons, pickups, coins, the HUD, the pause screen, drift marks and the camera. Where the run's things need a place in the depth order next to the raised areas (enemies, pickups, coins, effects), draw them as the street level does today, at height 0. How enemies deal with heights is T-207's job, so don't change enemy behaviour here.

Keep the MVP map. It stays in the project, and one constant or setting switches the run back to it (say which in `game/README.md`). The drive-only elevation sample scene keeps working (F6).

Where the docs leave something open (for example where the car starts on the new map), make a proposal for the playtest and list it in the result notes.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the work (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] A run started from the main menu's Start plays on the elevation sample map's layout: its rooftops, ramps, buildings and roads, with the car's height, round shadow, see-through and depth order as in the drive-only scene (screenshots of the car on the street, on a rooftop and in the air during a run) (QA: pass: street, rooftop, air (round shadow on street) and see-through screenshots show the elevation layout in a run)
- [ ] During that run the enemies spawn and chase the car, weapons fire, the timer, likes and levels run, and the level-up gift drop and the kaiju still come, with no errors in Godot's output over a 2-minute headless or scripted run (QA: pass: 150 s soak ran, car at heights 0/3/6, minions, shots, 4 level-ups via gifts, kaiju; the only error line is the exit-time "1 resources still in use at exit", none during play)
- [ ] The MVP map is still in the project, and one named constant or setting switches the run back to it; `game/README.md` says which (QA: pass: USE_ELEVATION_MAP in run.gd, documented in game/README.md; MVP soak runs on it)
- [ ] The drive-only elevation sample scene still runs (F6) as before (QA: pass: drive-only scene ran 10 s with no errors)
- [ ] The full GUT suite and all Python tool tests pass, with new tests for the run building the elevation map (QA: pass: GUT 1141/1141; tools 399 OK; game/tools 354 OK (1 skipped); 13 new tests in test_run_elevation_map.gd)

The board's review: start a run from the main menu and play the full game on the elevation sample map.
Board review files: `game/scenes/run/run.tscn` via the main menu.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-20, Open → In progress

Started: the agent is working in its own folder, C:\solid-carbide-worktrees$t, in parallel with the others.

### 2026-10-21, In progress → In QA

Built: a run from the main menu plays the full game on the elevation map (switch back with USE_ELEVATION_MAP in run.gd). Sent to QA.

## Result notes

Written by the agent when it finishes.

### Game Loop Agent, 2026-10-21

Two agents worked on this ticket: the first was cut off before it committed, and the second checked its work, kept it, and finished the ticket.

**What was built**
- `game/scripts/level/elevation_layer.gd` (new) holds the rooftops and ramps with their drawings, the ground height, the shared depth order of rooftops, ramps and buildings (`restack`, `z_for`), and see-through. The code was moved out of `elevation_sample_map.gd` and not copied: the drive-only scene now calls its layer through thin wrappers, so the scene and the run share one copy of the code.
- `game/scripts/run/run.gd`: `const USE_ELEVATION_MAP := true` switches the map, and `run.use_elevation_map` sets the same thing per run instance for tests. On the elevation map the run loads `data/level/elevation_sample_map.json` into the map, adds the layer, sets `car.ground` and shows the round `CarShadow`. `_sync_view_elevation()` does what the drive-only scene does: it lifts the car by its height, uses the shadowless frames in the air, places the shadow on the ground, sets the depth order, runs see-through, and makes the camera follow at street level. With the switch set to false, the run builds the MVP map exactly as before.
- `mvp_map.gd`: `map.elevation` (null on the MVP map) brings the rooftops and ramps into `top_z_index`, `car_z_index`, the boulder z-order and `is_open_spot`. Street level only, so gift packages and meteors never land on a rooftop. The map's own building fade is off when the layer is present. `enemy_depth.gd` draws enemies, coins and pickups under any rooftop that covers them, at height 0. Enemy behaviour is unchanged (T-207).
- `weapons.gd`: `is_target(e)` is now untyped, so a target that has already been freed returns false instead of raising a script error. The earlier agent found this error on the elevation map.

**Proposals for the playtest**
- The start is unchanged: (0, 0) in the gravel square, nose north, at street level on this layout.
- Enemies, coins, pickups and effects are drawn at height 0 in the depth order. Gift packages and meteor landings pick street-level spots only.
- On a rooftop, the drift smoke and boost are lifted with the ground under the car, so they stay at its tyres.

**Tests**
- New: `game/tests/unit/run/test_run_elevation_map.gd` (13 tests). They cover the switch in both directions, one drawing per area, a new layer for each run, the height, shadow and air frames, the car's depth order on a rooftop and behind one, see-through, the camera, open spots, enemy depth, and a run going on with enemies.
- Tests that check the MVP map's own blocks now set `run.use_elevation_map = false`.
- `test_run_scene.gd` now checks one boulder body per pattern copy: 56 on the elevation map, 60 on the MVP map.
- I fixed a broken assertion the earlier agent left in `test_elevation_sample_map.gd`, and restored that file's line endings to LF.
- Results: full GUT suite 1141/1141 passed. Python `tools/` 399 OK. `game/tools/` 354 OK (1 skipped).

**2-minute scripted run** (`python game/tools/run_scene_headless.py res://tests/fixtures/run_elevation_soak.tscn 150 --show`)
- The car spent time on the street, at height 3 and at height 6 (max 6.00), with up to 21 minions and 201 shots.
- There were 4 level-up screens through the gift packs, and the kaiju arrived. The run was still going at 120 s.
- No errors appeared during the run.
- At quit, Godot prints one line: `ERROR: 1 resources still in use at exit`. It is the engine-loop sound's stream (`748027_sedan-engine-loop.ogg`) still being held. The same line appears on the MVP map (`run_mvp_soak.tscn`), so it is older than this ticket and not caused by the run. Freeing the game before quitting did not remove it. I left it for a separate SFX or tooling ticket if wanted.

**Drive-only scene:** `run_scene_headless.py res://scenes/elevation_sample/elevation_sample_map.tscn 10` reports no errors, and its GUT tests all pass.

**Screenshots** (`art-archive/T-206/screenshots/`)
- `run_elevation_street.png`: on the street.
- `run_elevation_rooftop.png`: on the height-6 rooftop.
- `run_elevation_air.png`: in the air off the rooftop, with the round shadow on the street.
- `run_elevation_behind.png`: behind a rooftop, which is see-through.
- `run_elevation_kaiju.png`: the kaiju arriving, with a see-through building.
- `drive_only_elevation_sample.png`: the drive-only scene, unchanged.

**Docs updated**
- `docs/level-design.md`: Content, "Elevation sample map", "The run on this map".
- `docs/game-loop-architecture.md`: "The run scene".
- `game/README.md`: "The run", "The run's map (T-206)", plus the sample-map sections that now point to the shared layer.

No commands were refused.


### QA, round 1

All 5 criteria pass. The "1 resources still in use at exit" line also appears in run_mvp_soak.tscn (run here on the branch, where the MVP fixture exists; the MVP map's code path is unchanged by the switch), so it is not specific to the elevation map; it is not an error during play.
