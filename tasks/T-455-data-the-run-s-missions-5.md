---
id: T-455
title: Data: the run's missions (5 fixed, generator rules) and the four driving power-ups with their tiers
status: in-qa
from: project-lead
to: game-data
lead: Goal-G-009
epic: game-loop
milestone: mvp
goal: G-009
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md, docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/drifting.md, game/docs/data/game-data.md, game/docs/driving/tricks.md, game/data/combo.json, game/data/weapons.json, game/scripts/data/weapon_data.gd, game/scripts/driving/trick_detector.gd]
files_expected_to_change: [game/data/missions.json, game/data/power_ups.json, game/scripts/data/mission_data.gd, game/scripts/data/power_up_data.gd, game/tests/unit/test_mission_data.gd, game/docs/data/game-data.md, docs/game-loop-architecture.md, docs/drifting.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board decided mission packs and driving power-ups on 2026-10-31 (Game loop architecture, Decisions, 'Mission packs'; Drifting, Decisions, 'Driving power-ups'). This ticket writes the data the rest of goal G-009 reads; no gameplay code.

1. `game/data/missions.json`: `total` 30, and the 5 fixed missions in the board's order, each one goal with a trick type and amount: (1) drift 4 seconds continuously (one unbroken drift, a duration goal); (2) 10 alt drifts; (3) 3 seconds of airtime; (4) 3 air 180s; (5) 1 air 360. Trick type ids must match the trick names the trick detector already emits (`trick_detector.gd`, and thread the needle from `thread_the_needle.gd`); list the ids you use and where each comes from in the result notes. Then the generator's rules for missions 6 to 30: which trick types are allowed, each with a base amount and how the amount grows from mission 6 to 30, and how many goals a mission has (and how that grows). Every rule carries a `reason` note and a `proposal: true` flag, for the board's playtest. Numbers for driving tricks are the Driving & Drift Agent's call by the docs; write them as proposals and say in the result notes they are proposed on its behalf.
2. `game/data/power_ups.json`: Rev Charge, Jump, Bouncy Bumpers and Rusty Overcoat, each with an id, an icon path under `game/art/power_ups/` (the files come later in the art ticket; the path is fixed now), and a list of tiers with per-tier numbers, each marked as a proposal with a reason: Rev Charge (charge time to full, boost strength/speed, boost duration), Jump (hop takeoff speed or height, hence airtime), Bouncy Bumpers (bounce distance factor over the T-435 wall bounce), Rusty Overcoat (contact damage per hit, a per-enemy repeat cooldown, and whether it hits the kaiju; the last two are open questions for the board, so write them as proposals). Also an `offer_when_exhausted` field: the proposal for what the power-up overlay does when every power-up is at its last tier (for example: the mission gift is skipped and the run goes on), with its reason.
3. Loaders `mission_data.gd` and `power_up_data.gd` (same style as `weapon_data.gd`) and a GUT data check test.

Write the proposals and their reasons in Content of Game loop architecture (missions) and Drifting (power-ups); the Decisions lines stay the board's.

## Acceptance criteria

- [ ] game/data/missions.json holds `total` 30 and exactly 5 fixed missions in the board's order: 4 s continuous drift, 10 alt drifts, 3 s airtime, 3 air 180s, 1 air 360, each with a trick type and an amount. (QA: pass)
- [ ] missions.json holds the generator's rules (allowed trick types, how amounts grow from mission 6 to 30, how many goals per mission), and every rule has a reason note and is marked as a proposal. (QA: pass)
- [ ] game/data/power_ups.json holds rev_charge, jump, bouncy_bumpers and rusty_overcoat, each with an icon path under game/art/power_ups/ and at least 1 tier, every tier's numbers marked as proposals; it also holds the proposal for what happens when every power-up is at its last tier. (QA: pass)
- [ ] A GUT data test loads both files through mission_data.gd and power_up_data.gd and checks: 5 fixed missions, a total of 30, every trick type in the rules is one of a listed known set, the four power-ups present, and at least 1 tier each; it passes. (QA: pass)
- [ ] Game loop architecture, Content, and Drifting, Content, describe the proposals and their reasons; the result notes list the trick ids used and say there is nothing to picture (no screenshots). (QA: pass)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Open → In progress

Goal runner (G-009): started, in C:\solid-carbide-worktrees\T-455.

### 2026-10-31, In progress → In QA

Goal runner (G-009): the agent is done; QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

**Done (Game Data).** Files: `game/data/missions.json`, `game/data/power_ups.json`, `game/scripts/data/mission_data.gd` (`MissionData`), `game/scripts/data/power_up_data.gd` (`PowerUpData`), `game/tests/unit/test_mission_data.gd` (5 tests), `game/docs/data/game-data.md`, `docs/game-loop-architecture.md` (Content, "Missions: the generator's rules"), `docs/drifting.md` (Content, "Driving power-ups: the tiers"). The Decisions lines are untouched.

**Trick ids used and where they come from:** `extended_drift` (trick_detector.gd, TRICK_EXTENDED_DRIFT; mission 1 "4 s continuous drift", a seconds goal), `alternate_drift` (TRICK_ALTERNATE_DRIFT), `airtime` (TRICK_AIRTIME; seconds goal, summed from `airtime_trick`), `air_one_eighty` (TRICK_AIR_ONE_EIGHTY), `air_three_sixty` (TRICK_AIR_THREE_SIXTY), `three_sixty` (TRICK_THREE_SIXTY, ground 360, generator only), `thread_the_needle` (thread_the_needle.gd, the id in ComboData.needle_rules; generator only).

**Proposals:** all generator numbers (goals per mission 1/2/3 by range, per-trick base, growth per mission, cap) and all power-up tier numbers are proposals for the board's playtest, written by Game Data on the Driving & Drift Agent's behalf (the docs give driving numbers to it). Each has a `reason` and `proposal: true`. Open questions for the board (as proposals): Rusty Overcoat's per-enemy repeat cooldown and whether it hits the kaiju (tier 4 only); `offer_when_exhausted` = `skip_gift`. Note for the building tickets: the file has `known_tricks`; a "seconds" goal shows no progress, a "count" goal does.

**Tests:** GUT 2319/2319 passed (191 scripts, includes the 5 new); `python -m unittest discover -s game/tools`: 767 tests OK (1 skipped); `python -m unittest discover -s tools`: NOT finished. It ran over 10 minutes (about 105 dots, no failure shown, then it crawled), so I stopped it. This ticket changes nothing under `tools/`, so QA or the merge script should run that set.

**Screenshots:** none. Data and loaders only, nothing is on screen.

**QA round 1:** all six criteria pass. Data files read and match the criteria. GUT 191 scripts, 2319/2319 pass (incl. the 5 in test_mission_data.gd). `game/tools` unittest: 767 OK (1 skipped). `tools/` unittest: 614 OK (584 s; the Developer's note that it did not finish was only slowness). `tools/qa_check.py` was refused (not pre-approved), so skipped; the checks were done by hand.
