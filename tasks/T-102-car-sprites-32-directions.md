---
id: T-102
title: The car in 32 directions, built from the approved 16 (PixelLab)
status: open
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: final-release
user_facing_text: no
changes_visuals: yes
depends_on: [T-101]
documents_affected: [game/README.md, art-archive/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/drifting.md, docs/extended-narrative.md, tasks/T-013-placeholder-car-sprites.md, tasks/T-014-car-sprites-16-directions.md, tasks/T-101-car-sprites-remaining-directions.md, art-archive/README.md, game/README.md]
files_expected_to_change: [the car sprite sheet and its JSON, game/art/car/car_iso_noshadow.png and its JSON, game/tools/build_car_noshadow.py, game/tools/build_car_sheet.py, tests, the PixelLab generation log, art-archive/, game/README.md]
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

**Scheduled now (board, 2026-10-20).** The board wants 32 directions so the car turns more smoothly, and approves this task's PixelLab generations. Sample first (`docs/working-with-the-board.md`, "Art and money"): generate **one** new in-between frame first, build it into an image the board can look at next to its two neighbours (enlarged, on a dark and a light background), and stop there: hand back with the result notes saying the sample is ready for the board. Only after the board approves it, generate the other 15 the same way. After the full sheet, rebuild the shadowless frames for the air (T-204, `game/art/car/car_iso_noshadow.png`) from the 32-frame sheet with the free script `game/tools/build_car_noshadow.py` (extend it if it assumes 16 frames), so the car in the air also turns in 32 directions.

**For some point after the MVP's current steps; not scheduled (board, 2026-10-12).** The board played the 16-direction car (T-101), likes its look, and wants 32 directions at some point (Visual style, Decisions), so the car turns more smoothly on screen.

Build 32 directions, 11.25 degrees apart, from the approved 16 in `game/art/car/car_iso.png`: keep all 16 existing frames exactly as they are, and add one frame between each pair, so every new frame matches its neighbours (the same car, colours, stripes, size and shadow). T-101's notes say how the 16 were made (`/generate-8-rotations-v3` then `/rotate`, mapped to the approved sprite's palette by `build_car_sheet.py`, centred), and which frames are off their heading (frame 11 about 40 degrees, frame 1 about 20); say in the result notes whether the new frames make that better or worse, and how close each new frame is to its heading.

`game/scripts/driving/car_sprite.gd` already reads `frame_count` and `step_deg` from the sheet's JSON, so 32 frames should need no code change; if anything outside the art does need changing, say so in the result notes and keep it to rendering, never the driving code.

The board approves the generations this task needs. Plan the calls first and write the plan and its expected cost in the result notes before calling; check the balance before and after; use a long HTTP timeout. One round: don't regenerate frames you don't like; report them. Every generation that isn't used as-is goes to `art-archive/T-102/` with its record and a row in `art-archive/README.md`; nothing generated is deleted, and `game/art/` holds only the final sheet.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The isometric sheet has 32 frames of 128 by 128 pixels, 11.25 degrees apart, in T-013's layout and JSON convention; the 16 frames from T-101 are byte-identical in their new places; Godot imports it (QA: pass / fail)
- [ ] A check script shows every frame follows Visual style's technical rules (transparent background, no semi-transparent pixels, about 30 colours or fewer, judged as in T-014) (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass / fail)
- [ ] In a run started from the main menu and in the drift prototype, the car shows all 32 frames following its heading, with no change to the driving code (screenshots) (QA: pass / fail)
- [ ] `game/art/car/car_iso_noshadow.png` is rebuilt with 32 frames by `build_car_noshadow.py`, and in the air the car shows them following its heading (screenshot) (QA: pass / fail)
- [ ] Every unused or raw generation is in `art-archive/T-102/` with its record and listed in `art-archive/README.md` (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: first the one-frame sample, then playtest the car in a run and judge the 32 directions; one round only, so problems are reported rather than regenerated.
Board review files: the car sheet under `game/art/car/`.

## Result notes

Written by the agent when it finishes.
