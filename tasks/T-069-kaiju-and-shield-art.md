---
id: T-069
title: Art: the kaiju
status: done
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-045]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-003-pixellab-test-generation.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/enemies.md, tasks/T-045-kaiju.md]
files_expected_to_change: [art files under game/art/ and their records, the scenes that used the placeholders, game/README.md]
model: sonnet
qa_rounds: 1
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

**Blocked until T-045 (the kaiju, with placeholders) is done.**

The kaiju, as Visual style, Decisions describes it: a giant Godzilla-style monster several times the car's size, never a copy of Godzilla. Propose its size, directions and walk frames. Swap it in for T-045's placeholder. It has no shield in the MVP (Enemies, Decisions, 2026-10-11); the shield moved to T-099, after the MVP.

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. Real-world things are inspiration only: no real logos, no copies of existing characters. Details the docs leave open (directions, frame counts, variants, sizes) are this agent's proposal, written in the result notes for the board to judge (Visual style, Decisions).

Use the existing client, `game/tools/pixellab_client.py`. Record every call with its prompt, settings and cost, and the balance before and after. One round of generation only: don't regenerate; report problems instead. The board judges the result.

This art task swaps its art in for the placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass; check_sprite_rules.py --size 224 --frames 6 on all five kaiju sheets: ALL FRAMES PASS, 0 semi-transparent, 30 colours)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass; log has 7 rows (sample + 6 calls) with prompts, settings, usage, balances noted; one round, no regeneration; overrun: 32 for the set against the 6 to 12 planned, explained by canvas-size cost)
- [ ] A screenshot shows the final kaiju in a run (QA: pass; screenshots/kaiju_walking.png shows the new kaiju sprite beside the car in a run with HUD)
- [ ] T-045's tests still pass (QA: pass; full GUT suite passes, kaiju tests included)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass; GUT 1194/1194 in 385 s with GUT_TIME_LIMIT=900; tools 414 tests OK (458 s); game/tools 358 tests OK, 1 skipped)

The board's review: judge the look. One round only, so problems are reported rather than regenerated.

## Updates

### 2026-10-21, Open → In progress

Started at the board's request, in C:\solid-carbide-worktrees$t.

### 2026-10-21, In progress → In QA

Kaiju sample in (1 generation). Good palette and detail, but side-on rather than isometric, toy-like joints, and very close to Godzilla itself. Pictures: C:\solid-carbide-worktrees\T-069\art-archive\T-069\review_kaiju_se_dark.png

### 2026-10-21, In progress

Sample approved by the board. Started: the full kaiju set from the sample, then swapped into the game.

### 2026-10-21, In progress → In QA

Full kaiju set built and swapped in (8 directions, 6 walk frames). Cost 32 generations against about 6 to 12 planned. Sent to QA.

### 2026-10-21, In QA → Needs playtest

QA passed all 5. Ready for the board: C:\solid-carbide-worktrees\T-069\game\project.godot or Play on T-069 in the Builds tab; the kaiju arrives late in the run (or watch kaiju_walking.gif).

### 2026-10-21, Needs playtest → Done

The board approved the kaiju. Merged into master.

## Result notes

### Sample round (2026-10-21, board's go for T-069's generations)

**Planned call and cost (written before calling):** one `/create-image-pixflux` call, 224x224, `view: high top-down`, `isometric: true`, `direction: south-east`, `no_background: true`, selective outline, detailed shading, highly detailed, seed 69001; expected cost 1 generation. Prompt and settings: `art-archive/T-069/kaiju_se_sample_req.json` (record: `kaiju_se_sample.json`; log row in `game/art/pixellab-generation-log.jsonl`). Balance before: 4860 of 5000 generations (USD credit 0). Balance after: the account still showed 4860.0 right after the call (the counter may lag); the call reported usage of 1 generation. One call only, no regeneration.

**Proposal for the board (mine, nothing in the docs):**
- Size: 7 units tall, as T-045's placeholder (224 art pixels at 32 px per unit; canvas 224x224), about 2.3 car lengths tall. Against the elevation sample map: skyscrapers are drawn 15 units high, so it is shorter than the towers but taller than a rooftop's height of 6 units; from the street it stands about as high as a second-floor rooftop, so it will not loom over rooftops. If the board wants that, 9 units (288 px) is the next size up.
- Directions: 8, like the minion (5 drawn, 3 mirrored), built from this sample with the minion's recipe (rotate, then animate).
- Walk frames: 6 per direction (a slow, heavy stride), so about 30 drawn frames plus 18 mirrored.

**Judgment of the sample (honest):** it reads as a Godzilla-style kaiju: dark green hide, big pale cyan dorsal plates, yellow eyes, teeth, curled tail, in the night palette, with a selective outline and shading; 20 colours, no semi-transparent pixels. It is not a copy of the film monster. Problems: (1) PixelLab ignored `no_background` at this canvas size and returned an opaque speckled grey background; I removed it by a free flood-fill script and kept the raw (`kaiju_se_sample_clean.png`); the walk frames may have the same fault. (2) The view is a front three-quarter, upright pose, not a clean isometric one: it faces the camera and the right, the tail curls up on the left instead of lying along the isometric ground axes like the car, so it may look a little out of place beside the isometric buildings. (3) The limbs look like segmented shiny balls, somewhat toy-like, and the mid-stride is not clear. (4) The sprite fills the canvas almost to its edges (x 13 to 211, y 18 to 206), leaving no room for more tail or glow. No glow is drawn into the pixels yet.

### Full set (board approved the sample, 2026-10-21): plan before calling

Same recipe as the minion (T-068), from the approved sample's cleaned copy (`kaiju_se_sample_clean.png`, 224x224) as the reference. Planned calls, one at a time, 600 s HTTP timeout, no regeneration:
- Call A: `/generate-8-rotations-v3` from the sample (seed 69002), `no_background`. Estimated 1 generation (the minion's and the car's cost 1 to 2).
- Calls B1 to B5: `/animate-with-text-v3`, one per drawn direction (south, south-east, east, north-east, north), first frame the matching rotation, `frame_count` 6 (the endpoint takes even counts and returns the first frame plus the requested count; I use the first 6), seed 69003, `no_background`. Estimated 1 generation each, 5 in all.
- Total: 6 calls, about 6 generations (up to about 12 if the larger canvas costs more). If an endpoint refuses 224x224, that is reported and I do not pay for a workaround. The three mirrored directions (south-west, west, north-west) are made in the game, free. Backgrounds removed by free script where PixelLab ignores `no_background`. Requests are built by `art-archive/T-069/make_req.py`.
- Balance before the set: 4860 of 5000 generations.

### Full set: what was done (2026-10-21)

**Calls (6, one at a time, one round, no regeneration, 600 s HTTP timeout; params `art-archive/T-069/rot_req.json`, `walk_<dir>_req.json`, built by `make_req.py`; records and the log in `game/art/pixellab-generation-log.jsonl`):**
- A: `/generate-8-rotations-v3` from `kaiju_se_sample_clean.png`, seed 69002: the record says **7 generations** (my estimate of 1 was wrong: the cost grows with the 224x224 canvas). Files `art-archive/T-069/rotations/kaiju_rot8_0..7.png`, already transparent. Order from the pictures: 0 south-east (the sample), 1 east, 2 north-east, 3 north, 4 north-west, 5 west, 6 south-west, 7 south.
- B1 to B5: `/animate-with-text-v3`, `frame_count` 6, seed 69003, action "a heavy, slow kaiju stride ...", first frame the rotation of the direction: east (1), south (7), south-east (0), north-east (2), north (3). Each returned 7 frames (the first frame plus 6; the first 6 are used). The record says **5 generations each**, 25 in all. Files `art-archive/T-069/walk_<dir>/`, transparent.
- **Total by the records: 32 generations** (planned about 6 to 12: more than planned, because the large canvas costs more; the board's go covers the task, and I did not stop mid-way since each call was within the go and I had no way to ask). Balance (shared account): before the set 4857; after call A 4848; after E 4841; after S 4834; after SE 4829; after NE 4824; after N 4819 (the 4857 to 4819 drop of 38 includes other sessions' spending; the account read 4804 later, not mine). The sample's own balance note above said 4860 before; the account read 4857 when the set started.

**Free script work:** `game/tools/build_kaiju_sheets.py` builds the five game sheets `game/art/kaiju/kaiju_{s,se,e,ne,n}.png` (6 frames of 224x224, 1344x224) from the first 6 frames of each walk; the raw frames had 31 to 48 colours per direction, so each sheet gets one shared palette of at most 30 colours with `reduce_palette.py` (every colour already in the art, no new pixels; the raw frames stay in the archive). Check script `game/tools/check_sprite_rules.py --size 224 --frames 6` on all five sheets: all frames pass (transparent corners, 0 semi-transparent pixels, 30 colours). PixelLab gave a transparent background this time for the rotations and the walks (only the single sample had the grey one).

**In the game (behaviour unchanged):** `game/scripts/enemies/kaiju_sprite.gd` draws the sheets instead of the placeholder, 8 directions from the way it walks (south-west, west and north-west mirrored), 6 frames from the same walk cycle as the placeholder's stomp (0.9 cycles a second), feet on the ground point, the ground shadow kept, drawn at scale 0.5 so the canvas is 7 units. The placeholder drawing stays as the fallback if a sheet is missing. `drawn_height_px()` now returns the art's visible height (93 screen pixels, so the health bar sits on the head); `drawn_width_px()` is unchanged. Nothing else in the kaiju's code changed: collision, speed, attacks and health are the same. `game/README.md`, "The kaiju", is updated.

**Tests:** new `game/tests/unit/enemies/test_kaiju_sprite.gd` (direction, mirroring, frame choice, the five sheets 6 x 224, size, facing) and `game/tools/test_build_kaiju_sheets.py`. `bash game/tools/run_tests.sh` (with `GUT_TIME_LIMIT=900`: the full suite takes about 306 s, the default limit of 300 s stops it): 98 scripts, 1194 of 1194 pass (T-045's kaiju tests included). `python -m unittest discover -s tools -p "test_*.py"`: OK. `python -m unittest discover -s game/tools -p "test_*.py"`: 358 tests, OK (1 skipped, as before). `.import` line-ending noise reverted; the five new `game/art/kaiju/*.import` files are committed like the other art's.

**Screenshots and recording** in `art-archive/T-069/screenshots/`: `kaiju_demo.png` (the kaiju beside the car and minions, T-045's fixture), `kaiju_walking.png`, `kaiju_walk_first.png`, `kaiju_walk_middle.png`, `kaiju_walk_last.png` and `kaiju_walking.gif` (50 frames at 12 a second: it walks in toward the parked car in a run from the main menu; fixture `tests/fixtures/kaiju_walk_demo.tscn`), `kaiju_on_ramp.png` (T-207's elevation fixture, the kaiju is not in this shot: it is a street view only). Review sheets: `art-archive/T-069/review_walk_all_dark.png` (all 5 directions x 6 frames), `review_rotations.png`.

**Honest judgment of the set:** it keeps the approved sample's look in every direction (same palette, plates and proportions), reads clearly as the same big monster in the run and is clearly bigger than the car. Weaknesses: (1) The walk is subtle: the stride is a small leg and tail change from frame to frame, more a stomping sway than a clear step, and some frames show a leg in an odd pose (south and north-east frames 4 and 5). (2) Consistency between directions is good but not perfect: the tail curl, the plates and the belly vary a little from direction to direction; the back view (north) has an odd dark mark where the tail meets the body. (3) As in the sample it is more a front three-quarter figure than a strict isometric one, and the joints are shiny and ball-like. (4) The palette cut to 30 colours flattened some shading. (5) Mirroring makes the south-west, west and north-west views the right-hand ones flipped, so the tail curls on the other side. (6) The sprite is 93 screen pixels tall from feet to head, shorter than the 7-unit canvas (112), and about the height of a rooftop of 6 units on screen; if the board wants it to loom, the next size up costs a whole new set. (7) The kaiju on the elevation sample map's ramps was not recorded: the existing T-207 kaiju fixture frames the street, so only the flat ground is shown. Problems are reported, not regenerated.

**Refused commands:** none this round (the earlier inline Python edit of this file was refused; see above).

**Files:** `art-archive/T-069/kaiju_se_sample.png` (raw), `kaiju_se_sample_clean.png` (transparent), review images `review_kaiju_se_dark.png` and `review_kaiju_se_light.png` (3x nearest-neighbour, the car's first frame beside it for scale). Nothing is swapped into the game yet. Refused command: an inline Python edit of this file was refused by the status hook, so I made this edit with the Edit tool instead.
- 2026-10-21, in-progress → in-qa: Kaiju sample ready for the board alone, no QA agent
- 2026-10-21, in-qa → in-progress: the board took it out of QA with 5 acceptance criteria not marked
- 2026-10-21, needs-playtest → done: Board: 69 looks good
