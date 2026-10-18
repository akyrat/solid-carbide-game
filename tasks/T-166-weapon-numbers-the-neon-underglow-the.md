---
id: T-166
title: Weapon numbers: the neon underglow, the molotovs and the windshield wiper, with 8 tiers each
status: done
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

The board added three weapons to the MVP (docs/weapons.md, Decisions, 2026-10-18): the neon underglow (a circle around the car; enemies inside take damage every second, and an enemy takes damage as soon as it enters), the molotovs (thrown from the car at random; each leaves a circular fire area where it lands, and enemies burn and take damage only while inside it), and the windshield wiper (one wiper in front of the car, always sweeping a semicircle; it damages what it hits, pushes minions back but not the kaiju). Each has 8 tiers like the gun and the flamethrower: tier 1 is getting it, tiers 2 to 8 are 7 upgrades. The numbers and what each tier changes are your proposal, judged in the board's playtest.

Add one entry per weapon to `game/data/weapons.json` (ids `underglow`, `molotov`, `wiper`) in the same shape as the gun's and the flamethrower's: base values (for example damage, radius, tick interval; for the molotovs the throw interval, how far from the car they land, the fire area's radius and how long it lasts; for the wiper its length, sweep speed and knockback strength) and a `tiers` list of exactly 7 entries (tiers 2 to 8), each an `effect` and a `value`. Units and seconds as in the file's comment; update the comment, which today says no weapon pushes. Make `weapon_data.gd` read the new entries the way it reads the existing two, and extend the data test. Write the proposal and its reasoning (why these numbers, how they compare with the gun and the flamethrower) in your result notes. Do not invent anything the docs don't say beyond the numbers and tier effects.

## Acceptance criteria

- [ ] `game/data/weapons.json` has entries `underglow`, `molotov` and `wiper`, each with base values and a `tiers` list of exactly 7 entries numbered 2 to 8, each with an `effect` and a `value`; the gun's and the flamethrower's entries are unchanged. (QA: pass; diff adds three entries with 7 tiers 2 to 8, gun and flame lines untouched)
- [ ] The wiper's entry has a knockback strength, and the file's comment no longer says that no weapon pushes enemies (it says only the wiper pushes, and only minions). (QA: pass; knockback_distance 1.5, comment updated)
- [ ] `weapon_data.gd` returns the new weapons' base values and tiers, and `game/tests/unit/test_weapon_data.gd` checks there are 5 weapons, each with tiers 1 to 8 (base plus 7 tiers); the game's test set passes. (QA: pass; full suite 850/850, test_weapon_data 13/13)
- [ ] The result notes hold the proposed numbers and tier effects for the three weapons with the reasoning for each. (QA: pass)
- [ ] `docs/weapons.md` Content lists the three weapons' numbers and tiers and says they are proposals for the board's playtest; `game/README.md` 'Game data' mentions the new entries. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-18, Open → In progress

Goal runner (G-002): started, in C:\solid-carbide-worktrees\T-166.

### 2026-10-18, In progress → In QA

Goal runner (G-002): the agent is done; QA is checking it.

### 2026-10-18, In QA → Done

Goal runner (G-002): QA passed; merged into playtest/G-002.

## Result notes

Game Data Agent. Added `underglow`, `molotov` and `wiper` to `game/data/weapons.json` (gun and flamethrower untouched; comment updated: only the wiper pushes, minions only). `WeaponData` got `underglow_at`, `molotov_at`, `wiper_at`; the data test now covers 5 weapons x (base + 7 tiers) and the new values. Docs: `docs/weapons.md` Content ("Numbers for the three new weapons") and `game/README.md` "Game data". **Tests run (second pass):** `bash game/tools/run_tests.sh`: 850/850 passing, including `test_weapon_data.gd` 13/13 (five weapons x 8 tiers, the new tier tests, wiper knockback). The JSON loads through the loader in those tests.

Proposal (all for the board's playtest; the garage damage bonus multiplies each):

- **Underglow:** radius 2.5, 1 damage on entering and every 1 s (damage_on_enter). Tiers: 2 radius x1.2; 3 damage x1.5; 4 interval x0.75; 5 radius x1.25; 6 damage x1.5; 7 interval x0.67; 8 radius x1.3. Reasoning: it is always on and needs no aim, so it starts weak (1 dps, below the gun's ~1.6 dps per bullet and far below the flamethrower's 10 dps) and grows by area, damage and speed in turns; final about 4.5 dps in a 5.85 radius, a constant wide aura but still under the flamethrower's burst.
- **Molotov:** one per 3 s, lands 3 to 8 units away at random, fire radius 1.5 for 3 s, 2 damage on entering and every 0.5 s inside (4 dps per enemy, area stays on the ground). Tiers: 2 radius x1.2; 3 interval x0.8; 4 damage x1.5; 5 +1 molotov; 6 +1.5 s fire; 7 radius x1.3; 8 +1 molotov. Final: 3 per throw every 2.4 s, radius 2.34, 4.5 s, 3 damage. Reasoning: random placement and delay make it less reliable than the flamethrower, so per-enemy dps is mid (4 to 6) and strength comes from stacked area and count.
- **Wiper:** arm 2.5 long, 180 degree sweep at 240 deg/s (a pass every 0.75 s), 3 damage per hit, same enemy hit again after 0.5 s, minions pushed 1.5 units, kaiju not pushed (knockback_kaiju false). Tiers: 2 length x1.2; 3 damage x1.4; 4 speed x1.25; 5 knockback x1.5; 6 length x1.3; 7 damage x1.4; 8 speed x1.3. Final: length 3.9, damage about 5.9, knockback 2.25. Reasoning: short range but high per-hit damage and crowd control; knockback keeps minions off the car, so it is a defensive weapon with the lowest reach of the five.

Open for the board: the enter-damage and tick values are guesses until played; the knockback unit (distance moved, in units) is my reading of "pushes back".
- 2026-10-18, in-qa → done: QA passed every criterion (goal G-002).
