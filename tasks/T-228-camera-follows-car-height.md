---
id: T-228
title: The camera follows the car's height, keeping it near the middle of the screen
status: open
from: project-lead
to: driving-drift
lead: Coursework
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/README.md, game/scripts/driving/camera_follow.gd, tasks/T-206-run-on-the-elevation-sample-map.md]
files_expected_to_change: [game/scripts/driving/camera_follow.gd, game/scripts/run/, game/tests/unit/, game/README.md, docs/drifting.md, art-archive/T-228/screenshots/]
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

The board's decision (Drifting, Decisions, "The camera follows the car's height", 2026-10-21): in a run on the elevation map the camera follows the car's ground position and ignores its height (T-206's proposal), so on a height-6 rooftop the car sits high on the screen and the board "can't really see a lot of what is happening". Make the camera follow the car as drawn, height included (the car's drawing is lifted 16 pixels per unit of height, Drifting, Content), so the car stays near the middle of the screen on rooftops, ramps and in the air. Ease the height part smoothly (your proposal for how fast), so a jump, a landing or a drive up a ramp doesn't jerk the view; the ground part follows as it does today, including the camera options (smoothing, dynamic camera). Use it in the run, the drive-only elevation sample scene and the elevation test scene. On the street nothing changes.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the car on the street and on a height-6 rooftop, and a short GIF of the car driving up a ramp and jumping off a rooftop (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] Tests show that with the car at height 6, after the easing settles, the car's drawn position is at the middle of the screen (within a few pixels), and on the street the camera behaves exactly as before (QA: pass / fail)
- [ ] Tests show the height part of the camera eases rather than jumping when the car's height changes suddenly (QA: pass / fail)
- [ ] Screenshots of the car on the street and on a height-6 rooftop, and a GIF of a ramp climb and a jump, from a run, show the car near the middle (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: drive up to a height-6 rooftop and jump off it.
Board review files: the screenshots and GIF in `art-archive/T-228/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
