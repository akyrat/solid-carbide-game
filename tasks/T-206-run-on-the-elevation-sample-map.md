---
id: T-206
title: A run plays on the elevation sample map
status: open
from: project-lead
to: game-loop
lead: Coursework
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/level-design.md, docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/game-loop-architecture.md, docs/drifting.md, game/README.md, game/scripts/run/run.gd, game/scripts/level/elevation_sample_map.gd, game/data/level/elevation_sample_map.json, tasks/T-196-elevation-sample-map.md, tasks/T-197-elevation-sample-depth-order.md]
files_expected_to_change: [game/scripts/run/run.gd, game/scenes/run/run.tscn, game/tests/unit/, game/README.md, art-archive/T-206/screenshots/]
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

The board played the elevation sample map (G-004) and wants it to become the game's map: a run started from the main menu (Start) plays on the elevation sample map's layout as the full game, with enemies, weapons, the timer, likes and levels, gift drops and the kaiju, so the board can see how the enemies behave on it (Level design, Decisions, "The elevation sample map becomes the run's map", 2026-10-20).

Today `run.gd` builds `mvp_map.tscn` with the MVP layout. `elevation_sample_map.gd` builds the same map script from `data/level/elevation_sample_map.json`, with the raised areas, the ramps, the car's height (`car_height.gd`, GroundHeight), its round shadow, the shadowless frames in the air, see-through and the depth order (T-196, T-197, T-205). Make the run use that layout and everything elevation brings, reusing the sample map's code rather than copying it. The run's other parts keep working on it: enemies spawning from the screen edges, weapons, pickups, coins, the HUD, the pause screen, drift marks and the camera. Where the run's things need a place in the depth order next to the raised areas (enemies, pickups, coins, effects), draw them as the street level does today, at height 0. How enemies deal with heights is T-207's job, so don't change enemy behaviour here.

Keep the MVP map. It stays in the project, and one constant or setting switches the run back to it (say which in `game/README.md`). The drive-only elevation sample scene keeps working (F6).

Where the docs leave something open (for example where the car starts on the new map), make a proposal for the playtest and list it in the result notes.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the work (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] A run started from the main menu's Start plays on the elevation sample map's layout: its rooftops, ramps, buildings and roads, with the car's height, round shadow, see-through and depth order as in the drive-only scene (screenshots of the car on the street, on a rooftop and in the air during a run) (QA: pass / fail)
- [ ] During that run the enemies spawn and chase the car, weapons fire, the timer, likes and levels run, and the level-up gift drop and the kaiju still come, with no errors in Godot's output over a 2-minute headless or scripted run (QA: pass / fail)
- [ ] The MVP map is still in the project, and one named constant or setting switches the run back to it; `game/README.md` says which (QA: pass / fail)
- [ ] The drive-only elevation sample scene still runs (F6) as before (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass, with new tests for the run building the elevation map (QA: pass / fail)

The board's review: start a run from the main menu and play the full game on the elevation sample map.
Board review files: `game/scenes/run/run.tscn` via the main menu.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
