---
id: T-033
title: Car collisions: bounce off walls and boulders, and take knockback
status: in-qa
from: project-lead
to: driving-drift
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-012]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/drifting/unity-prototype-report.md, docs/enemies.md, tasks/T-012-godot-drift-prototype.md, game/README.md]
files_expected_to_change: [the car's code and scene, the tuning panel, their tests, docs/drifting.md, game/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The Godot car from T-012 drives and drifts, but nothing in the drift prototype is solid yet. The rules for what happens when the car hits things are in Drifting, Decisions:

- **Bounce:** the car bounces slightly off walls (buildings and the map's edges) and off boulders.
- **Enemies:** the car does not bounce off enemies. Enemies only damage it.
- **Knockback:** minions and the kaiju's meteors knock the car back (Enemies, Decisions).

Build the car side of this:

1. **Solid bodies:** the car collides with static bodies (walls, buildings, boulders) using its 1 by 1 unit physics body (Drifting, Decisions). The drawn car may stick out past the body, as it does now.
2. **Bounce:** on hitting a wall or boulder the car bounces off slightly instead of stopping dead or sliding along it.
   - The docs give no number for "slightly". Make the bounce strength a tuning panel slider and propose a default. The board judges it in a playtest.
   - The Unity prototype has no bounce material (report, section 3), so this isn't a copy of Unity.
   - Driving and drifting away from the wall afterwards must work as before.
3. **Enemies don't block the car:** set up collision layers so enemies and the car can overlap, or at least don't push each other, and the car never bounces off them. Damage itself is not part of this task.
4. **Knockback:** a public function on the car that other agents call to knock it back: a direction and a strength, applied on the next physics step. The Enemy Behavior Agent will call it for minion hits and meteor impacts, so name and document it clearly.
5. **Test room:** add a few walls and a boulder (3 units across) to the drift prototype, so the board can try the bounce. The real map is T-019.
6. **Collision signal:** the car sends a signal whenever it hits a wall, building or boulder, so the combo (T-081) can react to it.
7. **Collision layers:** write down which layer is which (car, walls and buildings, boulders, enemies, pickups) in `game/README.md`, so the map, enemy and weapon tasks use the same ones.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test drives the car straight into a wall: the car does not pass through, and it moves away from the wall with a small speed (not zero, and less than the speed it hit with) (QA: pass / fail)
- [ ] The same test against a boulder 3 units across gives the same result (QA: pass / fail)
- [ ] A test shows the car passes into an enemy-layer body without bouncing: its speed and direction are the same as without the body (QA: pass / fail)
- [ ] A test drives the car into a wall and shows the collision signal fires once per hit (QA: pass / fail)
- [ ] A test calls the knockback function with a direction and strength, and shows the car's velocity changes in that direction on the next physics step (QA: pass / fail)
- [ ] The tuning panel has a bounce strength slider, and its reset button restores the proposed default (QA: pass / fail)
- [ ] A screenshot of the drift prototype shows the test walls and boulder (QA: pass / fail)
- [ ] `game/README.md` lists the collision layers and documents the knockback function. `docs/drifting.md` mentions the bounce slider in Content without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The T-012 and T-029 tests still pass, and the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: try the bounce in the drift prototype and pick the bounce strength.

## Result notes

**Driving & Drift Agent, 2026-10-10.**

**Built:**

- **Solid body and bounce** (`game/scripts/driving/car.gd`): the car's 1 by 1 unit body now moves with `move_and_collide`. With nothing in the way it still moves by the model's own 64-bit step, exactly as before. On a hit it stops against the obstacle for that step, and the part of its velocity going into the surface is reversed and scaled by the new `wall_bounce` setting; the part along the surface is kept. The driving model (`car_model.gd`) is unchanged.
- **Proposed bounce default: 0.25.** A head-on hit at cruise speed (11) bounces back at 2.75 units/s (it rolls about 0.4 units when W is let go); a hit at top speed (33) bounces back at 8.25 units/s (about 3.4 units). For the board to judge.
- **Bounce slider:** "Wall bounce" (0 to 1, step 0.01) in a new "Collisions (not in the Unity prototype)" group at the bottom of the tuning panel (`tuning_panel.gd`, `collision_sliders`). The value is `CarTuning.wall_bounce`, listed in a separate `CarTuning.COLLISION_SETTINGS`, because it has no Unity value; the T-012 test that checks one slider per Unity setting "and no extras" therefore still passes unchanged. The reset button restores 0.25.
- **Enemies:** the car is on layer 2 with mask 1 (obstacles only), so nothing on the enemy layer (3) can block it or make it bounce.
- **Collision signal:** `hit_obstacle(collider, shape_index, normal, impact_speed)`, emitted once per hit on anything on layer 1. Staying pressed against the same obstacle shape counts as one hit; it re-arms once the car is more than 0.25 units away from it.
- **Knockback:** `apply_knockback(direction: Vector2, strength: float)` on the car node. It adds `direction.normalized() * strength` (units/s) to the car's velocity on the next physics step, after the model's own update. Calls add up and a zero direction is ignored. `pending_knockback()` shows what is waiting.
- **Collision layers:** 1 obstacles (walls, buildings, map edge, boulders), 2 car, 3 enemies, 4 pickups. They are named in `project.godot` and are constants in `car.gd`. Walls and boulders share layer 1 because the MVP map (T-019) already puts both there; a test checks the map's bodies are on it. The table and the rules for enemies (no mask on layer 2; damage through an `Area2D`) and pickups are in `game/README.md`, "Car collisions".
- **Test room** (`game/scripts/driving/test_room.gd`, added to the drift prototype): a closed square of walls 40 units out, an L-shaped wall to the right of the start, and a boulder 3 units across at (12, -12) units. Placeholder colours are the MVP map's. It is placed outside the reach of every existing scripted drive (tests and the screenshot demo).
- **Screenshot fixtures:** `game/tests/fixtures/drift_prototype_room_flat.tscn` and `..._iso.tscn` (the demo fixture gained `start_units` and `zoom`). `bash game/tools/screenshot.sh res://tests/fixtures/drift_prototype_room_iso.tscn screenshots/T-033-room-iso.png 40` shows the car against the boulder with the walls around it. My copies are in the worktree's git-ignored `screenshots/T-033-room-flat.png` and `T-033-room-iso.png`.

**Tests:** `game/tests/unit/test_car_collisions.gd` (18 tests): straight into a wall and into a 3-unit boulder (no pass-through; bounces away at impact x 0.25, more than 0 and less than the impact speed; rolls away when W is let go; still not through after 150 steps of W), a hit at top speed, a glancing hit, driving away afterwards, bounce 0 and 1, an enemy-layer body leaving the car's position and velocity exactly as without it, the signal once per hit (also for a boulder), knockback (from standstill, while driving, adding up, into a wall), the layers (also the MVP map's), the test room, and the slider and reset. Full GUT suite: 118 of 118 pass, including the T-012 and T-029 tests, unmodified.

**Python tool tests: 3 of 51 fail, but not because of this task.** They fail the same way with my changes stashed. `test_build_mvp_map.py` errors with `KeyError: 'boulders'`, because `build_mvp_map.py` reads every `docs/level-design/<pattern>/arrow-*.json`, which now also matches the `arrow-*.driven.json` and `arrow-*.fitted.json` files that T-021's check and T-019's build write next to the sketches. So the three failures come from T-019 and T-021 together on master, not from this task. The Level/Challenge Design Agent's fix (only reading `arrow-<n>.json`) needs its own task.

**What the board should know for the playtest:**

- **W held into a wall:** the car stays pressed against the wall. W snaps the forward speed back to cruise on the next step (the Unity model), so the bounce shows when W is let go, when reversing, or on glancing hits, where the slide carries the car off the wall.
- **Knockback while W is held:** the part of a push along the nose, against the direction W drives, is cancelled one step later by the same snap to cruise. Only the sideways part stays, fading like a drift. A minion pushing head-on into a car holding W will therefore barely move it. If the board wants knockback to be felt no matter what, that needs a decision (for example a short moment where W does not snap), and the Enemy Behavior or Game Data task is the place to raise it.

**Documents affected:** `docs/drifting.md` (Content, "Godot drift prototype": a Collisions bullet with the bounce slider; Summary, Decisions and Open questions are unchanged). `game/README.md` (drift prototype panel and test room, the new "Car collisions" section with the layers, bounce, signal and knockback, and the MVP map note about collisions updated).
