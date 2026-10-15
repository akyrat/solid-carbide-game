---
id: T-060
title: Garage upgrade: acceleration applied to the car at the start of a run
status: done
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
qa_rounds: 1
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

- [ ] A test at upgrade level 0 shows the car's time to top speed is unchanged (QA: pass)
- [ ] A test at a higher level shows the time to top speed is the data's value for that level, and the car reaches top speed sooner (QA: pass)
- [ ] A test shows the drift prototype is not affected (QA: pass)
- [ ] `game/README.md` says how upgrades reach the car (QA: pass)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass)

## Result notes

Done. `CarTuning.apply_acceleration_upgrade(progress)` sets `time_to_top_speed = progress.current_value("acceleration")`; `GameFlow.start_run()` calls it with one line right after the run is built (the drift prototype never calls it). Tests: `game/tests/unit/game/test_acceleration_upgrade.gd` (level 0 = 2.3 s unchanged; levels 1, 5, 10 use the data's value and the measured climb to top speed is shorter and scales with it; the prototype keeps 2.3 s even with level 10 saved). Full GUT suite passes, game/tools Python tests (257) and tools Python tests (180) pass. Docs updated: game/README.md, docs/drifting.md. Note: W snaps to cruise first, so the real time from standstill to top is a share of the "time to top speed" value, not the value itself.
- 2026-10-15, in-qa → done: QA pass: all 5. Fresh CarTuning per car, only GameFlow.start_run applies it; prototype test passes. GUT 683/683, Python 257+180 OK.
