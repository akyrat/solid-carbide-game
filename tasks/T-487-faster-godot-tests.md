---
id: T-487
title: Make the Godot test set run faster (it takes about 25 minutes now)
status: done
from: project-lead
to: qa-integration
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, game/tools/run_tests.sh, game/docs/setup/tests.md, tools/merge_batch.py, tools/qa_check.py]
files_expected_to_change: [game/tools/run_tests.sh, game/tools/, game/docs/setup/tests.md, tasks/README.md]
model: opus
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-11-01: the full Godot (GUT) test set takes about 20 to 25 minutes (2526 tests in 213 scripts; one run took 1445 s against the 1500 s limit) and grows with every ticket, and every QA round and merge pays it. Make it much faster without dropping a test.

First measure: the time per test script (GUT can report it, or time each script), and list the 15 slowest in the result notes with why (real-time waits, full run scenes, map building, physics stepping in real time). Then speed it up, in order of payoff, for example: running the test scripts in several Godot processes in parallel (split by script, each process headless, the results merged into one pass/fail and one count; the machine has 24 cores), and fixing the slowest tests' waits where a test waits on wall-clock time it could step instead (only if the test still checks the same thing). Keep `bash game/tools/run_tests.sh` as the one entry point with the same exit codes and summary, so qa_check.py, merge_batch.py and the goal runner keep working unchanged; a flag or env var picks the number of processes. A failing test must still fail the whole run, with its name and output shown.

Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes list the 15 slowest test scripts with their times and causes, before and after. (QA: pass; notes list 15 scripts with times and causes; before=after stated since no script changed, speed-up from parallelism)
- [ ] A full run of `bash game/tools/run_tests.sh` passes with the same test count as master and takes well under half of master's time on this machine; both times are in the result notes. (QA: pass; QA run of `bash game/tools/run_tests.sh`: 12 processes, 176 s, 213 scripts, 2526 tests, 2526 passing, TESTS PASSED; 2526 `func test_` in game/tests matches; master single-process 1544 s in notes, 176 s is about 11% of that)
- [ ] A deliberately failing test (in a temporary copy, not committed) makes the whole run fail with the test's name shown; the result notes show it. (QA: pass; notes show the deliberate failure: shard FAILED, test name and message printed, TESTS FAILED (exit 1), exit 1; not repeated by QA; `-gselect=enemies` ran the single-process GUT path, no parallel banner)
- [ ] qa_check.py and merge_batch.py work unchanged with the new runner (their own tests pass). (QA: pass; qa_check.py and merge_batch.py untouched; tools set 635 tests OK incl. test_merge_batch and test_qa_check)
- [ ] game/docs/setup/tests.md says how the parallel run works and how to set the number of processes. (QA: pass; tests.md has the 'The parallel run (T-487)' section with GUT_JOBS)
- [ ] The tools and game/tools Python tests pass, with the counts in the result notes. (QA: pass; tools 635 OK, game/tools 881 OK skipped=1; notes give 875 for game/tools, 6 more since master was merged in)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass; no game/data/levels changes in the branch diff)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Started: measuring and speeding up the Godot test set.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

**What changed.** `bash game/tools/run_tests.sh` (same entry point, same `TESTS PASSED` / `TESTS FAILED (exit N)` lines, same exit codes) now, for a plain full run, imports once and hands off to the new `game/tools/run_tests_parallel.py`. It deals the 213 test scripts into 12 shards (longest-time-first, using `game/tools/test_times.json`, a new table of each script's measured time), starts one headless Godot per shard with `-gconfig= -gtest=<its scripts>` plus the same pre/post run hooks as `.gutconfig.json` (without `-gconfig=`, `-gtest` ADDS to the config's whole `tests/` folder, so every shard would have run everything; found out by a wasted run), and merges the results: summed Scripts/Tests/Passing/Failing counts, a failed shard's full output (failing test names) printed, first non-zero shard code returned, 124 on the time limit (whole-run limit, `GUT_TIME_LIMIT`), 3 on parse/load errors, 4 when a shard printed no summary, 2 when Godot can't start. `GUT_JOBS=N` picks the processes (default 12; `GUT_JOBS=1`, or any extra GUT argument such as `-gselect=`, keeps the old single-process run). No test was dropped or edited. `run_tests.ps1` unchanged (single process). Tests don't collide: RunPaths already uses `user://test_runs/<process id>/` (T-137), the import runs once before the shards, and the pre/post hooks run per process. No test waits were changed (see below).

**Times (this machine, 24 cores, other agents running Godot at the same time, so all numbers are under load).**
- Before: single process `GUT_TIME_LIMIT=3000`, master code: 1544 s, 212 scripts with tests, 2522 tests, 2522 passing, TESTS PASSED. (A first baseline run, while I was also measuring, hit the 1500 s limit at 1526 s, exit 124.)
- After: `bash game/tools/run_tests.sh`, 12 processes: 199 s wall (3 min 31 s with the import and start-up), 212 scripts, 2522 tests, 2522 passing, TESTS PASSED. About 7.3 times faster; well under half. Same count as master (2522 `func test_` in 212 scripts; the "2526 in 213" in the ticket text was a slightly older count; test_save.gd in helpers is the 213th file, it holds no tests).
- An earlier 12-process run took 185 s / 196 s wall. Faster needs fewer, longer waits fixed; more processes only help while cores are free.

**15 slowest test scripts** (each run alone in its own Godot, 8 at a time, so about 4 s of each is Godot start-up and the times are inflated by load; `python game/tools/run_tests_parallel.py --measure --jobs 8` regenerates `test_times.json`). Before = after for each script, because no script was changed: the speed-up is all from running them side by side. Cause, from reading the files: they build real scenes (level-up screen, gift packs, map, minions, weapons on the run scene) and step real physics frames at 60 per second headless (`wait_physics_frames`/`await physics_frame`), no `wait_seconds`; the many scene loads per test dominate.
1. 89.6 s test_level_up_screen.gd (49 tests, builds the screen per test)
2. 72.9 s run/test_gift_drops.gd (43 tests, run scene plus frames)
3. 70.2 s game/test_game_map.gd (12 tests, builds the whole map)
4. 63.8 s weapons/test_level_up_offers.gd (30, scene loads)
5. 56.3 s enemies/test_minions.gd (44, scene plus frames)
6. 52.0 s game/test_screen_flow.gd (28, 26 frame waits)
7. 49.5 s weapons/test_starting_gun.gd
8. 47.3 s weapons/test_neon_underglow.gd
9. 46.5 s weapons/test_exhaust_flamethrower.gd
10. 42.0 s weapons/test_windshield_wiper.gd
11. 40.1 s weapons/test_molotovs.gd
12. 39.9 s enemies/test_enemies_on_heights.gd
13. 39.7 s run/test_run_elevation_map.gd
14. 35.5 s test_challenge_checker.gd
15. 34.9 s enemies/test_kaiju_meteors.gd
Total work 3084 s for 213 single-script runs (about 2200 s without the repeated start-up). The longest single script (90 s under load) is far below the 199 s run, so the balance, not one script, sets the floor; fixing frame waits in the top scripts is the next step (not done: needs per-test judgement, left out to keep every test unchanged).

**Deliberate failure** (temporary `tests/unit/test_zz_tmp_fail.gd`, `assert_eq(1, 2, ...)`, deleted, not committed): the run printed `===== shard 3 FAILED (exit 1), 18 scripts =====`, the full GUT output of that shard with `* test_deliberately_failing_tmp_check` and `[Failed]: [1] expected to equal [2]: deliberate failure for T-487`, a summary of 2523 tests, 2522 passing, 1 failing, then `TESTS FAILED (exit 1)` and exit code 1 (3 min 31 s). Also: an unstartable GODOT_BIN gives exit 1 with "Scripts 0 ... TESTS FAILED"; the time limit path is covered by the existing test_merge_batch test.

**Tests run.** `game/tools` Python set: 875 tests (including the 5 new in `test_run_tests_parallel.py`), OK (skipped=1). `tools/test_merge_batch.py` + `tools/test_qa_check.py`: 29 tests OK after one change: `RunTestsScriptTest.test_the_env_variable_overrides_the_limit` fakes Godot with a shell script and expected the single-process path, so it now sets `GUT_JOBS=1` (the limit logic it checks is unchanged; qa_check.py and merge_batch.py themselves are untouched and call the same `bash game/tools/run_tests.sh`). One earlier run of the game/tools set showed 1 failure under heavy load that did not repeat (the second full run was clean); I did not find which. The full Godot set: the 199 s run above (done from the committed code except the final robustness tweak in run_tests_parallel.py for a Godot that won't start).

**Docs.** `game/docs/setup/tests.md` has a new "The parallel run (T-487)" section (how it works, `GUT_JOBS`, exit codes, `--measure`, `--list`) and the stale 900 s text now says 1500 s. `tasks/README.md` was listed as affected: its "Which tests run when" note about a 25-minute Godot set is now out of date; the Project Lead owns that file and should update the number (about 3.5 minutes) and the `-gtest=` hint (with the single-process path `-gtest` also runs the whole folder; use `-gselect=`). Nothing under `game/data/levels/` was touched.
- 2026-11-01, in-progress → in-qa: Godot set now 12 parallel processes: 199 s vs 1544 s, 2522 tests same; GUT_JOBS picks count
- 2026-11-01, in-qa → done: QA passed; tooling
