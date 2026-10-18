---
id: T-157
title: "Art: real-depth trick frames with PixelLab's rotation tools (sample: one direction)"
status: cancelled
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: final-release
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/drifting.md, docs/working-with-the-board.md, tasks/T-153-side-flip-art.md, tasks/T-155-trick-prototype-jumps-and-new-tricks.md, game/README.md, game/tools/pixellab_client.py, game/art/car/car_iso.json]
files_expected_to_change: [new frames under game/art/car/ and their records, art-archive/T-157/, the trick prototype's roll sheets, game/tools/pixellab_client.py (new endpoints only), docs/visual-style.md, game/README.md]
model: opus
qa_rounds: 1
---

## Description

The board found the trick art flat: T-153's roll (made with `/animate-with-text-v3`) and the code roll both look like a 2D image being flipped ("Paper Mario"), with no depth or sense of physics. The board wants the tricks done with full generated art instead of the code stand-in (Drifting, Decisions, 2026-10-17), using PixelLab's rotation tools.

What the API offers (checked 2026-10-17 in https://api.pixellab.ai/v2/openapi.json):
- `/rotate` (1 generation per call): from a reference sprite, change its facing (`direction_change` in degrees, or `from_direction`/`to_direction`) and its camera view (`view_change`, "how many degrees to tilt the subject", or `from_view`/`to_view` among side, low top-down, high top-down), with `isometric`, `init_image` and a forced palette (`color_image`). The client already supports it (T-101).
- `/generate-8-rotations-v3`: turntable rotations around the vertical axis (how the car's 16 directions were made, T-101).
- `/interpolation-v2`: in-between frames from a start and an end key image, with an `action` text and a target palette. Add it to the client if you use it.
- Nothing rolls an object around its own long axis directly. Combine the tools: for example, key poses made with `/rotate` (tilted, on its side, showing the underside) and in-betweens made with `/interpolation-v2`. Script fixes (palette, alignment, cleanup) are free and come first.

**Sample first** (`docs/working-with-the-board.md`, "Art and money"): one direction only, the car's start direction (car sheet frame 12, nose up-right), for:
1. **The side roll**: a full roll to the car's right around its long axis, with real depth (the car's side, then its underside and wheels, then the other side). The left flip plays it in reverse (T-155).
2. **The nose pop**: the car dips onto its nose, then pitches nose-up through the flip and lands (T-155's nose launch). The tilt in `/rotate` is the likely tool here.

About 8 frames each, 128x128, transparent, the car's palette and size, no shadow (the game draws it), each centred like T-153's sheet so there is no pop.

**PixelLab go (board, 2026-10-17):** "scratch the current way, i want to do it with the full art". This ticket is the sample round only, capped at **15 generations** in all. Plan first: write every planned call (endpoint, settings, cost) in the result notes and commit them before calling. Use a 600 s HTTP timeout and record every call with its prompt, settings and cost, and the balance before and after. One round: if a result is weak, report it honestly with a picture; don't regenerate beyond the plan. Never delete generated art: raw output in `art-archive/T-157/`, game-ready frames in `game/art/car/`. The full set (all 16 directions) is a separate ticket after the board approves the sample.

Generation starts now from `master`. The Project Lead merges T-155's branch into this one once T-155 is in QA, and tells you; then drop the frames into the trick prototype the way T-153 did (roll sheet for direction 12; T-155 says how the nose pop takes its sheet) and check them in the scene.

## Acceptance criteria

- [ ] The result notes list every planned call and its cost, committed before the first call; the record lists every call with prompt, settings, cost and balance before and after; the total is at most 15 generations. (QA: pass) -- plan committed 02:07:22 UTC (e4d9e3d), first call 02:07:29; 15 /rotate calls logged, 1 generation each; settings in raw/*.json and requests/, balance 4896 to 4881 in notes
- [ ] Game-ready frames for the side roll and the nose pop (direction 12, about 8 each, transparent, the car's palette and size) are in `game/art/car/` with records; raw output is in `art-archive/T-157/`. (QA: pass) -- car_roll3d_ne_0..7, car_nose_ne_0..5 with json, sheets car_roll3d.png (9 frames) and car_nose.png (7), RGBA 128 px; 30 raw files in art-archive/T-157/raw
- [ ] Enlarged previews on a dark and a light background are in `art-archive/T-157/`. (QA: pass) -- review_roll/nose_dark.png and _light.png present (plus motion gifs)
- [ ] In the trick prototype, the right flip, the left flip (reversed) and the nose launch use the new frames in direction 12 (test or scripted screenshots). (QA: pass) -- test_trick_art_frames.gd passes (right 0..8, left 0,8..1, nose launch); screenshots right/left/nose_in_scene.png present
- [ ] `docs/visual-style.md` and `game/README.md` record the frames and the method. All three test sets pass. (QA: pass) -- visual-style.md, game/README.md updated; GUT 905/904 (only the accepted test_screen_flow main-scene failure), game/tools 293 OK, tools 182 OK

The board's review: judge the sample frames, then the tricks in the trick prototype (one playtest build with T-155 and T-156).
Board review files: art-archive/T-157/ previews (listed in the result notes).

## Updates

### 2026-10-17, Open → In progress

Started: the Asset Generation Agent plans a sample in one direction (side roll and nose pop) with PixelLab's rotation tools, capped at 15 generations, writing the planned calls and cost before calling.

### 2026-10-17, In progress

Sample made: 15 generations (cap reached), side roll and nose pop for the start direction. Honest read: the nose pop has real depth in most frames; the side roll is inconsistent (the car loses its look in the middle frames and will likely flicker). Now going into the playtest build so you can judge it in motion.

### 2026-10-17, In QA

Frames are in the trick prototype for all three tricks (start direction) and in the playtest build: open C:\solid-carbide-worktrees\playtest-tricks\game\project.godot and press Play. QA is checking the criteria now.

### 2026-10-17, Needs playtest

QA passed all 5 criteria. Waiting for your playtest and your pick for the roll art (script fix, script 3D drawings, or ~4 more generations).

## Result notes

### Plan before calling PixelLab (Asset Generation Agent, 2026-10-17)

**Why T-153's roll looked flat:** `/animate-with-text-v3` was given only a start frame and words, so the model invented the motion; it tumbled and turned the car on screen instead of rolling it around its long axis, and it never showed a consistent 3D side, underside and other side. PixelLab has no tool that rolls an object around its own axis, so this round gives the model the geometry instead of asking for it.

**Method:** `game/tools/render_trick_guides.py` (free, tested) builds a simple 3D model of the car (body box, fastback cabin, eight-sided wheels, stripes, dark underside with axles, tail lights) and draws it with a depth buffer in an isometric orthographic camera fitted to `car_iso.png` frame 12 (45 degrees elevation, so the upright guide's box is within 1 px of the sprite's), rolled or pitched by any angle, in the car's palette. Each guide is a physically correct pose (the side, the underside, the other side as they would really turn towards the camera). Each PixelLab call is `/rotate` with `from_image` = the real car (frame 12, the look) and `init_image` = the guide (the pose), no turn and no view change, so the model paints the real car onto a pose it could not reach on its own. Guides: `art-archive/T-157/guides/`, sheets `art-archive/T-157/guides_roll_sheet.png`, `guides_nose_sheet.png`. Request bodies: `art-archive/T-157/requests/` (written by `game/tools/trick_frame_requests.py`). `/interpolation-v2` is not used: its cost is not published and it is the same text-driven kind of model that went flat in T-153; known-cost `/rotate` on every frame keeps the 15 cap safe.

**Calls (all `/rotate`, 128 x 128, 1 generation each, seeds 157001 to 157015, `image_guidance_scale` 4.0, from/to `north-east`, `high top-down`, `isometric` true, `color_image` = frame 12):**

| # | Name | Guide | init_image_strength |
|---|------|-------|---------------------|
| 1 | roll_080_s300 | roll 80 degrees | 300 (probe) |
| 2 | roll_080_s600 | roll 80 degrees | 600 (probe) |
| 3-9 | roll_040, 120, 160, 200, 240, 280, 320 | roll 40 to 320 in 40-degree steps | the better probe value (450 if neither is clearly better) |
| 10-15 | pitch_340, 045, 090, 135, 180, 270 | nose dip 20 degrees, then nose up 45, 90, 135, 180, 270 | the same value |

- The side roll: frame 12 upright, then 8 rolled frames 40 degrees apart (9 even steps of a full roll to the right). The left flip plays them reversed.
- The nose pop: the dip, then 5 pitched frames of a backflip, back to upright frame 12 (7 frames with the upright one; 225 and 315 are left out to stay within the cap and are the fastest part of the flip).
- **Checkpoint:** if calls 1 and 2 both show that `/rotate` ignores the guide (the car comes back upright), stop after call 2 and report (2 generations spent) instead of spending the other 13.
- **Total: 15 generations at most** (the cap). Balance before planning: 4896 of 5000. HTTP timeout 600 s (the client's). No retries; weak frames are reported, not regenerated.
- Free steps afterwards (script): palette mapped to the car's 33 colours, semi-transparent pixels cut, each frame centred by whole pixels on the car's centre (64.5, 65.5), dark and light enlarged previews.

### Phase one result (generation only; no swap-in, status not moved)

**Call record:** 15 calls, all `/rotate`, all charged 1 generation (15 in all, the cap). Balance 4896 before, 4881 after (checked twice; the first check lagged by one). Each call's request body is in `art-archive/T-157/requests/<name>.json`, its output and full record (settings, seed, usage, resources consulted) in `art-archive/T-157/raw/<name>.png` / `.json`, and every call is in `game/art/pixellab-generation-log.jsonl` (2026-10-17 02:07 to 02:11 UTC). No prompt (`/rotate` takes none); no retries, no errors.

| # | Name | init_image_strength | Seed | Result |
|---|------|---------------------|------|--------|
| 1 | roll_080_s300 | 300 | 157001 | ignored the guide: the car came back upright |
| 2 | roll_080_s600 | 600 | 157002 | copied the guide almost exactly (boxy, the model's look lost) |
| 3 | roll_040 | 450 | 157003 | twisted car, half rolled, stripes kept |
| 4 | roll_120 | 450 | 157004 | weak: reads as an upright car seen from the front, not 120 degrees over |
| 5 | roll_160 | 450 | 157005 | mostly underside, some lights on the wrong end |
| 6 | roll_200 | 450 | 157006 | underside, good depth |
| 7 | roll_240 | 450 | 157007 | underside and side, good depth |
| 8 | roll_280 | 450 | 157008 | on its side, underside showing, reads well |
| 9 | roll_320 | 450 | 157009 | nearly upright again, stripes partly back |
| 10 | pitch_340 | 450 | 157010 | nose dip, rear lifted: good |
| 11 | pitch_045 | 450 | 157011 | nose up 45 degrees, roof and stripes towards the camera: good |
| 12 | pitch_090 | 450 | 157012 | standing on its tail: good |
| 13 | pitch_135 | 450 | 157013 | weak: muddled shape |
| 14 | pitch_180 | 450 | 157014 | upside down, underside: good |
| 15 | pitch_270 | 450 | 157015 | standing on its nose: fair |

Calls 1 and 2 were the planned probe: neither was clearly better (300 ignores the pose, 600 ignores the look), so calls 3 to 15 used the planned middle value, 450.

**Game-ready frames (free script, no new pixels):** `python game/tools/build_trick_frames.py` cuts alpha, maps every colour to `car_iso.png`'s own colours (CIELAB; `/rotate` ignored the forced palette, 102 to 200 colours in, 24 to 31 out) and centres each frame by whole pixels on (64.5, 65.5).
- Side roll: `game/art/car/car_roll3d_ne_0.png` to `_7.png` (40 to 320 degrees; frame 1 is call 2, the 600 probe, the only 80-degree frame that is on its side) and `car_roll3d_ne.json`.
- Nose pop: `game/art/car/car_nose_ne_0.png` to `_5.png` (dip, then 45, 90, 135, 180, 270) and `car_nose_ne.json`.
- Play both with `car_iso.png` frame 12 before the first and after the last frame. Not yet in the trick prototype (phase two). T-153's `car_roll_ne_*` frames are not on this branch and are untouched.
- Tests: `game/tools/test_render_trick_guides.py`, `game/tools/test_build_trick_frames.py` (the committed frames match a rebuild). All three test sets pass: GUT all passing, `game/tools` 290 OK, `tools` 182 OK.

**Previews (for the board):** `art-archive/T-157/review_roll_dark.png`, `review_roll_light.png`, `review_nose_dark.png`, `review_nose_light.png` (3x, upright frame 12 at both ends), and in motion `review_roll_motion.gif`, `review_nose_motion.gif`. The pose guides: `art-archive/T-157/guides_roll_sheet.png`, `guides_nose_sheet.png`.

**Honest verdict:** better depth than T-153 in places, but not a clean result. The guided poses work: several frames show a real 3D car (the nose pop's dip, nose-up and standing frames, the underside frames of both tricks) instead of a flat image being flipped. But `/rotate` has no setting that both keeps the car's look and follows the pose: at 450 it keeps the pose only part of the time, so the roll is inconsistent (frame 2 at 120 degrees snaps back to an upright-looking car, frame 1 is the boxy guide, the stripes come and go, and the car turns into a generic dark sports car in the middle frames). In motion the roll will likely flicker rather than roll smoothly. The nose pop is the stronger of the two; its 135-degree frame is weak. Cheapest next steps for the board to choose from: (a) accept the nose pop and hand-fix or drop the weak roll frames (free); (b) use the script's 3D guides themselves, made more detailed, as the trick frames (free, fully consistent, but script-drawn rather than generated); (c) a second paid round only on the weak frames (120, 135, 40, 80) at a strength between 450 and 600, on the board's say-so.
- Documents (`docs/visual-style.md`, `game/README.md`) are updated in phase two with the method the board keeps.

### Phase two result (swap-in; Asset Generation Agent, 2026-10-17)

- **No new PixelLab calls** (total stays 15 generations) and no repainting: the frames are used exactly as built in phase one.
- **Sheets** (built by `python game/tools/build_trick_frames.py`, the drop-in format of T-151/T-153): `game/art/car/car_roll3d.png` + `car_roll3d.json` (9 frames: `car_iso` frame 12, then the 8 roll frames; `roll_deg` listed) and `game/art/car/car_nose.png` + `car_nose.json` (7 frames: frame 12, the dip, then 45, 90, 135, 180, 270; `pitch_deg` listed). `direction_frame` 12, `center_px` (64.5, 65.5), `px_per_unit` 32.
- **Right and left flip:** `TrickPrototype.ROLL_SHEETS` now points at `res://art/car/car_roll3d` instead of T-153's `car_roll` (T-153's files are kept in `game/art/car/`). The right flip plays frames 0 to 8, the left flip 0 then 8 down to 1 (T-155's reverse play, unchanged).
- **Nose launch hook (new, small):** `TrickPrototype.NOSE_SHEETS` (`res://art/car/car_nose`), `TrickFlip.load_nose_sheet()` (as `load_roll_sheet` plus `pitch_deg`; both share `_read_sheet()`), `TrickFlip.nose_frames` and `nose_sequence_frame(pitch_deg)`: upright, the dip frame from halfway through the dip, then in the air the frame with the nearest pitch (the -20-degree dip frame also shows just before landing, nose down), upright for the landing squash. The hop, the tip toward the nose and the landing squash stay; no code pitch, mirror or tint with frames. Other directions and the flat view keep the code-drawn nose launch.
- **Tests:** new `game/tests/unit/test_trick_art_frames.gd` (the scene loads both sheets for direction 12 at the car's size; the right flip shows frames 0..8 in order, the left flip 0, 8..1; the nose launch shows 0, 1, 0, 2, 3, 4, 5, 6, 1, 0 and is never tinted or mirrored; `nose_sequence_frame` phases; `load_nose_sheet` refuses a sheet without `pitch_deg`; other directions keep the code nose launch). `test_trick_jumps.gd::test_nose_launch_drawing` now clears `nose_frames` first (it checks the code-drawn launch, as T-153 did for the code roll). `game/tools/test_build_trick_frames.py` unchanged in scope (frames match a rebuild).
- **In-scene screenshots** (`TRICK_DEMO=right|left|nose bash game/tools/screenshot.sh res://tests/fixtures/trick_jumps_demo.tscn ...`, cropped around the car, 2x): `art-archive/T-157/screenshots/right_in_scene.png`, `left_in_scene.png`, `nose_in_scene.png`. They show the frames playing at the car's place and size in the scene. Seen there: the roll's 80-degree frame (the boxy probe) and the change of look in the middle frames stand out; in the nose pop the 135 and 180-degree frames look a little smaller than the upright car.
- **Test runs:** GUT 905 tests in 79 scripts, 904 passing, 1 failing: `test_screen_flow.gd::test_the_main_scene_is_the_game_flow`, the expected one (the main scene is temporarily the trick prototype on this line; `project.godot` left alone). `game/tools`: 293 OK (1 skipped). `tools`: 182 OK.
- **Documents updated:** `docs/visual-style.md` (method, files, honest read), `game/README.md` ("Trick frames with depth (T-157)"), `art-archive/README.md` (the T-157 rows).
- The board's options after playing (from phase one): (a) keep the nose pop and fix or drop the weak roll frames (free); (b) use more detailed script drawings as the frames (free, consistent, script-drawn); (c) a second paid round on the weak frames only, on the board's say-so.
- 2026-10-19, needs-playtest → cancelled: Board, 2026-10-19: building the trick prototype before an elevation system was a mistake. Not merged; kept as the reference for rebuilding the tricks on real height (Drifting, Content, 'Trick prototype (reference)'); code on the branch hold/trick-prototype, art in art-archive/.
