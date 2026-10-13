# Game

The Godot 4 project lives here: scenes, scripts, data (JSON), art and audio. Everything for the game, in the same repository as the documents.

## Setup

The engine is Godot 4.6.2. The scripts below find it through `GODOT_BIN` in `.env` at the repo root. To set that up, see [Secrets and API keys](../README.md#secrets-and-api-keys) in the root README.

## Folder layout

| Folder | What goes in it |
| --- | --- |
| `scenes/` | Scenes (`.tscn`). `game/game.tscn` is the main scene (the screen flow); `drift_prototype/` is the drift prototype; `driving/` the drift marks; `level/` is the MVP map; `run/` is the run |
| `scripts/` | Game GDScript (`.gd`). `game/` holds the screen flow; `driving/` holds the car's movement, the drift prototype and its tuning panel; `level/` the map and its challenges; `run/` the run and its state |
| `data/` | Game data as JSON (see "Game data"). `level/mvp_map.json` is the MVP map's layout |
| `art/` | Sprites, tilesets and other images |
| `audio/` | Sound effects and music |
| `tests/unit/` | GUT test scripts (`test_*.gd`), in subfolders if you like |
| `tests/fixtures/` | Scenes and files that exist only for tests |
| `tools/` | Test runner, screenshot tool, audio import checker, Freesound downloader, PixelLab client, sprite rule checker, placeholder car sheet generator, final car sheet builder, effect art builders (level-up particles, drift mark) and shared shell helpers. Not game code |
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

**Palette and previews (free, no PixelLab call):** `python game/tools/reduce_palette.py reduce IN.png OUT.png [--max-colors 30]` merges a sprite's least-used colours into the nearest remaining ones until at most 30 are left (no new colours, alpha unchanged); `python game/tools/reduce_palette.py preview IN.png OUT.png [--scale 4]` enlarges it (nearest-neighbour) on a dark and a light background side by side. Tests: `game/tools/test_reduce_palette.py`.

**Boulder base removal (T-065, free):** `python game/tools/remove_boulder_base.py build` removes the stone disc under the first sample boulder (`art-archive/T-065/boulder_sample.png`), keeps the rock pixel-identical above the disc, closes its bottom with the sprite's own outline colour and writes `boulder_sample_nobase.png`, its record and three previews to `art-archive/T-065/`; `check` confirms the committed sprite matches a fresh build. Tests: `game/tools/test_remove_boulder_base.py`.

**Boulder art (T-065, free):** `python game/tools/build_boulder_art.py build` makes the game-ready boulders in `game/art/boulders/` from the two samples the board approved (see "The boulders (T-065)" below); `check` confirms the committed files match a fresh build; `--no-mirrors` leaves out the mirrored copies. Tests: `game/tools/test_build_boulder_art.py`.

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

`game/art/ground/road_tile.png` (128 x 64 pixels, 8-bit RGBA, 9 colours) and its record `road_tile.json`: the board-approved asphalt road tile (2026-10-12): dark navy-purple asphalt, light cracks, a white dashed lane line. Since T-103 the map's ground is built from it (next section).

- **Size and repeat:** a 2:1 isometric diamond of 128 x 64 art pixels, **2 x 2 units** at the car art's density (32 art pixels per unit); the game draws art at scale 0.5, so it covers 64 x 32 screen pixels. Neighbours sit at (+64, +32) pixels across the road (world x) and (-64, +32) along it (world y); the tile is cut to the exact footprint, so repeats have 0 gaps and 0 overlaps. The line runs along world y. A road 24 units wide is 12 tiles across, so a centred line needs a double line or a centre-line piece (T-103).
- **How it was made:** one PixelLab `/create-tiles-pro` call (six variations) -> tile 1 squashed to 2:1 -> `build_road_tile.py fix` (edge outline removed, line brightened) -> the board edited the line by hand. Everything else (the other five tiles, the script-fix step, the board's indexed original and every mock-up, including the approved tile's `road_mockup.png`) is in `art-archive/T-063/`; T-103 may take tiles from there to break up the repeating cracks.
- **Tool:** `game/tools/build_road_tile.py` (`process`, `fix`, `check`, `mockup`; tests in `game/tools/test_build_road_tile.py`). Check the tile: `python game/tools/build_road_tile.py check game/art/ground/road_tile.png`.

## The map's ground (T-103)

In a run (the isometric view) the map's roads and gravel centre are drawn from `game/art/ground/ground_atlas.png` (with its record `ground_atlas.json`): 87 tiles of 128 x 64 pixels, each a 2 x 2 unit isometric diamond drawn at half size (32 art pixels per unit), placed one per cell as listed in `game/data/level/mvp_ground.json` (120 x 120 cells, -1 for building cells). The flat view, the outside of the map and the buildings keep their placeholder colours.

- **Tiles:** 3 dusty gravel tiles and, for 7 asphalt bases (the approved `road_tile.png` without its line, mirrored, and 5 plain asphalt tiles), plain asphalt, the centre line in two halves (a 24-unit road's centre is a tile edge), and zebra crossings (full, and with the road's edge on either side), each along world y and mirrored for world x. The bases are mixed across the map by a fixed hash, so the cracks don't repeat regularly.
- **Where things go:** zebra crossings one tile deep, 2 units before every box where 3 or 4 roads meet; the centre line along every road, stopping 6 units before a junction box; junction boxes plain asphalt.
- **How it is made:** `python game/tools/build_ground_tiles.py` builds the atlas, its record and the layout from the approved road tile, the raw tiles of T-103's one PixelLab call (in `art-archive/T-103/raw/`) and `data/level/mvp_map.json` (read only). No new colours: every pixel comes from those tiles. Run it again after the map's layout changes.
- **Check:** `python game/tools/build_ground_tiles.py check` (Visual style's technical rules and the exact footprint, every tile); `python game/tools/build_ground_tiles.py mockup OUT.png [I0 J0 I1 J1]` draws the ground (or the cells I0..I1, J0..J1) as the game does. Tests: `game/tools/test_build_ground_tiles.py` and `game/tests/unit/test_mvp_map_ground.gd`.
- **Drawing:** `scripts/level/mvp_map.gd` (`_GroundTiles`), drawn in screen pixels under the map's `View` node, between the outside colour and the buildings. Screenshots of a run: `tests/fixtures/ground_from_menu_demo.tscn` (`GROUND_X`, `GROUND_Y`, `GROUND_HEADING_DEG`, `GROUND_ZOOM`).
- **The client** (`pixellab_client.py`) now knows `create-tiles-pro`: `/tiles-pro/{tile_id}` answers with storage URLs, which it downloads (the storage host refuses Python's default user agent) and saves one PNG and record per tile.

## The boulders (T-065)

In a run (the isometric view) every boulder on the MVP map (the pattern copies', the kaiju's landed meteor boulders and, when switched on, the meteor challenges') is drawn with the boulder art in `game/art/boulders/`. The flat view keeps the placeholder circles. Only the drawing changed: bodies, sizes and placement are as before.

- **Variants:** `boulder_a.png` (the first sample with its stone disc removed: a tall rounded rock with glowing magenta cracks) and `boulder_b.png` (the second sample: a low, boxy rock), plus `boulder_a_mirror.png` and `boulder_b_mirror.png`, the same pixels flipped left to right (free extra variants; drop them with `build_boulder_art.py build --no-mirrors`, which rewrites `boulders.json`). All are 160 x 160, 30 colours, transparent background, no semi-transparent pixels. Each has a record (`boulder_a.json`, ...) naming its archive source, the PixelLab call and the cleanup scripts behind it.
- **List:** `game/art/boulders/boulders.json` lists the variants in order, each with its texture, its opaque box (`bbox`, art pixels) and the convex outline of its opaque pixels (`hull`). Made by `game/tools/build_boulder_art.py`; do not edit by hand.
- **Which variant:** `map.boulder_variant(b)` hashes the boulder's centre (`boulder_key`, to a hundredth of a unit), so a boulder gets the same variant on every map and every run. The MVP map's 96 boulders use all four, roughly evenly (a test checks every variant is used).
- **Size and place:** `map.boulder_sprite_rect(b, variant)`: the sprite's opaque width equals the 3-unit collision circle's on-screen width (3 x 16 x sqrt 2, about 67.9 screen pixels), centred on the circle, with the bottom of its opaque pixels on the circle's front edge. That is a scale of about 0.69 for variant a (99 art pixels wide) and 0.55 for variant b (124 wide); nearest filtering (`map.boulder_sprites_root.texture_filter`), so no smoothing, but at these scales some art pixels are dropped. The sprites are `Sprite2D` children of `BoulderSprites` (after `Boulders` in `map.view_root`), drawn in screen pixels like the ground tiles; `map.boulder_sprites` lists them, each with its `variant`, `centre_units`, on-screen `outline` and `box`.
- **Depth order:** see "Draw order" under the MVP map: a boulder is drawn under the buildings that cover it and over the rest; the car is drawn under a boulder it is behind and overlaps on screen. Boulders do not fade (only buildings do).
- **Tests:** `tests/unit/test_boulder_art.gd` (one sprite per boulder, stable variants, the width and place against the collision circle, nearest filtering, the flat view, meteor boulders, the depth order with buildings and the car). Screenshots of a run started from the main menu: `bash game/tools/screenshot.sh res://tests/fixtures/boulder_art_behind.tscn screenshots/T-065_boulders_behind.png 30` (the car just behind a boulder of the pattern at the crossing 27, -54) and `..._front.tscn` (the car in front of it).

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
- `drift_marks.gd`: the drift marks (task T-117, see "Drift marks"), drawn over the ground and under the test room and the car, in the current view.
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

## Drift marks

Task T-117 (Visual style, Decisions, "Drift marks"). While the car drifts, its two rear tyres leave marks on the ground. The scene is `scenes/driving/drift_marks.tscn` (script `scripts/driving/drift_marks.gd`); the run (`run.drift_marks`) and the drift prototype (`drift_prototype.drift_marks`) each add one and call `bind(car)`.

- **When:** only while the car's own drift state is on (`car.model.is_drifting`, the same one that gives likes for drifting: W, or S, held with A or D). Never while driving straight or standing still. Each drift starts a new mark per rear tyre (`marks_started` counts them), so separate drifts leave separate marks.
- **Where:** after every car physics step, at each rear tyre's real place on the ground, from the car's position, heading and size (Drifting, Decisions: 1 unit wide, 3 long): `rear_axle_units` behind the centre and `half_track_units` to each side (`rear_tyres(position, rotation)` returns `[left, right]` in units). A point is added once a tyre has moved `min_segment_units`. Points are in flat world pixels, so the node sits under the view's projection: in the run, inside the map's drawing (`map.view_root`), right after the ground tiles and before the buildings, arrows and boulders; the car (the run's `View`) and the HUD are drawn after the map. In the drift prototype it is right after the ground grid, before the test room and the car sprite, with the view's transform (flat or isometric). Marks stay where they were laid.
- **How long:** a mark is a chain of `Line2D` pieces. A piece closes after `piece_segments` segments, or when the drift ends; the next piece starts at its last point, so the mark stays joined. Each closed piece stays fully visible for `lifetime` seconds, then fades as a whole (the node's `modulate` alpha, never per pixel: Visual style, Decisions, "See-through rule") over `fade_time` seconds and is removed. Time runs in `_process` with the default (pausable) process mode, so marks do not fade while the game is paused. A new run builds a new map, which brings new, empty marks.
- **Cap:** at most `max_segments` segments, both tyres together; past it the oldest closed pieces go first (or, if only pieces still being laid are left, their oldest points). `segment_count()` is the count now.
- **Numbers (proposals for the board's playtest):** lifetime 6 s, fade 1 s, width 0.25 units (4 flat world pixels, about one tyre), cap 800 segments, pieces of 16 segments, a point every 0.1 units or more, rear axle 0.9 units behind the centre, tyres 0.375 units to each side. At drift speed a point is laid on every physics step (50 per second per tyre), so a continuous drift keeps about 7 s x 100 = 700 segments alive: the cap is a safety net above that.
- **Look (task T-118, a proposal for the board's review):** the scene's `mark_texture` is `art/effects/drift_mark.png`, an 8 x 8 tile drawn by a script (no PixelLab, board 2026-10-13): x runs along the mark, y across it, one tile is one period of the tread (0.25 units long at `width_units` 0.25, 32 texels per unit, the car and ground art's density). A chevron of 2-texel grooves (46, 43, 64) in deep rubber (12, 10, 20), between two ragged shoulder rows (27, 24, 40) whose gaps are the texture's transparent background. 3 colours, every one darker than the asphalt and the gravel, no semi-transparent pixels, not Redgull red. The rows inside the mark are fully opaque, so the mark never breaks up at a tile join. `texture_mode` 1 (tile), `mark_color` white (no tint), and lifetime, fade, width, cap and geometry unchanged from T-117. Each `Line2D` piece starts the tread at its own start, so where two pieces join, one chevron can be a little shorter; at this size it does not show as a seam. The record, with the tread and the palette, is `art/effects/drift_mark.json`; previews over both grounds and the unused alternative (transparent grooves) are in `art-archive/T-118/`.
- **Build and check the art:** `python game/tools/build_drift_mark.py build` (writes the PNG, its record and the archive previews; byte-identical every run) and `python game/tools/build_drift_mark.py check` (transparent background, no semi-transparent pixels, about 30 colours or fewer, no Redgull red nor any red, the rows inside the mark opaque, shoulder gaps of at most 2 texels across the join, every colour darker than both grounds; exit 1 on a fail). Python tests: `game/tools/test_build_drift_mark.py` (also fails if the committed PNG, record or previews are out of date). T-117's placeholder was a 4 x 4 one-colour texture stored in the scene itself, so there is no file to archive.

**To swap the art and retune (done by T-118):** change only `scenes/driving/drift_marks.tscn`: `mark_texture` (the mark's texture, no semi-transparent pixels: the whole piece fades), `texture_mode` (1 = tile along the line, 2 = stretch), `mark_color` (a tint, keep it white for the texture's own colours, alpha 1), `width_units`, `lifetime`, `fade_time`, and if needed `max_segments`, `piece_segments`, `min_segment_units`, `rear_axle_units` and `half_track_units`. With `texture_mode` tile, one texture tile is as long as the texture's width scaled by `width_units x 16 / texture height`. Keep the root's `texture_filter` Nearest. When and where marks are laid is in the script and does not change.

**Screenshots** of a run started from the main menu, the car drifting (two marks behind the rear tyres) and driving straight (none laid): `bash game/tools/screenshot.sh res://tests/fixtures/drift_marks_demo_drift.tscn screenshots/drift_marks_drifting.png 150` and `bash game/tools/screenshot.sh res://tests/fixtures/drift_marks_demo_straight.tscn screenshots/drift_marks_straight.png 90`. The car drifting on the asphalt and on the gravel (T-118; the fixture's `start_units` puts the car on the road at (54, 0)): `bash game/tools/screenshot.sh res://tests/fixtures/drift_marks_demo_asphalt.tscn screenshots/drift_marks_asphalt.png 150` and `... res://tests/fixtures/drift_marks_demo_gravel.tscn screenshots/drift_marks_gravel.png 150`.

**Tests:** `tests/unit/test_drift_marks.gd`, part of the GUT suite: marks while drifting and none while driving straight or standing still, one per rear tyre on the tyre's place, a new mark per drift, the lifetime, the fade as a whole and the removal, the cap during a 30-second drift, pieces staying joined, no aging while paused, the drawing order in the run and the prototype (and the view switch), the texture (nearest, no semi-transparent pixels, dark, not Redgull red), the settings in the scene, a new run, and a run started from the main menu. `tests/unit/test_drift_marks_art.gd` (T-118): the scene uses `art/effects/drift_mark.png` tiled and repeating, the PNG matches its record, a transparent background only in the shoulder rows, dark rubber with more than one colour, and a run's marks using it.

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
- **Typed readers:** for each data file, a small class next to the loader wraps it so game code does not index dictionaries. `scripts/data/run_data.gd` (`RunData`) gives `xp_needed(level)`, `challenge_xp(level)`, `drift_xp_per_second()`, `max_level()`, `carries_over()`, `starting_health()`, and the likes drain (`likes_drain` in `run.json`, task T-114): `likes_drain_enabled()`, `likes_drain_bar_share_per_second()` (share of the current level's bar drained per second, proposed 0.02: a full bar empties in 50 s, 2 XP/s at level 1), `likes_drain_extra_wait_seconds()` (wait after the combo has fully drained, 0) and `likes_drain_xp_per_second(level)` (the share times that level's `xp_needed`, 0 when off or at max level). `scripts/data/combo_data.gd` (`ComboData`, from `combo.json`) gives `trick_add(trick)`, `after_trick()`, `after_collision()`, `after_idle()` and `spawn_multiplier()`.
- **Garage:** `garage.json` holds the 3 upgrades (`acceleration`, `car_health`, `damage_bonus`), 10 levels each, with a `price` and a `value` per level and a `base_value` for level 0. `scripts/data/garage_data.gd` (`GarageData`) gives `max_level()`, `price(upgrade, level)` and `value(upgrade, level)`. Tests: `tests/unit/test_garage_data.gd`.
- **Weapons (T-040):** `data/weapons.json` holds the starting gun and the exhaust flamethrower: base values and, for each, the 7 upgrade tiers (tiers 2 to 8) as `effect` plus `value`. `scripts/data/weapon_data.gd` (`WeaponData`) adds the tiers up: `gun_at(tier)` and `flame_at(tier)` return the weapon's values at that tier (tier 1 = just got it), and `tiers(weapon)` the raw list. Tests: `tests/unit/test_weapon_data.gd`, which compares everything with the Unity weapons report.
- **Enemies (T-039):** `data/enemies.json` holds the minion (`health`, `move_speed`, `contact_damage`, `contact_damage_interval`, `knockback`), `spawning` (how many minions are kept around: `minions_at_start`, growing in a straight line to `minions_at_boss_time` at `growth_until_seconds` = the kaiju's arrival, then held; one spawns every `spawn_interval_seconds` while fewer are around, `spawn_margin_units` beyond the visible screen's edge), `coins` (`drop_chance`, `coins_per_drop`), the `kaiju` (same keys as the minion), `kaiju_coins` (T-119: the coins the kaiju drops when defeated, `drop_chance` 1 = always and `coins_per_drop`; its death ends the run, so they are added to the run's coins as it ends, without a pickup) and its `meteor_attack` (`first_attack_after_seconds`, `seconds_between_attacks`, `windup_seconds`, `meteors_per_attack`, `warning_seconds` (decided, 2 s), `land_within_units_of_car`, `impact_radius_units`, `impact_damage`, `knockback`). Units as everywhere: 1 unit = the car's width, speeds and knockback in units per second, damage in the car's health points. `scripts/data/enemy_data.gd` (`EnemyData`) gives each section as a Dictionary of floats (`minion()`, `spawning()`, `coins()`, `kaiju()`, `meteor_attack()`), `kaiju_coins()`, `minions_wanted(run_seconds, spawn_multiplier = 1.0)` (pass `ComboData.spawn_multiplier(combo)` for the combo's extra spawning), `expected_coins_per_kill()`, `kaiju_coins_on_defeat()` (whole coins the defeated kaiju adds) and `meteor_attack_times(fight_seconds)`. Enemy stats never change over a run; only `minions_wanted` grows. Tests: `tests/unit/test_enemy_data.gd`, including the kaiju's time to kill with the MVP weapons and its coins when defeated.
- **Tests:** `tests/unit/test_run_data.gd`, `tests/unit/test_combo_data.gd`, `tests/unit/test_garage_data.gd`, `tests/unit/test_weapon_data.gd`, `tests/unit/test_enemy_data.gd`. New data files get a test that loads them through the loader.

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

- `map_building.gd`: one building, its placeholder box and its see-through fade (task T-034, "See-through buildings" below).
- `mvp_map.gd`: builds the map from the layout data. Same units and physics as the drift car: 16 pixels per unit, the map's centre on the node's origin. The `Physics` child holds static bodies on collision layer 1 (the buildings and the map's edge in `Walls`, and one body per pattern copy for its boulders), never drawn. The `View` child draws the map, flat or isometric (`set_view("flat" | "iso")`), like the drift prototype.
- To check the challenges (when switched on), set the map's `car` to the car node (its position in the same flat world pixels, nose along +x at rotation 0), or call `update_car(centre_in_units, rotation)` once per physics step. When a challenge is completed, its arrow is hidden, its boulders stay, and the map emits `challenge_completed(challenge_id)` once. `challenge_ids()`, `get_challenge(id)` and `is_challenge_completed(id)` give the challenges and their positions.
- `challenge_tracker.gd`: the completion rule for one challenge (no nodes, so tests run it directly). Unused while challenges are off.
- `challenge_arrow.gd`: the placeholder arrow (a blue band as wide as the corridor, a white start dot and an arrowhead).
- `map_overview.gd`: the overview scenes, with a camera that fits the whole map.

**See-through buildings** (task T-034; the rule: Visual style, Decisions, and `docs/level-design.md`, Content, "See-through buildings"; the research: `docs/visual-style/see-through-buildings.md`, T-020).

- **The buildings:** each building in the layout data is its own node, `scripts/level/map_building.gd`, named `Building01` ... under the map's `Buildings` node (`map.buildings_draw`, which still sits after the ground tiles and drift marks and before the boulders in `map.view_root`; it also draws the map's outline). `map.buildings` lists them in the layout data's order. Each has its `footprint` (a `Rect2` in units) and `height_units`. In the isometric view the placeholder is a box `BUILDING_HEIGHT_UNITS` (15) tall, drawn in flat world pixels under the view's projection (one unit up on screen is the world offset (-1, -1) unit); in the flat view it is the flat rectangle as before and never covers anything.
- **Draw order:** buildings get a `z_index` from their front corner (`depth_key()`, x + y of the footprint's far corner): `BUILDING_Z_BASE` (2) plus `BUILDING_Z_STEP` (3, task T-065) per place in that order, so the nearest is drawn last. The ground, ground tiles, drift marks, arrows and the flat view's placeholder boulders stay at z 0, under every building. Each boulder sprite (T-065) gets a z once, when it is placed: one under the lowest building that covers it (the boulder's centre is behind the building and its outline overlaps the building's on screen), or `top_z_index()`. `map.car_z_index(centre_units, rotation)` gives the car's place: one under the lowest building that covers it, or `top_z_index()` (over every building) when none does; then one under any boulder that covers it (the car's centre has a smaller x + y than the boulder's and the car's screen shape overlaps the boulder's outline). So each gap between two buildings has two levels: the boulders, and the car in front of them (the car comes later in the tree, so at the same z it is drawn over), and below that the car behind a boulder. The run puts it on its `View` node in `sync_view()`, so the car sprite, the level-up burst and the trick popups (z 100 inside `View`) move together; keep every building's z under 100 so the popups stay on top.
- **When a building fades:** `covers(car_centre_units, car_shape)`: the car is behind it (`is_behind()`: its centre is not in front of the +x or +y wall, `x < footprint.end.x and y < footprint.end.y`) and the drawn car's screen shape overlaps the building's on-screen outline (`silhouette()`, six points in the map's screen pixels; `Geometry2D.intersect_polygons`). The car's shape is `map.car_screen_shape(centre_units, rotation)`: its 1 by 3 unit rectangle on the ground and the same rectangle `CAR_HEIGHT_UNITS` (1) higher, as one convex outline.
- **The fade:** every frame (`_process`) the map calls `update_see_through(car.position / 16, car.rotation, delta)` when its `car` is set (the run sets it). A covering building moves its `modulate.a` towards `SEE_THROUGH_ALPHA` (0.15), every other one towards 1, both at a speed that takes `SEE_THROUGH_FADE_TIME` (0.15 s) for the whole way. Nothing else is touched: no tint, no shader, no pixel of any texture. `covering_buildings()` lists the buildings covering the car now; `alpha()` is a building's alpha. The two values are the constants at the top of `mvp_map.gd`, the one place to change them.
- **For the final building art (T-064):** add the art under each building node (for example a child `Sprite2D` with `texture_filter` nearest, placed so the building's footprint lines up with its block): it fades with the node's `modulate`, so the sprite keeps no semi-transparent pixels. Stop the placeholder box from drawing: set the building's `draw_placeholder` to false. Set `height_units` to how tall the art stands, or, when the art's outline is not a box, set `custom_silhouette` to its on-screen outline in the map's screen pixels (isometric view, the map node's coordinates), so the fade starts exactly when the art covers the car. Several buildings per block also work: give each its own footprint; the draw order and the fade follow. Keep the `z_index` scheme (and under 100).
- **Under a building:** the ground art has no tiles on the blocks (T-103), so a faded building shows the dark outside colour where it stands.
- **Screenshots** of a run started from the main menu, the car behind the block south of the gravel centre (faded) and on the road in front of it (opaque): `bash game/tools/screenshot.sh res://tests/fixtures/see_through_map_behind.tscn screenshots/see_through_behind.png 60` and `... res://tests/fixtures/see_through_map_open.tscn screenshots/see_through_open.png 60` (fixture script `tests/fixtures/see_through_map_demo.gd`, `car_at` in units). Copies are in `docs/level-design/`.
- **Tests:** `tests/unit/test_see_through_map.gd`: the values from Visual style, the covering building fading to 15% while a building not covering the car stays opaque, the building fully opaque again once the car is in the open or in front, the 0.15 s fade both ways, "further back" not being enough, only `modulate.a` changing, the draw order (car under covering buildings only, nearer buildings later, everything over the ground and drift marks), the flat view never fading, the boxes' height, the map fading on its own with `car` set, and a run started from the main menu.

The T-020 research demo (`scenes/see_through_demo/`, `scripts/level/see_through_building.gd`) stays as it was; the map does not use it.

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

**The HUD** (task T-090): `scenes/hud/hud.tscn` with `scripts/hud/hud.gd` (`Hud`, a CanvasLayer) is added by the run scene and bound to the run's state (`run.hud`). It shows the timer (`hud.timer_label`, M:SS from `time_left_text()`), and since T-049 the car's health bar (`health_bar`, `health_label`), the likes bar (`likes_bar`, `likes_label`, `heart`) with the level (`level_label`) and the coins (`coins_label`, `coins_value_label`), following the run state's `health_changed`, `xp_changed`, `coins_changed` and (T-083) `combo_changed`: the combo counter `combo_label` ("Combo x{multiplier}", `Hud.combo_text()`). Layout since T-113: the top-left `left_column` (a plain Control, `_layout_left()`) holds "Car Health" with the upright health bar directly under it (`fill_mode` bottom to top, `Hud.HEALTH_BAR_SIZE` 24 x 160), both at the same left edge. `bottom_area` (a full-screen Control that ignores the mouse, `_layout_bottom()`, re-run when the window or a text's size changes) holds the horizontal likes bar (fill left to right, `LIKES_BAR_WIDTH` half the screen wide, `LIKES_BAR_HEIGHT` 16, centred, `MARGIN` 16 above the bottom edge); directly above it one row: `likes_row` (heart and "Likes") from the bar's left end and `level_label` ending at its right end, given the same top and height so both texts share a baseline; and the combo counter centred above that row. Since T-116 the combo counter is hidden at "no combo": `Hud.show_combo(multiplier)` is true only above combo.json's `start_multiplier` (read through `ComboData`, compared at the two decimals the counter shows), so it starts hidden, shows after a trick and hides again once the combo drains back; every element keeps its own fixed place, so hiding it moves nothing. The texts are T-048's (`Hud.TEXT_*`). It appears in every run, also one started from the main menu. A screenshot fixture of it is `tests/fixtures/hud_from_menu_demo.tscn`. What it shows: `docs/hud-and-menus.md`, Content. Tests: `tests/unit/hud/test_hud_timer.gd`, `test_hud_values.gd`, `test_hud_combo.gd` (the counter and the popup amounts), `test_hud_combo_hidden.gd` (T-116: hidden at no combo, shown after a trick, hidden again after the drain and in a new run, nothing else moving) and `test_hud_layout.gd` (T-113: health bar upright under "Car Health", likes bar centred at the bottom with its row and the combo above it, same font size per group, the layout following a window resize, no overlaps at 1152x648, 1280x720, 1920x1080 and 1024x576, clear of the screen's middle and the pause strip's content; headless the root viewport is 64x64, so the test lays the HUD out in a window-sized SubViewport). Screenshot of the HUD in a run from the main menu: `bash game/tools/screenshot.sh res://tests/fixtures/hud_from_menu_demo.tscn screenshots/hud.png 30` (with a combo, so the counter shows); the same with no combo, the counter hidden (T-116): `bash game/tools/screenshot.sh res://tests/fixtures/hud_no_combo_from_menu_demo.tscn screenshots/hud_no_combo.png 30`; screenshot of the counter and a popup per trick in a run from the main menu: `bash game/tools/screenshot.sh res://tests/fixtures/combo_demo.tscn screenshots/combo.png 30`; part of the GUT suite.

**The scene** (`scripts/run/run.gd`, root node `Run`):

- Children: `Map` (the MVP map scene, drawn in the isometric view, with the drift marks inside its drawing, see "Drift marks"), `PhysicsWorld` (the `Car`, never drawn, in the same flat world pixels as the map), `View` (the car's sprite and the `Camera`) and `RunState` (the state, below).
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
| `xp_changed(xp: float, xp_needed: float, level: int)` | When XP or the level changes (gains, level-ups, every frame the likes drain takes XP away), and on start. For the HUD's likes bar (T-049) |
| `score(amount: float, challenge_id: String)` | When a challenge is completed, with the XP (likes) it gave. For the challenge popup (T-092) |
| `level_up(new_level: int)` | Once per level reached, switch on or off |
| `level_up_choice_started(new_level: int)` | Switch on: the run is now paused for that level's choice (T-052 opens its screen here) |
| `level_up_choice_made(new_level: int)` | Switch on: `choice_made()` closed that level's choice |

A new run (`start_run()`) resets XP to 0 and the level to 1, forgets the drift in progress and any waiting choice (unpausing if it was waiting). Nothing is added after the run ends.

**The likes drain** (task T-115; the rule is Game loop architecture, Decisions, "Likes drain", the numbers are `likes_drain` in `data/run.json` through `RunData`, task T-114). Once the combo is back at "no combo" (`combo` at `start_multiplier`, after the combo's own wait and drain), and after `likes_drain_extra_wait_seconds` (0 for now), `xp` goes down by `RunData.likes_drain_xp_per_second(level)` per second, stopping at 0: the level never goes down. Any trick raises the combo, which stops the drain until the combo has drained again. It runs inside `advance()` (`_drain_likes()`), so it stops while the tree is paused (pause screen, level-up screen) and after the run ends; it also skips while a weapon choice is waiting. At the top level there is nothing to drain: XP stays at 0 there and the HUD shows the bar full. Each frame it takes XP away it sends `xp_changed`, so the HUD's likes bar empties (the bar rounds to whole likes, its step being 1, so it moves one like at a time).

| Function or value | Is |
| --- | --- |
| `has_no_combo()` | True when the combo is at "no combo" |
| `is_likes_draining()` | True while the drain is taking XP away now (no combo, the extra wait passed, XP above 0, not the top level, no choice waiting, the run going) |
| `likes_drain_idle` | Seconds the combo has been at "no combo"; a trick or a new run sets it to 0 |

A screenshot fixture, `tests/fixtures/likes_drain_demo.tscn`, starts a run from the main menu with level 2 and a fifth of its bar, then does nothing, printing the time, XP and level every half second: `bash game/tools/screenshot.sh res://tests/fixtures/likes_drain_demo.tscn screenshots/likes_drain_1.png 600` (the bar emptying) and `... screenshots/likes_drain_2.png 3500` (empty, still level 2). The frame counts depend on the screen's refresh rate; the printed lines say how far in each shot is.

**The level-up effect** (task T-112; Visual style, Decisions, "Level-up effect"): at every level-up the car gives off one burst of pixel particles. The run scene connects the state's `level_up` signal to its burst, `run.level_up_burst`, a `CPUParticles2D` from `scenes/run/level_up_burst.tscn` (script `scripts/run/level_up_burst.gd`: `play()` starts the burst, `is_playing()`). It sits under `View`, drawn over the car, and `sync_view()` keeps it on the drawn car; `local_coords` is on, so the particles move with the car while they play. Several level-ups in the same moment (one gain giving two levels) restart the same burst, so they show as one burst. Its `process_mode` is Always, so it keeps playing while the run is paused for the level-up screen (T-052).

- **Particle art (task T-074, a proposal for the board's review):** `art/effects/level_up_particles.png`, one row of six 11 x 11 frames drawn by a script (no PixelLab, board 2026-10-13): a cyan and a pink four-point star, a pink and a cyan diamond, a violet pixel cross and a small cyan spark, each with a white-hot core and stepped darker halo pixels (glow in the pixels), 13 colours in all, no red. Its record, with the palette, is `art/effects/level_up_particles.json`. Built and checked by `python game/tools/build_level_up_particles.py build` (byte-identical every run) and `python game/tools/build_level_up_particles.py check` (every frame: transparent background, no semi-transparent pixels, about 30 colours or fewer; the whole sheet: no Redgull red nor any red; exit 1 on a fail). Python tests: `game/tools/test_build_level_up_particles.py` (also fails if the committed PNG or record is out of date).
- **How the scene uses it:** a `CanvasItemMaterial` with particles animation (`particles_anim_h_frames` 6) reads the sheet as a flipbook; `anim_offset` 0 to 1 with `anim_speed` 0 gives every particle one random shape for its whole life. `scale_amount` 0.5 draws the art at the car's density (32 art pixels per unit at 16 world pixels per unit); particles are never rotated. Tuning: `amount` 40, `lifetime` 0.8 s with `lifetime_randomness` 0.35, `emission_sphere_radius` 24, `spread` 180, `initial_velocity` 180 to 320, `damping` 180 to 240. They do not fade: `scale_amount_curve` keeps full size until 65% of the life, steps to half size, and pops out at 86%. The placeholder (a 4 x 4 pale cyan square, T-112) is gone.
- **To swap the art and retune it (T-074):** change only `scenes/run/level_up_burst.tscn` (and redraw the sheet with the script above): `texture` (the particle sprite; keep `color` white so the sprite shows its own colours), `amount`, `lifetime`, `initial_velocity_min/max`, `damping_min/max`, `spread`, `emission_sphere_radius`, `scale_amount_curve` and the flipbook material's frame count. Keep `texture_filter` Nearest, `one_shot`, `explosiveness` 1, `process_mode` Always and every colour's alpha at 1; the tests below check them. When and how it plays is in `scripts/run/run.gd` and does not change.
- **Screenshot** of the burst at a level-up in a run from the main menu: `bash game/tools/screenshot.sh res://tests/fixtures/level_up_burst_demo.tscn screenshots/level_up_burst.png 40`.
- **Tests:** `tests/unit/run/test_level_up_burst.gd` (part of the GUT suite): not playing before, started by the `level_up` signal and by a real level-up, on the car and following it, two level-ups at once, one burst that ends, still playing while paused, the settings in the scene, nearest-neighbour, no alpha fade, and particle art that is not Redgull red. `tests/unit/run/test_level_up_particles_art.gd` (T-074): the scene uses the sheet, the sheet matches its record, one random shape per particle, the car's art density, no rotation, the stepped shrink with no fade.

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

**Tests:** `tests/unit/run/test_run_state.gd` (the clock, boss time, health, coins, win and loss, pause, a second run), `tests/unit/run/test_run_scene.gd` (the map and car loaded, the start position, the camera following the car, a second run resetting the map and car) and `tests/unit/run/test_run_likes.gd` (challenge and meteor challenge XP, drift seconds, level-ups and leftovers, the pause switch off and on, two level-ups at once, the top level, a new run resetting XP) and `tests/unit/run/test_run_combo.gd` (tricks raising the multiplier, the cap, likes multiplied, collisions and damage cutting it, the drain and a trick stopping it, a new run, pause, a run started from the main menu) and `tests/unit/run/test_run_likes_drain.gd` (T-115: no drain with a combo, the drain at T-114's speed once it is gone, a trick stopping it, never below the level's start even over a long drain, no drain while paused, while a choice waits, after the run ends or at the top level, the extra wait, the switch, `xp_changed` firing and the HUD's likes bar emptying in a run), part of the GUT suite.
