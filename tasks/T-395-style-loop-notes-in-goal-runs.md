---
id: T-395
title: In a goal run, the style loop notes a score below 8 instead of flagging the ticket and pausing the goal
status: in-progress
from: project-lead
to: project-lead
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md, docs/working-with-the-board.md]
files_to_read_first: [tasks/README.md, docs/working-with-the-board.md, tools/style_loop/loop.py, tools/style_loop/run.py, tools/style_loop/test_loop.py, tools/goal_agent/build.py]
files_expected_to_change: [tools/style_loop/, tools/goal_agent/, tasks/README.md]
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

The board's decision (tasks/README.md, "The style loop", 2026-10-29; T-395). Goal runs already say art or text still below 8 after its refines "is noted for the final playtest" (docs/working-with-the-board.md, "Goal runs"), but the style loop's tool always moves the task to `flagged-for-review` (`tools/style_loop/loop.py`, the flag step), and the goal runner then can't move it to `in-qa` and pauses ("a command the runner ran was refused"). G-007 paused twice this way (T-381, T-383) and the Project Lead had to move each ticket back and resume by hand.

Fix: when the task's header has a `goal:` line (a goal run's ticket), the style loop doesn't flag: it keeps the best version as now, writes in the Style review and the result notes that it is kept below 8 and noted for the board's final playtest, leaves the status `in-progress`, and exits in a way the agent and the runner read as "kept, below 8, noted" (not a stop). Outside goal runs nothing changes. Check the goal runner (`tools/goal_agent/`) handles that result: the ticket goes on to QA. Don't touch the running goal G-007's folders or files.

Tools only; nothing in the game changes.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] With a fixture that never reaches 8 (`text-never-8.json`) on a task with a `goal:` line, the task stays in-progress and the Style review and result notes say the version is kept below 8 and noted for the final playtest (test). (QA: pass / fail)
- [ ] Without a `goal:` line the task is still moved to flagged-for-review as before (existing test). (QA: pass / fail)
- [ ] The goal runner's tests cover a ticket whose style loop kept a version below 8: it goes on to QA without a pause (test with the fake team). (QA: pass / fail)
- [ ] tasks/README.md ("The style loop") and docs/working-with-the-board.md ("Goal runs") agree with the behaviour. (QA: pass / fail)
- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, with the count in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started on your word: in a goal run the style loop will note a score below 8 instead of flagging and pausing the goal.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
