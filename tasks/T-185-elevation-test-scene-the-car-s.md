---
id: T-185
title: Elevation test scene: the car's drawing lifts with its height, a shadow on the ground, placeholder platform and ramp
status: in-qa
from: project-lead
to: driving-drift
lead: Goal-G-003
epic: driving
milestone: mvp
goal: G-003
user_facing_text: no
changes_visuals: yes
depends_on: [T-182, T-183, T-184]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/scripts/driving/drift_prototype.gd, game/scripts/driving/car_sprite.gd, game/scripts/driving/car.gd, game/scripts/driving/car_height.gd, game/scripts/level/ground_height.gd, game/scripts/enemies/enemy_depth.gd]
files_expected_to_change: [game/scenes/elevation_test/elevation_test.tscn, game/scripts/driving/elevation_test.gd, game/scripts/driving/car_shadow.gd, game/scripts/level/elevation_platform_drawing.gd, game/scripts/driving/car_sprite.gd, game/tests/unit/test_elevation_drawing.gd, game/tests/fixtures/elevation_test_*.tscn, game/tests/fixtures/elevation_test_demo.gd, docs/drifting/elevation-*.png, docs/drifting.md, game/README.md]
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

docs/drifting.md, Decisions, 'Elevation': built first in a test scene, the way the drift prototype was, not in the real map. The illusion of height in this 2D game: the car's drawing lifts up the screen with its height while its shadow stays on the ground.

1. A new test scene, `game/scenes/elevation_test/elevation_test.tscn`, built like the drift prototype (the same car, camera and isometric view, W/A/S/D), with the platform and ramp from `game/data/level/elevation_test.json` and the car's height from the elevation tasks. It is not the project's main scene and is not reachable from the main menu. No new on-screen text (no labels or readouts the player reads).
2. In the isometric view, the car's drawing is offset up the screen by its height, at 16 px per unit as the rest of the drawing. A shadow (script-drawn, dark, no semi-transparent pixels or a whole-object fade only, no Redgull red) is drawn at the car's map position on the ground under it: on the platform's top when over the platform, on the ground otherwise.
3. The platform and the ramp are drawn with script-drawn placeholders (flat-coloured isometric top faces and visible side faces, no Redgull red), in depth order with the car: the car on the ground behind the platform is drawn under it, the car on the platform or above it over it.
4. A test checks the drawing's offset for a known height (for example height 1 unit = 16 px up the screen).
5. Screenshots from the running scene (fixtures in `game/tests/fixtures/`, taken with `game/tools/screenshot.sh`), saved in `docs/drifting/`: the car on the ground, on the ramp, on the platform, and in the air past a drop-off edge, each with its shadow.
6. docs/drifting.md, Content, gets an 'Elevation test scene' section: where the scene is, how to run it, what the car's height does (summing up the elevation tasks), and every proposed number marked as a proposal. game/README.md, 'Elevation test scene': the scene's path, how to run it and the drawing's main functions.

The board's review: Play `game/scenes/elevation_test/elevation_test.tscn`: drive up the ramp, along the platform and off its edges, and judge the lift, the shadow, the jumps and the landings.

## Acceptance criteria

- [ ] `game/scenes/elevation_test/elevation_test.tscn` runs headless for a few seconds without errors or warnings in the log. (QA: pass: no direct headless run, as the godot command isn't pre-approved; the GUT test instantiates the scene and runs 50 physics frames, and the full suite log shows it clean)
- [ ] GUT test: in the isometric view the car's drawing is offset up the screen by height x 16 px for a known height, and the shadow is drawn at the car's map position on the ground under it (the platform's top when over it). (QA: pass: test_elevation_drawing.gd lift and shadow tests pass)
- [ ] The platform and the ramp are drawn with script-drawn placeholders containing no Redgull red (checked by script on the colours used). (QA: pass: colour tests in test_elevation_drawing.gd pass)
- [ ] GUT test or screenshot: depth order is right: the car on the ground behind the platform is drawn under it, the car on the platform over it. (QA: pass: depth-order tests pass)
- [ ] Four screenshots in `docs/drifting/` show the car on the ground, on the ramp, on the platform and in the air past a drop-off edge, each with its shadow visible. (QA: pass: the four files plus the extra are in docs/drifting/; not viewed pixel by pixel)
- [ ] docs/drifting.md, Content, has an 'Elevation test scene' section (where the scene is, how to run it, what the car's height does, proposals marked) and game/README.md has the scene's path and how to run it. (QA: pass: both sections present)
- [ ] The full GUT suite passes headless. (QA: pass: 1015/1015)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-19, Blocked → In progress

Goal runner (G-003): started, in C:\solid-carbide-worktrees\T-185.

### 2026-10-19, In progress → In QA

Goal runner (G-003): the agent is done; QA is checking it.

## Result notes

Driving & Drift Agent, 2026-10-19.

**What was built**
- `game/scenes/elevation_test/elevation_test.tscn` with `game/scripts/driving/elevation_test.gd`: the drift prototype's car (`car.gd`, unchanged), camera (`camera_follow.gd`, saved zoom and options) and isometric view, W/A/S/D, on the platform and ramp from `game/data/level/elevation_test.json` (the `GroundHeight` is the car's `ground`, so T-183/T-184's height and sides apply). Not the main scene, not reachable from any menu, no on-screen text (no hint label, no tuning panel, no pause screen). The car starts at (26, 0) facing west, so W drives straight up the ramp (proposal).
- The lift: `car_sprite.gd` gets `lift_for_height(h)` = (0, -h x 16) and `place(drawn_ground_px, h)`; the lift is in the sprite's position, so physics interpolation smooths it.
- The shadow: `game/scripts/driving/car_shadow.gd`, one opaque dark colour (no semi-transparent pixels, not red), the car's footprint turned with it (3.2 x 1.2 units, proposal), at the car's map position lifted by the ground's height under it (platform top, ramp, or street). It does not change size with height (proposal).
- The placeholders: `game/scripts/level/elevation_platform_drawing.gd`, one node per platform/ramp: flat top face with a unit grid, the visible east and south side faces, light edges. Grey-blue platform, dull sand ramp top (proposals).
- Depth order: an area's `is_behind(centre, radius, height)` (wholly north or west of its rectangle and lower than its top there); `elevation_test.gd`'s `z_for` puts the shadow and the car, each on its own, just under the first area they are behind, otherwise over all. So a car high above the street behind the platform is over the platform while its shadow is under it.
- Camera (proposal): it follows the car's map position at height 0, not the lifted drawing, so jumps show as the car rising on screen.

**Tests:** `game/tests/unit/test_elevation_drawing.gd`, 19 tests: lift 16 px per unit (height 1 = 16 px up, platform = 48 px up), shadow on the street / platform top / ramp, colours opaque and far from Redgull red (`HudScript.HEART_COLOR`, the same check as the drift marks), face shapes, depth order (behind the platform under it, on it over it, in front over it, above-behind over with the shadow under, behind the ramp under the ramp but over the platform), a drive up the ramp where the drawing and shadow follow the height every step through the takeoff, and the scene running 50 physics frames on its own. Full GUT suite: 1015/1015 passed (`bash game/tools/run_tests.sh`). Python tool tests: 282 OK (1 skipped).

**Screenshots** (`game/tests/fixtures/elevation_test_{ground,ramp,platform,air,behind}.tscn` with `elevation_test_demo.gd`, taken with `game/tools/screenshot.sh`), in `docs/drifting/`:
- `C:\solid-carbide-worktrees\T-185\docs\drifting\elevation-ground.png`: on the street in front of the platform, shadow around the car.
- `C:\solid-carbide-worktrees\T-185\docs\drifting\elevation-ramp.png`: on the ramp, height 1.46, shadow on the ramp.
- `C:\solid-carbide-worktrees\T-185\docs\drifting\elevation-platform.png`: on the platform, height 3, shadow on the top.
- `C:\solid-carbide-worktrees\T-185\docs\drifting\elevation-air.png`: in the air past the platform's south edge, shadow on the street well below the car.
- `C:\solid-carbide-worktrees\T-185\docs\drifting\elevation-behind.png` (extra): on the street behind the platform, only the roof shows over the platform's edge (depth order).
They are in `docs/drifting/` as the Description asks, not also in `art-archive/T-185/screenshots/`.

**For the board's playtest:** a car behind the 3-unit platform is hidden by it (last screenshot); the map's buildings have a see-through effect for this, the test scene does not. Every number and colour here is a proposal.

**Not done here:** the headless run of the scene itself (`"$GODOT_BIN" --headless ...`) is not among the pre-approved commands, so I didn't run it; the GUT test instantiates the scene and runs it for 50 physics frames headless with no errors, and the screenshot runs logged no errors or warnings. No refusals met. PixelLab: none used.

**Documents updated:** `docs/drifting.md` (Content, new "Elevation test scene" section), `game/README.md` ("Elevation test scene (T-182)" intro, "The car's height (T-183)" pointer, new "The scene and its drawing (T-185)").
