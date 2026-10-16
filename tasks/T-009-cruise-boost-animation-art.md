---
id: T-009
title: Boost animation art for the jump to cruise speed
status: in-progress
from: project-lead
to: asset-generation
lead: Playtest
epic: art
milestone: final-release
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, tasks/T-008-cruise-boost-effect.md, docs/extended-narrative.md]
files_expected_to_change: [the boost animation frames and their record files]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Built on T-008's branch (board, 2026-10-16).** T-008 (the boost effect, with its placeholder streaks) is not merged: it waits for this art. Branch `task/T-009-cruise-boost-animation-art` from `task/T-008-cruise-boost-effect` (not from master), in your own folder `C:\solid-carbide-worktrees\T-009`, and merge master into it. The board plays this folder; T-008 merges first, then this.

**The board's description (Visual style, Decisions):** discreet: a few motion lines that show briefly (2026-10-15; the board found T-008's five streaks too much). **Animated, made with PixelLab** (board, 2026-10-16).

**No sample review for this asset (board, 2026-10-16):** "There's no point for me checking the samples." The board judges the motion lines only in the game. So generate the animation, then swap it in for T-008's placeholder yourself, hooked to the same `Car.boost` signal and placed behind the car, so the board plays it straight away. Keep T-008's timing unless the frames need otherwise, and say what you chose.

**PixelLab:** the board gave its go for one round (2026-10-16). Before calling, write the planned calls and their cost in the result notes. Use a 600 s HTTP timeout. One round only: report problems, don't regenerate. Keep every generation: game-ready frames under `game/art/`, the rest in `art-archive/T-009/`, each with its record, as the Visual style document says. No Redgull red.

## Acceptance criteria

- [ ] The planned PixelLab calls and their cost are in the result notes, written before the calls, and only one round was generated (QA: pass / fail)
- [ ] The animation frames are in `game/art/` with their record files, every other generation is in `art-archive/T-009/`, and Godot imports the frames without errors (QA: pass / fail)
- [ ] A test shows a W press that jumps the car to cruise speed plays the new animation (not T-008's placeholder streaks) behind the car, and it ends by itself (QA: pass / fail)
- [ ] T-008's boost tests still pass: no boost while W stays held in a drift, and the driving is unchanged (QA: pass / fail)
- [ ] A screenshot (or a strip of frames from the game) shows the motion lines behind the car (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: play it in the game before it is merged; no separate sample review (board, 2026-10-16).

## Updates

### 2026-10-16, Open → In progress

Started: the Asset Generation Agent makes animated motion lines with PixelLab (one round) and puts them straight into the game on top of T-008, for you to play in C:\solid-carbide-worktrees\T-009.

## Result notes

### Planned PixelLab calls (written before calling, 2026-10-16)

One round, two calls, run one at a time with the client's 600 s HTTP timeout, never relaunched. Balance before: 4900 generations.

- **Call 1, `/create-image-pixflux`** (64 x 64, `no_background`, a 5-colour `color_image` of pale cyans and whites, no red): the first frame, a few thin horizontal motion lines on a transparent background, as if trailing behind something moving to the right. Estimated cost: 1 generation (pixflux at this size cost 1 in T-064/T-075).
- **Call 2, `/animate-with-text-v3`** (first frame = call 1's image, `frame_count` 8, `no_background`): the lines streak away to the left, thin out and vanish. The endpoint returns the first frame plus 8 (9 in all, as in T-068). Estimated cost: 1 generation (each T-068 call cost 1).

Total estimate: **2 generations**. After that, free script work only: transparency and colour clean-up, a Redgull-red check, and turning the frames to the car's directions (nearest-neighbour, no new pixels), so the lines always trail behind the car.
