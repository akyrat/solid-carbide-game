---
id: T-014
title: The first pixel-art car sprite: one direction, front to the bottom-left (PixelLab)
status: in-progress
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-013, T-012]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/drifting.md, tasks/T-013-placeholder-car-sprites.md, game/README.md, docs/extended-narrative.md]
files_expected_to_change: [a car sprite PNG and its record under game/art/, the PixelLab generation log, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Scoped down by the board (2026-10-12): one sprite only, for now.** The board wants to see the first generated car before anything else. The other 15 directions, and swapping the final sheet in for the placeholder, moved to T-101, which waits for the board's review of this sprite.

Generate **one** pixel-art car sprite with PixelLab:

- **The car** (Visual style, Decisions, "The car"): looks like a 1967 Ford Mustang GT fastback, **dark green** as the main colour, with **two white racing stripes** running down the length of the car (bonnet, roof and boot), centred on the car as much as possible, with a **gap of body colour between the two stripes**. No real badges or logos (no Ford, Mustang or Shelby badges). The reference photos are in Visual style, References.
- **The direction:** seen in the game's isometric view, the car lies on the diagonal from the top-right of the screen to the bottom-left, with its **front (nose) at the bottom-left** (facing south-west on screen). Use the isometric projection the game uses (`game/art/placeholders/car/car_iso.json` and `game/README.md`, "Placeholder car sprite sheets") and say in the result notes which frame of T-013's 16-frame layout this sprite matches, so T-101 can build on it.
- **The technical style** (Visual style, Decisions): a 128 by 128 pixel frame, about 40 pixels per unit (the car about 120 pixels long and 3 times as long as it is wide, Drifting, Decisions), a selective dark outline, detailed shading, high detail, about 30 colours, no anti-aliasing, no semi-transparent pixels, a transparent background, the isometric view only. The technical-style reference image (Visual style, References) may be used as a style image, for its style only.

**PixelLab:** pick the endpoint that best makes one isometric sprite in a given direction at 128 by 128 (re-check https://www.pixellab.ai/llms.txt and https://api.pixellab.ai/v2/openapi.json first; the API changes), and say in the result notes why. Use the existing client, `game/tools/pixellab_client.py`. Record every call with its prompt, settings and cost, and the balance before and after, as for T-003. **One round of generation only:** do not regenerate; report problems instead. If a single call returns several images, keep them all for the board to choose from.

**Do not put it into the game yet:** save the sprite (and its record) under `game/art/` next to the placeholders, without changing any scene, script or the placeholder sheets. T-101 does the swap once the full set exists.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The sprite is a 128 by 128 pixel PNG under `game/art/`, and the result notes say which of T-013's isometric frames its direction matches (QA: pass / fail)
- [ ] A check script shows it follows Visual style's technical rules: transparent background, no semi-transparent pixels, about 30 colours or fewer (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass / fail)
- [ ] `git diff master...HEAD` shows no change to scenes, game scripts or the placeholder sheets (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the car's look (the Mustang GT shape, the dark green, the two centred stripes with a gap, the direction); one round only, so problems are reported rather than regenerated.
Board review files: the new sprite PNG(s) under `game/art/`.

## Result notes

Written by the agent when it finishes.
