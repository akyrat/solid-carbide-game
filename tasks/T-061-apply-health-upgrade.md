---
id: T-061
title: Garage upgrade: car health applied at the start of a run
status: open
from: project-lead
to: game-loop
lead:
epic: garage
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-057, T-036]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, docs/game-loop-architecture.md, tasks/T-057-save-and-buy.md, tasks/T-036-run-scene-and-state.md, game/README.md]
files_expected_to_change: [the run's code, tests, game/README.md]
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

**Blocked until T-057 (the saved upgrade levels) and T-036 (the run) are done.**

At the start of every run, the car's starting and maximum health use the car health upgrade's current level (T-056's data, read through T-057). At level 0 it is T-038's starting value.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test at level 0 shows the run starts with T-038's health (QA: pass / fail)
- [ ] A test at a higher level shows the run starts with the data's health for that level, and the HUD's maximum matches (QA: pass / fail)
- [ ] `game/README.md` mentions the health upgrade under "The run" (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
