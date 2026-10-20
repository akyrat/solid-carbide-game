---
id: T-213
title: The guard refuses a script whose arguments write a task's header lines
status: done
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, tools/test_guard.py, tasks/T-212-board-drag-out-of-qa-and-guard-false-alarms.md]
files_expected_to_change: [.claude/hooks/board_gate.py, tools/test_guard.py, tasks/README.md]
model: sonnet
qa_rounds: 1
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

T-212's QA found a loosening in the guard (`.claude/hooks/board_gate.py`, `pre_shell`): a script run from a file is now judged by its own code, so a generic writer script passes even when its command-line arguments name a task file and carry a guarded header line, for example `python w.py tasks/T-1.md "status: done"` where `w.py` only writes `argv[2]` into `argv[1]`. The old guard refused it. The commit check still catches a changed header at commit time, but the command check should refuse it too.

Close the hole: refuse a script run whose arguments name a task file (or the tasks folder) and also contain a `status`, `qa_rounds` or `lead` header line or field name, with a message that says so. Keep T-212's two quoted read-only commands passing, and keep every other guard test passing.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line.

## Acceptance criteria

- [ ] A test feeds `pre_shell` the example above (with a real `w.py` that only writes its arguments) and the guard refuses it, naming the arguments as the reason (QA: pass - test_a_generic_writer_script_is_refused_by_its_arguments denies it with "its arguments name a task file")
- [ ] T-212's two quoted read-only commands still pass and every existing guard test still passes (QA: pass - tools.test_guard 44 tests OK; one existing case's expected reason changed to the arguments reason, still refused)
- [ ] `tasks/README.md` describes the rule in one sentence (QA: pass - one clause added to the shell-command paragraph)
- [ ] All Python tool tests pass (QA: pass - tools suite OK; game/tools 354 tests OK, 1 skipped)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Started: closing the guard loosening QA found in T-212.

### 2026-10-21, In progress → In QA

Built: the guard now refuses a script whose arguments name a ticket and carry a status, qa_rounds or lead line. Sent to QA.

### 2026-10-21, In QA → Done

QA passed all 4. Merged into master.

## Result notes

Written by the agent when it finishes.

- `board_gate.py`: new `script_args_reason`, called before `script_reason` in `why_risky`. A script run whose arguments (up to a shell comment) name a task file or the tasks folder and also hold `status`, `qa_rounds` or `lead` as a word is refused, with the reason "its arguments name a task file (...) and hold a `status` line or field name".
- `tools/test_guard.py`: new test `test_a_generic_writer_script_is_refused_by_its_arguments` (real `w.py` that only writes its arguments; `python w.py tasks/T-1.md "status: done"` denied, reason names the arguments; same file with a non-ticket path or without a field name still allowed). The existing `set2.sh lead Tools tasks/T-1-x.md` case now expects the arguments reason, since that rule fires first; it is still refused.
- `tasks/README.md`: one sentence added to the shell-command paragraph.
- T-212's two quoted read-only commands and all 44 guard tests pass; `tools` tests pass; `game/tools` tests pass (354 tests, OK, 1 skipped).
- Refused: one `python - <<EOF` edit script (inline code naming `tasks`), skipped; the same edits were made with the Edit tool instead. A later scratch debug script was also refused and abandoned.
- Nothing to picture: tooling only.
- 2026-10-21, in-qa → done: QA passed all 4; tooling, merged straight after QA
