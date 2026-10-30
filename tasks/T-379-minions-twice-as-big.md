---
id: T-379
title: Minions twice as big, hitbox included
status: in-progress
from: project-lead
to: enemy-behavior
lead: Greenbull
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/enemies.md, game/docs/enemies/]
files_to_read_first: [tasks/README.md, docs/enemies.md, game/data/enemies.json, game/scripts/enemies/minion.gd]
files_expected_to_change: [game/data/enemies.json, game/scripts/enemies/, game/scenes/, game/tests/unit/, game/docs/enemies/, docs/enemies.md, art-archive/]
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

The board's decision (Enemies, Decisions, "Minions twice as big", 2026-10-29; an MVP nice-to-have, **start only after the last MVP round**). Draw the minions twice as big as today and grow the size they hit and get hit with to match (their contact with the car, weapon hits, the pickup and coin drop spots if they depend on it, and their navigation radius so they still fit through gaps). Hard pixel edges (a whole-number scale). Numbers in `game/data/enemies.json`. The kaiju stays as it is. Check the minions still path to the car on the elevation map (rooftops and ramps) and don't get stuck more than before.

The board's review: play a run and see the bigger minions.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Minions are drawn at twice today's size with hard pixel edges, from a number in game/data/enemies.json (test and screenshot). (QA: pass / fail)
- [ ] Their collision with the car and the weapons' hits grow to match the new size (tests). (QA: pass / fail)
- [ ] Minions still reach the car on the elevation map, rooftops and ramps included (test). (QA: pass / fail)
- [ ] Enemies, Content and the game docs give the new size. (QA: pass / fail)
- [ ] A screenshot of a run with the bigger minions next to the car is in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started in build F.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Done by the Enemy Behavior Agent, 2026-10-30.

- Number: `minion.size_scale` 2 in `game/data/enemies.json` (read by `EnemyData.minion()`; whole number, so the art is drawn at 1 screen pixel per art pixel, hard edges). The kaiju is untouched.
- Drawing: `minion_sprite.gd` has `size_scale` (set by the spawner); art size and lift scale with it (placeholder shape too).
- Hits: `minion.gd` has `size_scale`, `radius_units()` (0.5 x scale = 1.0: collision circle, `touches_car` reach, spawner free-spot clearance, depth order, separation distance) and `hit_radius_units()`, which the weapons' target-radius checks (bullets, molotov, underglow, burn flames) already ask for.
- Navigation: `enemy_navigation.gd` `building_margin` (0.5 x scale) round buildings and boulders, so paths keep the bigger body off them.
- Finding worth knowing: with the full radius off rooftop/ramp edges, a minion jammed at a rooftop's corner (the navigation's 2-unit cells put path corners exactly 1 unit from an edge). So the body keeps the old 0.5 off ground edges (`BASE_RADIUS_UNITS` in `_move()`); the edges are not physics walls. Checked over 6 random seeds of the 4-minion climb to the nw height-6 car: all reach it (before the fix 3 of 6 seeds jammed).
- Tests added: size from data and whole number, collision circle, `touches_car` reach (1.5), weapon radius, navigation margin (`test_minions.gd`), art scale (`test_minion_sprite.gd`). Updated for the new size: `test_enemy_data.gd` (size_scale key is not time growth), `test_starting_gun.gd` (hit radius 2.0), tests that used the old `RADIUS_UNITS`/`HEIGHT_UNITS` constants, and one start point inside a building in `test_enemies_on_heights.gd`. The elevation tests (both rooftop climbs, descents, drops) pass with the bigger minions.
- Test counts: GUT 158 scripts, 1951 tests, 1951 passing (one earlier full run had a flaky `test_run_scene_drift_pays_its_combo_once_when_it_ends` fail, unrelated; it passed on the final run); `python -m unittest discover -s game/tools` 678 tests OK (1 skipped); `python -m unittest discover -s tools` 579 tests OK.
- Screenshot: `art-archive/T-379/screenshots/minions_twice_as_big.png` (the minions demo: bigger minions around the car).
- Documents updated: `docs/enemies.md` (Decisions note, Look line), `game/docs/enemies/minions.md` (Size section, minion.gd line).
- Not done / for the playtest: crowd density looks heavier with the same count (12 to 20); the board judges the feel.
