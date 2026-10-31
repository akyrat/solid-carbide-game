---
id: T-457
title: Missions in the run: 30 per run (5 fixed, 25 generated), progress from trick events, signals, and the car's owned power-ups
status: open
from: project-lead
to: game-loop
lead: Goal-G-009
epic: game-loop
milestone: mvp
goal: G-009
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: [T-455]
documents_affected: [docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/drifting.md, game/docs/game-loop/the-run.md, game/docs/driving/tricks.md, game/data/missions.json, game/data/power_ups.json, game/scripts/data/mission_data.gd, game/scripts/data/power_up_data.gd, game/scripts/run/run_state.gd, game/scripts/run/run.gd, game/scripts/driving/trick_detector.gd, game/scripts/level/thread_the_needle.gd]
files_expected_to_change: [game/scripts/run/missions.gd, game/scripts/run/run_state.gd, game/scripts/run/run.gd, game/tests/unit/run/test_missions.gd, game/docs/game-loop/the-run.md, docs/game-loop-architecture.md]
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

Game loop architecture, Decisions, 'Mission packs' (board, 2026-10-31). Build the run's mission tracker, invisible to the player (the HUD page and the overlay are separate tickets).

- A mission node (or part of RunState) holds the run's 30 missions: the 5 fixed ones from `missions.json`, then 25 generated from its rules with an RNG seeded per run (a new seed each run; a test can pass a seed). A new run (Start, or Restart from the pause screen) resets to mission 1 and a fresh set.
- Trick events advance the current mission's goals: drift duration, alt drift, airtime seconds, air 180, air 360, thread the needle, and the other types the data allows. Hook into the signals the trick detector and thread the needle already emit; don't change how tricks pay. A continuous-drift goal counts only one unbroken drift (a drift that ends, by release or a wall hit, starts over).
- Signals: `goal_progress(mission_index, goal_index, done, total)`, `goal_completed(mission_index, goal_index)`, `mission_completed(mission_index)`. After mission 30 nothing more is offered (proposal; note it).
- The car's owned driving power-ups live in RunState too, so the power-up tickets can read them: `power_up_tier(id)` (0 = not owned), `grant_power_up(id)` (new at tier 1, or the next tier), cleared on a new run. A signal `power_ups_changed`.

Document it in game/docs/game-loop/the-run.md and Game loop architecture, Content.

## Acceptance criteria

- [ ] A new run has 30 missions; its first 5 match missions.json's fixed list and are identical across at least 3 different seeds, and missions 6 to 30 differ between at least two seeds (GUT test). (QA: pass / fail)
- [ ] GUT tests complete missions 1 to 5 in order from simulated trick events, each sending goal_progress, goal_completed and mission_completed, and the current mission advances after each. (QA: pass / fail)
- [ ] A GUT test shows the continuous-drift goal counts only one unbroken drift: two 2 s drifts don't complete mission 1, one 4 s drift does. (QA: pass / fail)
- [ ] Starting a new run (and Restart) resets the tracker to mission 1 and clears owned power-ups; grant_power_up gives tier 1 then tier 2 and power_up_tier reads them (GUT tests). (QA: pass / fail)
- [ ] game/docs/game-loop/the-run.md and Game loop architecture, Content, describe the tracker, its signals and the power-up state; the result notes say there is nothing to picture. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
