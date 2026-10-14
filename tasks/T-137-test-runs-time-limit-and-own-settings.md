---
id: T-137
title: Test runs end themselves when hung, and parallel runs don't share settings files
status: in-progress
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
qa_rounds: 0
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

- [ ] A test (or a script run QA can repeat) starts a GUT run with a deliberately hanging test and shows the runner stops it after the time limit and exits with a failure naming the limit, leaving no Godot process behind (QA: pass / fail)
- [ ] A list in the result notes names every test that writes under user://, and each now uses a per-run file or folder (QA: pass / fail)
- [ ] Two full GUT runs started at the same time from two different folders both pass, three times in a row (QA: pass / fail)
- [ ] `game/README.md` documents the time limit and the per-run test files (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
