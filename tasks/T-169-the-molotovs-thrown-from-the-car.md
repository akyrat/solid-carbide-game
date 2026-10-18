---
id: T-169
title: The molotovs: thrown from the car, they leave fire areas that burn enemies (placeholder look)
status: blocked
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
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/visual-style.md, docs/extended-narrative.md, game/data/weapons.json, game/scripts/weapons/weapons.gd, game/scripts/weapons/weapon.gd, game/scripts/weapons/bullet.gd, game/scripts/weapons/starting_gun.gd, game/scripts/enemies/enemy_depth.gd, game/README.md]
files_expected_to_change: [game/scripts/weapons/molotovs.gd, game/scripts/weapons/molotov_fire.gd, game/scripts/weapons/weapons.gd, game/tests/unit/weapons/test_molotovs.gd, docs/weapons.md, game/README.md]
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

Build the molotovs (docs/weapons.md, Decisions, 2026-10-18): thrown from the car at random, each makes a circular area on fire where it lands, and enemies in a fire area burn and take damage. The board's answer: an enemy burns only while it is inside the fire area, not after it leaves. Add a weapon script to the rack (id `molotov`), not owned at the start of a run, given and upgraded through `rack.upgrade("molotov")`, with all numbers and tiers 2 to 8 read from its weapons.json entry (D1). When and where they land within 'at random' is your proposal (use the run's random generator so tests can seed it): write it in the result notes. Bottles in flight and fire areas are projectiles in the rack (add_projectile), so they stop while paused and are cleared on a new run. Damage through take_damage, times the garage damage multiplier. Placeholder look drawn in code: a small bottle in flight and a flat fire circle on the ground, never Redgull red; the final art comes later (D10). Do not add the level-up choice: that is D7.

The board's review: Play a run from the task folder with the molotovs given and see the placeholder bottles land and their fire areas burn minions.

## Acceptance criteria

- [ ] A new run has no molotovs; after `rack.upgrade("molotov")`, a seeded test shows a molotov thrown at the interval from weapons.json lands within the distance weapons.json gives and leaves a fire area of the radius weapons.json gives. (QA: pass / fail)
- [ ] A test shows a fake enemy inside a fire area takes damage with the values from weapons.json (times the garage damage multiplier), and one outside or that has left the area takes no more damage. (QA: pass / fail)
- [ ] Tests show fire areas expire after their duration, stop while paused, and are removed on a new run. (QA: pass / fail)
- [ ] A test per tier 2 to 8 applies the tier from code and checks the change weapons.json gives it. (QA: pass / fail)
- [ ] Placeholder bottle and fire area are drawn in code, in no shade of Redgull red; `docs/weapons.md` Content and `game/README.md` 'Weapons' describe the molotovs, and the game's test set passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
