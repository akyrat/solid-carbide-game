---
id: T-297
title: "Ticket guard: a shell edit of a ticket's body passes when it can't write a guarded line"
status: in-progress
from: project-lead
to: project-lead
lead: Greenbull
epic: tooling
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, tools/guard_ledger.py, tools/test_guard.py]
files_expected_to_change: [.claude/hooks/board_gate.py, tools/test_guard.py, tasks/README.md]
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

The board's decision (2026-10-26): the ticket guard should let through edits of a ticket that don't touch its `status`, `lead` or `qa_rounds` lines, so the rule and the agents' practice match. During the Greenbull rebrand (T-294, T-295), agents twice had a `sed -i` on a ticket's body refused (fixing a typo in the result notes, ticking acceptance-criteria boxes) and then made the same edit with the Edit tool, which the guard allows. The edits were harmless, but redoing a refused action with another tool goes against the common rule (CLAUDE.md, "Common rules for every agent").

Today `.claude/hooks/board_gate.py` refuses every `sed -i` on a file that could be a ticket (tasks/README.md, "Changing a task's status": "a `sed` is judged by its scripts … only `-i`, `-f` or a `w` or `e` command is refused"). Change it so a `sed -i` on a ticket passes when the guard can read all of its scripts and none of them can write a guarded line: only `s` commands (and `d`, `a`, `i`, `c` with literal text) whose pattern, replacement and text don't name `status`, `qa_rounds` or `lead`, and whose address is not the header (a line range starting at 1, or an address that could match a line starting `status:`, `qa_rounds:` or `lead:`). Anything the guard can't read stays refused, as do `-f`, `w` and `e`. The second guard (`tools/guard_ledger.py`, checked on every `git commit`) stays as it is and still catches a guarded line changed by any tool.

Only `sed -i` is in scope; Python and PowerShell writes that name a task file stay refused.

## Acceptance criteria

- [ ] A `sed -i 's/teh/the/' tasks/T-012-x.md` and a `sed -i 's/- \[ \] The wordmark/- [x] The wordmark/' tasks/T-012-x.md` pass the hook, as new tests in `tools/test_guard.py` show. (QA: pass / fail)
- [ ] These stay refused, as tests show: a script naming `status`, `qa_rounds` or `lead`; an address range starting at line 1; `-f script.sed`; a `w` or `e` command; a script the guard can't read (from a variable or substitution). (QA: pass / fail)
- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes. (QA: pass / fail)
- [ ] `tasks/README.md`, "Changing a task's status", says which `sed -i` edits of a ticket pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-26, Open → In progress

Building it in this session, alongside T-296, so G-006 can finish.

## Result notes
