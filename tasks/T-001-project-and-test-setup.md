---
id: T-001
title: Set up the Godot project, headless runner and test suite
status: done
from: project-lead
to: qa-integration
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md, README.md]
files_to_read_first: [CLAUDE.md, README.md, game/README.md, tasks/_TEMPLATE.md, docs/game-loop-architecture.md]
files_expected_to_change: [game/project.godot, game/README.md, .gitignore, .env.example, the runner and test scripts this task creates]
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

`game/` has no Godot project yet. Every code agent must write and run tests, and QA/Integration must run the full suite before each playtest, so the project, a headless way to run Godot and a test framework must exist before any game work starts. The board decided QA/Integration owns this setup.

This task is technical scaffolding only. It adds no game content: no scenes, mechanics, art or sounds beyond what a sample test needs.

1. Create a Godot 4.6.2 project in `game/` with a folder layout for scenes, scripts, data (JSON), art and audio.
2. Godot is not on the PATH. The console executable on the board's machine is `C:\Tools\Godot\Godot_v4.6.2-stable_win64_console.exe`. Read its location from a `GODOT_BIN` variable in `.env` at the repo root, so the path is not hard-coded in scripts.
3. Add `.gitignore` at the repo root. It must ignore `.env`, the `.secrets/` folder, Godot's `.godot/` cache and other generated files. Add `.env.example` listing every expected variable with no real values: `GODOT_BIN`, `FREESOUND_CLIENT_ID`, `FREESOUND_API_KEY`, `FREESOUND_REDIRECT_URI`, `PIXELLAB_API_KEY`. The root `README.md` section "Secrets and API keys" describes these; add `GODOT_BIN` there.
   `.env` does not exist yet. Create `.gitignore` **first**, confirm `git check-ignore .env` prints `.env`, and only then create `.env` containing `GODOT_BIN` alone. Never write any other value into `.env`: the board adds its own credentials there after this task is done. If `.env` already exists when you start, do not overwrite it; only add `GODOT_BIN` if it is missing.
4. Install a GDScript test framework (GUT or gdUnit4, your choice; give the reason in the result notes) inside the project.
5. Provide one command, run from the repo root, that runs the whole test suite headless and exits with a non-zero code when any test fails.
6. Provide one script that runs a given scene for a set number of frames and saves a screenshot to a given path, so later visual criteria can be checked from an image.
7. Add one sample test that passes, to prove the pipeline works.
8. Document in `game/README.md` how to run the tests and take a screenshot, in a form other agents can follow without asking. For `.env` setup, link to the root README's "Secrets and API keys" section instead of repeating it.

## Acceptance criteria

QA/Integration checks its own setup in this task. Every criterion is mechanical, so the result is the same whoever runs it.

- [x] `game/project.godot` exists and reports Godot 4.6 as its engine version (QA: pass)
- [x] `.gitignore` exists at the repo root, and `git check-ignore .env .secrets/x` prints both paths (QA: pass)
- [x] `.env.example` exists and lists `GODOT_BIN`, `FREESOUND_CLIENT_ID`, `FREESOUND_API_KEY`, `FREESOUND_REDIRECT_URI` and `PIXELLAB_API_KEY` with no real values (QA: pass)
- [x] `.env` exists, is not tracked by git, and contains `GODOT_BIN` pointing to a file that exists (QA: pass)
- [x] No script contains the Godot path as a literal; it is read from `GODOT_BIN` (QA: pass)
- [x] The documented test command exits 0 with the sample test in place (QA: pass)
- [x] After a deliberately failing test is added temporarily, the same command exits non-zero; the failing test is then removed (QA: pass)
- [x] The screenshot script, run on a minimal scene, writes a non-empty PNG to the given path (QA: pass)
- [x] `game/README.md` documents the test command and the screenshot script, and links to the root README for `.env` setup (QA: pass)
- [x] The root README's "Secrets and API keys" section describes `GODOT_BIN` (QA: pass)

## Result notes

Written by QA/Integration (as the building agent) on 2026-10-04. The QA boxes above are left unticked for the separate QA pass.

### What was built

- A Godot 4.6.2 project in `game/` (`project.godot`, features `"4.6", "Forward Plus"`, the Godot default renderer). Folders: `scenes/`, `scripts/`, `data/`, `art/`, `audio/` (each with a `.gitkeep`), `tests/unit/`, `tests/fixtures/`, `tools/`, `addons/gut/`. No game content, no window size or resolution set (these are game decisions).
- `.gitignore` at the repo root (`.env`, `.secrets/`, `.godot/`, `/screenshots/`, export and OS clutter). It was created first, `git check-ignore .env` printed `.env`, and only then `.env` was created with `GODOT_BIN` alone (forward slashes: `C:/Tools/Godot/Godot_v4.6.2-stable_win64_console.exe`, works from both shells).
- `.env.example` with `GODOT_BIN`, `FREESOUND_CLIENT_ID`, `FREESOUND_API_KEY`, `FREESOUND_REDIRECT_URI`, `PIXELLAB_API_KEY`, all empty.
- The test runner and the screenshot tool, each in a Git Bash version (`.sh`) and a PowerShell 5.1 version (`.ps1`). Both read `GODOT_BIN` from the environment if set, otherwise from `.env` (shared helpers `godot_env.sh` and `godot_env.ps1`), and stop with exit 2 if it is missing or points to no file.
- Two test scripts: `test_sample.gd` (sample pipeline test) and `test_screenshot_tool.gd` (tests the screenshot tool's argument parsing). A fixture scene `tests/fixtures/screenshot_fixture.tscn` (two ColorRects) for checking the screenshot tool.

### Test framework: GUT 9.6.1

GUT was chosen over gdUnit4 because its command-line runner is a single plain GDScript (`gut_cmdln.gd`) that runs with `--headless`, reads one JSON config and exits 0/1 by itself, with no editor plugin or C# parts needed. That makes it the simplest thing for every agent to run from a shell. Version 9.6.1 is the GUT line for Godot 4.6: the newest GUT (9.7.1) fails to parse on 4.6.2 (it uses `AccessibilityServer`, which 4.6 does not have), and GUT itself recommends 9.6.1 when run on 4.6.2. GUT is MIT-licensed; its license is in `game/addons/gut/LICENSE.md`.

### Commands (run from the repo root)

- Tests, Git Bash: `bash game/tools/run_tests.sh`
- Tests, PowerShell: `powershell -ExecutionPolicy Bypass -File game/tools/run_tests.ps1`
- Screenshot, Git Bash: `bash game/tools/screenshot.sh <res://scene.tscn> <out.png> [frames]`
- Screenshot, PowerShell: `powershell -ExecutionPolicy Bypass -File game/tools/screenshot.ps1 <res://scene.tscn> <out.png> [frames]`
- Example: `bash game/tools/screenshot.sh res://tests/fixtures/screenshot_fixture.tscn screenshots/fixture.png 30`

### Files created or changed

Created: `.gitignore`, `.gitattributes`, `.env.example`, `.env` (git-ignored, not tracked), `game/project.godot`, `game/.gutconfig.json`, `game/{scenes,scripts,data,art,audio}/.gitkeep`, `game/addons/gut/` (GUT 9.6.1, unmodified), `game/tools/godot_env.sh`, `game/tools/godot_env.ps1`, `game/tools/run_tests.sh`, `game/tools/run_tests.ps1`, `game/tools/screenshot.sh`, `game/tools/screenshot.ps1`, `game/tools/screenshot.gd`, `game/tests/unit/test_sample.gd`, `game/tests/unit/test_screenshot_tool.gd`, `game/tests/fixtures/screenshot_fixture.tscn`, plus the `.uid` files Godot made for the scripts (they belong in git).
Changed: `README.md` (added a "Godot" subsection to "Secrets and API keys"; the uncommitted Freesound and PixelLab text was kept as it was), `game/README.md` (setup link, folder layout, test and screenshot instructions).

Documents affected: `game/README.md`, `README.md`. Both updated.

### Self-check (all ten criteria passed when I ran them; boxes left for QA)

1. `project.godot` has `config/features=PackedStringArray("4.6", ...)`. 2. `git check-ignore .env .secrets/x` prints both. 3. `.env.example` lists all five, empty. 4. `.env` is untracked, and `GODOT_BIN` points to an existing file. 5. No `.sh`/`.ps1`/`.gd` file under `game/` (including `addons/`) contains the Godot path. 6. The test command exits 0 (5 tests, 8 asserts), from a fresh `.godot/` too. 7. With a temporary failing test, it exits 1 in both shells; the test was removed after. 8. The screenshot tool wrote a 3705-byte 1152x648 PNG in both shells (the PowerShell run used a path with a space in it); I looked at the image and it shows the fixture correctly. 9 and 10. Documented as required.

### Things the board should know

- **Parse errors:** on its own, GUT skips a test file that fails to parse and still exits 0. Both runners scan the output for `Parse Error` / `Failed to load script` and then exit 3, so a broken test or game script can't pass quietly.
- **Screenshots need a window.** Headless mode has no renderer, so the screenshot tool briefly opens a real window (it worked here on Vulkan Forward+, RTX 5070). It can't run on a machine without a display or GPU.
- **Where screenshots go:** save them outside `game/` (the docs say `screenshots/` at the repo root, which is git-ignored). Godot imports any PNG inside `game/` as a project asset.
- **`.gitattributes` was not in the expected file list.** I added it because this repo has `core.autocrlf=true`. Without it, a fresh checkout would turn the `.sh` scripts' line endings into CRLF and break them in Git Bash. It contains only `*.sh text eol=lf`.
- The PowerShell runner sends Godot's output through `cmd.exe`. PowerShell 5.1 otherwise wraps a native program's error output in error records.
- The screenshot size is Godot's default window (1152x648) until a task sets the game's resolution.

### QA round 1

Independent check by a separate QA/Integration session on 2026-10-04. Everything was re-run from scratch; the builder's self-check was not relied on. All ten criteria pass.

Commands and outcomes (run from the repo root):

1. `game/project.godot`: `config/features=PackedStringArray("4.6", "Forward Plus")`, `config_version=5`.
2. `git check-ignore .env .secrets/x` printed `.env` and `.secrets/x`, exit 0.
3. `.env.example`: all five variables present, each empty. The only path in it is a comment example with a placeholder version (`Godot_vX.Y`).
4. `.env` exists, is one line (`GODOT_BIN=C:/Tools/Godot/Godot_v4.6.2-stable_win64_console.exe`), `git ls-files --error-unmatch .env` fails (untracked), and the target file exists.
5. `grep -rniE 'C:[/\]+Tools|Godot_v4'` over the repo (excluding `.env`, `.git`, `.godot`, `docs/`): no hits in any `.sh`, `.ps1` or `.gd` file. Hits only in `README.md` (the documented example), `.env.example` (a comment) and this task file. All tool scripts get the path from `GODOT_BIN` via `godot_env.sh` / `godot_env.ps1`.
6. `bash game/tools/run_tests.sh`: exit 0, 2 scripts, 5 tests, 5 passing, 8 asserts. `powershell -ExecutionPolicy Bypass -File game/tools/run_tests.ps1`: exit 0, same totals.
7. Added a temporary `game/tests/unit/test_qa_tmp_fail.gd` (`assert_eq(1, 2)`): Git Bash exit 1, PowerShell exit 1, both "6 tests, 1 failing". Removed the file and the `.uid` Godot generated for it; the Git Bash run then exited 0 again. `git status` matches the pre-QA state.
8. `bash game/tools/screenshot.sh res://tests/fixtures/screenshot_fixture.tscn screenshots/qa_t001_fixture.png 30`: exit 0, wrote a 3705-byte 1152x648 RGB PNG (Vulkan Forward+). Viewed it: dark navy 640x360 rectangle top-left with a pink 100x100 square at (270,130), on Godot's grey clear colour, matching the fixture scene. `screenshots/` is git-ignored; the image was left there for reference.
9. `game/README.md` has "Running the tests" (both shells) and "Taking a screenshot" (both shells, with an example), and links to `../README.md#secrets-and-api-keys`.
10. The root README's "Secrets and API keys" has a "Godot" subsection describing `GODOT_BIN`.

Observations for the Project Lead (not failures):

- `.gitattributes` is not in `files_expected_to_change`. It contains two comment lines explaining why, plus the single rule `*.sh text eol=lf` (so "only `*.sh text eol=lf`" is true apart from the comments). `git check-attr eol` confirms `lf` for the `.sh` scripts. The reason given (repo has `core.autocrlf=true`) is sound.
- The screenshot tool was checked only from Git Bash in this round; the PowerShell `screenshot.ps1` was read but not run. The criterion asks for one working script, so this does not affect the result.
- The runners also fail (exit 3) on any `Parse Error` / `Failed to load script` text in Godot's output. Good safeguard, but a future test that deliberately loads a bad script would trip it.
- Nothing is committed yet: all T-001 files are still untracked or modified in the working tree.
