---
id: T-101
title: Full pixel-art car sprites: the other 15 directions, and swap them in (PixelLab)
status: in-progress
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-014]
documents_affected: [game/README.md]
files_to_read_first: [art-archive/README.md, tasks/README.md, docs/visual-style.md, docs/drifting.md, tasks/T-013-placeholder-car-sprites.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/extended-narrative.md]
files_expected_to_change: [the car sprite sheets and their record files, the PixelLab generation log, game/README.md]
model: opus
qa_rounds: 0
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

- [ ] The isometric sheet has 16 frames of 128 by 128 pixels, 22.5 degrees apart, in T-013's exact layout and JSON convention, including T-014's sprite in its frame, and Godot imports it (QA: pass / fail)
- [ ] A check script shows every frame follows Visual style's technical rules: transparent background, no semi-transparent pixels, about 30 colours or fewer (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass / fail)
- [ ] A screenshot of the drift prototype in the isometric view shows the final car, with no change to the driving code (QA: pass / fail)
- [ ] In a run started from the main menu (`game.tscn`), the car is the final art at the right size (about 3 units long, matching its collisions), and screenshots of it driving in several directions show the frames match the car's heading (QA: pass / fail)
- [ ] Every unused generation is in `art-archive/T-101/` with its record, and `art-archive/README.md` lists it (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest the car in a run and judge its look in all 16 directions; one round only, so problems are reported rather than regenerated.
Board review files: the final car sheet under `game/art/`.

## Result notes

Written by the agent when it finishes.
