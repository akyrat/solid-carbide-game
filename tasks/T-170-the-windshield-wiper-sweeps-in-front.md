---
id: T-170
title: The windshield wiper: sweeps in front of the car, damages and pushes minions back (placeholder look)
status: in-progress
from: project-lead
to: weapon-behavior
lead: Goal-G-002
epic: weapons
milestone: mvp
goal: G-002
user_facing_text: no
changes_visuals: yes
depends_on: [T-166, T-167]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/enemies.md, docs/visual-style.md, docs/extended-narrative.md, game/data/weapons.json, game/scripts/weapons/weapons.gd, game/scripts/weapons/weapon.gd, game/scripts/enemies/minion.gd, game/tests/unit/weapons/test_starting_gun.gd, game/tests/unit/weapons/test_exhaust_flamethrower.gd, game/README.md]
files_expected_to_change: [game/scripts/weapons/windshield_wiper.gd, game/scripts/weapons/weapons.gd, game/tests/unit/weapons/test_windshield_wiper.gd, game/tests/unit/weapons/test_starting_gun.gd, game/tests/unit/weapons/test_exhaust_flamethrower.gd, docs/weapons.md, game/README.md]
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

Build the windshield wiper (docs/weapons.md, Decisions, 2026-10-18): one wiper in front of the car that sweeps back and forth in a semicircle, all the time, turning with the car. An enemy it hits takes damage; minions are knocked back through the minion knockback call (D2); the kaiju is damaged but never pushed. It is the only weapon that pushes. Add a weapon script to the rack (id `wiper`), not owned at the start of a run, given and upgraded through `rack.upgrade("wiper")`, with all numbers and tiers 2 to 8 from its weapons.json entry (D1). Damage through take_damage, times the garage damage multiplier. How often the same enemy can be hit by one sweep is your proposal: write it in the result notes. Placeholder look: a wiper blade drawn in code in front of the car, never Redgull red; the final art comes later (D10). Do not add the level-up choice: that is D7.

The board's review: Play a run from the task folder with the wiper given and see the placeholder wiper sweep and push minions away.

## Acceptance criteria

- [ ] A new run has no wiper; after `rack.upgrade("wiper")` a test shows the wiper's angle sweeps back and forth across a semicircle in front of the car and the semicircle turns when the car turns. (QA: pass / fail)
- [ ] A test shows a fake minion the wiper reaches takes the damage from weapons.json (times the garage damage multiplier) and is moved away from the car through the knockback call; a test shows the kaiju (or a fake big enemy) is damaged but not moved. (QA: pass / fail)
- [ ] A test shows the gun's bullets and the flamethrower still never move an enemy. (QA: pass / fail)
- [ ] A test per tier 2 to 8 applies the tier from code and checks the change weapons.json gives it; tests show it stops while paused and is removed on a new run. (QA: pass / fail)
- [ ] A placeholder wiper drawn in code, in no shade of Redgull red, shows in front of the car; `docs/weapons.md` Content and `game/README.md` 'Weapons' describe the wiper, and the game's test set passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-18, Blocked → In progress

Goal runner (G-002): started, in C:\solid-carbide-worktrees\T-170.

## Result notes

Written by the agent when it finishes.
