---
id: T-220
title: Enemies drop health pickups that restore 30% of the car's health
status: in-progress
from: project-lead
to: enemy-behavior
lead: Coursework
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/visual-style.md, docs/game-loop-architecture.md, game/README.md, game/data/enemies.json]
files_expected_to_change: [game/scripts/enemies/, game/scripts/run/, game/data/enemies.json, game/tests/unit/, game/README.md, docs/enemies.md, art-archive/T-220/screenshots/]
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

The board's decision (Enemies, Decisions, "Health drops", 2026-10-21): enemies also drop health pickups, at the same drop rate as the coins (`game/data/enemies.json`, today 60% for a minion). Driving over one restores 30% of the car's maximum health, never above the maximum. Build it like the coins: dropped where the enemy died, at its height on the elevation map (T-207), drawn in the depth order, standing still while paused, gone on a new run.

Use a **placeholder** look for now, drawn in code: a small red canister with a white cross, in a canister red that is not Redgull's red (Visual style, Decisions, "Health drop"; placeholders never use Redgull red). T-221 swaps in the final art afterwards. The drop chance and the 30% are tuning numbers in `game/data/enemies.json`, not in code. Proposals for the playtest, in the result notes: whether the health roll is separate from the coin roll (so one kill can drop both), whether the kaiju drops any, and whether a full-health car still picks one up.

Another ticket (T-222) adds a magnet that pulls pickups to the car; keep the health pickup easy for it to find, the same way the coins are found.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the work (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] Tests show a dying enemy drops a health pickup at the data's drop chance, where it died and at its height, and that driving over it restores 30% of the maximum health, capped at the maximum (QA: pass / fail)
- [ ] The drop chance and the 30% are read from `game/data/enemies.json` (test) (QA: pass / fail)
- [ ] The placeholder is a red canister with a white cross, not Redgull's red, drawn in the depth order like the coins (screenshot in a run) (QA: pass / fail)
- [ ] Health pickups stand still while paused and are gone on a new run (tests); coins behave as before (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: play a run, pick up health drops after taking damage.
Board review files: the screenshots in `art-archive/T-220/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Started at the board's request.

## Result notes

Written by the agent when it finishes.

Built (enemy-behavior agent): a dying minion drops a health pickup where it died, at its ground height and in the coins' depth order. `game/scripts/enemies/health_pickup.gd` (Area2D, pickups layer, mask 2, group `health_pickups`, `spawner.health_pickups`), placeholder drawing `health_pickup_sprite.gd` (orange-red canister, white cross; not Redgull red). `RunState.heal_car()` restores `restore_fraction * max_health`, capped. Numbers in `game/data/enemies.json` `health_drops` (`drop_chance` 0.6, `restore_fraction` 0.3), read via `EnemyData.health_drops()`. Tests: `game/tests/unit/enemies/test_health_drops.gd`. GUT 1222/1222 pass; Python tests (tools 439, game/tools 387) pass. Screenshot: `art-archive/T-220/screenshots/health_pickups_run.png` (fixture `minions_demo.tscn` now also places two canisters).

Proposals for the playtest:
- The health roll is separate from the coin roll, so one kill can drop both (same 60% rate, own number in the data).
- The kaiju drops no health pickups (its death ends the run anyway).
- A full-health car still picks one up and uses it up (simplest; the magnet T-222 will not leave unusable ones lying around).
- Pickup is not damage: it does not touch the combo.

Refused commands: none.
