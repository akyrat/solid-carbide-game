---
id: T-449
title: The status script lets board-approved art go straight to the board's playtest
status: in-progress
from: project-lead
to: qa-integration
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, tasks/_TEMPLATE.md, tools/task_status.py, tools/test_task_status.py, tools/new_ticket.py, tools/merge_batch.py, tools/qa_check.py]
files_expected_to_change: [tools/task_status.py, tools/test_task_status.py, tools/new_ticket.py, tools/test_new_ticket.py, tasks/_TEMPLATE.md, tasks/README.md]
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

The board, 2026-10-31 (tasks/README.md, "QA", "Art the board has already approved skips QA and the tests"): art the board has already seen and approved goes from the agent straight to the board's playtest, with no QA round and no tests. The status script doesn't know this yet: for T-445 (the board's own splash) it refused in-progress → needs-playtest, then refused done until QA had marked every criterion, so the Project Lead had to check and mark the criteria by hand and go through in-qa.

1. A ticket header field that marks a ticket as board-approved art, for example `board_approved_art: yes` (default no), written by tools/new_ticket.py from the JSON input and present in tasks/_TEMPLATE.md.
2. For such a ticket, task_status.py allows in-progress → needs-playtest directly, without QA marks, and needs-playtest → done without QA marks (the board's LGTM is the check). Every other ticket keeps today's rules exactly.
3. merge_batch.py: a board-approved-art ticket merges without running the test sets even when `--no-tests` isn't given, and its line says so.
4. tasks/README.md ("QA" and "Changing a task's status") describes the field and the shortened path.

Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test shows a ticket with `board_approved_art: yes` can move in-progress → needs-playtest → done with no QA marks, and that the same moves are still refused for a ticket without it. (QA: pass / fail)
- [ ] A test shows new_ticket.py writes the field from its JSON input, defaulting to no, and tasks/_TEMPLATE.md has it. (QA: pass / fail)
- [ ] A test (with stubbed test runs) shows merge_batch.py runs no test sets for a board-approved-art ticket and runs them as before for others. (QA: pass / fail)
- [ ] tasks/README.md describes the field and the shortened path. (QA: pass / fail)
- [ ] The tools and game/tools Python tests pass (`python -m unittest discover -s tools -p "test_*.py"`, `python -m unittest discover -s game/tools -p "test_*.py"`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Open → In progress

Started: the QA/Integration Agent builds it in C:\solid-carbide-worktrees\T-449.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Built (QA/Integration Agent, T-449):
- tasks/_TEMPLATE.md: new header line `board_approved_art: no` plus its comment line. tools/new_ticket.py: the `"board_approved_art"` key (default no) is accepted and written.
- tools/task_status.py (`allowed`): a ticket with `board_approved_art: yes` may go in-progress -> needs-playtest once result notes exist, with no QA marks and no QA round. needs-playtest -> done already needed no marks. Other tickets are unchanged.
- tools/merge_batch.py: reads the field from the ticket on its branch; a round made only of such tickets runs no test sets (also with --each, per ticket); a batch that also holds an ordinary ticket is tested as before. The ticket's line reads "merged (board-approved art: no test sets run)".
- tasks/README.md: "Changing a task's status" (the shortened path) and "QA" (the field) describe it.
- Tests: tools/test_task_status.py (BoardApprovedArt, 3 tests), tools/test_new_ticket.py (1), tools/test_merge_batch.py (BoardApprovedArtTest, 4, with stubbed counting test commands), tools/goal_agent/temp_repo.py (approved_art option).
- Test results: `python -m unittest discover -s tools -p "test_*.py"` Ran 599, OK. `python -m unittest discover -s game/tools -p "test_*.py"` Ran 767, OK (skipped=1).
- Nothing under game/data/levels/ was touched.
- Not done: the mixed-batch case runs the tests for everyone (by design); the guard hook refused inline python that names tasks, so I used the Edit tool instead.
