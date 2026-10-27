---
id: T-323
title: "Game data: the Bricks weapon's numbers and upgrade tiers"
status: in-qa
from: project-lead
to: game-data
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/drifting.md, docs/enemies.md, game/README.md, game/data/]
files_expected_to_change: [game/data/, game/scripts/data/, game/tests/unit/, docs/weapons.md, game/README.md]
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

The board's decision (Weapons, Decisions, "Bricks", 2026-10-28). Propose Bricks' numbers in the game's weapon data, the way the three G-002 weapons were (Weapons, Content, "Numbers for the three new weapons"): the impact wave's damage, its radius, its knockback (if any), how short a time in the air still counts as a landing (so a bump in the road doesn't fire it), a cooldown if one is needed, and the upgrade tiers (how many, and what each raises). First build: the same wave whatever the height of the fall. Compare with the other weapons' damage per second at the same tier and with how often a player lands in a run on the elevation map (Drifting, Content, the airtime trick), and say why. Add Bricks to the level-up offers' list of weapons in the data, so T-324 can make it available. Numbers only; no behaviour.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [x] Bricks' numbers and tiers are in the weapon data, read through the game's data scripts like the other weapons (test that loads them). (QA: PASS. weapons.json "bricks" with 7 tiers, read by WeaponData.bricks_at(); test_bricks_numbers_and_tiers loads it. Bricks is not in level_up_offers WEAPON_ORDER/ALL_IDS and offered_in_level_ups is false, checked by test_bricks_not_offered_until_built.)
- [x] Weapons, Content, "Bricks" lists each number with the reason for it. (QA: PASS. Damage, radius, knockback, min air time, cooldown, same-wave rule and tiers each have a reason, plus a comparison with the other weapons.)
- [x] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: PASS. game/tools 620 OK (1 skipped); tools 501 OK; GUT 1690/1690.)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Started: the Game Data Agent is proposing Bricks' numbers and tiers.

### 2026-10-27, In progress → In QA

Built: Bricks' numbers and 7 tiers are in the data, kept out of the offers until T-324 builds the weapon. QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Bricks' numbers are in `game/data/weapons.json` ("bricks"), read through `WeaponData.bricks_at(tier)`. Proposals, with the reason for each in Weapons, Content, "Bricks (numbers proposed in task T-323)":

- damage 6 (kills a minion, health 4, from tier 1; landings are rare so one hit is big), radius 4, knockback 4 (minions only, never the kaiju), minimum air time 0.3 s (the airtime trick's `min_seconds`, so a bump does not fire it), cooldown 0.5 s (no stacked waves from bounces).
- 7 tiers, like the wiper: 2 radius x1.2; 3 damage x1.5; 4 knockback x1.5; 5 radius x1.25; 6 damage x1.5; 7 knockback x1.5; 8 radius x1.3 (final radius 7.8, damage 13.5, knockback 9).
- Offers: there is no weapon list in the data; the offers' list is code (`WEAPON_ORDER` and `ALL_IDS` in `level_up_offers.gd`). Adding Bricks there would change the choices (nine to eleven) before the weapon exists, so it is kept out: the data has `offered_in_level_ups: false` (`WeaponData.bricks_offered()`). To turn it on, T-324 sets that true, adds `bricks` to `WEAPON_ORDER` and `get_bricks` / `upgrade_bricks` to `ALL_IDS`, and updates the tests that list five weapons (`test_level_up_offers.gd`, `test_all_weapons_run.gd`).
- Tests: `game/tests/unit/test_weapon_data.gd` (new `test_bricks_numbers_and_tiers`, `test_bricks_not_offered_until_built`; the tier-count and weapon-count tests now include Bricks).
- Test results: `game/tools` 620 tests OK (1 skipped); `tools` 501 OK; `run_tests.sh` 1690 of 1690 GUT tests pass.
- Documents updated: docs/weapons.md, game/README.md.
- Not done: no behaviour, no level-up card or art (T-322, T-324, T-325).
