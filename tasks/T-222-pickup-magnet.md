---
id: T-222
title: Pickups are pulled to the car within one car length
status: done
from: project-lead
to: game-loop
lead: Coursework
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/enemies.md, docs/garage-design.md, game/README.md, tasks/T-220-health-drops.md]
files_expected_to_change: [game/scripts/run/, game/scripts/enemies/, game/data/run.json, game/tests/unit/, game/README.md, art-archive/T-222/screenshots/]
model: sonnet
qa_rounds: 1
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

The board's decision (Game loop architecture, Decisions, "Pickup magnet", 2026-10-21): coins, the level-up gift packs and health drops are pulled towards the car once they are within **1 car length** of it, so they are easier to pick up. The radius becomes a garage upgrade later (T-224), so read it from one place the upgrade can set: a value in the run's data (for example `game/data/run.json`), in units, starting at the car's length (Drifting, Decisions, for the car's size).

The health drops come from T-220, which is being built at the same time: branch from `task/T-220-health-drops` (merge it in again before handing over if it has moved), so the magnet covers all three; this ticket merges only after T-220. How fast pickups fly and whether they follow the car's height on the elevation map are proposals for the playtest, in the result notes. Picking up still happens as today, when the car touches the pickup.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots and a short GIF of pickups being pulled in (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] Tests show a coin, a gift pack and a health drop within the radius move towards the car and are picked up, and ones outside it stay where they are (QA: pass; test_pickup_magnet.gd covers all three in and out of reach)
- [ ] The radius is read from one data value, in units, set to the car's length, which a test can change (QA: pass; run.json pickup_magnet.radius_units = 3.0, a test changes it)
- [ ] A GIF from a run shows pickups being pulled to the car (QA: pass; GIF exists, screenshots show coins converging, counter 4 to 6)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass; GUT 1232/1232, tools 439 OK, game/tools no tests and exit 0)

The board's review: play a run and pick things up with the magnet.
Board review files: the GIF in `art-archive/T-222/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Started at the board's request.

### 2026-10-21, In progress → In QA

Built: coins, gift packs and health drops fly to the car within 3 units (1 car length). Sent to QA.

### 2026-10-21, In QA → Needs playtest

QA passed all 4 (the Project Lead re-ran game/tools: 387 OK). Ready for the board: C:\solid-carbide-worktrees\T-222\game\project.godot, with the health drops too.

### 2026-10-21, Needs playtest → Done

The board approved the magnet. Merged into master.

## Result notes

Written by the agent when it finishes.

Built and merged with T-220 (893277b), so the magnet covers coins, landed gift packs and health drops.

- `game/scripts/run/pickup_magnet.gd` (child "PickupMagnet" of the run): each physics step, pickups in groups `coins` and `health_pickups` and landed gift packages within the reach fly straight at the car; a pulled coin or drop is collected within 0.5 units of the car's centre (same as touching). Sprites move with their pickup.
- One value: `game/data/run.json` `pickup_magnet.radius_units` = 3.0 (1 car length: the car is drawn 3 units long), read by `RunData` into `RunState.pickup_magnet_radius_units` at every `start_run()`; T-224 sets it there. Tests change it.
- Tests: `game/tests/unit/run/test_pickup_magnet.gd` (10 tests: coin, gift pack, health drop in/out of reach, one value changes reach, falling pack not pulled, paused). GUT 1232 pass; `tools` and `game/tools` Python tests pass.
- GIF and screenshots: `art-archive/T-222/screenshots/pickup_magnet.gif`, `magnet_40.png`, `magnet_60.png`, `magnet_80.png` (coins counter rises as coins beside the path fly in). Fixture: `game/tests/fixtures/pickup_magnet_gif_demo.tscn`. The GIF shows coins only (health drops and packs are covered by tests).
- Proposals for the playtest: pull speed 30 units/s (above the car's top speed 27.5), constant speed; the reach ignores heights (a pickup on a rooftop is pulled by a car on the street below within 3 units on the flat map); only landed gift packs are pulled, not falling ones; a package is still picked up by its own 2.0-unit radius.
- Documents updated: docs/game-loop-architecture.md, game/README.md. Nothing refused.
- 2026-10-21, needs-playtest → done: Board: the pickup magnet works well
