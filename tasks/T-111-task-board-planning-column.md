---
id: T-111
title: A Planning column on the task board
status: open
from: project-lead
to: project-lead
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md, tasks/_TEMPLATE.md, docs/README.md, WORKING-WITH-THE-BOARD.md]
files_to_read_first: [tasks/README.md, docs/README.md, tools/task_status.py, tools/taskboard/taskboard.html, .claude/hooks/board_gate.py]
files_expected_to_change: [tools/taskboard_sync.py, tools/task_status.py, tools/test_task_status.py, tools/taskboard/taskboard.html, .claude/hooks/board_gate.py, tasks/README.md, tasks/_TEMPLATE.md, docs/README.md, WORKING-WITH-THE-BOARD.md]
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

The board wants a **Planning** column on the task board, between To do and In progress (board, 2026-10-13). When the board mentions a ticket in conversation, it drags it there, and it refines the ticket with the Project Lead until the ticket's open questions are answered. Then the ticket moves on to In progress.

What to build:

- A new status, `planning`, for a ticket being refined with the board. It is optional: a ticket can still go straight from To do to In progress.
- Moves (in `tools/task_status.py`):
  - `open` or `blocked` to `planning`, always. A blocked ticket can be refined before what it waits on is finished.
  - `planning` to `in-progress`, only when every task in `depends_on` is `done`, as from `open`.
  - `planning` to `open` or `blocked`, and to `cancelled` (with a note, as for every cancel).
  - `in-progress` to `planning`, to go back to refining.
- The task board page: a fifth lane, "Planning", between "To do" and "In progress", in its own colour. Dropping a card there moves it to `planning`. The lane layout fits five lanes on a wide screen and still wraps on narrow ones. The Inbox lists planning tickets under "Needs you", with a line saying the ticket is being refined with the Project Lead.
- The hook (`.claude/hooks/board_gate.py`): when the board moves a ticket to `planning`, the message to the Project Lead says to read the ticket and bring its open questions to the board.
- Docs: the status rules in `tasks/README.md` ("Status rules" and "Changing a task's status"), the status list in `tasks/_TEMPLATE.md`, the board's description in `docs/README.md` ("The task board", now five lanes), and in `WORKING-WITH-THE-BOARD.md` ("The task board"): what the Project Lead does with a ticket moved to Planning.

The board's review: open the task board at http://localhost:8765, check that the Planning column sits between To do and In progress, drag a ticket into it, and check that the Project Lead picks it up and brings its open questions.

Board review files: none (the task board, started from `C:\solid-carbide-worktrees\T-111` with `python tools/taskboard/server.py`).

## Acceptance criteria

- [ ] `planning` is in `STATUSES` in `tools/taskboard_sync.py`, and `tools/task_status.py` allows exactly the moves listed in the description to and from `planning`. Tests in `tools/test_task_status.py` cover each of them, including that `planning` to `in-progress` is refused while a dependency isn't done. (QA: pass / fail)
- [ ] The page's lanes are, in order: To do, Planning, In progress, then the existing last lanes. Planning holds only `planning` tickets, and its drop target is `planning`. QA checks this in `tools/taskboard/taskboard.html` and by fetching `/api/tickets` from a running server with one test ticket moved to `planning` and back. (QA: pass / fail)
- [ ] The board layout has five columns above 900 px wide, and still wraps to two and then one column on narrower screens (QA checks the CSS). (QA: pass / fail)
- [ ] The Inbox's "Needs you" folder includes `planning` tickets (QA checks the page's code). (QA: pass / fail)
- [ ] The hook's message for a move to `planning` tells the Project Lead to read the ticket and bring its open questions to the board (QA checks `describe_moves` by running it on a sample move). (QA: pass / fail)
- [ ] `tasks/README.md`, `tasks/_TEMPLATE.md`, `docs/README.md` and `WORKING-WITH-THE-BOARD.md` describe the Planning status and column as built. (QA: pass / fail)
- [ ] All three test sets pass: `python -m unittest discover -s tools -p "test_*.py"`, `python -m unittest discover -s game/tools -p "test_*.py"`, and the Godot tests as described in `game/README.md`. (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
