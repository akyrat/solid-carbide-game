---
id: T-155
title: "Trick prototype: jump over obstacles for a bonus, the left side flip and the nose launch"
status: open
from: project-lead
to: driving-drift
lead: Tricks
epic: driving
milestone: final-release
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, tasks/T-151-arrow-key-trick-prototype.md, tasks/T-153-side-flip-art.md]
files_expected_to_change: [game/scripts/driving/arrow_tricks.gd, game/scripts/driving/trick_flip.gd, game/scripts/driving/trick_prototype.gd, the trick prototype scene, tests under game/tests/, game/README.md, docs/drifting.md (Content, "Prototypes so far")]
model: opus
qa_rounds: 0
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

- [ ] Up, Left, Down, Right fires `side_flip_left` and Up, Down, Up, Up fires `nose_launch`; the right flip still works; tests show the three are told apart. (QA: pass / fail)
- [ ] A test shows the car passes over an obstacle during a trick's jump and still collides with it on the ground. (QA: pass / fail)
- [ ] A test shows a jump never ends with the car inside an obstacle. (QA: pass / fail)
- [ ] A test shows `trick_performed("jump_over")` fires when an obstacle is cleared during a jump, and not when none is. (QA: pass / fail)
- [ ] The trick prototype has boulders and at least one low wall to jump over (screenshot). (QA: pass / fail)
- [ ] The left flip plays the roll frames reversed in the start direction and the mirrored code roll elsewhere; the nose launch plays its dip, launch, pitch and landing (test or scripted screenshots). (QA: pass / fail)
- [ ] `docs/drifting.md` ("Prototypes so far") and `game/README.md` describe the changes. All three test sets pass. (QA: pass / fail)

The board's review: play the trick prototype with T-156 (one playtest build).

## Updates

## Result notes
