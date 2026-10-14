---
id: T-137
title: Test runs end themselves when hung, and parallel runs don't share settings files
status: done
from: project-lead
to: qa-integration
lead: Enemies
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, game/README.md, game/tools/run_tests.sh, game/tools/run_tests.ps1, tasks/T-001-project-and-test-setup.md]
files_expected_to_change: [game/tools/run_tests.sh, game/tools/run_tests.ps1, the tests that write user:// files, tests, game/README.md]
model: sonnet
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Two problems with running the GUT suite, now that several task folders run it at the same time (board, 2026-10-15):

1. **Hung runs:** a test run that hangs (for example a test helper calling itself) keeps its Godot process alive, and an agent once had to kill it by hand. Give `run_tests.sh` and `run_tests.ps1` a time limit: a run that goes past it is stopped by the runner itself (only the Godot process that runner started), and the runner exits with a clear failure message naming the limit. Pick a limit comfortably above a normal full run (about 90 s today) and say it in `game/README.md`.
2. **Shared user:// files:** some tests (for example `test_camera_options.gd`, which writes `user://test_settings_t123.cfg`, and the zoom and pause camera tests) write files in Godot's user folder, which every worktree shares (`AppData/Roaming/Godot/app_userdata/Solid Carbide/`). Two runs at once overwrite each other's files, so tests fail at random. Make each test run use its own files, for example a per-run folder or file names that include the run's process id, cleaned up afterwards, so parallel runs from different folders never interfere. Find every test that writes under `user://`, not only the one named here.

Change no game behaviour and no game data. Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test (or a script run QA can repeat) starts a GUT run with a deliberately hanging test and shows the runner stops it after the time limit and exits with a failure naming the limit, leaving no Godot process behind (QA: pass)
- [ ] A list in the result notes names every test that writes under user://, and each now uses a per-run file or folder (QA: pass)
- [ ] Two full GUT runs started at the same time from two different folders both pass, three times in a row (QA: pass)
- [ ] `game/README.md` documents the time limit and the per-run test files (QA: pass)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass)

## Result notes

Time limit: **300 seconds** (a full run takes about 105 s, also with two at once). `game/tools/run_tests.sh` uses `timeout -k 5`; `run_tests.ps1` starts Godot with Start-Process and, past the limit, kills only that process tree (`taskkill /PID <its pid> /T /F`). Past the limit the runner prints `TIME LIMIT: the test run went past 300 seconds and was stopped ...` and exits 124. `GUT_TIME_LIMIT` (seconds) overrides it. Both runners applied to the import step too.

Repeatable check: `bash game/tools/check_time_limit.sh [seconds]` (default 10) runs GUT on `game/tools/hang_fixture/test_hang.gd` (an endless loop, outside `tests/`, so the normal suite never runs it). It checks exit 124, the message naming the limit, and that no Godot process with `hang_fixture` on its command line is left. Result: TIME LIMIT CHECK PASSED. The PowerShell runner was checked by hand the same way (limit 10 s, exit 124, message printed).

Tests that wrote under user:// (all now use `RunPaths.file(...)` from `tests/helpers/run_paths.gd`, which gives `user://test_runs/<process id>/<name>`; the folder is removed after the run by `tests/helpers/post_run.gd`, set as `post_run_script` in `.gutconfig.json`):
- test_camera_options.gd (test_settings_t123.cfg)
- test_pause_camera_controls.gd (test_settings_t124.cfg)
- test_pause_screen.gd (test_settings_t015.cfg)
- game/test_screen_flow.gd (test_settings_t055.cfg)
- hud/test_hud_layout.gd (test_settings_t113.cfg)
- run/test_run_combo.gd (test_settings_t081.cfg)
- test_drift_marks.gd (test_settings_t117.cfg)
- test_drift_smoke.gd (test_settings_t121.cfg)
- test_mvp_map_no_challenges.gd (test_settings_t097.cfg)
- test_car_sheets.gd (folder test_car_sheets, PNG files)
- test_drift_prototype.gd and test_tricks.gd (pointed GameSettings at a non-existent file; now per-run too)
- fixtures/pause_run_dynamic_demo.gd (screenshot demo, not in the suite; per-run too)
No other file under tests/ mentions user://. Tests restore `GameSettings.path` to `settings.cfg` as before and never write it. After runs, `user://test_runs/` is empty.

Parallel check: two full GUT runs at the same time, one from this folder and one from a temporary copy (game, docs, art-archive, .env) outside the repo, three rounds in a row: all six runs exit 0 (626 tests, 104 to 109 s each). A first attempt failed only because my copy lacked docs/; fixed by copying docs/. The copy is deleted.

Results: full GUT suite 626/626 pass (57 scripts); Python tests `game/tools` 241 OK (1 skipped), `tools` 171 OK. game/README.md has two new sections ("Time limit (T-137)", "Per-run test files (T-137)"). No game behaviour or data changed. Godot's line-ending-only .import changes left uncommitted.

### QA round 1 (QA/Integration, 2026-10-15, independent check)

- Criterion 1 pass: `bash game/tools/check_time_limit.sh` run by me: exit 124, message "went past 10 seconds", TIME LIMIT CHECK PASSED, no Godot process of the fixture left.
- Criterion 2 pass: grep of `user://` over game/tests on this branch finds only `tests/helpers/run_paths.gd`; all 12 tests/fixture in the list use `RunPaths.file(...)`; `user://test_runs` is empty after the runs. Gap, not part of this branch: master gained `game/tests/unit/enemies/test_kaiju.gd` (T-045) which writes `user://test_playtest_t045.json` outside RunPaths. It is the only master test that does. test_level_up_particles_art.gd and test_pixellab_assets.gd only read res:// files. The Project Lead should have it moved onto `RunPaths.file(...)` at merge (or in a small follow-up).
- Criterion 3 pass: three rounds of two simultaneous full runs (this folder and a temporary copy outside the repo): all six exit 0, 57 scripts, 626/626 each. Copy deleted.
- Criterion 4 pass: game/README.md has the 'Time limit (T-137)' and 'Per-run test files (T-137)' sections (300 s, GUT_TIME_LIMIT, RunPaths, post-run cleanup).
- Criterion 5 pass: full GUT 626/626 (in the parallel runs); Python tests game/tools 241 OK (1 skipped), tools 171 OK.
- No game behaviour or data changed: the diff against the merge base (aefa6b5) touches only tests, tests/helpers, .gutconfig.json, game/tools runners and fixture, game/README.md and this task file.
- 2026-10-15, in-qa → done: QA round 1: all criteria pass; note test_kaiju.gd on master still writes user:// outside RunPaths

After merging master (T-041, T-042, T-045, T-068, T-085): enemies/test_kaiju.gd (test_playtest_t045.json) now uses RunPaths.file too; no other user:// use under game/tests outside RunPaths. Full GUT 665/665 pass, Python tests game/tools 246 OK (1 skipped), tools 171 OK.
