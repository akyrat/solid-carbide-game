---
id: T-167
title: Minions can be knocked back by a weapon (a knockback call)
status: in-progress
from: project-lead
to: enemy-behavior
lead: Goal-G-002
epic: enemies
milestone: mvp
goal: G-002
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/weapons.md, game/scripts/enemies/minion.gd, game/scripts/enemies/minion_spawner.gd, game/scripts/enemies/kaiju.gd, game/tests/unit/enemies/test_minions.gd, game/README.md]
files_expected_to_change: [game/scripts/enemies/minion.gd, game/tests/unit/enemies/test_minions.gd, docs/enemies.md, game/README.md]
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

The windshield wiper (docs/weapons.md, Decisions, 2026-10-18) damages the enemies it hits and knocks minions back; the board's answer says the kaiju is damaged but never pushed. Enemies have no way to be pushed by a weapon today (`minion.gd` has take_damage and walk). Add a knockback call on minions, for example `apply_knockback(direction: Vector2, strength: float)` in flat-world units, that moves the minion away over a short time the way you propose, using the same collision rules as its walking so it is never pushed through buildings, walls or boulders. Add nothing to the kaiju. Without the call, minion movement must not change. The wiper task (Weapon Behavior Agent) calls it; this task only builds and tests the call.

## Acceptance criteria

- [ ] `minion.gd` has a knockback call taking a direction and a strength; a test shows a minion in open ground ends up farther from the push's origin, in the push's direction, after the call. (QA: pass / fail)
- [ ] A test pushes a minion toward a building or boulder and shows it stops at it and never ends up inside it. (QA: pass / fail)
- [ ] The kaiju has no knockback call, and the existing enemy tests (minions, kaiju, meteors) still pass unchanged. (QA: pass / fail)
- [ ] `docs/enemies.md` Content and `game/README.md` 'Minions' describe the call, its units, and that only minions can be pushed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-18, Open → In progress

Goal runner (G-002): started, in C:\solid-carbide-worktrees\T-167.

## Result notes

Enemy Behavior Agent, 2026-10-18.

- **The call:** `minion.gd` now has `apply_knockback(direction: Vector2, strength: float)` and `is_knocked_back()`. `strength` is the push's distance in flat-world units (matching the wiper's "pushed back 1.5 units" in `docs/weapons.md`); `direction` is any length and is normalized. The minion travels the distance over `KNOCKBACK_SECONDS` (0.15 s, a proposed feel number in the code, not balancing data) at an even speed, inside its own `walk()` step, so the spawner needs no change and the pause stops it. While pushed it does not walk; then it walks on. Movement uses the same `move_and_collide` and mask 1 as walking: it slides along obstacles, and the part of the push into an obstacle is dropped, so it is never pushed into one. A second push during a push adds to what is left and restarts the 0.15 s. Zero/negative strength, a zero direction and dead minions are ignored. Without a call, `walk()` runs exactly as before (one early branch only taken while a push is active).
- **Kaiju:** untouched; it has no `apply_knockback`. The wiper should check `has_method("apply_knockback")` or the `minions` group before pushing (written in `game/README.md`, "Minions").
- **Tests** (`game/tests/unit/enemies/test_minions.gd`, T-167 section, 6 new): open-ground push (the call's distance, in its direction, farther from the origin, within 0.15 s, then walks on); a push into a building stops at its wall with the body never inside (checked every step); a push into a map boulder stops against it, never inside; bad calls and dead minions ignored; two pushes add up; the kaiju has no knockback call. The existing tests are unchanged.
- **Test run:** `bash game/tools/run_tests.sh`: 856/856 passed (74 scripts), including minions 33/33, kaiju 25/25, meteors 22/22.
- **Documents:** `docs/enemies.md` (Content, "The minion": new "Knocked back by a weapon" item); `game/README.md` ("Minions": new "Pushing a minion" section and the test list).
- PixelLab: none used. Refusals: none.
