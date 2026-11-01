---
id: T-487
title: Make the Godot test set run faster (it takes about 25 minutes now)
status: open
from: project-lead
to: qa-integration
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, game/tools/run_tests.sh, game/docs/setup/tests.md, tools/merge_batch.py, tools/qa_check.py]
files_expected_to_change: [game/tools/run_tests.sh, game/tools/, game/docs/setup/tests.md, tasks/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-11-01: the full Godot (GUT) test set takes about 20 to 25 minutes (2526 tests in 213 scripts; one run took 1445 s against the 1500 s limit) and grows with every ticket, and every QA round and merge pays it. Make it much faster without dropping a test.

First measure: the time per test script (GUT can report it, or time each script), and list the 15 slowest in the result notes with why (real-time waits, full run scenes, map building, physics stepping in real time). Then speed it up, in order of payoff, for example: running the test scripts in several Godot processes in parallel (split by script, each process headless, the results merged into one pass/fail and one count; the machine has 24 cores), and fixing the slowest tests' waits where a test waits on wall-clock time it could step instead (only if the test still checks the same thing). Keep `bash game/tools/run_tests.sh` as the one entry point with the same exit codes and summary, so qa_check.py, merge_batch.py and the goal runner keep working unchanged; a flag or env var picks the number of processes. A failing test must still fail the whole run, with its name and output shown.

Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes list the 15 slowest test scripts with their times and causes, before and after. (QA: pass / fail)
- [ ] A full run of `bash game/tools/run_tests.sh` passes with the same test count as master and takes well under half of master's time on this machine; both times are in the result notes. (QA: pass / fail)
- [ ] A deliberately failing test (in a temporary copy, not committed) makes the whole run fail with the test's name shown; the result notes show it. (QA: pass / fail)
- [ ] qa_check.py and merge_batch.py work unchanged with the new runner (their own tests pass). (QA: pass / fail)
- [ ] game/docs/setup/tests.md says how the parallel run works and how to set the number of processes. (QA: pass / fail)
- [ ] The tools and game/tools Python tests pass, with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
