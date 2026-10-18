---
id: T-166
title: Weapon numbers: the neon underglow, the molotovs and the windshield wiper, with 8 tiers each
status: open
from: project-lead
to: game-data
lead: Goal-G-002
epic: weapons
milestone: mvp
goal: G-002
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/data/weapons.json, game/scripts/data/weapon_data.gd, game/tests/unit/test_weapon_data.gd, game/README.md]
files_expected_to_change: [game/data/weapons.json, game/scripts/data/weapon_data.gd, game/tests/unit/test_weapon_data.gd, docs/weapons.md, game/README.md]
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

The board added three weapons to the MVP (docs/weapons.md, Decisions, 2026-10-18): the neon underglow (a circle around the car; enemies inside take damage every second, and an enemy takes damage as soon as it enters), the molotovs (thrown from the car at random; each leaves a circular fire area where it lands, and enemies burn and take damage only while inside it), and the windshield wiper (one wiper in front of the car, always sweeping a semicircle; it damages what it hits, pushes minions back but not the kaiju). Each has 8 tiers like the gun and the flamethrower: tier 1 is getting it, tiers 2 to 8 are 7 upgrades. The numbers and what each tier changes are your proposal, judged in the board's playtest.

Add one entry per weapon to `game/data/weapons.json` (ids `underglow`, `molotov`, `wiper`) in the same shape as the gun's and the flamethrower's: base values (for example damage, radius, tick interval; for the molotovs the throw interval, how far from the car they land, the fire area's radius and how long it lasts; for the wiper its length, sweep speed and knockback strength) and a `tiers` list of exactly 7 entries (tiers 2 to 8), each an `effect` and a `value`. Units and seconds as in the file's comment; update the comment, which today says no weapon pushes. Make `weapon_data.gd` read the new entries the way it reads the existing two, and extend the data test. Write the proposal and its reasoning (why these numbers, how they compare with the gun and the flamethrower) in your result notes. Do not invent anything the docs don't say beyond the numbers and tier effects.

## Acceptance criteria

- [ ] `game/data/weapons.json` has entries `underglow`, `molotov` and `wiper`, each with base values and a `tiers` list of exactly 7 entries numbered 2 to 8, each with an `effect` and a `value`; the gun's and the flamethrower's entries are unchanged. (QA: pass / fail)
- [ ] The wiper's entry has a knockback strength, and the file's comment no longer says that no weapon pushes enemies (it says only the wiper pushes, and only minions). (QA: pass / fail)
- [ ] `weapon_data.gd` returns the new weapons' base values and tiers, and `game/tests/unit/test_weapon_data.gd` checks there are 5 weapons, each with tiers 1 to 8 (base plus 7 tiers); the game's test set passes. (QA: pass / fail)
- [ ] The result notes hold the proposed numbers and tier effects for the three weapons with the reasoning for each. (QA: pass / fail)
- [ ] `docs/weapons.md` Content lists the three weapons' numbers and tiers and says they are proposals for the board's playtest; `game/README.md` 'Game data' mentions the new entries. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
