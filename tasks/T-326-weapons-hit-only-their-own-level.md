---
id: T-326
title: Weapons hit only enemies on their own height level
status: open
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-324]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/enemies.md, docs/drifting.md, game/README.md, game/scripts/weapons/weapons.gd, game/scripts/weapons/weapon.gd, game/scripts/weapons/bricks.gd, game/scripts/weapons/neon_underglow.gd, game/scripts/weapons/windshield_wiper.gd, game/scripts/weapons/molotovs.gd, game/scripts/weapons/molotov_fire.gd, game/scripts/weapons/starting_gun.gd, game/scripts/weapons/bullet.gd, game/scripts/weapons/flamethrower/]
files_expected_to_change: [game/scripts/weapons/, game/tests/unit/weapons/, game/tests/unit/, game/README.md, docs/weapons.md]
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

The board's decision (Weapons, Decisions, "Weapons hit only enemies on the car's own level", 2026-10-28): on a map with rooftops and ramps (the elevation map, and levels from the level creator), a weapon damages only the enemies on the same height level as its hit. Today every weapon's reach is flat and ignores height ("The underglow and the wiper at height", 2026-10-21: "Their damage areas are unchanged"), so from a rooftop the underglow, the wiper and Bricks' wave also hit minions on the street below, and the other way round. The board asked this after reading Bricks' proposal "the wave ignores height" (T-324).

For every weapon, the hit counts only enemies on the hit's level:
- **The car's level** for the starting gun (it also shouldn't target or waste shots on an enemy on another level; your call how, for example skip it when choosing a target), the exhaust flamethrower, the neon underglow, the windshield wiper (its push too) and Bricks (its damage and its push; the wave is on the level where the car lands).
- **The fire's level** for a molotov: the fire stays where the bottle landed, and burns only enemies on that level.
- **In the air:** your proposal (for example the level under the car, or none until it lands).

Use the game's existing heights (the ground height under each body: `GroundHeight`, the elevation layer, the enemies' own height on the elevation map, Enemies, Content, "Enemies on the rooftops and ramps"). **Proposals for the playtest**, written in the result notes and in Weapons, Content: how a ramp's in-between heights count (for example a height tolerance, so an enemy halfway up a ramp next to the car is still hit), and whether the kaiju, which is huge and stands on the street, can be hit from a rooftop (a proposal: yes, it is tall enough to reach every level). On the MVP's flat map nothing changes.

Built on top of T-324 (Bricks): start from the branch the Project Lead gives you, which has it.

The board's review: on the elevation map, fight from a rooftop with minions below and beside the car, with each weapon (the `all_weapons_at_start` playtest switch helps): only the ones on your level are hit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] For each of the six weapons, a test puts one enemy on the car's level and one on another level, both within reach, and only the one on the same level is damaged (and, for the wiper and Bricks, pushed). (QA: pass / fail)
- [ ] A molotov's fire burns only enemies on the fire's level (test with the car on another level). (QA: pass / fail)
- [ ] The starting gun doesn't fire at an enemy on another level when it's the only one in range (test). (QA: pass / fail)
- [ ] On the flat MVP map every weapon hits exactly as before (the existing weapon tests pass unchanged, or the result notes say why one changed). (QA: pass / fail)
- [ ] The proposals (ramps' in-between heights, the kaiju, the car in the air) are in the result notes and in Weapons, Content, and game/README.md describes how it works. (QA: pass / fail)
- [ ] Screenshots (or a GIF for anything that moves) of the change in a run are in `art-archive/T-326/screenshots/`, as `tasks/README.md`, "Screenshots", asks: a weapon on a rooftop hitting a minion beside the car and not one on the street below. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
