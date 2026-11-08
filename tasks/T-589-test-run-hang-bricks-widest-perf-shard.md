---
id: T-589
title: The full Godot test run hangs after test_garage_button_pulse.gd, before test_bricks_widest_perf.gd starts
status: open
from: project-lead
to: weapon-behavior
lead: Tests
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [game/docs/setup/tests.md]
files_to_read_first: [game/docs/setup/tests.md, game/tools/run_tests_parallel.py, game/tools/run_tests.sh, game/tests/unit/weapons/test_bricks_widest_perf.gd, game/tests/unit/weapons/test_bricks_perf.gd, game/tests/unit/test_garage_button_pulse.gd, game/tests/helpers/post_run.gd, game/tests/helpers/pre_run.gd, game/.gutconfig.json]
files_expected_to_change: [game/tests/unit/weapons/test_bricks_widest_perf.gd, game/tests/, game/scripts/weapons/bricks.gd, game/scripts/, game/tools/, game/docs/setup/tests.md]
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

A real, repeatable hang of the full Godot test set (bash game/tools/run_tests.sh, 12 processes). Seen four times on 2026-11-08: once in a merge run on master (merge log .board/merge_batch-20261108-024641.log: TIME LIMIT after 3600 s, the shard's last lines were the five test names of tests/unit/test_garage_button_pulse.gd), and three times in a row in T-588's folder (two full runs of 25 minutes each stopped at the 1500 s limit, and once more with that shard's exact script list in one Godot process). Each time the shard prints the five tests of test_garage_button_pulse.gd, ending with test_letters_are_light_blue_and_button_not_tinted_or_scaled, then `ERROR: BUG: Unreferenced static string to 0: Physics2DConstraintSolveIslands (string_name.cpp:116)`, and nothing more: no GUT summary, the process never ends. The only script of that shard that never started is tests/unit/weapons/test_bricks_widest_perf.gd (T-498's benchmark: a tier-8 bricks landing in a real run with a crowd of real minions). It passes alone (4/4, about 18 s) and passed in a short run together with the garage test and test_four_minute_run_data.gd, so the hang depends on the state the scripts before it leave behind. The two scripts land together because neither has an entry in test_times.json (both newer than the last --measure), so the deal puts them last in the same shard; the pairing is the same on master.

The shard that hangs (the exact deal in C:\solid-carbide-worktrees\T-588 after merging master, 23 scripts, in this order): tests/unit/game/test_game_map.gd, tests/unit/test_drift_smoke.gd, tests/unit/weapons/test_weapons_wreck.gd, tests/unit/level_creator/test_creator_spawn.gd, tests/unit/run/test_run_drift_marks_on_raised_ground.gd, tests/unit/game/test_acceleration_upgrade.gd, tests/unit/test_mvp_map.gd, tests/unit/run/test_run_likes.gd, tests/unit/test_see_through_map.gd, tests/unit/test_car_noshadow_in_air.gd, tests/unit/test_rev_charge.gd, tests/unit/test_boost.gd, tests/unit/hud/test_shared_button.gd, tests/unit/test_drift_exit_slip.gd, tests/unit/run/test_magnet_upgrade.gd, tests/unit/test_garage_data.gd, tests/unit/test_sample.gd, tests/unit/test_reverse_and_aura_tricks.gd, tests/unit/test_no_preselected_button.gd, tests/unit/test_jump_real_run.gd, tests/unit/game/test_pause_resume_stack.gd, tests/unit/test_garage_button_pulse.gd, tests/unit/weapons/test_bricks_widest_perf.gd. Reproduce it the way the runner does: one headless Godot with `-gconfig= -gtest=<those scripts>` plus the pre and post run hooks of .gutconfig.json (see run_tests_parallel.py, run_shard), with a short GUT_TIME_LIMIT so a hang costs minutes, not 25. Then bisect the list in front of the benchmark to find which earlier script's leftover state makes it hang (or whether the benchmark itself hangs on a pause, a paused tree, a stuck physics step or an await that never returns), name the cause with evidence, and fix it at the cause: in the benchmark, in the script that leaks the state, or in the game code if the hang is a real bug. Never fix it by changing the shard deal or the time limit. If the right fix is to take the benchmark out of the unit suite (it mostly prints timings; test_bricks_perf.gd, T-481, is its sibling), say so in the notes: the Project Lead accepts moving it next to the other benches in game/tools/ as long as what it asserts is kept somewhere.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, Handing back). Never write, move or change anything in game/data/levels/. No PixelLab calls. Run tests in the foreground only, one command at a time, and leave no background job running; use GUT_TIME_LIMIT so no single command runs past 10 minutes. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes name the cause of the hang (which script, which state, why it only shows after the scripts dealt before it) with the evidence that showed it (the bisection steps or the stack), not a guess. (QA: pass / fail)
- [ ] The shard's exact 23-script list above, run in one headless Godot the way run_tests_parallel.py runs a shard, finishes with a GUT summary and no failing test three times in a row, each under 400 s. (QA: pass / fail)
- [ ] `bash game/tools/run_tests.sh` with no arguments prints TESTS PASSED twice in a row in the ticket's folder, with no shard stopped by the time limit; the wall times are in the result notes. (QA: pass / fail)
- [ ] What test_bricks_widest_perf.gd asserted before the fix is still asserted somewhere (the file itself, or a bench in game/tools/ named in the notes); no test is deleted without its assertions moving. (QA: pass / fail)
- [ ] No change to the shard deal, the time limit or the runner's exit codes is used as the fix (run_tests_parallel.py's shard(), weight() and the limit are unchanged, or changed only for a reason the notes give that is not avoiding this hang). (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent), and QA's full run passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
