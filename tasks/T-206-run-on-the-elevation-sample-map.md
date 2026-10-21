---
id: T-206
title: A run plays on the elevation sample map
status: done
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
qa_rounds: 3
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

- [ ] A run started from the main menu's Start plays on the elevation sample map's layout: its rooftops, ramps, buildings and roads, with the car's height, round shadow, see-through and depth order as in the drive-only scene (screenshots of the car on the street, on a rooftop and in the air during a run) (QA: pass; street, rooftop, air (round shadow, no smoke or tyre marks) and see-through screenshots show the elevation layout in a run)
- [ ] During that run the enemies spawn and chase the car, weapons fire, the timer, likes and levels run, and the level-up gift drop and the kaiju still come, with no errors in Godot's output over a 2-minute headless or scripted run (QA: pass; 150 s soak re-run with the tweaks, only the exit-time "1 resources still in use at exit" line, none during play)
- [ ] The MVP map is still in the project, and one named constant or setting switches the run back to it; `game/README.md` says which (QA: pass; USE_ELEVATION_MAP in run.gd, documented in game/README.md)
- [ ] The drive-only elevation sample scene still runs (F6) as before (QA: pass; drive-only scene's tests pass in the full suite; its scene code is unchanged since the round 1 run with no errors)
- [ ] The full GUT suite and all Python tool tests pass, with new tests for the run building the elevation map (QA: pass; GUT 1147/1147, tools 399 OK, game/tools 354 OK (1 skipped); new tests in test_run_elevation_map.gd cover the tweaks)

The board's review: start a run from the main menu and play the full game on the elevation sample map.
Board review files: `game/scenes/run/run.tscn` via the main menu.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-20, Open → In progress

Started: the agent is working in its own folder, C:\solid-carbide-worktrees$t, in parallel with the others.

### 2026-10-21, In progress → In QA

Built: a run from the main menu plays the full game on the elevation map (switch back with USE_ELEVATION_MAP in run.gd). Sent to QA.

### 2026-10-21, In QA → Needs playtest

QA passed all 5. Ready for the board: open C:\solid-carbide-worktrees\T-206\game\project.godot, or Play on T-206 in the Builds tab, and start a run from the main menu.

### 2026-10-21, Needs playtest → In progress

Back to the agent with the board's two fixes: no drift smoke in the air, and the flamethrower at the car's height. Enemies on ramps goes to T-207.

### 2026-10-21, In progress → In QA

Both fixes in: no drift smoke in the air, and the flames come out at the car's height. Ready for the board to play: C:\solid-carbide-worktrees\T-206\game\project.godot or Play on T-206 in the Builds tab.

### 2026-10-21, In QA → Needs playtest

QA passed round 1; the board's tweak follows.

### 2026-10-21, Needs playtest → In progress

Back to the agent: no tyre marks in the air, like the smoke.

### 2026-10-21, In progress → In QA

Tweak in: no tyre marks in the air. Ready for the board to play.

### 2026-10-21, In QA → Needs playtest

Final QA passed all 5 with the board's tweaks in. Ready for the board (or play T-207, which contains it).

### 2026-10-21, Needs playtest → Done

The board approved it with T-207. Merged into master.

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
- 2026-10-21, needs-playtest → in-progress: Board's playtest (2026-10-21): no drift smoke while the car is airborne; the exhaust flamethrower ignores the car's height and spawns away from the car on rooftops and in the air, so draw and place it at the car's height. Enemies ignoring raised surfaces goes to T-207.

### Tweak, Game Loop Agent, 2026-10-21: the board's two fixes

1. **No drift smoke in the air** (Drifting, Decisions, "No drift smoke in the air"; I copied the line from master into this branch's `docs/drifting.md`).
   - `drift_smoke.gd` `bind()` now makes smoke only when `smokes(car)` is true: the car is drifting and not airborne.
   - The smoke stops while the car is in the air, even with the drift keys held, and comes back on the first step after landing. On a rooftop the car is not airborne, so it still makes smoke there.
2. **The flamethrower at height** (Weapons, Decisions, "The flamethrower at height"; I copied the line from master into `docs/weapons.md`).
   - `exhaust_flamethrower.gd` `_update_drawing()` now lifts the flame drawing by the car's height (`car_height()`), the same way the car sprite is lifted. On a rooftop or in the air the flames come out of the exhaust where the car is drawn.
   - Proposal: the damage area is still the flat rectangle behind the car's map position, so it burns what is at the car's spot. Enemies stay at street level, because enemies on raised surfaces are T-207's job.
   - Only the drawing's placement changed in the weapon code.

**New tests:** 5 in `game/tests/unit/run/test_run_elevation_map.gd`.
- No smoke in the air, and smoke again after landing.
- Smoke on a rooftop.
- The flame at the car's exhaust on a rooftop (height 6) and in the air (height 4).
- The flame on a rooftop burns an enemy behind the exhaust and not one far away.

**Test results:** GUT 1146/1146 passed. Python `tools/` 399 OK. `game/tools/` 354 OK (1 skipped).

**Screenshots:**
- `art-archive/T-206/screenshots/run_elevation_air_drift_keys.png`: the car in the air with W and D held, drifting, and 0 smoke puffs. The fixture is `run_elevation_air_drift_keys.tscn`.
- `art-archive/T-206/screenshots/run_elevation_flamethrower_rooftop.png`: the car drifting on the height-6 rooftop with flames at its exhaust. The fixture is `run_elevation_flamethrower_rooftop.tscn`.

**Docs updated:** `docs/drifting.md` and `docs/weapons.md` (the decision lines copied from master), and `game/README.md` ("The run's map (T-206)").

**Not asked for, noticed:** the drift marks are still drawn on the street under a car that is drifting in the air. You can see them faintly in the air screenshot. I left them as they are; whether to stop them in the air is the board's call.

No commands were refused.
- 2026-10-21, in-progress → in-qa: Ready for the board to play: the board's two fixes are in (no smoke in the air, flamethrower at height); one QA round before merging
- 2026-10-21, needs-playtest → in-progress: Board (2026-10-21): no tyre marks in the air either, like the smoke

### Tweak 2, Game Loop Agent, 2026-10-21: no tyre marks in the air

**What changed:** `game/scripts/driving/drift_marks.gd` `bind()` now lays marks only when `lays(car)` is true: the car is drifting and not airborne. This works the same way as the smoke fix. The marks end on takeoff, even with the drift keys held, and a new mark starts on the first step after landing.

**Docs updated:**
- I copied the decision line from master into `docs/drifting.md`. It is now "No drift smoke or tyre marks in the air", replacing the smoke-only line.
- `game/README.md` ("The run's map (T-206)").

**New test:** `test_no_tyre_marks_in_the_air_and_back_on_landing` in `game/tests/unit/run/test_run_elevation_map.gd`. It checks that drifting on the street lays marks, that 10 drifting steps in the air start no new mark and lay no segments, and that a new mark starts after landing.

**Test results:** GUT 1147/1147 passed. Python `tools/` 399 OK. `game/tools/` 354 OK (1 skipped).

**Screenshot:** `art-archive/T-206/screenshots/run_elevation_air_no_marks.png`. The car is in the air at height 5 with W and D held, drifting, and nothing under it except its round shadow: no smoke and no tyre marks. It comes from the fixture `run_elevation_air_drift_keys.tscn`.

**Stale screenshot:** the earlier `run_elevation_air_drift_keys.png` still shows the faint marks from before this fix. I kept it, as the "never delete" rule says.

No commands were refused.
- 2026-10-21, in-progress → in-qa: Ready for the board to play: no tyre marks in the air either; one QA round before merging
- 2026-10-21, needs-playtest → done: Board: T-206 can be closed too (with T-207: LGTM)
