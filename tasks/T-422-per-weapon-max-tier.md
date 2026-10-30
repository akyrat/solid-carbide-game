---
id: T-422
title: Each weapon has its own top tier
status: in-qa
from: project-lead
to: weapon-behavior
lead: Audit
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: [T-408]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/weapons.md, game/scripts/weapons/weapon.gd, game/scripts/data/weapon_data.gd, game/data/weapons.json, game/scripts/weapons/starting_gun.gd]
files_expected_to_change: [game/scripts/weapons/weapon.gd, game/scripts/data/weapon_data.gd, game/data/weapons.json, game/scripts/weapons/starting_gun.gd]
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

Code hole. weapon.gd uses data.max_tier(), one weapons.json max_tier (8) for every weapon, but Weapons, Decisions now gives the gun tiers 2 to 11 (T-408); raising the shared number gives every weapon empty tiers. Give each weapon its own top tier, from its own data. Also a data guard: starting_gun.gd _fire_next() pops an empty queue and crashes when bullets is 0. Runs after T-408 (another session), which reworks the gun. Note (Project Lead, 2026-10-30): T-408 already added WeaponData.max_tier(weapon) and the gun's own max_tier 11 in weapons.json; check it, keep it, and add what is missing (tests, the gift pack check, the bullets 0 guard). The player meets nothing here beyond what T-408's playtest covered, so it merges after QA without a board's review.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Each weapon's top tier comes from its own data; the gun reaches its T-408 top tier while the others keep theirs. (QA: pass)
- [ ] A weapon at its own top tier is never offered in a gift pack. (QA: pass)
- [ ] A gun with bullets 0 in the data doesn't crash and reports an error. (QA: pass)
- [ ] New headless tests cover each criterion below that describes behaviour, and all three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Build J (Audit): started on playtest/audit-world, worktree C:\solid-carbide-worktrees\T-422, Weapon Behavior Agent. It goes to master with build J.

### 2026-10-30, In progress → In QA

Build J (Audit): the agent finished. T-408's per-weapon top tier already worked everywhere; added the gift pack check's tests and a bullets 0 error. In QA now.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Weapon Behavior Agent, 2026-10-30.

Checked T-408's work: `WeaponData.max_tier(weapon)` (own `max_tier` in the weapon's entry, else the shared 8) is used by `weapon.gd` (`max_tier()`, `is_max_tier()`, `set_tier()` clamp, `upgrade()`) and so by `level_up_offers.gd` `available_offers()`. The gift pack opens the same choice (`RunState.open_choice` -> offers), so one check covers both. Kept as is; no weapon numbers changed.

What I added:
- `game/scripts/weapons/starting_gun.gd`: the empty-queue pop was already safe (`_fire_next()` returns on an empty queue, and `step()` returned silently on bullets 0). Now bullets 0 also does `push_error` once per run (flag reset in `reset_for_run()`), and fires nothing.
- Tests: `test_weapon_data.gd` (each weapon's top tier equals its own data, tier list matches, unknown weapon falls back to the shared one); `test_level_up_offers.gd` (each weapon reaches its own top and stops there, gun 11, others 8; a weapon at its own top is never offered in a gift pack, for all six weapons over 10 seeds, and the gun at 10 is still offered); `test_starting_gun.gd` (`test_no_bullets_fires_nothing` now also expects the one error).

Test counts:
- Godot GUT, full suite: 174 scripts, 2146 tests, 2145 passing, 1 failing: `test_no_bullets_fires_nothing`, which failed only because of my new error (unexpected push_error). I fixed that test to expect the error, then reran `test_starting_gun`: 31/31 pass. I did not rerun the full 13-minute suite after that one-line test fix. `test_run_likes.gd` did not fail.
- `python -m unittest discover -s game/tools`: 722 tests OK (1 skipped).
- `python -m unittest discover -s tools`: 582 tests OK.

Screenshots: none, nothing here is on screen.

QA round 1, 2026-10-30:
- Criterion 1 pass: weapons.json has shared max_tier 8 and the gun's own 11; WeaponData.max_tier(weapon) is used by weapon.gd; new tests assert gun 11, molotov 8, clamp per weapon.
- Criterion 2 pass: gift pack test covers all six weapons over 10 seeds; the gun at 10 is still offered.
- Criterion 3 pass: starting_gun.gd returns without firing on bullets 0 and does one push_error per run; test_no_bullets_fires_nothing asserts no volleys and exactly one error.
- Criterion 4 pass: new tests present; qa_check ran all three test sets (GUT, game/tools, tools) on the branch and they passed, including the full GUT suite after the test fix.
- qa_check: tests PASS, documents PASS (none listed), screenshots PASS (nothing to picture).
