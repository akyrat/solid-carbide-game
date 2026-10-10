---
id: T-080
title: Combo numbers: what each trick adds, the drain, and how the combo raises spawning
status: in-progress
from: project-lead
to: game-data
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-038]
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/drifting.md, docs/hud-and-menus.md, docs/enemies.md, tasks/T-038-run-and-likes-data.md, game/README.md]
files_expected_to_change: [JSON data under game/data/, tests, docs/game-loop-architecture.md, game/README.md]
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

**Blocked until T-038 (the data convention and the likes numbers) is done.**

Work out the combo's numbers within Game loop architecture and Enemies, Decisions, as JSON under `game/data/`:
- The starting multiplier (no combo), and how much each trick adds: extended drift a little, a 360 more, an alternate drift the most. Decide whether the multiplier has a maximum.
- The cut on a collision is 80% (decided). How "cut by 80%" applies to the multiplier (for example to the part above the starting value): say which.
- The drain: after 2 seconds with no trick (decided), how fast the combo falls back.
- How strongly the combo raises minion spawning (Enemies, Decisions).

Explain the numbers in the result notes, with an example: a minute of good driving and what multiplier it reaches. The board judges them in playtests.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The data is valid JSON under `game/data/`, and a test loads it through T-038's loader (QA: pass / fail)
- [ ] A test shows an alternate drift adds more than a 360, and a 360 more than an extended drift (QA: pass / fail)
- [ ] The data holds the 80% cut and the 2-second wait as given, and the result notes explain every other number with the example (QA: pass / fail)
- [ ] `docs/game-loop-architecture.md` points to the data in References, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
