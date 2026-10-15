---
id: T-060
title: Garage upgrade: acceleration applied to the car at the start of a run
status: open
from: project-lead
to: driving-drift
lead: Weapons
epic: garage
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-057, T-029]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, docs/game-loop-architecture.md, docs/drifting.md, tasks/T-057-save-and-buy.md, tasks/T-029-drift-defaults-after-playtest.md, game/README.md]
files_expected_to_change: [the car's code, tests, game/README.md]
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

**Blocked until T-057 (the saved upgrade levels) and T-029 (the car's defaults) are done.**

At the start of every run, the car's time to top speed uses the acceleration upgrade's current level (T-056's data, read through T-057), so the car reaches top speed faster (Garage design, Decisions). At level 0 the car drives exactly as now. The drift prototype keeps its own tuning and isn't affected.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test at upgrade level 0 shows the car's time to top speed is unchanged (QA: pass / fail)
- [ ] A test at a higher level shows the time to top speed is the data's value for that level, and the car reaches top speed sooner (QA: pass / fail)
- [ ] A test shows the drift prototype is not affected (QA: pass / fail)
- [ ] `game/README.md` says how upgrades reach the car (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
