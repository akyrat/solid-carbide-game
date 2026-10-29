---
id: T-326
title: Weapons hit only enemies on their own height level
status: done
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
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/enemies.md, docs/drifting.md, game/docs/weapons/shared.md, game/scripts/weapons/weapons.gd, game/scripts/weapons/weapon.gd, game/scripts/weapons/bricks.gd, game/scripts/weapons/neon_underglow.gd, game/scripts/weapons/windshield_wiper.gd, game/scripts/weapons/molotovs.gd, game/scripts/weapons/molotov_fire.gd, game/scripts/weapons/starting_gun.gd, game/scripts/weapons/bullet.gd, game/scripts/weapons/flamethrower/]
files_expected_to_change: [game/scripts/weapons/, game/tests/unit/weapons/, game/tests/unit/, game/README.md, docs/weapons.md]
model: opus
qa_rounds: 1
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

- [ ] For each of the six weapons, a test puts one enemy on the car's level and one on another level, both within reach, and only the one on the same level is damaged (and, for the wiper and Bricks, pushed). (QA: pass)
- [ ] A molotov's fire burns only enemies on the fire's level (test with the car on another level). (QA: pass)
- [ ] The starting gun doesn't fire at an enemy on another level when it's the only one in range (test). (QA: pass)
- [ ] On the flat MVP map every weapon hits exactly as before (the existing weapon tests pass unchanged, or the result notes say why one changed). (QA: pass)
- [ ] The proposals (ramps' in-between heights, the kaiju, the car in the air) are in the result notes and in Weapons, Content, and game/README.md describes how it works. (QA: pass)
- [ ] Screenshots (or a GIF for anything that moves) of the change in a run are in `art-archive/T-326/screenshots/`, as `tasks/README.md`, "Screenshots", asks: a weapon on a rooftop hitting a minion beside the car and not one on the street below. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started overnight (build A, Stream reacts): the Weapon Behavior Agent is making weapons hit only enemies on their own height level.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Done (Weapon Behavior Agent, 2026-10-29).** On a map with rooftops and ramps, every weapon now hits only the enemies on the height level of its hit. On a map without heights nothing changes.

**How it works** (`game/scripts/weapons/weapons.gd`, the rack): `car_level()` is the ground's height under the car's centre (`car.ground`, the map's GroundHeight; NAN when the car has none). `level_at(units)` gives the ground height at any point. `on_level(enemy, level)` compares the enemy's `body_height()` (else `ground_height()`) with the level, within `LEVEL_TOLERANCE`, 1.5 units. Three cases always count: an enemy in the group `kaiju`, an enemy that reports no height, and a NAN level (no ground). `enemies_at_level(level)`, `enemies_at_car_level()` and `enemies_within(centre, radius, level = NAN)` use this check.
- Underglow, wiper (damage and push) and flamethrower: `targets()` = `rack.enemies_at_car_level()`.
- Bricks: `targets(centre)` = the enemies on the level of the ground at the landing spot. Damage and push both follow it.
- Starting gun: picks its targets with `enemies_within(car, range, car_level())`, so it fires no volley when the only enemies in range are on another level. Each bullet keeps the level it was fired on (`bullet.gd` `level`) and flies past enemies on other levels.
- Molotov fire: takes `level = rack.level_at(centre)` when it starts (where the bottle landed) and burns only that level, wherever the car is.

**Proposals for the playtest** (also in Weapons, Content, "Weapons hit only their own level (built in task T-326)"):
- **Ramps' in-between heights:** a tolerance of 1.5 units. A ramp rises 3 units over 12, so this covers 6 units along the slope, and an enemy part way up a ramp next to the car is hit. Every rooftop is at least 3 units above the street and the next rooftop, so nothing on another level is ever hit. A falling enemy counts at its height in the air. The enemies' contact damage uses 1 unit; the weapons' 1.5 is a little more generous on ramps.
- **In the air:** the level under the car, the ground right below its centre. The weapons keep working through a jump: over a rooftop they hit that rooftop, over the street they hit the street.
- **The kaiju:** it can be hit from every level, because it is taller than the highest rooftop. Its push rules are unchanged.

**Flat map:** with no ground, every level is NAN and every enemy counts, so every weapon hits exactly as before. No existing weapon test changed: their fake enemies report no height, so they count on every level.

**Tests** (all three sets run in the foreground, 2026-10-29):
- `python -m unittest discover -s game/tools -p "test_*.py"`: 657 tests OK (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: 560 tests OK.
- `bash game/tools/run_tests.sh`: 1831/1831 passing (1,245,314 asserts).
- New: `game/tests/unit/weapons/test_weapon_levels.gd`, 15 tests, with the fixture `game/tests/fixtures/weapons/fake_level_minion.gd`. The tests use a test ground with a height-3 rooftop round the car.
  - For each of the six weapons, one enemy on the car's level and one on the street, both in reach: only the first is damaged (and pushed, for the wiper and Bricks).
  - The gun fires no volley at a lone enemy on another level, and its bullet flies past one in its way.
  - A molotov fire on the street, with the car on the rooftop, burns the street; one on the rooftop burns the rooftop. Bricks landing on the street hits the street.
  - The tolerance: an enemy 1.4 units below is hit, one 1.6 units below is not. The kaiju and an enemy with no height count on every level. In the air, the level under the car counts. With no ground, every height is hit.
  - On the real elevation map, with the car on roof-nw-3 by its edge, the underglow hits a real minion beside the car and not a real minion on the street below, inside the ring.

**Screenshots:** `art-archive/T-326/screenshots/weapon_levels_rooftop.png`, from the fixture `game/tests/fixtures/weapons/weapon_levels_demo.tscn`. The car stands on roof-nw-3 with the underglow. One minion stands beside it on the rooftop and three on the street at the foot of the wall, all within 2.5 flat units. The fixture's log shows only the rooftop minion hit ("hit Minion2 (height 3.0) for 1.25"). To take it: `bash game/tools/screenshot.sh res://tests/fixtures/weapons/weapon_levels_demo.tscn art-archive/T-326/screenshots/weapon_levels_rooftop.png 75`.

**Documents affected:**
- `docs/weapons.md`: a new Content section, and a line in Bricks' "The wave".
- `game/README.md`: the index line for shared.md.
- `game/docs/weapons/shared.md`: a new "Levels" section, and the rack's calls.
- `game/docs/weapons/bricks.md`: the wave's targets.

**For the Project Lead:**
- `docs/enemies.md` line 101 ("Weapons: unchanged by this task: the weapons find and hit enemies at any height") is now out of date. Enemies is not this ticket's document, so I left it alone; it could point to Weapons, Content, "Weapons hit only their own level".
- Found while building, and not changed: a molotov fire is always drawn on the street's plane (Decisions, "The underglow and the wiper at height": the molotov fire "is not lifted"). A bottle thrown from a rooftop that lands on the roof now burns the rooftop, as the board decided, but its fire is drawn where the street would be under the roof. The board may notice this when fighting with molotovs from a rooftop. Lifting the fire's drawing would be a separate visual ticket.
- One refusal, not worked around: a hook refused an inline Python command that would have written these result notes. I wrote them with the Edit tool instead, as the brief asked.


**QA (2026-10-29, round 1): all 7 criteria pass.** qa_check: tests (3 sets) pass, documents changed, screenshot present. New test file test_weapon_levels.gd covers the six weapons, molotov fire level, gun with a lone off-level enemy, tolerance, kaiju, air, no-ground. Existing weapon tests unchanged. Proposals are in the result notes and docs/weapons.md (Content section); game/docs/weapons/shared.md and the README index describe it. Screenshot shows the rooftop car with one minion beside it and three on the street below. Note: molotov fires are still drawn on the street plane (visual only, not a criterion). Also docs/enemies.md line 101 is out of date (the agent flagged it).

**Merged master (2026-10-29):** one conflict, in starting_gun.gd. Resolved by keeping both sides: the bullet keeps its level (T-326) and master's `weapon_id`. Tests pass: game/tools 657 OK (1 skipped), tools 573 OK, GUT 1864/1864.
- 2026-10-29, needs-playtest → done: The board played build A: LGTM (2026-10-29).
