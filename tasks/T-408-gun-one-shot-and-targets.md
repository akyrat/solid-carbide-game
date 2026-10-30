---
id: T-408
title: Gun: one-shots a minion from tier 1; upgrades are +1 bullet x2, faster x2, 3 targets, +1 bullet x2, faster x2, 5 targets
status: open
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

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
