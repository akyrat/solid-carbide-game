---
id: T-418
title: Meteors hit minions and push pickups aside
status: needs-playtest
from: project-lead
to: enemy-behavior
lead: Audit
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/enemies.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, game/scripts/enemies/kaiju_meteors.gd, game/scripts/enemies/enemy_data.gd, game/scripts/enemies/minion_spawner.gd]
files_expected_to_change: [game/scripts/enemies/kaiju_meteors.gd, game/scripts/enemies/enemy_data.gd, game/scripts/enemies/minion_spawner.gd]
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

Enemies, Decisions: "Meteors hit minions and push pickups aside". Today a boulder appears around any minion, coin or health pickup on its spot (kaiju_meteors.gd _blocked_by_body checks only the car and the kaiju), meteors never damage minions, and a meteor hits a car jumping over it (only the flat distance is checked). Also two data guards: enemy_data.gd meteor_attack_times() loops forever if seconds_between_attacks is 0 or less; minion_spawner.gd reads spawn_interval_seconds without a default. Refuse or clamp bad values with a clear error.

The board's review: during the kaiju fight, see meteors kill minions and push coins out from under the boulders.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A meteor landing on a minion damages it (minion health drops). (QA: pass)
- [ ] A coin or health pickup on a boulder's spot ends up outside the boulder, still collectable. (QA: pass)
- [ ] A car more than 1 unit above a landing meteor takes no damage; at the same level it does. (QA: pass)
- [ ] seconds_between_attacks of 0 doesn't hang (the test finishes) and reports an error; a missing spawn_interval_seconds uses the default. (QA: pass)
- [ ] New headless tests cover each criterion below that describes behaviour, and all three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Build J (Audit): started on playtest/audit-world, worktree C:\solid-carbide-worktrees\T-418, Enemy Behavior Agent.

### 2026-10-30, In progress → In QA

Build J (Audit): the agent finished (meteors damage minions, minion_damage 2 is its proposal; pickups pushed out of boulders; data guards). Pickup code only in minion_spawner.gd. In QA now.

### 2026-10-30, In QA → Needs playtest

Build J (Audit): QA passed all 5 criteria and the tests; screenshots in art-archive/T-418/screenshots/. Merged into playtest/audit-world, waiting for the board's playtest of build J.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Enemy Behavior Agent, 2026-10-30.

What changed
- A meteor landing damages every minion at the landing's level within impact_radius_units (+ the minion's radius): new `minion_damage` in enemies.json `meteor_attack` = 2 health points (a proposed number; minion health is 4). kaiju_meteors.gd `land()` calls the spawner.
- When a meteor's boulder is placed, coins and health pickups within the boulder's radius (+0.5) are moved just outside it (0.1 clear, along the way out from the centre, first of 16 directions that is free ground), sprite, height and z follow; still in the coins/health_pickups lists and groups, so still collectable.
- A car more than 1 unit (EnemyHeight.LEVEL_TOLERANCE, the contact-damage rule) above the landing is missed.
- Guards: EnemyData.meteor_attack_times() with seconds_between_attacks <= 0 pushes an error and counts only the first attack; the attack clock in kaiju_meteors.gd step() adds at least MIN_ATTACK_GAP (0.1 s); minion_spawner.spawn_interval() uses DEFAULT_SPAWN_INTERVAL 0.5 when spawn_interval_seconds is missing, and replaces a value <= 0 with it and an error.

Files: game/scripts/enemies/kaiju_meteors.gd, game/scripts/enemies/minion_spawner.gd, game/scripts/data/enemy_data.gd (the ticket listed enemy_data.gd under enemies/; it is in data/), game/data/enemies.json, docs/enemies.md (detail lines in "The kaiju's meteor attack"; the decision unchanged), game/tests/unit/test_enemy_data.gd (key list), new game/tests/unit/enemies/test_meteors_minions_pickups.gd (11 tests, one per behaviour criterion).

Pickup files and functions changed: none of coin.gd, health_pickup.gd, or their sprites. All pickup changes are in minion_spawner.gd: new push_pickups_out(), _pickup_spot_free(), _move_pickup() (they read spawn_coin_at / spawn_health_pickup_at's conventions but do not edit those functions). Nothing in game/data/levels/.

Tests: GUT 2136 tests, first full run 2134 passing, 2 failing: test_enemy_data.gd key list (mine, fixed, rerun alone: 10/10) and test_run_likes.gd drift timing (known under load; rerun alone: 37/37 pass). New file 11/11. Python game/tools: 722 tests OK (1 skipped). Python tools: 582 tests OK. No full GUT rerun after the test_enemy_data fix (only that file).

QA round 1 (QA/Integration Agent, 2026-10-30)
- qa_check --no-marks: PASS tests (3 sets); PASS documents (docs/enemies.md changed); FAIL screenshots (no image or recording in art-archive/T-418/screenshots/; none listed in the result notes either).
- Criteria 1-5 pass: new test file has 11 tests covering minion damage, pickups pushed out and still collectable, car 1 unit up hit and high car missed, zero gap no hang plus error, missing spawn interval default. QA did not re-run test counts separately; qa_check ran the three sets and passed.
- Missing: screenshots of the meteor hitting minions and coins pushed out (ticket has a The board's review line). Paperwork only.

Screenshots (Enemy Behavior Agent, after QA round 1; fixtures game/tests/fixtures/t418_meteor_demo*.gd/.tscn, no game code changed):
- art-archive/T-418/screenshots/before_warning_on_minions_and_pickups.png: the warning circle on three minions, a coin and a health pickup.
- art-archive/T-418/screenshots/after_minions_hurt_pickups_pushed_out.png: about a second after the landing: the boulder stands, the minions have 2 of 4 health (printed by the fixture), the health pickup and the coin lie 2.1 units from its centre, outside the 1.5 radius. The minions are partly behind the tall boulder art.

Board review files: art-archive/T-418/screenshots/before_warning_on_minions_and_pickups.png, art-archive/T-418/screenshots/after_minions_hurt_pickups_pushed_out.png
