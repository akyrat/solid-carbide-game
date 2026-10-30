---
id: T-417
title: A broken save never wipes progress
status: done
from: project-lead
to: game-data
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/garage-design.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, game/scripts/data/player_progress.gd, game/scripts/data/run_history.gd]
files_expected_to_change: [game/scripts/data/player_progress.gd, game/scripts/data/run_history.gd]
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

Garage design, Decisions: "A broken save never wipes progress". Today save() writes over user://progress.json directly; a crash mid-write or a hand edit gives invalid JSON, the next launch treats it as a new player, and the next save overwrites the old file for good. No version field, so a renamed upgrade id drops to 0. run_history.gd has the same behaviour. Write to a temp file and rename; keep the last good save as a backup and load it when the main file fails; never overwrite a file that failed to load; add a version and a way to map old ids.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A truncated progress.json loads the backup's coins and levels. (QA: pass)
- [ ] After a failed load with no backup, the broken file is kept (renamed aside), not overwritten. (QA: pass)
- [ ] A save writes a temp file and renames it (a save interrupted before the rename leaves the old file intact). (QA: pass)
- [ ] Saves carry a version; a file without one loads as version 1. (QA: pass)
- [ ] run_history.gd follows the same rules (same tests). (QA: pass)
- [ ] New headless tests cover each criterion below that describes behaviour, and all three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Build I (wreck and run rules) started: the game-data agent is on it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Done. New `game/scripts/data/safe_save.gd` (`SafeSave`), used by `PlayerProgress` and `RunHistory`: save = write `<file>.tmp`, check it reads back, copy the last good file to `<file>.bak`, rename the temp over the file. Load = main file; if it fails it is renamed to `<file>.broken-<unix time>` (never overwritten, numbered if the name is taken) and `<file>.bak` loads; neither = new player / empty history. Every save holds `"version"` (1); a file without one loads as version 1 (`loaded_version`); `loaded_from` says main, backup or none. `PlayerProgress.ID_RENAMES` (version -> {old id: new id}, empty today) maps old ids on load; a rename means raising `SafeSave.CURRENT_VERSION` and adding the mapping. Existing tests' cleanup now also removes the .bak and .broken files (`SafeSave.remove_all`, in test_save.gd, test_player_progress.gd, test_run_history.gd). New `tests/unit/test_safe_save.gd` (16 tests: truncated main loads backup, broken kept aside with and without a backup, wrong shape, two broken files, temp file used, save cut off before the rename, stale temp, broken never becomes the backup, versions, id mapping, history equivalents). Tests: GUT 2141/2141 pass (the first full run had 2 failures from leftover .bak files in old tests' cleanup, fixed); game/tools Python 722 OK (1 skipped); tools Python 582 OK. Only temp test paths used. Docs updated: docs/garage-design.md, game/docs/data/game-data.md. Untracked .uid files in the worktree are Godot noise, not committed (except safe_save's and its test's).
- 2026-10-30, in-progress → in-qa: Safe saves done: temp file+rename, .bak backup, broken file kept aside, version 1, ID_RENAMES; 16 new tests; all three sets pass.
- 2026-10-30, in-qa → done: QA pass: all 6 criteria, three test sets green (GUT 2141 pass in builder run; qa_check green)
