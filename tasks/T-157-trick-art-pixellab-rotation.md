---
id: T-157
title: "Art: real-depth trick frames with PixelLab's rotation tools (sample: one direction)"
status: open
from: project-lead
to: asset-generation
lead: Tricks
epic: art
milestone: final-release
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/drifting.md, docs/working-with-the-board.md, tasks/T-153-side-flip-art.md, tasks/T-155-trick-prototype-jumps-and-new-tricks.md, game/README.md, game/tools/pixellab_client.py, game/art/car/car_iso.json]
files_expected_to_change: [new frames under game/art/car/ and their records, art-archive/T-157/, the trick prototype's roll sheets, game/tools/pixellab_client.py (new endpoints only), docs/visual-style.md, game/README.md]
model: opus
qa_rounds: 0
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

- [ ] The result notes list every planned call and its cost, committed before the first call; the record lists every call with prompt, settings, cost and balance before and after; the total is at most 15 generations. (QA: pass / fail)
- [ ] Game-ready frames for the side roll and the nose pop (direction 12, about 8 each, transparent, the car's palette and size) are in `game/art/car/` with records; raw output is in `art-archive/T-157/`. (QA: pass / fail)
- [ ] Enlarged previews on a dark and a light background are in `art-archive/T-157/`. (QA: pass / fail)
- [ ] In the trick prototype, the right flip, the left flip (reversed) and the nose launch use the new frames in direction 12 (test or scripted screenshots). (QA: pass / fail)
- [ ] `docs/visual-style.md` and `game/README.md` record the frames and the method. All three test sets pass. (QA: pass / fail)

The board's review: judge the sample frames, then the tricks in the trick prototype (one playtest build with T-155 and T-156).
Board review files: art-archive/T-157/ previews (listed in the result notes).

## Updates

## Result notes
