# Taking a screenshot

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

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

