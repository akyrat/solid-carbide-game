---
id: T-143
title: The status hook stops blocking read-only commands that mention "status:"
status: open
from: project-lead
to: project-lead
lead: Playtest
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, tools/task_status.py]
files_expected_to_change: [.claude/hooks/board_gate.py, its tests, tasks/README.md]
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

The board asked for this (2026-10-16). The shell check in `.claude/hooks/board_gate.py` (`pre_shell`) refuses any shell command that names a task file (`tasks/T-NNN`) and contains `status:` or `qa_rounds:`, so status lines change only through the status script. It also refuses commands that only read, for example `grep -n "^status" tasks/T-052*.md` or `sed -n '2,12p' tasks/T-058*.md | grep status:`. The Enemy Behavior Agent and the Project Lead were both stopped this way on 2026-10-15 and 2026-10-16 while only reading.

Keep blocking commands that could write a task file's status or qa_rounds line (for example `sed -i`, redirection `>` or `>>` into a task file, `tee`, `perl -i`, Python or PowerShell writes). Let read-only commands through (`grep`, `rg`, `sed -n` without `-i`, `head`, `tail`, `cat`, `awk` without redirection into a task file, `Select-String`, `Get-Content`). When unsure, keep blocking: a false refusal costs a retry, a missed write breaks the workflow rules. The PowerShell tool goes through the same check.

## Acceptance criteria

- [ ] Tests show read-only commands that name a task file and mention `status:` are allowed: `grep -n "^status:" tasks/T-001-x.md`, `sed -n '1,10p' tasks/T-001-x.md | grep "status:"`, `head -5 tasks/T-001-x.md` with `grep qa_rounds:` (QA: pass / fail)
- [ ] Tests show writing commands are still refused: `sed -i 's/status: open/status: done/' tasks/T-001-x.md`, `echo "status: done" >> tasks/T-001-x.md`, a `python -c` that writes a task file's status, a PowerShell `Set-Content` on a task file with `status:` (QA: pass / fail)
- [ ] The existing hook tests still pass, and the status script still works from the main checkout and from a task's folder (QA: pass / fail)
- [ ] `tasks/README.md` says read-only commands may mention the status line (QA: pass / fail)
- [ ] All Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
