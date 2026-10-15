# Game

The Godot 4 project lives here: scenes, scripts, data (JSON), art and audio. Everything for the game, in the same repository as the documents.

## Setup

The engine is Godot 4.6.2. The scripts below find it through `GODOT_BIN` in `.env` at the repo root. To set that up, see [Secrets and API keys](../README.md#secrets-and-api-keys) in the root README.

## Folder layout

| Folder | What goes in it |
| --- | --- |
| `scenes/` | Scenes (`.tscn`). `game/game.tscn` is the main scene (the screen flow); `drift_prototype/` is the drift prototype; `driving/` the drift marks and drift smoke; `level/` is the MVP map; `run/` is the run |
| `scripts/` | Game GDScript (`.gd`). `game/` holds the screen flow; `driving/` holds the car's movement, the drift prototype and its tuning panel; `level/` the map and its challenges; `run/` the run and its state; `enemies/` the minions and their coins (see "Minions") and the kaiju (see "The kaiju"); `weapons/` the car's weapons (see "Weapons") |
| `data/` | Game data as JSON (see "Game data"). `level/mvp_map.json` is the MVP map's layout |
| `art/` | Sprites, tilesets and other images |
| `audio/` | Sound effects and music |
| `tests/unit/` | GUT test scripts (`test_*.gd`), in subfolders if you like |
| `tests/fixtures/` | Scenes and files that exist only for tests |
| `tools/` | Test runner, screenshot tool, audio import checker, Freesound downloader, PixelLab client, sprite rule checker, placeholder car sheet generator, final car sheet builder, effect art builders (level-up particles, drift mark, drift smoke) and shared shell helpers. Not game code |
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

### Time limit (T-137)

A run that goes past **300 seconds** is stopped by the runner itself (only the Godot process it started, and its children), which prints `TIME LIMIT: the test run went past 300 seconds and was stopped` and exits with code **124**. A normal full run takes about 90 to 110 seconds (two at once, a little more), so 300 is comfortably above it. To change it, set `GUT_TIME_LIMIT` (seconds) for one run, for example `GUT_TIME_LIMIT=600 bash game/tools/run_tests.sh`. To see the limit work, run `bash game/tools/check_time_limit.sh` (default 10 seconds): it runs GUT on `game/tools/hang_fixture/test_hang.gd`, a test that hangs forever on purpose and lives outside `tests/` so the normal suite never runs it, then checks the exit code, the message and that no Godot process is left behind.

### Per-run test files (T-137)

Godot's user folder (`AppData/Roaming/Godot/app_userdata/Solid Carbide/`) is shared by every task folder, so tests never write fixed names there. A test that needs a file under `user://` gets its path from `RunPaths.file("name")` (`tests/helpers/run_paths.gd`), which puts it in `user://test_runs/<process id>/`. Two runs at once have different process ids, so they never touch each other's files. The folder is removed when the run ends (`tests/helpers/post_run.gd`, set as `post_run_script` in `.gutconfig.json`); a run that is stopped by the time limit may leave its folder behind, and it is safe to delete. New tests that write under `user://` must use `RunPaths`.

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

- Only Godot-importable formats (wav, ogg, mp3) are picked, and originals over 5 MB are skipped (`--max-bytes`, 0 = no limit). The downloader accepts only CC0 and CC BY sounds: the search is filtered, and each result is checked again before saving, so a disallowed sound is skipped (one line is printed) and never written. The rule is in [`docs/unfiled-game-details.md`](../docs/unfiled-game-details.md) ("Sound licenses"); the allowed list is `ALLOWED_LICENSES` in the script.
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
- `drift_smoke.gd`: the drift smoke (task T-121, see "Drift smoke"), drawn over the test room and under the car, in the current view.
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
| 3 | 4 | `enemies` | Minions, the kaiju, meteors | Layer 3. Their mask must not include layer 2, so they and the car never push each other. To touch or damage the car, use an `Area2D` whose mask includes layer 2 (the minions measure their overlap with the car's body themselves instead, see "Minions") |
| 4 | 8 | `pickups` | Coins and other pickups | `Area2D` on layer 4 with mask 2, to notice the car driving over it |

Walls and boulders share layer 1 because the MVP map builds them that way and the car treats them the same. To tell them apart (for example in the combo), use the body `hit_obstacle` reports: on the MVP map, `map.walls` is the buildings and the edge, `map.boulder_bodies` the pattern copies' boulders and `map.meteor_boulder_bodies` the boulders meteors left. The starting gun's bullets have no physics body and no layer: they find enemies through the group `enemies` (see "Weapons"). A weapon that does need a body or an `Area2D` adds a layer (the next free number) to this table.

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

## Drift smoke

Task T-121 (Visual style, Decisions, "Drift smoke"). While the car drifts, puffs of smoke come off its two rear tyres. The scene is `scenes/driving/drift_smoke.tscn` (script `scripts/driving/drift_smoke.gd`); the run (`run.drift_smoke`) and the drift prototype (`drift_prototype.drift_smoke`) each add one and call `bind(car, drift_marks)`.

- **When:** only while the car's own drift state is on (`car.model.is_drifting`, the same one the drift marks and the likes use). Never while driving straight or standing still (steering on the spot included). Each drift starts with one puff from each tyre at once, then `puffs_per_second` from each tyre (fractions carry over between physics steps). `puffs_made` counts every puff so far.
- **Where:** after every car physics step, at each rear tyre's place, taken from the drift marks' `rear_tyres()` (the node given to `bind()`), so smoke and marks start at the same spot; plus a random offset of up to `spawn_jitter_units`. A puff keeps its spot in flat world pixels and does not move with the car; it is drawn at `view_transform` x its spot, and drifts on screen by itself: up at `rise_speed` plus up to `spread_speed` outward in a random direction (drawn pixels per second). Puffs are drawn upright in screen pixels, not skewed by the isometric projection.
- **Life:** each puff lives `lifetime` seconds, varied by up to `lifetime_randomness` either way. Its size follows `size_curve` over its life (x 0 = born, 1 = end; y times `puff_scale`, the texture's scale): it grows, then shrinks, and pops out when its life ends. No puff fades: `puff_color` and the node's modulate keep alpha 1, and the texture has only opaque or fully clear pixels (Visual style, Decisions, "See-through rule"). Time runs in `_process` with the default (pausable) process mode, so puffs stand still on the pause screen.
- **Cap:** at most `max_puffs` puffs at once, both tyres together; a new puff past the cap replaces the oldest. All puffs are drawn by the one node (`_draw`), no node per puff. `puff_count()` is the count now, `puffs()` lists them (spot, drawn place, size, age, life, tyre).
- **Depth order:** in the run the node is a child of the run's `View`, before the car sprite: the smoke is drawn with the car, under the car sprite, and shares the car's place in the buildings' depth order (T-034, `View.z_index` from `map.car_z_index()`). So it is over the map's ground, drift marks and boulders (all at z 0 in the map, drawn before `View`, whose z is always 1 or more), under the HUD (a CanvasLayer), and a building that covers the car covers the smoke too. Puffs left far behind keep the car's current depth, so for their short life they can show over or under a building they are not next to. In the drift prototype it is after the ground, the marks and the test room and before the car sprite, and `set_view()` sets its `view_transform` (flat or isometric). A new run empties it (`clear()`) and binds it to the new car and map's marks.
- **Numbers (proposals for the board's playtest):** 50 puffs per second per tyre, lifetime 0.13 s +-25% (T-073 round 2, the board's playtest: the trail must span about 20 degrees of the circle in a full-circle drift; measured 20.2 degrees, and 138 degrees with the old 0.7 s and 30 per second; the arc is the live puffs of one tyre, oldest to newest, seen from the circle's centre, pinned by a test), cap 64 puffs, size curve 0.5 at birth, 1.3 at 40% of the life, 0.8 at the end (then pops; retuned in T-073), `puff_scale` 0.5 (the car art's density: the 24-texel puff is 12 drawn pixels at size 1, so a full-grown puff, 15.6 drawn pixels, is still about one car width, as with the placeholder), rise 10 and spread up to 8 drawn pixels per second, jitter 0.15 units. A steady drift keeps about 2 x 50 x 0.13 = 13 puffs, so the cap never trims. The whole puff does not fade as an object either (allowed by the See-through rule, but the pop-out keeps the pixel look crisp, as the level-up burst does); if the board wants a fade, that is a small code change.
- **Look (T-073):** the puff is one 24 x 24 sprite, `art/effects/drift_smoke_puff.png` (record `drift_smoke_puff.json`), drawn by `tools/build_drift_smoke.py` (no PixelLab): a lumpy cloud lit from the top left in five cool grey-violet tones (a faint cyan-tinted highlight, light, mid, dark, a deep violet rim), bands blended with a checkerboard dither and the outermost ring chequered away for a ragged, soft edge; no semi-transparent pixels, transparent background, no red. One sprite is the whole animation: the size curve grows it, then shrinks it. The root `texture_filter` stays Nearest. The old placeholder (a flat 16 x 16 round puff stored in the scene) is gone.

**Smoke sprite script:** `python game/tools/build_drift_smoke.py build` redraws the PNG, its record and the preview (`art-archive/T-073/drift_smoke_preview.png`, over asphalt and gravel at four sizes); `... check` runs the rules (transparent background, no semi-transparent pixels, about 30 colours or fewer, no Redgull red, cool colours, body at least 40 luma lighter than asphalt and gravel) on the committed PNG and exits 1 on a fail. Tests: `tools/test_build_drift_smoke.py` (Python tool tests).

**To swap the art or retune again:** change only `scenes/driving/drift_smoke.tscn`: `puff_texture` (opaque or fully clear pixels only), `puff_color` (a tint; white for the texture's own colours, alpha 1), `puff_scale`, `size_curve`, `lifetime`, `lifetime_randomness`, `puffs_per_second`, `max_puffs`, `rise_speed`, `spread_speed` and `spawn_jitter_units`. Keep the root's `texture_filter` Nearest. When and where puffs are made, and where the node sits in the drawing, are in the scripts and do not change. (`rear_axle_units` and `half_track_units` are only a fallback for when no drift marks are given; the run and the prototype use the marks' values.)

**Screenshots** of a run started from the main menu, the car drifting (smoke behind the rear tyres) and driving straight (none): `bash game/tools/screenshot.sh res://tests/fixtures/drift_smoke_demo_drift.tscn screenshots/drift_smoke_drifting.png 150` and `bash game/tools/screenshot.sh res://tests/fixtures/drift_smoke_demo_straight.tscn screenshots/drift_smoke_straight.png 90` (fixture `tests/fixtures/drift_smoke_demo.gd`). The car starts on the gravel; `drift_smoke_demo_asphalt.tscn` starts it on the asphalt road (`start_units` (54, 0)).

**Tests:** `tests/unit/test_drift_smoke.gd`, part of the GUT suite: smoke from both rear tyres on the marks' tyre places while drifting, none while driving straight or standing still, none after the drift ends; puffs staying where they were left while the car drives away, growing then shrinking and popping out within their lifetime, every puff gone once the longest life has passed, a 30-second drift never over the cap (and reaching and holding it with time stopped); the trail in a steady full-circle drift (W + D) spanning about 20 degrees (+-5); no aging while paused; the depth order in the run (in the car's drawing under the car sprite, over the map, under the HUD, under a building covering the car and over it in the open) and in the prototype (and the view switch); the puff art (nearest, no semi-transparent pixels, cool grey-violet, not Redgull red, no fading tint); the settings in the scene; a new run; a run started from the main menu.

## Trick popups

Task T-091 (UI Agent). When the car's `trick` signal fires, the trick's name pops out above the car, rises and fades (text from T-082, wording in `docs/hud-and-menus.md`, "Trick popups").

- `scripts/hud/trick_popups.gd` (`TrickPopups`): a node in the world view (next to the car sprite) in both the run (`run.trick_popups`) and the drift prototype (`prototype.trick_popups`). `bind(car, car_position_callable)` listens to a car's `trick`; the run binds again each time it builds a new car. `show_popup(text, drawn_position, font_size)` shows any text. `bind_score(run_state, car_position_callable)` (task T-092) shows the challenge popup, "Trending! +{likes} Likes" (`SCORE_TEXT`), for the run state's `score` signal; the run binds it once. `bind_combo(run_state, car_position_callable)` (task T-083) shows the trick popups from the run state's `combo_trick` signal, with the amount added (`trick_text(trick_id, added)`, e.g. "FULL 360! +0.25", the name only at the cap); once bound, the car's own `trick` signal no longer shows a popup, so the run does not show two. The drift prototype binds only the car and shows names only. `popups()` lists the popups showing. Sizes are `SIZE_NORMAL` and `SIZE_SMALL` (extended drift): they pick the normal or the small baked popup (`PIXEL_SCALE` 0.5 drawn px per popup pixel since T-125 round 3 (0.8 before round 2), for both sizes; drawn with nearest filtering).
- **Popups follow the car (task T-125):** `show_popup(text, at, font_size, follow)` takes an optional Callable returning where the car is drawn (`car_sprite.position`); `bind`, `bind_score` and `bind_combo` pass theirs, so every popup follows the car for its whole life. A `PopupText` keeps `anchor` (the car's drawn position, updated from `follow`), `stack` (extra upward offset) and `rise()`; `offset()` is its offset from the car (`START_OFFSET` plus stack minus rise) and `place()` sets `position = anchor_now() + offset()`. The game calls `place()` in `_physics_process`, like the car sprite and camera, so physics interpolation smooths it the same way (no shaking); `_process` only advances the age, scale and fade. `advance(dt)` (tests) also places. Without `follow` a popup stays where it was shown. Stacking: `show_popup` calls `_free_stack()`, which moves a new popup up by `STACK_STEP` (4 px) until its rectangle, grown by `STACK_GAP` (4 px), touches no popup showing; older popups keep their place. **Screen-height limit (T-125, round 2):** `top_limit()` returns the highest a popup's top edge may be, as a negative offset from the car in drawn pixels: `MAX_REACH` (0.25) of the viewport height divided by the screen pixels per drawn pixel (the camera's zoom times the view's own scale), so it is measured in screen space and holds at any window size and zoom; the camera keeps the car at the screen's centre, so a quarter of the height is half way from the car to the top. It is 0 (no limit) when the viewport has no Camera2D. `_free_stack()` checks the popup at the end of its whole rise (the highest it gets); when the stack would go higher, the oldest popup showing is removed to make room, repeated until the newcomer fits. If even an unstacked popup would end above the limit (a very close zoom), `place()` keeps it down at the limit. **Three at most, eased rise (T-125, round 3):** `MAX_POPUPS` (3): `show_popup` removes the oldest popup while three show, so a fourth makes room. The sizes are chosen so three stack under the limit at the default zoom (14.4, window 1152x648: a camera zoom of 1.40625 and a limit of 115.2 drawn px above the car): `PIXEL_SCALE` 0.5, `START_OFFSET` (0, -30), `RISE` 20. `PopupText.rise()` is a cubic ease-out, `RISE * (1 - (1 - t)^3)` over the same `LIFETIME`: fast at the start, slow where the popup fades. Screenshot fixture: `popups_follow_demo.tscn` (fast drift, a 360 at frame 10, a LONG DRIFT! every 12 frames): `bash game/tools/screenshot.sh res://tests/fixtures/popups_follow_demo.tscn screenshots/popups_follow_r3_a.png 26`, and again with 31 frames. Tests: `tests/unit/test_trick_popups_follow.gd`.
- **Always above the buildings (task T-132):** `show_popup` sets each `PopupText` to `z_as_relative = false` and `z_index = POPUP_Z` (`RenderingServer.CANVAS_ITEM_Z_MAX`, 4096, the top of Godot's range). The popups sit under `run.view_root`, whose z is the car's depth (`map.car_z_index()`, under any building covering the car), so a relative z (it was 100 before) could be under a building slot (up to 146 and growing); an absolute z at the engine's maximum does not read the map's numbers and cannot be passed when the map's top z grows. The HUD, pause and level-up screens are CanvasLayers (layers 10 and 20), which draw over the whole world canvas whatever the z inside it. Tests: `tests/unit/test_popups_above_buildings.gd` (over `map.top_z_index()` and every slot, sign, boulder and the car; still above after the map's slots and the view are raised by 2000; the challenge popup; the HUD layers over the world; the drift prototype). Screenshot, the car among the skyscrapers with a popup over them: `bash game/tools/screenshot.sh res://tests/fixtures/popup_over_building_demo.tscn screenshots/T-132_popups_over_building.png 24`.
- **Comic look (task T-084, round 2):** `scripts/hud/trick_popup_art.gd` (`TrickPopupArt`) bakes one hard-edged RGBA image per text and size, at the first use, cached (`texture(text, style)`, `bake()`): the text in Bangers (smoothing off, glyphs read from the font server, no viewport needed, so it also works headless), every letter black on one straight baseline (names and amounts alike, no outline or shadow), on a white rounded rectangle with a 2 pixel black border (T-125 round 3, board 2026-10-14; it was a jagged burst), fitted to the text with `MARGIN_X`/`MARGIN_Y` padding and stepped pixel corners of radius `CORNER` (pixel centres tested, no smoothing; same texture for the same text). Round 1 had pink names, cyan amounts and a navy burst; the board's playtest asked for white and black. Only opaque or fully transparent pixels, three colours (black, white, nothing), no Redgull red. `tools/build_trick_popup.py` made the first sample (round 1, old colours) and is no longer used by the game. No PixelLab call was made for this. Screenshot: `bash game/tools/screenshot.sh res://tests/fixtures/trick_popups_demo.tscn screenshots/trick_popups.png 10` (all four popups); `combo_demo.tscn` shows the real combo path.
- **Heat steps (task T-133):** the popups follow the combo's heat steps (T-131, `ComboHeat`). `TrickPopups.heat_for(multiplier)` is `ComboHeat.step_for(multiplier)` (the only thresholds are `ComboHeat.THRESHOLDS`). `_on_combo_trick` passes the step of the signal's `multiplier` (the combo after the trick) and `_on_score` the step of the bound run state's `combo` to `show_popup(..., heat)`; the car's own `trick` signal (the drift prototype) always shows step 0. `PopupText.heat` (0 to 3) and `PopupText.frame` pick the texture (`texture()`); at the flaming step `advance()` moves `frame` on every `ComboHeat.FLICKER_FRAME` and redraws. `PopupText.size()` (stacking, the height limit) is always the plain popup's size. In `TrickPopupArt`, `bake(text, style, heat := 0, frame := 0)` and `texture(text, style, heat, frame)` (cached per style, heat, flame frame and text): heat 0 is byte for byte the plain look. `HEAT_RINGS` lists each step's rings round the white fill, from the outside in: step 1 a 1 px black outline and a 3 px yellow ring; steps 2 and 3 a 1 px black outline, a 3 px orange ring and a 2 px yellow inner ring; the image grows by `ring_extra(heat)` on each side, the fill, padding and corner radius of the fill stay. From `AMOUNT_HOT_STEP` (2) the "+amount" glyphs (`split_text`; `_letter` marks them `AMOUNT`) are orange with a 1 px black outline (four neighbours, so small digits keep their holes). From `FLAME_STEP` (3) `_flames()` adds pixel flames in `FLAME_PX` (3) popup pixel blocks, about 2 screen pixels like `LikesFire.PIXEL`, outside the bubble: up to `FLAME_UP` (21) above, `FLAME_SIDE` (9) at the sides and `FLAME_DOWN` (3) below, with LikesFire's swaying tongues and colours (white-hot, yellow, orange-yellow, orange tip, sparks), baked in `FLAME_FRAMES` (6) frames; the image grows by `FLAME_SIDE` and `FLAME_UP` on each side so the bubble stays centred. `text_box(text, style, heat)` gives the letters' box at a step. All colours are LikesFire's, none near the heart red. Screenshots: `bash game/tools/popup_heat_shots.sh screenshots` makes `T-133_popups_heat.png` (fixture `tests/fixtures/popups_heat_demo.tscn`: one row per step, a normal, a small and a challenge popup), `T-133_popups_heat_zoom.png` (that, enlarged 2x), `T-133_popups_heat_sheet.png` and `..._sheet_f3.png` (the baked popups alone on dark and light, enlarged 3x, flame frames 0 and 3; `tools/popup_heat_sheet.gd`, headless) and `T-133_combo_heat_<base|step1|step2|step3>.png` (T-131's combo fixtures: the real popup at the car with the HUD counter at the same step). Tests: `tests/unit/test_trick_popups_heat.gd`.
- **Font:** Bangers Regular 2.100, by Vernon Adams ("Copyright 2010 The Bangers Project Authors"), SIL Open Font License 1.1 (use and bundling in a commercial game allowed; the font may not be sold on its own). Source: https://github.com/google/fonts/tree/main/ofl/bangers (commit `66928797f271fed5ee428544e7229685e2d90127`); files `game/fonts/bangers/Bangers-Regular.ttf`, the licence text `game/fonts/bangers/OFL.txt` next to it, and the record `bangers.json`.
- **Tests:** `tests/unit/test_trick_popups.gd` (part of the GUT suite): each trick's text near the car, rising and going away, the small extended-drift popup, a second run, any text, and a drive in the prototype. `tests/unit/test_trick_popup_art.gd` (T-084): no semi-transparent pixels, a transparent border, no colour near the heart red, the bubble fits each text, wider for longer text, the same texture for the same text, only white and black with a black border, name and amount both black, letters on one baseline, nearest filtering. `tests/unit/test_challenge_popup.gd`: the score signal and a completed challenge in the run. Screenshot of a challenge popup in a run from the main menu: `bash game/tools/screenshot.sh res://tests/fixtures/challenge_popup_demo.tscn screenshots/challenge_popup.png 30`. Trick screenshot: `bash game/tools/screenshot.sh res://tests/fixtures/trick_popups_demo.tscn screenshots/trick_popups.png 10`.

## Pause screen

Task T-015 (UI Agent). Escape (the `pause` action in the input map) pauses the whole game tree and shows the pause screen: the title, a hint that Escape resumes, and one setting, the camera zoom slider (6 to 20, default 14.4, the same value as the tuning panel's zoom slider; moving either updates the other). Pressing Escape again resumes from exactly where the car was. The tuning panel (Tab) does not work while paused. The texts are from task T-047. The slider's label is "Camera zoom level" (T-093). The panel sits in a compact strip just below the HUD timer (`STRIP_TOP`), only as tall as its content (T-095), over a light dim, and moving the slider zooms the view behind it at once while everything stays paused (the camera normally updates in the physics step, which does not run while paused, so while paused it updates every frame with physics interpolation off, and resuming puts it back). A full pause menu with more settings is task T-016.

- `scripts/ui/pause_screen.gd`: the screen. It keeps processing while the tree is paused, handles Escape and sets the zoom on the scene it belongs to.
- `scripts/ui/game_settings.gd` (`GameSettings`): the saved zoom, in `user://settings.cfg` (section `camera`, key `zoom`), and since T-123 the camera options (see "Camera options"). Read when the game starts; no file, a bad value or no value gives 14.4, and a saved value outside 6 to 20 is clamped. The pause slider saves on every change; the tuning panel's zoom slider and its reset button do not save.
- **Camera controls (task T-124):** under the slider, `smoothing_check` ("Camera smoothing") and `dynamic_check` ("Dynamic camera"), and while the dynamic camera is on a `tuning_row` with `set_min_button` ("Set min zoom"), `min_label`, `set_max_button` ("Set max zoom") and `max_label`. They call `target.camera_follow` (see "Camera options") and read their state from it on pausing and on its `changed` signal. The two buttons are a temporary tool for the board and go once the values are settled. Tests: `tests/unit/test_pause_camera_controls.gd`. The checkboxes have their own placeholder icons (`check_icon()`: a light frame on a dark fill, a light square inside when checked) and the buttons their own frames (`button_style()`, for normal, hover, pressed and focus), and the strip is nearly opaque (`STRIP_COLOR`), so all of them show over the bright ground of a run (QA round 1). Screenshots with the dynamic camera on: in the drift prototype, `bash game/tools/screenshot.sh res://tests/fixtures/pause_screen_demo_dynamic.tscn screenshots/pause_dynamic.png 300`; in a run started from the main menu, `res://tests/fixtures/pause_run_dynamic_gravel.tscn` (the run's start, on the gravel) or `..._asphalt.tscn` (on the road), 60 frames. The run fixtures use their own test settings file (dynamic camera on, smoothing off, min 10.0 and max 17.5), never the player's real settings.
- **Tests:** `tests/unit/test_pause_screen.gd` (part of the GUT suite) uses a test settings file, never the real one. For a screenshot of the paused game: `bash game/tools/screenshot.sh res://tests/fixtures/pause_screen_demo.tscn screenshots/pause.png 300`; `pause_screen_demo_in.tscn` and `pause_screen_demo_out.tscn` do the same with the slider moved to 7 and 19 after pausing; `pause_from_menu_demo.tscn` pauses a run started from the main menu.

## Camera options

Task T-123 (Drifting, Content, "Camera options"): camera smoothing and the dynamic camera (zoom follows the car's speed), both off by default. With both off the camera sits exactly on the drawn car with the slider's zoom, as before.

- `scripts/driving/camera_follow.gd`: the options, no nodes. The drift prototype and the run each own one, `camera_follow`. After every car physics step the scene calls `camera_follow.step(drawn_car_position, speed_fraction, dt)` and puts `camera_follow.position` and `camera_follow.size` (Unity's orthographic size) on its `Camera`; a new run, a view switch or an outside `sync_view()` call snaps it with `snap()`. `speed_fraction_of(car.model)` is the car's speed in any direction over its top forward speed, capped at 1. The tunable rates are its constants `SMOOTHING_RATE` (8 per second) and `ZOOM_EASE_RATE` (3 per second).
- **Saved:** in `user://settings.cfg`, section `camera`, next to `zoom`: `smoothing` and `dynamic` (true or false, default false), `dynamic_min` and `dynamic_max` (6 to 20, defaults `GameSettings.DEFAULT_DYNAMIC_ZOOM_MIN` 11.0 and `DEFAULT_DYNAMIC_ZOOM_MAX` 17.0; out of range is clamped, a bad value gives the default). `GameSettings` has `load_`/`save_camera_smoothing`, `load_`/`save_dynamic_camera`, `load_`/`save_dynamic_zoom_min` and `load_`/`save_dynamic_zoom_max`. The drift prototype reads them at start; `game_flow.gd` has a run read them right after the zoom (`run.load_camera_options()`). A run scene opened on its own starts with both off.
- **Reading the board's min and max:** every save of the min or max prints a line like `Dynamic camera zoom: min 11.0, max 17.0 (saved in C:/Users/.../settings.cfg, section camera)` to Godot's output (`GameSettings.dynamic_zoom_report()` gives the same line). The file itself is a plain text file: on Windows, `%APPDATA%\Godot\app_userdata\Solid Carbide\settings.cfg`, keys `dynamic_min` and `dynamic_max`. Copy them into `DEFAULT_DYNAMIC_ZOOM_MIN` and `DEFAULT_DYNAMIC_ZOOM_MAX` to make them the game's defaults.
- **Tests:** `tests/unit/test_camera_options.gd`, part of the GUT suite.

**API for the pause screen's controls (task T-124).** The pause screen's `target` is the drift prototype or the run; call these on `target.camera_follow`. Every setter saves at once and applies at once, also while the game is paused.

| Call | Does |
| --- | --- |
| `set_smoothing(on: bool)` | The "Camera smoothing" checkbox. |
| `is_smoothing() -> bool` | Its state, for the checkbox's starting value. |
| `set_dynamic(on: bool)` | The "Dynamic camera" checkbox. On: the zoom eases from where it is toward the speed's zoom. Off: straight back to the slider's zoom. |
| `is_dynamic() -> bool` | Its state (also: show the min and max buttons only while it is on). |
| `set_dynamic_min_from_current() -> float` | "Set min zoom": the min becomes the slider's current zoom (`target.zoom`); returns the new min. |
| `set_dynamic_max_from_current() -> float` | "Set max zoom": the same for the max. |
| `get_dynamic_min() -> float`, `get_dynamic_max() -> float` | The stored values, to show next to the buttons. |
| signal `changed` | Emitted after any of the above and after a slider zoom change. |

The zoom slider keeps calling `target.set_zoom(v)`: with the dynamic camera off that is the camera's zoom, as before; with it on the view shows that zoom at once (a preview for choosing the min or max) and eases back to the speed's zoom when the car moves.

## Game data

Written by the Game Data Agent (task T-038); the enemy, weapon and garage data tasks follow the same convention.

- **Where:** one JSON file per area under `game/data/` (`run.json` for the run's XP, levels and car starting health). Keys are `snake_case`. A `_comment` key may explain a file. Numbers are proposals the board judges in playtests, and are changed in the file, never in code.
- **Loader:** `scripts/data/game_data.gd` (`GameData`). `GameData.load_file("run")` reads `res://data/run.json`; `GameData.get_value(data, "car.starting_health")` reads a dotted path (array indexes as numbers). Both return `{ok, data, error}`: a missing file, invalid JSON or missing value gives `ok = false` and a clear `error` message. `GameData.unwrap(result)` returns the data, or `push_error`s the message and returns null.
- **Typed readers:** for each data file, a small class next to the loader wraps it so game code does not index dictionaries. `scripts/data/run_data.gd` (`RunData`) gives `xp_needed(level)`, `challenge_xp(level)`, `drift_xp_per_second()`, `max_level()`, `carries_over()`, `starting_health()`, and the likes drain (`likes_drain` in `run.json`, task T-114): `likes_drain_enabled()`, `likes_drain_bar_share_per_second()` (share of the current level's bar drained per second, 0.08, the board's playtest value since T-120: a full bar empties in 12.5 s, 8 likes a second at level 1), `likes_drain_extra_wait_seconds()` (wait after the combo has fully drained, 0) and `likes_drain_xp_per_second(level)` (the share times that level's `xp_needed`, 0 when off or at max level). `scripts/data/combo_data.gd` (`ComboData`, from `combo.json`) gives `trick_add(trick)`, `after_trick()`, `after_collision()`, `after_idle()` and `spawn_multiplier()`.
- **Garage:** `garage.json` holds the 3 upgrades (`acceleration`, `car_health`, `damage_bonus`), 10 levels each, with a `price` and a `value` per level and a `base_value` for level 0. `scripts/data/garage_data.gd` (`GarageData`) gives `max_level()`, `price(upgrade, level)` and `value(upgrade, level)`. Tests: `tests/unit/test_garage_data.gd`.
- **Weapons (T-040):** `data/weapons.json` holds the starting gun and the exhaust flamethrower: base values and, for each, the 7 upgrade tiers (tiers 2 to 8) as `effect` plus `value`. `scripts/data/weapon_data.gd` (`WeaponData`) adds the tiers up: `gun_at(tier)` and `flame_at(tier)` return the weapon's values at that tier (tier 1 = just got it), and `tiers(weapon)` the raw list. Tests: `tests/unit/test_weapon_data.gd`, which compares everything with the Unity weapons report.
- **Enemies (T-039):** `data/enemies.json` holds the minion (`health`, `move_speed`, `contact_damage`, `contact_damage_interval`, `knockback`), `spawning` (how many minions are kept around: `minions_at_start`, growing in a straight line to `minions_at_boss_time` at `growth_until_seconds` = the kaiju's arrival, then held; one spawns every `spawn_interval_seconds` while fewer are around, `spawn_margin_units` beyond the visible screen's edge), `coins` (`drop_chance`, `coins_per_drop`), the `kaiju` (same keys as the minion), `kaiju_coins` (T-119: the coins the kaiju drops when defeated, `drop_chance` 1 = always and `coins_per_drop`; its death ends the run, so they are added to the run's coins as it ends, without a pickup) and its `meteor_attack` (`first_attack_after_seconds`, `seconds_between_attacks`, `windup_seconds`, `meteors_per_attack`, `warning_seconds` (decided, 2 s), `land_within_units_of_car`, `impact_radius_units`, `impact_damage`, `knockback`). Units as everywhere: 1 unit = the car's width, speeds and knockback in units per second, damage in the car's health points. `scripts/data/enemy_data.gd` (`EnemyData`) gives each section as a Dictionary of floats (`minion()`, `spawning()`, `coins()`, `kaiju()`, `meteor_attack()`), `kaiju_coins()`, `minions_wanted(run_seconds, spawn_multiplier = 1.0)` (pass `ComboData.spawn_multiplier(combo)` for the combo's extra spawning), `expected_coins_per_kill()`, `kaiju_coins_on_defeat()` (whole coins the defeated kaiju adds) and `meteor_attack_times(fight_seconds)`. Enemy stats never change over a run; only `minions_wanted` grows. Tests: `tests/unit/test_enemy_data.gd`, including the kaiju's time to kill with the MVP weapons and its coins when defeated.
- **Playtest switches:** `data/playtest.json` holds switches for playtests only, not balancing numbers and never shown to the player: a dictionary of independent keys, each read by its own task's code. `flamethrower_at_start` (T-042, see "Weapons") and `kaiju_early_arrival` (T-045, see "The kaiju"). Each reading script has a static `playtest_override` that tests set, so the tests follow the game's rules whatever the file says.
- **Saving and buying (T-057):** `scripts/data/player_progress.gd` (`PlayerProgress`) keeps the player's coins and the garage upgrade levels in `user://progress.json` (`{"coins": n, "levels": {"acceleration": 0, ...}}`). A missing or broken file is a new player: 0 coins, every level 0. `GameFlow.progress` is the game's instance; it banks each run's coins on `run_ended` (win or loss) and saves. Tests set the static `PlayerProgress.path` to `RunPaths.file(...)`. Functions, for the garage screen (T-058) and for applying upgrades at the start of a run (T-060, T-061, T-062); upgrade ids are `GarageData.UPGRADES`:
  - `get_coins() -> int` and the `coins` field; `level(id) -> int`; `is_maxed(id) -> bool`.
  - `next_price(id) -> int` (coins for the next level, -1 when maxed).
  - `current_value(id) -> float` (the stat at the current level: time to top speed in seconds, starting health, damage bonus in percent; level 0 is the base) and `next_value(id) -> float` (-1.0 when maxed). Apply an upgrade at run start by reading `current_value(id)`.
  - `info(id) -> Dictionary` with `id`, `level`, `max_level`, `maxed`, `next_price`, `current_value`, `next_value`, `can_buy`, everything a garage row shows.
  - `can_buy(id) -> String`: `PlayerProgress.OK` (empty), or the refusal reason `NOT_ENOUGH_COINS`, `MAXED` or `UNKNOWN_UPGRADE`.
  - `buy(id) -> Dictionary` `{"ok": bool, "reason": String}`: if it can be bought it spends the price, raises the level and saves; a refusal changes nothing.
  - `bank_run(result, coins)` adds a run's coins and saves; `connect_run(run_state)` connects it to `run_ended`. `changed` is emitted after buying or banking. `save()` and `load_from_disk()` are there for completeness.
  - Tests: `tests/unit/test_player_progress.gd`.
  - **Damage bonus (T-062):** `GameFlow.start_run()` calls `run.weapons.set_damage_bonus(progress.current_value("damage_bonus"))` right after the run is added. The rack keeps `damage_bonus_percent`; `damage_multiplier()` is `1 + percent / 100`. Each weapon's `apply_tier()` multiplies that tier's damage with `boosted_damage()` (weapon.gd), so the gun's bullets and the flame's ticks get the same factor, it stacks multiplicatively with the tier's own damage (the flame's hotter-flame tier), and it survives a new run's weapon reset. Level 0 is 0 percent: unchanged. Tests: `tests/unit/weapons/test_damage_bonus.gd`.
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

**See-through buildings** (task T-034, per-slot with the art in T-064; the rule: Visual style, Decisions, and `docs/level-design.md`, Content, "See-through buildings"; the research: `docs/visual-style/see-through-buildings.md`, T-020).

- **The buildings:** each building in the layout data is its own node, `scripts/level/map_building.gd`, named `Building01` ... under the map's `Buildings` node (`map.buildings_draw`, which still sits after the ground tiles and drift marks and before the boulders in `map.view_root`; it also draws the map's outline). `map.buildings` lists them in the layout data's order. Each has its `footprint` (a `Rect2` in units) and `height_units`. In the isometric view the placeholder is a box `BUILDING_HEIGHT_UNITS` (15) tall, drawn in flat world pixels under the view's projection (one unit up on screen is the world offset (-1, -1) unit); in the flat view it is the flat rectangle as before and never covers anything.
- **Draw order:** buildings get a `z_index` from their front corner (`depth_key()`, x + y of the footprint's far corner): `BUILDING_Z_BASE` (2) plus `BUILDING_Z_STEP` (3, task T-065) per place in that order, so the nearest is drawn last. The ground, ground tiles, drift marks, arrows and the flat view's placeholder boulders stay at z 0, under every building. Each boulder sprite (T-065) gets a z once, when it is placed: one under the lowest building that covers it (the boulder's centre is behind the building and its outline overlaps the building's on screen), or `top_z_index()`. `map.car_z_index(centre_units, rotation)` gives the car's place: one under the lowest building that covers it, or `top_z_index()` (over every building) when none does; then one under any boulder that covers it (the car's centre has a smaller x + y than the boulder's and the car's screen shape overlaps the boulder's outline). So each gap between two buildings has two levels: the boulders, and the car in front of them (the car comes later in the tree, so at the same z it is drawn over), and below that the car behind a boulder. The run puts it on its `View` node in `sync_view()`, so the car sprite, the level-up burst and the trick popups (z 100 inside `View`) move together; keep every building's z under 100 so the popups stay on top.
- **When a building fades:** `covers(car_centre_units, car_shape)`: the car is behind it (`is_behind()`: its centre is not in front of the +x or +y wall, `x < footprint.end.x and y < footprint.end.y`) and the drawn car's screen shape overlaps the building's on-screen outline (`silhouette()`, six points in the map's screen pixels; `Geometry2D.intersect_polygons`). The car's shape is `map.car_screen_shape(centre_units, rotation)`: its 1 by 3 unit rectangle on the ground and the same rectangle `CAR_HEIGHT_UNITS` (1) higher, as one convex outline.
- **The fade:** every frame (`_process`) the map calls `update_see_through(car.position / 16, car.rotation, delta)` when its `car` is set (the run sets it). A covering building moves its `modulate.a` towards `SEE_THROUGH_ALPHA` (0.15), every other one towards 1, both at a speed that takes `SEE_THROUGH_FADE_TIME` (0.15 s) for the whole way. Nothing else is touched: no tint, no shader, no pixel of any texture. `covering_buildings()` lists the buildings covering the car now; `alpha()` is a building's alpha. The two values are the constants at the top of `mvp_map.gd`, the one place to change them.
- **The final building art (T-064, done; Visual style, Decisions, "Buildings" and "City colours"):** each block is 2 x 2 slots of 15 x 15 units; each slot holds one skyscraper (a 12 x 12 unit footprint centred in the slot, 1.5 units of pavement around it). The body is a 768 x 960 art px sprite (a 24-unit wall at the outer corners, 30 at the front corner, the top 6 units dissolving into the dark with an ordered dither, no roof), drawn at scale 0.5 (32 art px per unit, the car's and the ground's density) with nearest filtering, anchored at its bottom centre = the footprint's front corner, in the map's screen pixels (the node `Art` undoes the view's projection, like the ground tiles and boulders). Palette B (steel and glass); the boulders deliberately keep their own alien palette.
- **Per-slot fade (T-064):** `BuildingTowers.setup()` (`scripts/level/building_towers.gd`, the block's `Towers` child) makes the four slots' own fade nodes (`map_building.gd`: footprint 12 x 12, `height_units` 30, `custom_silhouette` the body's outline, `draw_placeholder` false, child `Art/Sprite`); the map adds them to its `Buildings` container and lists them in `map.slots`. `map.fade_items()` is the list that fades and sorts with the car: `slots` when the art is loaded, else the blocks (`map.buildings`). `update_see_through`, `covering_buildings`, `car_z_index`, `top_z_index` and the boulders' z use it, so only the skyscraper covering the car fades, and the depth order is per slot (z from each slot's front corner). The blocks stay in `map.buildings` for layout and collisions (unchanged) and for the flat view's placeholder boxes. The pavement (4 sprites per block, `Towers.pavement_root`) sits directly in `map.buildings_draw` at z 0 under the car, boulders and slots, so it never fades; a faded skyscraper shows its pavement.
- **Which skyscraper goes where, and how the art is made:** `BuildingTowers.make_plan(block_x, block_y)` gives each slot one of 6 skyscrapers (the four of a block always differ, neighbouring blocks are shifted) and one of its 2 variants (flip, sign wall and height, facade bands, rubble) from a fixed hash of the block's position (the same on every run). The art: per skyscraper a PixelLab facade band and shopfront strip (the sample's tower 1: 3 calls, towers 2 to 6: 2 calls each, `art-archive/T-064/round2/raw/`), the vertical signs drawn by script (abstract strokes, no real glyphs), assembled for free by `python game/tools/build_city.py` (flat pieces snapped to the 28 colours of palette B, the wall lifted for contrast, built from floor-high bands with random slices and flips so the mirror pattern is not obvious, sheared 2:1 onto the two walls with no resampling, a darker right wall, floor lines, outline, dither, 12 bodies `art/buildings/skyscraper_<tower>_<variant>.png`, listed in `art/buildings/skyscrapers.json`); the slot pavement is script drawn (`city_palettes.py`, `cityB_pavement_*.png`). `tools/test_build_skyscrapers.py` and `tools/test_build_buildings.py` check the pieces. The round-1 dense towers are kept in `art-archive/T-064/round1-game-art/`, the palette A and C recolours in `art-archive/T-064/round2/palettes/`. Tests: `tests/unit/test_building_art.gd` (4 slots and 4 pavements per block, flat view keeps the box, nearest filter and scale, four different skyscrapers per block and all 6 used, stable plan, silhouettes, only the slot covering the car fades, the car's z under only that slot, no semi-transparent body pixel); the older fade and depth tests (`test_see_through_map.gd`, `test_boulder_art.gd`) run on the placeholder blocks (`building_art_enabled = false`), the mechanism is the same. Screenshots (isometric): `bash game/tools/screenshot.sh res://tests/fixtures/city_behind_shot.tscn screenshots/x.png 60` (car behind a skyscraper, only that one faded), `city_palette_shot.tscn` (a block next to the car and a boulder), and `res://scenes/level/mvp_map_overview_iso.tscn` for the whole map.
- **Short buildings whose roofs show (T-129):** a slot can hold a short building instead of a skyscraper: `BuildingTowers.short_slots(block_x, block_y)` picks them by a fixed hash (the front slot (1,1) half the time, one of the side slots (1,0) or (0,1) 40% of the time, the back slot (0,0) never: about 0.9 per block); `make_plan` adds `short` and `short_body` (0 to 7; two shorts in a block are always different designs) to each slot. A short building is 4 designs x 2 looks (the second look is mirrored with the pale-blue accent), 8 bodies `art/buildings/short_body_0..7.png` (768 x 518 or 522 art px, palette B, anchored at the bottom centre like the skyscrapers, listed under `short` in `skyscrapers.json`), its own slot fade node of 4.3 units, the same pavement. Its fade outline is `BuildingTowers.short_outline(w, h)`: six points following the roof diamond (apex at the top centre, side corners w / 4 lower) and the walls' bottom edges, one pixel of margin, so it holds every opaque pixel and leaves out the empty triangles above the roof's back edges (QA round 1: with the skyscrapers' full-width top, a car on the road behind the roof faded it); the skyscrapers keep their 5-point outline. Made for free from PixelLab facades and rooftop props by `python game/tools/build_short_set.py --raw art-archive/T-129/raw --out-dir art-archive/T-129/full --game-dir game/art/buildings` (`build_short_buildings.py`: exact 2:1 shear of two facades, the roof drawn by script, props with their base plates cut off, scripted abstract shop signs with no glyphs; `short_building_requests.py` writes the PixelLab request bodies; `sample_short_building.py` made the sample's previews). Designs: A and D from their own facades, B uses one facade on both walls (mirrored), C mixes B's left and D's right wall (the c_facade results were nearly black and are not used). Tests: `tests/unit/test_building_art.gd` (slot rule, designs, short slot drawn low and fading by itself, the outline holding all opaque pixels of the 8 bodies, no fade behind the roof's back edges) and `tools/test_build_short_buildings.py`. Screenshots: `res://tests/fixtures/short_building_beside.tscn` and `short_building_behind.tscn` (copies in `art-archive/T-129/screenshots/`).
- **Alert signs (T-130; Visual style, Decisions, "City brief" and the alert-sign red):** 6 road-style kaiju signs, from `data/level/kaiju_signs.json` (a small list: id, kind, block [column, row], slot, wall, `along`, `bottom_units`, design; edit it to move, add or remove signs, no code change), built by `scripts/level/kaiju_signs.gd` right after the buildings (`map.alert_signs` lists the sprites, `map.alert_signs_root` the pavement ones). **4 banners hang on skyscraper walls** (never on a short building: too low): block (0,0) slot (0,1) south wall, block (3,1) slot (1,1) east wall, block (2,0) slot (1,0) east wall, block (1,3) slot (0,1) south wall; each is a `Sprite2D` child of its slot's `Art` node, the 2:1-sheared sprite (`art/banners/kaiju_*_building_wall.png`, flipped for the +x wall) with its bottom 3 units above the ground, so it fades with that slot and shares its depth. **2 signs stand on the pavement** at the +x/+y corner of blocks (0,2) and (3,3), 0.75 units in from the kerb (plan said 1.5; the pavement strip is only 1.5 wide, so 0.75 keeps the post on it), in `alert_signs_root` (never fades), `z_index` = the block's front slot + 1 (over the wall behind it, under every nearer slot and the car in front). Pictures only: no collisions. Hidden in the flat view with the building art. Heads are the red triangle, bodies the red circle. The sprites are built by `python game/tools/build_kaiju_banners.py build` (0 PixelLab calls); tests `tests/unit/test_kaiju_signs.gd`, `tools/test_build_kaiju_banners.py`. Screenshots (copies in `art-archive/T-130/screenshots/`): `bash game/tools/screenshot.sh res://tests/fixtures/alert_banner_beside.tscn screenshots/x.png 60` (also `alert_banner_south`, `alert_sign_beside`, `alert_banner_behind`: the car behind the skyscraper, banner faded).
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

**The HUD** (task T-090): `scenes/hud/hud.tscn` with `scripts/hud/hud.gd` (`Hud`, a CanvasLayer) is added by the run scene and bound to the run's state (`run.hud`). It shows the timer (`hud.timer_label`, M:SS from `time_left_text()`), and since T-049 the car's health bar (`health_bar`, `health_label`), the likes bar (`likes_bar`, `likes_label`, `heart`) with the level (`level_label`) and the coins (`coins_label`, `coins_value_label`), following the run state's `health_changed`, `xp_changed`, `coins_changed` and (T-083) `combo_changed`: the combo counter `combo_label` ("Combo x{multiplier}", `Hud.combo_text()`). Layout since T-113: the top-left `left_column` (a plain Control, `_layout_left()`) holds "Car Health" with the upright health bar directly under it (`fill_mode` bottom to top, `Hud.HEALTH_BAR_SIZE` 24 x 160), both at the same left edge. `bottom_area` (a full-screen Control that ignores the mouse, `_layout_bottom()`, re-run when the window or a text's size changes) holds the horizontal likes bar (fill left to right, `LIKES_BAR_WIDTH` half the screen wide, `LIKES_BAR_HEIGHT` 16, centred, `MARGIN` 16 above the bottom edge); directly above it one row: `likes_row` (heart and "Likes") from the bar's left end and `level_label` ending at its right end, given the same top and height so both texts share a baseline; and the combo counter centred above that row. Since T-116 the combo counter is hidden at "no combo": `Hud.show_combo(multiplier)` is true only above combo.json's `start_multiplier` (read through `ComboData`, compared at the two decimals the counter shows), so it starts hidden, shows after a trick and hides again once the combo drains back; every element keeps its own fixed place, so hiding it moves nothing. The texts are T-048's (`Hud.TEXT_*`). It appears in every run, also one started from the main menu. A screenshot fixture of it is `tests/fixtures/hud_from_menu_demo.tscn`. What it shows: `docs/hud-and-menus.md`, Content. Tests: `tests/unit/hud/test_hud_timer.gd`, `test_hud_values.gd`, `test_hud_combo.gd` (the counter and the popup amounts), `test_hud_combo_hidden.gd` (T-116: hidden at no combo, shown after a trick, hidden again after the drain and in a new run, nothing else moving) and `test_hud_layout.gd` (T-113: health bar upright under "Car Health", likes bar centred at the bottom with its row and the combo above it, same font size per group, the layout following a window resize, no overlaps at 1152x648, 1280x720, 1920x1080 and 1024x576, clear of the screen's middle and the pause strip's content; headless the root viewport is 64x64, so the test lays the HUD out in a window-sized SubViewport). **Combo heat (task T-131):** `scripts/hud/combo_heat.gd` (`ComboHeat`, a pausable node under the HUD, `hud.combo_heat`) picks the heat step from the multiplier (`ComboHeat.step_for()`, compared at two decimals; the thresholds are `ComboHeat.THRESHOLDS` = [2.0, 3.0, 4.0], the only place to change them) and restyles the combo counter per step from `ComboHeat.STEPS` (font size 30, 36, 42, 50; pink, yellow, orange, white-hot; a glow ring drawn as the label's zero-offset shadow from step 2, flickering between oranges and yellows at step 3; a pulse of 0, 6, 10 and 14 per cent, in 1/12 s pixel-art frames, `pulse_scale()`). The pulse scales the label from its bottom centre (`pivot_offset`, set in `_layout_bottom()`), so it stays centred and never grows down into the row. From `ComboHeat.FIRE_STEP` (3) it lights `scripts/hud/likes_fire.gd` (`LikesFire`, `hud.likes_fire`, a Control drawn in code between the likes bar and the row's texts): columns of 2-pixel squares in four flame colours (`LikesFire.PALETTE`), up to `MAX_HEIGHT` 26 above the bar over the filled part (`fill_ratio`, from the bar's value), `TEXT_HEIGHT` 8 under "Likes" and "Hype Lv" (`low_spans`, set in the layout), `EMPTY_HEIGHT` 4 over the empty part, and `INTO_BAR` 4 into the bar's top; heights flicker in the same frames, with a few sparks. `hud.combo_step()` and `hud.fire_on()` report the state. **The heart (task T-086):** `hud.heart` is a `TextureRect` showing `art/hud/likes_heart.png` (`Hud.HEART_PATH`), an 11 x 10 pixel-art icon (flat Redgull red `Hud.HEART_COLOR` with a 1 art pixel dark outline in `Hud.OUTLINE_COLOR`, two colours, transparent background, no semi-transparent pixels) shown at `Hud.HEART_SCALE` 2 with nearest filtering, so about the height of "Likes" and level with it. It sits in `hud.heart_box`, a 26 x 26 `Control` (`Hud.HEART_BOX`, the placeholder's size) at the row's left end, the art at the box's left edge and 2 px above its vertical centre, so the row's height and width, "Likes", "Hype Lv" and the combo counter sit exactly where they did before the art (pinned by `tests/unit/hud/test_hud_positions_t086.gd`, values measured from master's code). It is drawn by a script, not PixelLab (0 generations): `python game/tools/build_heart_icon.py build` rebuilds the PNG and its record `art/hud/likes_heart.json` (the grid is `FILL` in the script; `check` verifies the committed PNG); tests `tools/test_build_heart_icon.py` and `tests/unit/hud/test_hud_heart_art.gd`. Enlarged previews on dark and light: `art-archive/T-086/heart_dark_light_x16.png`; HUD screenshots: `bash game/tools/screenshot.sh res://tests/fixtures/hud_from_menu_demo.tscn screenshots/hud.png 30` and `bash game/tools/screenshot.sh res://tests/fixtures/combo_heat_step3.tscn screenshots/hud_step3.png 30` (copies in `art-archive/T-086/screenshots/`). `Hud.comic_font()` is Bangers with smoothing off, used by the counter, "Likes" and "Hype Lv". Both nodes are `PROCESS_MODE_PAUSABLE`, so they stand still while paused. Tests: `tests/unit/hud/test_hud_combo_heat.gd` (the step at each side of each threshold, sizes growing step by step, the fire only at step 3, the look following the drain and a collision down, the comic font and unchanged words, no Redgull red in any counter, glow or flame colour, the layout and the flames' limits at step 3 at the four window sizes over a whole pulse, standing still while paused, a run from the main menu). Screenshots of the four steps (fixtures `tests/fixtures/combo_heat_base.tscn`, `combo_heat_step1.tscn`, `combo_heat_step2.tscn`, `combo_heat_step3.tscn`, script `combo_heat_demo.gd`): `bash game/tools/combo_heat_shots.sh screenshots` writes `screenshots/combo_heat_{base,step1,step2,step3}.png` and `screenshots/combo_heat_steps.png` (the bottom of the four, stacked, 2x; `tools/combo_heat_strip.py`, tested by `tools/test_combo_heat_strip.py`). Screenshot of the HUD in a run from the main menu: `bash game/tools/screenshot.sh res://tests/fixtures/hud_from_menu_demo.tscn screenshots/hud.png 30` (with a combo, so the counter shows); the same with no combo, the counter hidden (T-116): `bash game/tools/screenshot.sh res://tests/fixtures/hud_no_combo_from_menu_demo.tscn screenshots/hud_no_combo.png 30`; screenshot of the counter and a popup per trick in a run from the main menu: `bash game/tools/screenshot.sh res://tests/fixtures/combo_demo.tscn screenshots/combo.png 30`; part of the GUT suite.

**The scene** (`scripts/run/run.gd`, root node `Run`):

- Children: `Map` (the MVP map scene, drawn in the isometric view, with the drift marks inside its drawing, see "Drift marks"), `PhysicsWorld` (the `Car`, never drawn, in the same flat world pixels as the map), `View` (the drift smoke, see "Drift smoke", then the car's sprite and the `Camera`) and `RunState` (the state, below).
- The car starts at the centre of the map (0, 0 units, in the gravel square), nose along -y, as in the drift prototype. The camera sits exactly on the drawn car, zoom 14.4, as in the drift prototype, unless a camera option is on (see "Camera options"). The map checks its challenges against the car (`map.car`).
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

A screenshot fixture, `tests/fixtures/likes_drain_demo.tscn`, starts a run from the main menu with level 2 and a fifth of its bar, then does nothing, printing the time, XP and level every half second: `bash game/tools/screenshot.sh res://tests/fixtures/likes_drain_demo.tscn screenshots/likes_drain_1.png 90` (the bar emptying; at T-120's speed the fifth of level 2's bar is gone in about 2.5 s) and `... screenshots/likes_drain_2.png 3500` (empty, still level 2). The frame counts depend on the screen's refresh rate; the printed lines say how far in each shot is.

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

## Minions

Task T-044 (Enemy Behavior Agent): the MVP minion as Enemies, Decisions describes it, with T-039's numbers (`data/enemies.json` through `EnemyData`, "Game data" above). What it does: `docs/enemies.md`, Content, "The minion". Placeholders for now (a light green four-legged lizard drawn in code, gold coins); the final art comes from separate art tasks.

**See it:** start the game (F5) and press Start, or open `scenes/run/run.tscn` and press F6. Minions start coming in from the screen's edges at once and walk towards the car. Screenshots, from the repo root: `bash game/tools/screenshot.sh res://tests/fixtures/minions_demo.tscn screenshots/minions.png 20` (minions and two coins around the car in the gravel square) and `bash game/tools/screenshot.sh res://tests/fixtures/minions_draw_order_demo.tscn screenshots/minions_draw_order.png 20` (the car on the road beside a block of skyscrapers and two boulders, minions in front of and behind them). Both start the run from the main menu (fixture script `tests/fixtures/minions_demo.gd`). Copies are in `art-archive/T-044/screenshots/`.

**How it is built** (`scripts/enemies/`):

- `minion_spawner.gd`: the run's minions. The run scene adds it as `run.minions` (child `Minions`) and calls `bind(run)`. It moves everything in `step(dt)`, once per physics step from `_physics_process` (pausable, so the pause screen and the level-up pause stop the minions and their damage), and does nothing once the run is over. On `run.world_rebuilt` (a new run) it removes every minion and coin and follows the new car and map. `enabled = false` stops it (tests).
- `minion.gd`: one minion, a `CharacterBody2D` in the run's `PhysicsWorld` (flat world pixels, 16 per unit, like the car) on layer 3 (`enemies`) with mask 1 (obstacles): a circle of `RADIUS_UNITS` (0.5). It slides along walls, buildings and boulders and walks round one it meets head-on (`detour_side`, picked at random per minion); it never pushes or blocks the car. In the groups `enemies` and `minions`.
- `minion_sprite.gd`: the minion's final art (T-068): 8-frame walk sheets in `art/minion/` (`minion_s/se/e/ne/n.png`, 8 frames of 48 x 48 side by side; the other three directions mirror se, e and ne), drawn at scale 0.5 (16 screen pixels per unit), the direction chosen from the way it walks, 10 frames a second, each minion at a random phase. It stops with the game's pause. No shadow under it (board tweak, 2026-10-15). Falls back to the old placeholder shape if a sheet is missing. Sheets are built by `tools/build_minion_sheets.py` from `art-archive/T-068/`; `tools/fix_minion_frames.py` holds the free pixel fixes.
- `coin_sprite.gd`: the placeholder coin drawing, in the isometric view.
- `coin.gd`: a coin, an `Area2D` on layer 4 (`pickups`) with mask 2 (the car).
- `enemy_depth.gd`: the minions' and coins' place in the buildings' depth order.

**Spawning:** the spawner keeps `minions_wanted_now()` minions around, which is `EnemyData.minions_wanted(state.time_elapsed(), spawn_multiplier)` (12 at the start growing to 20 at 7:00, then held). While fewer are around, one spawns every `spawn_interval_seconds` (0.5 s; the first at once), at a random point on the ring `spawn_margin_units` (3) beyond the edge of the visible screen (the camera's view, so it follows the zoom), inside the map and clear of buildings and boulders (`is_free_spot()`; 12 tries, else it waits for the next interval). A minion a whole screen beyond the visible screen (the car drove away from it) is removed without coins and the spawner refills at the edge, so the minions stay around the car.

**The combo raises spawning (T-085):** every call of `minions_wanted_now()` sets `run.minions.spawn_multiplier` from `RunState.combo_spawn_multiplier()` (`ComboData.spawn_multiplier(combo)`: 1.0 with no combo, up to the data's `max_spawn_multiplier` in `data/combo.json`), so the count follows the combo live. **The switch:** `run.minions.combo_raises_spawning` (a variable of `minion_spawner.gd`, default `true`). Set it to `false` and the combo changes nothing: the multiplier stays 1.0. To flip it for a playtest, change the default on that line, or set it from a test or playtest scene. It is a setting, not a key and not player-facing text. Tests: `tests/unit/enemies/test_minions.gd`.

**Movement:** straight towards the car's centre at `move_speed` (6 units/s), plus a small push away from other minions closer than 1.2 units (`Minion.SEPARATION_UNITS`), so a crowd spreads round the car.

**Contact damage:** a minion touches the car when its circle overlaps the car's 1 x 1 unit body (`touches_car()`). While touching, it hits once every `contact_damage_interval` (0.5 s), the first hit as soon as it touches: `RunState.damage_car(contact_damage)` (5; this also cuts the combo) and `car.apply_knockback(away from the minion, knockback)` (8 units/s). Each minion keeps its own interval, so two minions touching hit twice as often.

**Damaging a minion (for the weapon tasks, T-041 and T-042):**

```
func take_damage(amount: float) -> void
```

Call it on a minion node. `amount` is in the same points as `health` (4, `data/enemies.json`). Zero or negative amounts, and calls on a dead minion, are ignored. At 0 health the minion dies: its `died(minion, position_units)` signal fires once, it leaves the groups `enemies` and `minions` at once, its drawing goes, and the node is freed at the end of the frame (so calling it from an `Area2D` callback is safe). To find targets: `get_tree().get_nodes_in_group("enemies")` (the minions and, once it has appeared, the kaiju: see "The kaiju") or `run.minions.minions` (the live minions). Each has `position_units()` (flat world, units; `position` is in flat world pixels), `health`, `max_health` and `is_dead()`. Bodies are on layer 3, so a projectile's `Area2D` finds them with a mask of 4. Check `is_dead()` before damaging one found earlier in the same frame.

**Coins:** when a minion dies, `drop_chance` (0.6) decides whether it drops coins; if so, `coins_per_drop` (2) coins of 1 each land around where it died (`roll_coin_drop()`, using the spawner's `rng`; seed it for tests). Driving over a coin (the car's body entering its circle of 0.5 units) collects it: `RunState.add_coins(1)`, and the coin and its drawing are gone. Coins stay until collected or until a new run. `run.minions.coins` lists them; `spawn_coin_at(units, value)` adds one. The spawner's `minion_killed(minion, coins)` signal fires per death with the number of coins dropped.

**Draw order:** each minion's and coin's drawing is in `run.minions.draw_root` (the node `Enemies`, just before the car's `View` in the run, Y-sorted). Every physics step each drawing is placed on its body in the isometric view and given a `z_index` by the map's rule for the car (`map.car_z_index()`, "See-through buildings" above): one under the lowest building slot or boulder sprite that covers it (it stands behind it and their outlines overlap on screen), otherwise `map.top_z_index()`, over every building. Nothing fades for a minion: the fade stays car-only, so a minion behind an opaque skyscraper is hidden by it, and one behind a building faded for the car shows through it. Where the car and a minion get the same z, the car is drawn over the minion.

**Not in the data:** the minion's and coin's sizes (0.5 unit radius each), the separation distance (1.2 units) and the rule that removes minions a whole screen behind are in the code (`minion.gd`, `coin.gd`, `minion_spawner.gd`): sizes and rules of the placeholder, not balancing numbers.

**Tests:** `tests/unit/enemies/test_minions.gd`, part of the GUT suite: more minions at the end of the 7 minutes than at the start (the run's clock moved on, the count matching `minions_wanted`), one spawn per interval off the screen and clear of obstacles, the combo hook, a minion walking straight at the car at the data's speed and round a building, contact damage at the data's rate with knockback away from the minion, no damage without touching, death at 0 health (once), coins dropping at about the data's chance over 600 deaths, driving over a coin collecting it, minions standing still while paused, a new run clearing everything, nothing moving after the run ends, minions far behind being removed, the collision layers, the draw order under a covering building and over the rest, and no Redgull red in the placeholders.

**Coin art and the hit tint (T-072):** `coin.png` (10 x 12, redrawn by hand in the palette of the one PixelLab sample, `art-archive/T-072/sample/`; `python game/tools/build_hit_coin_damage_effects.py build` redraws it, byte-identical, and `check` runs the rules) is what `coin_sprite.gd` draws, still bobbing. The board played the first version, which also had a hit flash, a death puff and a car damage effect, and dropped those (2026-10-15); the drawn sheets are kept in `art-archive/T-072/unused_effects/`. The one effect left: an enemy that takes damage and survives gets a slight red tint, briefly. `scripts/enemies/hit_tint.gd` (`HitTint`, `DURATION` 0.12 s, `TINT` pale red `Color(1, 0.62, 0.62)`, not Redgull red) tints the owner's `sprite` through `modulate` and restores it by itself. **Used by** `minion.gd` and `kaiju.gd` (both call `HitTint.attach(self)` once in `_ready()` and `hit_tint.flash()` in `take_damage()` when still alive); any other enemy with a `sprite` property (the CanvasItem to tint) can do the same. It works on T-068's animated minion sprite, which is drawn in `_draw`, because `modulate` tints everything the node draws. **With the flamethrower's orange burn flash (T-042):** it never fights it: the tint does not start while the sprite already has another tint, and puts the colour back only if the sprite still has its own red, so orange always wins. **The car shake (T-072; board: "a short shake or wobble of the car" when it takes damage):** `RunState.car_damaged(amount)` (emitted by `damage_car`) makes `run.gd` call `car_sprite.shake()` (`scripts/driving/car_sprite.gd`): for `SHAKE_SECONDS` 0.2 s the drawing moves about `SHAKE_PIXELS` 3 screen pixels (20 Hz, dying down) through the sprite's `offset` only, so the car's physics, position, collisions, the popups and the camera are unchanged. It runs in `_process`, so pausing stops it. Tests: `game/tools/test_build_hit_coin_damage_effects.py` and the T-072 tests at the end of `tests/unit/enemies/test_minions.gd`. Screenshots: `art-archive/T-072/screenshots/` (`tests/fixtures/effects_demo.tscn`, needs a window).
## Weapons

Task T-041 (Weapon Behavior Agent): the starting gun, and how weapons plug into the run. What the gun does: `docs/weapons.md`, Content, "The starting gun". Numbers: `data/weapons.json` through `WeaponData` ("Game data" above); nothing in the weapon code changes them. The bullets are placeholders (a small cyan dot with a white core and a dark outline, drawn in code); the final bullet art comes from a separate art task and replaces `bullet.gd`'s `_draw()`.

**See it:** start the game (F5) and press Start, or open `scenes/run/run.tscn` and press F6. Once a minion is within 12 units of the car, the gun fires at it every 1.26 s. Screenshots, from the repo root: `bash game/tools/screenshot.sh res://tests/fixtures/starting_gun_demo.tscn screenshots/starting_gun.png 16` (the base gun's bullet on its way to the closest minion) and `bash game/tools/screenshot.sh res://tests/fixtures/starting_gun_tier2_demo.tscn screenshots/starting_gun_tier2.png 34` (the gun at tier 2, two of its three bullets in the air). Both start the run from the main menu, place four standing minions round the car and set the gun's clock to fire on the first step (fixture script `tests/fixtures/starting_gun_demo.gd`). Copies are in `art-archive/T-041/screenshots/`.

**How weapons plug into the run** (`scripts/weapons/`, for T-042 and later weapons):

- `weapons.gd`, **the weapon rack**: the run scene adds it as `run.weapons` (child `Weapons`) and calls `bind(run)`; that is the only change to `run.gd`. It holds one node of each weapon in `WEAPON_SCRIPTS`, created in `_init()` and kept for the whole session (`run.weapons.weapons`, a Dictionary by id; `run.weapons.gun` is the starting gun). Once per physics step (`_physics_process`, pausable, so the pause screen and the level-up pause stop the weapons) `step(dt)` moves every projectile, then steps every owned weapon; it does nothing once the run is over (`state.is_running()` false) or with `enabled = false` (tests). On `run.world_rebuilt` (every new run) it follows the new car and map, removes every projectile and calls each weapon's `reset_for_run()`: **a new run starts with the starting gun at tier 1 and nothing else.**
- `weapon.gd`, **the base of every weapon** (extend it with `extends "res://scripts/weapons/weapon.gd"`): `weapon_id` (the key in `data/weapons.json`: `gun`, `flamethrower`), `starts_owned` (true only for the gun), `tier` (0 = not owned, 1 = just got it, up to `max_tier()` = 8), `rack` (the rack, set for you), `data` (a `WeaponData`). `set_tier(t)` clamps, calls your `apply_tier()`, then emits `tier_changed(weapon_id, tier)`; `upgrade()` goes up one tier (0 to 1 gets the weapon) and returns false at the last tier; `is_owned()`, `is_max_tier()`; `reset_for_run()` sets tier 1 or 0 (override it to clear your own state, then call `super.reset_for_run()`). Override `step(dt)`: the rack calls it once per physics step while the weapon is owned and the run is going.
- **To add a weapon (T-042):** a new script in `scripts/weapons/` extending `weapon.gd`, setting `weapon_id` and `starts_owned` in `_init()`, reading its tier's values in `apply_tier()` (for example `data.flame_at(maxi(tier, 1))`), and doing its work in `step(dt)`; then add its preloaded script to `WEAPON_SCRIPTS` in `weapons.gd` (one line). It is then reachable as `run.weapons.get_weapon("flamethrower")`, reset every run, paused with the run, and upgradable through `run.weapons.upgrade(id)`.
- **What the rack gives a weapon:** `rack.car` (the run's car; `rack.car_units()` its centre in units, flat world), `rack.state` (the `RunState`), `rack.run` (the run scene), `rack.living_enemies()`, `rack.enemies_within(centre_units, radius_units)` (living enemies whose centre is within `radius_units`, closest first), `rack.radius_of(enemy)` (how far its body reaches, in units), `rack.is_target(node)`, `rack.add_projectile(node)` (a `Node2D` with `step(dt)` and `is_done()`, drawn in `rack.draw_root` and freed once done or at a new run) and `rack.depth` (the minions' depth-order rule, `enemy_depth.gd`, for the `z_index` of anything drawn in the isometric view).
- **Upgrades from code** (the level-up offers them: "The level-up offers" below): `run.weapons.upgrade("gun")` applies the gun's next tier; `run.weapons.gun.set_tier(t)` sets any tier; `run.weapons.owned_ids()` lists the owned weapons; `run.weapons.get_weapon(id).tier` and `.is_max_tier()` say where each stands.

**Targets** (the minions and the kaiju, see "The kaiju"): every node in the group `enemies` inside the run that has `take_damage(amount: float)` and is not dead (`is_dead()`, when it has one; nodes queued for deletion are skipped). Each must have `position_units()` (its centre, flat world, units). Its size comes from `hit_radius_units()` when it has one, otherwise from its first `CollisionShape2D` (a circle's radius; half the diagonal of a rectangle; the larger of a capsule's radius and half height), otherwise 0.5 units. So **the kaiju needs only to join the group `enemies` and have `take_damage()` and `position_units()`**; if its body is not a circle, giving it `hit_radius_units()` makes hits match its size. Range is measured centre to centre (the target's size does not count, as in the prototype); hits use the target's size. Nothing here reads `run.minions` or uses collision layers, so meteors (on layer 3 but without `take_damage`) are never targeted.

**The starting gun** (`starting_gun.gd`, `weapon_id` `gun`): `stats` is `WeaponData.gun_at(tier)` (plus `bullet_drawn_size` for the placeholder). `fire_clock` counts physics time; when it reaches `fire_interval()` (1.26 s at tier 1) it goes back to 0 and the gun looks for enemies within `stats.range` of the car's centre. None: nothing happens until the next check, one interval later (the gun checks only once per interval, so an enemy that walks in just after a check waits up to 1.26 s). Some: a volley of `stats.bullets` bullets, `delay_between_bullets` (0.05 s) apart. **Targeting rule** (the prototype's, Unity weapons report, section 2, "How it chooses and aims at a target"): the enemies in range sorted by distance, **closest first**; bullet 1 goes to the closest, bullet 2 to the second closest, and so on, going round them again from the closest when there are more bullets than enemies. Each bullet leaves the car's centre aimed at its target's centre at that moment, with no leading; a target that died before its bullet left is aimed at where it was last seen. `fired(bullet, target)` fires per bullet; `fire_at(aim_units, target = null)` fires one bullet by hand (tests and fixtures). `checks` and `volleys` count the checks and the volleys that fired.

**The bullet** (`bullet.gd`, a `Node2D` in `rack.draw_root`, node `WeaponShots`, just before the car's `View`): flies in a straight line in the flat world at `bullet_speed` (15 units/s), starting on the physics step after it was fired. After each move it hits every living enemy whose body comes within `bullet_hit_radius` (1 unit) of its centre, closest first, each enemy at most once: `take_damage(damage)` (2) and its `hit(enemy, damage)` signal. It is done after `1 + pierce_hits` hits (1; 2 at tier 8), or once it has flown `missed_bullet_max_travel` (the gun's range at its tier). No knockback, and it passes through walls and boulders, as in the prototype. It is drawn 0.5 units above the ground at its place in the isometric view, with the minions' depth-order rule; at the same depth the car is drawn over it, so a bullet comes out from under the car.

**Not in the data:** the bullet's drawn height (0.5 units), its placeholder colours and the 0.5-unit fallback target size are in the code (`bullet.gd`, `weapons.gd`): sizes and looks of the placeholder, not balancing numbers.

**Tests:** `tests/unit/weapons/test_starting_gun.gd`, part of the GUT suite: the rack in the run with the gun at tier 1 and its draw order; no shots with no enemy or one just out of range; shots at the data's interval (1.26 s) with an enemy in range; one check per interval; the closest enemy targeted and damaged by the data's amount (2), the others untouched; a minion killed through `take_damage`; the bullet's speed and its start at the car's centre; the 1-unit hit circle plus the minion's body; a missed bullet removed past the range; a volley going round the enemies closest first, 0.05 s apart; every tier's values equal to `WeaponData.gun_at()`; `upgrade()` through the tiers and not past the last; tiers 2 and 6 firing 3 and 5 bullets; tiers 3, 4 and 7 shortening the interval to the data's; tier 5 reaching 15 units; tier 8 piercing one enemy (tier 7 not); a new run (also one started from the main menu) back to the base gun with no projectiles; a non-minion enemy in the group (a stand-in for the kaiju) targeted and damaged; nothing firing while paused or after the run ends; and no Redgull red in the placeholder bullet.

### The exhaust flamethrower

Task T-042 (Weapon Behavior Agent): the exhaust flamethrower as Weapons, Decisions describes it, copying the Unity prototype's Flame Exhaust (Unity weapons report, section 3) with the board's fixes, and T-040's numbers (`data/weapons.json` through `WeaponData.flame_at(tier)`). What it does: `docs/weapons.md`, Content, "The exhaust flamethrower (built in task T-042)". The flames are placeholders (orange and yellow squares); the final flame art comes from a separate art task.

**See it:** with the playtest switch on (below), start the game (F5), press Start and drift (W or S held with A or D). Screenshot, from the repo root: `bash game/tools/screenshot.sh res://tests/fixtures/weapons/flamethrower_demo.tscn screenshots/flamethrower.png 90` (a run from the main menu, the car drifting in a circle with the flames behind it). Copies in `art-archive/T-042/screenshots/`.

**How it plugs in:** `scripts/weapons/flamethrower/exhaust_flamethrower.gd` extends `weapon.gd` (`weapon_id` `flamethrower`, `starts_owned` false) and is listed in `weapons.gd`'s `WEAPON_SCRIPTS`. The rack owns it (`run.weapons.flamethrower`, or `get_weapon("flamethrower")`), steps it once per physics step while it is owned (after the car has moved: the run's `PhysicsWorld` comes before `Weapons`), and resets it at every new run to tier 0, not owned (Weapons, Decisions). `run.weapons.upgrade("flamethrower")` gives it (0 to 1) and then applies its tiers, the call the level-up (T-043) will use; `set_tier(t)` sets any tier. `run.gd` has no flamethrower lines.

**Playtest switch:** `game/data/playtest.json`, key `"flamethrower_at_start"` (the file is a dictionary of independent switches). `true` makes the rack call `upgrade("flamethrower")` at the start of every run (`weapons.gd`, `reset_for_run()`), so the board can play it before the level-up offer exists; `false` is the game's rule (every run starts without it). Not player-facing. Tests override it with the script's static `playtest_override` (0 off, 1 on, -1 read the file).

**Each step while owned:** on while the car's drift state (`CarModel.is_drifting`) is on at `min_speed` or faster, then for `linger` seconds, or always from tier 8. The damage area is a rectangle behind the car (from `inner_edge`, `area_depth` deep, `area_width` wide at full size), starting each drift at `ramp_start_fraction` of full size and growing over `ramp_seconds` (`size_fraction()`, `area()`). An entering enemy takes one hit at once and flashes (its `sprite`'s `modulate` = the data's `burn_flash_tint` for `burn_flash_seconds`); every `tick_interval` every enemy inside takes one hit: `take_damage(stats.damage)`, signal `enemy_hit(enemy, amount)`. Tier 7 multiplies the car's `tuning.turn_speed` (a new run's car starts at its own speed). Values: `tier`, `stats`, `active`, `hits`, `is_burning(enemy)`.

**Targets:** `rack.living_enemies()`. **Inside** (board, 2026-10-14): an enemy that reports its body size with `hit_radius_units()` (the kaiju, T-045) is inside when its body (a circle of that radius) overlaps the rectangle at all (`overlaps_circle()`); any other enemy, such as the minions, when its centre (`position_units()`) is inside (`contains_point()`), as in the prototype.

**The drawing:** a `CPUParticles2D` (`scenes/weapons/flamethrower/exhaust_flame.tscn`, node `ExhaustFlame`), made the first time the flamethrower is owned and kept in the run's `View` just under the car sprite, at 0.42 units behind the car's centre (`EXHAUST_OFFSET_UNITS`), pointed backwards in the isometric view, scaled by the size multiplier times the ramp, emitting only while the flame is on. Its tuning is the Unity prefab's (18 particles, 0.45 s, an 18 degree cone, 2.2 to 5.2 units/s, 0.29 to 0.36 units), stepped orange-yellow colours with no fading, no Redgull red. The art task swaps the scene's texture and tuning; the code does not change. The drift smoke stays on with the flamethrower (board, 2026-10-14).

**Tests:** `tests/unit/weapons/test_exhaust_flamethrower.gd` (part of the GUT suite; test enemies `tests/fixtures/weapons/fake_enemy.gd` and `fake_big_enemy.gd`): on only while drifting and off after the linger, the minimum speed, the data's damage on entering and per tick inside and none outside, a big enemy burnt when its body overlaps the flames, the ramp, the same size in every direction, killing a real minion, the burn flash, nothing while paused, every tier's values and effects (size, damage, flash, steering, always on), a new run without it, the playtest switch, its place in the rack, the drawing's place and colours. `test_starting_gun.gd` turns the playtest switch off, so it checks the game's rule.

### The level-up offers

Task T-043 (Weapon Behavior Agent): which weapon choices a level-up gives and applying the one taken. What they do: `docs/weapons.md`, Content, "The level-up offers". Code: `scripts/weapons/level_up_offers.gd`, made by the rack in `bind()` as `run.weapons.offers` (node `LevelUpOffers`). It listens to `RunState.level_up_choice_started` (which only fires with `state.pause_on_level_up` on, the switch T-052 turns on).

**For the UI Agent (T-052):**

- **Choice ids** (constants on the script): `"upgrade_gun"`, `"get_flamethrower"`, `"upgrade_flamethrower"`. Show text by id.
- **Signal** `run.weapons.offers.offers_ready(level: int, offers: Array)`: the choice has started (the run is already paused). `offers` has 1 or 2 ids, the gun's first. Also readable at any time: `offers.current_offers` (empty when none waiting) and `offers.has_offers()`.
- **Function** `run.weapons.offers.choose(id: String) -> bool`: call it with the id taken. It applies the choice, emits `offer_taken(id)`, then calls `state.choice_made()` (which resumes the run, or starts the next waiting level-up's choice and a new `offers_ready`). Returns false and changes nothing for an id not on offer.
- **Nothing to offer** (both weapons at the last tier): the choice is skipped on its own, `state.choice_made()` is called at once and `offers_ready` is not emitted, so the screen never opens. The screen must not call `choice_made()` itself.
- `offers.compute_offers()` returns the ids for the current weapons without changing anything.
- A run that starts with the flamethrower (playtest switch `flamethrower_at_start`) offers `upgrade_gun` and `upgrade_flamethrower` from the first level-up.

**Tests:** `tests/unit/weapons/test_level_up_offers.gd`: the first offer, the offer after taking the flamethrower, each choice applied and the run resumed, refused ids, last-tier weapons not offered, skipping with nothing to offer, the playtest start, two level-ups at once, a new run.

## The kaiju

Task T-045 (Enemy Behavior Agent): Crash City's final boss as Enemies, Decisions describes it, with T-039's numbers (`kaiju` and, T-119, `kaiju_coins` in `data/enemies.json` through `EnemyData`). What it does: `docs/enemies.md`, Content, "The kaiju". A placeholder for now (a large dark slate green Godzilla-style shape drawn in code); the final art comes from a separate art task. Its meteor attack is task T-046.

**See it:** start the game (F5) and press Start, or open `scenes/run/run.tscn` and press F6. With the playtest switch on (below) the kaiju walks in from a screen edge 30 seconds into the run; the starting gun (and the flamethrower, with T-042's `flamethrower_at_start` on) can kill it, which wins the run. Screenshot, from the repo root: `bash game/tools/screenshot.sh res://tests/fixtures/kaiju_demo.tscn screenshots/kaiju.png 20` (the kaiju beside the car in the gravel square, with a few minions, in a run started from the main menu; fixture script `tests/fixtures/kaiju_demo.gd`). A copy is in `art-archive/T-045/screenshots/`.

**Playtest switch: early arrival.** The boss time is 7 minutes in, so for playtests `data/playtest.json` (its other keys are other tasks' switches) can bring the kaiju's arrival forward:

```
"kaiju_early_arrival": { "enabled": true, "after_seconds": 30 }
```

With `enabled` true, the kaiju arrives `after_seconds` into the run instead of at the boss time. **To switch it back, set `"enabled": false`**: the kaiju then arrives at the boss time (7 minutes in, 1:00 left) as Enemies and Game loop architecture decide. A missing file or key is off too. Only the kaiju's arrival moves: the clock, the minions' growth and the `boss_time` signal stay as they are, and a later `boss_time` brings no second kaiju. It is on (30 s) for the board's playtest of T-045 and is set back to `false` right before T-045 merges (board, 2026-10-14). `KaijuBoss.read_early_arrival_seconds()` (in `kaiju_boss.gd`) reads it into `run.kaiju_boss.early_arrival_seconds` (-1 = off) when the run is made. Tests set the static `playtest_override` in `kaiju_boss.gd` (-1 = off, seconds = on, -2 = read the file), as T-042's tests do for the flamethrower.

**How it is built** (`scripts/enemies/`):

- `kaiju_boss.gd`: the run's kaiju. The run scene adds it as `run.kaiju_boss` (child `Kaiju`) and calls `bind(run)`. On the state's `boss_time` it makes the kaiju appear (`try_appear()`; once per run). It moves everything in `step(dt)`, once per physics step from `_physics_process` (pausable, so the pause screen and the level-up pause stop the kaiju and its damage), and does nothing once the run is over. On `run.world_rebuilt` (a new run) it removes the kaiju; it arrives again at that run's boss time. `enabled = false` stops it (tests).
- `kaiju.gd`: the kaiju, a `CharacterBody2D` in the run's `PhysicsWorld` (flat world pixels, 16 per unit) on layer 3 (`enemies`) with mask 1 (obstacles): a circle of `RADIUS_UNITS` (2.0, so 4 units across). It slides along walls, buildings and boulders and walks round one it meets head-on, as a minion does; it never pushes or blocks the car. In the groups `enemies` and `kaiju` (not `minions`).
- `kaiju_sprite.gd`: the placeholder drawing in the isometric view, `HEIGHT_UNITS` (7) tall, facing left or right the way it walks.

**Arrival:** at a random point on `arrival_ring()`, the visible screen (the camera's view) grown so that the whole drawing, its ground circle and its height, is `OFFSCREEN_MARGIN_UNITS` (1) beyond the screen's edge, inside the map and clear of buildings and boulders (`is_free_spot()`; 24 tries a step, else it tries again on the next step). `appear_at(units)` puts it at a given place (tests, fixtures).

**Movement:** straight towards the car's centre at `move_speed` (3 units/s).

**Contact damage:** as a minion's: it touches the car when its circle overlaps the car's 1 x 1 unit body (`touches_car()`); while touching, it hits once every `contact_damage_interval` (1 s), the first hit at once: `RunState.damage_car(contact_damage)` (20; this also cuts the combo) and `car.apply_knockback(away from the kaiju, knockback)` (16 units/s).

**Damaging the kaiju (for the weapon tasks, T-041 and T-042):** exactly as a minion, so a weapon that finds minions finds the kaiju too: `take_damage(amount: float)` on the kaiju node, the same points as `health` (500). It can be damaged at any time, as soon as it has appeared (no shield, no vulnerability windows). Zero or negative amounts, and calls on a dead kaiju, are ignored. It is in the `enemies` group and its body on layer 3, so `get_tree().get_nodes_in_group("enemies")` and a projectile's `Area2D` with a mask of 4 find it; it has `position_units()`, `health`, `max_health` and `is_dead()` like a minion. It is much bigger than a minion, so it also has `hit_radius_units()`, its body on the ground as a radius in units (`RADIUS_UNITS`, 2.0, its collision circle; the minion's body is 0.5). The weapons read it ("Weapons", Targets): the gun's bullets hit when they come within their hit radius of its body, and the flamethrower counts any overlap of the flames with its body as a hit (board, 2026-10-14; minions keep the centre rule). Check `is_dead()` before damaging one found earlier in the same frame.

**Health, for the HUD:** `run.kaiju_boss.kaiju` is the live kaiju (null before it appears and after it dies). The boss relays everything a HUD needs, so it can connect once:

| Signal or function | Is |
| --- | --- |
| `kaiju_appeared(kaiju: Node)` | The kaiju appeared (just off-screen) |
| `kaiju_health_changed(health: float, max_health: float)` | Once when it appears (full health), then on every hit |
| `kaiju_defeated(coins: int)` | It died, with the coins it added |
| `kaiju_health()`, `kaiju_max_health()`, `has_appeared()` | Its health now (0 when there is none), its full health, and whether it has appeared this run |

The kaiju node itself sends `health_changed(health, max_health)` on every hit and `died(kaiju, position_units)` once.

**Death:** at 0 health the kaiju dies once: `died` fires, it leaves the groups `enemies` and `kaiju` at once, its drawing goes, and the node is freed at the end of the frame. The boss then adds its coins, `EnemyData.kaiju_coins_on_defeat()` (10), through `RunState.add_coins()`, **before** calling `RunState.kaiju_killed()`, which ends the run as a win; so `run_ended("win", coins)` carries the kaiju's coins and they are saved with the run.

**Draw order:** the kaiju's drawing is in the minions' draw node (`run.minions.draw_root`, the Y-sorted `Enemies` node just before the car's `View`), placed every physics step on its body in the isometric view with a `z_index` from `enemy_depth.gd` (the map's rule for the car, as for the minions, with the kaiju's size).

**Not in the data:** the kaiju's size (4 units across, 7 tall) and the off-screen margin are in the code: sizes and rules of the placeholder, not balancing numbers.

**Tests:** `tests/unit/enemies/test_kaiju.gd`, part of the GUT suite: no kaiju before boss time; boss time bringing it just off-screen, clear of obstacles, walking towards the car at the data's speed, once per run; walking round a building; weapon damage through `take_damage()` lowering its health as soon as it appears, with both health signals; a projectile-style physics query on the enemies mask finding it; damage to 0 adding its coins before the run ends as a win, `kaiju_killed()` called once; contact damage at the data's rate and knockback away from it; no damage without touching; standing still while paused and after the run ends; a new run removing it and boss time bringing it back; the collision layers; the draw order; the placeholder's size and no Redgull red; `hit_radius_units()` matching its body; the starting gun hitting it, the flamethrower burning it when only its body overlaps the flames, and the gun killing it winning the run with its coins; the playtest switch (arrival at its time, once, again in a new run), reading its key beside other keys, and the committed file keeping both switches.
