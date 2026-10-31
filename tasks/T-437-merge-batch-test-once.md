---
id: T-437
title: Merges test once per batch, with a 1500 s Godot test limit
status: done
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

The board, 2026-10-31: merges take too long, and they now time out. The Godot test set takes about 890 s on its own (T-372's agent measured 889 s; the script's comment says 90 s at first and 270 to 306 s on 2026-10-21), so its 900 s limit (`game/tools/run_tests.sh`, GUT_TIME_LIMIT default) stops merges whenever the machine is busy: Audit's T-436 merge stopped on it (exit 124) with no test failing. And `tools/merge_batch.py` runs all three test sets after every ticket, about 20 to 25 minutes each, so a queue of six tickets takes two to three hours.

Two changes, both approved by the board:
1. The Godot set's default time limit becomes 1500 s (GUT_TIME_LIMIT still overrides it). Update the script's comment with today's timings.
2. merge_batch tests once per batch: it merges every ticket in the batch (each one still checked as today: no conflict, marked done, .import noise reverted, its own commit), runs the three test sets once on the result, and if they pass the whole batch is in. If they fail, it finds the ticket that broke them by testing ticket by ticket (or by halving the batch), keeps the tickets that pass, stops the one that fails with the reason, and leaves master clean and green as it does today. A ticket that conflicts stops on its own without stopping the others. Keep today's one-line-per-ticket output and the log file. Keep a flag for the old ticket-by-ticket mode.

Also, read only: list the 10 slowest Godot test files with their times in the result notes (GUT's own timings or a timed run), as data for the board on why the set has grown. Don't change any game test.

Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/tools/run_tests.sh` defaults to a 1500 s limit, GUT_TIME_LIMIT still overrides it (a test or a dry run shows both). (QA: pass - default 1500, env override tested)
- [ ] merge_batch with several tickets runs the three test sets once when they all pass (tests with stubbed test runs count the runs: one per batch). (QA: pass - test_all_green_runs_the_tests_once_for_the_batch)
- [ ] When the batch's tests fail, merge_batch finds the breaking ticket, merges the others, stops only that one with its reason, and leaves master with no merge in progress and without the breaking ticket's commits (tests with stubbed runs and a temporary git repo). (QA: pass - test_the_breaking_ticket_is_found_and_the_others_merge)
- [ ] A ticket that conflicts stops on its own and the rest of the batch still merges (test). (QA: pass - test_a_conflict_stops_alone_and_the_rest_is_tested_once)
- [ ] The old ticket-by-ticket mode is still there behind a flag (test). (QA: pass - test_each_flag_keeps_the_old_mode)
- [ ] docs/working-with-the-board.md, "Merging (Project Lead)", describes testing once per batch and the flag. (QA: pass - doc line 46 describes once per batch, halving, --each, 1500 s)
- [ ] The 10 slowest Godot test files and their times are in the result notes. (QA: pass - 10 files listed in result notes (from junit data; read only))
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass - qa_check ran the 3 sets: all green)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Open → In progress

Started: the QA/Integration Agent builds it in C:\solid-carbide-worktrees\T-437 (tooling, merges straight after QA).

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built by the QA/Integration Agent, 2026-10-31.

- `game/tools/run_tests.sh`: default limit 1500 s (`GUT_TIME_LIMIT` still overrides); the comment carries the timings (90 s at first, 270 to 306 s on 2026-10-21, 889 s on 2026-10-31).
- `tools/merge_batch.py`: default mode merges and commits every ticket without tests, runs the three sets once on the result, then removes the worktrees and branches. On a red batch it halves the merged prefixes (`git reset --keep` to each ticket's merge commit) to find the first ticket whose state is red, undoes it (reset to the prefix before it, drops its done commit on the branch), stops it with "test failed: ...", merges the tickets after it again and tests again; tickets before it stay. A conflict stops that ticket alone. If master turns unclean mid-batch (another instance's merge), tickets already committed are reported "merged, NOT tested", worktrees kept. `--each` is the old mode (tests per ticket before its commit). One line per ticket and the log file are unchanged.
- `tools/test_merge_batch.py`: new tests with stubbed counting test commands on temporary repos: one run per green batch of three; `--each` runs three; breaker found among four with the others merged, timeline and branch tip clean, no merge in progress; a conflict stops alone and the rest is tested once; run_tests.sh default is 1500, and a fake Godot with GUT_TIME_LIMIT=1 ends with exit 124.
- `docs/working-with-the-board.md`, "Merging (Project Lead)": describes testing once per batch, the halving, `--each`, and the 1500 s limit.

Test counts (T-437 folder, foreground): game/tools 752 tests OK (1 skipped); tools 591 tests OK; GUT 182 scripts, 2239 of 2239 passing, 729 s.

The 10 slowest Godot test files (GUT junit export, one full run, 654 s of test time): test_level_up_screen 27.7 s; enemies/test_minions 24.0 s; weapons/test_all_weapons_run 21.0 s; run/test_gift_drops 20.8 s; weapons/test_level_up_offers 17.6 s; enemies/test_enemies_on_heights 17.0 s; test_camera_options 16.2 s; enemies/test_kaiju_meteors 15.9 s; weapons/test_starting_gun 15.9 s; weapons/test_neon_underglow 14.6 s. Together about 191 s of 654 s: the set has grown by count (182 scripts, 2239 tests, mean 3.6 s per script); no single file dominates. For per-file times: `bash game/tools/run_tests.sh -gjunit_xml_file=user://full.xml` (an absolute path wrote nothing).

Not done: the new merge_batch was not run on the real repo; the main checkout's copy is untouched.
- 2026-10-31, in-progress → in-qa: Built and tested; ready for QA
- 2026-10-31, in-qa → done: QA passed
