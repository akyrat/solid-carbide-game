---
id: T-151
title: "Trick prototype: arrow-key sequences, the side flip and its hop (placeholder flip)"
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
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/scenes/drift_prototype/drift_prototype.tscn]
files_expected_to_change: [a new trick prototype scene and its scripts under game/, tests under game/tests/, game/README.md, docs/drifting.md (Content, "Prototypes so far")]
model: opus
qa_rounds: 1
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

- [ ] A trick prototype scene exists and runs from Godot; `game/README.md` says how to open it. (QA: pass) [scene and README run instructions present]
- [ ] The car drives with W/A/S/D in that scene as in the drift prototype. (QA: pass) [test_trick_prototype drives with WASD, arrows do not drive]
- [ ] Automated tests cover the sequence detector cases listed above and pass. (QA: pass) [test_arrow_tricks 11 tests cover fire once, wrong key, Up restart, timeout, blocked]
- [ ] A test or a scripted run shows the side flip plays (the drawing rises and returns, the roll runs) and the car's physics body position is not moved by it. (QA: pass) [test_trick_prototype checks hop rise ~16 px, roll, physics position equal to unflipped twin]
- [ ] The scene exposes held arrow keys, sequence progress and a `trick_performed` signal, documented in `game/README.md`. (QA: pass) [README documents held, progress, trick_performed]
- [ ] The trick list is in one place, and the flip can take a frame sequence for one direction (documented). (QA: pass) [TRICKS table in arrow_tricks.gd; roll sheet slot documented]
- [ ] `docs/drifting.md`, Content, "Prototypes so far" describes the prototype. (QA: pass) [drifting.md paragraph present]
- [ ] All three test sets pass. (QA: pass) [GUT 869/869 (both new files ran], game/tools 278 OK, tools 182 OK)

The board's review: play the trick prototype together with T-152 and T-153 (one playtest build).

## Updates

### 2026-10-16, Open → In progress

Started: the Driving & Drift Agent builds the trick prototype (Up, Right, Down, Left makes a side flip with a fake hop), with a code roll as a placeholder.

### 2026-10-16, In QA

Prototype built, all three test sets pass. QA is checking it now; the key display (T-152) and the PixelLab roll (T-153) are being added on top of it.

### 2026-10-16, Needs playtest

QA passed all 8 criteria; waiting for your playtest, together with T-152 and T-153 in one build.

### 2026-10-16, Needs playtest

Ready to play in one build: open C:\solid-carbide-worktrees\playtest-tricks\game\project.godot, open scenes/trick_prototype/trick_prototype.tscn and press F6. Arrow keys Up, Right, Down, Left for the side flip.

### 2026-10-17, Needs playtest

Play in the playtest build now starts straight into the trick prototype (temporary, playtest branch only; master keeps the main game).

## Result notes

Built by the Driving & Drift Agent, 2026-10-16.

**How the board opens it:** in the Godot editor (the task folder's `game/project.godot`), open `scenes/trick_prototype/trick_prototype.tscn` and press **F6** (Run Current Scene). F5, and the task board's Play button, start the main menu instead, not this scene. Without the editor, from the task folder: `"$GODOT_BIN" --path game res://scenes/trick_prototype/trick_prototype.tscn`. Keys: W/A/S/D drive as in the drift prototype (Tab, V, Escape too); Up, Right, Down, Left makes the side flip.

**Start direction (for T-153):** the car starts at world heading -90 degrees, car sheet frame **12**: drawn pointing **up-right on screen** (PixelLab "north-east"; `car_iso.json` frame 12, from `/generate-8-rotations-v3` image 4). The roll frames should be generated from that frame.

**What was built:**

- `game/scripts/driving/arrow_tricks.gd`: the trick list (`TRICKS`, one constant table: id and arrow sequence; only `side_flip_right` = up, right, down, left) and the sequence detector. Consecutive presses, `MAX_GAP` 0.6 s between presses (proposal); a wrong key resets, and counts as a new first step if it is one (Up); a timeout resets even with no new press (so the HUD clears in time); `blocked` while a flip plays.
- `game/scripts/driving/trick_flip.gd`: the flip, drawing only. Hop: parabola, 16 drawn px high, 0.6 s, then a 0.12 s landing squash. Roll: a full turn over the hop, eased. Ground shadow: dark ellipse of the car's 3 x 1 unit footprint, drawn only during the flip, shrinking to 70% and fading to 60% at the top. Placeholder code roll: the sprite squashed across its drawn long axis by cos(angle), mirrored and tinted darker (underside) for the middle half, with a 3 px lean to the car's right.
- `game/scripts/driving/trick_prototype.gd` + `game/scenes/trick_prototype/trick_prototype.tscn`: extends the drift prototype (nothing in it changed), reads the arrow keys, starts the flip, applies it after every car physics step. The camera stays on the car's ground position, so the hop shows against a steady view.
- Fixture `game/tests/fixtures/trick_flip_demo.tscn` for screenshots (`bash game/tools/screenshot.sh res://tests/fixtures/trick_flip_demo.tscn screenshots/trick_flip.png 60`, try 10 to 140 frames). I checked frames 4 to 140: the car squashes to a line, shows mirrored, comes back upright and lands; the shadow stays on the ground.

**HUD API (T-152), on the scene node:** `arrow_tricks.held` + `arrow_tricks.held_changed(held)`; `arrow_tricks.steps`, `matched()`, `target_sequence()`, `progress_changed(steps, target)`, `sequence_reset(reason)` ("wrong_key", "timeout", "blocked", "completed"); `trick_performed(trick_id)` on the scene node (also on `arrow_tricks`); `flip.flip_started`, `flip.flip_finished`, `flip.is_playing()`. Details in `game/README.md`, "Trick prototype (T-151)".

**Frame sequence slot (T-153):** drop `game/art/car/car_roll.png` (one row of frames, upright through a full roll to the right) and `car_roll.json` (`direction_frame` 12, `frame_count`, `frame_width`, `frame_height`, `center_px`, `px_per_unit`, as in `car_iso.json`). The scene loads it at start (`ROLL_SHEETS`, `TrickFlip.load_roll_sheet`); during a flip, while the car shows frame 12 in the isometric view, the sprite shows the sequence frame for the roll angle, with the same hop, shadow and squash, and the car sheet comes back after. Other directions and the flat view keep the code roll. No code change needed.

**Notes:** the pink disc that shows under the car when it hops at the start point is the ground grid's existing origin marker, not part of the flip. The shadow is subtle on the very dark prototype ground (black at 60% alpha); easy to tune in `SHADOW_COLOR`. No on-screen text was added (the drift prototype's hint line is unchanged and does not mention the arrows; that is for T-152 / Narrative).

**Tests:** `game/tests/unit/test_arrow_tricks.gd` (11: fires once, progress, wrong key resets, Up after a wrong key restarts, Up Up, timeout with and without a press, just inside the limit, blocked, held keys) and `game/tests/unit/test_trick_prototype.gd` (12: drives, arrows do not drive, keys to the flip and signal, held keys, no trick during a flip, the flip rises about 16 px, mirrors and tints while the physics position and rotation match an unflipped twin car step for step, hop arc and shadow, the frame sequence for one direction, other directions and the flat view keep the code roll, loading a roll sheet). All three test sets pass: GUT 869/869, `game/tools` Python 278 OK (1 skipped), `tools` Python 182 OK.

**Documents affected:** `docs/drifting.md` (Content, "Prototypes so far": a paragraph on the trick prototype), `game/README.md` (new section "Trick prototype (T-151)", folder layout row).

**Playtest only (board, 2026-10-17):** on branch `playtest/tricks` only, `game/project.godot` `run/main_scene` points at `res://scenes/trick_prototype/trick_prototype.tscn` so Play (F5, the task board) starts the trick prototype; temporary, must not reach master (master keeps `res://scenes/game/game.tscn`).
- 2026-10-19, needs-playtest → cancelled: Board, 2026-10-19: building the trick prototype before an elevation system was a mistake. Not merged; kept as the reference for rebuilding the tricks on real height (Drifting, Content, 'Trick prototype (reference)'); code on the branch hold/trick-prototype, art in art-archive/.
