---
id: T-186
title: Art: the ramp and the raised platform for the elevation test scene (PixelLab)
status: open
from: project-lead
to: asset-generation
lead: Goal-G-003
epic: art
milestone: mvp
goal: G-003
user_facing_text: no
changes_visuals: yes
depends_on: [T-185]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/level-design.md, docs/working-with-the-board.md, game/README.md, game/scripts/level/elevation_platform_drawing.gd, game/data/level/elevation_test.json, tools/check_sprite_rules.py]
files_expected_to_change: [game/art/elevation/*.png, game/art/elevation/*.json, art-archive/<this task's id>/, game/scripts/level/elevation_platform_drawing.gd, game/scenes/elevation_test/elevation_test.tscn, game/tests/unit/test_elevation_art.gd, docs/drifting/elevation-final-art.png, docs/visual-style.md, game/README.md]
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

PixelLab art for the elevation test scene's raised platform and its ramp, replacing the script-drawn placeholders from the test scene task. Built in the board's goal run: the goal is the board's go for PixelLab, up to its art cap of 20 generations; no sample review; one round, no regeneration (docs/working-with-the-board.md, 'Goal runs' and 'Art and money').

1. Before any call, write the planned PixelLab calls and their cost in this task's result notes (within 20 generations). Use a long HTTP timeout (600 s).
2. Make the platform (its top surface and its visible drop-off side faces, in the city's asphalt/concrete look from the map's ground art) and the ramp, in the isometric view matching the platform's and ramp's sizes in `game/data/level/elevation_test.json`.
3. Follow Visual style, Decisions: 32 art px per unit drawn at scale 0.5, hard pixel edges, no semi-transparent pixels, about 30 colours or fewer per sprite (check with `tools/check_sprite_rules.py`), transparent background, no Redgull red. Free script fixes (palette reduction, cleanup) come before anything paid.
4. Game-ready images go in `game/art/elevation/` with their PixelLab record `.json` files; every other generation goes in `art-archive/<this task's id>/`. Never delete generated art.
5. Swap the art in for the placeholders in the test scene, keeping the depth order with the car.
6. Record in docs/visual-style.md what was made and with how many generations; weak results are noted there and in the result notes, not regenerated.

The board's review: Look at the platform and ramp art in `game/scenes/elevation_test/elevation_test.tscn` and the screenshot in `docs/drifting/`.

## Acceptance criteria

- [ ] The result notes list the planned PixelLab calls and their cost, written before the first call, within the art cap of 20; the number of calls actually made is recorded and is no more than 20. (QA: pass / fail)
- [ ] Game-ready ramp and platform images are in `game/art/elevation/`, each with its PixelLab record `.json`; every other generation is in `art-archive/<this task's id>/`. (QA: pass / fail)
- [ ] `tools/check_sprite_rules.py` (or a test) shows each game image has no semi-transparent pixels, about 30 colours or fewer, a transparent background and no Redgull red, at 32 art px per unit. (QA: pass / fail)
- [ ] The test scene uses the new art instead of the placeholders and still runs headless without errors. (QA: pass / fail)
- [ ] A screenshot in `docs/drifting/` shows the car on the platform and in the air beside it with the final art. (QA: pass / fail)
- [ ] docs/visual-style.md records the ramp and platform art: what was made and with how many generations. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
