---
id: T-500
title: Playtest switch: start a run with every weapon at a chosen tier
status: open
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, game/data/playtest.json, game/scripts/weapons/weapons.gd, game/scripts/weapons/level_up_offers.gd]
files_expected_to_change: [game/data/playtest.json, game/scripts/weapons/weapons.gd, game/tests/unit/, game/docs/weapons/]
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

So the board can play the new weapon trees (T-495 to T-499) at their top tiers without a long run, add one playtest switch to game/data/playtest.json: `weapon_tier_at_start` (an integer, default 0 = off, the game's rule). When it is 1 or more and `all_weapons_at_start` is true, every weapon starts the run at that tier, capped at each weapon's own last tier (max_tier), with every tier's effects applied as if levelled up in order. With it at 0, nothing changes. Never visible to players; the level-up offers then offer only what is left (nothing for a weapon at its last tier). Document the key in playtest.json's _comment like the others, and in game/docs/weapons/ where all_weapons_at_start is described. Leave the switch off (0) and all_weapons_at_start false in the committed file. Built from master, so it works with today's tiers and the new trees alike. Never write, move or commit anything in game/data/levels/. SFX stay off.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/playtest.json has weapon_tier_at_start: 0 and its _comment describes it; all_weapons_at_start stays false. (QA: pass / fail)
- [ ] A unit test: with all_weapons_at_start true and weapon_tier_at_start 8, every weapon starts the run at min(8, its max_tier) with the same stats as levelling it up tier by tier. (QA: pass / fail)
- [ ] A unit test: with weapon_tier_at_start 0, a run starts as before (gun at tier 1 only). (QA: pass / fail)
- [ ] A unit test: the level-up offers never offer a weapon already at its last tier. (QA: pass / fail)
- [ ] The Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
