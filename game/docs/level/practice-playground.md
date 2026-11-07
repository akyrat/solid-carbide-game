# The practice playground

(Level design, Decisions and Content, "The practice playground"; task T-560; the index is [../../README.md](../../README.md).)

The level the tutorial's practice windows load (T-561): `data/level/practice_playground.json`. What it holds and why: Level design, Content, "The practice playground". This is how it is built and checked.

## The file

- **Made by** `python game/tools/build_practice_playground.py` (from the repo root), which writes the JSON from the numbers at its top. Edit the script and run it again, or open the file in the level creator and save it as a level of the board's own; the creator keeps the two keys below.
- **Format:** the level creator's (the elevation sample map's): `map`, `legend`, `ground_rows` (all road), `ground`, `platforms`, `ramps`, `rails`, `spawn`. Checked with `python game/tools/check_level.py game/data/level/practice_playground.json` and `python game/tools/check_height_data.py game/data/level/practice_playground.json` (both print `OK`).
- **`ground_style`** (new, T-560): `{"kind": "grid", "ground_color", "minor_color", "major_color", "major_every"}`, colours as 0 to 1 numbers. `GridGround.of(level)` (`scripts/level/grid_ground.gd`) reads it; `mvp_map.gd` keeps it in `grid_style`, hides the ground tiles when it is set (`_GroundTiles.has_art()`) and draws the ground colour and the grid in its ground node (`GridGround.draw`), in the isometric and the flat view. A level without the key, or with another kind, draws its usual ground.
- **`start_points`** (new, T-560): `[{"id", "x", "y", "heading"}]`, each checked like the spawn point (`check_level.py`, `check_start_points`: unique ids, a place a car can stand). `LevelStartPoints` (`scripts/level/start_points.gd`): `ids(level)`, `of(level, id)`, `with_spawn(level, id)`. `run.start_point_id` (set before the run enters the tree) starts the car on that point instead of the spawn; `GameFlow.add_run(parent, progress, layout_path, history, start_point_id)` passes it. An id the level lacks keeps the spawn.

## For T-561 (the tutorial's practice windows)

- **Path:** `res://data/level/practice_playground.json`.
- **Start point ids:** `drift`, `alt_drift`, `air_spin`, `grind` (all heading 0, east). The level's `spawn` is `drift`.
- Load it with `GameFlow.add_run(parent, progress, "res://data/level/practice_playground.json", null, "air_spin")`.

## The checks (tests)

`tests/unit/level/test_practice_playground.gd`: the file's shape and small size; one start point per slide, each on open ground, the run starting the car on it; the grid ground drawn (and Kaiju City's ground unchanged); the rails beyond the jump ramp's top; and scripted drives with the real car (W held, no keyboard): from `air_spin` the car is at 16.5 units/s at the jump ramp's top, is in the air 1.8 s and A held in the air pays `air_three_sixty`; with Space held from `air_spin` and from `grind` it catches `rail-2`; a lane over (y 3.5) it catches `rail-3`; with W let go at 11 units/s on the rooftop it catches `rail-1`. `tools/test_check_level.py` checks the start points rule.

## Screenshots

`game/tools/shots/practice_playground_shots.tscn` (mode from the environment variable `T560_MODE`: `drift`, `ramp`, `air`, `rail`, `overview`) with `bash game/tools/screenshot.sh res://tools/shots/practice_playground_shots.tscn <out.png> 150`. The task's pictures are in `art-archive/T-560/screenshots/`.
