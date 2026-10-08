---
id: T-014
title: Full pixel-art car sprites in 16 directions (PixelLab)
status: blocked
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-013]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/drifting.md, tasks/T-013-placeholder-car-sprites.md, game/README.md, docs/extended-narrative.md]
files_expected_to_change: [the car sprite sheets and their record files]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until:** T-013 is done (it fixes the sheet layout this art must match), **and** the board has described what the car looks like (Visual style, Open questions). The technical style is decided (Visual style, Decisions): 128 by 128 pixel frames, about 40 pixels per unit, selective dark outline, detailed shading, high detail, about 30 colours, and the isometric view only. The Project Lead adds the description here and unblocks the task.

The final pixel-art car, drawn 3 times as long as it is wide (Drifting, Decisions), in **16 directions**, 22.5 degrees apart, replacing the placeholder sheets from T-013. It must use exactly T-013's layout and JSON convention, so the drift prototype picks it up with no code change.

**What PixelLab can do** (checked by the Project Lead on 2026-10-07 in https://www.pixellab.ai/llms.txt and https://api.pixellab.ai/v2/openapi.json; re-check before starting, the API changes):

- **No tool makes 16 directions in one call.** The built-in rotation tools stop at 8 (south, south-east, east, north-east, north, north-west, west, south-west).
- **Step 1, 8 directions:** `POST /create-8-direction-object` (20 to 40 generations per call; sizes 24 to 168 pixels; views "low top-down", "high top-down" or "side"; accepts a `style_image` or `style_object_id` to keep a consistent look), or `POST /generate-8-rotations-v3` from one reference frame (up to 256 pixels).
- **Step 2, the 8 in-between directions:** `POST /rotate` turns an existing sprite by `direction_change` degrees (whole numbers, -180 to 180), has an `isometric` option, and takes 16, 32, 64 or 128 pixel images. Rotate each of the 8 directions by 22 or 23 degrees; the half-degree rounding is not visible. Check that every in-between frame keeps the car's identity, colours and size.
- Use the existing client, `game/tools/pixellab_client.py`, and record every call as for T-003.

**Budget:** the board's account is on Tier 2 "Pixel Artisan" with 5,000 generations a month (checked 2026-10-07). Check the balance before and after, and report the cost of each call. One round of generation only, as for every asset: do not regenerate; report problems instead. The board judges the result.

## Acceptance criteria

To be finalised when the board's description is in. They will cover: 16 frames per required view in T-013's exact layout and JSON convention, Godot imports them, every call recorded with its cost, balance before and after, and, if the drift prototype (T-012) is done by then, a screenshot of it showing the new sheets with no code change.

## Result notes

Written by the agent when it finishes.
