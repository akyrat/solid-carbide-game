---
id: T-589
title: The full Godot test run hangs after test_garage_button_pulse.gd, before test_bricks_widest_perf.gd starts
status: in-progress
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

### 2026-11-08, Open → In progress

Started: the Weapon Behavior Agent hunts the hang in C:\solid-carbide-worktrees\T-589 (shard list and reproduction in the ticket).

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

PARTIAL (blocked on a hook refusal before the full runs). CAUSE: tests/unit/run/test_level_up_prewarm.gd:test_first_pickup_still_opens_the_screen_with_cards opens the level-up screen, which sets get_tree().paused = true, and the script had no after_each, so the tree stayed paused for every later script in the same Godot process. GUT's timed waits (wait_seconds, the time limits of wait_for_signal/wait_until) count in addons/gut/awaiter.gd's _physics_process, which does not run while the tree is paused, so the next timed wait never returns. In the hanging shard that is test_garage_button_pulse.gd's 5th test (test_letters_are_light_blue_and_button_not_tinted_or_scaled, await wait_seconds(PULSE_SECONDS/4)), the first timed wait after the leak. test_bricks_widest_perf.gd is innocent: it never started. The 'Unreferenced static string ... Physics2DConstraintSolveIslands' line is printed when the stuck process is killed, not a cause. THE TICKET'S 23-SCRIPT LIST IS NOT THE SHARD THAT HANGS: it runs clean (below). The real hanging shard is shard 6 of the master merge run (.board/merge_batch-20261108-024641.log, line 13601): test_screen_flow, test_bricks, test_enemies_drop_off_ledges, test_elevation_sample_see_through, test_elevation_sample_depth, test_missions_power_ups_run, test_combo_broken_popup, test_hud_layout_editor, test_likes_spring, test_t420_needle_scrape_and_level_guards, test_level_up_prewarm, test_challenge_popup, test_drift_marks_art, test_wall_bounce, test_kaiju_signs, test_bouncy_bumpers, test_trick_list, helpers/test_save.gd, test_minion_sprite, test_four_minute_run_data, test_weapon_tier_at_start, test_garage_button_pulse, test_bricks_widest_perf. T-588's runs report the same totals (2887 tests, shard 6), so the same deal. A T-585 run of exactly that list (pid 53880, another session's) was live-stuck at 20+ min: main thread in Sleep (ExecutionDelay) using about 1 s CPU per 5 s, workers idle, i.e. the main loop ran frames and an await never returned, not a deadlock. EVIDENCE: (1) the ticket's 23 list in one process, as the runner does: passed 270/270 in 224 s (no hang). (2) a diagnostic hook (not committed) logging every SceneTree.paused change per test, plus a watchdog thread, in a full parallel run (GUT_TIME_LIMIT=540, TESTS PASSED, 275 s): exactly one test in the whole suite ends with the tree paused, test_level_up_prewarm.gd:test_first_pickup_still_opens_the_screen_with_cards; every following test in that process started paused until a later script (test_run_rails in today's deal) happened to unpause it. In shard 6's deal no later script unpauses before the garage test. (3) the ticket's 23 list again with every frame slowed to 120 ms (simulated load): 270/270, 334 s, no leak. (4) direct reproduction: the old test_level_up_prewarm.gd then test_garage_button_pulse.gd in one process, hooks without the guard: rc 124 at 90 s, output ends at test_letters_are_light_blue... then the same ERROR Physics2DConstraintSolveIslands line, the exact signature. With the fix: test_level_up_prewarm + garage + test_pause_guard: 15/15, 4 s. Old prewarm + garage with the guard: no hang, 12/12, 4 s, guard names the test and exits 1. CHANGES (3 commits on task/T-589): 8a8ccef5 game/tests/helpers/pause_guard.gd (PauseGuard: after every test, after after_each and the autofree, a paused tree is unpaused and the test named; post_run.gd fails the run), pre_run.gd starts it, post_run.gd fails on a leak, game/tests/unit/test_pause_guard.gd (3 tests). e36ece25 test_level_up_prewarm.gd: after_each sets get_tree().paused = false. 2456453b game/docs/setup/tests.md: new rule 'Every test ends with the tree unpaused (T-589)'. Benchmark test_bricks_widest_perf.gd unchanged, assertions untouched; run_tests_parallel.py (shard, weight, limit, exit codes) unchanged. VERIFIED: full parallel run with the guard before the fix: TESTS FAILED exit 1 in 275 s, only because the guard named the one leaker (no hang). Ticket's 23 list three times in a row after the fix, one process each, limit 400 s: 214 s, 213 s, 210 s, each 23 scripts 270/270 passing, no guard line. NOT DONE: the throwaway guard check after the resume, the real shard-6 list after the fix, and the two full bash game/tools/run_tests.sh runs. After the resume, a PreToolUse hook refused every Godot test command ('Task statuses change only through the status script ... timeout: a command the guard can't tell won't write a ticket'), first on my scratchpad wrapper script, then on a plain timeout + Godot GUT command. Earlier the same commands ran fine. I stopped there and did not try other ways round it.
