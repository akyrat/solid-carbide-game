# Running the tests

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

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

### The parallel run (T-487)

A full run (`bash game/tools/run_tests.sh` with no extra arguments) is split over several headless Godot processes, because one process took 20 to 25 minutes. The script imports the project once, then `game/tools/run_tests_parallel.py` finds every `tests/**/test_*.gd`, deals the scripts into shards balanced by each script's last measured time (`game/tools/test_times.json`; a script not in it is weighed by its file size), and starts one Godot per shard with `-gconfig= -gtest=<its scripts>` plus the same pre and post run hooks as `.gutconfig.json`. Each process has its own process id, so `RunPaths` gives it its own `user://test_runs/<pid>/` folder and the processes never share a file.

- **Number of processes:** `GUT_JOBS=N bash game/tools/run_tests.sh` (default 12). `GUT_JOBS=1` runs the old single process, as does any extra argument (`-gselect=`, `-gunit_test_name=`, `-gtest=`): those filter inside one GUT run.
- **Output:** a shard that passed prints nothing; a shard that failed prints its whole GUT output (failing test names included) under `===== shard N FAILED =====`. Then one summary (`Scripts`, `Tests`, `Passing Tests`, `Failing Tests`, `Risky/Pending`, summed over all shards) and `TESTS PASSED`, or `TESTS FAILED (exit N)`.
- **Exit codes:** 0 all passed; the failing shard's GUT code otherwise; 124 time limit (`GUT_TIME_LIMIT`, applies to the whole run); 3 a script failed to parse or load; 4 a shard printed no summary (crashed).
- **New test scripts** need nothing: they are found by name. `python game/tools/run_tests_parallel.py --measure --jobs 8` (with `GODOT_BIN` set) times every script alone and rewrites `test_times.json`; do it now and then so the shards stay balanced (a stale table only costs speed, never correctness). `--list` prints the shards.
- A test that writes `user://` files must still use `RunPaths`; one that writes a fixed name would now collide between its own shards.
- `run_tests.ps1` is unchanged and still runs one process.

### Never call a method on a node that may be freed (T-281)

After an `await` (a frame, a timer), a node the game freed with `queue_free()` is gone. Calling any method on it, even `is_queued_for_deletion()`, can crash the whole engine (exit **139**, signal 11) instead of failing the test, and only in some runs, depending on whether its memory was reused. Always check `is_instance_valid(node)` first, for example `assert_true(not is_instance_valid(p) or p.is_queued_for_deletion())`, never the other way round. That is what made the suite crash at `test_it_goes_away_after_its_life` in `tests/unit/hud/test_combo_broken_popup.gd` in most runs before T-281.

### Time limit (T-137)

A run that goes past **1500 seconds** (900 before T-437) is stopped by the runner itself (only the Godot process it started, and its children), which prints `TIME LIMIT: the test run went past 1500 seconds and was stopped` and exits with code **124**. To change it, set `GUT_TIME_LIMIT` (seconds) for one run, for example `GUT_TIME_LIMIT=1200 bash game/tools/run_tests.sh`. To see the limit work, run `bash game/tools/check_time_limit.sh` (default 10 seconds): it runs GUT on `game/tools/hang_fixture/test_hang.gd`, a test that hangs forever on purpose and lives outside `tests/` so the normal suite never runs it, then checks the exit code, the message and that no Godot process is left behind.

### Per-run test files (T-137)

Godot's user folder (`AppData/Roaming/Godot/app_userdata/Solid Carbide/`) is shared by every task folder, so tests never write fixed names there. A test that needs a file under `user://` gets its path from `RunPaths.file("name")` (`tests/helpers/run_paths.gd`), which puts it in `user://test_runs/<process id>/`. Two runs at once have different process ids, so they never touch each other's files. The folder is removed when the run ends (`tests/helpers/post_run.gd`, set as `post_run_script` in `.gutconfig.json`); a run that is stopped by the time limit may leave its folder behind, and it is safe to delete. New tests that write under `user://` must use `RunPaths`.

### Tests never use the real save (T-148)

`user://progress.json` and `user://settings.cfg` are the player's real save, and tests never read, write or depend on them. Before the first test, `tests/helpers/pre_run.gd` (`pre_run_script` in `.gutconfig.json`) points `PlayerProgress.path` and `GameSettings.path` at empty test files in the run's `RunPaths` folder (`tests/helpers/test_save.gd`, `TestSave`). A test that changes those paths puts them back with `TestSave.restore()` (or `restore_progress()` / `restore_settings()`), never with `DEFAULT_PATH`. If a run ends with either path still on the real save, `post_run.gd` logs an error and fails the run.

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

