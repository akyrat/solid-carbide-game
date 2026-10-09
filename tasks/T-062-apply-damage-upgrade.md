---
id: T-062
title: Garage upgrade: damage bonus applied to the weapons
status: blocked
from: project-lead
to: weapon-behavior
epic: garage
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-057, T-041, T-042]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, docs/game-loop-architecture.md, docs/weapons.md, tasks/T-057-save-and-buy.md, tasks/T-041-starting-gun.md, tasks/T-042-exhaust-flamethrower.md, game/README.md]
files_expected_to_change: [the weapon code, tests, game/README.md]
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

**Blocked until T-057 (the saved upgrade levels), T-041 (the gun) and T-042 (the flamethrower) are done.**

At the start of every run, the damage bonus upgrade's current level (T-056's data, read through T-057) adds its percentage to the damage of the car's weapons: the gun and the flamethrower (Garage design, Decisions). It stacks with the weapons' own upgrade tiers; say how in the result notes.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test at level 0 shows weapon damage is unchanged (QA: pass / fail)
- [ ] A test at a higher level shows both weapons' damage goes up by the data's percentage (QA: pass / fail)
- [ ] `game/README.md` says how the bonus reaches the weapons, and `docs/weapons.md` mentions it in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
