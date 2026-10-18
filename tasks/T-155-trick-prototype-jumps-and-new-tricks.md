---
id: T-155
title: "Trick prototype: jump over obstacles for a bonus, the left side flip and the nose launch"
status: cancelled
from: project-lead
to: driving-drift
lead: Coursework
epic: driving
milestone: final-release
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, tasks/T-151-arrow-key-trick-prototype.md, tasks/T-153-side-flip-art.md]
files_expected_to_change: [game/scripts/driving/arrow_tricks.gd, game/scripts/driving/trick_flip.gd, game/scripts/driving/trick_prototype.gd, the trick prototype scene, tests under game/tests/, game/README.md, docs/drifting.md (Content, "Prototypes so far")]
model: opus
qa_rounds: 1
---

## Description

The board played the trick prototype (T-151, T-152, T-153) and asked for three things (Drifting, Decisions, 2026-10-17). Work on a branch made from `playtest/tricks` (the combined playtest build), so the HUD and the roll frames are there. Keep it a quick prototype.

1. **Jump over obstacles and walls.** While the car is in the air during any trick, it passes over obstacles and walls (everything on the `obstacles` layer, game/README.md, "Collision layers") instead of hitting them. It must never land inside one: if the jump would end over an obstacle, keep it in the air until it is clear (or propose another rule that never leaves the car stuck, and say which in the result notes). Each time the car clears an obstacle during a jump, it earns a **jump-over bonus**, which counts as a trick of its own: send `trick_performed("jump_over")` (one per obstacle cleared, or one per jump; propose which). Add a few obstacles to the trick prototype's ground to try it on: some boulders (the game's boulder art) and a low wall or two, near the start, plus the drift prototype's test room if it is there.
2. **Left side flip.** A second arrow trick: **Up, Left, Down, Right** makes the car do the side flip to its **left**, the mirror of the existing right flip (same hop). In the start direction, play T-153's roll frames in reverse order (a roll played backwards is the roll the other way); elsewhere the code roll, mirrored. Trick id `side_flip_left`.
3. **Nose launch.** A third arrow trick: **Up, Down, Up, Up**. The board's description: the car leans forward onto its nose, then suddenly launches forward, its nose flipping up quickly while it keeps travelling through the air, then it falls back down, like pressing on the back of a toy car and quickly letting it spring forward. Build it as: a short nose dip (the drawing tips forward and squashes, about 0.15 s), then a launch with a forward push to the car's speed (propose the amount), a longer and higher hop than the side flip, and the drawing pitching nose-up through a full backflip (or as far as reads best; propose it) before landing with a squash. Code-drawn for now (pitching the sprite and squashing it). It also jumps over obstacles and earns the bonus. Trick id `nose_launch`.

All three sequences start with Up; check the detector tells them apart at the second key, and that a wrong key that is Up still starts a new sequence. All new numbers (heights, durations, push) are tunable constants and proposals for the board's playtest.

On-screen text is not in this task: the confirmation card for the new tricks and the bonus is T-156, with T-154's text.

Tests: the two new sequences fire their tricks and the three are told apart; the car passes over an obstacle while in the air and collides with it normally on the ground; it never ends a jump inside an obstacle; the jump-over bonus fires when an obstacle is cleared and not when none is; the nose launch adds its forward push.

## Acceptance criteria

- [x] Up, Left, Down, Right fires `side_flip_left` and Up, Down, Up, Up fires `nose_launch`; the right flip still works; tests show the three are told apart. (QA: pass) test_trick_jumps and test_arrow_tricks cover both sequences, right flip, telling apart; all pass
- [x] A test shows the car passes over an obstacle during a trick's jump and still collides with it on the ground. (QA: pass) test_trick_jumps boulder test: hit on ground, over during flip, collides again after landing
- [x] A test shows a jump never ends with the car inside an obstacle. (QA: pass) tests for start-on-boulder and slow hops onto every boulder and wall, flip and nose launch
- [x] A test shows `trick_performed("jump_over")` fires when an obstacle is cleared during a jump, and not when none is. (QA: pass) tests for one bonus per cleared obstacle and none without one
- [x] The trick prototype has boulders and at least one low wall to jump over (screenshot). (QA: pass) T-155_obstacles_5.png and contact sheet show boulders and a low wall
- [x] The left flip plays the roll frames reversed in the start direction and the mirrored code roll elsewhere; the nose launch plays its dip, launch, pitch and landing (test or scripted screenshots). (QA: pass) tests for reversed frames, mirrored code roll, nose launch phases; contact sheet shows left/nose frames
- [x] `docs/drifting.md` ("Prototypes so far") and `game/README.md` describe the changes. All three test sets pass. (QA: pass) drifting.md and game/README.md have T-155 sections; GUT 891/892 on playtest line, the one failure is the expected main-scene check, which passes (23/23 in test_screen_flow with the main scene restored; game/tools 281 OK, tools 182 OK)

The board's review: play the trick prototype with T-156 (one playtest build).

## Updates

### 2026-10-17, Open → In progress

Started: flying over obstacles and walls with a jump-over bonus, the left side flip (Up, Left, Down, Right) and the nose launch (Up, Down, Up, Up), on top of the playtest build.

### 2026-10-17, In QA

Built: flying over obstacles (3 boulders, 2 low walls) with a bonus per obstacle cleared, the left flip, and the nose pop (dip, +8 speed push, 28 px hop with a backflip). QA is checking it now.

### 2026-10-17, Needs playtest

QA passed all 7 criteria; waits for your playtest with T-156 and T-157 in one build.

## Result notes

### Driving & Drift Agent, 2026-10-17

**Built** (on `playtest/tricks`, T-152's HUD code untouched):
- **Left side flip** (Up, Left, Down, Right, `side_flip_left`): the right flip's hop, roll angle 0 to -TAU. In the start direction the T-153 roll frames play reversed (frame 0, then 8 down to 1); elsewhere the code roll, mirrored (leans and turns left).
- **Nose launch** (Up, Down, Up, Up, `nose_launch`), code-drawn. Proposed numbers: a 0.15 s nose dip (tips 3 px toward the nose, squashes to 0.82), then the launch with a **+8 units/s** push along the nose (cruise 11, top 33), a 0.9 s, 28 px hop (side flip: 0.6 s, 16 px), and the drawing pitching nose-up through **one full backflip** (squashed along the nose axis, mirrored and tinted for the underside, lifted 4 px while on its tail). Landing squash 0.72.
- **Jumping over obstacles:** while any trick is airborne, the car's collision mask is cleared, so it passes over everything on the obstacles layer; it is set back on landing. **Landing rule (as asked):** if the hop would end over an obstacle, it holds in the air, 6 px up, until the car is clear (checked with a 1.1-unit square, so it never lands touching one). **Plus one safety rule:** while held, a car slower than 3 units/s is pushed along its nose up to 3 units/s, so it can never hang there. The car can still drive in the air.
- **Jump-over bonus: one per obstacle cleared** (proposal), sent as `trick_performed("jump_over")` the moment the car's body (checked as a 0.8-unit square, so touching one at take-off doesn't count) comes clear of an obstacle it was over. Two boulders in one jump earn two.
- **Obstacles:** three boulders (the game's boulder art: variants a, b, a_mirror) and two low walls just ahead of the start (`scripts/driving/trick_obstacles.gd`). The test room is still there.
- **Detector:** the three sequences are told apart at the second key. A wrong key that is Up starts a new sequence (tested). New `arrow_tricks.candidates()`.
- All numbers are named constants (`trick_flip.gd`, `trick_prototype.gd`, `trick_obstacles.gd`). `car.gd` is unchanged.

**For T-156 (the HUD): what to read to know which sequence is in progress.** Read `arrow_tricks.candidates()` on `progress_changed`. One id means that trick. All three (after Up alone) means it isn't decided yet. `target_sequence()` still returns the first candidate's sequence, so after Up alone it shows the right flip's, which is misleading. New ids on the scene's `trick_performed`: `side_flip_left`, `nose_launch`, `jump_over`. `jump_over` can fire while a flip's card is still showing. `flip.kind` is the trick playing. Today the HUD shows no card for ids it has no text for.

**Known limits (prototype):** the car is always drawn over the obstacles, even on the ground behind one (no depth order). A jump can carry the car over the test room's outer wall and out of the room.

**Screenshots:** `art-archive/T-155/screenshots/`. They come from `tests/fixtures/trick_jumps_demo.tscn`, with `TRICK_DEMO` set to `nose`, `left`, `right` or `obstacles`; the car moves one physics step per drawn frame. Files: `T-155_obstacles_5.png` (boulders and low walls), `T-155_nose_5/14/30/46.png` (dip, launch over the boulder pitched, past it, landing), `T-155_left_10/18/26.png` (roll frames reversed), `T-155_right_18.png`, `T-155_contact_sheet.png`.

**Tests:** `game/tests/unit/test_trick_jumps.gd`, 18 tests. The existing `test_trick_prototype.gd` and `test_arrow_tricks.gd` pass unchanged. Full GUT run: **891 of 892** (78 scripts). The one failure is `test_screen_flow.gd::test_the_main_scene_is_the_game_flow`, which is expected on this line: `project.godot`'s main scene is temporarily the trick prototype for the playtest, left as instructed. It passes once that is reverted for master. `game/tools` Python: 281 OK (1 skipped). `tools` Python: 182 OK.

**Documents affected:** `docs/drifting.md` (Content, "Prototypes so far": "Trick prototype, round 2 (task T-155)"), `game/README.md` ("Trick prototype, round 2 (T-155)", plus the layer 1 row of "Collision layers").
- 2026-10-17, in-progress → in-qa: Built: left side flip, nose launch, flying over obstacles with a jump-over bonus (one per obstacle cleared), boulders and low walls in the trick prototype. Tests pass except the expected main-scene check on this playtest line.
- 2026-10-19, needs-playtest → cancelled: Board, 2026-10-19: building the trick prototype before an elevation system was a mistake. Not merged; kept as the reference for rebuilding the tricks on real height (Drifting, Content, 'Trick prototype (reference)'); code on the branch hold/trick-prototype, art in art-archive/.
