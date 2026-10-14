---
id: T-101
title: Full pixel-art car sprites: the other 15 directions, and swap them in (PixelLab)
status: done
from: project-lead
to: asset-generation
lead:
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-014]
documents_affected: [game/README.md]
files_to_read_first: [art-archive/README.md, tasks/README.md, docs/visual-style.md, docs/drifting.md, tasks/T-013-placeholder-car-sprites.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/extended-narrative.md]
files_expected_to_change: [the car sprite sheets and their record files, the PixelLab generation log, game/README.md]
model: opus
qa_rounds: 2
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**The board approved T-014's first sprite and asked for this task (2026-10-12):** the other 15 directions, put into the actual game so the board can playtest the car in a run. Split from T-014.

**What T-014 learned (read its result notes and board review):**
- The approved sprite is `game/art/car/car_sw_front.png` (frame 4 of T-013's isometric layout), shadow included. Every other frame must match it: the same car, colours, stripes and size, and a shadow drawn the same way, falling the same way on screen in every direction, so the car looks consistent as it turns.
- PixelLab draws a shadow under isometric cars even with "no shadow" in the prompt; don't fight it, match it.
- `create-image-pixflux`'s `direction` is a loose guide; check every frame's real heading on screen against T-013's frame angles (`car_iso.json`) and say in the result notes how close each is.
- Slow calls: use a long HTTP timeout (T-014 used 600 s); a timed-out call is still charged.
- **Archive rule** (Visual style, Decisions, 2026-10-12): every generation that is not used goes to `art-archive/T-101/` with its record; nothing generated is deleted.
- The board has approved the generations this task needs. Plan the calls first, write the plan and its expected cost in the result notes before calling, and keep to one round: don't regenerate frames you don't like; report them.

The car's look and technical style: Visual style, Decisions ("The car" and the technical rules), as T-014 used them.

This art task swaps its sprites in for the placeholders itself (`tasks/README.md`, "Art replaces placeholders"): the drift prototype must show the final car.

The final pixel-art car, drawn 3 times as long as it is wide (Drifting, Decisions), in **16 directions**, 22.5 degrees apart, replacing the placeholder sheets from T-013. It must use exactly T-013's layout and JSON convention, so the drift prototype picks it up with no code change.

**What PixelLab can do** (checked by the Project Lead on 2026-10-07 in https://www.pixellab.ai/llms.txt and https://api.pixellab.ai/v2/openapi.json; re-check before starting, the API changes):

- **No tool makes 16 directions in one call.** The built-in rotation tools stop at 8 (south, south-east, east, north-east, north, north-west, west, south-west).
- **Step 1, 8 directions:** `POST /create-8-direction-object` (20 to 40 generations per call; sizes 24 to 168 pixels; views "low top-down", "high top-down" or "side"; accepts a `style_image` or `style_object_id` to keep a consistent look), or `POST /generate-8-rotations-v3` from one reference frame (up to 256 pixels).
- **Step 2, the 8 in-between directions:** `POST /rotate` turns an existing sprite by `direction_change` degrees (whole numbers, -180 to 180), has an `isometric` option, and takes 16, 32, 64 or 128 pixel images. Rotate each of the 8 directions by 22 or 23 degrees; the half-degree rounding is not visible. Check that every in-between frame keeps the car's identity, colours and size.
- Use the existing client, `game/tools/pixellab_client.py`, and record every call as for T-003.

**Budget:** the board's account is on Tier 2 "Pixel Artisan" with 5,000 generations a month (checked 2026-10-07). Check the balance before and after, and report the cost of each call. One round of generation only, as for every asset: do not regenerate; report problems instead. The board judges the result.

Start from T-014's approved sprite: build the other 15 directions from it, so every frame keeps the same car, colours and size.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] The isometric sheet has 16 frames of 128 by 128 pixels, 22.5 degrees apart, in T-013's exact layout and JSON convention, including T-014's sprite in its frame, and Godot imports it (QA: pass)
- [x] A check script shows every frame follows Visual style's technical rules: transparent background, no semi-transparent pixels, about 30 colours or fewer (QA: pass)
- [x] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass)
- [x] A screenshot of the drift prototype in the isometric view shows the final car, with no change to the driving code (QA: pass)
- [x] In a run started from the main menu (`game.tscn`), the car is the final art at the right size (about 3 units long, matching its collisions), and screenshots of it driving in several directions show the frames match the car's heading (QA: pass)
- [ ] Every unused generation is in `art-archive/T-101/` with its record, and `art-archive/README.md` lists it (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest the car in a run and judge its look in all 16 directions; one round only, so problems are reported rather than regenerated.
Board review files: the final car sheet under `game/art/`.

## Result notes

Written by the agent when it finishes.

**Asset Generation Agent, 2026-10-12**

### Plan (written before any PixelLab call)

API re-checked today (https://api.pixellab.ai/v2/llms.txt, https://www.pixellab.ai/llms.txt, https://api.pixellab.ai/v2/openapi.json, and the docs pages for Rotate, Rotating a character and Create 8-directional sprite (Pro)). Still no 16-direction tool; the 8-direction tools give south, south-west, west, north-west, north, north-east, east, south-east.

**Direction mapping.** PixelLab's 8 compass directions in the isometric view are 45 degrees apart in world heading, so they are T-013's even frames: south-east = frame 0, south = 2, south-west = 4 (T-014's approved sprite), west = 6, north-west = 8, north = 10, north-east = 12, east = 14. The odd frames are the in-betweens.

**Calls (9 in all, one round):**

1. `POST /generate-8-rotations-v3` (async; listed first under Rotate, so PixelLab's default; takes one reference frame up to 256 pixels and keeps its size), once: `first_frame` = the approved `game/art/car/car_sw_front.png`, `no_background: true`, `description` = T-014's car description without the direction words. Gives the 8 even frames. Its south-west image is not used (frame 4 stays the approved original) and goes to the archive. Cost: not published for v3; the Pro 8-rotation tool costs 25 generations at this size, so I expect about 20 to 40 generations.
2. `POST /rotate` (direct), 8 times, one per even frame (frame 4 from the approved original, the others from step 1's images): `direction_change: 22`, the same sign every time, `isometric: true`, `from_view`/`to_view: high top-down` (the API's default is "side"), `from_direction` = the source's compass direction, `image_guidance_scale: 7.5`, and `color_image` = the approved sprite, which forces its palette (about 30 colours, the same greens and whites). The sign convention of `direction_change` is not documented; with one sign for all 8, the 8 results cover all 8 odd frames whichever way it turns, and I place each by its measured heading. Expected cost: about 1 generation each.

Expected total: about 30 to 50 generations from 4996. The client (`game/tools/pixellab_client.py`) gained `/rotate` and `/generate-8-rotations-v3` (multi-image results, each image saved with its own record; poll limit 20 minutes for that job), HTTP timeout 600 s, with tests. No regeneration: frames that come out wrong are reported, not redone.

### What was done

**Calls made (9, one round, no regeneration; all in `game/art/pixellab-generation-log.jsonl`, each with its record JSON next to its image):**

| # | Endpoint | Input | Settings | Result | Cost |
|---|---|---|---|---|---|
| 1 | `/generate-8-rotations-v3` | `first_frame` = `car_sw_front.png` | `no_background: true`; description: T-014's car text without the direction words, plus "isometric pixel art game sprite, same camera and same size in every direction" (full text in the records) | 8 images, 128 x 128, in the order south-west, south, south-east, east, north-east, north, north-west, west (the response has no labels; I read the order from the pictures) | 2 generations |
| 2 to 9 | `/rotate` (8 calls) | `from_image` = frame 4 (the original), then frames 0, 2, 6, 8, 10, 12, 14 | `direction_change: 22`, `isometric: true`, `from_view`/`to_view: high top-down`, `from_direction` = the source's compass direction, `to_direction: null`, `image_guidance_scale: 7.5`, `color_image` = `car_sw_front.png`; no prompt (the endpoint has none) | one 128 x 128 image each; +22 turned the car clockwise on screen, so each gives the next (odd) frame | 1 generation each |

**Cost and balance:** 10 generations ($0.00, subscription), less than the 30 to 50 planned (v3 cost 2, not 20 to 40). Balance before **4996** of 5000, after **4986** of 5000 (checked twice).

**Files:** sources in `game/art/car/frames/` (7 v3 images and 8 rotations, with records); the sheet `game/art/car/car_iso.png` + `car_iso.json` (built by `game/tools/build_car_sheet.py`); `car_sw_front.png` unchanged and used as frame 4. **Archived:** `art-archive/T-101/car_rot8_v3_0.png` (+ `.json`), v3's redraw of the south-west direction, not used because frame 4 is the approved original; listed in `art-archive/README.md`. Nothing deleted.

**Processing (no generation, no new pixels), so the sheet meets the technical rules:** the rotations came back with 210 to 272 colours each and the v3 images with 49 each (the forced palette of `/rotate` did not hold). `build_car_sheet.py` maps every opaque pixel to the nearest colour (CIELAB) of the approved sprite's own 33-colour palette, and moves each frame by whole pixels (at most 4) so its bounding-box centre sits where the approved sprite's does. Side by side at 2x I could not see a difference from the raw frames; the raw PixelLab frames stay in `game/art/car/frames/` for comparison. If the board prefers the raw colours, that is a change to this script, not a new generation.

**Layout:** T-013's convention (one row of 16 frames, frame 0 = heading 0, clockwise, `frame = posmod(roundi(rotation / 22.5 deg), 16)`), with this sheet's own values: frame 128 x 128, `center_px` (64.5, 65.5) (the approved sprite's bounding-box centre), `px_per_unit` 32, `placeholder: false`, the palette, and per frame its source, the colours before and after, the move, the ideal screen angle and the angle I see.

**In the game:** `scripts/driving/car_sprite.gd` now points its `"iso"` sheet at `res://art/car/car_iso` (a path change only; it reads the JSON as before). The run (`game.tscn`, Start) and the drift prototype both start in the isometric view, so both show the final car; the flat view keeps the placeholder (Visual style). No change to the driving code (`car.gd`, `car_model.gd`, `run.gd`, `drift_prototype.gd` untouched). The sprite is drawn at scale 0.5 (16 world px per unit / 32), so the car is about 3 units long: the screenshots with the 3 x 1 footprint drawn over them show the car covering about the footprint's length in most directions (a little shorter in the side views, frames 6 and 14). Note: at the default camera zoom (14.4) one sprite pixel is about 0.7 screen pixels, so the art is shown a little below its native size and a few thin lines drop out; at zoom 10 it is about 1:1.

### Heading of every frame (the board judges)

Nose angle on screen, in degrees clockwise from screen right. "Ideal" is the game's 2:1 projection (`car_iso.json`); "seen" is my estimate from the pictures (about plus or minus 5 degrees). PixelLab draws its isometric diagonals flatter than 2:1 (the approved frame 4 too), so most frames are 5 to 15 degrees off.

| Frame | Heading | Ideal | Seen | Source | Note |
|---|---|---|---|---|---|
| 0 | 0 | 27 | 25 | v3 (south-east) | |
| 1 | 22.5 | 50 | 70 | rotate of 0 | **about 20 off**, points almost straight down |
| 2 | 45 | 90 | 90 | v3 (south) | |
| 3 | 67.5 | 130 | 120 | rotate of 2 | 10 off |
| 4 | 90 | 153 | 163 | approved original | 10 off (as in T-014) |
| 5 | 112.5 | 168 | 170 | rotate of 4 | |
| 6 | 135 | 180 | 170 | v3 (west) | 10 off, nose slightly down |
| 7 | 157.5 | 192 | 182 | rotate of 6 | 10 off, side view, nose left |
| 8 | 180 | 207 | 200 | v3 (north-west) | |
| 9 | 202.5 | 230 | 218 | rotate of 8 | 12 off |
| 10 | 225 | 270 | 260 | v3 (north) | 10 off, tilted left |
| 11 | 247.5 | 310 | 270 | rotate of 10 | **about 40 off: the car points straight up, almost the same heading as frame 10** (the rotation barely turned it) |
| 12 | 270 | 333 | 320 | v3 (north-east) | 13 off |
| 13 | 292.5 | 348 | 343 | rotate of 12 | |
| 14 | 315 | 0 | 0 | v3 (east) | flat side view |
| 15 | 337.5 | 12 | 17 | rotate of 14 | |

### Look of the frames (not a judgement; problems reported, not regenerated)

- **Frames 1 and 11** are the worst for heading (above). Frame 11 is a straight rear view, so when the car turns from frame 10 through 11 to 12 it seems to pause and then jump.
- **Side views 6, 7 and 14** look lower and flatter than the approved high top-down frame 4 (v3 chose a lower camera for west and east); frame 7 has a broken white line along its side and a dented-looking roof.
- **Shadow:** every frame has a dark opaque shadow under it, as frame 4 does, but it does not always fall the same way: mostly down and to the right of the car, smaller in the side views (6, 7, 14) and longer under the front in frames 1 and 3.
- **Colours and stripes:** the same palette in every frame; two white stripes with a green gap show in every frame, clearly in the front and rear views (2, 10, 11), while in the side views they read as one white band over the roof. The v3 frames' pinkish rear window was mapped to frame 4's lavender.
- **On the dark grid** of the drift prototype the car's near-black outline and shadow blend into the background; on the run's gravel the car stands out.

### Checks

- **Rules** (`python game/tools/check_sprite_rules.py game/art/car/car_iso.png --frames 16`): all 16 frames are 128 x 128, with transparent corners and 0 semi-transparent pixels. Colours per frame: 31, 31, 30, 29, 33, 30, 27, 32, 29, 32, 30, 32, 31, 30, 27, 31, all from the approved sprite's 33-colour palette. With the default limit of 30, the frames with 31 to 33 print FAIL on that line only (the approved frame 4 has 33, judged "about 30" in T-014); with `--max-colors 33` every frame passes.
- **Godot imports** the sheet. GUT `test_car_final_sheet.gd` checks the size, the layout JSON, frame 4 identical to `car_sw_front.png` in its visible pixels, no semi-transparent pixels, only the approved palette, and that the run and the drift prototype use it at scale 0.5 with the car's drawing 3 units long.
- **Tests:** full GUT suite `bash game/tools/run_tests.sh`: 300/300 passed (TESTS PASSED; the one warning, "Ignoring Inner Class TestRoom", was there before). Python: `python -m unittest discover -s game/tools -p "test_*.py"` 86 OK; `-s tools` 75 OK. Line-ending-only `.import` changes from the Godot runs were not committed.

**Screenshots** (git-ignored, in this task's folder, `screenshots/T-101/`): the run started from the main menu (`game.tscn`, Start, the car turned to each heading and driving forward with W): `run_frame00.png` to `run_frame15.png` (one per frame), `run_all16_grid.png` (the 16 cars cropped and enlarged 2x) and `run_all16_grid_overlay.png` (the same with the driving direction in red, the 3 x 1 unit drawing footprint in yellow and the 1 x 1 physics body in cyan); the drift prototype in the isometric view: `drift_prototype_iso.png` (400 frames) and `drift_prototype_iso_200.png` (200 frames). New fixture: `tests/fixtures/car_art_from_menu_demo.tscn` (heading from `CAR_HEADING_DEG`).

**Files created:** `game/art/car/car_iso.png` (+ `.import`), `car_iso.json`, `game/art/car/frames/` (15 PNGs with records and `.import` files), `art-archive/T-101/car_rot8_v3_0.png` + `.json`, `game/tools/build_car_sheet.py`, `game/tools/test_build_car_sheet.py`, `game/tests/unit/test_car_final_sheet.gd` (+ `.uid`), `game/tests/fixtures/car_art_from_menu_demo.gd` (+ `.uid`) and `.tscn`. **Changed:** `game/scripts/driving/car_sprite.gd` (iso sheet path and comment), `game/tests/unit/test_drift_prototype.gd` (iso path and scale), `game/tools/pixellab_client.py` and its tests, `game/tools/check_sprite_rules.py` (`--frames`) and its tests, `game/art/pixellab-generation-log.jsonl`, `game/README.md`, `art-archive/README.md`, `agent-notes/asset-generation.md`, this task file.

**Documents affected:** `game/README.md` (new section "The final car sheet (T-101)", the PixelLab client's endpoints, the T-014 section, the layout and pixel-scale notes) and `art-archive/README.md`. No game area doc changed.

### QA round 1

**QA/Integration Agent, 2026-10-12. Result: six criteria pass, one fails (the archive rule). Status stays `in-qa` for the Project Lead.** No PixelLab calls made. Checked on branch `task/T-101-car-directions` at b5c4e84.

1. **Sheet, layout, import: pass.** `game/art/car/car_iso.png` is 2048 x 128, one row of 16 frames of 128 x 128. `car_iso.json` uses T-013's keys and convention (columns 16, `frame0_heading_deg` 0, the same `frame_from_rotation` formula, 22.5-degree steps, `nose_screen_angle_deg` per frame as in the placeholder), with this sheet's own size, centre and `px_per_unit` 32. Frame 4 cropped from the sheet is byte-identical in all RGBA bytes to `game/art/car/car_sw_front.png` (QA's own Pillow check), and `car_sw_front.png` is unchanged from master. Godot imports it (`.import` committed, GUT `test_sheet_is_16_frames_of_128_and_imports` passes, and the game loads `res://art/car/car_iso.png` in QA's runs).
2. **Technical rules: pass.** QA ran `python game/tools/check_sprite_rules.py game/art/car/car_iso.png --frames 16`: every frame 128 x 128, transparent corners, 0 semi-transparent pixels. Colours per frame 27 to 33 (eight frames print FAIL on the colour line only, at 31 to 33 against the script's limit of 30). Judged as T-014 did: the approved frame 4 has 33 and was judged "about 30", and every frame uses only that sprite's 33-colour palette (GUT checks this), so all are within "about 30".
3. **Record: pass.** `game/art/pixellab-generation-log.jsonl` has 9 new T-101 lines: 1 `/generate-8-rotations-v3` (2 generations) and 8 `/rotate` (1 each), 10 generations in all. Each image has a record JSON with the full request settings (`direction_change` 22, views, `from_direction`, `isometric`, `image_guidance_scale`, `color_image`), the prompt (v3's description; `/rotate` has no prompt field, recorded as empty) and usage. Balance before 4996 and after 4986 are in the result notes (consistent with 10 generations; not re-verifiable without a PixelLab call, as in T-014). One round, no regeneration.
4. **Drift prototype, no driving code change: pass.** QA's own screenshot (`drift_prototype.tscn`, 120 frames, isometric view by default) shows the final green car with white stripes. `git diff master...HEAD -- game/scripts game/scenes` changes only `game/scripts/driving/car_sprite.gd`, and only the iso sheet path and a comment; `car.gd`, `car_model.gd`, `run.gd`, `drift_prototype.gd` and every scene are untouched.
5. **Run from the main menu, size and heading: pass.** QA's own screenshots with the fixture (`game.tscn`, Start pressed, car turned and driving forward) at headings 0, 45, 90, 157.5, 247.5 and 315: each uses `res://art/car/car_iso.png` at scale 0.5 and picks frames 0, 2, 4, 7, 11, 14; the car's nose points the way the car drives in each, broadly (down-right, down, down-left, left, up, right). Size: 96 px drawing length x 0.5 = 48 world px = 3 units at 16 px per unit (GUT asserts this), and the agent's overlay screenshot shows the car covering its 3 x 1 footprint in every direction, a little shorter in the side views. The heading errors the agent reports (frame 11 about 40 degrees, frame 1 about 20) are visible and are for the board's review.
6. **Archive: FAIL.** `art-archive/T-101/` holds only v3's unused south-west image, and the README lists it. But the agent left the 15 raw PixelLab generations (7 v3 images and 8 rotations, with records and Godot `.import` files) in `game/art/car/frames/`. The game does not use them (only the processed `car_iso.png` is loaded; the only reference is `build_car_sheet.py`'s source path), and they are not game-ready: QA's check script finds 210 to 272 colours in each rotation and 49 in each v3 image, against the rule's "about 30". Visual style, Decisions (2026-10-12) says `game/art/` holds only clean, game-ready art and every other generation is archived in `art-archive/<task>/` with its record. Suggested fix (no new generation): move `game/art/car/frames/*.png` and `*.json` to `art-archive/T-101/` (drop their `.import` files, as T-014 did), point `build_car_sheet.py`'s source folder and the `source` paths in `car_iso.json` at the archive (outside `game/`, so Godot won't import them; the sheet's pixels need not change), add the 15 files to the table in `art-archive/README.md`, and update `game/README.md` where it mentions the folder.
7. **Tests: pass.** Full GUT suite `bash game/tools/run_tests.sh`: 300/300 passing, TESTS PASSED (1 known warning). Python: `game/tools` 86 tests OK, `tools` 75 tests OK. Line-ending-only `.import` changes from the Godot runs were left uncommitted.

For the board's review later (not QA failures): the heading errors in frames 1 and 11, the flatter side views (6, 7, 14), and shadows that don't fall the same way in every frame, all reported by the agent and visible in QA's screenshots.

### Archive fix after QA round 1 (Asset Generation Agent, 2026-10-12)

No PixelLab calls (balance unchanged at 4986). With `git mv` (nothing deleted), the 15 raw PixelLab frames and their record JSONs moved from `game/art/car/frames/` to `art-archive/T-101/frames/`, and their Godot `.import` files were removed (`git rm`; they are generated). `game/art/car/` now holds only game-ready art: `car_sw_front.png` and `car_iso.png` with their JSON and `.import` files. `build_car_sheet.py` reads its sources from `art-archive/T-101/frames/`, and the `source` paths in `car_iso.json` point there. Rebuilding gives a byte-identical `car_iso.png` (sha256 `0eb4d158...0e9e` before and after); only the 15 `source` lines of `car_iso.json` changed. `art-archive/README.md` lists all 15 files: what each one is, that it is the raw source the sheet was built from, and its original path. `game/README.md` ("The final car sheet (T-101)") now points at the archive. The earlier notes above that say `game/art/car/frames/` describe the state before this fix.

Tests: full GUT suite 300/300 (TESTS PASSED); Python `game/tools` 86 OK, `tools` 75 OK. Documents affected: `game/README.md` and `art-archive/README.md`.


### QA round 2

**QA/Integration Agent, 2026-10-12. Result: all criteria pass. Status set to `needs-playtest`.** No PixelLab calls made. Checked on branch `task/T-101-car-directions` at b4c7db9. Only the archive criterion failed in round 1, so round 2 rechecks it and re-runs everything that could have been affected.

- **Archive criterion: PASS.** `art-archive/T-101/` holds `car_rot8_v3_0.png` (+ json) and `frames/` with the other 15 raw PNGs, each with its json record. `art-archive/README.md` has 16 T-101 rows covering them all. `game/art/` holds only `car/` (`car_iso`, `car_sw_front`, with json), `placeholders/`, and `pixellab-generation-log.jsonl`. `git log --diff-filter=D --name-only master..HEAD` lists only 15 `game/art/car/frames/*.png.import` files (generated Godot files). The raw frames show as 100% renames (nothing altered or deleted).
- **Sheet unchanged: PASS.** `car_iso.png` is identical to commit db72f6f. Re-running `build_car_sheet.py` from the archive gives a byte-identical file (same sha256, prefix `0eb4d158`). Only the 15 `source` paths in `car_iso.json` differ from round 1.
- **Nothing references the archive: PASS.** No `.gd`, `.tscn`, `.tres` or `project.godot` in `game/` mentions `art-archive`; only the build script's source path does.
- **Run from the main menu: PASS.** `game.tscn` shows the main menu; the Start path (fixture `car_art_from_menu_demo`) shows the run with the final pixel-art car from `car_iso.png` (frame 4 at heading 90).
- **Tests: PASS.** Full GUT suite 300/300 (31 scripts, TESTS PASSED). `tools` Python tests 75 OK. `game/tools` Python tests OK.
- Round 1 results for the other six criteria are unchanged (no art, code or test changes since).

Line-ending-only changes to `.import` files and `project.godot` made by running Godot were discarded, not committed.

### Board review

The board played the car in a run on 2026-10-12: 'i really like the look of the car.' Approved as is, including the frames with heading errors. The board wants 32 directions at some point (T-102, T-103).
