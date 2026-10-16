---
id: T-151
title: "Trick prototype: arrow-key sequences, the side flip and its hop (placeholder flip)"
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
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/scenes/drift_prototype/drift_prototype.tscn]
files_expected_to_change: [a new trick prototype scene and its scripts under game/, tests under game/tests/, game/README.md, docs/drifting.md (Content, "Prototypes so far")]
model: opus
qa_rounds: 0
---

## Description

The board wants to playtest arrow-key tricks (Drifting, Decisions, 2026-10-16). Build a **standalone trick prototype scene**, like the drift prototype: the car drives exactly as it does now (W/A/S/D), on a simple ground, and the arrow keys do tricks. It is a quick prototype: keep it small.

1. **Sequence detection.** Read the four arrow keys (they are not used for driving). The one trick for now is the **side flip (right)**: Up, Right, Down, Left pressed in that order, as consecutive presses. A wrong key starts the sequence again (a wrong key that is itself Up counts as the start of a new sequence). Propose a time limit between presses (for example 0.6 s) as a tunable constant; too slow starts it again. Put the trick list in one place (a data file or a constant table: sequence, trick id) so more tricks are easy to add later. No new trick can start while a flip is playing.
2. **Signals for the HUD** (T-152 builds the HUD on top of this branch): readable state or signals for which arrow keys are held right now, how far the current sequence has got (which steps are matched, and when it resets), and a `trick_performed(trick_id)` signal when a sequence completes.
3. **The side flip and its hop.** When the trick fires, the car does a side flip: it rolls a full turn to its right around its long axis while it does a small jump. It is a visual effect only: the car keeps driving and colliding exactly as before (its physics body stays on the ground). The hop illusion: the car's drawing rises and falls on an arc (propose a height, for example 12 to 20 pixels, and a duration, for example 0.6 s), while a dark ground shadow stays under the car and shrinks and fades a little at the top of the jump. A short landing squash is welcome.
4. **Placeholder flip.** Until the art task (T-153) swaps in generated roll frames, fake the roll in code with the existing car sprite (for example scale the sprite across to zero and back, flipping it, with a darker tint for the underside half). Write the flip so a frame sequence for one car direction can be dropped in (T-153 generates frames for one direction first; the other directions keep the code roll).
5. Make the scene easy to launch: say in `game/README.md` and the result notes how the board opens it. Add the prototype to Drifting, Content, "Prototypes so far" (factual, one short paragraph).

No on-screen text in this task: the input HUD and the confirmation animation are T-152.

Tests: the sequence detector (correct sequence fires once, wrong key resets, Up after a wrong key restarts, timeout resets, no trick during a flip) and that the flip leaves the car's physics position untouched.

## Acceptance criteria

- [ ] A trick prototype scene exists and runs from Godot; `game/README.md` says how to open it. (QA: pass / fail)
- [ ] The car drives with W/A/S/D in that scene as in the drift prototype. (QA: pass / fail)
- [ ] Automated tests cover the sequence detector cases listed above and pass. (QA: pass / fail)
- [ ] A test or a scripted run shows the side flip plays (the drawing rises and returns, the roll runs) and the car's physics body position is not moved by it. (QA: pass / fail)
- [ ] The scene exposes held arrow keys, sequence progress and a `trick_performed` signal, documented in `game/README.md`. (QA: pass / fail)
- [ ] The trick list is in one place, and the flip can take a frame sequence for one direction (documented). (QA: pass / fail)
- [ ] `docs/drifting.md`, Content, "Prototypes so far" describes the prototype. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

The board's review: play the trick prototype together with T-152 and T-153 (one playtest build).

## Updates

## Result notes
