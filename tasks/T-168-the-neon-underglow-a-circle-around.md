---
id: T-168
title: The neon underglow: a circle around the car that damages enemies (placeholder look)
status: open
from: project-lead
to: weapon-behavior
lead: Goal-G-002
epic: weapons
milestone: mvp
goal: G-002
user_facing_text: no
changes_visuals: yes
depends_on: [T-166]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/visual-style.md, docs/extended-narrative.md, game/data/weapons.json, game/scripts/weapons/weapons.gd, game/scripts/weapons/weapon.gd, game/scripts/weapons/flamethrower/exhaust_flamethrower.gd, game/tests/unit/weapons/test_exhaust_flamethrower.gd, game/README.md]
files_expected_to_change: [game/scripts/weapons/neon_underglow.gd, game/scripts/weapons/weapons.gd, game/tests/unit/weapons/test_neon_underglow.gd, docs/weapons.md, game/README.md]
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

Build the neon underglow (docs/weapons.md, Decisions, 2026-10-18): neon lights under the car make a circular area around it; every enemy inside takes damage every second, and an enemy takes damage as soon as it enters. Add it as a weapon script in the rack (`WEAPON_SCRIPTS` in `weapons.gd`, id `underglow`), not owned at the start of a run, given and upgraded through `rack.upgrade("underglow")`, with all numbers and tiers 2 to 8 read from its `weapons.json` entry (D1). Damage goes through each enemy's take_damage and is multiplied by the garage damage bonus (`rack.damage_multiplier()`), as the board decided for every weapon. Use the rack's target rules (minions by centre, the kaiju by body overlap, as the flamethrower does). Whether an enemy leaving and re-entering within the same second is hit again on entry is your proposal: write it in the result notes. Placeholder look: a flat circle drawn in code under the car showing the area, in a neon colour that is never Redgull red; the Asset Generation Agent swaps the final art in later (D10). Do not add the level-up choice: that is D7.

The board's review: Play a run from the task folder with the underglow given (by its test fixture or the playtest switch the agent records) and see the placeholder circle under the car hurt minions.

## Acceptance criteria

- [ ] A new run has no underglow; after `rack.upgrade("underglow")` a test shows a fake enemy that enters the circle takes damage on that step, and an enemy staying inside takes damage again once per tick interval from weapons.json, with the damage value from weapons.json times the garage damage multiplier. (QA: pass / fail)
- [ ] A test per tier 2 to 8 applies the tier from code and checks the change weapons.json gives it. (QA: pass / fail)
- [ ] A test shows no damage while the run is paused or after it ends, and that a new run removes the underglow. (QA: pass / fail)
- [ ] A placeholder circle drawn in code shows under the car while it is owned, in no shade of Redgull red, drawn below the car sprite (checked in a test or a screenshot fixture). (QA: pass / fail)
- [ ] `docs/weapons.md` Content and `game/README.md` 'Weapons' describe the underglow, and the game's test set passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
