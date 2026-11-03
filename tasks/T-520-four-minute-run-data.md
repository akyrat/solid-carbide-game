---
id: T-520
title: Data: 5-tier weapons, 2-tier power-ups, sub goals for 12 gift packs in 3 minutes
status: open
from: project-lead
to: game-data
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-519]
documents_affected: [docs/weapons.md, docs/drifting.md]
files_to_read_first: [docs/weapons.md, docs/drifting.md, docs/game-loop-architecture.md, game/data/weapons.json, game/data/power_ups.json, game/data/run.json, tasks/README.md]
files_expected_to_change: [game/data/weapons.json, game/data/power_ups.json, game/data/run.json, game/scripts/, game/tests/unit/, docs/weapons.md, docs/drifting.md]
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

Change game/data to the board's new trees: weapons.json, every weapon 5 tiers (max_tier 5; tiers 2 to 5 exactly as docs/weapons.md, Decisions, "Shorter trees: 5 tiers", the stacked numbers not rounded; Bricks' widest wave at the tier 4 radius; Neon Underglow's tier 5 radius x1.3 marked as a placeholder in its _comment), each card pointing at T-519's text keys. power_ups.json: every power-up 2 tiers (tier 1 as today, tier 2 = today's tier 4). run.json: the level table (sub goals) so a player who drifts and does tricks steadily gets about 12 gift packs by 3:00 (propose from the subs per second a run earns today, with tricks paying subs since T-513; show the sum in the result notes); the heal amount for a full sub goal once everything is maxed if it lives in data. Update the code that only reads these shapes if it hard-codes 8 tiers or 4 power-up tiers (say where). Update docs/weapons.md Content and docs/drifting.md Content tier lists. God mode and the playtest switches (weapon_tier_at_start) must still work with max_tier 5.

The board, 2026-11-03: the run is shortened to 4 minutes (3:00 build, kaiju 3:00 to 4:00). Decisions: docs/game-loop-architecture.md "A 4-minute run: 3 minutes to build, 1 minute of kaiju"; docs/weapons.md "Shorter trees: 5 tiers"; docs/drifting.md "Two tiers and three slots for the driving power-ups"; docs/enemies.md "Paced for the 4-minute run"; docs/hud-and-menus.md "Weapon and power-up slots". T-519 to T-523 are built in parallel and combined by the Project Lead into one build (T-521's folder) that the board plays before anything merges. Many existing tests assume the 8-minute run, the kaiju at 7:00 and 8 tiers: update the ones your change breaks (say which in the result notes), never delete a test's purpose. Numbers you choose are proposals for the playtest, in game/data with a _comment. Never write, move or commit anything in game/data/levels/. SFX stay off. Stage files by name, never .uid/.import noise. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play the one combined build (T-519 to T-523) from C:\solid-carbide-worktrees\T-521\game\project.godot before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A unit test: every weapon has max_tier 5 and tiers 2 to 5 with exactly the docs' numbers; every power-up has 2 tiers, tier 2 equal to the old tier 4's values. (QA: pass / fail)
- [ ] A unit test: the level table's total subs to reach 12 level-ups fits the proposed 3-minute earning rate (the rate and the sum in a _comment and the result notes). (QA: pass / fail)
- [ ] A unit test: God mode's tier range and weapon_tier_at_start cap at 5 for weapons and 2 for power-ups. (QA: pass / fail)
- [ ] docs/weapons.md and docs/drifting.md Content show the new tiers. (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)
- [ ] A screenshot of a level-up screen with merged-tier cards, under art-archive/T-NNN/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
