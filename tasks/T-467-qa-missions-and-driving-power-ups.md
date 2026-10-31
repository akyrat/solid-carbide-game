---
id: T-467
title: QA: missions and driving power-ups through a whole run
status: open
from: project-lead
to: qa-integration
lead: Goal-G-009
epic: game-loop
milestone: mvp
goal: G-009
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: [T-457, T-458, T-459, T-460, T-461, T-462, T-463]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, game/docs/setup/tests.md, game/scenes/game/game.tscn, game/scripts/run/missions.gd, game/scripts/ui/power_up_screen.gd, game/scripts/ui/level_up_screen.gd]
files_expected_to_change: [game/tests/unit/game/test_missions_power_ups_run.gd]
model: sonnet
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

An integration test of goal G-009 in the real game scene, to catch the pieces not fitting together. Headless, from the main game scene: start a run, complete mission 1 from simulated input or trick events, see the power-up overlay pause the run, take a power-up, see the run resume and mission 2 on the notebook page, then trigger a weapon level-up and pick up its gift pack and see the weapons gift screen still open. Check the two overlays never show at once (or queue as documented), and that Restart resets the missions to mission 1 and removes the power-ups. Only a test; no game code changes (a failure is reported on the ticket for the owning agent).

## Acceptance criteria

- [ ] A headless GUT test from the main game scene completes mission 1, sees the run paused with the power-up overlay open, takes a card, sees the run resume and mission 2 shown on the notebook page, and then sees a weapon level-up open the weapons gift screen; it passes. (QA: pass / fail)
- [ ] The test shows the power-up overlay and the weapons gift screen are never open at the same time (or queue as documented in HUD and menus). (QA: pass / fail)
- [ ] The test shows Restart resets the missions to mission 1 and clears the owned power-ups. (QA: pass / fail)
- [ ] All three test sets pass in the ticket's folder, with the counts in the result notes; the result notes say there is nothing new to picture. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
