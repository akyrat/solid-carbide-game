---
id: T-110
title: The task board stops opening terminal windows
status: open
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
qa_rounds: 0
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

- [ ] `task_folders` in `tools/taskboard_sync.py` runs `git` with `subprocess.CREATE_NO_WINDOW` when `os.name == "nt"`, and with no extra flags otherwise. (QA: pass / fail)
- [ ] No other subprocess call in `tools/taskboard/server.py`, `tools/taskboard_sync.py` or `tools/task_status.py` (or in anything they import from `tools/`) starts a program without `CREATE_NO_WINDOW` on Windows; QA checks by searching those files for `subprocess`. (QA: pass / fail)
- [ ] `tools/test_taskboard_sync.py` has a test that fails if `task_folders` stops passing `CREATE_NO_WINDOW` on Windows (the test patches `os.name` and `subprocess.run`, so it runs on any system). (QA: pass / fail)
- [ ] `task_folders()` still returns this task's own folder for `T-110` when run from the task's folder. (QA: pass / fail)
- [ ] All three test sets pass: `python -m unittest discover -s tools -p "test_*.py"`, `python -m unittest discover -s game/tools -p "test_*.py"`, and the Godot tests as described in `game/README.md`. (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
