---
id: T-259
title: The drift marks show on rooftops and ramps
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
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/level-design.md, game/README.md, game/scripts/driving/drift_marks.gd, game/scenes/driving/drift_marks.tscn, game/scripts/level/elevation_layer.gd, game/scripts/run/run.gd, tasks/T-117-drift-marks.md, tasks/T-249-hype-drift-trail.md, tasks/T-258-car-shadow-on-raised-ground.md]
files_expected_to_change: [game/scripts/driving/, game/scenes/driving/, game/scripts/level/elevation_layer.gd, game/scripts/run/, game/tests/, game/README.md, art-archive/T-259/screenshots/]
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

A bug the board found in a playtest (2026-10-22): when the car drifts on a rooftop or a ramp, its drift marks (T-117, with the hype trail of T-249) don't show at all; the drift smoke does. On the street they show. The marks must show on whatever surface the car drifts on (the street, a height 3 or 6 rooftop, a ramp), at that surface's height, drawn over that surface and in the same depth order as the shadow (T-258), and keep their hype look, fade and lifetime. Marks left on a rooftop stay on it (they don't drop to the street when the car leaves), and are hidden or faded with it when a building or rooftop in front covers them, as the see-through rule does for the rest. Find the cause first (for example the marks drawn only on the ground layer, under every raised area) and fix it, in the run, the level creator's runs (same code) and the elevation test scene. The drift prototype is flat and unchanged.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of drift marks on a height 3 rooftop, a height 6 rooftop and a ramp (one of them with the hype trail at x4), and a short GIF of a drift across a rooftop and down a ramp with its marks.

## Acceptance criteria

- [ ] Tests show marks laid while drifting on the street, a height 3 rooftop, a height 6 rooftop and a ramp are visible, at that surface's height and drawn over it, and stay there after the car leaves (QA: pass; new test file with 9 tests covers all four surfaces, lifted, over the area, kept after the car leaves; passes in the full suite, and the GIF shows marks staying on the ramp)
- [ ] The hype look (T-249), fade and lifetime are unchanged; the existing drift marks, elevation, depth order and see-through tests pass (QA: pass; git diff master...HEAD -- game/tests adds files only, no existing test changed; all pass)
- [ ] Screenshots and the GIF are in `art-archive/T-259/screenshots/`; `game/README.md`, "Drift marks", notes the fix; the full GUT suite and all Python tool tests pass (QA: pass; 3 screenshots and GIF present with marks visible on roof 3, roof 6, ramp x4 and rooftop-to-ramp; README Drift marks notes the fix; GUT all passed, tools 446 OK, game/tools 395 OK)

The board's review: drift on rooftops and ramps and watch the marks.
Board review files: the screenshots and GIF in `art-archive/T-259/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Open → In progress

Started at the board's report: drift marks must show on rooftops and ramps.

### 2026-10-22, In progress → In QA

Fixed: the marks were drawn flat under every rooftop and ramp; they now sit on the surface they were laid on. Sent to QA.

### 2026-10-22, In QA → Needs playtest

QA passed all 3. Ready to play: drift on rooftops and ramps and watch the marks stay on them.

### 2026-10-22, Needs playtest → Done

The board played it: looks good. Merged into master.

## Result notes

**Cause.** The marks were one flat node (`DriftMarks`) placed right after the ground tiles at z 0, with points at the street's pixels. On a rooftop or ramp the area's drawing (z above 0) covered them, and they were not lifted by the ground's height either.

**Fix.** `drift_marks.gd` has `height_at`, `depth_for`, `view_basis` (set by `run.gd` on the elevation map, so the level creator's runs too). `point_px()` lifts each point by the ground height under that tyre; each piece gets the z_index `z_for(...) - 1` of where it is laid (over the area it lies on, under buildings/boulders/areas covering the car, as the shadow), and a piece closes and a new one starts when the depth changes. The sparks node follows the depth. Street marks stay z 0; hype look, fade, lifetime unchanged. The drift prototype is untouched (flat); the elevation test scene has no marks.

**Tests.** New `tests/unit/run/test_run_drift_marks_on_raised_ground.gd` (9 tests): street, height 3, height 6, ramp (visible, lifted, over the area, stay after the car leaves), every area's top, hype look, fade and lifetime, depth-change closing, flat unchanged. Full GUT suite 1324/1324, tools 446 OK, game/tools 395 OK (1 skipped).

**Screenshots** in `art-archive/T-259/screenshots/`: `marks_roof3.png`, `marks_roof6.png`, `marks_ramp_x4.png` (hype x4 trail on the ramp), `marks_roof_to_ramp.gif` (a drift across the height 3 rooftop and down the ramp). Fixtures `tests/fixtures/run_marks_*.tscn`, `run_marks_raised_demo.gd`. Documents: `game/README.md`, "Drift marks".

No actions were refused.
- 2026-10-22, needs-playtest → done: board's playtest: looks good
