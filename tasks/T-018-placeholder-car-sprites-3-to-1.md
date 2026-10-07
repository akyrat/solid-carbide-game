---
id: T-018
title: Redraw the placeholder car sprites at 3:1
status: done
from: project-lead
to: asset-generation
epic: art
milestone: mvp
depends_on: [T-013]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, tasks/T-013-placeholder-car-sprites.md, game/README.md]
files_expected_to_change: [the placeholder car sheet generator and its tests, the two placeholder sheets and their JSON files, game/README.md]
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board decided the car is drawn 3 times as long as it is wide (Drifting, Decisions). The placeholder sheets from T-013 are 2:1 (32 by 16 pixels). Redraw them at 3:1 with T-013's generator script, for example 48 by 16 pixels, keeping everything else the same: 16 directions, a flat and an isometric sheet, a single body colour with a distinct nose, no PixelLab.

- Keep T-013's layout convention (frame 0's direction, frame order, the car's centre at the centre of each frame), so code that reads the sheets needs no change. Make the frames as large as the longer car needs in every direction, in both views; if the frame size changes, the JSON files say so.
- The JSON files record the car's drawn size in units as well as pixels: 1 unit wide, 3 units long, so code can scale the sprite to the world.
- Update the script's tests and `game/README.md` ("Placeholder car sprite sheets") to match.

## Acceptance criteria

- [x] Both sheets have exactly 16 frames of equal size, and Godot imports them without errors (QA: pass)
- [x] Looking at both sheets, every frame shows a single-colour rectangle 3 times as long as it is wide (in the flat sheet, measured in pixels; in the isometric sheet, before projection) with a distinct nose, turning steadily from frame to frame as in T-013 (QA: pass)
- [x] The JSON files keep T-013's layout fields and add the car's drawn size in units (1 wide, 3 long) (QA: pass)
- [x] Running the generator twice produces byte-identical sheets (QA: pass)
- [x] The generator's tests, the full GUT suite and all Python tool tests pass (QA: pass)
- [x] No PixelLab call was made: `game/art/pixellab-generation-log.jsonl` is unchanged (QA: pass)
- [x] `game/README.md` describes the 3:1 sheets (QA: pass)

## Result notes

**Asset Generation Agent, 2026-10-07.**

**What changed.** T-013's generator now draws the placeholder car at 3:1: a 48 x 16 pixel rectangle (1 unit wide, 3 units long, 16 pixels per unit) in one solid blue (#2e86ff), with the front 8 pixels in yellow (#ffe600) as the nose, exactly as in T-013. Everything else is the same: 16 directions, a flat and a flat-projected isometric sheet (screen = (x - y, (x + y) / 2), no box height), pixel-centre sampling with no outline or shading, no PixelLab. No PixelLab call (and no API call of any kind) was made: `git diff master -- game/art/pixellab-generation-log.jsonl` is empty.

**New frame size: 80 x 80** (was 64 x 64), so each sheet is 1280 x 80; the car's centre is (40, 40), still the middle of the frame. Why it grew: in the isometric view the 48 x 16 car reaches up to about 35.8 pixels from the centre on screen (sqrt(2) times its half-diagonal of 25.3), which no longer fits in 64. 80 leaves an empty margin all round in every frame of both views (tested). The layout convention is otherwise unchanged: frame 0 = world heading 0 (nose along +x), each next frame +22.5 degrees clockwise on screen, `frame = posmod(roundi(rotation / deg_to_rad(22.5)), 16)` for both views, a `Sprite2D` with `centered = true`, `hframes = 16` and no offset. Code that reads `frame_width`, `frame_height` and `center_px` from the JSON needs no change; code that hard-coded 64 or (32, 32) would. Nothing in the repo reads the sheets yet.

**JSON fields added** (both `car_flat.json` and `car_iso.json`; all T-013 fields kept, with `frame_width`/`frame_height` now 80 and `center_px` now (40, 40)):

- `car_size_units`: `{"width": 1.0, "length": 3.0}`
- `car_size_px`: `{"width": 16.0, "length": 48.0}`
- `px_per_unit`: `16.0`
- `car_size_note`: says this is the drawn size in the flat world before projection, the drawing only (the physics body is in `docs/drifting.md`, Decisions), and how to scale: world size of 1 unit / `px_per_unit`.
- In `record`: `task` now "T-013 (first 2:1 version), T-018 (redrawn at 3:1)", and this task file added to `resources_consulted`. `settings.car_length_px` is now 48.

**How to regenerate** (from the repo root, headless, byte-identical every run):

```
bash game/tools/generate_car_sheets.sh
powershell -ExecutionPolicy Bypass -File game/tools/generate_car_sheets.ps1
```

**Tests** (`game/tests/unit/test_car_sheets.gd`, now 12 tests): the 80 x 80 frame and 1280 x 80 sheet sizes and the imported size; the JSON layout and the new size fields; only body and nose colours, with a nose, in every frame; flat frame 0 is exactly the 48 x 16 rectangle with the nose on the right; new: flat frame 4 is exactly the 16 x 48 rectangle with the nose at the bottom; new: in every frame of both sheets, the drawn pixels un-projected to the flat world measure 48 along the heading and 16 across it (within sampling error) and are centred on (40, 40); new: no frame touches its frame's edges; the nose faces the expected direction in chosen frames; the nose's world heading is i * 22.5 degrees in all frames; the committed files match the generator; two runs give byte-identical PNGs.

**Self-check per criterion:**

1. 16 equal frames, Godot imports without errors: yes. Both PNGs are 1280 x 80 (16 frames of 80 x 80). `--import` printed no errors, both `.ctex` files are in `.godot/imported`, and `test_godot_imports_sheets` passes.
2. Every frame a single-colour 3:1 rectangle with a distinct nose, turning steadily: yes. Looked at both sheets enlarged; each has exactly 3 colours (transparent, body, nose). Measured by the new test in pixels (flat) and before projection (iso). The isometric sheet turns 22.5 degrees per frame in world heading, uneven on screen, as in T-013 (the board kept that).
3. JSON keeps T-013's layout fields and adds the size in units: yes (fields above).
4. Running the generator twice gives byte-identical sheets: yes. sha256 of all six files in `game/art/placeholders/car/` identical before and after a second `bash game/tools/generate_car_sheets.sh`; also the GUT test.
5. Tests pass: GUT TESTS PASSED (5 scripts, 23 tests, 12 in `test_car_sheets.gd`); Python `game/tools`: 45 tests OK; root `tools/`: 42 tests OK.
6. No PixelLab call: confirmed, log unchanged.
7. `game/README.md` describes the 3:1 sheets: yes, "Placeholder car sprite sheets" now gives 48 x 16 (1 by 3 units), 80 x 80 frames, the (40, 40) centre, the new JSON fields and how to scale to the world.

**Files changed:** `game/tools/car_sheet_generator.gd`, `game/tests/unit/test_car_sheets.gd`, `game/art/placeholders/car/car_flat.png`, `car_flat.json`, `car_iso.png`, `car_iso.json` (their `.import` files are unchanged), `game/README.md`, `agent-notes/asset-generation.md` (working notes), this task file. No files created.
**Documents affected:** `game/README.md` (updated).

**Problems.**
- As expected, the worktree's first Godot import rewrote committed `.import` files (GUT addon, test-run art and audio) with LF line endings and no content change; `git add` cleared the false status and nothing was committed for them.
- The frame size changed from 64 to 80, so anything that hard-codes 64 x 64 frames or the (32, 32) centre (for example the drift prototype, if it does not read the JSON) must be updated. Nothing in this repo does today.

### QA round 1

**QA/Integration Agent, 2026-10-07.** Checked from scratch in `C:\solid-carbide-worktrees\T-018`. All 7 criteria pass.

- **Sheets and import:** both PNGs are 1280 x 80 RGBA, so 16 frames of 80 x 80. I deleted the two cached `.ctex` files in `.godot/imported` and ran `--headless --import`: both sheets reimported, exit 0, no errors (only Godot's usual "ObjectDB instances leaked at exit" warning). `test_godot_imports_sheets` passes.
- **Looked at and measured:** I enlarged both sheets and looked at every frame: a blue rectangle with a yellow nose, turning steadily (on screen for the flat sheet; in world heading for the isometric sheet, as in T-013). Each sheet has exactly two colours (#2e86ff, #ffe600). My own script measured every frame. Flat: 768 pixels (48 x 16) with a 128-pixel nose (8 x 16); extent 48 along the heading and 16 across at 0/90/180/270 degrees, 47-48 by 15-16 at the other angles (sampling). Isometric, un-projected with screen = (x - y, (x + y) / 2): 748 to 816 pixels (the projection keeps area), 46.7-48 along and 14.8-16 across, so 3:1 within sampling. Nose direction (body centroid to nose centroid) is i * 22.5 degrees within 0.3 in all 16 frames of both sheets; every frame's centroid is exactly the frame's middle (40, 40); no frame touches its edges.
- **JSON:** compared all keys (nested) of both files with `master`: none of T-013's fields is missing. Added: `car_size_units` (width 1, length 3), `car_size_px` (16, 48), `px_per_unit` 16, `car_size_note`. `frame_width`/`frame_height` 80, `center_px` (40, 40), `frame_count` 16, `frames` has 16 entries; `frame0_heading_deg`, `order`, `step_deg`, `frame_from_rotation` unchanged.
- **Determinism:** `bash game/tools/generate_car_sheets.sh` twice (exit 0 both): sha256 of all six files in `game/art/placeholders/car/` identical before, after run 1 and after run 2; `git status` clean.
- **Tests:** `bash game/tools/run_tests.sh`: TESTS PASSED, 5 scripts, 23/23 tests (12 in `test_car_sheets.gd`), exit 0. `python -m unittest discover -s game/tools -p "test_*.py"`: 45 OK. `python -m unittest discover -s tools`: 42 OK.
- **PixelLab:** `git diff master -- game/art/pixellab-generation-log.jsonl` is empty (log still 2 lines).
- **README:** "Placeholder car sprite sheets" in `game/README.md` gives the 48 x 16 car (1 by 3 units, 16 px per unit), 80 x 80 frames in a 1280 x 80 sheet, centre (40, 40), the new JSON fields and how to scale to the world.

**Observations for the Project Lead.**
- **Frame size 64 -> 80:** frame 0's direction, the frame order, the rotation-to-frame formula and "centre = middle of the frame" are all unchanged, so code that reads `frame_width`/`frame_height`/`center_px` from the JSON, or uses a `Sprite2D` with `centered = true` and `hframes = 16`, needs no change. Code that hard-coded 64 or (32, 32) would. The task explicitly allows the frame size to grow if the JSON says so, which it does, so I read this as consistent with keeping T-013's layout convention. The growth is needed: the isometric car reaches about 35.8 pixels from the centre, more than 64 / 2. Nothing in the repo reads the sheets yet (searched for `car_flat`/`car_iso`).
- The 1 x 3 unit size in the JSON is the drawing only; the README notes the physics body is 1 x 1 unit, so the drawing sticks out past it at the front and back. That matches the master commit "car drawn 3:1 with a 1 by 1 physics body".
- No `.import` files were rewritten by my Godot runs in this worktree; `git status` stayed clean throughout.

### Board review

2026-10-07: the board reviewed the 3:1 sheets and marked the task `done`.
