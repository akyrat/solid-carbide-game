---
id: T-228
title: The camera follows the car's height, keeping it near the middle of the screen
status: done
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
qa_rounds: 1
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

- [ ] Tests show that with the car at height 6, after the easing settles, the car's drawn position is at the middle of the screen (within a few pixels), and on the street the camera behaves exactly as before (QA: pass; test_camera_follow_height settles centred at height 6, street identical with/without lift; run test centres on drawn car (changed test keeps its purpose: still checks the camera position on a rooftop, now per the new decision, and the lifted car is asserted))
- [ ] Tests show the height part of the camera eases rather than jumping when the car's height changes suddenly (QA: pass; sudden-change easing tests in test_camera_follow_height and the run, all GUT passing)
- [ ] Screenshots of the car on the street and on a height-6 rooftop, and a GIF of a ramp climb and a jump, from a run, show the car near the middle (QA: pass; street and rooftop PNGs have the car at the screen centre, GIF frames show it near the middle (first frame car hidden behind a faded building))
- [ ] The full GUT suite and all Python tool tests pass (QA: pass; GUT all passed, tools 439 OK, game/tools 393 OK (1 skipped))

The board's review: drive up to a height-6 rooftop and jump off it.
Board review files: the screenshots and GIF in `art-archive/T-228/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Started: the camera follows the car's height, eased smoothly.

### 2026-10-21, In progress → In QA

Built: the camera follows the car's height, eased (about 0.75 s to settle). Sent to QA.

### 2026-10-21, In QA → Needs playtest

QA passed all 4. Ready for the board: C:\solid-carbide-worktrees\T-228\game\project.godot; drive up to a height-6 rooftop and jump off.

### 2026-10-22, Needs playtest → Done

The board played it in the T-229 build: good. Merging into master.

## Result notes

Written by the agent when it finishes.

**Built.** `camera_follow.gd`: `step()` and `snap()` take an optional last argument, the lift of the car's drawing (`CarSprite.lift_for_height`, 16 px per unit, 0 on the street). The ground part follows exactly as before (smoothing, dynamic camera); the height part (`height_offset`) eases on its own, and `position` is the sum. The run (`_sync_view_elevation`), the elevation sample scene and the elevation test scene pass the car's lift. On the street the lift is 0, so the camera is unchanged.

**Easing proposal (a proposal, `HEIGHT_EASE_RATE` in `camera_follow.gd`):** 4 per second, the same exponential ease as the zoom and smoothing: about 63% of a change in 0.25 s, 95% in 0.75 s. In the GIF run the car is at most about 24 px off-centre during a ramp climb, a takeoff or a fall, and within 1 px of centre about 1.5 s after a change. Faster (6 to 8) would centre sooner but jerk more; slower (2 to 3) feels floaty.

**Tests.** New `game/tests/unit/test_camera_follow_height.gd` (6 tests: height 6 settles centred, the street is identical with and without the lift argument, a sudden change eases step by step without a jump, ground smoothing kept, snap, elevation test scene). `test_run_elevation_map.gd`: the old "camera at street level" test now expects the lifted car, plus a new easing test in the run. Results: GUT 1295/1295 pass (`bash game/tools/run_tests.sh`, one earlier failure was my own new test being wrong, fixed), `tools` 439 OK, `game/tools` 393 OK (1 skipped).

**Screenshots and GIF** (`art-archive/T-228/screenshots/`): `camera_street.png`, `camera_rooftop_height_6.png` (the car near the middle on a height-6 rooftop, both from a run), `camera_ramp_and_jump.gif` (a run driven up both ramps and off the height-6 rooftop; fixture `tests/fixtures/run_camera_height_gif.tscn`; car stays near the middle through the climb and the fall). Viewed myself: the car is mid-frame in all. The GIF is 3.8 MB.

**Documents updated:** `docs/drifting.md` (new "Camera follows the car's height" entry; the old street-level camera sentence marked superseded), `game/README.md` (Camera options, the run's elevation section, the sample map's camera line).

**Not done / refused:** nothing refused. The drift prototype has no heights, so it is unchanged.
- 2026-10-22, needs-playtest → done: board's playtest: good (played in the T-229 build)
