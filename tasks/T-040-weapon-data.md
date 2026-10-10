---
id: T-040
title: Weapon numbers: the gun, the flamethrower and their upgrade tiers
status: in-progress
from: project-lead
to: game-data
epic: weapons
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-022, T-038]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/weapons/unity-weapons-report.md, tasks/T-038-run-and-likes-data.md, game/README.md]
files_expected_to_change: [JSON data under game/data/, tests, docs/weapons.md, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: in-progress | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-022 (the Unity weapons report) and T-038 (the data convention) are done.**

Weapons, Decisions says both MVP weapons and their upgrades copy the Unity prototype: the same tiers and what each tier changes. The Game Data Agent works out how upgrades scale from level to level, starting from the Unity values.

Write as JSON under `game/data/`:
- **The starting gun:** damage, range, fire interval, bullet speed, and anything else the report lists.
- **The exhaust flamethrower:** damage, the flame's size and shape values, how damage is applied over time, and anything else the report lists.
- **Each weapon's upgrade tiers:** what each tier changes, with its values.

Use the report's values where it gives them, and say in the result notes where you scaled or filled in.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The data is valid JSON under `game/data/`, and a test loads it through T-038's loader (QA: pass / fail)
- [ ] A test compares the base values and tier changes with the report's tables and shows they match, except where the result notes explain a difference (QA: pass / fail)
- [ ] `docs/weapons.md` points to the data in References, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
