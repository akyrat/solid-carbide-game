---
id: T-409
title: Neon underglow: each tick deals half a minion's health (2 ticks kill), and it knocks enemies back a little from tier 1
status: open
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-412]
documents_affected: [docs/weapons.md, game/docs/weapons/neon-underglow.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/enemies.md, game/docs/weapons/neon-underglow.md, game/docs/weapons/shared.md, game/data/weapons.json, game/data/enemies.json]
files_expected_to_change: [game/scripts/weapons/, game/data/weapons.json, game/tests/unit/, game/docs/weapons/, docs/weapons.md, art-archive/]
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

The board's decision (Weapons, Decisions, "The neon underglow kills a minion in 2 ticks and pushes from tier 1", 2026-10-30). The board: "make the neon zone deal half of the max HP: it takes 2 ticks of damage for the mini enemies to die from the neon, that's its initial damage. And make it so that even initially, enemies are knocked back a little bit."

- **Damage:** tier 1's tick damage is half a minion's maximum health (`enemies.json`), so 2 ticks kill one; later tiers keep their multipliers from the new base.
- **Push:** from tier 1 each tick knocks the enemy back a little, away from the car's centre (minions; for the kaiju, follow the wiper's rule: it damages the kaiju but pushes only minions, unless you propose otherwise). How far (a small distance, a proposal) and whether it grows with the tiers, in `weapons.json`.
- The level-up card shows the weapon, not per-tier text (check `screen_texts.json`); if a tier line does show, stop and tell the Project Lead.

Other agents work at the same time on the minions (T-379 twice as big, T-380 ramps), the gun (T-408) and the red flash on hits (T-404): keep to the underglow's code and data.

The board's review: in a run, get the neon underglow and drive into a swarm: minions die in two ticks and are pushed back a little.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] At tier 1 a minion dies on its second tick and not its first (test). (QA: pass / fail)
- [ ] From tier 1 each tick pushes a minion away from the car by the distance in `weapons.json` (test); the kaiju behaves as the result notes say (test). (QA: pass / fail)
- [ ] Later tiers keep their multipliers from the new base (test). (QA: pass / fail)
- [ ] Weapons (Content, "The neon underglow") and game/docs/weapons/neon-underglow.md describe the new damage and the push. (QA: pass / fail)
- [ ] A GIF of the underglow in a swarm is in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
