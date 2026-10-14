---
id: T-042
title: The exhaust flamethrower: fires only while drifting
status: open
from: project-lead
to: weapon-behavior
lead:
epic: weapons
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-022, T-040, T-036, T-044]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/weapons/unity-weapons-report.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, docs/drifting.md, tasks/T-036-run-scene-and-state.md, tasks/T-044-minions.md, tasks/T-041-starting-gun.md, game/README.md]
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

**Blocked until T-022 (the report), T-040 (the numbers), T-036 (the run) and T-044 (the minions) are done.**

Build the exhaust flamethrower as Weapons, Decisions describes it, copying the Unity prototype's flame shape and trigger from T-022's report:
- Flames come out of the car's exhaust, only while the car is drifting (the car's drift state from T-012).
- The flames damage enemies they touch, through T-044's damage function, as the data describes.
- The player doesn't start with it; it is gained at a level-up (T-043).
- Its upgrade tiers (T-040's data) can be applied from code.
- It resets at the start of every run.

The flames are placeholders for now. The final flame art comes from a separate art task and replaces them.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test shows the flames are active only while the car is drifting, and stop when it stops drifting (QA: pass / fail)
- [ ] A test shows an enemy inside the flames takes damage as the data describes, and one outside does not (QA: pass / fail)
- [ ] A test applies each upgrade tier and shows the changed values take effect (QA: pass / fail)
- [ ] A test shows a new run starts without the flamethrower (QA: pass / fail)
- [ ] A screenshot shows placeholder flames behind the drifting car (QA: pass / fail)
- [ ] `docs/weapons.md` describes the built flamethrower in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

Written by the agent when it finishes.
