---
id: T-153
title: "Art: the car's side flip roll frames (one direction, PixelLab)"
status: open
from: project-lead
to: asset-generation
lead: Tricks
epic: art
milestone: final-release
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [game/README.md, docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/working-with-the-board.md, tasks/T-151-arrow-key-trick-prototype.md, game/README.md, game/art/car/car_iso.json]
files_expected_to_change: [new frames under game/art/car/ and their record, art-archive/T-153/, the T-151 flip that uses the placeholder roll, game/README.md, docs/visual-style.md]
model: sonnet
qa_rounds: 0
---

## Description

The art for T-151's side flip (Drifting, Decisions, 2026-10-16). The car rolls a full turn to its right around its long axis during a small jump. Generate a short roll animation of the existing car (the final car art in `game/art/car/`: same palette, size and look) for **one direction**: the direction the car faces when the trick prototype starts (T-151 says which; if it isn't known yet, use the car's default start direction in the drift prototype). About 6 to 8 frames: upright, tipping right, on its side, upside down (underside visible), on the other side, back upright. No shadow in the frames (T-151 draws the ground shadow). Transparent background.

Generation can start now from `master`. To swap the art in, the Project Lead merges T-151's branch into this task's branch once T-151 is ready and tells you; then replace the code roll for that one direction with the frames. The other directions keep T-151's code roll.

**PixelLab go (board, 2026-10-16):** the board asked for PixelLab art for this flip. One round: write the planned calls and their cost in the result notes before calling, use `game/tools/pixellab_client.py` with a 600 s HTTP timeout, and record every call with its prompt, settings and cost, and the balance before and after. If a result is weak, report it; don't regenerate. Free script fixes (cleanup, palette match, aligning frames) come first. Never delete generated art: raw output in `art-archive/T-153/`, only clean game-ready frames in `game/art/`.

## Acceptance criteria

- [ ] The result notes list the planned calls and cost before the calls, and the record lists every call with prompt, settings, cost and balance before and after. (QA: pass / fail)
- [ ] Game-ready roll frames (6 to 8, transparent, the car's size and palette) are in `game/art/car/` with a record; raw output is in `art-archive/T-153/`. (QA: pass / fail)
- [ ] In the trick prototype, the side flip uses the frames when the car faces the generated direction and the code roll otherwise (test or scripted run). (QA: pass / fail)
- [ ] `docs/visual-style.md` and `game/README.md` record the new frames. All three test sets pass. (QA: pass / fail)

The board's review: judge the roll in the trick prototype, with T-151 and T-152 (one playtest build).
Board review files: the new frames under game/art/car/ (listed in the result notes).

## Updates

## Result notes
