---
id: T-483
title: Record the tutorial clips: a zoomed-out drift, a long drift, an alt drift, and a ramp jump with hang time and an air spin
status: in-progress
from: project-lead
to: driving-drift
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/drifting.md, game/scenes/drift_prototype/, game/scenes/elevation_test/]
files_expected_to_change: [game/tools/, game/tests/, game/art/tutorial/clips/, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-11-01 (HUD and menus, Decisions, "The tutorial slides are redrawn, with clips of the real car"): the redrawn tutorial slides show short looping clips of the real car, recorded from the game on a simple background (like the drift prototype's plain grid), never cut from run recordings with the city and the HUD. The board rejected clips cut from old test GIFs. Record four clips, as GIFs, by script so they can be re-recorded:

1. **The drift, zoomed out** (slide 1): seen from higher up than the run's camera (zoomed out), so the whole path shows: the car driving straight, then turning with W held so it breaks into a drift, its tyre marks and smoke tracing the path it takes from where the drift starts. The camera holds still (or follows slowly) so the trajectory reads.
2. **Long drift** (slide 2): one long unbroken drift.
3. **Alt drift** (slide 2): drifting one way, then flicking into a drift the other way, as the ALT DRIFT! trick counts it.
4. **Ramp jump** (slide 2): the car takes a ramp at speed, flies into the air with enough airtime for HANG TIME!, and spins while airborne (an air 180 or 360), then lands, all in one clip.

Each clip: the real car code and art, a simple background with nothing else (no HUD, no enemies, no popups), a few seconds long and looping cleanly, about 480 x 320 pixels, nearest-neighbour, small enough for a slide (aim under 1.5 MB each). Drive the car by script (inputs), the way the existing recording tools do. Put the final GIFs in game/art/tutorial/clips/ (they will be shown on the slides later; nothing in the game uses them yet), with a short record JSON per clip saying how it was made. Keep every take you record in art-archive/<this ticket>/ (never delete). No game behaviour changes. Never write, move or commit anything in game/data/levels/.

The board's review: watch the four clips; the Project Lead puts them on the draft page.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Four GIFs exist in game/art/tutorial/clips/: the zoomed-out drift, the long drift, the alt drift and the ramp jump, each with a record JSON; the result notes list their sizes, lengths and file sizes. (QA: pass / fail)
- [ ] Each clip shows only the car (with its tyre marks, smoke and shadow) on a simple background: no HUD, enemies, popups or city. (QA: pass / fail)
- [ ] The drift clip's camera is zoomed out enough that the drift's path from its start shows in the frame (the result notes say the zoom used against the run's). (QA: pass / fail)
- [ ] The ramp clip shows the car leaving a ramp, airborne long enough for the airtime trick (the result notes give the airtime against the HANG TIME! threshold) and turning at least 180 degrees in the air before landing. (QA: pass / fail)
- [ ] A script re-records all four (the result notes say how to run it); a test checks the script's output (four files, the expected size). (QA: pass / fail)
- [ ] Only tools, tests, the clips and docs change: no game script or scene behaviour changes. (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content) says where the clips are and how to re-record them. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1800 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Started: the Driving & Drift Agent records the four tutorial clips from the real car on a plain background.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the Driving & Drift Agent (2026-11-01).

**The four clips** (`game/art/tutorial/clips/`, each with `<name>.json`), all 480 x 320 pixels, a straight crop of the 1152 x 648 window (no scaling, nearest by construction), looping, one shared palette:

| Clip | File | Length | Frames | Size |
|---|---|---|---|---|
| Drift, zoomed out (slide 1) | `drift.gif` | 6.0 s | 150 at 25 fps | 140,530 bytes |
| Long drift (slide 2) | `long_drift.gif` | 5.04 s | 84 at 16.7 fps | 1,428,518 bytes |
| Alt drift (slide 2) | `alt_drift.gif` | 3.84 s | 64 at 16.7 fps | 1,010,558 bytes |
| Ramp jump (slide 2) | `ramp_jump.gif` | 3.06 s | 51 at 16.7 fps | 1,433,801 bytes |

All four are under the 1.5 MB aim. The three clips whose camera follows the car redraw the whole frame every frame, so they keep every third physics step (16.7 fps); the held-camera drift clip keeps every second (25 fps). The records also hold the tricks and air numbers the real car printed during the take.

**What is on screen:** the drift prototype's plain grid (the test room's walls and boulder removed, its HUD hint, tuning panel and trick popups hidden) with the grid drawn in a light grey (fixture-only colours, because the grid's own dark navy hides the dark tyre marks), the real car, its shadow, tyre marks and smoke. The ramp clip adds the ramp and a short rooftop (the game's placeholder art). No HUD, enemies, popups or city.

**Zoom (drift clip):** orthographic size 28 against the run's 14.4 (about 1.94 times further out, so the car is about half the size); the camera is held still at one point (`fixed_camera`), the car enters from outside the frame, drives straight, breaks into a drift with W + A, and the whole drift circle shows from where it starts; the marks fade after the car leaves, so the clip loops from an empty grid. The long and alt drifts use the run's own 14.4 with a following camera.

**Alt drift:** W + A drift for 1 s, then W released and S pressed with A kept (the forward-then-backward drift with the same steering the detector counts); the real detector printed `alternate_drift` at step 96. The long drift (3.4 s of W + A) also earns a drift 360 at 2.5 s, since one unbroken drift that long turns a full circle.

**Ramp jump:** the elevation test's ramp (12 long, 8 wide, 0 to 3) up to a short rooftop (8 long) of its own, so the car flies over the rooftop and lands on the street: on the elevation test's 16-unit rooftop the car lands on it after 0.66 s and turns only about 160 degrees, short of a 180. The ground data is `game/tests/fixtures/data/tutorial_ramp.json`, read by `tutorial_ramp_scene.gd`, a copy of `elevation_test.gd` with only that path changed (the game's scene and script are untouched). The real car holds W up the ramp, then W + A from takeoff: takeoff off the ramp's top at 16.5 units/s, **airtime 1.12 s against the HANG TIME! minimum of 0.30 s** (combo.json, airtime.min_seconds), **264 degrees turned in the air** (the detector printed `air_one_eighty`), landing on the street.

**Re-recording:** from the repo root, `python game/tools/record_tutorial_clips.py` (a real window, not headless; about 15 s a clip; `--only drift long_drift ...`, `--no-archive`). Fixtures: `game/tests/fixtures/tutorial_clip_<name>.tscn` with `tutorial_clip_demo.gd` (the inputs, zoom, camera and start are exported values in each scene). Every take is copied to `art-archive/T-483/takes/` (6 takes kept; two earlier trial takes of the long and alt drifts, at 25 fps and over 1.5 MB, were removed with the first run's folder by mistake and are not kept).

**Tests:** `game/tools/test_record_tutorial_clips.py` (crop, assembly at the clip size and loop, then the four committed GIFs and records: size, under 1.5 MB, the ramp record's airtime and half turn, the alt record's trick) and `game/tests/unit/test_tutorial_clips.gd` (the four scenes load with a drive, the drift clip is zoomed out with a held camera, the ramp ground is valid, and the real car driven the way the clip drives it takes off from the ramp, with more than the minimum airtime and over 180 degrees turned). Results: `python -m unittest discover -s game/tools -p "test_*.py"`: 864 tests OK (1 skipped); `python -m unittest discover -s tools -p "test_*.py"`: 633 tests OK; GUT (`GUT_TIME_LIMIT=1800 ... run_tests.sh`): 2518 tests in 213 scripts, all passing.

**Documents changed:** `docs/hud-and-menus.md` (Content, "Tutorial clips (T-483)"). No game script or scene was changed; nothing under `game/data/levels/` was touched. Open for the board's playtest: the rooftop's textured art makes the ramp clip look busier than the plain grid; the clips' frame rates (16.7 against 25) are a size trade-off.

