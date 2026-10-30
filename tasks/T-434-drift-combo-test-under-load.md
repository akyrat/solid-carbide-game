---
id: T-434
title: The drift-pays-its-combo test fails when the machine is busy
status: in-progress
from: project-lead
to: game-loop
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, game/tests/unit/run/test_run_likes.gd, tasks/T-424-wreck-revive-test-flaky.md]
files_expected_to_change: [game/tests/unit/run/test_run_likes.gd]
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

Bug in a test, not in the game. `game/tests/unit/run/test_run_likes.gd`, `test_run_scene_drift_pays_its_combo_once_when_it_ends`, fails when other Godot processes are running (agents and merges test in parallel): it waits a set number of physics frames for a drift and then expects the drift to have lasted 1.5 to 1.7 s, but under load it measures about 1.1 s (1.08, 1.10, 1.12 seen on 2026-10-30), so 'nothing paid while it lasts', the length, the payment and the popup all fail. It passes when its file is run alone. It has stopped merges into master (T-402, T-411) and shows up in most agents' runs.

Make it deterministic, the way T-424 fixed the wreck test: drive the drift by the game's own clock or step the physics a known number of times instead of waiting on wall-clock frames, and keep the run real. Don't change what it checks. If that can't be done without changing game code, stop and say what you'd change.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The root cause is in the result notes: why the measured drift is shorter under load. (QA: pass / fail)
- [ ] The test passes while the CPU is loaded: run its file 10 times while the full GUT suite runs in another Godot process at the same time (or an equivalent load the agent names), all 10 passing; the counts in the result notes. (QA: pass / fail)
- [ ] The test still asserts what it did before (no assert removed or loosened). (QA: pass / fail)
- [ ] No game code changes, or, if any were needed, the agent stopped and asked first (result notes). (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started: this test stops merges whenever the machine is busy.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Root cause: the test waited `wait_physics_frames(75)` and assumed each waited frame was one car step. Under load the engine's physics ticks and GUT's frame count drift apart, so the car got fewer steps than frames waited: the drift's own clock (`_drift_time`, +1 `dt` per car step) read about 1.1 s, not 1.5 s.
Fix (test only, no game code): the car's own physics process is switched off in the test (`run.car.set_physics_process(false)`) and `run.car.physics_step()` (the car's public step) is called 75 times, then 3 times after the drift ends. Same run, same code path, a known step count. No assert removed or loosened.
Load check: the file (`-gselect=test_run_likes`) run 10 times while the full GUT suite ran in a second Godot process (other agents' runs added load): the drift test passed 10 of 10. The file as a whole passed 7 of 10: the other 3 runs failed on a different test in the same file, `test_switch_off_level_up_keeps_clock_running` ("the clock keeps running": `await wait_physics_frames(5)`, then expects time_left to drop; the same wall-clock-frame flaw). Out of this ticket's scope; needs its own ticket with the same fix pattern.
Three sets: game/tools python OK (582 tests), tools python OK, GUT 2172/2172 passing.
Changed: game/tests/unit/run/test_run_likes.gd. Documents affected: none.
