---
id: T-437
title: Merges test once per batch, with a 1500 s Godot test limit
status: open
from: project-lead
to: qa-integration
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/working-with-the-board.md]
files_to_read_first: [tasks/README.md, docs/working-with-the-board.md, tools/merge_batch.py, tools/test_merge_batch.py, game/tools/run_tests.sh]
files_expected_to_change: [tools/merge_batch.py, tools/test_merge_batch.py, game/tools/run_tests.sh]
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

The board, 2026-10-31: merges take too long, and they now time out. The Godot test set takes about 890 s on its own (T-372's agent measured 889 s; the script's comment says 90 s at first and 270 to 306 s on 2026-10-21), so its 900 s limit (`game/tools/run_tests.sh`, GUT_TIME_LIMIT default) stops merges whenever the machine is busy: Audit's T-436 merge stopped on it (exit 124) with no test failing. And `tools/merge_batch.py` runs all three test sets after every ticket, about 20 to 25 minutes each, so a queue of six tickets takes two to three hours.

Two changes, both approved by the board:
1. The Godot set's default time limit becomes 1500 s (GUT_TIME_LIMIT still overrides it). Update the script's comment with today's timings.
2. merge_batch tests once per batch: it merges every ticket in the batch (each one still checked as today: no conflict, marked done, .import noise reverted, its own commit), runs the three test sets once on the result, and if they pass the whole batch is in. If they fail, it finds the ticket that broke them by testing ticket by ticket (or by halving the batch), keeps the tickets that pass, stops the one that fails with the reason, and leaves master clean and green as it does today. A ticket that conflicts stops on its own without stopping the others. Keep today's one-line-per-ticket output and the log file. Keep a flag for the old ticket-by-ticket mode.

Also, read only: list the 10 slowest Godot test files with their times in the result notes (GUT's own timings or a timed run), as data for the board on why the set has grown. Don't change any game test.

Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/tools/run_tests.sh` defaults to a 1500 s limit, GUT_TIME_LIMIT still overrides it (a test or a dry run shows both). (QA: pass / fail)
- [ ] merge_batch with several tickets runs the three test sets once when they all pass (tests with stubbed test runs count the runs: one per batch). (QA: pass / fail)
- [ ] When the batch's tests fail, merge_batch finds the breaking ticket, merges the others, stops only that one with its reason, and leaves master with no merge in progress and without the breaking ticket's commits (tests with stubbed runs and a temporary git repo). (QA: pass / fail)
- [ ] A ticket that conflicts stops on its own and the rest of the batch still merges (test). (QA: pass / fail)
- [ ] The old ticket-by-ticket mode is still there behind a flag (test). (QA: pass / fail)
- [ ] docs/working-with-the-board.md, "Merging (Project Lead)", describes testing once per batch and the flag. (QA: pass / fail)
- [ ] The 10 slowest Godot test files and their times are in the result notes. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
