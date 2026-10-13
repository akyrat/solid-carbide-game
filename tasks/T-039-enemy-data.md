---
id: T-039
title: Enemy numbers: minions, spawning, coins and the kaiju
status: in-qa
from: project-lead
to: game-data
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-038, T-040]
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, docs/weapons.md, tasks/T-038-run-and-likes-data.md, tasks/T-040-weapon-data.md, game/README.md]
files_expected_to_change: [JSON data under game/data/, tests, docs/enemies.md, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-038 (the data convention and the car's health) and T-040 (weapon damage) are done.**

The Game Data Agent works out the enemy balancing numbers, with the Enemy Behavior Agent's needs in mind (Enemies, Decisions). Write them as JSON under `game/data/`, following T-038's convention:

- **Minion:** health, contact damage, knockback strength, and how often contact damage applies while a minion touches the car.
- **Spawning:** how many minions are around at the start, how that number grows over the 7 minutes before the kaiju ("slightly"; enemies never get tougher), and how far off-screen they appear.
- **Coins:** the drop chance and how many coins a minion drops.
- **Kaiju:** health (it can be damaged at any time; propose it with T-040's damage, and say in the result notes how long the MVP weapons take to bring it down, for the board to judge); its walking speed, contact damage and knockback.
- **Meteor attack:** how often the kaiju attacks, how many meteors fall per attack, and the meteor impact damage and knockback. The warning circle shows for 2 seconds (Enemies, Decisions); that is fixed, not a balancing number.

Explain each number briefly in the result notes. The board judges them in playtests.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The data is valid JSON under `game/data/`, and a test loads it through T-038's loader (QA: pass / fail)
- [ ] A test shows the minion count at the end of the 7 minutes is higher than at the start, and minion health and damage do not change over time (QA: pass / fail)
- [ ] The result notes say how long the MVP weapons take to bring the kaiju's health to 0 (from T-040's data, with the assumptions), and a test checks that figure against the data (QA: pass / fail)
- [ ] The result notes explain every number, and `docs/enemies.md` points to the data in References, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the Game Data Agent.

**Produced:** `game/data/enemies.json`; reader `game/scripts/data/enemy_data.gd` (`EnemyData`); tests `game/tests/unit/test_enemy_data.gd` (9 tests, loading through `GameData`); one References line in `docs/enemies.md`; "Enemies (T-039)" in `game/README.md` (Game data). Documents affected: `docs/enemies.md` (References only), `game/README.md`.

All numbers are proposals for the board's playtests. Scale used throughout: car health 100 (run.json), cruise speed 11 and top speed 33 units/s, the default camera shows 28.8 units top to bottom (about 51 across at 16:9), gun 2 damage every 1.26 s at tier 1, flame 2 damage every 0.2 s (weapons.json).

**Minion** (never changes over a run)
- `health` 4: two gun bullets at tier 1 (and still two with the garage's +50% bonus, 3 per bullet); the flame kills it on entry plus one tick (0.2 s). Weak alone, a threat in numbers, as a swarm enemy should be.
- `move_speed` 6 units/s: a bit over half cruise speed, so a moving car always outruns minions and only a car that stops, crashes or circles in place gets caught. This is a number the minion task needs that the ticket did not list; flagged for the board.
- `contact_damage` 5, `contact_damage_interval` 0.5 s: T-038 planned "about 5 to 10 per hit, so 10 to 20 hits". 5 per hit is 20 hits from full health; touching for a whole second costs 10. Any damage also cuts the combo by 80% (Game loop architecture), so the real cost of a hit is bigger than the health.
- `knockback` 8 units/s: about 70% of cruise speed, a clear shove that ends most contacts after one or two hits. Note from T-033: with W held and the nose pointing into the push, W's snap to cruise cancels the push along the nose, so a head-on minion barely moves the car.

**Spawning** (the count grows, nothing toughens)
- `minions_at_start` 12, `minions_at_boss_time` 20, in a straight line over `growth_until_seconds` 420 (the 7 minutes), then held during the kaiju's minute. +67%, under double, so "slightly"; the test checks it is higher at the end, never goes down, and stays under double. The combo multiplies this count (combo.json `spawning`, max x1.75), so a maxed combo at 7:00 means 35. Holding the count during the kaiju's minute is a choice the docs leave open; the board can change it.
- `spawn_interval_seconds` 0.5: while fewer than wanted are around, one spawns every 0.5 s, so the start fills up over 6 s instead of all at once, and kills are refilled at up to 2 per second.
- `spawn_margin_units` 3: spawn 3 units beyond the visible screen's edge (measured from the camera, so it follows the zoom slider), enough for a minion's body to be fully off-screen when it appears, and only about half a second's walk from the edge.

**Coins**
- `drop_chance` 0.6, `coins_per_drop` 2: 1.2 coins per kill on average. Rough estimate: an average run kills about 250 to 300 minions (around 0.6 kills per second over 7.5 minutes, from the weapons' damage against 4 health and the 12 to 20 minions around) and the player picks up most but not all coins, which lands near the 250 coins per average run that garage.json's prices assume. Frequent small drops (rather than rare big ones) keep pickups flowing during driving. The kaiju drops no coins: its death ends the run at once.

**Kaiju**
- `health` 500 (see the time to kill below).
- `move_speed` 3 units/s: slow (Enemies, Decisions), about a quarter of cruise speed, so the car can always get away and circle it.
- `contact_damage` 20, `contact_damage_interval` 1.0 s: a heavy hit, four times a minion's, because it is huge and easy to avoid at its speed; five seconds pressed against it ends a base-health run.
- `knockback` 16 units/s: twice a minion's, faster than cruise, so a touch throws the car clear of the kaiju.

**Meteor attack**
- `first_attack_after_seconds` 5, `seconds_between_attacks` 8: attacks at 5, 13, 21, 29, 37, 45 and 53 s after the kaiju appears, 7 attacks in its minute; the last one lands at 56 s, inside the minute.
- `windup_seconds` 1.0: the "short animation" before the meteors (a placeholder pause for now).
- `meteors_per_attack` 3: "several"; 21 meteors and up to 21 new boulders in the minute, enough to change the roads without blocking them.
- `warning_seconds` 2.0: decided (Enemies, Decisions), stored so the code reads it from one place; not a balancing number.
- `land_within_units_of_car` 10: "near the car", inside the visible screen at the default zoom (14.4 units from the car to the top and bottom edges), so the player sees every circle; at cruise speed the car crosses 22 units in the 2 s warning, so every meteor can be dodged.
- `impact_radius_units` 1.5: a meteor hits the car when the car's centre is within the boulder's own radius (boulders are 3 units across), so a hit means the boulder would have landed on the car.
- `impact_damage` 15: more than a minion hit, less than a kaiju touch; three direct hits take almost half a base-health car, and the 2 s warning makes it a punishment for not watching.
- `knockback` 20 units/s: the strongest push, it throws the car out of the boulder's spot.

**How long the MVP weapons take to bring the kaiju to 0** (500 health; checked by `test_kaiju_time_to_kill_matches_result_notes`, which works it out from weapons.json, garage.json and enemies.json). Assumptions: every gun bullet hits the kaiju (it is huge and the bullet's hit circle is 2 units across), and the flame is on the kaiju 30% of the fight (it is behind the car only while drifting past it). Gun damage per second = bullets x 2 / fire interval; flame = damage / 0.2 s x 0.3.

| Build at 7:00 | Damage per second | Time to kill |
|---|---|---|
| Gun tier 1 only (no level-ups) | 1.59 | 315 s (cannot win) |
| Average run, level 8 (flame, gun tier 4, flame tier 4) | 10.32 | 48.5 s |
| The same with the garage's damage bonus level 5 (+25%) | 12.90 | 38.8 s |
| Top level 12 (gun tier 6, flame tier 6) | 14.79 | 33.8 s |
| Every pick on the gun (gun tier 8, no flame) | 13.26 | 37.7 s |
| Gun tier 8, flame tier 4, garage bonus maxed (+50%) | 25.28 | 19.8 s |

So an average run wins with about 10 s to spare out of the 60, a strong or upgraded one comfortably, and a run with no level-ups cannot win. Two things make the real figure longer: the gun shoots the closest enemy, so minions nearer than the kaiju take shots away from it, and the flame share depends on how the player drives. If the board finds the kaiju too tough in playtests, lowering `health` is the one-number change (400 gives 38.8 s for the average run).

**Tests:** `test_enemy_data.gd` 9 of 9 pass. Full GUT suite: 392 of 392 pass (40 scripts, `TESTS PASSED`). Python tool tests: `game/tools` 141 OK, `tools` 115 OK.
