---
id: T-402
title: Bug: a gift pack that falls on a platform is drawn below the platform
status: in-progress
from: project-lead
to: game-loop
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/level-design.md, docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/game-loop-architecture.md, tasks/T-393-creator-objects-ignore-heights.md, game/scripts/run/, game/scripts/level/]
files_expected_to_change: [game/scripts/run/, game/scripts/level/, game/tests/unit/, docs/level-design.md, docs/game-loop-architecture.md, art-archive/]
model: opus
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

The board's decision (Level design, Decisions, "A gift pack that falls on a platform shows on it", 2026-10-30; a bug the board wants fixed at once): "fix a bug where the gift, when it falls on a platform, it shows below the platform." Today's rule (Level design, Content, "Elevation sample map") says gift packs pick only street-level spots, so either the drop spot picker misses platforms (for example on levels made in the creator) or the pack's depth or height ignores the platform. Find the root cause and fix it. Write in the result notes, as a proposal for the board's playtest, which way it goes: the pack keeps to street spots (the rule as written), or it can land on a platform, drawn at the platform's height and picked up there. Either way it is never drawn below a platform.

T-393 (in review, its own worktree `C:\solid-carbide-worktrees\T-393`) fixed the depth rule for placed objects on maps with rooftops; read its result notes and reuse its rule where it fits rather than writing a second one, and keep your changes to the gift pack's code so the merges stay clean. The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked): copy one into your worktree to reproduce (uncommitted), never write or commit them.

Widened by the board, 2026-10-30 (through the Project Lead): "when I go to pick up the gift on a platform, its hitbox is in the wrong place." Beyond the drawing, every pickup (gift packs, health pickups, coins and any other) must be drawn and picked up at the height it is at: on a platform the car picks it up there, and not from the street below. Keep to the pickups' code (T-405, another agent, turns low-rise, small and long buildings into platforms at height 3).

The board's review: play a level with platforms until a gift pack drops near one, and see where it lands and how it is drawn.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The root cause is written in the result notes, with a test that fails before the fix (named). (QA: pass / fail)
- [ ] A gift pack is never drawn below a platform: it lands on a street spot or on the platform as the result notes propose, drawn at the height of what it lands on (tests). (QA: pass / fail)
- [ ] If it can land on a platform, the car picks it up there (test). (QA: pass / fail)
- [ ] Widened by the board, 2026-10-30: every pickup (gift package, coin, health pickup) is drawn and picked up at the height it is at; on a platform the car picks it up there and not from the street below (tests). (QA: pass / fail)
- [ ] Level design (Content) and Game loop architecture describe the behaviour. (QA: pass / fail)
- [ ] Screenshots of a gift pack by a platform before and after are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started: root cause and fix for the gift pack drawn below a platform.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Game Loop Agent, 2026-10-30.

**Root cause.** The landing-spot picker (`gift_drops.gd` `landing_spot`) did keep to the street (`map.is_open_spot` refuses rooftops and ramps), but when no street spot was open within its search (up to 1.5 x `land_ahead_units` = 12 units plus 1 unit clearance) it fell back to the car's own spot. With the car well inside a large rooftop (Kaiju City's 32 x 32 rooftops, the default map's roof-nw-6), that spot is on the rooftop. The package had no height: `drawn_ground` was the street's projection of the spot, so it was drawn 16 px per unit of height (48 px on a 3, 96 px on a 6) below the rooftop's top, and the pickup was a flat-distance check with no height either. So the pack was drawn in the wrong place, its hitbox stayed where it really was (the board's "hitbox in the wrong place"), and it was picked up at once when it landed on the car's own spot. Coins and health pickups were already drawn at their height (T-207), but their Area2D collected them whatever the car's height, so a car on the street touching a rooftop's wall picked up what lay on its edge, and the magnet pulled them up or down walls and left their sprite at the old height.

**Failing tests before the fix.** These were checked by stashing the fix and running them:
- `tests/unit/run/test_gift_drops_heights.gd` `test_a_package_that_lands_on_a_rooftop_is_drawn_at_the_rooftops_height` fails: drawn y -864, expected -960.
- `tests/unit/run/test_pickup_heights.gd` `test_a_car_on_the_street_by_the_wall_does_not_collect_a_coin_on_the_rooftop` fails: the coin was collected from below.
- 7 of the 10 widened tests fail before the fix.

**Proposal for the playtest (which way it goes).** Street spots stay the rule. Only when no street spot is open within the search does the pack land on the rooftop the car is on, and then only on open, flat ground of that rooftop: the same search directions, the clearance square all at that height, no ramp, no edge, no higher rooftop on it, no building, boulder or prop. It is drawn at the rooftop's height and picked up there. The car's own spot remains the last fallback, also drawn at its height. Either way the pack is drawn in the depth order the car has at that spot and height (`elevation_layer.gd` `z_for`, the car's dynamic-object rule). T-393's rule is for placed static objects (boulders, props) and is not used here. On maps without rooftops nothing changes (`map.car_z_index`).

**Widened by the board (every pickup at its height).** There is one rule, in the new `game/scripts/run/pickup_height.gd`: the car picks a pickup up only when its height is at least the pickup's less 0.5 units. So a car on the street does not pick up from a rooftop, and a car jumping over a street pickup still does. It is used by:
- the gift package (`GiftDrops.check_pickups`);
- coins (`coin.gd` `can_be_picked_up_by`);
- health pickups (`health_pickup.gd`).

`minion_spawner.gd` sets each coin's and health pickup's `ground_height` (two lines). Pickup magnet (proposal): it pulls only pickups on the level the car is on (the ground under the car, within 0.5), so nothing is pulled up or down a wall. A pulled pickup follows the ground's height and depth (`_follow_ground`, `GiftDrops.move_package`).

**Changed:**
- `game/scripts/run/gift_drops.gd`, `gift_package.gd` (`ground_height`, `set_ground`), `pickup_magnet.gd`, new `pickup_height.gd`.
- `game/scripts/enemies/coin.gd`, `health_pickup.gd`, `minion_spawner.gd`.
- `game/scripts/level/mvp_map.gd`: `is_open_spot` gained an optional `street_only := true`, a 3-line change in a function T-393 does not touch.
- Tests: `tests/unit/run/test_gift_drops_heights.gd` (9 tests: the rooftop case, rooftop spots, street first near an edge, a sweep of 1,200+ car positions over the map, pickup on the rooftop, no pickup from below, jumping over still picks up, the magnet moves it with the ground) and `tests/unit/run/test_pickup_heights.gd` (10 tests: the rule, the gift picked up where it is drawn, coins and health pickups at their height and not from below, a real physics test at the wall, the magnet's level rule and height following).

**Screenshots** in `art-archive/T-402/screenshots/`. Each shows the car parked in the middle of a rooftop when the pack drops, then backed off 5 units.
- `before.png` and `after.png`: the board's Kaiju City level, roof-1, height 3. These used the untracked copy `game/data/levels/kaiju_city.json`, which was not committed.
- `before_default_map.png` and `after_default_map.png`: the run's default map, roof-nw-6, height 6.
- Before: the pack lies at the car's old spot but is drawn 48 or 96 px lower, off its real place. After: it is 8 units ahead on the rooftop, drawn on its top.

Fixtures: `game/tests/fixtures/gift_pack_rooftop_demo.tscn` and `_default.tscn`.

**Test counts:**
- `python -m unittest discover -s game/tools -p "test_*.py"`: 668 OK (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: 576 OK.
- `bash game/tools/run_tests.sh`: 1958 of 1958 passing.

**Documents affected:**
- `docs/level-design.md`: Content, "Elevation sample map", the run's proposals bullet.
- `docs/game-loop-architecture.md`: Decisions, "Pickup magnet"; Content, "The gift pack drop", two bullets.
- `game/docs/game-loop/gift-pack-and-pickups.md`: where it lands and the magnet.

Note: the worktree has no `.env`. The tests ran with `GODOT_BIN` set on the command line from the main checkout's value.

Board review files: art-archive/T-402/screenshots/before.png, art-archive/T-402/screenshots/after.png, art-archive/T-402/screenshots/before_default_map.png, art-archive/T-402/screenshots/after_default_map.png
