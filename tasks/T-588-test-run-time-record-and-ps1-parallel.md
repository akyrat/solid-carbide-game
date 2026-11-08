---
id: T-588
title: The test runner records each full run's wall-clock time, and run_tests.ps1 runs the same parallel split
status: blocked
from: project-lead
to: qa-integration
lead: Tests
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, game/docs/setup/tests.md, game/tools/run_tests_parallel.py, game/tools/run_tests.sh, game/tools/run_tests.ps1, game/tools/test_run_tests_parallel.py, game/tools/test_times.json, tools/merge_batch.py, tools/qa_check.py]
files_expected_to_change: [game/tools/run_tests_parallel.py, game/tools/run_tests.ps1, game/tools/test_run_tests_parallel.py, game/tools/, game/docs/setup/tests.md, tasks/README.md]
model: opus
qa_rounds: 0
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

Why (board, 2026-11-08): when asked how long the tests take, the agents answer with the single-process time (the sum of game/tools/test_times.json, about 51 minutes) instead of the real parallel run (275 s on 12 processes in last night's merge logs), because the only timing record in the repo is the single-process per-script table and nothing in it says so, and because run_tests.ps1 still runs one process. Two changes, both tooling the player never meets.

1. The record of the real run. After every full parallel run (bash game/tools/run_tests.sh with no GUT arguments), run_tests_parallel.py writes a small record of that run: the date and time, the wall-clock seconds of the whole run (import included, as the runner measures it), the number of processes (GUT_JOBS), the summary counts (scripts, tests, passing, failing, risky/pending) and whether it passed. Where: propose either a sibling file game/tools/test_run_record.json (keep only the last run, or the last few) or a clearly named key in test_times.json that load_times() and weight() skip; the per-script values in test_times.json are labelled as single-process seconds (a comment key, the docstring and tests.md). The runner's final summary line also prints the wall time and the process count, for example `TESTS PASSED (275 s on 12 processes)`, so every result note and merge log carries the real number. The --measure output says its times are single-process. Nothing in the run itself changes: same shards, same exit codes, same time limit.

2. run_tests.ps1 runs the same split as run_tests.sh: import once, then run_tests_parallel.py with GUT_JOBS (default 12, 1 = the old single process) and the 1500 s default limit (GUT_TIME_LIMIT overrides it), the same exit codes (0, GUT's, 124, 3, 4) and the same TESTS PASSED / TESTS FAILED lines, and any extra GUT argument still filters inside one process as in the .sh. Its stale comment about run times goes; it points at the record instead. Keep the PowerShell 5.1 rules (no &&, no ternary). If sharing the Python runner from PowerShell needs a Python lookup, do it the way run_tests.sh does.

Docs: game/docs/setup/tests.md (The parallel run) describes the record, says the per-script table is single-process and that run_tests.ps1 now runs in parallel; tasks/README.md, Which tests run when, points at the record for the current run time instead of quoting a number. No agent definition changes. Tests: test_run_tests_parallel.py covers the record (written after a run, skipped by the shard weights, the summary line's wording); the .ps1 is checked by running it (see the criteria).

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, Handing back). Never write, move or change anything in game/data/levels/. No PixelLab calls. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] After `bash game/tools/run_tests.sh` with no arguments, a record of that run exists where tests.md says (date and time, wall-clock seconds, number of processes, the five summary counts, passed or not), and its wall-clock seconds are within a few seconds of the run's real duration. (QA: pass / fail)
- [ ] The runner's final line names the wall time and the process count, for example `TESTS PASSED (275 s on 12 processes)`, and the merge script and qa_check.py still recognise TESTS PASSED and TESTS FAILED (their tests pass). (QA: pass / fail)
- [ ] The record never changes the shards: `python game/tools/run_tests_parallel.py --list` prints the same shards before and after a run writes the record, and the per-script table's values and their single-process meaning are labelled in the file or its docstring and in tests.md. (QA: pass / fail)
- [ ] `powershell -ExecutionPolicy Bypass -File game/tools/run_tests.ps1` with no arguments runs the parallel split (its output names the process count), prints TESTS PASSED and exits 0 on a green tree, in about the same time as run_tests.sh, not the single-process time; `GUT_JOBS=1` and an extra GUT argument such as `-gselect=test_sample` run one process as the .sh does. (QA: pass / fail)
- [ ] run_tests.ps1 keeps the time limit (default 1500 s, GUT_TIME_LIMIT overrides it) and the exit codes 124 (limit), 3 (parse or load error) and 4 (a shard printed no summary), as documented in tests.md. (QA: pass / fail)
- [ ] `python -m unittest game.tools.test_run_tests_parallel` passes with new tests for the record and the summary line; the tests for the changed code pass (the agent), and QA's full run passes. (QA: pass / fail)
- [ ] tasks/README.md (Which tests run when) and game/docs/setup/tests.md (The parallel run) describe the record and the parallel .ps1 and no longer quote the 25-minute single-process time as the current one. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: the QA/Integration Agent builds the run record and the parallel run_tests.ps1 in C:\solid-carbide-worktrees\T-588.

### 2026-11-08, In progress → Blocked

Built and committed (run record, final line with wall time and process count, parallel run_tests.ps1, docs); master merged in. Blocked on T-589: the full Godot run hangs in the shard that ends with test_garage_button_pulse.gd then test_bricks_widest_perf.gd, a hang that also hit a merge run on master last night. T-588 goes to QA once T-589 is fixed.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

BUILT (commits 20b05e9c, eb8d7b10 on task/T-588): run_tests_parallel.py writes game/tools/test_run_record.json after every full parallel run (git-ignored, latest run only; keys time, wall_seconds, processes, scripts, tests, passing, failing, risky_pending, passed). Final line is now 'TESTS PASSED (N s on P processes)' / 'TESTS FAILED (exit C, N s on P processes)', printed last. test_times.json has a '_note' key (single-process seconds); load_times() skips '_' keys; --measure says its times are single-process. run_tests.sh leaves the final line to the runner on the parallel path. merge_batch.py and qa_check.py go by exit code, unchanged (their 33 tests OK). run_tests.ps1 imports once, then runs run_tests_parallel.py with GUT_JOBS (default 12, 1 = single), limit 1500 (GUT_TIME_LIMIT), same exit codes; extra GUT args keep one process. Docs updated: game/docs/setup/tests.md, tasks/README.md. Proposal: record is git-ignored (tracked would dirty the tree and conflict on merges). CHECKED: unittest test_run_tests_parallel 9 OK; --list identical before/after (12 shards); ps1 -gselect=test_sample: one process, TESTS PASSED, exit 0; ps1 GUT_TIME_LIMIT=40: 12 parallel processes, exit 124, 'TESTS FAILED (exit 124, 41 s on 12 processes)'. BLOCKED: two full run_tests.sh runs (25m23s, 25m09s) both hit the 1500 s limit, record passed=false, though all reported tests passed (2887/2887): shard 6 hangs after tests/unit/test_garage_button_pulse.gd (T-573 test, added 2026-11-08 01:08) with 'Unreferenced static string to 0: Physics2DConstraintSolveIslands' and prints no GUT summary; reproduced running shard 6 alone. Not caused by T-588 (no game or test code touched). Full ps1 run not done (same hang). Green-run record and line wording unverified in a full pass.
