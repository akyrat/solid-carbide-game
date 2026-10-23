---
id: T-281
title: The full test suite crashes (exit 139) in the combo popup test about two runs in three
status: in-qa
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

### 2026-10-23, In progress → In QA

Cause found: the test called a method on a popup that had already freed itself, reading freed memory. Swapped the two checks; 5 clean full runs in a row. Sent to QA.

## Result notes

Game Loop Agent, 2026-10-23.

**What caused it.** The test itself. Its last line was `assert_true(p.is_queued_for_deletion() or not is_instance_valid(p))`. The popup frees itself (`queue_free()`) once its life is over, so after the `await get_tree().process_frame` it is already gone. The assertion then called a method, `is_queued_for_deletion()`, on the freed popup *before* checking `is_instance_valid()`. In this Godot build (4.6.2) a call on a freed object does not reliably fail with an error. It reads freed memory, so whether the engine crashes (signal 11, exit 139) depends on whether that memory was reused, which is why the crash came and went. Nothing in the game code is wrong. Earlier tests, freed runs, timers and GUT are not involved.

**How it was found.** A copy of the file run on its own crashed 4 runs in 15. A copy with only this test crashed 19 in 20. Making the same Run and awaiting the frame without the assertion crashed 0 in 20, `assert_false(is_instance_valid(p))` alone crashed 0 in 20, and `print(p.is_queued_for_deletion())` alone crashed 8 in 10. The bisect copies lived in a temporary folder that has been removed.

**What changed.**
- `game/tests/unit/hud/test_combo_broken_popup.gd`: the assertion now checks validity first: `assert_true(not is_instance_valid(p) or p.is_queued_for_deletion())`. It accepts the same outcomes as before (the popup is freed, or queued to be freed) and only the order of the two checks changed. No test was skipped, removed or loosened. The reordered single test ran 30 in 30 without a crash.
- `game/README.md`, "Running the tests": a new section, "Never call a method on a node that may be freed (T-281)", gives the rule and the example.
- `game/tools/run_tests.sh` is unchanged. A warm-up frame was not needed.

**Run results (this folder).**
- HUD folder (`bash game/tools/run_tests.sh -gdir=res://tests/unit/hud`): exit 0 on 5 runs in a row, 101/101 each time. Before the fix it crashed 1 run in 9.
- Full suite (`bash game/tools/run_tests.sh`): exit 0 on 5 runs in a row, 1365/1365 each time. Before the fix it crashed 2 runs in 3.
- `python -m unittest discover -s tools -p "test_*.py"`: 451 tests, OK.
- `python -m unittest discover -s game/tools -p "test_*.py"`: 395 tests, OK (1 skipped, which was already skipped before).

Documents affected: `game/README.md`.
