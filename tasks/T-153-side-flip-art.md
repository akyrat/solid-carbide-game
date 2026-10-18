---
id: T-153
title: "Art: the car's side flip roll frames (one direction, PixelLab)"
status: cancelled
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: final-release
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [game/README.md, docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/working-with-the-board.md, tasks/T-151-arrow-key-trick-prototype.md, game/README.md, game/art/car/car_iso.json]
files_expected_to_change: [new frames under game/art/car/ and their record, art-archive/T-153/, the T-151 flip that uses the placeholder roll, game/README.md, docs/visual-style.md]
model: sonnet
qa_rounds: 1
---

## Description

The art for T-151's side flip (Drifting, Decisions, 2026-10-16). The car rolls a full turn to its right around its long axis during a small jump. Generate a short roll animation of the existing car (the final car art in `game/art/car/`: same palette, size and look) for **one direction**: the direction the car faces when the trick prototype starts (T-151 says which; if it isn't known yet, use the car's default start direction in the drift prototype). About 6 to 8 frames: upright, tipping right, on its side, upside down (underside visible), on the other side, back upright. No shadow in the frames (T-151 draws the ground shadow). Transparent background.

Generation can start now from `master`. To swap the art in, the Project Lead merges T-151's branch into this task's branch once T-151 is ready and tells you; then replace the code roll for that one direction with the frames. The other directions keep T-151's code roll.

**PixelLab go (board, 2026-10-16):** the board asked for PixelLab art for this flip. One round: write the planned calls and their cost in the result notes before calling, use `game/tools/pixellab_client.py` with a 600 s HTTP timeout, and record every call with its prompt, settings and cost, and the balance before and after. If a result is weak, report it; don't regenerate. Free script fixes (cleanup, palette match, aligning frames) come first. Never delete generated art: raw output in `art-archive/T-153/`, only clean game-ready frames in `game/art/`.

## Acceptance criteria

- [ ] The result notes list the planned calls and cost before the calls, and the record lists every call with prompt, settings, cost and balance before and after. (QA: pass) Plan and cost committed 22:53 before the call (22:56); log line has endpoint, seed/job, cost 2.0; settings in roll_req.json, balance 4898 to 4896 in the notes (the log line's prompt is null, the call takes none).
- [ ] Game-ready roll frames (6 to 8, transparent, the car's size and palette) are in `game/art/car/` with a record; raw output is in `art-archive/T-153/`. (QA: pass) 8 frames car_roll_ne_0..7 plus car_roll.png (9 frames) and json in game/art/car/, raw output and record in art-archive/T-153/.
- [ ] In the trick prototype, the side flip uses the frames when the car faces the generated direction and the code roll otherwise (test or scripted run). (QA: pass) ROLL_SHEETS loads car_roll (direction_frame 12); trick tests cover frames for 12 and code roll for others; screenshot C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/a8ab9cc1-7909-4212-a234-159640b92962/scratchpad/flip_qa.png taken from trick_flip_demo.tscn (agent's copy art-archive/T-153/screenshot_flip_in_scene.png).
- [ ] `docs/visual-style.md` and `game/README.md` record the new frames. All three test sets pass. (QA: pass) Both docs record the frames. GUT 869/869 (76 scripts), game/tools python 281 OK, tools python 182 OK.

The board's review: judge the roll in the trick prototype, with T-151 and T-152 (one playtest build).
Board review files: the new frames under game/art/car/ (listed in the result notes).

## Updates

### 2026-10-16, Open → In progress

Started: the Asset Generation Agent plans the PixelLab roll frames (one direction), writes the cost first, then generates one round.

### 2026-10-16, In progress

Roll frames made: 8 frames for the car's start direction (nose up-right). PixelLab cost 2 generations (planned 1). Honest read: it reads as a tip, roll onto the side and roof, and back, but it's more of a tumble than a clean barrel roll and there may be a small pop at the end. It goes into the prototype once T-151 is ready.

### 2026-10-16, In QA

Roll frames are in the flip (lined up with the car's size and place to cut the pop at the end); no new PixelLab calls, 2 generations in all. QA is checking it now.

### 2026-10-16, Needs playtest

Ready to play in one build: open C:\solid-carbide-worktrees\playtest-tricks\game\project.godot, open scenes/trick_prototype/trick_prototype.tscn and press F6. Arrow keys Up, Right, Down, Left for the side flip.

## Result notes

### Plan before calling PixelLab (Asset Generation Agent, 2026-10-16)

- Direction: the drift prototype starts the car at `rotation = -PI / 2` (`game/scripts/driving/car_model.gd`), world heading 270 degrees = frame 12 of `car_iso.png` (nose drawn pointing up-right on screen, PixelLab north-east). T-151 is not on this branch; if it changes the start heading this must be redone.
- Call 1 (the only one): `/animate-with-text-v3`, first frame = frame 12 of `game/art/car/car_iso.png` (128 x 128, saved as `art-archive/T-153/first_frame_car_iso_12.png`), `frame_count` 8, `no_background` true, seed 153001, request in `art-archive/T-153/roll_req.json`. Output about 9 images (the first frame plus 8), from which 6 to 8 game frames are picked.
- Cost: 1 generation (earlier animate-with-text-v3 calls were charged 1.0 each). Balance before: 4898 of 5000 generations. HTTP timeout 600 s. No retries; a weak result is reported, not regenerated.
- Free script steps afterwards: palette match to the car's palette (CIELAB nearest, like T-101), strip semi-transparent pixels, centre each frame on the car's centre (64.5, 65.5).

### Phase one result (generation only; swap-in not done; status not moved)

- **Call record:** 1 call, `/animate-with-text-v3`, seed 153001, 128 x 128 first frame (car_iso frame 12), 8 frames asked, 9 images returned (`art-archive/T-153/roll/`, each with its record JSON; request `art-archive/T-153/roll_req.json`; also in `game/art/pixellab-generation-log.jsonl`). **Cost: 2 generations** (balance 4898 before, 4896 after; the plan said 1, the call was charged 2). No retries.
- **Direction:** world heading 270 degrees (the drift prototype's `rotation = -PI / 2`), `car_iso.png` frame 12, nose up-right on screen. T-151 not on this branch.
- **Game-ready frames:** `game/art/car/car_roll_ne_0.png` to `car_roll_ne_7.png` (128 x 128, transparent, 8 frames) and `game/art/car/car_roll_ne.json`. Made from raw frames 1 to 8 by `python game/tools/build_car_roll.py` (alpha cut, palette mapped to the car's 33 colours, no moves; tests `game/tools/test_build_car_roll.py`). Raw frame 0 (a copy of the start) is left out: the game should draw car_iso frame 12 before frame 0 and after frame 7. Previews: `art-archive/T-153/review_roll_dark.png`, `review_roll_light.png`.
- **Quality (honest):** the sequence reads as the car tipping over to its right, standing on its side, going upside down (underside, axles visible) and coming back, and the paint, stripes and palette match. It is not a clean barrel roll: the middle frames look more like the car tumbling and turning on screen, the car shrinks and shifts a few pixels between frames, and the upright end frame differs slightly from the real sprite (a few pixels higher/shorter), so a small pop at the end is possible. No shadow, no background. The board should judge it in motion.

### Phase two result (swap-in)

- `game/art/car/car_roll.png` + `car_roll.json` built by `python game/tools/build_car_roll.py`: 9 frames (car_iso frame 12 first, then the 8 roll frames centred by whole pixels on `center_px` 64.5, 65.5; `px_per_unit` 32; `direction_frame` 12). T-151's `TrickPrototype.ROLL_SHEETS` loads it, no code change. The `car_roll_ne_*.png` frames are kept. No new PixelLab calls (total 2 generations).
- One existing test changed: `test_other_directions_keep_the_code_roll` now clears `flip.roll_frames` first, because the real sheet now covers the start direction.
- In-scene check: screenshots of `trick_flip_demo.tscn` at frames 3 to 32 show the upright car, then the roll frames playing at the car's size and place (`art-archive/T-153/screenshot_flip_in_scene.png`). The start/end pop is reduced by the centring but not measured in motion; the board judges it.
- Tests: GUT 869 of 869 passing (76 scripts); `game/tools` python tests OK; `tools` python tests OK (182).
- Documents updated: docs/visual-style.md, game/README.md.
- 2026-10-19, needs-playtest → cancelled: Board, 2026-10-19: building the trick prototype before an elevation system was a mistake. Not merged; kept as the reference for rebuilding the tricks on real height (Drifting, Content, 'Trick prototype (reference)'); code on the branch hold/trick-prototype, art in art-archive/.
