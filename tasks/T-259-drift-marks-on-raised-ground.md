---
id: T-259
title: The drift marks show on rooftops and ramps
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
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/level-design.md, game/README.md, game/scripts/driving/drift_marks.gd, game/scenes/driving/drift_marks.tscn, game/scripts/level/elevation_layer.gd, game/scripts/run/run.gd, tasks/T-117-drift-marks.md, tasks/T-249-hype-drift-trail.md, tasks/T-258-car-shadow-on-raised-ground.md]
files_expected_to_change: [game/scripts/driving/, game/scenes/driving/, game/scripts/level/elevation_layer.gd, game/scripts/run/, game/tests/, game/README.md, art-archive/T-259/screenshots/]
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

A bug the board found in a playtest (2026-10-22): when the car drifts on a rooftop or a ramp, its drift marks (T-117, with the hype trail of T-249) don't show at all; the drift smoke does. On the street they show. The marks must show on whatever surface the car drifts on (the street, a height 3 or 6 rooftop, a ramp), at that surface's height, drawn over that surface and in the same depth order as the shadow (T-258), and keep their hype look, fade and lifetime. Marks left on a rooftop stay on it (they don't drop to the street when the car leaves), and are hidden or faded with it when a building or rooftop in front covers them, as the see-through rule does for the rest. Find the cause first (for example the marks drawn only on the ground layer, under every raised area) and fix it, in the run, the level creator's runs (same code) and the elevation test scene. The drift prototype is flat and unchanged.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of drift marks on a height 3 rooftop, a height 6 rooftop and a ramp (one of them with the hype trail at x4), and a short GIF of a drift across a rooftop and down a ramp with its marks.

## Acceptance criteria

- [ ] Tests show marks laid while drifting on the street, a height 3 rooftop, a height 6 rooftop and a ramp are visible, at that surface's height and drawn over it, and stay there after the car leaves (QA: pass / fail)
- [ ] The hype look (T-249), fade and lifetime are unchanged; the existing drift marks, elevation, depth order and see-through tests pass (QA: pass / fail)
- [ ] Screenshots and the GIF are in `art-archive/T-259/screenshots/`; `game/README.md`, "Drift marks", notes the fix; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: drift on rooftops and ramps and watch the marks.
Board review files: the screenshots and GIF in `art-archive/T-259/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
