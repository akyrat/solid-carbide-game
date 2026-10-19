---
id: T-196
title: Elevation sample map: the drive-only scene (the MVP map's city with rooftops and ramps, placeholder drawing)
status: blocked
from: project-lead
to: level-challenge
lead: Goal-G-004
epic: level-challenges
milestone: mvp
goal: G-004
user_facing_text: no
changes_visuals: yes
depends_on: [T-194]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/scripts/driving/elevation_test.gd, game/scripts/level/mvp_map.gd, game/scripts/level/elevation_platform_drawing.gd, game/scripts/driving/car_shadow.gd, game/scripts/driving/camera_follow.gd, game/data/level/elevation_sample_map.json, game/tests/fixtures/elevation_test_demo.gd]
files_expected_to_change: [game/scenes/elevation_sample/elevation_sample_map.tscn, game/scripts/level/elevation_sample_map.gd, game/scripts/level/mvp_map.gd, game/tests/unit/test_elevation_sample_map.gd, game/tests/fixtures/elevation_sample_demo.gd, game/tests/fixtures/elevation_sample_*.tscn, game/README.md, docs/level-design.md]
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

Level design, Decisions, 'Elevation sample map' (board, 2026-10-19): a drive-only sample map, like the elevation test scene but city-sized. No enemies, weapons, run timer, likes, levels or HUD: the car just drives around freely.

Build a new scene (game/scenes/elevation_sample/elevation_sample_map.tscn) that loads game/data/level/elevation_sample_map.json (D2) and shows, in the isometric view:
- the MVP map's ground art, buildings (see-through as on the MVP map), boulders and edge walls, from mvp_map.gd. Give mvp_map.gd a way to load another layout file (for example a layout_path set before it is added to the tree), keeping the MVP map's default, so the MVP run is unchanged;
- every raised area and ramp from the file, drawn with elevation_platform_drawing.gd's script drawing as the placeholder (the art comes in a later ticket);
- the car with its final sprite lifted by its height, its round shadow on the ground under it (car_shadow.gd), and the car's real height on the sample map's ground (car_height.gd via GroundHeight);
- the camera following as in the elevation test scene (camera_follow.gd, the saved zoom and camera options).
W/A/S/D drive the car, as in the elevation test scene. Pick a start point on the street near a 0-to-3 ramp's foot, facing it (a proposal).

Depth order: reuse the elevation test scene's approach for the areas and the map's for the buildings so the scene is playable; the full depth order across many areas and buildings is the next ticket (D5), so don't spend long on edge cases here.

How the board opens it is an open question the docs don't answer. Propose the same as the elevation test scene: open the scene in the editor and press F6, or the run command in game/README.md; no main menu button (a button would need its text from the Narrative Theme Agent, in a new ticket). List it as an open question in the result notes.

Screenshots with the screenshot tool (game/README.md, 'Taking a screenshot'), from fixtures like the elevation test's: the car on the street, on a 0-to-3 ramp, on a 3-to-6 ramp, on height 3, on height 6, and in the air with its shadow below; in art-archive/<task id>/screenshots/.

The board's review: Drive the elevation sample map (placeholder drawing for rooftops and ramps), in the goal's final playtest.

## Acceptance criteria

- [ ] game/scenes/elevation_sample/elevation_sample_map.tscn loads game/data/level/elevation_sample_map.json, and a test checks the scene has the ground, the buildings, the boulders, one drawing per raised area and ramp in the file, the car's sprite, and the car's shadow. (QA: pass / fail)
- [ ] A test checks the scene tree has no enemies, minions, kaiju, weapons, run timer, likes, levels or HUD run-state nodes (no run.gd, hud.gd, weapons.gd, minion_spawner.gd or kaiju nodes). (QA: pass / fail)
- [ ] A test places the car on a height-3 area and on a height-6 area: the car's sprite is lifted by its height and the shadow sits on the area's top under the car. (QA: pass / fail)
- [ ] The scene runs headless for 10 seconds with no errors in the output; the run command is in game/README.md. (QA: pass / fail)
- [ ] The MVP run is unchanged: test_mvp_map.gd, test_run_scene.gd and test_screen_flow.gd pass, and a run started from the main menu loads mvp_map.json. (QA: pass / fail)
- [ ] Screenshots exist in art-archive/<task id>/screenshots/ showing the car on the street, on a 0-to-3 ramp, on a 3-to-6 ramp, on height 3, on height 6, and in the air with its shadow below, and they are listed in the result notes and on the Board review files line. (QA: pass / fail)
- [ ] game/README.md and docs/level-design.md describe the scene, how to open it (the proposal) and what it shows; the result notes list how the board opens it as an open question. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
