---
id: T-039
title: Enemy numbers: minions, spawning, coins and the kaiju
status: open
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

Written by the agent when it finishes.
