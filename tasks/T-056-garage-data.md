---
id: T-056
title: Garage numbers: 3 upgrades, about 10 levels each, prices and effects
status: in-progress
from: project-lead
to: game-data
epic: garage
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-038]
documents_affected: [docs/garage-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, docs/game-loop-architecture.md, docs/drifting.md, docs/weapons.md, tasks/T-038-run-and-likes-data.md, game/README.md]
files_expected_to_change: [JSON data under game/data/, tests, docs/garage-design.md, game/README.md]
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

**Blocked until T-038 (the data convention and the car's starting health) is done.**

The MVP garage sells three permanent upgrades, each with about 10 levels (Garage design, Decisions). Work out each level's price in coins and how much it improves:
- **Acceleration:** reaching top speed faster. It changes the car's time to top speed (Drifting; the setting is in the car's tuning from T-012 and T-029).
- **Car health:** raises the car's starting health from T-038's value.
- **Damage bonus:** a percentage added to the car's weapons' damage.

Prices should fit how many coins a run gives. If T-039's coin numbers aren't done, say what you assumed. Explain the numbers in the result notes, with a table. The board judges them in playtests.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The data is valid JSON under `game/data/`, and a test loads it through T-038's loader (QA: pass / fail)
- [ ] A test shows each upgrade has a price and effect for every level, prices never go down, and effects only improve (QA: pass / fail)
- [ ] The result notes have the table and the reasoning, and `docs/garage-design.md` points to the data in References, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
