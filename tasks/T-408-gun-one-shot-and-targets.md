---
id: T-408
title: Gun: one-shots a minion from tier 1; upgrades are +1 bullet x2, faster x2, 3 targets, +1 bullet x2, faster x2, 5 targets
status: blocked
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/weapons.md, game/docs/weapons/starting-gun.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/enemies.md, game/docs/weapons/starting-gun.md, game/docs/weapons/shared.md, game/data/weapons.json, game/data/enemies.json]
files_expected_to_change: [game/scripts/weapons/, game/data/weapons.json, game/tests/unit/, game/docs/weapons/, docs/weapons.md, art-archive/]
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

The board's decision (Weapons, Decisions, "The gun one-shots minions and grows in bullets, speed and targets", 2026-10-30). The board: "make it so that the gun, its initial damage, takes the mini kaiju enemies in one hit and concentrate its level progression towards speed and quantity of bullets ... 2 upgrades that give +1 bullet, 2 upgrades that give attack speed. And then at the halfway of all the upgrades, it can target up to 3 enemies at the same time, because it's already going to have at least 3 bullets ... And then another 2 quantity, 2 attack speed. And then it can target up to 5 enemies at the same time."

- **Damage:** tier 1's bullet damage is at least a minion's maximum health (`enemies.json`), so one bullet kills one; with the garage damage bonus it only grows. The kaiju takes the same bullet damage (say what that does to its fight in the result notes).
- **Tiers 2 to 11** (proposal for the order the board gave): 2 and 3 +1 bullet each (3 bullets); 4 and 5 shorter interval; 6 targets up to 3; 7 and 8 +1 bullet each (5 bullets); 9 and 10 shorter interval; 11 (the last) targets up to 5. The old range and pass-through tiers go; the range stays at tier 1's 12 units. The intervals are your proposal (today 1.26 s at tier 1).
- **Targets:** today a volley's bullets go closest first, round the enemies in range. The board's "targets up to N enemies at once" needs a rule below tier 6 too: propose one in the result notes (for example below tier 6 a volley aims at the closest enemy only, retargeting to the next closest when it dies mid-volley, so no bullet is wasted on a dead minion), and from tier 6 the volley spreads over up to 3, from tier 11 up to 5, with the bullets fired at the same time rather than 0.05 s apart if that reads better.
- The level-up offers use the gun's last tier (now 11) from the data, not a hard-coded 8. The level-up card shows the weapon, not per-tier text (check `screen_texts.json`); if a tier line does show, stop and tell the Project Lead (a text ticket comes first).

Other agents work at the same time on the minions (T-379 twice as big, T-380 ramps) and the red flash on hits (T-403, T-404): keep to the gun's code and data.

The board's review: in a run, take the gun's upgrades one by one (the playtest switch or the level-ups) and watch minions die in one bullet, the volleys grow and spread to 3 then 5 targets.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] At tier 1 one bullet kills a minion (test). (QA: pass / fail)
- [ ] Tiers 2 to 11 follow the order in the description, read from `weapons.json` (tests), and the level-ups offer the gun up to tier 11. (QA: pass / fail)
- [ ] The targeting rule below tier 6, from tier 6 (up to 3) and at tier 11 (up to 5) behaves as the result notes propose (tests). (QA: pass / fail)
- [ ] The gun still aims only at enemies on the car's level and stops when the run is paused or over (existing tests). (QA: pass / fail)
- [ ] Weapons (Content, "The starting gun") and game/docs/weapons/starting-gun.md describe the new tiers and the targeting rule; the open question on fire rate is closed. (QA: pass / fail)
- [ ] A GIF of the gun at tier 1, tier 6 and tier 11 against a swarm is in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started in build F: the gun one-shots minions and grows in bullets, speed and targets.

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
