---
id: T-169
title: The molotovs: thrown from the car, they leave fire areas that burn enemies (placeholder look)
status: done
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
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/visual-style.md, docs/extended-narrative.md, game/data/weapons.json, game/scripts/weapons/weapons.gd, game/scripts/weapons/weapon.gd, game/scripts/weapons/bullet.gd, game/scripts/weapons/starting_gun.gd, game/scripts/enemies/enemy_depth.gd, game/README.md]
files_expected_to_change: [game/scripts/weapons/molotovs.gd, game/scripts/weapons/molotov_fire.gd, game/scripts/weapons/weapons.gd, game/tests/unit/weapons/test_molotovs.gd, docs/weapons.md, game/README.md]
model: opus
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

Build the molotovs (docs/weapons.md, Decisions, 2026-10-18): thrown from the car at random, each makes a circular area on fire where it lands, and enemies in a fire area burn and take damage. The board's answer: an enemy burns only while it is inside the fire area, not after it leaves. Add a weapon script to the rack (id `molotov`), not owned at the start of a run, given and upgraded through `rack.upgrade("molotov")`, with all numbers and tiers 2 to 8 read from its weapons.json entry (D1). When and where they land within 'at random' is your proposal (use the run's random generator so tests can seed it): write it in the result notes. Bottles in flight and fire areas are projectiles in the rack (add_projectile), so they stop while paused and are cleared on a new run. Damage through take_damage, times the garage damage multiplier. Placeholder look drawn in code: a small bottle in flight and a flat fire circle on the ground, never Redgull red; the final art comes later (D10). Do not add the level-up choice: that is D7.

The board's review: Play a run from the task folder with the molotovs given and see the placeholder bottles land and their fire areas burn minions.

## Acceptance criteria

- [ ] A new run has no molotovs; after `rack.upgrade("molotov")`, a seeded test shows a molotov thrown at the interval from weapons.json lands within the distance weapons.json gives and leaves a fire area of the radius weapons.json gives. (QA: pass)
- [ ] A test shows a fake enemy inside a fire area takes damage with the values from weapons.json (times the garage damage multiplier), and one outside or that has left the area takes no more damage. (QA: pass)
- [ ] Tests show fire areas expire after their duration, stop while paused, and are removed on a new run. (QA: pass)
- [ ] A test per tier 2 to 8 applies the tier from code and checks the change weapons.json gives it. (QA: pass)
- [ ] Placeholder bottle and fire area are drawn in code, in no shade of Redgull red; `docs/weapons.md` Content and `game/README.md` 'Weapons' describe the molotovs, and the game's test set passes. (QA: pass; GUT 904/904, color test passes, docs mention molotovs)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-18, Blocked → In progress

Goal runner (G-002): started, in C:\solid-carbide-worktrees\T-169.

### 2026-10-18, In progress → In QA

Goal runner (G-002): the agent is done; QA is checking it.

### 2026-10-18, In QA → Needs playtest

Goal runner (G-002): QA passed; merged into playtest/G-002.

## Result notes

Weapon Behavior Agent, 2026-10-18.

**Built:** `game/scripts/weapons/molotovs.gd` (the weapon, id `molotov`, plus the in-flight bottle as inner class `MolotovBottle`) and `game/scripts/weapons/molotov_fire.gd` (one fire area), listed in `weapons.gd`'s `WEAPON_SCRIPTS` (`rack.molotov`). Not owned at the start of a run; `rack.upgrade("molotov")` gives it and applies tiers 2 to 8, every number from `WeaponData.molotov_at(tier)` (weapons.json "molotov"), damage times `rack.damage_multiplier()`. Bottles and fire areas are rack projectiles, so they stop while paused or after the run ends and are cleared at a new run. No level-up choice (D7).

**My proposal for "at random" (for the board's playtest):**
- A throw clock starts when the car gets the molotovs. Each time it reaches `throw_interval`, `molotovs_per_throw` bottles leave the car's centre at the same moment.
- Each bottle has its own landing spot: a direction anywhere around the car (uniform angle) and a distance picked evenly between `throw_distance_min` and `throw_distance_max` (3 to 8). Where enemies are plays no part. The spot is fixed when the bottle leaves. It can land on a building or boulder; the fire burns there anyway.
- The random numbers come from the weapon's own `RandomNumberGenerator` (`rack.molotov.rng`), which tests seed. The run has no shared random generator, so I followed the minion spawner and the kaiju, which each keep their own. A new run does not re-seed it.
- A bottle takes 0.5 s to land (`FLIGHT_SECONDS`), along an arc 1.5 units high. These are look and feel values kept in the code, not in weapons.json. If the board wants them tunable, they can move to the data (Game Data Agent).
- A fire area keeps the tier values it landed with. Overlapping fire areas each burn: an enemy inside two is hit by both.
- Hit timing inside a fire is the underglow's rule. Each enemy has its own clock per fire: it is hit on the step it enters (`damage_on_enter`), then every `tick_interval` while it stays. Once it leaves it takes nothing more (the board's answer). The kaiju counts as inside when its body overlaps the circle, a minion when its centre is inside.

**Rack change:** `add_projectile(p, parent = null)`. The fire areas go in a node `MolotovFires` in the map's `view_root`, right after `DriftMarks`. That puts them on the ground (the map's isometric transform makes the circle an ellipse), with buildings, enemies and the car drawn over them, and they are still stepped and cleared like any projectile.

**Placeholder look:** a green bottle with a pale rag and a yellow flame, spinning in flight. A flat fire disc: dark rim, orange, yellow middle, pale core, small yellow flickers. Opaque, hard-edged, no Redgull red (tested). Screenshot: `art-archive/T-169/screenshots/molotov.png`. Three fire areas with burning minions (they show the minions' hit flash) and a ring of minions walking in.

**Playtest switch:** `game/data/playtest.json` gets `molotov_at_start` (false). True gives the molotovs at the start of every run, until the level-up offers them. That file was not in files_expected_to_change; I added the switch the same way the underglow's was added.

**For the board's review:** open `C:\solid-carbide-worktrees\T-169\game\project.godot` and play `tests/fixtures/weapons/molotov_demo.tscn` with F6: three bottles are thrown at once, minions get dropped into the first fires, and after 2 s the keyboard drives. Or set `molotov_at_start` to true and press F5.

**Tests:** `game/tests/unit/weapons/test_molotovs.gd`, 25 tests covering every criterion: a seeded throw at the interval, landing within the distances and leaving a fire of the data's radius; damage inside times the garage multiplier, none outside or after leaving; expiry, pause, end of run, a new run; one test per tier 2 to 8 read from weapons.json; colours. Full GUT suite: 904/904 passed. Python tool tests: 278 OK (1 skipped).

**Documents updated:** `docs/weapons.md` (Content, "The molotovs (built in task T-169)") and `game/README.md` ("Weapons", "The molotovs", plus the rack's `add_projectile` parent).

**Not committed:** Godot's line-ending-only `.import` noise, left in the working tree as the rules say.

**PixelLab:** none used. **Refusals:** none.
- 2026-10-18, in-qa → needs-playtest: QA passed every criterion (goal G-002).
- 2026-10-18, needs-playtest → done: Board's playtest of G-002 (2026-10-18): works great.
