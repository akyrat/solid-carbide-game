# Game

The Godot 4 project lives here: scenes, scripts, data (JSON), art and audio. Everything for the game, in the same repository as the documents.

## Setup

The engine is Godot 4.6.2. The scripts below find it through `GODOT_BIN` in `.env` at the repo root. To set that up, see [Secrets and API keys](../README.md#secrets-and-api-keys) in the root README.

## Folder layout

| Folder | What goes in it |
| --- | --- |
| `scenes/` | Scenes (`.tscn`). `drift_prototype/` is the drift prototype; `level/` is the MVP map; `run/` is the run |
| `scripts/` | Game GDScript (`.gd`). `driving/` holds the car's movement, the drift prototype and its tuning panel; `level/` the map and its challenges; `run/` the run and its state |
| `data/` | Game data as JSON (see "Game data"). `level/mvp_map.json` is the MVP map's layout |
| `art/` | Sprites, tilesets and other images |
| `audio/` | Sound effects and music |
| `tests/unit/` | GUT test scripts (`test_*.gd`), in subfolders if you like |
| `tests/fixtures/` | Scenes and files that exist only for tests |
| `tools/` | Test runner, screenshot tool, audio import checker, Freesound downloader, PixelLab client, placeholder car sheet generator and shared shell helpers. Not game code |
| `addons/gut/` | The GUT test framework (9.6.1). Do not edit |

The `.godot/` folder is Godot's cache. It is git-ignored and rebuilt automatically. Keep the `.uid` files Godot creates next to scripts: they belong in git.

## Running the tests

Run every command from the repo root. Each script runs from Git Bash, and has a PowerShell version too.

**Git Bash:**

```
bash game/tools/run_tests.sh
```

**PowerShell:**

```
powershell -ExecutionPolicy Bypass -File game/tools/run_tests.ps1
```

This imports the project, then runs every test under `game/tests/` headless (no window) with GUT. It prints `TESTS PASSED` and exits with code 0 when every test passes. It exits non-zero when a test fails, or when any script fails to parse or load. (On its own, GUT silently skips a test file with a parse error, so the runner treats a parse error as a failure.)

To run only some tests, add GUT options after the command. For example, `-gselect=test_sample` runs only test scripts whose name contains `test_sample`, and `-gunit_test_name=drift` runs only tests whose name contains `drift`.

### Python tool tests

Some tools in `game/tools/` are Python scripts (standard library only, Python 3.9+). Their tests are `game/tools/test_*.py` and run with Python's own test runner, not GUT:

```
python -m unittest discover -s game/tools -p "test_*.py"
```

It prints `OK` and exits with code 0 when every test passes. Run it alongside `run_tests.sh` before handing a task over.

### Writing tests

- Put test scripts under `game/tests/unit/` (subfolders are fine). Name the file `test_<something>.gd` and start it with `extends GutTest`.
- Each test is a function whose name starts with `test_`. Use asserts such as `assert_eq(got, expected)`, `assert_true(cond)` and `assert_almost_eq(got, expected, tolerance)`.
- `game/tests/unit/test_sample.gd` is a minimal example. The GUT documentation is at https://gut.readthedocs.io.
- Test settings (folders, file prefix) are in `game/.gutconfig.json`.

## Taking a screenshot

The screenshot tool runs a scene for a set number of frames, then saves what is on screen as a PNG. It opens a game window for a moment, because headless mode has no renderer and cannot take a picture.

**Git Bash:**

```
bash game/tools/screenshot.sh <res://path/to/scene.tscn> <out.png> [frames]
```

**PowerShell:**

```
powershell -ExecutionPolicy Bypass -File game/tools/screenshot.ps1 <res://path/to/scene.tscn> <out.png> [frames]
```

- The scene is a Godot resource path (`res://...`) inside `game/`.
- `frames` defaults to 60 (about one second at 60 fps).
- A relative output path is resolved against the current directory. Missing folders are created.
- Save screenshots to `screenshots/` at the repo root, which is git-ignored. Do not save them inside `game/`, or Godot imports them as project assets.
- Exit codes: 0 = PNG saved; 1 = bad arguments; 2 = scene could not be loaded; 3 = no image (the renderer did not run); 4 = PNG could not be written.

Example, using the test fixture scene:

```
bash game/tools/screenshot.sh res://tests/fixtures/screenshot_fixture.tscn screenshots/fixture.png 30
```

The image is the size of the game window (Godot's default 1152x648 until the project sets a resolution).

## Downloading sounds from Freesound

`game/tools/freesound.py` (used by the SFX Agent) searches Freesound and downloads the **original** sound files, not previews, with a metadata JSON next to each one. It reads `FREESOUND_CLIENT_ID` and `FREESOUND_API_KEY` from `.env` (see [Secrets and API keys](../README.md#secrets-and-api-keys)) and needs Python 3.9+ (standard library only). Run it from the repo root.

**One-time login.** Downloading originals needs the board's Freesound login (OAuth2):

```
python game/tools/freesound.py auth-url          # prints the login link for the board
python game/tools/freesound.py login <code>      # exchange the code Freesound shows after approving
```

The code expires within minutes, so run `login` as soon as it arrives. The tokens are stored in `.secrets/freesound_token.json` (git-ignored). The access token is renewed automatically with the refresh token, so later runs do not need the board. `python game/tools/freesound.py status` checks the stored login without downloading anything.

**Download:**

```
python game/tools/freesound.py download --query "car engine idle" --count 3 --out game/audio/sfx/<folder>
```

- Only Godot-importable formats (wav, ogg, mp3) are picked, and originals over 5 MB are skipped (`--max-bytes`, 0 = no limit). It does not filter by license.
- `--count` is how many sounds the folder should hold in total. Sounds already there (found by the Freesound id in their JSON) count towards it and are never downloaded twice, so re-running the same command downloads nothing, though it still checks (and if needed renews) the login.
- Each sound is saved as `<id>_<name>.<ext>` with `<id>_<name>.json` next to it. The JSON holds `freesound_id`, `name`, `username`, `freesound_url`, `license_name`, `license_url`, `search_query`, `download_date`, plus `file`, `original_type`, `duration_s` and `filesize_bytes`.
- Exit codes: 0 = done; 1 = request failed or fewer sounds found than asked; 2 = credentials missing from `.env`; 3 = login needed (run `auth-url` and `login` again).

## Checking audio imports

Checks that every `.wav`, `.ogg` and `.mp3` under a folder was imported by Godot and loads as a non-empty AudioStream. Runs headless and imports the project first.

**Git Bash:**

```
bash game/tools/check_audio.sh [res://folder]
```

**PowerShell:**

```
powershell -ExecutionPolicy Bypass -File game/tools/check_audio.ps1 [res://folder]
```

The folder defaults to `res://audio`. It prints one `OK` or `FAIL` line per file. Exit codes: 0 = all load; 1 = bad arguments or no audio files found; 2 = at least one file failed.

## Generating art with PixelLab

`game/tools/pixellab_client.py` (used by the Asset Generation Agent) calls the PixelLab API (https://api.pixellab.ai/v2) directly, with Python 3.9+ and the standard library only. It reads `PIXELLAB_API_KEY` from the environment or from `.env` (see [Secrets and API keys](../README.md#secrets-and-api-keys)) and never prints or stores it. Run it from the repo root.

**Balance (free):**

```
python game/tools/pixellab_client.py balance
```

**Generate one asset (a paid call):**

```
python game/tools/pixellab_client.py generate --endpoint create-image-pixflux \
  --params '{"description": "...", "image_size": {"width": 64, "height": 64}}' \
  --out-dir game/art/<folder> --name <asset-name> \
  --consulted docs/visual-style.md --consulted <other resource> --task T-000
```

- `--endpoint` takes the endpoint without its leading slash (Git Bash turns a leading `/` into a Windows path). Known endpoints: `create-image-pixflux` and `create-image-bitforge` (direct: the image comes back in the response) and `create-isometric-tile` (asynchronous: the script polls the background job every 5 s, stops with an error on `failed` or after 10 minutes, then fetches the tile). Others are added in the `ENDPOINTS` table at the top of the script.
- `--params` is the request body as JSON; `--params-file` reads it from a file instead. `--consulted` (repeatable, at least one) lists the documents and other resources looked at before generating. `--notes` adds free text to the record.
- Each call makes exactly one generation request and never retries. It refuses to overwrite an existing `<name>.png` or `<name>.json`, so an asset cannot be regenerated by accident.
- It saves `<name>.png` and a record `<name>.json` next to it: `endpoint`, `request_params`, `prompt`, `job_id` (`null` for direct endpoints), any result id such as `tile_id`, `usage` (the cost PixelLab reports), `generated_at`, `image` (width, height), `resources_consulted`, `task` and `notes`.
- Every generation call, successful or not, is also appended to `game/art/pixellab-generation-log.jsonl`.
- Exit codes: 0 = saved (or balance shown); 1 = token missing, bad parameters, request failed, job failed or polling timed out; 2 = bad command-line arguments.

Its Python tests (`game/tools/test_pixellab_client.py`) run with the Python tool tests command above and never call PixelLab. `game/tests/unit/test_pixellab_assets.gd`, part of the GUT suite, checks that every generated PNG under `art/` loads in Godot with the size its record gives.

## Placeholder car sprite sheets

`game/tools/generate_car_sheets.gd` (tasks T-013 and T-018, Asset Generation Agent) draws the placeholder car: a plain 48 x 16 pixel rectangle, 3 times as long as it is wide (1 unit wide, 3 units long, 16 pixels per unit), with a differently coloured nose (the front 8 pixels), in 16 directions. It is drawn pixel by pixel by a script, not generated with PixelLab, and running it again gives byte-identical files. The drawing code is `game/tools/car_sheet_generator.gd`; its tests are `game/tests/unit/test_car_sheets.gd` (part of the GUT suite).

**Regenerate the sheets** (headless, from the repo root):

```
bash game/tools/generate_car_sheets.sh
```

```
powershell -ExecutionPolicy Bypass -File game/tools/generate_car_sheets.ps1
```

It overwrites, in `game/art/placeholders/car/`:

- `car_flat.png`: the flat top-down view.
- `car_iso.png`: the same rectangle in a 2:1 isometric projection, screen = (x - y, (x + y) / 2), flat (no box height).
- `car_flat.json` and `car_iso.json`: the layout below, the car's drawn size (`car_size_units`: width 1, length 3; `car_size_px`: width 16, length 48; `px_per_unit`: 16), a `record` (script, command, settings, placeholder) and the nose's world heading and screen angle for every frame.

**Layout** (the same for both sheets, and for the full-art sheets that replace them later):

- One row of 16 frames, each 80 x 80 pixels; frame `i` starts at x = `i * 80`. The sheet is 1280 x 80. (The 2:1 sheets from T-013 used 64 x 64 frames; the longer car needs up to about 36 pixels from the centre in the isometric view, so the frames grew.)
- Frames are indexed by the car's heading in the flat physics world (Godot axes, y down). Frame 0 is heading 0 degrees, nose along world +x (pointing right in the flat view, down-right in the isometric view). Each next frame adds 22.5 degrees, turning clockwise on screen, the way Godot's `rotation` grows. For a car body whose nose is +x at rotation 0, the frame is `posmod(roundi(rotation / deg_to_rad(22.5)), 16)` in both views.
- In the isometric sheet the world headings are 22.5 degrees apart, so the nose's angle on screen is not evenly spaced (the JSON lists it per frame).
- The car's centre is the point (40, 40) in frame pixel coordinates (top-left of the frame = 0, 0), the middle of the frame: a `Sprite2D` with `centered = true`, `hframes = 16` and no offset puts the car's centre on the node's origin.
- Scale: 1 world pixel = 1 sprite pixel in the flat view; the isometric sheet projects those same world pixels. One unit is 16 pixels, so to draw the car at its world size, scale the sprite by (world size of 1 unit) / `px_per_unit`. The size is the drawing only: the car's physics body is a 1 by 1 unit square (Drifting, Decisions), so the drawing sticks out 1 unit past it at the front and back.

## Drift prototype

The first playable piece (task T-012): the car driving and drifting like the board's Unity prototype, on a flat, empty ground with a grid, with a tuning panel and a flat / isometric view switch. It is the project's main scene. After the board's playtest (task T-029) it differs from the Unity prototype in four defaults (see Drifting, Decisions, 2026-10-08): top speed multiplier 3.0 (top speed 33; Unity 2.5), cruise jump still 11, physics interpolation on, and it starts in the isometric view. Every other driving value is the Unity value.

**Run it:**

- From the Godot editor: open the `game/` folder as a project and press F5 (Run Project), or open `scenes/drift_prototype/drift_prototype.tscn` and press F6.
- Without the editor, from the repo root in Git Bash: `"$GODOT_BIN" --path game` (with `GODOT_BIN` from `.env`). In PowerShell: `& $env:GODOT_BIN --path game` after setting `$env:GODOT_BIN` to the same path.

**Keys:**

| Key | Does |
| --- | --- |
| W | Forward: jumps to cruise speed, then speeds up to top speed |
| S | Brakes while moving forward, then reverses |
| A / D | Rotate the car left / right (at any speed, also standing still) |
| Tab | Opens and closes the tuning panel |
| V | Switches between the flat top-down and the isometric view |

Escape is not used here (pause is task T-015). There is no jump, no arrow-key steering and no gamepad.

**Tuning panel** (Tab): a live readout (speed, forward and sideways speed, drift angle, drift amount), a button that resets everything to the game's values (the defaults above, interpolation on, zoom 14.4), an "Isometric view" toggle (same as V; on at start), a "Physics interpolation" toggle (on by default), the camera zoom slider (6 to 20, starting at 14.4) and one slider per handling setting. Every slider starts at the game's value and applies at once; hover a slider or its label for a tooltip, which also shows the Unity value. Changes are not saved: restarting goes back to the defaults.

**How it is built** (`scripts/driving/`):

- `car_model.gd`: the movement, step by step as in the Unity prototype report, section 4, in units (1 unit = the car's width). No nodes, so tests run it directly. Its `cruise_jump(from_speed, w_just_pressed)` signal fires when W makes the car jump up to cruise speed (for the boost effect, task T-008).
- `car_tuning.gd`: the handling values (defaults = the Unity values except top speed multiplier 3.0; the `UNITY` constant keeps the Unity values) and the slider list with labels, ranges and tooltips.
- `car.gd`: the car's `CharacterBody2D` in the flat physics world, a 1 x 1 unit square, running the model once per physics step (50 per second, set in `project.godot`). It relays `cruise_jump` and emits `stepped` after every step.
- `drift_prototype.gd`: builds the scene. The physics world is never drawn; the `View` node draws the ground grid and the car sprite either flat or through the 2:1 isometric projection screen = (x - y, (x + y) / 2), and places the camera exactly on the drawn car (no rotation, no smoothing). Switching views changes only the drawing.
- `car_sprite.gd`: picks the sheet frame closest to the car's heading, reading the layout from the JSON next to each sheet (see "Placeholder car sprite sheets"), so the final art drops in without code changes.
- `ground_grid.gd`, `tuning_panel.gd`: the ground and the panel.

**Pixel scale:** 16 pixels per unit in the flat world, the same as the placeholder car sheets, so the sheets are drawn at scale 1. The camera zoom is Unity's orthographic size (half the visible height in units); Godot's zoom is set to window height / (2 x size x 16), so 14.4 shows 28.8 units from top to bottom in both views.

**Tests:** `tests/unit/test_drift_model.gd` (the movement against the report's numbers) and `tests/unit/test_drift_prototype.gd` (settings, input map, sliders, reset, view switch, camera, sprite), part of the GUT suite. For screenshots of a scripted drive, use the fixtures `res://tests/fixtures/drift_prototype_demo_flat.tscn` and `..._iso.tscn` (add `_panel` for the panel open) with the screenshot tool, for example `bash game/tools/screenshot.sh res://tests/fixtures/drift_prototype_demo_iso.tscn screenshots/drift_iso.png 400`.

## Game data

Written by the Game Data Agent (task T-038); the enemy, weapon and garage data tasks follow the same convention.

- **Where:** one JSON file per area under `game/data/` (`run.json` for the run's XP, levels and car starting health). Keys are `snake_case`. A `_comment` key may explain a file. Numbers are proposals the board judges in playtests, and are changed in the file, never in code.
- **Loader:** `scripts/data/game_data.gd` (`GameData`). `GameData.load_file("run")` reads `res://data/run.json`; `GameData.get_value(data, "car.starting_health")` reads a dotted path (array indexes as numbers). Both return `{ok, data, error}`: a missing file, invalid JSON or missing value gives `ok = false` and a clear `error` message. `GameData.unwrap(result)` returns the data, or `push_error`s the message and returns null.
- **Typed readers:** for each data file, a small class next to the loader wraps it so game code does not index dictionaries. `scripts/data/run_data.gd` (`RunData`) gives `xp_needed(level)`, `challenge_xp(level)`, `drift_xp_per_second()`, `max_level()`, `carries_over()` and `starting_health()`.
- **Tests:** `tests/unit/test_run_data.gd`. New data files get a test that loads them through the loader.

## Challenge drivability check

`game/tools/check_challenge.gd` (task T-021, Driving & Drift Agent) checks that a challenge drawing (`docs/level-design/<pattern>/arrow-*.json`) can be driven. The Level/Challenge Design Agent runs it on every challenge before handing it over.

**Run it** (headless, from the repo root; give drawings or folders, which are searched recursively):

```
bash game/tools/check_challenge.sh --save docs/level-design
```

```
powershell -ExecutionPolicy Bypass -File game/tools/check_challenge.ps1 --save docs/level-design
```

- It prints the car's handling values, then one line per drawing: `PASS` with how long the drive took and how fast it went, or `FAIL` with how far along the arrow the best attempt got, the drawing point nearest that place (numbered from the start, 1 = the white dot), what went wrong (left the corridor, hit a boulder, hit a building, stopped making progress) and the radius of the drawn curve there.
- `--save` writes, next to each passing drawing, `<name>.driven.json` (the line the car drove: x, y, speed and heading every physics step, plus the driver setting and the handling values used) and `<name>.driven.svg` (the drawing with the driven line in cyan and the drawn car every half second). It never changes the drawing's own `.json` or `.svg`.
- `--attempts=<folder>` writes a picture of the furthest attempt for each failing drawing into that folder (`<pattern>-<name>.attempt.svg`). Use a folder outside `docs/` and `game/`, such as `screenshots/`.
- `--set=<key>=<value>` overrides one handling value from `scripts/driving/car_tuning.gd` for this run, for example `--set=top_speed_multiplier=3.0`. Without it, the check uses the game's current values.
- Exit codes: 0 = every drawing can be driven; 1 = at least one cannot; 2 = bad arguments or a drawing could not be read.

**What it checks.** It drives the game's own car code (`scripts/driving/car_model.gd`, with the values in `car_tuning.gd`), 50 physics steps per second, pressing W, S, A and D each step like a player. The car starts on the arrow's first point, nose along the arrow. A drive passes when the car's centre reaches the arrow's last point while:

- the drawn car (1 by 3 units) touches the 3-unit corridor on every step, on the stretch of the arrow it has reached (3 units behind to 6 units ahead), so a path that crosses itself is followed in order;
- the car's physics body (1 by 1 unit) never touches a boulder or a building cell (`B`) of the drawing.

The centre line is the same rounded curve the drawing's picture shows. Two drivers try it:

- **A path follower** (120 fixed settings): it aims at a point a little way ahead on the arrow, turning the nose a bit past it to cancel the slide (counter-steer), and holds a target speed: W below it (W jumps to cruise speed, so under cruise it coasts and taps W), S when well above. The settings are 10 target speeds from top speed down to 3 units/s, 4 look-ahead distances and 3 counter-steer strengths.
- **A search over key combinations:** from a standstill on the arrow's start, it tries all 9 sets of keys (W, S or neither, with A, D or neither), each held for 5 physics steps, from the 48 most promising drives so far (furthest along the arrow and nearest its centre line, spread over positions, headings and speeds), until one reaches the end or none is left.

The drawing passes if any drive passes; the saved line is the quickest passing drive. On a fail, the reported place is the furthest any drive got. The `PASS` line also says whether the path follower passed with W held the whole way (a target speed at or above cruise speed), a quick sign of how hard the challenge is. Everything is deterministic: the same drawing and values always give the same result. A run of the 3 MVP drawings takes about 15 seconds.

The drawn car only has to touch the corridor, and it is 3 units long, so its centre can be up to about 3 units from the arrow's centre line. A quick drive can therefore cut inside a loop, close to a boulder, and the driven-line pictures show where it does. The drawn car may also overlap a boulder in the picture: only the 1 by 1 physics body collides.

The code is `tools/challenge_checker.gd` (the check and the picture) and `tools/check_challenge.gd` (the command line); its tests are `tests/unit/test_challenge_checker.gd`, part of the GUT suite.

## MVP map

The city map (task T-019): the 80 by 80 unit city grid, the obstacle pattern copies and the preset challenges, in flat placeholder colours. What it contains and why: `docs/level-design.md`, Content, "MVP map".

**Open it:**

- In the Godot editor: open `scenes/level/mvp_map_overview.tscn` (the whole map, flat top-down) or `scenes/level/mvp_map_overview_iso.tscn` (isometric) and press F6 (Run Current Scene). `scenes/level/mvp_map.tscn` is the map itself, without a camera, for putting into a run.
- Screenshot, from the repo root: `bash game/tools/screenshot.sh res://scenes/level/mvp_map_overview.tscn screenshots/mvp_map.png 10` (use `..._iso.tscn` for the isometric view).

**Layout data:** `data/level/mvp_map.json` holds the whole map in units from the map's centre (x right, y down): the buildings, an 80 by 80 grid of ground cells (R road, G gravel, B building), the pattern copies with their boulders, and the challenges with their arrow points and centre lines. It and the fitted patterns next to the board's sketches (`docs/level-design/<pattern>/<arrow>.fitted.json` and `.svg`) are made by a script; do not edit them by hand. To change the copies or which ones are challenges, edit `COPIES` and `CHALLENGES` at the top of the script and run it:

```
python game/tools/build_mvp_map.py
```

Running it twice gives identical files. Its tests (`game/tools/test_build_mvp_map.py`) run with the Python tool tests and fail if the files on disk are out of date.

**How it is built** (`scripts/level/`):

- `mvp_map.gd`: builds the map from the layout data. Same units and physics as the drift car: 16 pixels per unit, the map's centre on the node's origin. The `Physics` child holds static bodies on collision layer 1 (the buildings and the map's edge in `Walls`, and one body per pattern copy for its boulders), never drawn. The `View` child draws the map, flat or isometric (`set_view("flat" | "iso")`), like the drift prototype.
- To check the challenges, set the map's `car` to the car node (its position in the same flat world pixels, nose along +x at rotation 0), or call `update_car(centre_in_units, rotation)` once per physics step. When a challenge is completed, its arrow is hidden, its boulders stay, and the map emits `challenge_completed(challenge_id)` once. `challenge_ids()`, `get_challenge(id)` and `is_challenge_completed(id)` give the challenges and their positions.
- `challenge_tracker.gd`: the completion rule for one challenge (no nodes, so tests run it directly).
- `challenge_arrow.gd`: the placeholder arrow (a blue band as wide as the corridor, a white start dot and an arrowhead).
- `map_overview.gd`: the overview scenes, with a camera that fits the whole map.

The car does not collide with the map yet: the drift car's collision response (bouncing off walls and boulders, Drifting, Decisions) is the Driving & Drift Agent's.

**Tests:** `tests/unit/test_mvp_map.gd` (part of the GUT suite): the grid against Level design, the boulders and fitted patterns against the sketches, the 30% rule, nothing overlapping a building or leaving the map, and a stand-in body driving the challenges.

## The run

The run itself (task T-036): `scenes/run/run.tscn` puts the MVP map and the drift car together under a camera that follows the car, and holds the run's state: the 8-minute clock, the car's health, the coins collected this run, and win and loss (Game loop architecture, Decisions). The drift prototype stays as it is, as a tuning tool.

**Run it:** in the Godot editor, open `scenes/run/run.tscn` and press F6. Screenshot, from the repo root: `bash game/tools/screenshot.sh res://scenes/run/run.tscn screenshots/run.png 30`. Keys: W, S, A and D, as in the drift prototype. Nothing happens on screen when the run ends yet (the screen flow and the HUD are later tasks).

**The scene** (`scripts/run/run.gd`, root node `Run`):

- Children: `Map` (the MVP map scene, drawn in the isometric view), `PhysicsWorld` (the `Car`, never drawn, in the same flat world pixels as the map), `View` (the car's sprite and the `Camera`) and `RunState` (the state, below).
- The car starts at the centre of the map (0, 0 units, in the gravel square), nose along -y, as in the drift prototype. The camera sits exactly on the drawn car, zoom 14.4, as in the drift prototype. The map checks its challenges against the car (`map.car`).
- `run.start_run()` starts a fresh run: it replaces the map (every challenge open again) and the car (back at the start, standing still), emits `world_rebuilt`, then resets the state. The scene calls it once in `_ready()`. Anything holding the old `run.map` or `run.car` picks up the new ones on `world_rebuilt`.

**The state** (`scripts/run/run_state.gd`, class `RunState`). Reach it with `run.state`, or from anywhere with `get_tree().get_first_node_in_group("run_state")`.

| Function | Does |
| --- | --- |
| `start_run()` | Resets the state for a fresh run: health = max health = the starting health in `data/run.json`, 8:00 on the clock, 0 coins. Use `run.start_run()` to reset the map and car too |
| `damage_car(amount: float)` | Takes `amount` off the car's health (stops at 0). At 0 the run ends as a loss. Ignored when the run is over or `amount` is not positive |
| `add_coins(amount: int)` | Adds coins collected this run. Ignored when the run is over or `amount` is not positive |
| `kaiju_killed()` | The Enemy Behavior Agent calls it when the kaiju dies: the run ends at once as a win. Ignored when the run is over |
| `advance(seconds: float)` | Moves the clock forward by hand (tests). The clock otherwise runs on its own in `_process` |
| `is_running()` | True from `start_run()` until the run ends |
| `time_left_text()` | The time left as M:SS ("8:00" ... "0:01", "0:00"), rounded up to whole seconds |
| `shown_seconds()`, `time_elapsed()` | The time left in whole seconds as the clock shows it; seconds since the run started |

| Value | Is |
| --- | --- |
| `time_left` | Seconds left, 480 at the start, 0 at the end |
| `health`, `max_health` | The car's health now, and its full health |
| `coins` | Coins collected this run |
| `result` | "" while the run is going, then "win" or "loss" |

| Signal | Fires |
| --- | --- |
| `run_started()` | When a fresh run starts (after every value is reset) |
| `boss_time()` | Once per run, when 7 minutes have passed (1:00 left). The kaiju spawns on it |
| `run_ended(result: String, coins: int)` | Once per run: "win" (kaiju killed) or "loss" (health at 0, or the clock reaching 0:00), with this run's coins, kept either way. Saving them is a Game Data task that listens here |
| `time_left_changed(seconds_left: float)` | When the clock shows a different whole second (and on start) |
| `health_changed(health: float, max_health: float)` | When the car takes damage (and on start) |
| `coins_changed(coins: int)` | When coins are added (and on start) |

**Pause:** the clock runs in `_process` with the default (pausable) process mode, so setting `get_tree().paused = true` stops it. Anything that pauses the run (the pause screen, the level-up choice) does it that way. The run's length (8 minutes) and the boss's arrival (7 minutes in) are constants in `run_state.gd`, `RUN_SECONDS` and `BOSS_TIME_LEFT`, because they are Decisions, not balancing numbers.

**Tests:** `tests/unit/run/test_run_state.gd` (the clock, boss time, health, coins, win and loss, pause, a second run) and `tests/unit/run/test_run_scene.gd` (the map and car loaded, the start position, the camera following the car, a second run resetting the map and car), part of the GUT suite.
