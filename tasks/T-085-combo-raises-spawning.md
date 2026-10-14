---
id: T-085
title: The combo raises minion spawning (can be switched off)
status: open
from: project-lead
to: enemy-behavior
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-044, T-081, T-080]
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, tasks/T-044-minions.md, tasks/T-081-combo.md, tasks/T-080-combo-data.md, game/README.md]
files_expected_to_change: [the enemy code, tests, docs/enemies.md, game/README.md]
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

**Blocked until T-044 (minion spawning), T-081 (the combo) and T-080 (the numbers) are done.**

Enemies, Decisions: the higher the combo, the more minions spawn, on top of the slow growth over the run. Use T-081's current multiplier and T-080's numbers. Add an on/off switch (a setting the board can flip for playtests, documented in `game/README.md`), because the board will judge whether to keep it.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test with a high combo shows more minions spawn than with no combo, by the data's amount (QA: pass / fail)
- [ ] A test with the switch off shows the combo makes no difference to spawning (QA: pass / fail)
- [ ] `game/README.md` says how to switch it, and `docs/enemies.md` describes it in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
