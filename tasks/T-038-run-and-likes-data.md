---
id: T-038
title: The run's numbers: likes (XP) per challenge, drift and level, and the car's starting health
status: open
from: project-lead
to: game-data
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/weapons.md, docs/garage-design.md, docs/enemies.md, game/README.md]
files_expected_to_change: [JSON data files under game/data/, a small loader with tests, game/README.md, docs/game-loop-architecture.md]
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

This is the Game Data Agent's first task. It sets up how game data is stored, and writes the numbers the run needs (Game loop architecture, Decisions).

1. **Where data lives:**
   - JSON files under `game/data/`, plus a small loader the other agents' code uses to read them. It gives a clear error if a file or value is missing.
   - Write the convention in `game/README.md` ("Game data"), so the enemy, weapon and garage data tasks follow it.
2. **Likes (XP) and levels**, within the decisions:
   - At level 1, one challenge fills the XP bar.
   - A second of drifting is worth a fixed 10% of the level-1 bar, at every level.
   - Work out sensible scaling: XP per challenge at each level, and how much XP each level needs. Decide whether leftover XP carries over.
   - An 8-minute run should give roughly the number of level-ups the weapons can use. In the MVP the level-up offers are the flamethrower and upgrades to both weapons (Weapons, Decisions). How many upgrade tiers exist comes from the Unity weapons report (T-022). If it isn't done yet, pick a level count that fits and say it will be revisited.
   - Explain the reasoning in the result notes, with a small table (level, XP needed, challenges or drift-seconds it takes). The board judges it in playtests.
3. **Car health:** the car's starting health as a number.
   - No doc gives it, so propose one and explain it. Enemy damage is balanced against it later.
   - The garage's car health upgrade (Garage design) will raise it in a later task.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The data files are valid JSON under `game/data/`, and a test loads them through the loader (QA: pass / fail)
- [ ] A test shows level 1's threshold equals the XP of one challenge at level 1 (QA: pass / fail)
- [ ] A test shows the XP per drift second is 10% of the level-1 threshold and is the same at every level (QA: pass / fail)
- [ ] A test shows the loader gives a clear error for a missing file or value (QA: pass / fail)
- [ ] The result notes have the table of levels and the reasoning, and propose the car's starting health with a reason (QA: pass / fail)
- [ ] `game/README.md` has the "Game data" section. `docs/game-loop-architecture.md` points to the data file in References, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: look at the level table and the starting health.

## Result notes

Written by the agent when it finishes.
