---
id: T-110
title: The task board stops opening terminal windows
status: done
from: project-lead
to: project-lead
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, tools/taskboard/server.py, tools/taskboard_sync.py, .claude/hooks/board_gate.py]
files_expected_to_change: [tools/taskboard_sync.py, tools/test_taskboard_sync.py]
model: sonnet
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

While the task board page is open, a terminal window pops up every 2 seconds on the board's screen and takes the focus from whatever window the board is using (board, 2026-10-13).

Cause: the session hook starts the server as a background process with no console (`.claude/hooks/board_gate.py`, `ensure_server`). The page asks the server for `/api/version` every 2 seconds, and the server answers by running `git worktree list` (`tools/taskboard_sync.py`, `task_folders`). On Windows, a console program started from a process without a console gets a new console window of its own, unless it is started with the `CREATE_NO_WINDOW` flag. That call doesn't pass it.

Fix: start `git` (and any other program the server runs while serving the page or a drag) with `CREATE_NO_WINDOW` on Windows, and nothing changed on other systems. Add a test that would have caught it.

The board's review: start the task board from this task's folder, keep the page open at http://localhost:8765 for a minute, drag one card, and confirm no terminal window appears.

Board review files: none (run `python tools/taskboard/server.py` from `C:\solid-carbide-worktrees\T-110`, or let the session hook start it).

## Acceptance criteria

- [ ] `task_folders` in `tools/taskboard_sync.py` runs `git` with `subprocess.CREATE_NO_WINDOW` when `os.name == "nt"`, and with no extra flags otherwise. (QA: pass)
- [ ] No other subprocess call in `tools/taskboard/server.py`, `tools/taskboard_sync.py` or `tools/task_status.py` (or in anything they import from `tools/`) starts a program without `CREATE_NO_WINDOW` on Windows; QA checks by searching those files for `subprocess`. (QA: pass)
- [ ] `tools/test_taskboard_sync.py` has a test that fails if `task_folders` stops passing `CREATE_NO_WINDOW` on Windows (the test patches `os.name` and `subprocess.run`, so it runs on any system). (QA: pass)
- [ ] `task_folders()` still returns this task's own folder for `T-110` when run from the task's folder. (QA: pass)
- [ ] All three test sets pass: `python -m unittest discover -s tools -p "test_*.py"`, `python -m unittest discover -s game/tools -p "test_*.py"`, and the Godot tests as described in `game/README.md`. (QA: pass)

## Result notes

Done by the Project Lead (2026-10-13).

- `tools/taskboard_sync.py`: new `no_window()` returns the `CREATE_NO_WINDOW` flag (0x08000000) on Windows and 0 elsewhere; `task_folders` passes it to its `git worktree list` call. That is the only subprocess call in `server.py`, `taskboard_sync.py` and `task_status.py`. The hook's own start of the server (`.claude/hooks/board_gate.py`) already used `CREATE_NO_WINDOW`.
- `tools/test_taskboard_sync.py`: two tests patch `os.name` and `subprocess.run`: on `nt` the flag is passed (and the worktree listing is still parsed), elsewhere it is 0. With the fix stashed, the test file fails; with it, it passes.
- `task_folders()` run in this folder returns `{'T-110': C:\solid-carbide-worktrees\T-110}`.
- Tests: `tools` 106 OK; `game/tools` 111 OK; Godot 307 of 307 passing (`TESTS PASSED`, exit 0). Godot's `.import` line-ending noise from the test run is left uncommitted.

### QA (QA/Integration, 2026-10-13, round 1)

- 1 pass: `task_folders` passes `creationflags=no_window()`, which is 0x08000000 on `nt` (equal to `subprocess.CREATE_NO_WINDOW`, checked) and 0 otherwise.
- 2 pass: searched `server.py`, `taskboard_sync.py`, `task_status.py` for `subprocess`, `Popen`, `os.system`, `os.popen`, `startfile`, `spawn`, `webbrowser`; the only process start is the `git worktree list` call. Their only imports from `tools/` are `taskboard_sync` and `task_status`.
- 3 pass: with `creationflags=no_window()` removed from the call, both new tests fail (7 run, 2 failures); with the fix restored, they pass.
- 4 pass: `task_folders()` run from this folder returns `C:\solid-carbide-worktrees\T-110` for `T-110`.
- 5 pass: `tools` 106 OK; `game/tools` 111 OK; Godot 307 of 307 passing, `TESTS PASSED`, exit 0. Godot's `.import` line-ending changes left uncommitted.
- 2026-10-13, needs-playtest → done: Board: LGTM (2026-10-13)
