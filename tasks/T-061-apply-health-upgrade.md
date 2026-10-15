---
id: T-061
title: Garage upgrade: car health applied at the start of a run
status: in-qa
from: project-lead
to: game-loop
lead: Weapons
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

The car health upgrade now sets the run's starting and maximum health. `RunState.progress` (new, null = run.json's base) is read in `start_run()` as `progress.current_value("car_health")`; `run.gd` has `progress` and passes it to the state; `GameFlow.start_run()` sets `run.progress = progress` before adding the run. Small and local: 3 scripts, a few lines each. Tests: `tests/unit/run/test_run_health_upgrade.gd` (level 0, no progress, every level against the data, a run through GameFlow at level 3 with the HUD bar maximum matching, a new run after buying). `game/README.md` mentions it under The run. Full GUT suite: 685 passing; Python tool tests: 257 OK.
