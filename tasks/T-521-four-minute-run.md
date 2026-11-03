---
id: T-521
title: The 4-minute run: kaiju at 3:00, 3 weapon and 3 power-up slots, new weapons at tier 2, the heal
status: open
from: project-lead
to: game-loop
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-519]
documents_affected: [docs/game-loop-architecture.md]
files_to_read_first: [docs/game-loop-architecture.md, docs/weapons.md, docs/drifting.md, tasks/README.md]
files_expected_to_change: [game/scripts/, game/data/, game/tests/unit/, game/docs/, docs/game-loop-architecture.md]
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

Build the run rules of docs/game-loop-architecture.md, Decisions, "A 4-minute run": the kaiju arrives at 3:00 (the boss time signal) and the run ends at 4:00; the clock's colour switch points and anything else timed to 8:00/7:00 in the run follow (say what). The player owns at most 3 weapons (the gun counts): once 3 are owned, the level-up offers only upgrades of those 3; a weapon picked for the first time arrives at tier 2 (its tier 1 and 2 applied in order). Once all 3 owned weapons are at their last tier, a full sub goal heals the car (amount: your proposal, in data) and shows T-519's heal message, with no level-up screen. At most 3 driving power-ups: once 3 are owned, missions offer only upgrades of those 3 (and nothing new once all 3 are maxed: say what a mission gift does then, a proposal). Pace the missions for the 3-minute build (how many, how fast: proposals). Read max tiers from data (T-520 changes them to 5 and 2 in parallel; don't hard-code). T-520 and T-522 and T-523 are built in parallel; the Project Lead combines them in this ticket's folder for the board's playtest. Update docs/game-loop-architecture.md Content.

The board, 2026-11-03: the run is shortened to 4 minutes (3:00 build, kaiju 3:00 to 4:00). Decisions: docs/game-loop-architecture.md "A 4-minute run: 3 minutes to build, 1 minute of kaiju"; docs/weapons.md "Shorter trees: 5 tiers"; docs/drifting.md "Two tiers and three slots for the driving power-ups"; docs/enemies.md "Paced for the 4-minute run"; docs/hud-and-menus.md "Weapon and power-up slots". T-519 to T-523 are built in parallel and combined by the Project Lead into one build (T-521's folder) that the board plays before anything merges. Many existing tests assume the 8-minute run, the kaiju at 7:00 and 8 tiers: update the ones your change breaks (say which in the result notes), never delete a test's purpose. Numbers you choose are proposals for the playtest, in game/data with a _comment. Never write, move or commit anything in game/data/levels/. SFX stay off. Stage files by name, never .uid/.import noise. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play the one combined build (T-519 to T-523) from C:\solid-carbide-worktrees\T-521\game\project.godot before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A unit test: the kaiju arrives at 3:00 and the run ends at 4:00 (win and loss as before). (QA: pass / fail)
- [ ] A unit test: with 3 weapons owned, level-up offers contain only upgrades of those 3; a weapon picked for the first time is at tier 2. (QA: pass / fail)
- [ ] A unit test: with all 3 owned weapons at their last tier, a full sub goal heals the car, shows the heal message key and opens no level-up screen. (QA: pass / fail)
- [ ] A unit test: with 3 power-ups owned, mission gifts offer only those 3; the behaviour once all are maxed is tested as proposed. (QA: pass / fail)
- [ ] Max tiers are read from data, not hard-coded (test with a data file of other max tiers, or a grep in the result notes). (QA: pass / fail)
- [ ] docs/game-loop-architecture.md Content describes the 4-minute run and the caps. (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)
- [ ] Screenshots: the kaiju arriving at 3:00, a level-up with 3 weapons owned, and the heal message, under art-archive/T-NNN/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
