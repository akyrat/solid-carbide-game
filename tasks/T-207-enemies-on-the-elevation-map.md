---
id: T-207
title: Enemies follow the car up the ramps on the elevation map, with pathfinding
status: in-progress
from: project-lead
to: enemy-behavior
lead: Coursework
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/level-design.md, game/README.md, tasks/T-206-run-on-the-elevation-sample-map.md, game/scripts/enemies/enemy_depth.gd, game/data/level/elevation_sample_map.json]
files_expected_to_change: [game/scripts/enemies/, game/tests/unit/, docs/enemies.md, game/README.md, art-archive/T-207/screenshots/]
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

**Rewritten after the board's playtest (2026-10-21).** In T-206's build the run plays on the elevation sample map, and the enemies completely ignore every raised surface. The board decided how they handle heights (Enemies, Decisions, "Enemies follow the car up the ramps"): enemies treat rooftops as raised ground they can reach only by the ramps. To reach a car on a rooftop they find their way to a ramp, go up it and follow the car, with pathfinding over the map's streets, ramps and rooftops. A rooftop's edge blocks them like a wall from below. Enemies on a rooftop stay on it until they go down a ramp.

Build that for every enemy that chases the car. Enemies get a height like the car's (from the map's ground height), are drawn at it in the right depth order, and their contact damage only hits the car when they are at the car's level. Pathfinding: use what Godot gives (for example a navigation mesh or an A* grid built from the map file's heights and ramps); choose what fits and say why in the result notes. It must stay fast with as many enemies as the run spawns (the T-206 soak reached 21 on screen). Enemies that spawn from the screen edges spawn on the street. For the kaiju and anything the decision doesn't cover, make a proposal for the playtest and list it in the result notes. Do not add new enemies or change their stats, numbers or attacks.

This builds on T-206's work, which is still being tweaked: branch from `task/T-206-run-on-elevation-map`, merge it again before handing over if it has moved, and this ticket merges only after T-206.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the work (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] In a GUT test with the car parked on a height-6 rooftop, enemies that start on the street reach it by going up the ramps (their path passes through the ramps, never through a rooftop's edge), within a time limit the test states (QA: pass / fail)
- [ ] In a GUT test with the car on the street, enemies on a rooftop come down by a ramp to reach it; no enemy crosses a rooftop's edge from below, in a test that drives enemies at every edge (QA: pass / fail)
- [ ] Enemies are drawn at their height in the right depth order next to the rooftops, ramps and the car, and contact damage only hits the car at its level (screenshots of enemies on a ramp and on a rooftop, and a test for the damage) (QA: pass / fail)
- [ ] A 2-minute scripted run on the elevation map has no errors during play, and the result notes give the frame time with the most enemies on screen, compared with T-206's soak (QA: pass / fail)
- [ ] Enemies, Decisions has this ticket's id on "Enemies follow the car up the ramps", and the result notes list every proposal made (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: play a run on the elevation map and judge how the enemies follow the car up and down the ramps.
Board review files: a run from the main menu.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Blocked → In progress

Started from T-206's build: enemies find their way up the ramps to the car, with pathfinding, as the board decided.

## Result notes

Written by the agent when it finishes.
