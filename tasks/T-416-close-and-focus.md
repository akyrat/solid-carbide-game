---
id: T-416
title: Closing the game mid-run, and pausing when the window loses focus
status: open
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

Game loop architecture, Decisions: "Closing the game mid-run". Today nothing handles the window's close request, so closing mid-run loses the run's coins and the run is missing from the runs list; switching to another window doesn't pause, so enemies keep hitting the car. Closing mid-run ends the run as a loss (coins banked, runs-list entry) before the game quits; losing focus opens the pause screen (not during the level-up choice or the time's up screen, where pause is already blocked).

The board's review: close the window mid-run and see the coins in the garage and the run in the runs list; alt-tab mid-run and come back paused.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A close request during a run banks its coins and adds a loss to the runs list before quitting (test sends NOTIFICATION_WM_CLOSE_REQUEST). (QA: pass / fail)
- [ ] A close request outside a run quits as today. (QA: pass / fail)
- [ ] Focus out during a run opens the pause screen; during the level-up choice or the time's up screen it does nothing. (QA: pass / fail)
- [ ] New headless tests cover each criterion below that describes behaviour, and all three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
