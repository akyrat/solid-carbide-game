---
id: T-415
title: Pickups at full hearts, the combo's hit window, and the run's base values
status: in-progress
from: project-lead
to: game-loop
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: [T-413]
documents_affected: [docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/scripts/run/run_state.gd, game/scripts/enemies/health_pickup.gd, game/scripts/run/pickup_magnet.gd, game/data/run.json, game/data/garage.json]
files_expected_to_change: [game/scripts/run/run_state.gd, game/scripts/enemies/health_pickup.gd, game/scripts/run/pickup_magnet.gd]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Game loop architecture, Decisions: "A health pickup at full hearts stays" and "Hits close together cut the combo once". Today a health pickup at full hearts is used up for nothing and the magnet pulls it; a corner or two boulders give several 50% cuts in a row (run_state.gd collision() has no window). Also a code hole: start_run replaces run.json's starting hearts and magnet radius with garage.json's absolute values instead of the run.json base plus the garage upgrade, as Game loop architecture ("The run scene") says; today the numbers match, so nothing shows. Make the garage add to run.json's base, and keep the same value in one file only.

The board's review: drive over a health pickup at full hearts and see it stay; scrape a corner and see the viewers cut once.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] At full hearts a health pickup is not collected and not pulled by the magnet; below full it is. (QA: pass / fail)
- [ ] Two collisions 0.3 s apart cut the combo once; two 0.7 s apart cut it twice. (QA: pass / fail)
- [ ] Changing run.json's starting hearts changes max health in a run with a saved garage (test with a progress object); the garage's car health level adds to it. (QA: pass / fail)
- [ ] The magnet radius follows the same rule (run.json base plus the garage level). (QA: pass / fail)
- [ ] The starting hearts and the base magnet radius are each stored in one data file only. (QA: pass / fail)
- [ ] New headless tests cover each criterion below that describes behaviour, and all three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

T-413 approved; the game-loop agent starts.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done (game-loop agent). Tests: unittest game/tools 722 (OK, 1 skipped), unittest tools 582 OK, GUT 174 scripts / 2150 tests all passing (an earlier run's test_wreck failure was a load flake; it passes alone and in the full rerun). New: `game/tests/unit/run/test_pickups_combo_base.gd` (11 tests, 49 asserts).

- Full hearts: `health_pickup.gd` gets `wants_health()` (below full, or wrecked: a pickup revives); `can_be_picked_up_by()` includes it. `pickup_magnet.gd` skips a pickup that doesn't want health. It waits where it lies and is taken once the car is hurt. Pickup files changed: `game/scripts/enemies/health_pickup.gd`, `game/scripts/run/pickup_magnet.gd`; `minion_spawner.gd` untouched.
- Combo window: `combo.json` `collision_window_seconds` 0.5, `ComboData.collision_window_seconds()`, `RunState._cut_combo()` (covers collision() and the damage path), on the run's clock, cleared by start_run(). Proposals for the playtest: the window starts only when a collision really cut the combo (a no-op collision starts none), a collision inside it does not restart it, and the crash still pays its trick (`crashed` fires).
- Base values: `garage.json` `car_health` and `pickup_magnet` lose `base_value` and the absolute `value`; each level stores a `bonus` (+1 heart, +0.6 units per level, same totals as before), with `base_from` naming run.json. `GarageData.value()` = run.json base (`RunData`, injectable as 2nd arg) + bonus; `bonus()` and `RUN_BASES` added. `RunState.start_run()` = run.json base + `progress.garage.bonus(...)`. The garage screen shows the same numbers.
- Existing tests adapted to the new rules (second collision, or health pickup at full hearts): test_crash_pays_trick, test_pickup_heights, test_run_combo.
- Screenshot: art-archive/T-415/screenshots/full_hearts_pickup_stays.png (two pickups beside the car at 5 of 5 hearts, not pulled); fixture tests/fixtures/full_hearts_pickup_demo.tscn.
- Documents updated: docs/game-loop-architecture.md (the two Decisions plus a new "The garage adds to run.json's base"), game/docs/data/game-data.md. The long GDD is regenerated at merge.
- All six criteria are covered by the tests.
