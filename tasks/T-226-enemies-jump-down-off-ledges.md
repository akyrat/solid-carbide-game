---
id: T-226
title: Enemies jump down off ledges to chase the car
status: open
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
files_to_read_first: [tasks/README.md, docs/enemies.md, game/README.md, tasks/T-207-enemies-on-the-elevation-map.md, game/scripts/enemies/enemy_navigation.gd, game/scripts/enemies/enemy_path_follower.gd, game/scripts/enemies/enemy_height.gd]
files_expected_to_change: [game/scripts/enemies/, game/tests/unit/, docs/enemies.md, game/README.md, art-archive/T-226/screenshots/]
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

The board noticed in a playtest (2026-10-21) that enemies on a rooftop won't jump off its edge to chase a car below: they walk all the way round to a ramp. The board's decision (Enemies, Decisions, "Enemies jump down off ledges"): going down, enemies jump (drop) off a rooftop's edge to chase the car. Going up still needs a ramp, and an edge still blocks them from below (T-207).

Add one-way links in the pathfinding (`enemy_navigation.gd`, T-207's A* grid) from a rooftop's edge cells down to the cells below, so a path down can drop off an edge, and make the enemy fall to the lower level when it does, landing on the ground below (falling like the car does, with gravity, or a short drop: your proposal). Its height and depth order follow it as it falls. Enemies still never climb an edge, and still never end up inside a building. Keep it fast with as many enemies as the run spawns. Proposals for the playtest, in the result notes: how the drop looks, whether an enemy can hurt the car while falling, and whether the kaiju jumps down too.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots and a short GIF of enemies dropping off a rooftop to chase the car (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] In a GUT test with enemies on a height-6 rooftop and the car on the street beside it, the enemies drop off the nearest edge instead of walking to a ramp, and reach the car sooner than before (the test states both times) (QA: pass / fail)
- [ ] Tests show enemies still can't climb an edge from below, still use the ramps to go up, and never end up inside a building (QA: pass / fail)
- [ ] A falling enemy's height and depth order follow it down (test, and a GIF from a run in `art-archive/T-226/screenshots/`) (QA: pass / fail)
- [ ] A 2-minute scripted run on the elevation map has no errors during play, and the result notes give the frame time with the most enemies on screen (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: play a run, go below enemies on a rooftop and watch them jump down after you.
Board review files: the GIF in `art-archive/T-226/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
