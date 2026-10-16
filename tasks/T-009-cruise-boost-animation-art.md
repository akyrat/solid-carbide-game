---
id: T-009
title: Boost animation art for the jump to cruise speed
status: needs-playtest
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
qa_rounds: 1
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

- [ ] The planned PixelLab calls and their cost are in the result notes, written before the calls, and only one round was generated (QA: pass) Plan (a432794) predates the calls; 2 generations = the 2 planned calls, call 1 empty and not regenerated, script-drawn first frame for call 2 declared before call 2 (free). Matches one round.
- [ ] The animation frames are in `game/art/` with their record files, every other generation is in `art-archive/T-009/`, and Godot imports the frames without errors (QA: pass) boost_lines.png + json in game/art/effects; all generations and records in art-archive/T-009/; launch with --quit-after 300 shows no errors.
- [ ] A test shows a W press that jumps the car to cruise speed plays the new animation (not T-008's placeholder streaks) behind the car, and it ends by itself (QA: pass) test_boost_art.gd: W press plays frames 0-4 behind the car, uses the PixelLab sheet, ends by itself; GUT passes.
- [ ] T-008's boost tests still pass: no boost while W stays held in a drift, and the driving is unchanged (QA: pass) test_boost.gd (8) unchanged and passing.
- [ ] A screenshot (or a strip of frames from the game) shows the motion lines behind the car (QA: pass) boost_strip_x2.png shows three thin pale-cyan lines behind the rear bumper fading over the strip.
- [ ] The full GUT suite and all Python tool tests pass (QA: pass) GUT 791/791; pytest tools 182; pytest game/tools 271 pass, 1 skipped.

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

**Call 1 result (problem, reported, not regenerated):** the pixflux call came back as a fully transparent 64 x 64 image (every pixel alpha 0, one flat colour underneath): PixelLab drew a plain backdrop with no lines, and its background removal took all of it. Cost 1 generation (balance 4900 to 4899). Kept with its record in `art-archive/T-009/call1/`.

**Change to call 2, before calling (no extra generation):** call 2's first frame is drawn by a script instead (free, `python game/tools/build_boost_lines.py first-frame`, `art-archive/T-009/first_frame_script.png`): three thin horizontal lines in the same 5-colour palette, bright at the right end (the car's side), tapering to the left, with a dark selective edge. Call 2 is otherwise as planned: `/animate-with-text-v3`, frame_count 8, no_background, estimated 1 generation. Total for the round stays at 2 generations.

### Done (2026-10-16), on `task/T-009-cruise-boost-animation-art` (built on T-008's branch, master merged in)

**PixelLab spend: 2 generations, as planned** (balance 4900 to 4898). Call 1 (pixflux) came back empty (above). Call 2, `/animate-with-text-v3` on the script-drawn first frame, 1 generation: 9 frames of 64 x 64 (`art-archive/T-009/call2/`, each with its record; request `call2_req.json`). No regeneration.

**What came back, honestly:** frames 0 to 3 show the lines sliding back to the left and thinning, frame 5 short stubs, and frames 4, 6, 7 and 8 are empty. The motion is jumpy rather than smooth. I use frames **0, 1, 3, 2, 5** in that order (ordered by how far back the lines have gone, frame 2 being the dimmer one), 5 frames.

**In the game:** `game/art/effects/boost_lines.png` (+ `boost_lines.json` record): the 5 frames turned by script (nearest-neighbour, no new colours) to 16 screen directions, 80 x 80 cells, 400 x 1280 sheet, 10 colours, no semi-transparent pixels, nearest Redgull-red distance 0.757. `boost_effect.gd` now draws this art instead of T-008's five streaks, on the same `Car.boost` signal through `bind(car)`, under the car sprite. Timing: 5 frames at 14 fps, about 0.36 s (T-008's 0.35 s kept). **One change from T-008:** each burst follows the car, with the lines' leading ends at the rear bumper (`behind_units` 0.8). With T-008's "stay where made", the car outran the lines at once and they floated a car length behind it.

**Screenshot:** `art-archive/T-009/screenshots/boost_strip_x2.png` (game frames 4 to 22 after a W press from standstill, 2x) and the single shots `boost_f*.png` next to it. Three thin pale-cyan lines sit right behind the rear bumper and fade back over a third of a second, which is discreet. Weak points: the lines' angle is the nearest of 16 screen directions, so here they run about 10 degrees flatter than the car's body; and the animation steps rather than flows (PixelLab's frames).

**How the board plays it:** open `C:\solid-carbide-worktrees\T-009\game\project.godot` (or Play on T-009 in the task board's Builds tab), start a run, and press W from standstill or after coasting below cruise speed.

**Tests:** new `game/tests/unit/test_boost_art.gd` (6: the sheet imports and matches its record; no semi-transparent pixels or Redgull red; the effect uses the PixelLab sheet, not the streaks; a W press in the run plays frames 0 to 4 in order behind the car, under the car sprite, following it, and ends by itself with no new burst while W is held; rows follow the heading on screen; lifetime close to T-008's). T-008's `test_boost.gd` (8) unchanged and passing. `game/tools/test_build_boost_lines.py` (6: rules, records, the build reproduces the committed sheet exactly, rotation adds no colours, first frame matches the one sent). Full GUT suite **791/791** pass; `python -m pytest tools` 182 pass; `python -m pytest game/tools` 271 pass, 1 skipped. Launch with `--quit-after 300`: no script errors.

**Tools:** `game/tools/build_boost_lines.py` (`first-frame`, `build 0,1,3,2,5`, `check`), free.

**Documents updated:** `docs/visual-style.md` (Content: "Cruise boost motion lines"), `game/README.md` ("Boost effect" section and the file list).
- 2026-10-16, in-progress → in-qa: PixelLab motion lines (2 generations, 5 frames x 16 directions, 80x80 cells) swapped in for T-008's streaks on Car.boost, behind and following the car; GUT 791/791, pytest 182 + 271 pass. Play: C:\solid-carbide-worktrees\T-009\game\project.godot, press W from standstill.

### QA round 1 (QA/Integration Agent, 2026-10-16)

All 6 criteria pass (marked above). Docs diff: visual-style.md Content only (+4 lines), game/README.md. GUT 791/791, pytest 182 and 271 (1 skipped), launch clean.
- 2026-10-16, in-qa → needs-playtest: QA round 1: all 6 criteria pass; GUT 791/791, pytest 182+271
