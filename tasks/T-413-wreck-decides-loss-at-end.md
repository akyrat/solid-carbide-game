---
id: T-413
title: The wreck decides the loss at its end
status: in-progress
from: project-lead
to: game-loop
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/scripts/run/run_state.gd, game/scripts/run/run.gd, game/scripts/game/game_flow.gd, game/scripts/run/pickup_magnet.gd, game/scripts/enemies/coin.gd, tasks/T-406-wreck-health-revive.md]
files_expected_to_change: [game/scripts/run/run_state.gd, game/scripts/run/run.gd, game/scripts/game/game_flow.gd, game/scripts/run/pickup_magnet.gd]
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

Game loop architecture, Decisions: "The wreck decides the loss at its end" and "A tie goes to the player". Today the last heart sets the result to a loss at once (run_state.gd _wreck/_decide), freezes the recap, and running=false makes the kaiju kill, coins and the magnet ignore everything during the wreck. Make the wreck a window: the result is decided when its 3 seconds end. During it: a kaiju kill wins; coins and health pickups are pulled and count; pause Restart or Exit cancels the run (no coins banked, no runs-list entry). The revive itself is T-406 (another session, Greenbull): leave a clear way for it to undo the wreck (clock, controls, loss) and drop the trick in progress at the wreck, and say in the result notes how T-406 should use it. The kaiju dying on the step the clock reaches 0:00 is a win (today the node order makes it a loss). Which weapons work during the wreck is the next ticket.

The board's review: lose the last heart while fires burn on a weak kaiju and see it win; lose the last heart near coins and see them counted; pause during a wreck and Exit, and see no coins added in the garage.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Losing the last heart doesn't set the result; the result is set when the wreck's 3 seconds end (test reads the result before and after). (QA: pass / fail)
- [ ] A kaiju kill during the wreck gives a win, the win recap, and no loss. (QA: pass / fail)
- [ ] Coins and health pickups within the magnet during the wreck are pulled and counted (coin total rises). (QA: pass / fail)
- [ ] Pause Restart or Exit during the wreck banks no coins and adds no runs-list entry (progress coins and history length unchanged). (QA: pass / fail)
- [ ] The kaiju dying on the same physics step the clock reaches 0:00 gives a win. (QA: pass / fail)
- [ ] The result notes say how T-406 undoes the wreck through this ticket's code. (QA: pass / fail)
- [ ] New headless tests cover each criterion below that describes behaviour, and all three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Build I (wreck and run rules) started: the game-loop agent is on it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Done (game-loop, 2026-10-30).** Built on master with T-406 (revive) and T-424 (test_wreck.gd's in-run test without minions and weapons); both still pass.

What changed:
- `game/scripts/run/run_state.gd`: `_wreck()` no longer calls `_decide()`: it sets `running` false (clock, likes, tricks, gift packs, damage stop), forgets the drift in progress (`drift_seconds`, `drift_seconds_paid`), sets `wrecked`, and leaves `result` "" and the recap live. `_finish_wreck()` decides the loss (`_end("loss", "health")`) only when `wreck_left` reaches 0. During the wreck `add_coins()` and `enemy_slain()` count (`_counts_pickups()`), and `kaiju_killed()` ends the wreck and the run as a win (`run_ended("win", coins)`, win recap; the wreck's end never comes). The last heart's hit cuts the combo through the new `_cut_combo()` without sending `crashed`, so the trick in progress is dropped, not paid (other hits still pay it first, T-315). Tie: `_time_up()` records `Engine.get_physics_frames()` and `get_process_frames()`; while both are unchanged (`_in_tie_step()`), the kaiju's kill, its coins and `kaiju_killed()` count and the time's up hold is called off (`_call_off_time_up()`: unpaused, `PROCESS_MODE_INHERIT`), a win. In the real game the kaiju dies in physics before the clock moves in `_process`, which already won; the new rule covers the clock being moved first in the same step.
- `game/scripts/run/pickup_magnet.gd`: during the wreck coins are pulled too (health pickups already were, T-406); landed gift packs stay still. This replaces T-406's proposal that coins stand still (the Decision says coins count).
- `game/scripts/run/run.gd`: on `wreck_started` the car's trick detector is reset and `detect_tricks` turned off; on `revived` it is reset again and given back.
- `game/scripts/game/game_flow.gd`: pause Restart and Exit bank through the new static `GameFlow.bank_left_run(progress, run)`, which banks nothing while wrecked. A run left from the pause screen never sends `run_ended`, so there is no runs-list entry. `game/scripts/level_creator/level_creator.gd` (not in files_expected_to_change) uses the same helper so the creator's Play follows the same rule.

How T-406 undoes the wreck through this code: `RunState.revive()` (which `heal_car()` calls while `is_wrecked()`) is the one way to undo it. It sets `wrecked` false and `running` true, so the clock runs on from where it stopped and likes, tricks and damage count again. Its clearing of `result`, `loss_reason` and `_final_recap` is now a no-op kept for safety, because no result is set until `_finish_wreck()`. It sends `revived`, and `run.gd._on_revived()` gives back the controls and the trick detection and stops the smoke. The trick in progress was dropped at the wreck (`_cut_combo()` without `crashed`, the detector reset), so nothing from before the wreck is paid after the revive. T-406 needs no further change.

For the board's review: in the game the weapons, and so the fires, still stand still during the wreck (`weapons.gd` checks `is_running()`). So "fires burning on a weak kaiju win the wreck" can only be seen once the next ticket (which weapons work during the wreck) is in. The state already turns any kaiju kill during the wreck into a win, and the screenshot fixture shows it by calling the kill.

Proposal (game-loop): kills (`enemy_slain`) count in the recap during the wreck, as coins do, so a kaiju kill during the wreck shows on the win recap.

Tests:
- New file `game/tests/unit/run/test_wreck_decides_loss.gd` (14 tests). The result is "" until the wreck's 3 s end, then "loss". The fatal hit drops the trick (no `crashed`) and still cuts the combo. The drift in progress is forgotten. A kaiju kill during the wreck gives `[win, coins]`, the win recap and no loss later. In the game it shows the recap and adds a runs-list win. Coins count during the wreck. A real coin in the magnet is pulled and counted in the run scene. Trick detection is off while wrecked and back after a revive. Pause Restart and Exit during the wreck leave the progress coins and the history count unchanged; Exit outside the wreck still banks. The tie at 0:00 is a win (unpaused, the kaiju's coins kept); a kill first in the step wins too; a kill a frame later is too late.
- Updated `test_wreck.gd`: the result waits for the wreck's end, coins count and are pulled during the wreck. Updated `test_time_up_screen.gd`: the frozen-run checks now run a frame after 0:00, since the step of 0:00 is the tie step. Updated `test_run_recap.gd`: the health loss reason is read after the wreck ends.
- All three test sets pass: GUT 2139/2139 tests (1263143 asserts); `tools` 582 tests OK; `game/tools` 722 tests OK (1 skipped).

Screenshots, in `art-archive/T-413/screenshots/` (made with `bash game/tools/record_wreck_decides.sh` and the fixture `game/tests/fixtures/wreck_decides_demo.tscn`):
- `1_wreck_starts.png`: the wreck has just started, with coins beside the slide; Coins 10.
- `2_wreck_coins_pulled.png`: still wrecked, the coins pulled in; Coins 30.
- `3_kaiju_kill_win_recap.png`: a kaiju kill during the wreck shows the win recap.

Documents: `docs/game-loop-architecture.md` (Content, "Wrecked": the loss is decided at the wreck's end; the T-406 bullet updated for coins). Code docs: `game/docs/game-loop/the-run.md`, `game/docs/game-loop/screen-flow.md`, `game/docs/hud-and-menus/time-up-screen.md`.
