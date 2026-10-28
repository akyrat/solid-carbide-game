---
id: T-354
title: Token spend: the guard refuses only commands that really write a ticket
status: open
from: project-lead
to: project-lead
lead: Tokens
epic: token-spend
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, tools/test_guard.py, tasks/T-348-guard-read-only-commands-again.md, tasks/T-349-a-guard-against-very-large-shell-output.md, docs/token-spend/after-2026-10-28-early.md]
files_expected_to_change: [.claude/hooks/board_gate.py, tools/test_guard.py, tasks/README.md]
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

The board's go (2026-10-28), from the token-spend early read: hook refusals rose to 4.3% of calls (baseline 1.2%), and most were false alarms from the ticket guard in `.claude/hooks/board_gate.py`. It refuses a command when its text merely names task files or contains a header word like `Lead`, even when the command writes no ticket. Three agents then redid the refused edit with the Edit tool (T-343, T-347, T-348), which the board's rule against working around refusals forbids. Fewer false refusals keeps that rule strict and saves the failed calls.

Real refusals from 2026-10-28 (seven) to reproduce in tests:
- `python tools/merge_batch.py T-350 ... --entry T-350="... written by the Project Lead ..."`: refused because an argument names a task and holds the word `Lead`. merge_batch.py writes tickets only through task_status.py.
- An inline `python -` edit of `tools/merge_batch.py` whose script text mentions `tasks` (T-347): refused, though it wrote only a tools file.
- Inline python or sed editing `.claude/agents/*.md` (T-343): refused for the same reason.
- A read-only `python -c` that opened a ticket to read it (T-347): refused.
- `grep ... ; date +%H:%M`: refused because of `date`.
- A read-only loop over `tasks/T-*.md` that used a shell `case $s in done|cancelled) continue;; esac` to skip finished tickets: refused (`case`: a command the guard can't tell won't write a ticket).
- `git rev-parse -q --verify MERGE_HEAD || { git add docs/timeline.md tasks/...md && git commit -m ... }`, the shared-master commit guard from docs/working-with-the-board.md: refused because of the `{` grouping.

Make the guard tell a real write of a ticket's guarded fields (status, lead, qa_rounds) apart from a mention:
- Allow the repo's own tools that change tickets only through `task_status.py` (`merge_batch.py`, `new_ticket.py`, `qa_check.py`, `task_status.py`) whatever their argument text says.
- Allow inline scripts and sed whose write targets are not task files, even if the text mentions tasks.
- Allow read-only commands such as `date`.
- Keep refusing anything that writes a task file's status, lead or qa_rounds outside task_status.py (cp, mv, redirection, sed -i or a script writing a `tasks/T-*.md` path), and anything the guard really can't read.

If the guard can't be sure whether a script writes a ticket, it still refuses: false refusals are cheaper than an unrecorded status change. Say which cases stay refused, and why. Nothing to picture. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `tools/test_guard.py` has a test for each of the seven real refusals in the description: each command is now allowed, with the refusal text from before named in the test. (QA: pass / fail)
- [ ] Tests show the guard still refusing: a `cp` or `mv` onto a `tasks/T-*.md` file, a redirection into one, `sed -i` on one, an inline script that writes a `tasks/T-*.md` path, and an edit of a ticket's status, lead or qa_rounds outside task_status.py. (QA: pass / fail)
- [ ] Every guard test that existed before still passes, unchanged unless the result notes say why. (QA: pass / fail)
- [ ] `tasks/README.md` says in one place what the guard refuses and what it allows, and the result notes list the cases that stay refused with the reason. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
