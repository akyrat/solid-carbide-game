---
id: T-413
title: The wreck decides the loss at its end
status: open
from: project-lead
to: game-loop
lead: Preemptive-bug-bash
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

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
