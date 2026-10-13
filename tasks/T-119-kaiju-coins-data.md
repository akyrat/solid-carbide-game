---
id: T-119
title: Data: the kaiju drops a few coins when defeated
status: in-progress
from: project-lead
to: game-data
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, docs/garage-design.md, game/data/enemies.json, tasks/T-039-enemy-data.md, game/README.md]
files_expected_to_change: [game/data/enemies.json, game/scripts/data/enemy_data.gd, its tests, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's decision (Enemies, Decisions, 2026-10-13): when the kaiju is defeated it always drops a few coins (100% chance). T-039 proposed that the kaiju drops none; change that.

1. Add the kaiju's coin drop to `game/data/enemies.json`: a 100% chance (or simply "always") and a small number of coins. "A few" is the board's word: propose the number, in the same range as a handful of minion drops (a minion drop is 2 coins), and explain it against the roughly 250 coins a run that the garage prices assume.
2. Expose it through `enemy_data.gd`, the way the other enemy numbers are read.
3. Update the `_comment` and T-039's reasoning where it said the kaiju drops none (in the JSON comment and game/README.md; leave T-039's finished task file as history).
4. Tests: the kaiju's drop chance is 1 and its coin count is above 0 and small.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] `game/data/enemies.json` gives the kaiju a 100% coin drop of a few coins, read through `enemy_data.gd`, and a GUT test checks the chance is 1 and the count is above 0 (QA: pass / fail)
- [ ] The result notes explain the number of coins; nothing in the JSON comment or game/README.md still says the kaiju drops no coins (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
