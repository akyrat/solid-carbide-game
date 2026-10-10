---
id: T-033
title: Car collisions: bounce off walls and boulders, and take knockback
status: in-progress
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

Written by the agent when it finishes.
