---
id: T-425
title: merge_batch.py crashes printing on the Windows console, and drive_elevation_sample.sh stops before driving
status: in-progress
from: project-lead
to: qa-integration
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, tools/merge_batch.py, game/tools/drive_elevation_sample.sh, game/tools/drive_elevation_sample.gd]
files_expected_to_change: [tools/merge_batch.py, tools/, game/tools/drive_elevation_sample.gd, game/tools/]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Two tooling bugs found on 2026-10-30.

1. `tools/merge_batch.py` crashed with `UnicodeEncodeError: 'charmap' codec can't encode character '\u2192'` when it printed a ticket's result line (`print(f"{tid}: {line}")`, about line 288) holding task_status's arrow ("in-qa → done"), because the Windows console uses cp1252. The batch stopped with the rest of its tickets not merged. The Project Lead now runs it with PYTHONIOENCODING=utf-8 as a stopgap. Make the script's own output safe on a cp1252 console (for example reconfigure stdout to UTF-8 with errors replaced, at start), and check the other tools that print task_status's lines the same way (task_status.py itself, qa_check.py, board_inbox.py) for the same crash.

2. `game/tools/drive_elevation_sample.sh` (the T-195 drive from the command line) stops at `prepare` with `Nonexistent function 'set_physics_process' in base 'Nil'` at `drive_elevation_sample.gd:89` (scene.car is null) and ends "FAIL: never on height 3", before any driving. It fails the same way on master at efbde4c6 (checked by QA on T-411), so it is older than T-411; the same drive passes inside GUT (`test_drive_elevation_sample`). Find why the car isn't there in the command-line run and fix the script.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test runs merge_batch's output path with a cp1252 stdout and a line holding "→", and it doesn't crash (named in the result notes); the same check for every other tool found printing task_status lines, or a note that it's safe. (QA: pass / fail)
- [ ] `bash game/tools/drive_elevation_sample.sh` runs to its end on master and drives onto height 3 (its output in the result notes), with the cause of the null car written down. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started: tooling, merges after QA.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Agent notes (builder):

- Bug 1: `merge_batch.py` now calls `safe_output()` (stdout and stderr reconfigured to UTF-8, errors replaced) at the start of `main`. `qa_check.py` had the same gap; its `main` now calls `tb.utf8_output()`. `task_status.py` and `board_inbox.py` already did, so they are safe. Test: `ConsoleEncodingTest` in `tools/test_merge_batch.py` runs with PYTHONIOENCODING=cp1252: the crash without the fix, the arrow printed with `safe_output()`, and the other three tools checked.
- Bug 2 cause: in a `-s` script the root is not ready during `_initialize`, so the scene's `_ready` (which creates `scene.car`) has not run when `prepare()` was called; the car was null. GUT's tree is already ready, so the test passed. Fix in `game/tools/drive_elevation_sample.gd`: `prepare()` runs on physics frame 1 (the drive still starts at frame 3).
- Drive output now: layers 0, 3 at 1.82 s, 6 at 5.40 s, 0 at 7.28 s; max height 6.85; "PASS: the street, height 3 and height 6 reached, and the car landed off the height-6 edge", exit 0.
- Tests (after merging master): `game/tools` python 752 OK (1 skipped); `tools` python 585 OK; `run_tests.sh` 2172/2172 passing, TESTS PASSED.
