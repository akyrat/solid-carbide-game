---
id: T-416
title: Closing the game mid-run, and pausing when the window loses focus
status: in-qa
from: project-lead
to: game-loop
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: [T-413]
documents_affected: [docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/scripts/game/game_flow.gd, game/scripts/ui/pause_screen.gd]
files_expected_to_change: [game/scripts/game/game_flow.gd]
model: sonnet
qa_rounds: 2
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

Game loop architecture, Decisions: "Closing the game mid-run". Today nothing handles the window's close request, so closing mid-run loses the run's coins and the run is missing from the runs list; switching to another window doesn't pause, so enemies keep hitting the car. Closing mid-run ends the run as a loss (coins banked, runs-list entry) before the game quits; losing focus opens the pause screen (not during the level-up choice or the time's up screen, where pause is already blocked).

The board's review: close the window mid-run and see the coins in the garage and the run in the runs list; alt-tab mid-run and come back paused.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A close request during a run banks its coins and adds a loss to the runs list before quitting (test sends NOTIFICATION_WM_CLOSE_REQUEST). (QA: pass - round 3 judged against the decision 'Restart, Exit or closing cancels the run': close mid-run banks no coins, writes no history, shows no recap; test_close_and_focus asserts it; abandon/LOSS_CLOSED/bank_left_run gone from code)
- [ ] A close request outside a run quits as today. (QA: pass)
- [ ] Focus out during a run opens the pause screen; during the level-up choice or the time's up screen it does nothing. (QA: pass)
- [ ] New headless tests cover each criterion below that describes behaviour, and all three test sets pass, with the counts in the result notes. (QA: pass - round 2: tests green in round 1, only the doc changed since; the doc now labels both choices as proposals for the playtest)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started in build I: the game-loop agent is on it.

### 2026-10-30, Needs playtest → In progress

Back to the agent: you want Restart, Exit and closing to cancel the run, with the coins lost and nothing saved.

### 2026-10-30, In QA

Reworked so Restart, Exit and closing cancel the run (coins lost, nothing saved). QA round 2 running now.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done (game-loop agent).

- `GameFlow._notification`: NOTIFICATION_WM_CLOSE_REQUEST calls the new `RunState.abandon()` when a run is on screen, then `quit_game`; outside a run it only quits. `abandon()` ends a running run as a loss (loss reason "closed", new `LOSS_CLOSED`), decides the loss on the spot during the wreck, sends the time's up loss during the time's up screen, and does nothing once the run has ended (no double log). run_ended banks the coins and adds the runs-list entry through the existing handlers.
- NOTIFICATION_APPLICATION_FOCUS_OUT calls `pause_screen.toggle()` while a run is on screen, undecided and not already paused; toggle() already refuses during the level-up choice and the time's up screen.
- Files: game/scripts/game/game_flow.gd, game/scripts/run/run_state.gd (one small addition beyond the listed file), game/tests/unit/game/test_close_and_focus.gd (9 tests), game/tests/fixtures/focus_out_demo.gd/.tscn (screenshot fixture).
- Doc: docs/game-loop-architecture.md, Decisions, "Closing the game mid-run": the how, with a proposal for the playtest (no auto-resume on focus return).
- Tests: game/tools python 722 OK (1 skipped); tools python 582 OK; GUT 2160 tests, 2159 passing; the one failure is the known test_run_likes drift-timing flake, rerun alone: 37/37 pass. New file alone: 9/9.
- Screenshot: art-archive/T-416/screenshots/focus_out_pauses.png (pause screen after focus out).
- 2026-10-30, in-progress → in-qa: Close request banks coins and logs a loss; focus out pauses; 9 new tests pass.
- 2026-10-30, in-qa → in-progress: QA round 1: criteria 1-3 pass, tests green. Criterion 4 fail paperwork: Closing the game mid-run in game-loop-architecture.md states as fact the open choices (close during wreck: loss decided on the spot, reason health; close in time's up: time loss). Label them proposals for the playtest.
- 2026-10-30, in-progress → in-qa: Project Lead fixed the doc labels QA asked for (Decisions, 'Closing the game mid-run'); back to QA for criterion 4.
- 2026-10-30, in-qa → needs-playtest: QA round 2: all 4 criteria pass; only the doc changed since round 1 (both choices now labelled proposals).
- Round 2 (the board's cancel decision, 2026-10-30): the closing-as-loss bullets above are superseded. Removed `RunState.abandon()`, `LOSS_CLOSED` and `GameFlow.bank_left_run`. Close, pause Restart and pause Exit (the game's and the level creator's Play) now bank nothing and log nothing; the close handler just quits (nothing banks coins until run_ended). Focus-out pausing unchanged.
- Asserts changed, all because of the board's decision: test_pause_restart_exit.gd (restart/exit: progress.coins 9 and 4 became 0, plus history.count() 0; tests renamed ..._cancels_...); test_play_level.gd (creator Restart/Exit: coins before + 7 / + 5 became unchanged; renamed); test_wreck_decides_loss.gd (Exit outside the wreck: coins + 6 became unchanged, history unchanged; renamed); test_close_and_focus.gd (close tests now assert coins 0, no history entry, no result, quit once; the wreck/time-up/already-ended close tests replaced by one wreck-close cancel test).
- Docs: hud-and-menus.md line 126 level-creator "(coins kept)" fixed; game-loop-architecture.md already carried the new decision. docs/long-gdd.md still has the old close line: regenerated by the merge script.
- Tests round 2: GUT 2202 tests, all pass after fixing one assert of mine (test_wreck_decides_loss, shared history count; rerun file alone 14/14); tools python 582 OK; game/tools python unchanged since round 1 (722 OK).
- 2026-10-30, needs-playtest → in-progress: The board, after playing build I (2026-10-30): Restart or Exit on the pause screen and closing the window cancel the run at any point, the wreck included: coins lost, nothing saved to the run history, no recap. Replaces closing as a loss with coins kept, and T-327's coins kept on Restart and Exit (Game loop architecture, Decisions, 'Restart, Exit or closing cancels the run').
- 2026-10-30, in-progress → in-qa: Restart, Exit and close cancel the run: no coins, no history; tests updated and green.
