---
id: T-407
title: A falling gift pack casts a shadow where it will land, like the car's shadow in the air
status: done
from: project-lead
to: game-loop
lead: Greenbull
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/game-loop-architecture.md, game/docs/game-loop/]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, tasks/T-402-gift-pack-below-platform.md, game/scripts/run/, game/docs/game-loop/]
files_expected_to_change: [game/scripts/run/, game/tests/unit/, game/docs/game-loop/, docs/game-loop-architecture.md, art-archive/]
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

The board's decision (Game loop architecture, Decisions, "A falling gift pack shows its shadow", 2026-10-30): "add a shadow under the gift pack while it's falling. The shadow is the same as the car has when it's in the air. It shows where it's going to land." From the moment the helicopter drops the package until it lands, a shadow sits at the landing spot, at the height of what it lands on (the ground or a platform), drawn with the car's air shadow (reuse its code or texture, no new art). Whether it grows or darkens as the package gets closer, like the car's, follows the car's shadow. It disappears when the package lands (the landed package keeps whatever it has today).

This builds on T-402 (gift packs drawn and picked up at their height): its worktree is branched from T-402's branch once T-402 passes QA, so the board plays both together, and it merges after T-402. Keep to the falling shadow.

The board's review: level up, watch the helicopter drop the gift pack on the ground and on a platform, and see the shadow mark where it lands.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] While a gift pack falls, a shadow shows at its landing spot, made with the car's air shadow (tests). (QA: pass - test 1 uses car_shadow.gd at the landing spot)
- [ ] On a platform the shadow sits at the platform's height, on the ground at the ground's (tests). (QA: pass - platform-height test)
- [ ] The shadow goes when the package lands (test). (QA: pass - freed on landing test)
- [ ] Game loop architecture (Content) and game/docs/game-loop/ describe it. (QA: pass - both docs updated)
- [ ] A GIF of a gift pack falling with its shadow, on the ground and on a platform, is in `art-archive/<id>/screenshots/`. (QA: pass - two GIFs present (street, roof))
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass - Godot 162 scripts/2007 tests, game/tools 686 OK, tools 579 OK)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started in build E, on top of T-402 (pickups at their height).

### 2026-10-30, In progress → In QA

A falling gift pack now shows the car's air shadow at its landing spot, at the ground's or platform's height, gone on landing; tests green, GIFs in art-archive/T-407/screenshots/.

### 2026-10-30, In QA → Needs playtest

QA passed: shadow tests, docs, both GIFs and all three test sets green (Godot 2007, Python 686 + 579); ready for your playtest.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built. `GiftDrops._drop()` adds the car's own air shadow (`car_shadow.gd`, no new art) at the landing spot, at the ground's height there (street or rooftop), in the car's shadow depth order (`elevation.shadow_z_for`; `car_z_index - 1` without rooftops). It is kept in `GiftPackage.shadow` and removed on landing (also on pickup and a new run). Like the car's, it does not grow or darken as the package nears (the car's shadow does not change with height). Not shown while the helicopter still carries the package. Kept to the falling shadow: T-405's colliders are untouched.

Tests: new `game/tests/unit/run/test_gift_drops_shadow.gd` (4 tests: the car's shadow script at the landing spot on the ground; at the platform's height with the right depth order; still while falling and freed on landing; none while carried, cleared by `clear()`). Counts: Godot 162 scripts, 2007 tests, all passing; `game/tools` Python 686 (1 skipped) OK; `tools` Python 579 OK.

Docs: `docs/game-loop-architecture.md` (the falling shadow, under "The gift pack drop"), `game/docs/game-loop/gift-pack-and-pickups.md` ("Falling shadow (T-407)").

GIFs (fixture `game/tests/fixtures/gift_pack_shadow_demo.tscn`): `art-archive/T-407/screenshots/gift_shadow_street.gif` (ground) and `gift_shadow_roof.gif` (rooftop, height 6). A contact sheet of the roof one shows the shadow under the parachute on the rooftop.
- 2026-10-30, needs-playtest → done: Build E (Platforms & heights) LGTM by the board
