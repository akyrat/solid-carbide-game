---
id: T-161
title: The status guard stops refusing worktree cleanup and text that only mentions its fields
status: open
from: project-lead
to: project-lead
lead: Level-up
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, tools/guard_ledger.py, tools/test_guard.py, tasks/T-149-guard-qa-rounds-hand-edits.md]
files_expected_to_change: [.claude/hooks/board_gate.py, tools/test_guard.py, tasks/README.md if the wording changes]
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

The board asked for this quick fix (2026-10-17). T-149 (merged as `56fff52`) tightened the shell check in `.claude/hooks/board_gate.py`, and it now refuses parts of the Project Lead's normal routine. Seen on 2026-10-17, each refused with "Task statuses change only through the status script":

1. **Worktree cleanup after a merge:** `git merge-base --is-ancestor <branch> master && git worktree remove --force C:/solid-carbide-worktrees/T-149 && git branch -d <branch>` (also refused combined with a status-script call that only shows a ticket). Removing a merged task's folder and branch is part of every merge (`docs/working-with-the-board.md`, "Merging").
2. **Text that only mentions the guarded fields:** a command appending a timeline entry (a heredoc into `docs/timeline.md`) and committing, whose text named the QA-rounds field, `tasks/README.md` and "cd tasks" as words. It wrote no task file.

Do:
1. Reproduce both by calling the hook's functions with those commands (as `tools/test_guard.py` does); don't run them for real.
2. Fix the check so these pass, while every gap T-149 closed stays closed (all of `tools/test_guard.py` still passes). Removing a whole worktree or deleting a merged branch doesn't edit a ticket's lines; text written into a non-task file (heredocs, echo, commit messages) doesn't either.
3. Add a test for each command above, and for the Project Lead's full merge routine in `docs/working-with-the-board.md` ("Merging"), showing each step is allowed.

Don't change T-149's ledger rules. Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. If an action is refused, stop and report; don't route around it.

## Acceptance criteria

- [ ] Tests show both commands above are now allowed by the hook (QA: pass / fail)
- [ ] A test walks the Project Lead's merge routine (merge, regenerate the long GDD and fingerprint, timeline entry, commit, worktree and branch removal) and every step is allowed (QA: pass / fail)
- [ ] Every existing test in `tools/test_guard.py` still passes (T-149's gaps stay closed) (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
