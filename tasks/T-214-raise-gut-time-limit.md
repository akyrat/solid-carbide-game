---
id: T-214
title: The GUT test run's time limit fits the suite's size
status: in-qa
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, game/tools/run_tests.sh, game/tools/run_tests.ps1, game/README.md]
files_expected_to_change: [game/tools/run_tests.sh, game/tools/run_tests.ps1, game/README.md, tools/goal_agent/]
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

The full GUT suite now takes about 270 to 306 seconds when the computer is busy with several agents, and `game/tools/run_tests.sh` and `run_tests.ps1` stop it at 300 seconds and report it as failed. T-071's QA failed only on this (2026-10-21), and T-069's and T-070's agents had to run with `GUT_TIME_LIMIT=900`. Their comments still say "a normal full run takes about 90 s".

Raise the default limit to 900 seconds in both scripts, keep `GUT_TIME_LIMIT` as the override, and correct the comments with today's run times. If anything else passes a 300-second GUT limit (for example the goal runner's prompts or QA instructions under `tools/goal_agent/`), update it the same way. Don't change any test.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line.

## Acceptance criteria

- [ ] Both scripts default to 900 seconds, `GUT_TIME_LIMIT` still overrides it, and their comments give today's run times (QA: pass; both default 900, override kept, comments give 270-306 s)
- [ ] The full GUT suite passes with the default limit in this folder (QA: pass; default-limit run passed in 336 s wall (320 s GUT), over the old 300)
- [ ] `game/README.md` states the limit and the override (QA: pass; README Time limit states 900 s and GUT_TIME_LIMIT override)
- [ ] All Python tool tests pass (QA: pass; tools OK, game/tools 355 tests OK (1 skipped))

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Started: the test suite's time limit goes from 300 to 900 seconds.

### 2026-10-21, In progress → In QA

Built: the limit is now 900 s, with GUT_TIME_LIMIT as the override. Sent to QA.

## Result notes

Written by the agent when it finishes.

- `run_tests.sh` and `run_tests.ps1` now default to 900 seconds; `GUT_TIME_LIMIT` still overrides. Their comments give today's run times (about 270 to 306 s when busy, about 90 s at first). `game/README.md` ("Time limit") states 900 s, the run times and the override (example now 1200).
- Nothing under `tools/goal_agent/` or `.claude/agents/` passes a 300-second GUT limit (searched), so nothing else changed. No test changed.
- Full GUT run with the default limit: passed, 393 s wall-clock (the computer was busy; it would have failed at 300).
- `python -m unittest discover -s tools -p "test_*.py"`: OK. `... -s game/tools ...`: 355 tests, OK (1 skipped).
- Nothing to picture (no visuals). No command was refused.
