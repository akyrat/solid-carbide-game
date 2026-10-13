---
id: T-041
title: The starting gun: aims itself and fires at enemies in range
status: blocked
from: project-lead
to: weapon-behavior
lead:
epic: weapons
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-022, T-040, T-036, T-044]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/weapons/unity-weapons-report.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-036-run-scene-and-state.md, tasks/T-044-minions.md, game/README.md]
files_expected_to_change: [the weapon code and scenes, tests, docs/weapons.md, game/README.md]
model: opus
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

**Blocked until T-022 (the report), T-040 (the numbers), T-036 (the run) and T-044 (the minions it shoots at) are done.**

Build the starting gun as Weapons, Decisions describes it, copying the Unity prototype's behaviour from T-022's report:
- The car starts every run with it. There is no visible weapon on the car, only the bullets it fires.
- It fires only when an enemy is within range, aims by itself, and fires at set intervals.
- Bullets damage enemies through the damage function T-044 defines.
- Its upgrade tiers (T-040's data) can be applied from code. Offering them at a level-up is T-043.
- Weapons reset at the start of every run: a new run starts with the base gun.

The bullets are placeholders for now (a simple shape in the palette). The final bullet art comes from a separate art task and replaces them.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test with no enemy in range shows the gun never fires, and with an enemy in range it fires at the interval in T-040's data (QA: pass / fail)
- [ ] A test shows bullets go for the target the report's targeting rule picks (the rule is named in the result notes) and damage it by the data's amount (QA: pass / fail)
- [ ] A test applies each upgrade tier and shows the changed values take effect (QA: pass / fail)
- [ ] A test shows a new run starts with the base gun and no upgrades (QA: pass / fail)
- [ ] A screenshot shows the car firing placeholder bullets at a minion (QA: pass / fail)
- [ ] `docs/weapons.md` describes the built gun in Content, and `game/README.md` says how weapons plug into the run, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

Written by the agent when it finishes.
