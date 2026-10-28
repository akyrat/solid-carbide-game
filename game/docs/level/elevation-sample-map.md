# Elevation sample map

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Elevation sample map (T-193)

The drive-only sample map with three layers (Level design, Decisions, "Elevation sample map"; Content, "Elevation sample map"): the street (height 0), a first floor (height 3) and a second floor (height 6). T-193 made its height data and the validator, T-194 the layout file ("The layout file (T-194)" below), T-196 the drive-only scene ("The scene (T-196)" below). Every number is a proposal for the board's playtest.

### Height data

The same format as the elevation test scene's (`data/level/elevation_test.json`, unchanged), read by the same `GroundHeight` (`scripts/level/ground_height.gd`). A JSON object with two lists, in flat-world units (x east, y south, so north is -y), so a level editor can later add, move and remove areas. Every field:

- `platforms` (a list of raised areas, rooftops):
  - `id` (text, unique): the name ramps and other platforms use for it.
  - `x`, `y` (numbers): the rectangle's north-west corner; `w`, `h` (numbers, above 0): its width (east) and depth (south). Axis-aligned.
  - `height` (number): the ground's height on top, in units (3 for a first floor, 6 for a second floor).
  - `on` (text, optional, new in T-193): the `id` of the platform it stands on (a second-floor rooftop on a first-floor one). Leave it out for an area standing on the street. Its whole rectangle must be inside that platform, and it must be higher. Two platforms may overlap only when one stands on the other (directly or through others); any other overlap is a mistake. `GroundHeight` keeps it as `on` ("" when missing) but doesn't need it: at any point the highest area wins.
- `ramps` (a list of slopes):
  - `id` (text, unique).
  - `platform` (text): the `id` of the area the ramp climbs to.
  - `side` (`north`, `east`, `south` or `west`): that area's side the ramp climbs; the ramp lies outside the area on that side (an `east` ramp is east of its area and rises westward).
  - `x`, `y`, `w`, `h` (numbers): the ramp's footprint. Its top end lies on the area's side, within its length.
  - `bottom_height` (number, default 0): the height at the foot (the end away from the area). It must match the ground the ramp stands on: 0 on the street, or the height of the platform holding its whole footprint (3 for a ramp on a first floor up to a second floor).
  - `top_height` (number): the height at the top; it must match the height of the area it climbs to.
  - The height rises in a straight line from foot to top. The ramp's other two sides are drop-offs.
- Anything else (for example `_comment`) is ignored.

The query is unchanged ("Elevation test scene", "The query" above): `height_at`, `ramp_at` and `area_index_at` give the highest area at a point (a ramp over the platform it stands on), and `side_normal` and `edge_between` work between rooftops too (the step from a height-6 area onto the height-3 area under it is 3).

**Validator:** from the repo root, `python game/tools/check_height_data.py <file.json>`. It prints `OK` and exits 0 when the file is valid; otherwise one line per problem and exit code 1. It rejects: overlapping platforms neither of which stands on the other; an `on` naming an unknown area, or an area that doesn't contain the whole footprint, or one that isn't lower; a ramp climbing to an unknown area; an unknown `side`; a ramp whose top doesn't touch the side it climbs; a `top_height` that doesn't match the area it climbs to; a `bottom_height` that doesn't match the ground at its foot; a ramp overlapping an area it doesn't stand on wholly; missing numbers, non-positive sizes, missing or repeated ids. Run it on every height-data file before handing a map over.

Tests: `tests/fixtures/height/three_layers.json` (a height-3 area at (-20, -20), 40 by 40; a height-6 area on it at (-10, -10), 16 by 16; a 0-to-3 ramp east of the first and a 3-to-6 ramp on it east of the second, each 12 by 8) with `tests/unit/test_ground_height_layers.gd` (GUT), and `tools/test_check_height_data.py` (Python tool tests).

### The layout file (T-194)

`data/level/elevation_sample_map.json`: the MVP map's layout (`data/level/mvp_map.json`) with the same keys `mvp_map.gd` reads (`map`, `gravel`, `buildings`, `pattern_copies`, `challenges`, `challenge_designs`, `ground_rows` and the rest), so the map script can load it, plus `platforms` and `ramps` in the height-data format above. The layout (two parking garages, rooftops at 3 and 6) and its picture: Level design, Content, "Elevation sample map". Every rooftop and ramp is a proposal for the board's playtest.

From the repo root:

- `python game/tools/build_elevation_sample_map.py` rebuilds the file from `mvp_map.json` (never changes it), runs the validator on the result, and draws `docs/level-design/elevation-sample-map.png` (and its copy in `art-archive/T-194/screenshots/`).
- `python game/tools/build_elevation_sample_map.py --check` rebuilds it in memory and prints `OK` (exit 0) when the committed file matches and the height data is valid; otherwise it says what differs (exit 1).
- To change the layout, edit `ROOFTOPS` and `RAMPS` (and `RAMP_LENGTH`, `RAMP_WIDTH`, `FOOT_APPROACH`) at the top of the script and run it again.

What the script does to the MVP layout: it leaves out every building overlapping a rooftop; every boulder overlapping a rooftop, a ramp or the strip `FOOT_APPROACH` (6) units deep in front of a ramp's foot; every pattern copy left with no boulder; and every challenge whose copy lost a boulder (challenges are off in the MVP). It rebuilds `ground_rows` from the remaining buildings (cells under a rooftop are `R`), updates `challenge_rule`'s counts, and adds `name`, `task`, `based_on` and `elevation_note` (what was left out).

Tests: `tools/test_build_elevation_sample_map.py` (Python tool tests): heights exactly {0, 3, 6}; an area at 3 and one at 6; a 0-to-3 and a 3-to-6 ramp; every area reachable from the street up ramps (a graph walk); no ramp or ramp foot strip on a building, a boulder or off the map; no boulder on a rooftop or ramp; no building under a rooftop; the validator accepts the file; the check mode matches.

### The scene (T-196)

`scenes/elevation_sample/elevation_sample_map.tscn`, script `scripts/level/elevation_sample_map.gd`: the elevation test scene made city-sized. Drive-only: no enemies, minions, kaiju, weapons, run timer, likes, levels or HUD; the car just drives around freely. Not the main scene, not reachable from the menus (no button: one would need its text from the Narrative Theme Agent), no on-screen text.

**Open it (a proposal, as the elevation test scene):** open the scene in the editor and press F6, or from the repo root `"$GODOT_BIN" --path game res://scenes/elevation_sample/elevation_sample_map.tscn`. W/S/A/D drive. The car starts on the road at (-81, -50) facing north (`START_UNITS`, `START_ROTATION`), 4 units from the foot of the north-west garage's 0-to-3 ramp, so W drives straight up it.

**Run it headless** (no window, to check for errors): `python game/tools/run_scene_headless.py res://scenes/elevation_sample/elevation_sample_map.tscn 10` imports the project, runs the scene for 10 seconds and exits 0 when Godot printed no error lines (1 with the lines, 2 for bad arguments or no `GODOT_BIN`). `--show` also prints what the scene printed. Tests: `tools/test_run_scene_headless.py`.

What it holds:

- `Map`: the MVP map's script (`mvp_map.gd`, from `scenes/level/mvp_map.tscn`) with `layout_path` set to `data/level/elevation_sample_map.json` before it enters the tree, in the isometric view: the ground art, the buildings with their art (see-through: the scene fades them, see "Depth order and see-through (T-197)" below; `map.car` stays unset), the boulders and the edge walls. `layout_path` (new in T-196) defaults to `LAYOUT_PATH` (`mvp_map.json`); the run sets it to this file since T-206 ("The run's map (T-206)").
- `PhysicsWorld` (never drawn) holds the `Car` (`car.gd`), whose `ground` is the scene's `ground_height` (a `GroundHeight` read from the same file), so the car has its real height (`car_height.gd`) on the rooftops and ramps. It collides with the map's buildings, boulders and edge walls. `place_car(units, rotation)` puts it at rest on the ground there.
- `Map/Elevation` (since T-206, `elevation_layer.gd`; before, under `View`): one `elevation_platform_drawing.gd` node per platform and ramp in the file (`areas`, named `platform_<id>` and `ramp_<id>`), drawn with its own art from `art/elevation_sample/<id>.png` ("Rooftop and ramp art (T-198)" below) or, when that art is missing, with its script drawing. `View`: the `CarShadow` (`car_shadow.gd`, on the ground under the car: the rooftop's top, the ramp or the street); the `CarSprite` (the final isometric sheet, lifted by the car's height); and the `Camera` (`camera_follow.gd` with the saved zoom and camera options, following the car as drawn, height included and eased, T-228).

Tests: `tests/unit/test_elevation_sample_map.gd`. Screenshot fixtures (`tests/fixtures/elevation_sample_demo.gd`: a start, W held for `drive_steps` physics steps, then the car stops; `hold_w = false` keeps it standing, `zoom` > 0 fixes the zoom with the dynamic camera off): `elevation_sample_{street,ramp_0_3,ramp_3_6,height_3,height_6,air}.tscn`. For example `bash game/tools/screenshot.sh res://tests/fixtures/elevation_sample_air.tscn art-archive/T-196/screenshots/air.png 700` (the air shot drives 106 steps, so it needs many frames). Screenshots: `art-archive/T-196/screenshots/`.

### Rooftop and ramp art (T-198)

PixelLab art for every rooftop and ramp of `data/level/elevation_sample_map.json`: `art/elevation_sample/<area id>.png` (for example `roof-nw-3.png`, `ramp-se-0-3.png`) with its record `<id>.json` (kind, `top_left_art_px` from the drawn origin, 32 art px per unit, drawn at scale 0.5, the PixelLab records it came from). `elevation_platform_drawing.gd`'s `setup(kind, block, basis, art_dir, art_name)` adds a `Sprite2D` (`art_sprite`) when the PNG and record exist, and then draws nothing itself; with them missing the script drawing is the fallback. The elevation sample map scene passes `SAMPLE_ART_DIR` and the area's id; the elevation test scene keeps its own art (`art/elevation/`, T-186). The sprite is a child of the drawing, so it fades with its area when the area turns see-through.

Made from 8 PixelLab textures and details (`art-archive/T-198/`, 8 generations, `requests/` holds the request files) by `python game/tools/build_elevation_sample_art.py build` (needs Pillow and numpy; it projects the textures onto each area's top and its east and south walls, adds the parapet, details and cracks on the rooftops, outlines, and reduces each sprite to 30 colours; a few minutes for the two 84 x 30 rooftops). **To rebuild after a layout change** (the JSON's platforms or ramps): run `build` again; the details' places are fixed by each area's id. `python game/tools/build_elevation_sample_art.py --check` runs the art rules and the record checks on the committed files and exits 1 on a failure. It never calls PixelLab. Tests: `game/tools/test_build_elevation_sample_art.py` (Python: `python -m unittest discover -s game/tools -p test_build_elevation_sample_art.py`) and `tests/unit/test_elevation_sample_art.gd`. Screenshots: `art-archive/T-198/screenshots/` (`street.png`, `rooftop_height_3.png`, `rooftop_height_6.png`, `ramp.png`, `see_through.png`).

### Depth order and see-through (T-197)

Every raised area, ramp and building of the sample map is in one depth order with the car and its shadow (Level design, Decisions, "Elevation sample map: depth order and see-through"). Since T-206 the code is in `scripts/level/elevation_layer.gd` (the map's child `Elevation`), shared by this scene and the run; the scene's `restack()`, `z_for()`, `update_see_through()`, `covering_areas()` and the rest below call its layer (`elevation`).

- **One back-to-front order:** `restack()` sorts the map's building slots and the areas together (`drawn_before`: an item standing on another, a stacked rooftop or a ramp whose foot is on a rooftop, is drawn after it; otherwise one wholly west or north of the other first; ties by the centre's x + y) and gives each its own z_index, `BUILDING_Z_STEP` (3) apart from `DEPTH_Z_BASE` (5, one step over the map's base, so a car under a boulder under the first item, and its shadow, stay over the ground at z 0); `depth_items` is the order. Then the boulders (`boulder_z`: under the buildings and areas that cover them, otherwise over every item, areas included) and the pavement signs are put back in it.
- **The car and its shadow:** `z_for(height)` puts the car just under the lowest building, boulder or area that covers it, otherwise over everything (`top_z_index()`). An area covers the car when the car is behind it (its centre west or north of the area, judged by the centre so a wall hit from behind doesn't pop it over, T-191), lower than the area's top there, and its shape (lifted by its height) overlaps the area's outline on screen. So the car is drawn under an area it is behind and lower than, and over the ones it is on, above or in front of; a car on a height-3 rooftop behind a height-6 one is between the two. The shadow takes `z_for` at the ground's height under the car, one lower.
- **See-through:** `update_see_through(delta)` (every physics step, from `sync_view`) fades each area and ramp covering the car (`elevation_platform_drawing.gd`, `update_fade`) and each building covering it (`map_building.gd`, `update_fade`), both with the car's shape at its height, the shape the depth order uses, to `mvp_map.gd`'s `SEE_THROUGH_ALPHA` (15%) over `SEE_THROUGH_FADE_TIME` (0.15 s), and the others back to solid. The fade step is `map_building.gd`'s `faded_alpha` for both: no second formula. The map's own fade (`map.car`) is left off here so the buildings are not faded twice with the car's shape on the ground. `covering_areas()` and `covering_buildings()` list what covered the car at the last update.

Tests: `tests/unit/test_elevation_sample_depth.gd` (the car on height 3 behind a height-6 area, in the air above 6 over a height-3 area, behind a building next to the garage, on top of a height-6 area; every `drawn_before` pair kept; grids over both garages checking the car is under every area covering it and over every area it overlaps without being behind; the shadow over the ground everywhere; uncovered boulders over every item) and `tests/unit/test_elevation_sample_see_through.gd` (the fade's numbers and step, no second fade formula, which areas fade where, the buildings fading, and drives into the west and north sides of height-3 and height-6 areas, from the street and from a height-3 rooftop, with the car and shadow under the area on every step of the hit). Screenshot fixtures: `elevation_sample_behind_{height_3,height_6,building}.tscn` (the car standing for 15 steps, so the fade is done), for example `bash game/tools/screenshot.sh res://tests/fixtures/elevation_sample_behind_height_6.tscn art-archive/T-197/screenshots/behind_height_6.png 60`. Screenshots: `art-archive/T-197/screenshots/`.

### The car's height on the three layers (T-195)

The car's height (`car_height.gd`, "The car's height (T-183)" and "The platform's sides (T-184)" above) works unchanged on the sample map's three layers: no fix was needed for ramps whose foot is on a rooftop (a 3-to-6 ramp), because the walk, the takeoff and the landing read the ground's height under the car, wherever its zero is. Its constants are unchanged.

**Tests** (`tests/unit/test_car_height_layers.gd`, the real `car.gd` and `car_height.gd` on `data/level/elevation_sample_map.json`'s ground). The ramps and areas are picked from the file by their heights, never by coordinates, so a layout change doesn't break them:

- up a 0-to-3 ramp and up a 3-to-6 ramp, the height is the ground's under the car on every step;
- off a 3-to-6 ramp's top at about cruise speed, the car takes off with `vertical_speed = ramp_vertical_speed x RAMP_TAKEOFF_FACTOR`, along the slope's line;
- off a height-6 side, it falls and lands on the height-3 area past it, and, off another side, on the street (each side found by searching the height-6 areas' sides for flat ground at 6 inside and at 3, or 0, outside, no ramp);
- on a height-3 rooftop, the side of a height-6 area is a wall: one hit (`hit_obstacle` with the `GroundHeight` and the area's index), the bounce, the car stays at 3;
- in the sample map scene, every tall building and every boulder with a clear 6-unit approach (88 of them) blocks the car on the street, on height 3, on height 6 and in the air (at 8 units, rising). The layout keeps rooftops away from buildings and boulders, so for 3 and 6 the test raises a temporary rooftop under the approach and the obstacle; the buildings and boulders are the map's own bodies, which block in the flat world at every height.

**The scripted drive** (`tools/drive_elevation_sample.gd`): the real car in the sample map scene, driven by scripted inputs from the street up a 0-to-3 ramp, up the 3-to-6 ramp on the rooftop it reaches, across the height-6 rooftop and off its far edge. The route comes from the file by heights (`plan()`: the first 0-to-3 ramp with a 3-to-6 ramp on its rooftop); the inputs hold W and steer toward waypoints along it (A/D in proportion to the heading error, `STEER_GAIN`), then release W once the car leaves the edge. It prints each layer reached with its time, the waypoints, every jump (where it took off, its takeoff vertical speed, its maximum height, its airtime and where it landed), the maximum height, the airtime of the jump off the height-6 edge, any wall or obstacle hit, and PASS or FAIL. From the repo root:

```
bash game/tools/drive_elevation_sample.sh [--csv=<file.csv>] [--plot=<file.png>]
powershell -ExecutionPolicy Bypass -File game/tools/drive_elevation_sample.ps1 [--csv=<file.csv>] [--plot=<file.png>]
```

It runs headless. Exit codes: 0 = the street, height 3 and height 6 reached in that order and the car landed off the height-6 edge; 1 = not; 2 = bad arguments or no such route in the file. `--csv` writes one line per physics step (time, position, height, the ground's height under the car, airborne, W, steer); `--plot` draws the height over time as a PNG (and `<name>_light.png`): the car's height, the ground under it, the time in the air shaded, lines at 0, 3 and 6, a tick every second. `tests/unit/test_drive_elevation_sample.gd` runs the same drive and checks it passes (no wall on the way up, about 1 s in the air off the edge, landing on the street).

Screenshot fixtures (`tests/fixtures/elevation_sample_drive_demo.gd`: the same drive, stopped after `steps` physics steps, or `plot = true` to show the plot instead of the map): `elevation_sample_drive_{height_3,ramp_jump,off_edge,plot,plot_light}.tscn`, for example `bash game/tools/screenshot.sh res://tests/fixtures/elevation_sample_drive_plot.tscn art-archive/T-195/screenshots/height-over-time.png 30`. Screenshots: `art-archive/T-195/screenshots/`.

**The car without its sprite shadow in the air (T-205).** `scripts/driving/car_sprite.gd` loads `art/car/car_iso_noshadow.png` (T-204; same layout as `car_iso.png`) next to the normal sheet. `set_in_air(bool)` swaps only the texture, so the frame, offset and scale do not change; `is_in_air(height, ground_under)` is true when the car's height is above the ground under it. `sync_view()` of the elevation sample map and of the elevation test scene calls it after every physics step, so the sheet switches on the takeoff step and the landing step. The run calls it too on the elevation map (T-206, "The run's map (T-206)"); on the MVP map and in the drift prototype the car always draws `car_iso.png` (and the flat view has no air sheet). Tests: `tests/unit/test_car_noshadow_in_air.gd`. Screenshots: `art-archive/T-205/screenshots/` (`air.png` from `elevation_sample_air.tscn`, `street.png` from `elevation_sample_street.tscn`).

