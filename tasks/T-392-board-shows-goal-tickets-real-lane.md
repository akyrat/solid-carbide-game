---
id: T-392
title: Bug: the task board shows a running goal's tickets in To do instead of their real lane
status: in-qa
from: project-lead
to: project-lead
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, tools/taskboard/server.py, tools/goal_agent/build.py, tools/test_taskboard_server.py]
files_expected_to_change: [tools/taskboard/, tools/test_taskboard_server.py, docs/README.md]
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

The board's decision (docs/README.md, The task board, "A goal's tickets show their real lane", 2026-10-29; a bug). The board: G-007 "looks like it's not running on the taskboard, like it's in the to do column". The server is meant to read each ticket from its open task branch (docs/README.md: "The server reads them, and the open task branches"), but G-007's tickets show master's copy (status open, so To do) while their folders say otherwise: at the time of writing, `C:\solid-carbide-worktrees\T-381` and `T-382` hold `needs-playtest`, and `T-383` is being built. Find why the server doesn't pick up a goal run's ticket folders (for example the goal runner's branch names or folder layout differ from what the server's lookup expects, or a ticket that was merged into `playtest/<goal id>` and whose folder is kept) and fix it so every ticket with an open folder shows that folder's status, goal runs included; a goal's ticket already merged into its build branch shows the status in that build (`C:\solid-carbide-worktrees\<goal id>`) when its own folder is gone. Don't change any ticket file, and don't touch the running goal's folders (read only).

Tools only; nothing in the game changes.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test with a temporary repository sets up a goal run's ticket folder (branch named the way tools/goal_agent names it) holding a status different from master's, and /api/tickets returns the folder's status (fails before the fix, named in the result notes). (QA: pass / fail)
- [ ] A goal ticket merged into the goal's build folder, with its own folder removed, shows the build's status (test). (QA: pass / fail)
- [ ] Ordinary tickets' folders still work as before (existing tests pass). (QA: pass / fail)
- [ ] docs/README.md, The task board, describes where a ticket's status is read from, goal runs included. (QA: pass / fail)
- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, with the count in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started on your word: fixing the task board so a running goal's tickets show in their real lanes.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Cause: a ticket with an open folder was already read from it (the runner's `task/<file stem>` branches match the lookup; against the live G-007 the running server returned needs-playtest for T-381/T-382 and flagged-for-review for T-383). The gap was a goal ticket merged into `playtest/<goal id>` whose own folder is gone: it fell back to master's copy (open, To do) although the build holds the real status. So criterion 1's test passes before the fix too (it guards the folder case); the build-fallback tests fail before it.
Fix: `taskboard_sync.build_copy` and a `builds` argument to `tickets_now`; the server passes `build_folders()` (worktrees on `playtest/G-NNN`) in /api/tickets and /api/goals, and `version()` hashes the build copy so the page refreshes. Only tickets with a `goal:` line use a build. Docs: docs/README.md, The task board.
Tests: 3 new (GoalTicketLaneTests, real temporary git repo); full suite `python -m unittest discover -s tools -p "test_*.py"`: 576 tests, OK.
