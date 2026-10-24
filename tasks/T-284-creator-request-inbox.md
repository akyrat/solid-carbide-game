---
id: T-284
title: "A request inbox: the creator's asset requests reach a Project Lead session"
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
documents_affected: [docs/README.md, tasks/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/working-with-the-board.md, tools/board_inbox.py, tools/task_status.py, tasks/T-127-task-board-session-owners.md, tasks/T-215-goal-runner-and-qa-mark-fixes.md]
files_expected_to_change: [tools/, docs/README.md, tasks/README.md, .gitignore]
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

The board's decision (Level design, Decisions, "Asking for a new piece from the creator", 2026-10-24). The board asks for a new piece from inside the level creator (T-283). The request has to reach a Project Lead session, which writes an art ticket and starts the Asset Generation Agent. Build the inbox between them, the way the board's drags reach a session today (`tools/board_inbox.py`):

- **Where requests live:** one JSON file per request in a git-ignored folder in the main checkout, with the path written once in one place that the creator and the tools both read; your proposal.
- **What a request holds:** an id, the time, the kind (building, obstacle or decoration), the board's description word for word, an optional footprint, and a status: waiting, claimed (with the session and ticket), making, ready or failed (with a short reason). Write the format in `docs/README.md` so T-283 can write requests and read their status.
- **A command-line tool,** for example `python tools/creator_requests.py`, with these steps:
  - **list:** shows the requests.
  - **claim:** a session takes a waiting request. It is refused if another session took it first, as ticket claims are.
  - **set the status:** of a claimed request.
  - **The ticket:** claiming writes the new art ticket's id onto the request. The session writes the ticket itself, through the usual tools.
- **Reaching the session:** `board_inbox.py watch <session>` also prints one line for each new waiting request, so the session's watcher fires as it does for a drag. The hooks that hand over drags pass new requests the same way. A request is never handed over twice.
- **With no session open:** requests wait, and the next session to start sees them at the start.

Do not change permission settings (`.claude/settings.json`); if the tool needs a new pre-approved command, write that in the result notes for the Project Lead to bring to the board. Built from `master` on your own branch and folder (`tasks/README.md`, "Git branches"). Tooling only: it merges straight after QA.

## Acceptance criteria

- [ ] Tests show a request file written in the documented format is listed, claimed once (a second claim is refused), moved through its statuses, and that a bad file is reported, not crashed on (QA: pass / fail)
- [ ] Tests show `board_inbox.py watch` prints one line for a new waiting request and never prints the same request twice, and that the existing drag handling is unchanged (its tests pass unchanged) (QA: pass / fail)
- [ ] `docs/README.md` gives the folder, the format and the commands; `tasks/README.md` says how a session handles a request; all Python tool tests pass (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
