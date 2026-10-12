# Game

The Godot 4 project lives here: scenes, scripts, data (JSON), art and audio. Everything for the game, in the same repository as the documents.

## Setup

The engine is Godot 4.6.2. The scripts below find it through `GODOT_BIN` in `.env` at the repo root. To set that up, see [Secrets and API keys](../README.md#secrets-and-api-keys) in the root README.

## Folder layout

| Folder | What goes in it |
| --- | --- |
| `scenes/` | Scenes (`.tscn`). `game/game.tscn` is the main scene (the screen flow); `drift_prototype/` is the drift prototype; `level/` is the MVP map; `run/` is the run |
| `scripts/` | Game GDScript (`.gd`). `game/` holds the screen flow; `driving/` holds the car's movement, the drift prototype and its tuning panel; `level/` the map and its challenges; `run/` the run and its state |
| `data/` | Game data as JSON (see "Game data"). `level/mvp_map.json` is the MVP map's layout |
| `art/` | Sprites, tilesets and other images |
| `audio/` | Sound effects and music |
| `tests/unit/` | GUT test scripts (`test_*.gd`), in subfolders if you like |
| `tests/fixtures/` | Scenes and files that exist only for tests |
| `tools/` | Test runner, screenshot tool, audio import checker, Freesound downloader, PixelLab client, sprite rule checker, placeholder car sheet generator, final car sheet builder and shared shell helpers. Not game code |
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

- `--endpoint` takes the endpoint without its leading slash (Git Bash turns a leading `/` into a Windows path). Known endpoints: `create-image-pixflux`, `create-image-bitforge`, `inpaint` and `rotate` (direct: the image comes back in the response; `rotate` takes no prompt), `create-isometric-tile` (asynchronous: the script polls the background job every 5 s, stops with an error on `failed` or after 10 minutes, then fetches the tile) and `generate-8-rotations-v3` (asynchronous, polled for up to 20 minutes; it returns 8 images, each saved as `<name>_<index>.png` with its own record, and each record says the call's usage is shared by all of them). Others are added in the `ENDPOINTS` table at the top of the script. The HTTP read timeout is 600 s: slow calls are charged even when they time out.
- `--params` is the request body as JSON; `--params-file` reads it from a file instead. `--consulted` (repeatable, at least one) lists the documents and other resources looked at before generating. `--notes` adds free text to the record.
- Each call makes exactly one generation request and never retries. It refuses to overwrite an existing `<name>.png` or `<name>.json`, so an asset cannot be regenerated by accident.
- It saves `<name>.png` and a record `<name>.json` next to it: `endpoint`, `request_params`, `prompt`, `job_id` (`null` for direct endpoints), any result id such as `tile_id`, `usage` (the cost PixelLab reports), `generated_at`, `image` (width, height), `resources_consulted`, `task` and `notes`.
- Every generation call, successful or not, is also appended to `game/art/pixellab-generation-log.jsonl`.
- Exit codes: 0 = saved (or balance shown); 1 = token missing, bad parameters, request failed, job failed or polling timed out; 2 = bad command-line arguments.

Its Python tests (`game/tools/test_pixellab_client.py`) run with the Python tool tests command above and never call PixelLab. `game/tests/unit/test_pixellab_assets.gd`, part of the GUT suite, checks that every generated PNG under `art/` loads in Godot with the size its record gives.

## The first final car sprite (T-014)

`game/art/car/car_sw_front.png` (128 x 128, with its record `car_sw_front.json` and the PixelLab log entry): the dark-green 1967 Mustang GT with two white stripes, nose at the bottom-left of the screen (PixelLab direction `south-west`). It matches frame 4 of the placeholder isometric sheet (heading 90 degrees, nose on screen at 153.43 degrees, down-left along the isometric axis). It is frame 4 of the final car sheet (T-101, next section), unchanged. Check it against Visual style's technical rules with `python game/tools/check_sprite_rules.py game/art/car/car_sw_front.png` (tests: `game/tools/test_check_sprite_rules.py`).

Archived versions (2026-10-12): the board approved this original, shadow included. The other versions (a script-made shadowless copy, a PixelLab inpaint, a fresh generation) and T-003's test art are not game art; they are kept in `art-archive/` at the repo root, outside the Godot project, with a table of what each is in `art-archive/README.md`. `game/tools/remove_car_shadow.py` is kept; its test reads the archived copy.

## The final car sheet (T-101)

`game/art/car/car_iso.png` (2048 x 128: one row of 16 frames of 128 x 128) and `car_iso.json`: the pixel-art car in 16 directions, in T-013's layout and JSON convention. The game draws it in the isometric view (the run and the drift prototype); the flat view keeps the placeholder (Visual style, Decisions).

- **Frames:** frame 4 is T-014's approved sprite, unchanged. The other even frames come from one PixelLab `/generate-8-rotations-v3` call on that sprite, and each odd frame from a PixelLab `/rotate` of the frame before it by 22 degrees. The raw PixelLab frames are not game-ready on their own (49 to 272 colours), so they and their records are archived in `art-archive/T-101/frames/` (listed in `art-archive/README.md`), where the build script reads them; `car_iso.json` lists the source of each frame, its world heading, the nose's ideal screen angle and the angle actually seen (PixelLab's isometric diagonals are flatter than the game's 2:1, so the two differ by up to about 20 degrees, and more in frame 11; T-101's result notes).
- **Built by** `python game/tools/build_car_sheet.py` (run from the repo root; byte-identical every run). It adds no new pixels: it maps every opaque pixel to the nearest colour of the approved sprite's 33-colour palette (PixelLab's rotations come back with 49 to 272 colours) and moves each frame by whole pixels so its bounding-box centre sits where the approved sprite's does. Tests: `game/tools/test_build_car_sheet.py` (Python) and `game/tests/unit/test_car_final_sheet.gd` (GUT).
- **Layout values:** frame 128 x 128, `center_px` (64.5, 65.5), `px_per_unit` 32. The sprite is drawn at scale 16 / 32 = 0.5 in the 16 px per unit world, so the car is about 3 units long; 32 was fitted to the art, because PixelLab's car is not drawn in the game's exact projection (side views come out a little shorter, diagonal ones a little longer).
- **Check the rules** for every frame: `python game/tools/check_sprite_rules.py game/art/car/car_iso.png --frames 16` (each frame has 27 to 33 colours, all from the approved sprite; the default limit is 30, so frames with 31 to 33 print FAIL on that line only; add `--max-colors 33` to check against the approved sprite's own count).
- **Screenshots** of the car in a run started from the main menu, in any direction: `CAR_HEADING_DEG=<degrees> bash game/tools/screenshot.sh res://tests/fixtures/car_art_from_menu_demo.tscn screenshots/car.png 40` (heading 0 = frame 0; frame = heading / 22.5).

## The first road tile (T-063)

`game/art/ground/road_tile.png` (128 x 64 pixels, 8-bit RGBA, 9 colours) and its record `road_tile.json`: the board-approved asphalt road tile (2026-10-12): dark navy-purple asphalt, light cracks, a white dashed lane line. Not in the map yet: T-103 does that.

- **Size and repeat:** a 2:1 isometric diamond of 128 x 64 art pixels, **2 x 2 units** at the car art's density (32 art pixels per unit); the game draws art at scale 0.5, so it covers 64 x 32 screen pixels. Neighbours sit at (+64, +32) pixels across the road (world x) and (-64, +32) along it (world y); the tile is cut to the exact footprint, so repeats have 0 gaps and 0 overlaps. The line runs along world y. A road 24 units wide is 12 tiles across, so a centred line needs a double line or a centre-line piece (T-103).
- **How it was made:** one PixelLab `/create-tiles-pro` call (six variations) -> tile 1 squashed to 2:1 -> `build_road_tile.py fix` (edge outline removed, line brightened) -> the board edited the line by hand. Everything else (the other five tiles, the script-fix step, the board's indexed original and every mock-up, including the approved tile's `road_mockup.png`) is in `art-archive/T-063/`; T-103 may take tiles from there to break up the repeating cracks.
- **Tool:** `game/tools/build_road_tile.py` (`process`, `fix`, `check`, `mockup`; tests in `game/tools/test_build_road_tile.py`). Check the tile: `python game/tools/build_road_tile.py check game/art/ground/road_tile.png`.
- **The client** (`pixellab_client.py`) now knows `create-tiles-pro`: `/tiles-pro/{tile_id}` answers with storage URLs, which it downloads (the storage host refuses Python's default user agent) and saves one PNG and record per tile.

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

**Layout** (the same for both sheets, and for the full-art sheet that replaced the isometric one in the game, which has its own frame size, centre and pixels per unit in its JSON):

- One row of 16 frames, each 80 x 80 pixels; frame `i` starts at x = `i * 80`. The sheet is 1280 x 80. (The 2:1 sheets from T-013 used 64 x 64 frames; the longer car needs up to about 36 pixels from the centre in the isometric view, so the frames grew.)
- Frames are indexed by the car's heading in the flat physics world (Godot axes, y down). Frame 0 is heading 0 degrees, nose along world +x (pointing right in the flat view, down-right in the isometric view). Each next frame adds 22.5 degrees, turning clockwise on screen, the way Godot's `rotation` grows. For a car body whose nose is +x at rotation 0, the frame is `posmod(roundi(rotation / deg_to_rad(22.5)), 16)` in both views.
- In the isometric sheet the world headings are 22.5 degrees apart, so the nose's angle on screen is not evenly spaced (the JSON lists it per frame).
- The car's centre is the point (40, 40) in frame pixel coordinates (top-left of the frame = 0, 0), the middle of the frame: a `Sprite2D` with `centered = true`, `hframes = 16` and no offset puts the car's centre on the node's origin.
- Scale: 1 world pixel = 1 sprite pixel in the flat view; the isometric sheet projects those same world pixels. One unit is 16 pixels, so to draw the car at its world size, scale the sprite by (world size of 1 unit) / `px_per_unit`. The size is the drawing only: the car's physics body is a 1 by 1 unit square (Drifting, Decisions), so the drawing sticks out 1 unit past it at the front and back.

## Main menu

The main menu (task T-054, UI Agent): `scenes/menu/main_menu.tscn` with its script `scripts/menu/main_menu.gd` (`MainMenu`). What it shows: `docs/hud-and-menus.md`, Content. The game opens on it through the screen flow (see "Screen flow").

- **Open it:** in the editor, open the scene and press F6. Screenshot, from the repo root: `bash game/tools/screenshot.sh res://scenes/menu/main_menu.tscn screenshots/main_menu.png 20`.
- **Signals:** `start_pressed`, `garage_pressed`, `exit_pressed`, one per button. The menu does nothing else when a button is pressed.
- **Tests:** `tests/unit/test_main_menu.gd` (the texts and each signal), part of the GUT suite.

## Screen flow

Task T-055 (Game Loop Agent). `scenes/game/game.tscn` (script `scripts/game/game_flow.gd`, class `GameFlow`) is the project's main scene: pressing F5 in the editor, or `"$GODOT_BIN" --path game`, starts the game on the main menu. The flow is Game loop architecture, Content, "Screen flow".

- **Start** removes the menu and starts a fresh run (`scenes/run/run.tscn`), with the pause screen (Escape) added to the run and the camera zoom read from the saved setting.
- **When the run ends,** win or loss (`RunState.run_ended`), the run is removed and the main menu comes back straight away, with no message.
- **Garage** does nothing yet (task T-089 wires it to the garage screen).
- **Exit** closes the game (`get_tree().quit()`, through `quit_game`, which tests replace).
- Only one screen is on show at a time, as the only child of `Game`: `game.menu` or `game.run` (the other is null). `game.pause_screen` is the run's pause screen. The signals `menu_shown` and `run_shown` fire after each switch.
- **Tests:** `tests/unit/game/test_screen_flow.gd`, part of the GUT suite: the first screen, Start, a win and both kinds of loss back to the menu, a second run, Garage, Exit, Escape during a run, and the zoom.

## Drift prototype

The first playable piece (task T-012): the car driving and drifting like the board's Unity prototype, on a flat, empty ground with a grid, with a tuning panel and a flat / isometric view switch. It is no longer the project's main scene (the main menu is, since task T-055); it stays as a tuning tool. After the board's playtest (task T-029) it differs from the Unity prototype in four defaults (see Drifting, Decisions, 2026-10-08): top speed multiplier 3.0 (top speed 33; Unity 2.5), cruise jump still 11, physics interpolation on, and it starts in the isometric view. Every other driving value is the Unity value.

**Run it:**

- From the Godot editor: open the `game/` folder as a project, open `scenes/drift_prototype/drift_prototype.tscn` and press F6 (Run Current Scene). F5 starts the game on the main menu instead.
- Without the editor, from the repo root in Git Bash: `"$GODOT_BIN" --path game res://scenes/drift_prototype/drift_prototype.tscn` (with `GODOT_BIN` from `.env`). In PowerShell: `& $env:GODOT_BIN --path game res://scenes/drift_prototype/drift_prototype.tscn` after setting `$env:GODOT_BIN` to the same path.

**Keys:**

| Key | Does |
| --- | --- |
| W | Forward: jumps to cruise speed, then speeds up to top speed |
| S | Brakes while moving forward, then reverses |
| A / D | Rotate the car left / right (at any speed, also standing still) |
| Tab | Opens and closes the tuning panel |
| V | Switches between the flat top-down and the isometric view |
| Escape | Pauses and resumes. The pause screen shows the title, a hint and the camera zoom slider (see "Pause screen") |

There is no jump, no arrow-key steering and no gamepad.

**Tuning panel** (Tab): a live readout (speed, forward and sideways speed, drift angle, drift amount, and the last trick, how long ago it was and how many of each trick so far), a button that resets everything to the game's values (the defaults above, interpolation on, zoom 14.4, wall bounce 0.25, the trick limits), an "Isometric view" toggle (same as V; on at start), a "Physics interpolation" toggle (on by default), the camera zoom slider (6 to 20, starting at 14.4), one slider per handling setting and, in a "Collisions" group at the bottom, the wall bounce slider (task T-033: 0 to 1, proposed default 0.25; see "Car collisions") and, in a "Tricks" group under it, the alternate drift's limits (task T-079; see "Tricks"). Every slider starts at the game's value and applies at once; hover a slider or its label for a tooltip, which also shows the Unity value. Changes are not saved: restarting goes back to the defaults.

**Test room** (task T-033): a few walls and one boulder (3 units across) around the start point, so the board can try the bounce: a closed square of walls 40 units from the start on every side, an L-shaped wall to the right of the start (its corner about 25 units right and 25 up) and the boulder 12 units right and 12 up. Placeholder colours, the MVP map's. The real map is the MVP map (below).

**How it is built** (`scripts/driving/`):

- `car_model.gd`: the movement, step by step as in the Unity prototype report, section 4, in units (1 unit = the car's width). No nodes, so tests run it directly. Its `cruise_jump(from_speed, w_just_pressed)` signal fires when W makes the car jump up to cruise speed (for the boost effect, task T-008).
- `car_tuning.gd`: the handling values (defaults = the Unity values except top speed multiplier 3.0; the `UNITY` constant keeps the Unity values) and the slider list with labels, ranges and tooltips.
- `car.gd`: the car's `CharacterBody2D` in the flat physics world, a 1 x 1 unit square, running the model once per physics step (50 per second, set in `project.godot`). It relays `cruise_jump` and emits `stepped` after every step. It also handles collisions, the `hit_obstacle` signal and knockback (see "Car collisions"), and the `trick` signal (see "Tricks").
- `trick_detector.gd`: finds the tricks in the car's driving (see "Tricks"). No nodes, so tests run it directly.
- `drift_prototype.gd`: builds the scene. The physics world is never drawn; the `View` node draws the ground grid and the car sprite either flat or through the 2:1 isometric projection screen = (x - y, (x + y) / 2), and places the camera exactly on the drawn car (no rotation, no smoothing). Switching views changes only the drawing.
- `car_sprite.gd`: picks the sheet frame closest to the car's heading, reading the layout from the JSON next to each sheet (see "Placeholder car sprite sheets"), so the final art drops in without code changes.
- `ground_grid.gd`, `tuning_panel.gd`: the ground and the panel.
- `test_room.gd`: the test room's walls and boulder (static bodies on layer 1, under `PhysicsWorld`) and their drawing.

**Pixel scale:** 16 pixels per unit in the flat world, the same as the placeholder car sheets, so the flat placeholder sheet is drawn at scale 1 and the final isometric sheet (32 px per unit) at scale 0.5. The camera zoom is Unity's orthographic size (half the visible height in units); Godot's zoom is set to window height / (2 x size x 16), so 14.4 shows 28.8 units from top to bottom in both views.

**Tests:** `tests/unit/test_drift_model.gd` (the movement against the report's numbers) `tests/unit/test_drift_prototype.gd` (settings, input map, sliders, reset, view switch, camera, sprite), `tests/unit/test_car_collisions.gd` (bounce, enemies, the hit signal, knockback, layers, the test room and the bounce slider) and `tests/unit/test_tricks.gd` (the three tricks, the trick signal, the trick sliders and readout, and the movement being the same with detection on and off), part of the GUT suite. For screenshots of a scripted drive, use the fixtures `res://tests/fixtures/drift_prototype_demo_flat.tscn` and `..._iso.tscn` (add `_panel` for the panel open) with the screenshot tool, for example `bash game/tools/screenshot.sh res://tests/fixtures/drift_prototype_demo_iso.tscn screenshots/drift_iso.png 400`. `res://tests/fixtures/drift_prototype_room_flat.tscn` and `..._iso.tscn` drive the car into the test boulder, zoomed out to show the walls (40 frames is enough).

## Car collisions

Task T-033. What the car does when it hits things is decided in Drifting, Decisions: it bounces slightly off walls (buildings and the map's edge) and boulders, and does not bounce off enemies, which only damage it. Minions and meteors knock it back (Enemies, Decisions).

### Collision layers

Every task that adds physics bodies uses these layers. They are named in `project.godot` (Project Settings, Layer Names, 2D Physics), and `scripts/driving/car.gd` has them as constants (`LAYER_OBSTACLES`, `LAYER_CAR`, `LAYER_ENEMIES`, `LAYER_PICKUPS`).

| Layer | Bit value | Name | What is on it | Set up as |
| --- | --- | --- | --- | --- |
| 1 | 1 | `obstacles` | Walls, buildings, the map's edge and boulders: everything the car bounces off. The MVP map's `Walls` and `Boulders_*` bodies, and the drift prototype's test room | `StaticBody2D` on layer 1, mask none |
| 2 | 2 | `car` | The player's car (`car.gd`) | Layer 2, mask 1: it collides only with obstacles |
| 3 | 4 | `enemies` | Minions, the kaiju, meteors | Layer 3. Their mask must not include layer 2, so they and the car never push each other. To touch or damage the car, use an `Area2D` whose mask includes layer 2 |
| 4 | 8 | `pickups` | Coins and other pickups | `Area2D` on layer 4 with mask 2, to notice the car driving over it |

Walls and boulders share layer 1 because the MVP map builds them that way and the car treats them the same. To tell them apart (for example in the combo), use the body `hit_obstacle` reports: on the MVP map, `map.walls` is the buildings and the edge, `map.boulder_bodies` the pattern copies' boulders and `map.meteor_boulder_bodies` the boulders meteors left. Weapons and their projectiles have no layer yet; the weapon tasks add one (the next free number) to this table.

### Bounce

When the car's 1 by 1 unit body hits anything on layer 1, it stops against it for that physics step, and the part of its velocity going into the surface is reversed and scaled by the wall bounce setting (`tuning.wall_bounce`, the tuning panel's "Wall bounce" slider). The part along the surface is kept, so after a glancing hit the car carries on along the wall while being pushed off it. 0 = no bounce (it slides along), 1 = it bounces back as fast as it hit. The proposed default is **0.25**: a head-on hit at cruise speed (11 units/s) bounces back at 2.75 units/s, one at top speed (33) at 8.25. The board judges it in a playtest. The Unity prototype has no bounce (report, section 3).

After the bounce the driving model carries on as usual. Holding W with the nose against the wall snaps the car back to cruise speed into it on the next step, so it stays pressed against the wall; let go of W, reverse or steer away to leave it. The drawn car (1 by 3 units) may overlap a wall or boulder: only the body collides.

### Collision signal

```
signal hit_obstacle(collider: Object, shape_index: int, normal: Vector2, impact_speed: float)
```

The car emits it once per hit on anything on layer 1, for the combo (task T-081). `collider` is the `StaticBody2D` hit and `shape_index` which of its shapes (which building or boulder); `normal` is the surface normal, pointing out of the obstacle towards the car; `impact_speed` is the car's speed into the surface in units per second, before the bounce. Staying pressed against the same obstacle is one hit: it counts again only once the car has been more than 0.25 units away from it (`REARM_GAP_UNITS`).

### Knockback

```
func apply_knockback(direction: Vector2, strength: float) -> void
```

Call it on the car node to knock the car back, for example for a minion hit or a meteor impact (Enemy Behavior Agent; the strengths are game data). `direction` is in the flat physics world (x right, y down) and does not need to be normalized; a zero direction is ignored. `strength` is a speed in units per second. On the car's next physics step, after the driving model's own update, `direction.normalized() * strength` is added to the car's velocity. Several calls before one step add up. `pending_knockback()` returns what is waiting.

From then on the push is ordinary speed: the part across the nose fades with the sideways grip (like a drift), the part along the nose changes the forward speed (with W held and the nose against the push, W snaps it back to cruise speed on the step after, as after a bounce), and a push into a wall bounces off it and emits `hit_obstacle`.

## Tricks

Task T-079. The MVP's three tricks are decided in Drifting, Decisions. The car finds them in its own driving and never changes how it drives to do it: `scripts/driving/trick_detector.gd` (`TrickDetector`) only reads the driving model after each physics step. Every car (the drift prototype's and the run's) has one, `car.tricks`.

### Trick signal

```
signal trick(trick_id: String)
```

The car node (`scripts/driving/car.gd`) emits it once per trick, at the physics step the trick is completed, for the combo (task T-081) and the trick popups. Several tricks can complete on the same step; each gets its own signal.

| Trick id | Trick | Fires |
| --- | --- | --- |
| `extended_drift` | Extended drift | Every full second of one unbroken drift: 3.5 s of drifting gives 3 |
| `three_sixty` | 360 | Each time the car's heading has turned a full 360 degrees in one direction during one unbroken drift: 720 degrees gives 2 |
| `alternate_drift` | Alternate drift | Each switch between a forward drift and a backward drift with the same steering side, once the new drift has lasted the shortest drift time |

The ids are constants on `TrickDetector` (`TRICK_EXTENDED_DRIFT`, `TRICK_THREE_SIXTY`, `TRICK_ALTERNATE_DRIFT`, and the list `TRICK_IDS`); they match the keys of `trick_add` in `data/combo.json`. `car.tricks.last_trick`, `car.tricks.seconds_since_last` and `car.tricks.counts` (trick id to count) are there for readouts; `car.tricks.reset()` forgets every drift in progress and the counts. `car.detect_tricks = false` turns detection off.

### How each trick is found

- **Drifting** is the driving model's own `is_drifting`, the Unity definition: W, or S without W, held together with A or D. A **break** is any physics step on which the car is not drifting.
- **Extended drift:** drifting time adds up step by step; each full second (`EXTENDED_DRIFT_SECONDS`) is one trick. A break starts the second again; changing steering side or between W and S without a break does not.
- **360:** the heading's change adds up step by step while drifting. Turning the other way starts the count again from that step; a break starts it from zero. A full turn (360 degrees, 94 steps with the default turn speed) is one trick, and the count carries on towards the next one.
- **Alternate drift:** the driving is cut into drift segments, each with one direction (W: forward, S without W: backward) and one steering side. A switch counts when, in order: a segment lasts at least the **shortest drift** time; it ends (W or S released, or straight from W to S); within the **switch time** a segment starts in the other direction with the same steering side; and that segment also lasts the shortest drift time, at which moment the trick fires. Holding S before releasing W counts as a switch with no gap. A segment too short to count breaks the chain. While **keep steering** is on, letting go of A or D (or pressing the other one) between the two drifts cancels the trick. Forward to backward and backward to forward each count, so W, S, W, S with A held all the way gives 3.

### Alternate drift limits

The limits are tuning values in `scripts/driving/car_tuning.gd` (`TRICK_SETTINGS`), read live, with sliders in the tuning panel's "Tricks" group. The panel's reset puts them back to these proposed values, for the board to tune:

| Setting | Key | Proposed | Slider |
| --- | --- | --- | --- |
| Switch time: longest time from the end of one drift to the start of the opposite one | `alternate_max_switch_seconds` | 0.5 s | 0 to 2 s |
| Shortest drift: how long both drifts must last; the trick fires when the new one reaches it | `alternate_min_drift_seconds` | 0.3 s | 0 to 2 s |
| Keep steering: A or D must stay held on the same side during the switch | `alternate_keep_steering` | on | on / off toggle |

The extended drift's second and the 360's full turn are Decisions, so they are constants, not sliders.

## Trick popups

Task T-091 (UI Agent). When the car's `trick` signal fires, the trick's name pops out above the car, rises and fades (text from T-082, wording in `docs/hud-and-menus.md`, "Trick popups").

- `scripts/hud/trick_popups.gd` (`TrickPopups`): a node in the world view (next to the car sprite) in both the run (`run.trick_popups`) and the drift prototype (`prototype.trick_popups`). `bind(car, car_position_callable)` listens to a car's `trick`; the run binds again each time it builds a new car. `show_popup(text, drawn_position, font_size)` shows any text. `bind_score(run_state, car_position_callable)` (task T-092) shows the challenge popup, "Trending! +{likes} Likes" (`SCORE_TEXT`), for the run state's `score` signal; the run binds it once. `bind_combo(run_state, car_position_callable)` (task T-083) shows the trick popups from the run state's `combo_trick` signal, with the amount added (`trick_text(trick_id, added)`, e.g. "FULL 360! +0.25", the name only at the cap); once bound, the car's own `trick` signal no longer shows a popup, so the run does not show two. The drift prototype binds only the car and shows names only. `popups()` lists the popups showing. Sizes are `SIZE_NORMAL` (28) and `SIZE_SMALL` (16, extended drift).
- **Tests:** `tests/unit/test_trick_popups.gd` (part of the GUT suite): each trick's text near the car, rising and going away, the small extended-drift popup, a second run, any text, and a drive in the prototype. `tests/unit/test_challenge_popup.gd`: the score signal and a completed challenge in the run. Screenshot of a challenge popup in a run from the main menu: `bash game/tools/screenshot.sh res://tests/fixtures/challenge_popup_demo.tscn screenshots/challenge_popup.png 30`. Trick screenshot: `bash game/tools/screenshot.sh res://tests/fixtures/trick_popups_demo.tscn screenshots/trick_popups.png 10`.

## Pause screen

Task T-015 (UI Agent). Escape (the `pause` action in the input map) pauses the whole game tree and shows the pause screen: the title, a hint that Escape resumes, and one setting, the camera zoom slider (6 to 20, default 14.4, the same value as the tuning panel's zoom slider; moving either updates the other). Pressing Escape again resumes from exactly where the car was. The tuning panel (Tab) does not work while paused. The texts are from task T-047. The slider's label is "Camera zoom level" (T-093). The panel sits in a compact strip just below the HUD timer (`STRIP_TOP`), only as tall as its content (T-095), over a light dim, and moving the slider zooms the view behind it at once while everything stays paused (the camera normally updates in the physics step, which does not run while paused, so while paused it updates every frame with physics interpolation off, and resuming puts it back). A full pause menu with more settings is task T-016.

- `scripts/ui/pause_screen.gd`: the screen. It keeps processing while the tree is paused, handles Escape and sets the zoom on the scene it belongs to.
- `scripts/ui/game_settings.gd` (`GameSettings`): the saved zoom, in `user://settings.cfg` (section `camera`, key `zoom`). Read when the game starts; no file, a bad value or no value gives 14.4, and a saved value outside 6 to 20 is clamped. The pause slider saves on every change; the tuning panel's zoom slider and its reset button do not save.
- **Tests:** `tests/unit/test_pause_screen.gd` (part of the GUT suite) uses a test settings file, never the real one. For a screenshot of the paused game: `bash game/tools/screenshot.sh res://tests/fixtures/pause_screen_demo.tscn screenshots/pause.png 300`; `pause_screen_demo_in.tscn` and `pause_screen_demo_out.tscn` do the same with the slider moved to 7 and 19 after pausing; `pause_from_menu_demo.tscn` pauses a run started from the main menu.

## Game data

Written by the Game Data Agent (task T-038); the enemy, weapon and garage data tasks follow the same convention.

- **Where:** one JSON file per area under `game/data/` (`run.json` for the run's XP, levels and car starting health). Keys are `snake_case`. A `_comment` key may explain a file. Numbers are proposals the board judges in playtests, and are changed in the file, never in code.
- **Loader:** `scripts/data/game_data.gd` (`GameData`). `GameData.load_file("run")` reads `res://data/run.json`; `GameData.get_value(data, "car.starting_health")` reads a dotted path (array indexes as numbers). Both return `{ok, data, error}`: a missing file, invalid JSON or missing value gives `ok = false` and a clear `error` message. `GameData.unwrap(result)` returns the data, or `push_error`s the message and returns null.
- **Typed readers:** for each data file, a small class next to the loader wraps it so game code does not index dictionaries. `scripts/data/run_data.gd` (`RunData`) gives `xp_needed(level)`, `challenge_xp(level)`, `drift_xp_per_second()`, `max_level()`, `carries_over()` and `starting_health()`. `scripts/data/combo_data.gd` (`ComboData`, from `combo.json`) gives `trick_add(trick)`, `after_trick()`, `after_collision()`, `after_idle()` and `spawn_multiplier()`.
- **Garage:** `garage.json` holds the 3 upgrades (`acceleration`, `car_health`, `damage_bonus`), 10 levels each, with a `price` and a `value` per level and a `base_value` for level 0. `scripts/data/garage_data.gd` (`GarageData`) gives `max_level()`, `price(upgrade, level)` and `value(upgrade, level)`. Tests: `tests/unit/test_garage_data.gd`.
- **Weapons (T-040):** `data/weapons.json` holds the starting gun and the exhaust flamethrower: base values and, for each, the 7 upgrade tiers (tiers 2 to 8) as `effect` plus `value`. `scripts/data/weapon_data.gd` (`WeaponData`) adds the tiers up: `gun_at(tier)` and `flame_at(tier)` return the weapon's values at that tier (tier 1 = just got it), and `tiers(weapon)` the raw list. Tests: `tests/unit/test_weapon_data.gd`, which compares everything with the Unity weapons report.
- **Tests:** `tests/unit/test_run_data.gd`, `tests/unit/test_combo_data.gd`, `tests/unit/test_garage_data.gd`, `tests/unit/test_weapon_data.gd`. New data files get a test that loads them through the loader.

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

The city map (task T-019, made bigger in tasks T-094 and T-096): the 240 by 240 unit city grid (24-unit roads, 30 by 30 blocks) and the obstacle pattern copies, in flat placeholder colours. What it contains and why: `docs/level-design.md`, Content, "MVP map".

**Challenges are off in the MVP** (task T-097; Level design, Decisions). The map builds no challenge trackers and no arrows, so it never sends `challenge_completed`, and the run never sends `score`; the pattern copies' boulders stay as plain obstacles. Everything for challenges is kept, unused, and still tested with challenges switched on: the 18 preset challenges and the 3 fitted designs in `data/level/mvp_map.json` (the build script still writes them), `challenge_tracker.gd` (the completion rule), `challenge_arrow.gd` (the arrows), the meteor challenge functions below, the run's wiring of both challenge signals to the likes, the challenge popup, and the drivability check.

**Turning challenges back on:** in `scripts/level/mvp_map.gd`, set `const CHALLENGES_ENABLED := true`. Every map then builds its preset challenges (arrows and completion checks), the run's included, since the run's `challenges_enabled` defaults to that constant. For one map or run only (tests, fixtures), set `map.challenges_enabled = true` before the map enters the tree, or `run.challenges_enabled = true` and then `run.start_run()`. Then update the tests in `tests/unit/test_mvp_map_no_challenges.gd`, which check they are off, and `test_run_scene.gd`'s first test.

**Open it:**

- In the Godot editor: open `scenes/level/mvp_map_overview.tscn` (the whole map, flat top-down) or `scenes/level/mvp_map_overview_iso.tscn` (isometric) and press F6 (Run Current Scene). `scenes/level/mvp_map.tscn` is the map itself, without a camera, for putting into a run.
- Screenshot, from the repo root: `bash game/tools/screenshot.sh res://scenes/level/mvp_map_overview.tscn screenshots/mvp_map.png 10` (use `..._iso.tscn` for the isometric view).

**Layout data:** `data/level/mvp_map.json` holds the whole map in units from the map's centre (x right, y down): the buildings, a 240 by 240 grid of ground cells (R road, G gravel, B building), the pattern copies with their boulders, and the challenges with their arrow points and centre lines. It and the fitted patterns next to the board's sketches (`docs/level-design/<pattern>/<arrow>.fitted.json` and `.svg`) are made by a script; do not edit them by hand. The map's size is set by `MAP_SIZE`, `PERIMETER_ROAD`, `BLOCK`, `ROAD`, `BLOCKS_PER_SIDE` and `GRAVEL` at the top of the script (the fitting reads the road width from `ROAD` too); where the copies go by `make_copies()` and which ones are challenges by `make_challenges()`. After a change, run it:

```
python game/tools/build_mvp_map.py
```

Running it twice gives identical files. Its tests (`game/tools/test_build_mvp_map.py`) run with the Python tool tests and fail if the files on disk are out of date.

**How it is built** (`scripts/level/`):

- `mvp_map.gd`: builds the map from the layout data. Same units and physics as the drift car: 16 pixels per unit, the map's centre on the node's origin. The `Physics` child holds static bodies on collision layer 1 (the buildings and the map's edge in `Walls`, and one body per pattern copy for its boulders), never drawn. The `View` child draws the map, flat or isometric (`set_view("flat" | "iso")`), like the drift prototype.
- To check the challenges (when switched on), set the map's `car` to the car node (its position in the same flat world pixels, nose along +x at rotation 0), or call `update_car(centre_in_units, rotation)` once per physics step. When a challenge is completed, its arrow is hidden, its boulders stay, and the map emits `challenge_completed(challenge_id)` once. `challenge_ids()`, `get_challenge(id)` and `is_challenge_completed(id)` give the challenges and their positions.
- `challenge_tracker.gd`: the completion rule for one challenge (no nodes, so tests run it directly). Unused while challenges are off.
- `challenge_arrow.gd`: the placeholder arrow (a blue band as wide as the corridor, a white start dot and an arrowhead).
- `map_overview.gd`: the overview scenes, with a camera that fits the whole map.

**Meteor boulders** (task T-097, for the Enemy Behavior Agent's meteor attack, T-046). The kaiju's meteors leave plain boulders where they land (Enemies, Decisions): no challenge and no arrow. Positions are in units from the map's centre (x right, y down).

| Function | Does |
|---|---|
| `can_place_meteor_boulder(centre: Vector2) -> bool` | The placement check: true when a boulder centred on `centre` lies wholly inside the map (-120 to 120) and does not overlap a building or any boulder already on the map (a pattern copy's, another meteor boulder's or a meteor challenge's). Just touching is allowed |
| `add_meteor_boulder(centre: Vector2) -> StaticBody2D` | Places one boulder: the same size (`boulder_diameter()`, 3 units, read from the map's own boulders), look (drawn with the map's boulders) and collision (a circle on a `StaticBody2D` on layer 1, under the map's `Physics`, so the car bounces off it and `hit_obstacle` reports it) as the map's boulders. Returns its body, also added to `meteor_boulder_bodies`. It does not run the placement check: call `can_place_meteor_boulder` first |
| `meteor_boulders` | The placed meteor boulders, `{x, y, diameter}` in units, in order. `all_boulders()` includes them |

A new run (`run.start_run()`) builds a new map, so meteor boulders go with the old one. Screenshot of a run started from the main menu, with one meteor boulder by the crossing at 0, -54 and no arrows: `bash game/tools/screenshot.sh res://tests/fixtures/map_from_menu_demo.tscn screenshots/map_from_menu.png 30`.

**Meteor challenges** (task T-035; off in the MVP, kept for later: the kaiju's meteors leave plain boulders instead, above). These functions work whether or not preset challenges are switched on, but nothing in the game calls them. The kaiju's meteors land as one of the 3 challenge designs; the map places it, draws its arrow in green, and checks it with the same completion rule as the preset challenges. Positions are in units from the map's centre (x right, y down); the angle is in radians, clockwise on screen, like `Node2D.rotation` (0 = the design as fitted: the Two Boulders runs along y).

| Function or signal | Does |
| --- | --- |
| `challenge_design_ids()` | The designs: `"single-boulder/arrow-1"`, `"single-boulder/arrow-2"`, `"two-boulders/arrow-1"` |
| `can_place_meteor_challenge(design_id, centre, angle) -> bool` | The placement check: true when none of the design's boulders and no part of its 3-unit corridor overlaps a building, a boulder already on the map (preset or meteor) or the map's edge. False for an unknown design |
| `add_meteor_challenge(design_id, centre, angle) -> String` | Creates the challenge: boulders (static bodies on layer 1, in `meteor_boulder_bodies`), the green arrow, and its completion check. Returns its id (`"meteor-1"`, `"meteor-2"`, ...), or `""` for an unknown design. It does not run the placement check: call `can_place_meteor_challenge` first |
| `meteor_challenge_completed(challenge_id)` (signal) | Fired once when a meteor challenge is completed, with the id `add_meteor_challenge` returned. Its arrow disappears and its boulders stay. Preset challenges send `challenge_completed` instead, never this one, and meteor challenges never send `challenge_completed` |
| `meteor_challenge_ids()`, `open_meteor_challenge_ids()` | All meteor challenges in creation order, and those not completed yet. Any number can be open at once |
| `get_meteor_challenge(id)`, `is_meteor_challenge(id)`, `is_challenge_completed(id)` | A meteor challenge's placed boulders and centre line (units), whether an id is a meteor challenge, and whether a challenge (preset or meteor) is completed |
| `place_design(design_id, centre, angle)`, `get_challenge_design(design_id)`, `all_boulders()` | Helpers: a design's placed boulders and centre line without creating it, a design as stored (unplaced), and every boulder on the map now |

The designs come from `challenge_designs` in `data/level/mvp_map.json` (the fitted versions, unplaced), written by `build_mvp_map.py`. Screenshot of a meteor challenge beside a preset one: `bash game/tools/screenshot.sh res://tests/fixtures/meteor_challenge_demo.tscn screenshots/meteor_challenge.png 10` (`..._iso.tscn` for isometric).

The map's static bodies are on collision layer 1, which the drift car (`scripts/driving/car.gd`) collides with and bounces off (see "Car collisions"). Putting the car into the map is for the run's scene.

**Tests:** `tests/unit/test_mvp_map.gd` (part of the GUT suite): the grid against Level design, the boulders and fitted patterns against the sketches, the 30% rule, nothing overlapping a building or leaving the map, and a stand-in body driving the challenges (with challenges switched on). `tests/unit/test_meteor_challenges.gd` (switched on too): creating each design at a position and angle, completing meteor challenges (one or several) and their signal, preset challenges not sending it, and the placement check. `tests/unit/test_mvp_map_no_challenges.gd` (task T-097): a run started from the main menu has no challenges and no arrows, every pattern copy's boulders are where the layout data puts them (the same as with challenges on), driving the car along every former challenge's arrow never sends `score` while drifting still gives likes, and the meteor boulders (placement check, size and collision, the car bouncing off one, a new run leaving them behind).

## The run

The run itself (task T-036): `scenes/run/run.tscn` puts the MVP map and the drift car together under a camera that follows the car, and holds the run's state: the 8-minute clock, the car's health, the coins collected this run, and win and loss (Game loop architecture, Decisions). The drift prototype stays as it is, as a tuning tool.

**Run it:** in the Godot editor, open `scenes/run/run.tscn` and press F6. Screenshot, from the repo root: `bash game/tools/screenshot.sh res://scenes/run/run.tscn screenshots/run.png 30`. Keys: W, S, A and D, as in the drift prototype. Run on its own like this, nothing happens on screen when the run ends and Escape does not pause; started from the main menu (see "Screen flow"), Escape pauses and the end of the run goes back to the menu.

**The HUD** (task T-090): `scenes/hud/hud.tscn` with `scripts/hud/hud.gd` (`Hud`, a CanvasLayer) is added by the run scene and bound to the run's state (`run.hud`). It shows the timer (`hud.timer_label`, M:SS from `time_left_text()`), and since T-049 the car's health bar (`health_bar`, `health_label`), the likes bar (`likes_bar`, `likes_label`, `heart`) with the level (`level_label`) and the coins (`coins_label`, `coins_value_label`), following the run state's `health_changed`, `xp_changed`, `coins_changed` and (T-083) `combo_changed`: the combo counter `combo_label` ("Combo x{multiplier}", `Hud.combo_text()`) to the right of the likes row. The texts are T-048's (`Hud.TEXT_*`). It appears in every run, also one started from the main menu. A screenshot fixture of it is `tests/fixtures/hud_from_menu_demo.tscn`. What it shows: `docs/hud-and-menus.md`, Content. Tests: `tests/unit/hud/test_hud_timer.gd`, `test_hud_values.gd` and `test_hud_combo.gd` (the counter and the popup amounts), screenshot of the counter and a popup per trick in a run from the main menu: `bash game/tools/screenshot.sh res://tests/fixtures/combo_demo.tscn screenshots/combo.png 30`; part of the GUT suite.

**The scene** (`scripts/run/run.gd`, root node `Run`):

- Children: `Map` (the MVP map scene, drawn in the isometric view), `PhysicsWorld` (the `Car`, never drawn, in the same flat world pixels as the map), `View` (the car's sprite and the `Camera`) and `RunState` (the state, below).
- The car starts at the centre of the map (0, 0 units, in the gravel square), nose along -y, as in the drift prototype. The camera sits exactly on the drawn car, zoom 14.4, as in the drift prototype. The map checks its challenges against the car (`map.car`).
- `run.start_run()` starts a fresh run: it replaces the map (meteor boulders gone; every challenge open again when challenges are on) and the car (back at the start, standing still), emits `world_rebuilt`, then resets the state. The scene calls it once in `_ready()`. Anything holding the old `run.map` or `run.car` picks up the new ones on `world_rebuilt`.

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

**Likes (XP) and levels** (task T-037; the rules are Game loop architecture, Decisions, the numbers are `data/run.json` through `RunData`). The run scene connects the map's `challenge_completed` and `meteor_challenge_completed` to `state.challenge_completed` (neither fires while challenges are off in the MVP, so likes come from drifting only), and after every car physics step calls `state.drift_step(car.model.is_drifting, car.model.dt)`. Drifting is the driving model's `is_drifting` (the Unity definition: W, or S without W, held with A or D). All XP gained is multiplied by the combo (below).

| Function | Does |
| --- | --- |
| `challenge_completed(challenge_id: String)` | A challenge (preset or meteor) was completed: sends `score` with the current level's `challenge_xp`, then adds it as XP |
| `drift_step(drifting: bool, delta: float)` | One physics step of the car's drift state. An unbroken drift gives `drift_xp_per_second` when it reaches 1 s (the first second included), then again at each further full second: 0.9 s gives nothing, 3 s gives 3 seconds' worth, 3.5 s gives 3. A step without drifting ends the drift |
| `add_xp(amount: float)` | Adds XP. Each time XP reaches the level's threshold, the level goes up by one and `level_up` fires; leftover XP carries over (`carry_over_xp`), so one gain can give several level-ups. At the top level (`max_level`) XP stays at 0 and the bar stops |
| `xp_needed()` | The current level's threshold (0 at the top level) |
| `is_max_level()` | True at the top level |
| `choice_made()` | The player made the level-up's weapon choice (T-052 calls it): the next waiting choice starts, or the run resumes. Ignored when no choice is waiting |
| `is_waiting_for_choice()`, `choice_level()` | Whether the run is paused for a choice, and the level whose choice is on show (0 for none) |

| Value | Is |
| --- | --- |
| `xp` | XP toward the next level (after leftovers), 0 at the start |
| `level` | The level, 1 at the start |
| `pause_on_level_up` | The level-up pause switch, **off for now**. Off: a level-up raises the level and the run carries on. On (T-052 turns it on): each level-up pauses the run (`get_tree().paused`, so the clock and the car stop) until `choice_made()`; two level-ups at once wait one after the other |
| `pending_choices` | The levels whose choice is waiting, oldest first (switch on only) |

| Signal | Fires |
| --- | --- |
| `xp_changed(xp: float, xp_needed: float, level: int)` | When XP or the level changes, and on start. For the HUD's likes bar (T-049) |
| `score(amount: float, challenge_id: String)` | When a challenge is completed, with the XP (likes) it gave. For the challenge popup (T-092) |
| `level_up(new_level: int)` | Once per level reached, switch on or off |
| `level_up_choice_started(new_level: int)` | Switch on: the run is now paused for that level's choice (T-052 opens its screen here) |
| `level_up_choice_made(new_level: int)` | Switch on: `choice_made()` closed that level's choice |

A new run (`start_run()`) resets XP to 0 and the level to 1, forgets the drift in progress and any waiting choice (unpausing if it was waiting). Nothing is added after the run ends.

**The combo** (task T-081; the rules are Game loop architecture, Decisions, the numbers are `data/combo.json` through `ComboData`). The run scene connects the car's `trick` signal to `state.add_trick` and the car's `hit_obstacle` (walls, buildings, the map edge, boulders) to `state.collision`. `damage_car()` also calls `collision()`, so any damage to the car (enemies, meteors) cuts the combo. The multiplier multiplies all XP gained: `challenge_completed()` (and its `score` signal), the drift seconds of `drift_step()`, and `add_xp()`.

| Function | Does |
| --- | --- |
| `add_trick(trick_id: String)` | The car did a trick: the multiplier goes up by `trick_add[trick_id]`, held at `max_multiplier`, and the drain wait starts again. Sends `combo_trick`, then `combo_changed` (if it changed). An id that is not one of `TrickDetector.TRICK_IDS` is ignored |
| `collision()` | The car collided with something: the multiplier is cut by `collision_cut` (80%) of the part above `start_multiplier` (`ComboData.after_collision`) |
| `combo_spawn_multiplier()` | How much the minion spawn rate is multiplied at the current combo (`ComboData.spawn_multiplier`, 1.0 with no combo). For enemy spawning (T-085) |

| Value | Is |
| --- | --- |
| `combo` | The multiplier now, `start_multiplier` (1.0, no combo) at the start of a run |
| `combo_idle` | Seconds since the last trick (or the run's start). Once it passes `drain_wait_seconds` (2 s), the multiplier drains by `drain_per_second`, down to `start_multiplier` |

| Signal | Fires |
| --- | --- |
| `combo_trick(trick_id: String, added: float, multiplier: float)` | Every trick during the run: the trick, how much the multiplier went up (the data's amount, less at the cap, 0 once there) and the new multiplier. For the trick popups (T-083) |
| `combo_changed(multiplier: float)` | Whenever the multiplier changes (a trick, a collision, the drain, every frame while draining) and on start. For the HUD's combo counter (T-083) and enemy spawning (T-085) |

The drain runs with the clock (`advance()`), so it stops while the run is paused, and the drain wait does not count paused time. A new run resets the multiplier and the drain wait. Nothing changes after the run ends.

**Pause:** the clock runs in `_process` with the default (pausable) process mode, so setting `get_tree().paused = true` stops it. Anything that pauses the run (the pause screen, the level-up choice) does it that way. The run's length (8 minutes) and the boss's arrival (7 minutes in) are constants in `run_state.gd`, `RUN_SECONDS` and `BOSS_TIME_LEFT`, because they are Decisions, not balancing numbers.

**Tests:** `tests/unit/run/test_run_state.gd` (the clock, boss time, health, coins, win and loss, pause, a second run), `tests/unit/run/test_run_scene.gd` (the map and car loaded, the start position, the camera following the car, a second run resetting the map and car) and `tests/unit/run/test_run_likes.gd` (challenge and meteor challenge XP, drift seconds, level-ups and leftovers, the pause switch off and on, two level-ups at once, the top level, a new run resetting XP) and `tests/unit/run/test_run_combo.gd` (tricks raising the multiplier, the cap, likes multiplied, collisions and damage cutting it, the drain and a trick stopping it, a new run, pause, a run started from the main menu), part of the GUT suite.
