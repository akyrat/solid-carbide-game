---
id: T-281
title: The full test suite crashes (exit 139) in the combo popup test about two runs in three
status: in-progress
from: project-lead
to: game-loop
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, game/README.md, game/tools/run_tests.sh, game/tests/unit/hud/test_combo_broken_popup.gd, tasks/T-276-health-bar-heart-weapon-icons.md]
files_expected_to_change: [game/tests/, game/tools/run_tests.sh, game/README.md]
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

The full GUT suite (`bash game/tools/run_tests.sh`) often ends with exit 139 (signal 11, the engine crashing). The crash comes at the first `await get_tree().process_frame` of `test_it_goes_away_after_its_life` in `game/tests/unit/hud/test_combo_broken_popup.gd` (about line 104), the first file of the HUD test folder. That test passes on its own. In T-276's checks (2026-10-23) it crashed in 2 of 3 runs of the HUD folder on master, and in 2 of 3 full runs on T-276's branch. Agents and QA now rerun until a run finishes, which costs time on every ticket and could hide a real crash.

Find out why the engine crashes there and fix it in the tests or the test runner, not in the game. One idea from T-276's agent: a warm-up frame before the first run is built. The fix must not skip or weaken any test.

Built from `master` on its own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The result notes say in plain words what caused the crash and what changed; no test is skipped, removed or loosened (`git diff`) (QA: pass / fail)
- [ ] The full GUT suite exits 0 on five runs in a row, and the HUD folder alone (`-gdir=res://tests/unit/hud`) exits 0 on five runs in a row (QA: pass / fail)
- [ ] `game/README.md` notes the fix where it describes running the tests; all Python tool tests pass (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-23, Open → In progress

Started at the board's go: find and fix the engine crash (exit 139) in the combo popup test.

## Result notes

Written by the agent when it finishes.
