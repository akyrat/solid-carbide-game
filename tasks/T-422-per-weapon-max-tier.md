---
id: T-422
title: Each weapon has its own top tier
status: open
from: project-lead
to: weapon-behavior
lead: Preemptive-bug-bash
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: [T-408]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/weapons.md, game/scripts/weapons/weapon.gd, game/scripts/data/weapon_data.gd, game/data/weapons.json, game/scripts/weapons/starting_gun.gd]
files_expected_to_change: [game/scripts/weapons/weapon.gd, game/scripts/data/weapon_data.gd, game/data/weapons.json, game/scripts/weapons/starting_gun.gd]
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

Code hole. weapon.gd uses data.max_tier(), one weapons.json max_tier (8) for every weapon, but Weapons, Decisions now gives the gun tiers 2 to 11 (T-408); raising the shared number gives every weapon empty tiers. Give each weapon its own top tier, from its own data. Also a data guard: starting_gun.gd _fire_next() pops an empty queue and crashes when bullets is 0. Runs after T-408 (another session), which reworks the gun.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Each weapon's top tier comes from its own data; the gun reaches its T-408 top tier while the others keep theirs. (QA: pass / fail)
- [ ] A weapon at its own top tier is never offered in a gift pack. (QA: pass / fail)
- [ ] A gun with bullets 0 in the data doesn't crash and reports an error. (QA: pass / fail)
- [ ] New headless tests cover each criterion below that describes behaviour, and all three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
