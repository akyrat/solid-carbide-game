---
id: T-258
title: The car's shadow shows on raised ground while the car is in the air
status: open
from: project-lead
to: driving-drift
lead:
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/level-design.md, game/README.md, game/scripts/driving/car_shadow.gd, game/scripts/driving/elevation_test.gd, game/scripts/level/elevation_layer.gd, game/scripts/run/run.gd, tasks/T-185-elevation-test-scene-the-car-s.md, tasks/T-192-elevation-round-shadow-no-bigger-option.md]
files_expected_to_change: [game/scripts/driving/, game/scripts/level/elevation_layer.gd, game/scripts/run/, game/tests/, game/README.md, art-archive/T-258/screenshots/]
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

A bug the board found in a playtest (2026-10-22): while the car is in the air over raised ground (a rooftop or a ramp), its round shadow (T-192) is not shown at all. Over the street it shows. The shadow must always show on the ground right under the car, at that ground's height, whether that is the street, a height 3 or a height 6 rooftop or a ramp, including when the car flies from one to another or off an edge. Find the cause (for example the shadow's depth putting it under the raised area it lies on, or its height not following the ground under it) and fix it, in the run, the level creator's runs (same code) and the elevation test scene. Nothing else about the car or its drawing changes.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the shadow under the airborne car over the street, a height 3 rooftop, a height 6 rooftop and a ramp, and a short GIF of a jump from a 6 down to a 3 with the shadow following.

## Acceptance criteria

- [ ] Tests show the shadow is visible and drawn above the raised area it lies on (depth order) and at that ground's height, while the car is airborne over the street, a height 3, a height 6 and a ramp (QA: pass / fail)
- [ ] The existing elevation, depth order and see-through tests pass unchanged (QA: pass / fail)
- [ ] Screenshots and the GIF are in `art-archive/T-258/screenshots/`; `game/README.md` notes the fix; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: jump between rooftops and watch the shadow.
Board review files: the screenshots and GIF in `art-archive/T-258/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
