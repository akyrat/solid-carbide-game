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
| `tools/` | Test runner, screenshot tool and shared shell helpers. Not game code |
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
