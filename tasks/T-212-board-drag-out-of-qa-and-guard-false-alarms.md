---
id: T-212
title: The board's drag can take a ticket out of QA with a warning, and the guard stops refusing read-only commands
status: open
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md, docs/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, tools/task_status.py, tools/taskboard/server.py, .claude/hooks/board_gate.py, tasks/T-181-guard-refuses-only-guarded-header-writes.md]
files_expected_to_change: [tools/task_status.py, tools/taskboard/, .claude/hooks/board_gate.py, tools/test_*.py, tasks/README.md, docs/README.md]
model: opus
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

Two fixes the board asked for (2026-10-20), after two false refusals and a ticket stuck in QA.

**1. The board's drag out of QA.** Today `task_status.py` refuses every move out of `in-qa` except to `cancelled` until QA has marked every acceptance criterion pass or fail, whoever moves it. T-102 went to QA only for the board to judge a sample; no QA marks were coming, so it can't go back to In progress. The board's words: it shouldn't be assumed that an agent has marked all the criteria; when the board drags a ticket whose criteria aren't all marked, the board gets a pop-up warning that says exactly which criteria haven't been marked, with a place to write an explanation of what has gone wrong, which is added to the ticket.

- A **drag by the board** (`by="board"`) from `in-qa` to `in-progress` or `planning` is allowed even when criteria are unmarked. It doesn't count as a QA round (`qa_rounds` unchanged).
- Before the move, the task board shows a pop-up listing each unmarked criterion word for word (and any marked fail), with a text box for the board's explanation and buttons to go ahead or cancel. Going ahead makes the move; the explanation goes into the ticket's result notes the way a drag's note does today, and reaches the owning session with the move as `(note: ...)`.
- Moves by the command line (agents and the Project Lead) keep today's rule: refused while criteria are unmarked.
- Other refused drags keep working as they do today.

**2. The guard's false refusals.** `.claude/hooks/board_gate.py` (`pre_shell`) refuses any shell command that seems to touch `tasks` and contains the word "status" or runs an interpreter, even when nothing writes to a task file. Two real cases it refused:
- `bash game/tools/run_tests.sh | grep ...; python -m unittest discover -s tools -p "test_*.py"; python -m unittest discover -s game/tools -p "test_*.py"; git status --short | grep -v import | head` (QA of T-209)
- an inline Python step that only read PNG images to measure a heading, in a command whose PixelLab client call listed task files in `--consulted` (T-102)

Make the guard refuse only commands that can write a task file's `status`, `qa_rounds` or `lead` line (as T-181 did for the Write and Edit tools), and let read-only and test commands through: `git status`, `git diff`, `git log`, the test runs, `grep`/`cat` of task files, and scripts that only read. Keep refusing everything it refuses today that does write those lines, including inline code that writes task files. When unsure, it may still refuse, but its message says what in the command made it refuse.

This changes a hook. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture except the pop-up: end with a screenshot of it.

## Acceptance criteria

- [ ] `task_status.py` with `by="board"` moves an `in-qa` ticket with unmarked criteria to `in-progress` and to `planning`, keeping `qa_rounds`, and writes the board's explanation into the result notes; the command line still refuses the same move; tests cover both (QA: pass / fail)
- [ ] Dragging such a ticket on the task board shows a pop-up listing the unmarked criteria word for word, with an explanation box, go-ahead and cancel; cancel leaves the ticket as it was (screenshot of the pop-up, and a server test for the endpoint the pop-up uses) (QA: pass / fail)
- [ ] The guard lets the two commands quoted in the description through (tests feeding them to `pre_shell`), and still refuses every case the existing guard tests refuse (QA: pass / fail)
- [ ] `tasks/README.md` ("Changing a task's status") and `docs/README.md` ("The task board") describe the new drag and the guard's rule (QA: pass / fail)
- [ ] All Python tool tests pass (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
