---
id: T-363
title: Every run's recap stats are saved on this computer
status: open
from: project-lead
to: game-data
lead: Greenbull
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: [T-319]
documents_affected: [docs/game-loop-architecture.md, game/docs/]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/scripts/data/player_progress.gd, tasks/T-319-run-stats-for-the-recap.md]
files_expected_to_change: [game/scripts/data/, game/scripts/run/, game/tests/unit/, game/docs/, docs/game-loop-architecture.md]
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

The board's decision (Game loop architecture, Decisions, "The runs list", 2026-10-29): "record the different stats from each recap screen for each run ... they're saved locally." When a run ends, add its recap summary (T-319's) to a run history saved under `user://` (like `player_progress.gd`'s `user://progress.json`, in its own file), with the date and time it ended, the result (win, loss by health, loss by time), the time survived, the coins and the likes. Keep every run (a cap, for example the last 200, is your proposal). Expose a read-only list, newest first, for the runs list screen. A missing or broken file starts an empty history without crashing. Tests point the file at `RunPaths.file(...)` (T-137). Nothing the player sees changes in this ticket.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] After a scripted run ends, the history file holds one more entry with T-319's summary, the end time, the result, the time survived, the coins and the likes (test). (QA: pass / fail)
- [ ] The list is read back newest first after a restart of the game (a new instance reading the same file), and a missing or broken file gives an empty list without errors (tests). (QA: pass / fail)
- [ ] Game loop architecture and the game docs describe the history, its file and its fields. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
