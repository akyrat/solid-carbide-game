---
id: T-033
title: Car collisions: bounce off walls and boulders, and take knockback
status: done
from: project-lead
to: driving-drift
lead:
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-012]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/drifting/unity-prototype-report.md, docs/enemies.md, tasks/T-012-godot-drift-prototype.md, game/README.md]
files_expected_to_change: [the car's code and scene, the tuning panel, their tests, docs/drifting.md, game/README.md]
model: opus
qa_rounds: 1
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

### QA round 1

**QA/Integration Agent, 2026-10-10.** Checked in `C:\solid-carbide-worktrees\T-033` on `task/T-033-car-collisions-and-knockback` (head `ceb97de`). Besides the agent's tests, I ran my own temporary GUT checks (not committed): a wall hit with W let go at impact, an off-centre hit on a 3-unit boulder, enemy-layer bodies set up as `game/README.md` says (mask 1, and mask including the car), knockback in four directions, both playtest notes, and 3000 to 6000 steps of random driving in the prototype's test room. All of them passed.

1. **Into a wall: pass.** `test_car_bounces_off_a_wall`: the body stops at the wall face, then moves away at impact x 0.25 (more than 0, less than the impact speed), rolls away when W is let go, and is still not through after 150 more steps of W. My check: impact 25.9 units/s, bounce speed 6.48, after letting go it rolled 2.4 units back and stopped. One hit signal.
2. **Into a 3-unit boulder: pass.** `test_car_bounces_off_a_boulder_3_units_across` gives the same result as the wall test, with a `CircleShape2D` 3 units across. My off-centre hit: impact 18.4, speed after 5.9 (a deflection off the curve). The car's centre never came closer than 2.12 units to the boulder's centre (radius 1.5 + half body 0.5).
3. **Enemy-layer body: pass.** `test_car_passes_through_an_enemy_layer_body_unchanged`: the car's x, y, vx and vy match exactly those of a car on the same route with no body there, and there is no hit signal. My check with two layer-3 bodies (mask 1, and mask 1 + 2) across a straight route gave the same: exact match, no hit. The car's mask is layer 1 only, so this holds whatever mask the enemy has.
4. **Collision signal once per hit: pass.** `test_hit_signal_fires_once_per_hit`: 1 signal on the hit, still 1 after 60 steps of W pressed against the wall, none while reversing, then 2 and 3 after new hits. It passes the wall body, a normal pointing out of the wall and the impact speed. The boulder version also passes. In my wall check: 1 signal over the hit plus 100 steps of rolling away.
5. **Knockback function: pass.** `apply_knockback(direction, strength)`: there is no change before the step. On the next step the velocity changes by `direction.normalized() * strength` (tests from standstill, while driving against a twin car, calls adding up, a zero direction ignored, a push into a wall bounces). My check in four directions, including the non-normalized (-2, 5), got exactly that velocity.
6. **Bounce slider and reset: pass.** `collision_sliders["wall_bounce"]` covers 0 to 1, starts at 0.25, has a tooltip and applies at once. The panel's reset button puts it back to 0.25 and the slider follows (`test_bounce_slider_and_reset`). It also appears in `CarTuning.default_values()`, so the car's own reset covers it.
7. **Screenshot: pass.** My own screenshots, `screenshots/qa-T-033-room-iso.png`, `qa-T-033-room-flat.png` and `qa-T-033-room-flat-150.png` (git-ignored), show the boulder, the L-shaped wall and the outer walls, with the car below the boulder. Minor: at 40 frames the car has not reached the boulder yet. At 150 frames it is pressed against it. README says 40 frames is enough, which holds for showing the walls and boulder but not the contact.
8. **Documentation: pass.** `game/README.md` has a "Car collisions" section with the layer table (1 obstacles, 2 car, 3 enemies, 4 pickups, bit values, how each is set up), the bounce, the `hit_obstacle` signal and the `apply_knockback` function. The layer names are also in `project.godot`. The layers match the MVP map: its `Walls` and boulder bodies are StaticBody2D on the default layer 1 (`test_mvp_map_obstacles_are_on_the_obstacle_layer`). In `docs/drifting.md` the only change is one Collisions bullet in Content (line 72), and Summary, Decisions and Open questions are unchanged. Minor: the README table says obstacles have "mask none", but the MVP map's bodies keep Godot's default mask 1. For static bodies this makes no difference.
9. **Tests: pass.** Full GUT suite: 118 of 118 pass, TESTS PASSED, 12 scripts. The one warning is GUT ignoring the `TestRoom` preload constant in the test file, which is harmless. The T-012 and T-029 tests (`test_drift_model.gd` 18/18, `test_drift_prototype.gd` 15/15) are unchanged on this branch and pass. `git diff master...HEAD -- game/scripts/driving/car_model.gd` is empty, so the driving model is unchanged. Root `tools`: 72 tests OK. `game/tools`: 51 tests, 3 fail, all in `test_build_mvp_map.py` (two `KeyError: 'boulders'` in setUpClass and `12 != 6` in `test_write_leaves_the_sketches_unchanged`). That is the map-generator bug master fixed in T-087, after this branch was made, and this branch changes nothing under `game/tools`, `tools` or `docs/level-design`. Every other test passes.

**The agent's playtest notes match the code.** With W held against a wall, the car stays exactly in place (y constant to 4 decimals over 30 steps), because W snaps the forward speed back to cruise each step and the bounce only shows without W. With W held and a 20 units/s push against the nose, the forward speed went from 19.3 to -0.4 on the next step and back to 11.0 (cruise) on the step after. So the push along the nose is cancelled after one step, as the notes say.

**For the Project Lead:** this branch does not merge cleanly into the current master. `game/scripts/driving/drift_prototype.gd` conflicts with T-015 (pause screen), because both add `const ... preload` lines in the same place. It is a trivial conflict, but it needs resolving at merge time, and the full GUT suite should be re-run after the merge.

### Board review

The board drove it on 2026-10-10: approved, with the proposed bounce strength of 0.25. Knockback being cancelled against the nose while W is held is fine.
