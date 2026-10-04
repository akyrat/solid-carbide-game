# Game

The Godot 4 project lives here: scenes, scripts, data (JSON), art and audio. Everything for the game, in the same repository as the documents.

## Setup

The engine is Godot 4.6.2. The scripts below find it through `GODOT_BIN` in `.env` at the repo root. To set that up, see [Secrets and API keys](../README.md#secrets-and-api-keys) in the root README.

## Folder layout

| Folder | What goes in it |
| --- | --- |
| `scenes/` | Scenes (`.tscn`) |
| `scripts/` | Game GDScript (`.gd`) |
| `data/` | Game data as JSON |
| `art/` | Sprites, tilesets and other images |
| `audio/` | Sound effects and music |
| `tests/unit/` | GUT test scripts (`test_*.gd`), in subfolders if you like |
| `tests/fixtures/` | Scenes and files that exist only for tests |
| `tools/` | Test runner, screenshot tool, audio import checker, Freesound downloader, PixelLab client and shared shell helpers. Not game code |
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
