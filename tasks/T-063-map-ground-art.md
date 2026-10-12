---
id: T-063
title: Art: the first ground tile, a stretch of asphalt road (PixelLab)
status: in-progress
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-019, T-097]
documents_affected: [game/README.md]
files_to_read_first: [art-archive/README.md, tasks/T-101-car-sprites-remaining-directions.md, tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-003-pixellab-test-generation.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/level-design.md, tasks/T-019-build-mvp-map.md]
files_expected_to_change: [a ground tile PNG and its record under game/art/, a mock-up image, the PixelLab generation log, game/README.md]
model: sonnet
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

**Scoped down by the board (2026-10-12): one road tile first,** as with the car (T-014). The rest of the ground set and putting it into the map moved to T-103, which waits for the board's review of this tile.

Generate **one** ground tile with PixelLab: a plain stretch of **asphalt road** for the MVP map, as Visual style, Decisions ("Ground") describes it, with the board's answers of 2026-10-12:
- asphalt with a **white** lane line (dashed or solid is your proposal; say which and why);
- **light cracks** from the disaster, nothing heavier;
- no zebra crossing and no pavement on this tile (they come with the full set in T-103), unless the tile you propose needs a pavement edge to read as a road; then say so.

**Fit the game:** drawn for the game's 2:1 isometric view (the projection the map and the car use: `game/README.md`) at about 40 pixels per unit, like the car (`game/art/car/car_iso.png`), and under the night palette (Visual style, Decisions). Roads are 24 units wide (Level design, Decisions), so one tile will be a piece of road, repeated: propose the tile's size in units and pixels and how it repeats along the road, and say so in the result notes. Show it next to the car at the same scale (a mock-up image is enough) so the board can judge the scale.

**PixelLab:** re-check the API docs first (https://www.pixellab.ai/llms.txt, https://api.pixellab.ai/v2/openapi.json) and pick the endpoint that best makes one isometric ground tile at this size (T-003 tried `/create-isometric-tile`; read its notes); say why. Use `game/tools/pixellab_client.py` with a long HTTP timeout, record every call with its prompt, settings and cost, and check the balance before and after. **One round only:** don't regenerate; report problems. If one call returns several images, keep them all for the board to choose from. Anything not chosen goes to `art-archive/T-063/` with its record (Visual style, Decisions); delete nothing.

**Don't put it into the map yet:** save it under `game/art/` without changing any scene or script. T-103 does the swap.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The tile is a PNG under `game/art/`, and the result notes give its size in units and pixels and how it repeats along a road (QA: pass / fail)
- [ ] A check script shows it follows Visual style's technical rules: no semi-transparent pixels, about 30 colours or fewer, and a transparent background outside the tile's shape (QA: pass / fail)
- [ ] A mock-up image shows the tile repeated as a road with the final car on it at the game's scale (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass / fail)
- [ ] `git diff master...HEAD` shows no change to scenes or game scripts (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the road tile's look (asphalt, the white line, the light cracks, the scale next to the car); one round only, so problems are reported rather than regenerated.
Board review files: the tile PNG under `game/art/` and the mock-up image.

## Result notes

Written by the agent when it finishes.
