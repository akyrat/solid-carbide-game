---
id: T-018
title: Redraw the placeholder car sprites at 3:1
status: in-progress
from: project-lead
to: asset-generation
epic: art
milestone: mvp
depends_on: [T-013]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, tasks/T-013-placeholder-car-sprites.md, game/README.md]
files_expected_to_change: [the placeholder car sheet generator and its tests, the two placeholder sheets and their JSON files, game/README.md]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board decided the car is drawn 3 times as long as it is wide (Drifting, Decisions). The placeholder sheets from T-013 are 2:1 (32 by 16 pixels). Redraw them at 3:1 with T-013's generator script, for example 48 by 16 pixels, keeping everything else the same: 16 directions, a flat and an isometric sheet, a single body colour with a distinct nose, no PixelLab.

- Keep T-013's layout convention (frame 0's direction, frame order, the car's centre at the centre of each frame), so code that reads the sheets needs no change. Make the frames as large as the longer car needs in every direction, in both views; if the frame size changes, the JSON files say so.
- The JSON files record the car's drawn size in units as well as pixels: 1 unit wide, 3 units long, so code can scale the sprite to the world.
- Update the script's tests and `game/README.md` ("Placeholder car sprite sheets") to match.

## Acceptance criteria

- [ ] Both sheets have exactly 16 frames of equal size, and Godot imports them without errors (QA: pass / fail)
- [ ] Looking at both sheets, every frame shows a single-colour rectangle 3 times as long as it is wide (in the flat sheet, measured in pixels; in the isometric sheet, before projection) with a distinct nose, turning steadily from frame to frame as in T-013 (QA: pass / fail)
- [ ] The JSON files keep T-013's layout fields and add the car's drawn size in units (1 wide, 3 long) (QA: pass / fail)
- [ ] Running the generator twice produces byte-identical sheets (QA: pass / fail)
- [ ] The generator's tests, the full GUT suite and all Python tool tests pass (QA: pass / fail)
- [ ] No PixelLab call was made: `game/art/pixellab-generation-log.jsonl` is unchanged (QA: pass / fail)
- [ ] `game/README.md` describes the 3:1 sheets (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
