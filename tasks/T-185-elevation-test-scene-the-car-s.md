---
id: T-185
title: Elevation test scene: the car's drawing lifts with its height, a shadow on the ground, placeholder platform and ramp
status: blocked
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

- [ ] `game/scenes/elevation_test/elevation_test.tscn` runs headless for a few seconds without errors or warnings in the log. (QA: pass / fail)
- [ ] GUT test: in the isometric view the car's drawing is offset up the screen by height x 16 px for a known height, and the shadow is drawn at the car's map position on the ground under it (the platform's top when over it). (QA: pass / fail)
- [ ] The platform and the ramp are drawn with script-drawn placeholders containing no Redgull red (checked by script on the colours used). (QA: pass / fail)
- [ ] GUT test or screenshot: depth order is right: the car on the ground behind the platform is drawn under it, the car on the platform over it. (QA: pass / fail)
- [ ] Four screenshots in `docs/drifting/` show the car on the ground, on the ramp, on the platform and in the air past a drop-off edge, each with its shadow visible. (QA: pass / fail)
- [ ] docs/drifting.md, Content, has an 'Elevation test scene' section (where the scene is, how to run it, what the car's height does, proposals marked) and game/README.md has the scene's path and how to run it. (QA: pass / fail)
- [ ] The full GUT suite passes headless. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
