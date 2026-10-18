---
id: T-168
title: The neon underglow: a circle around the car that damages enemies (placeholder look)
status: in-progress
from: project-lead
to: weapon-behavior
lead: Goal-G-002
epic: weapons
milestone: mvp
goal: G-002
user_facing_text: no
changes_visuals: yes
depends_on: [T-166]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/visual-style.md, docs/extended-narrative.md, game/data/weapons.json, game/scripts/weapons/weapons.gd, game/scripts/weapons/weapon.gd, game/scripts/weapons/flamethrower/exhaust_flamethrower.gd, game/tests/unit/weapons/test_exhaust_flamethrower.gd, game/README.md]
files_expected_to_change: [game/scripts/weapons/neon_underglow.gd, game/scripts/weapons/weapons.gd, game/tests/unit/weapons/test_neon_underglow.gd, docs/weapons.md, game/README.md]
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

Build the neon underglow (docs/weapons.md, Decisions, 2026-10-18): neon lights under the car make a circular area around it; every enemy inside takes damage every second, and an enemy takes damage as soon as it enters. Add it as a weapon script in the rack (`WEAPON_SCRIPTS` in `weapons.gd`, id `underglow`), not owned at the start of a run, given and upgraded through `rack.upgrade("underglow")`, with all numbers and tiers 2 to 8 read from its `weapons.json` entry (D1). Damage goes through each enemy's take_damage and is multiplied by the garage damage bonus (`rack.damage_multiplier()`), as the board decided for every weapon. Use the rack's target rules (minions by centre, the kaiju by body overlap, as the flamethrower does). Whether an enemy leaving and re-entering within the same second is hit again on entry is your proposal: write it in the result notes. Placeholder look: a flat circle drawn in code under the car showing the area, in a neon colour that is never Redgull red; the Asset Generation Agent swaps the final art in later (D10). Do not add the level-up choice: that is D7.

The board's review: Play a run from the task folder with the underglow given (by its test fixture or the playtest switch the agent records) and see the placeholder circle under the car hurt minions.

## Acceptance criteria

- [ ] A new run has no underglow; after `rack.upgrade("underglow")` a test shows a fake enemy that enters the circle takes damage on that step, and an enemy staying inside takes damage again once per tick interval from weapons.json, with the damage value from weapons.json times the garage damage multiplier. (QA: pass / fail)
- [ ] A test per tier 2 to 8 applies the tier from code and checks the change weapons.json gives it. (QA: pass / fail)
- [ ] A test shows no damage while the run is paused or after it ends, and that a new run removes the underglow. (QA: pass / fail)
- [ ] A placeholder circle drawn in code shows under the car while it is owned, in no shade of Redgull red, drawn below the car sprite (checked in a test or a screenshot fixture). (QA: pass / fail)
- [ ] `docs/weapons.md` Content and `game/README.md` 'Weapons' describe the underglow, and the game's test set passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-18, Blocked → In progress

Goal runner (G-002): started, in C:\solid-carbide-worktrees\T-168.

## Result notes

Written by the agent when it finishes.

**Weapon Behavior Agent, 2026-10-18.**

- **Built:** `game/scripts/weapons/neon_underglow.gd` (id `underglow`, not owned at the start of a run), listed in `WEAPON_SCRIPTS` in `weapons.gd` (also `run.weapons.underglow`). Every number and tiers 2 to 8 come from `weapons.json` through `WeaponData.underglow_at()`; damage is multiplied by `rack.damage_multiplier()`. Targets follow the rack's rules (minions by centre, an enemy with `hit_radius_units()`, the kaiju, by body overlap). No level-up choice (D7).
- **Proposal, leaving and re-entering within the same second:** each enemy has its own hit clock. An enemy inside is hit when it hasn't been hit by the underglow in the last tick interval. So it is hit on the step it enters and every interval after, but one that steps out and back in before its interval is over gets **no extra hit on re-entering**: it is hit when its interval runs out, if still inside. This stops enemies on the edge from being hit every step as they jitter in and out. One that stayed out longer than the interval is hit as it enters. Written in `docs/weapons.md` Content as a proposal for the playtest.
- **Placeholder look:** a ring drawn in code (the damage circle through the isometric transform), opaque and hard-edged: dark outline, cyan ring, darker cyan inner line. No Redgull red. It is the first child of the run's `View`, so it sits below the car sprite, the drift smoke and the flames, and grows with the radius tiers. The Asset Generation Agent swaps the art in later (D10).
- **For the board's review:** open `C:\solid-carbide-worktrees\T-168\game\project.godot`, open `tests/fixtures/weapons/underglow_demo.tscn` and press F6. That starts a run from the main menu with the underglow given and four minions inside the ring, and after 2 seconds the keyboard drives the car. Or set `underglow_at_start` to `true` in `game/data/playtest.json` (a new playtest switch, off by default) and play normally with F5. Screenshot: `bash game/tools/screenshot.sh res://tests/fixtures/weapons/underglow_demo.tscn screenshots/underglow.png 40` (saved to `C:\solid-carbide-worktrees\T-168\screenshots\underglow.png`, which git ignores; the hits printed 1.05 because the real save's garage damage bonus is applied there).
- **Tests:** `game/tests/unit/weapons/test_neon_underglow.gd`, 23 tests (one per tier 2 to 8). Full GUT suite and Python tool tests: see below.
- **Files changed:** `game/scripts/weapons/neon_underglow.gd` (new), `game/scripts/weapons/weapons.gd`, `game/data/playtest.json` (new switch `underglow_at_start`, false), `game/tests/unit/weapons/test_neon_underglow.gd` (new), `game/tests/fixtures/weapons/underglow_demo.gd` and `.tscn` (new), `docs/weapons.md` (Content, "The neon underglow (built in task T-168)"), `game/README.md` (Weapons, "The neon underglow").
- **Documents affected:** `docs/weapons.md`, `game/README.md`.
- PixelLab: 0 generations. Refusals: none.
