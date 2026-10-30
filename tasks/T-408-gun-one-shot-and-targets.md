---
id: T-408
title: Gun: one-shots a minion from tier 1; upgrades are +1 bullet x2, faster x2, 3 targets, +1 bullet x2, faster x2, 5 targets
status: needs-playtest
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-412]
documents_affected: [docs/weapons.md, game/docs/weapons/starting-gun.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/enemies.md, game/docs/weapons/starting-gun.md, game/docs/weapons/shared.md, game/data/weapons.json, game/data/enemies.json]
files_expected_to_change: [game/scripts/weapons/, game/data/weapons.json, game/tests/unit/, game/docs/weapons/, docs/weapons.md, art-archive/]
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

The board's decision (Weapons, Decisions, "The gun one-shots minions and grows in bullets, speed and targets", 2026-10-30). The board: "make it so that the gun, its initial damage, takes the mini kaiju enemies in one hit and concentrate its level progression towards speed and quantity of bullets ... 2 upgrades that give +1 bullet, 2 upgrades that give attack speed. And then at the halfway of all the upgrades, it can target up to 3 enemies at the same time, because it's already going to have at least 3 bullets ... And then another 2 quantity, 2 attack speed. And then it can target up to 5 enemies at the same time."

- **Damage:** tier 1's bullet damage is at least a minion's maximum health (`enemies.json`), so one bullet kills one; with the garage damage bonus it only grows. The kaiju takes the same bullet damage (say what that does to its fight in the result notes).
- **Tiers 2 to 11** (proposal for the order the board gave): 2 and 3 +1 bullet each (3 bullets); 4 and 5 shorter interval; 6 targets up to 3; 7 and 8 +1 bullet each (5 bullets); 9 and 10 shorter interval; 11 (the last) targets up to 5. The old range and pass-through tiers go; the range stays at tier 1's 12 units. The intervals are your proposal (today 1.26 s at tier 1).
- **Targets:** today a volley's bullets go closest first, round the enemies in range. The board's "targets up to N enemies at once" needs a rule below tier 6 too: propose one in the result notes (for example below tier 6 a volley aims at the closest enemy only, retargeting to the next closest when it dies mid-volley, so no bullet is wasted on a dead minion), and from tier 6 the volley spreads over up to 3, from tier 11 up to 5, with the bullets fired at the same time rather than 0.05 s apart if that reads better.
- The level-up offers use the gun's last tier (now 11) from the data, not a hard-coded 8. The level-up card shows the weapon, not per-tier text (check `screen_texts.json`); if a tier line does show, stop and tell the Project Lead (a text ticket comes first).

Other agents work at the same time on the minions (T-379 twice as big, T-380 ramps) and the red flash on hits (T-403, T-404): keep to the gun's code and data.

The board's review: in a run, take the gun's upgrades one by one (the playtest switch or the level-ups) and watch minions die in one bullet, the volleys grow and spread to 3 then 5 targets.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [x] At tier 1 one bullet kills a minion (test). (QA: pass)
- [x] Tiers 2 to 11 follow the order in the description, read from `weapons.json` (tests), and the level-ups offer the gun up to tier 11. (QA: pass)
- [x] The targeting rule below tier 6, from tier 6 (up to 3) and at tier 11 (up to 5) behaves as the result notes propose (tests). (QA: pass)
- [x] The gun still aims only at enemies on the car's level and stops when the run is paused or over (existing tests). (QA: pass)
- [x] Weapons (Content, "The starting gun") and game/docs/weapons/starting-gun.md describe the new tiers and the targeting rule; the open question on fire rate is closed. (QA: pass)
- [x] A GIF of the gun at tier 1, tier 6 and tier 11 against a swarm is in `art-archive/<id>/screenshots/`. (QA: pass)
- [x] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started in build F: the gun one-shots minions and grows in bullets, speed and targets.

### 2026-10-30, Blocked → In progress

T-412's card text is in; building the gun now.

### 2026-10-30, In progress → In QA

Gun built: 4 damage one-shots minions; tiers 2-11 in the board's order up to 5 targets; per-weapon last tier (gun 11); all three test sets pass; GIF in art-archive.

### 2026-10-30, In QA → Needs playtest

QA passed all 7 criteria; tests green (GUT all passed, python sets OK). Gun card text matches T-412. Ready for your playtest.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

### 2026-10-30, Weapon Behavior Agent: stopped before building (a tier line shows on the level-up card)

The description says: "The level-up card shows the weapon, not per-tier text (check `screen_texts.json`); if a tier line does show, stop and tell the Project Lead (a text ticket comes first)." A tier line does show, so no code or data was changed.

- **Where:** `game/scripts/ui/level_up_screen.gd` `card_text(id)` builds the key `upgrade_<weapon>.tier<N>` (N = the weapon's tier now + 1) and the card draws its `.title` and `.desc` (lines 450, 506, 512). The text lives in `game/scripts/ui/level_up_texts.gd` (not in `screen_texts.json`, which has no gun lines).
- **The gun's lines today** (`level_up_texts.gd` lines 13 to 26), tiers 2 to 8 only: tier 2 "Bonus Bullets" ("Two extra bullets per volley, 3 in all"), 3 "Quicker Trigger" (20% faster), 4 "Quicker Trigger II", 5 "Long Reach" (range 12 to 18), 6 "More Bonus Bullets" ("5 in all"), 7 "Quicker Trigger III", 8 "Through and Through" (pierce).
- **What the new tiers would show:** tier 2 would claim two extra bullets (now one), tier 5 a range that no longer grows, tier 6 more bullets (now targets up to 3), tier 8 pierce (now +1 bullet), and tiers 9, 10 and 11 would have empty cards (no keys). The UI test `test_level_up_screen.gd` `test_every_choice_and_tier_the_offers_can_produce_has_text` would also fail once the gun reaches 11 (it checks every offerable tier has a title, and counts `7 + 5 * 8` choices).
- **The text ticket needs** ten gun card lines (title and description each) for `upgrade_gun.tier2` to `upgrade_gun.tier11`, in the order the description gives: 2 and 3 "+1 bullet" (2, then 3 bullets per volley), 4 and 5 "fires faster", 6 "aims at up to 3 enemies at once", 7 and 8 "+1 bullet" (4, then 5), 9 and 10 "fires faster", 11 "aims at up to 5 enemies at once". The exact intervals are still my proposal; if the text should quote numbers, I propose a tier 1 interval of 1.26 s as today, then each "faster" tier multiplying the fire rate by 1.25: 1.02 and 0.83 s at tiers 4 and 5, 0.68 and 0.55 s at tiers 9 and 10 (base 1.2 / rate + 0.06). Safer for the text to say "faster" without a number.
- After the text is in, this ticket's build is unchanged in scope: a per-weapon last tier in `weapons.json` (gun 11, the others stay 8) read by `WeaponData`/`weapon.gd` so the level-ups offer the gun to 11; tier 1 damage at least the minion's 4 health (today 2); the new tier effects and targeting rule; the UI test's count; tests, docs and the GIF.

Tests: none run (nothing changed). Documents affected: none yet.
- 2026-10-30, in-progress → blocked: Stopped: the level-up card shows per-tier gun text (level_up_texts.gd); a text ticket for upgrade_gun.tier2-11 comes first.

### 2026-10-30, Weapon Behavior Agent: built (after T-412)

The proposal above (×1.25 per "faster" tier) is superseded: the Project Lead's numbers and T-412's cards say 20% faster, so `fire_rate_multiplier` 1.2.

**Data** (`game/data/weapons.json`, gun): `damage` 4 (= `enemies.json` minion.health 4), `max_tier` 11 (the gun's own), `targets_per_volley` 1, tiers 2 and 3 `add_bullets` 1, 4 and 5 `fire_rate_multiplier` 1.2, 6 `set_targets` 3, 7 and 8 `add_bullets` 1, 9 and 10 `fire_rate_multiplier` 1.2, 11 `set_targets` 5. The range and pierce tiers are gone; range stays 12 at every tier. Per tier (bullets / interval s / targets): 1: 1/1.26/1, 2: 2/1.26/1, 3: 3/1.26/1, 4: 3/1.06/1, 5: 3/0.893/1, 6: 3/0.893/3, 7: 4/0.893/3, 8: 5/0.893/3, 9: 5/0.754/3, 10: 5/0.639/3, 11: 5/0.639/5.

**Per-weapon last tier (covers T-422 for the gun):** `WeaponData.max_tier(weapon := "")` returns the weapon's own `max_tier` when its entry has one, else the shared top-level 8; `weapon.gd` `max_tier()` asks with its own `weapon_id`, so `is_max_tier()`, `upgrade()` and the level-up offers stop the gun at 11 and every other weapon at 8 with no hard-coded number. T-422's second point (a 0-bullet volley popping an empty queue) is guarded too: no volley when `bullets` is 0, and `_fire_next()` returns on an empty queue (tested). T-422 can be closed or reduced to the other weapons, which need nothing today.

**Targeting rule (my proposal, for the playtest):** enemies in range on the car's level, closest first; the tier's `targets` says how many a volley aims at.
- Below tier 6 (1 target): the whole volley goes at the closest enemy, bullets 0.05 s apart. A bullet whose target has died by the time it leaves goes at the closest living enemy in range, and so does the rest of the volley. Honest caveat: with one-shot damage and a 0.8 s flight to 12 units, the closest minion is usually still alive when bullets 2 and 3 leave, so at tiers 2 to 5 those extra bullets often follow the first one; they fly on past a dead minion and can hit one behind it (they hit any enemy in their path). Their full weight shows on the kaiju and on tougher enemies. This is the board's "targets 1 until halfway" taken literally; if the board wants the extra bullets to count against minions earlier, the cheapest change is to skip a target already "doomed" by bullets in flight (a few lines). **Superseded by the doomed-target fix below (Project Lead, 2026-10-30).**
- From tier 6 (up to 3; tier 11 up to 5): the volley aims at that many of the closest; bullet i goes to target i mod their count (closest first, round again), and the whole volley leaves in the same step, a fan, which reads better than 0.05 s apart.

**The kaiju** takes the same 4 a bullet. Gun alone (kaiju 500 health): about 158 s at tier 1 (was 315), 22 s at tier 8 (was 38), 16 s at tier 11; average run (gun 4, flame 4) 33.5 s (was 48.5), with garage bonus 5 26.8 s; top level (gun 6, flame 6) 29.4 s (was 33.8). The gun alone at tier 1 still takes over 60 s. `test_enemy_data.gd` `test_kaiju_time_to_kill_matches_result_notes` updated to these numbers (an Enemy test reading the gun's data; Enemies itself has no gun numbers, nothing stale there).

**Text:** T-412's ten gun cards copied into `game/scripts/ui/level_up_texts.gd` (`upgrade_gun.tier2` to `tier11`; the underglow lines left to T-409).

**Files:** `game/data/weapons.json`, `game/scripts/data/weapon_data.gd`, `game/scripts/weapons/weapon.gd`, `game/scripts/weapons/starting_gun.gd`, `game/scripts/weapons/level_up_offers.gd` (comment), `game/scripts/ui/level_up_texts.gd`; tests `game/tests/unit/weapons/test_starting_gun.gd`, `game/tests/unit/test_weapon_data.gd`, and the gun's numbers in `test_enemy_data.gd`, `test_level_up_screen.gd`, `weapons/test_level_up_offers.gd`, `weapons/test_all_weapons_run.gd`, `weapons/test_damage_bonus.gd`; GIF fixture `game/tests/fixtures/gun_tiers_gif_demo.gd`/`.tscn` and `game/tools/record_gun_tiers_gif.sh`.

**New tests** (`test_starting_gun.gd`): one bullet kills a minion at tier 1; below tier 6 the volley at the closest only, 0.05 s apart; a target dying mid-volley passes the rest to the next closest; tiers 6 and 7 over the 3 closest at once (4 bullets round again, the 4th closest never aimed at); one enemy takes a tier 6 volley at once; tier 11 over the 5 closest at once; no volley with 0 bullets; every tier 1 to 11 equal to the data and the last tier 11; the level-ups offer the gun at tier 10, not at 11; tiers 2, 3, 7, 8 add one bullet; tiers 4, 5, 9, 10 shorten the interval; range 12 at tier 11. `test_weapon_data.gd`: the board's order for every tier, damage >= the minion's health from `enemies.json`, the gun's last tier 11 and the others' 8. The level-filter and pause/run-over gun tests are unchanged and pass.

**GIF:** `art-archive/T-408/screenshots/gun_tiers_1_6_11.gif` (15 s: 5 s each at tier 1, 6, 11, a fresh swarm of 14 real minions each phase; the HUD's gun icon shows x6 and x11). Re-record: `bash game/tools/record_gun_tiers_gif.sh <out.gif> 3` with `GIF_ARGS="--shared --scale 0.5"`.

**Tests (all three sets):** `python -m unittest discover -s game/tools -p "test_*.py"`: 678 run, OK (1 skipped). `python -m unittest discover -s tools -p "test_*.py"`: 579 run, OK. `bash game/tools/run_tests.sh`: 158 scripts, 1952 tests, 1952 passing, 1247828 asserts. (An earlier full run had one failure in `test_run_likes.gd`, a drift-payment timing test unrelated to the gun; it passed in the final run.)

**Doomed-target fix (Project Lead, 2026-10-30, before QA):** below tier 6 each bullet, as it leaves, skips a target that is dead or doomed (the gun's bullets still in flight at it carry at least its health: `starting_gun.gd` `is_doomed()` / `damage_in_flight()`, tracking `[bullet, target]` pairs in `_in_flight`) and goes to the closest living, not doomed enemy in range; when every enemy in range is doomed it keeps its target. Against one-shot minions, bullet 1 goes to the closest, bullet 2 to the next closest and so on, so each +1 bullet upgrade kills one more minion per volley. A tough enemy (the kaiju) still takes the whole volley. From tier 6 the fan is unchanged. New tests: `test_below_tier_6_bullets_skip_a_minion_already_doomed` (3 real minions at tier 3: one bullet each, all three die) and `test_below_tier_6_a_tough_target_keeps_the_whole_volley`. The GIF is unchanged: tier 1 fires one bullet, and tiers 6 and 11 use the fan. Tests after the fix: game/tools 678 run, OK (1 skipped); tools 579 run, OK; GUT 158 scripts, 1954 tests, 1954 passing, 1247839 asserts.

**Documents affected:** `docs/weapons.md` (Content, "The starting gun": targeting rule, damage, tiers 2 to 11, the kaiju; "The level-up offers": each weapon's own last tier; Open questions: the fire-rate question closed), `game/docs/weapons/starting-gun.md`.
