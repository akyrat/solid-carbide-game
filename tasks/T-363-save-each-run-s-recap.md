---
id: T-363
title: Every run's recap stats are saved on this computer
status: done
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

The board's decision (Game loop architecture, Decisions, "The runs list", 2026-10-29): "record the different stats from each recap screen for each run ... they're saved locally." When a run ends, add its recap summary (T-319's) to a run history saved under `user://` (like `player_progress.gd`'s `user://progress.json`, in its own file), with the date and time it ended, the result (win, loss by health, loss by time), the time survived, the coins and the likes. Keep every run (a cap, for example the last 200, is your proposal). Expose a read-only list, newest first, for the runs list screen. A missing or broken file starts an empty history without crashing. Tests point the file at `RunPaths.file(...)` (T-137). Nothing the player sees changes in this ticket.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] After a scripted run ends, the history file holds one more entry with T-319's summary, the end time, the result, the time survived, the coins and the likes (test). (QA: pass)
- [ ] The list is read back newest first after a restart of the game (a new instance reading the same file), and a missing or broken file gives an empty list without errors (tests). (QA: pass)
- [ ] Game loop architecture and the game docs describe the history, its file and its fields. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started (build C): the Game Data Agent is saving every run's recap stats on this computer for the runs list.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Built by the Game Data Agent.

- New `game/scripts/data/run_history.gd` (`RunHistory`), modelled on `PlayerProgress`: `user://run_history.json` (`{"runs": [...]}`), static `path` for tests, `add_run(recap, ended_unix)`, `runs()` (copies, newest first), `count()`, `connect_run(state)` (listens only to `run_ended`, saves `state.recap()` once, no timing dependence). Entry = T-319's recap + `ended_at` (local) + `ended_unix`. A recap with no result is ignored. Missing or broken file = empty history.
- Hook: `GameFlow.history` (created in `_ready`) is passed to `GameFlow.add_run(parent, progress, layout_path, history)`, which calls `history.connect_run`. The level creator's Play passes none, so it is not saved.
- Proposal (board asleep): cap `MAX_RUNS` = 200, oldest dropped. Result (win, loss by health, loss by time) comes from the recap's `result` + `loss_reason`.
- `TestSave` now isolates `RunHistory.path` too (post_run fails the run if it is the real path).
- Tests: `game/tests/unit/test_run_history.gd` (9: empty, broken files, entry fields, unfinished ignored, newest first after restart, copies, cap, scripted run ending via RunState).
- Docs: Game loop architecture ("The run history"), `game/docs/data/game-data.md` ("Run history").
- Test counts: `game/tools` 657 (OK, 1 skipped), `tools` 573 OK, GUT 1835 passed (150 scripts).
- Documents affected: docs/game-loop-architecture.md, game/docs/data/game-data.md.

### QA round 1

- qa_check: tests PASS (3 sets), screenshots PASS (waived, nothing shown). Its documents line says "not changed on the branch: game/docs/": a false alarm, because the ticket lists the folder and the topic file game/docs/data/game-data.md did change (+1 line, "Run history"); docs/game-loop-architecture.md changed too ("The run history").
- Criterion 1: pass (test_a_scripted_run_ending_saves_one_entry, test_add_run_keeps_the_summary_and_end_time).
- Criterion 2: pass (test_newest_first_after_a_restart, test_no_file_is_an_empty_history, test_broken_files_are_empty).
- Criterion 3: pass (file, fields, cap described in both docs).
- Criterion 4: pass (all three test sets passed in qa_check; 9 new tests in test_run_history.gd).
- 2026-10-29, in-qa → done: QA passed; work the player never meets (no board review).
