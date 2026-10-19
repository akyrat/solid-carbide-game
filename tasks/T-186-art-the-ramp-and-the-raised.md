---
id: T-186
title: Art: the ramp and the raised platform for the elevation test scene (PixelLab)
status: done
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

PixelLab art for the elevation test scene's raised platform and its ramp, replacing the script-drawn placeholders from the test scene task. Built in the board's goal run: the goal is the board's go for PixelLab, up to its art cap of 20 generations; no sample review; one round, no regeneration (docs/working-with-the-board.md, 'Goal runs' and 'Art and money').

1. Before any call, write the planned PixelLab calls and their cost in this task's result notes (within 20 generations). Use a long HTTP timeout (600 s).
2. Make the platform (its top surface and its visible drop-off side faces, in the city's asphalt/concrete look from the map's ground art) and the ramp, in the isometric view matching the platform's and ramp's sizes in `game/data/level/elevation_test.json`.
3. Follow Visual style, Decisions: 32 art px per unit drawn at scale 0.5, hard pixel edges, no semi-transparent pixels, about 30 colours or fewer per sprite (check with `tools/check_sprite_rules.py`), transparent background, no Redgull red. Free script fixes (palette reduction, cleanup) come before anything paid.
4. Game-ready images go in `game/art/elevation/` with their PixelLab record `.json` files; every other generation goes in `art-archive/<this task's id>/`. Never delete generated art.
5. Swap the art in for the placeholders in the test scene, keeping the depth order with the car.
6. Record in docs/visual-style.md what was made and with how many generations; weak results are noted there and in the result notes, not regenerated.

The board's review: Look at the platform and ramp art in `game/scenes/elevation_test/elevation_test.tscn` and the screenshot in `docs/drifting/`.

## Acceptance criteria

- [ ] The result notes list the planned PixelLab calls and their cost, written before the first call, within the art cap of 20; the number of calls actually made is recorded and is no more than 20. (QA: pass: plan written first, 3 calls made)
- [ ] Game-ready ramp and platform images are in `game/art/elevation/`, each with its PixelLab record `.json`; every other generation is in `art-archive/<this task's id>/`. (QA: pass)
- [ ] `tools/check_sprite_rules.py` (or a test) shows each game image has no semi-transparent pixels, about 30 colours or fewer, a transparent background and no Redgull red, at 32 art px per unit. (QA: pass: build_elevation_art.py check, 29 and 26 colours, all rules pass)
- [ ] The test scene uses the new art instead of the placeholders and still runs headless without errors. (QA: pass: drawing uses Sprite2D from art/elevation; full GUT 1021/1021 passed)
- [ ] A screenshot in `docs/drifting/` shows the car on the platform and in the air beside it with the final art. (QA: pass: elevation-final-art.png and elevation-final-art-platform.png exist; not viewed)
- [ ] docs/visual-style.md records the ramp and platform art: what was made and with how many generations. (QA: pass: entry at line 56)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-19, Blocked → In progress

Goal runner (G-003): started, in C:\solid-carbide-worktrees\T-186.

### 2026-10-19, In progress → In QA

Goal runner (G-003): the agent is done; QA is checking it.

### 2026-10-19, In QA → Needs playtest

Goal runner (G-003): QA passed; merged into playtest/G-003.

## Result notes

### Plan, written before the first PixelLab call

PixelLab's largest image is 400 x 400, but the platform is 1024 x 608 art px and the ramp 640 x 416 (16 x 16 and 12 x 8 units at 32 art px per unit), so PixelLab makes the **surface textures** and a script (`game/tools/build_elevation_art.py`) projects them exactly onto the isometric faces of `elevation_test.json`'s platform and ramp (same projection as the placeholder drawing: screen = ((x - y), (x + y) / 2) x 32, heights lifted 32 px per unit). Planned calls (all `create-image-pixflux`, 128 x 128, 600 s timeout, one round, no regeneration), 3 of the cap of 20:

1. Platform top: seamless-looking cracked grey concrete / asphalt slab, top-down (1 generation).
2. Drop-off side wall: grey concrete retaining wall with panel seams and a lighter lip at the top (1 generation).
3. Ramp surface: dark asphalt with white lane markings / worn chevrons, top-down (1 generation).

Cost: 1 generation each, 3 in all (balance before: 4872 of 5000 subscription generations). Free script steps (projection, outline, palette reduction to 30 colours or fewer) come after.

### Result

- **PixelLab generations made: 3** (cap 20), exactly the planned calls, one round, no regeneration, 600 s timeout. Balance before 4872 of 5000 subscription generations. Raw textures and their records: `art-archive/T-186/raw_platform_top`, `raw_platform_wall`, `raw_ramp_top` (.png and .json); calls also appended to `game/art/pixellab-generation-log.jsonl`.
- **Game-ready:** `game/art/elevation/platform.png` (1024 x 608, 29 colours) and `ramp.png` (640 x 416, 26 colours), each with a record `.json` (sources, `top_left_art_px`). PixelLab's largest image is 400 x 400, so a script (`game/tools/build_elevation_art.py`) projects the textures exactly onto the isometric faces of the platform and ramp in `elevation_test.json` (platform top plus east and south drop-off faces; ramp's sloped top plus its south triangle), with outline, rim light and palette reduction. Free script fix before anything paid: the platform's top was desaturated and darkened.
- **Rules:** `python game/tools/build_elevation_art.py check` and the Python and GUT tests show no semi-transparent pixels, at most 30 colours, transparent corners, no Redgull red. (`tools/check_sprite_rules.py` only takes square frames, so the same four rules are in the build script's `rules()`.)
- **Scene:** `elevation_platform_drawing.gd` now shows the art as a `Sprite2D` (scale 0.5, nearest) instead of drawing the placeholder; geometry and depth order unchanged; headless tests pass: `test_elevation_art.gd` (6 new), `test_elevation_drawing.gd` (19), `test_elevation_edges.gd` (14), and `test_build_elevation_art.py` (4). I did not run the whole suite.
- **Screenshots:** `docs/drifting/elevation-final-art.png` (car at the platform's edge, in the air, with the ramp's start) and `elevation-final-art-platform.png` (car on the platform, ramp beside it).
- **Weak results (not regenerated):** the top texture is blue cobblestone with bright vignette blobs, mirrored, so a repeating pattern rather than plain concrete/asphalt; the ramp is purple with white arrows, not the street's grey asphalt; the wall reads as brick. The geometry, scale and depth order are right. The board judges the look in the final playtest; a regeneration of the textures (3 more generations) and a rebuild would fix it cheaply.
- Documents changed: `docs/visual-style.md`, `game/README.md`.
- Refusals: one. `python -c "import PIL"` (a check that Pillow exists) needed an approval I could not get; I skipped it, since `reduce_palette.py` already uses Pillow, and the build ran fine.
- 2026-10-19, in-qa → needs-playtest: QA passed every criterion (goal G-003).
- 2026-10-19, needs-playtest → done: Board's playtest of G-003 (2026-10-19): super happy with it.
