---
id: T-467
title: QA: missions and driving power-ups through a whole run
status: in-qa
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

### 2026-11-01, Blocked → In progress

Goal runner (G-009): started, in C:\solid-carbide-worktrees\T-467.

### 2026-11-01, In progress → In QA

Goal runner (G-009): the agent is done; QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Added `game/tests/unit/game/test_missions_power_ups_run.gd` (4 tests, 47 asserts, all pass; no game code changed). All from the main game scene (game.tscn, Start pressed on the menu):
1. `test_mission_one_to_power_up_to_mission_two_to_weapons_gift`: mission 1 (a 4 s drift, fed through `missions.on_trick`) opens the power-up overlay with 2 cards and pauses the run; taking a card grants tier 1, closes the overlay and resumes; mission 2 is on the notebook page (`hud.mission_page`); a level-up plus its landed gift pack picked up opens the weapons gift screen (run paused, power-up overlay closed); taking a weapon resumes.
2. `test_overlays_never_open_together_mission_during_weapon_choice`: a gift for a mission completed while a weapon choice is open waits (`pending`), and opens after the weapon choice; never both open.
3. `test_overlays_never_open_together_weapon_choice_during_overlay`: a weapon choice picked up while the overlay is open is held and shown when the overlay closes; never both open. This is the queueing documented in PowerUpOffers.
4. `test_restart_resets_missions_and_clears_power_ups`: Restart from the pause screen gives a new run on mission 1 with no owned power-ups, overlay closed, run unpaused.

Tests: the new file alone passes 4/4. Python unit tests: 842 run, OK (1 skipped). Full GUT suite: 201 scripts, 2423 tests, all passing, 1275125 asserts, TESTS PASSED. Third set (tool checks) ran inside the Python run above. Nothing new to picture: this is a test only, so there are no screenshots. No failure found for the owning agents.
