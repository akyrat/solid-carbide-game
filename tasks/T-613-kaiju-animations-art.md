---
id: T-613
title: Art for the kaiju's walk, windup and death animations
status: flagged-for-review
from: project-lead
to: asset-generation
lead: Polish
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/visual-style.md, docs/enemies.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/enemies.md, game/docs/enemies/kaiju.md, tasks/T-612-kaiju-animations.md, tasks/T-544-minion-death-art-full-set.md]
files_expected_to_change: [game/art/kaiju/, game/art/pixellab-generation-log.jsonl, art-archive/T-613/, game/data/enemies.json, game/tests/, game/docs/, docs/visual-style.md, docs/enemies.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Make the final art for Visual style, Decisions, "The kaiju's animations" (board, 2026-11-09) and swap it in for T-612's placeholder frames.

Three animations (walk cycle, meteor windup, death), each in the kaiju's five drawn directions (e, n, ne, s, se; the others are mirrored by the game): 15 animations. Generate them through PixelLab from the kaiju's current sprites (`game/art/kaiju/`) so it stays the same monster, in the frame format T-612 wrote in `game/docs/enemies/kaiju.md` (files, frame size, anchor); frame counts and speeds are numbers in `game/data/enemies.json` that you may change to fit the art.

Start now, in two steps (board, 2026-11-09: "start the art now, don't wait for the placeholder playtest"; the dependency on T-612 was removed for this). Step 1, now: generate the 15 animations from the current sprites, at the sprites' own frame size and anchor, through the style loop, and keep the game-ready frames and the contact sheets on this branch; T-612's code and frame format are not on this branch yet (T-612 is still being built in C:\solid-carbide-worktrees\T-612, which you may read but never change). Then hand back, saying step 1 is done. Step 2, when the Project Lead resumes you after T-612 is ready: bring T-612's work into this branch, fit the frames to its frame format with free script work (no new generations for that), swap them in for the placeholders, and take the in-game recordings. This ticket merges after T-612.

New budget (board, 2026-11-09, after the agent stopped: an animation call at 224 px costs 5 PixelLab units, 10 units spent on walk east). This replaces the PixelLab paragraph below and the "60 generations" in the criteria. Sample first: one animation, the windup facing east, through the style loop, at most 4 calls and 20 units. Then stop and hand back for the board's review of the sample; no other call until the board's go. The scope stays all three animations (a new walk too, replacing the one the kaiju has), but the rest of the set and its budget wait for that go. Hold the kaiju's look (dark slate hide, lighter belly, eyes, back plates): try free fixes (palette mapping to the still sprite's colours) before paying for a refine.

PixelLab (replaced by the paragraph above): the board gave its go for the full set, with no sample review (2026-11-09). Every animation goes through the style loop (tasks/README.md, "The style loop"): at most 3 refines each, so at most 4 generations per animation and at most 60 for the ticket. Nothing beyond that without the board's say-so. Write your planned calls and their cost in the result notes before the first call. Free script fixes (cropping, aligning, palette, mirroring) come before paid generations. Use a 600 s HTTP timeout: timed-out calls are still charged. An animation that stays below 8 after its refines keeps its best version and is listed in the result notes for the board.

Never delete art: the game-ready frames go in `game/art/kaiju/`, every raw generation in `art-archive/T-613/`, and T-612's placeholder frames move to `art-archive/T-613/` when yours replace them. The five still sprites stay. Add a section to Visual style, Content, on the set, and point Enemies, Content, "The kaiju", Look, at it.

The board's review: play it from C:\solid-carbide-worktrees\T-613\game\project.godot: reach the kaiju, watch it walk, wind up before its meteors and die, with the final art; the contact sheets and recordings are in art-archive/T-613/screenshots/.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes list the planned PixelLab calls and their cost, written before the first call, and the calls made: at most 4 generations per animation and at most 60 in all, each with a line in `game/art/pixellab-generation-log.jsonl`. (QA: pass / fail)
- [ ] Each of the 15 animations (walk, windup, death in e, n, ne, s, se) has an entry in the ticket's Style review with its score; any below 8 after its refines is listed in the result notes. (QA: pass / fail)
- [ ] The frames in `game/art/kaiju/` match the frame format in `game/docs/enemies/kaiju.md` (a test or a script check of file names, frame size and counts against `game/data/enemies.json`), and the game's kaiju tests pass with them. (QA: pass / fail)
- [ ] In the game the kaiju shows the final art for all three animations and no placeholder frame: recordings (one GIF each of the walk, the windup and the death, in the game) in art-archive/T-613/screenshots/. (QA: pass / fail)
- [ ] Contact sheets in art-archive/T-613/screenshots/: for each animation, its frames in the five directions beside the current still sprite, enlarged nearest-neighbour, on a dark and a light background. (QA: pass / fail)
- [ ] No art was deleted: every raw generation and T-612's placeholder frames are in art-archive/T-613/, and the five still sprites are still in `game/art/kaiju/`. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Every document in documents_affected is updated, and the proposals made for the playtest are listed in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-09, Open → Blocked

Waiting for T-612: the art is made in the frame format T-612 defines, then swapped in. The board's go for the full set (up to 60 generations) is recorded on the ticket.

### 2026-11-09, Blocked → In progress

Started on the board's word: the Asset Generation Agent is generating the kaiju's walk, windup and death art now (up to 60 generations), without waiting for T-612's placeholder playtest. The swap into the game follows once T-612 is ready.

### 2026-11-09, Flagged for review

Stopped on a cost question for the board: a 224 px animation call costs 5 PixelLab units, not 1. 10 units spent on walk east (best 7/10, look drifts). Waiting for the board's budget and scope before any further call.

## Style review

Run by `tools/style_loop/run.py` on 2026-11-09: art, brief `art-archive/T-613/brief_walk_e.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: `art-archive/T-613/style-loop/v1.png`
- Script checks: 31 of 31 pass
- Score: 6/10
- Reason: The script checks all pass: size, alpha, 30 colours, no Greenbull colours. No rule 6, 7 or 8 problems. The art is pixel art with a dark outline and a cyan plate palette, so rules 1 and 2 are largely met. The problems are rule 10 (the kaiju keeps its look) and the loop/motion brief.

1. Identity drifts between frames. The tail changes shape: it is thick with a big curl in frames 0-2, then thin with a small curl in frames 3-5. The leg and foot designs change from frame to frame: the foot is a clear 3-toed claw in frames 0-1, but in frames 3-4 it is a vague blob, and in frame 5 the leg is a stiff straight column. Frame 5 looks like a different pose model.
2. The loop does not close. Frame 5 (straight, extended leg, thin tail) is far from frame 0 (bent leg, thick tail), so the last frame does not lead back into the first.
3. It does not read as a heavy stride. In most frames both feet seem planted close together, and the arms flip between shapes (fist, claw), so there is no clear lift-and-plant.
4. The glowing yellow eyes are barely visible, and the hide reads more teal than slate-green. Check both against the still.

Fix: use the free --pick and --hold options to choose frames with a consistent tail and foot, or refine with an action text that fixes the tail and leg shapes and a clear pose that returns to frame 0.
- Rules broken: 10
- Refused: {"tool_input": {"command": "mkdir -p art-archive/T-613/style-loop && [ ! -e art-archive/T-613/style-loop/v1.png ] && python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-613/kaiju_walk_e_v1.png').convert('RGBA'); im.save('art-archive/T-613/style-loop/v1.png')\na=set(im.getdata(3)); print(im.size, im.mode, a, len(set(im.getdata())))\"", "description": "Save the built sheet as style loop version 1 and verify it"}, "tool_name": "Bash", "tool_use_id": "toolu_01CPZfHg2RDc6ejr1yY62Avw"}

### Round 2

- Version 2: `art-archive/T-613/style-loop/v2.png`
- What changed: Version 2: a free script fix, no new PixelLab call (still 1 of 4 used). Rebuilt the sheet with --pick from the v1 raw frames only, in the order raw 0 (the still itself), 1, 2, 3, 2, 1, with --align. This drops the three frames that drifted (thin tail with a small curl, blob foot, the stiff straight leg), so the tail keeps its thick shape and big curl and the feet keep their three-toed claws in all 6 frames, and the monster matches the still exactly in frame 0. The loop now closes: the last frame is one step from the first. Colours are the still's own 30 (the hide and eye colours are the still's palette, unchanged). Weak point, honestly: the motion is a there-and-back step (the far leg steps forward and returns, the tail lifts and settles, the arm swings), not a full two-leg alternating stride; if that is not enough, the next step is a paid refine with an action text that pins the tail and foot shapes and asks for a wider stride returning to the first pose. Preview: art-archive/T-613/screenshots/walk_e_v2a_pick; same sheet also at art-archive/T-613/kaiju_walk_e_v2a_pick.png.
- Script checks: 31 of 31 pass
- Score: 7/10
- Reason: The sheet follows the art rules. It keeps the still's palette and bold dark outline, with pale cyan plates, hard pixel edges, a transparent background and no shadow, effects or Greenbull colours. The script checks all pass. The monster reads as the same Godzilla-style kaiju in side view, so rules 1, 2, 3, 5, 6 and 9 are met. Problems to fix, mostly under rule 10 (the subject keeps its look, which the brief's loop and motion requirements extend):
1. Frame 5 has exactly the same opaque pixel count as frame 0 (17099), and frame 4 matches frame 2 (17579). These look like duplicated frames. A duplicate of frame 0 at the end makes the loop hitch, because frame 0 shows twice in a row. Pick or build a distinct last frame that leads into frame 0, and avoid repeats unless a hold is intended.
2. The stride is weak. The legs barely change between frames, and the lifted foot and planted foot are hard to tell apart. Only the tail curl, the arm and the plate positions shift slightly. Make one foot clearly lift and plant in each half of the cycle.
3. The hide looks more teal than the brief's slate-green. This is probably the still's own snapped palette, so check it against the still rather than treating it as a new error.
- Rules broken: 10
- Refused: {"tool_input": {"command": "R=art-archive/T-613/raw_walk_e_v1 && python game/tools/build_kaiju_anim_sheet.py e $R walk_e art-archive/T-613/kaiju_walk_e_v2a_pick.png --count 6 --align --pick $R:0,$R:1,$R:2,$R:3,$R:2,$R:1 --preview-dir art-archive/T-613/screenshots/walk_e_v2a_pick --scale 3", "description": "Build a free ping-pong pick of the consistent v1 frames"}, "tool_name": "Bash", "tool_use_id": "toolu_01MQCnrzuH17bk2dQ14jGain"}

### Round 3

- Version 3: `art-archive/T-613/style-loop/v3.png`
- What changed: Version 3: a paid refine, since the free picks from one raw set could not give a real stride (PixelLab call 2 of 4 for this animation, seed 2, new action text art-archive/T-613/action_walk_e_v2.txt; raw frames in art-archive/T-613/raw_walk_e_v2; 2 lines for T-613 in the generation log). The new action text asks for a long stride with one foot clearly lifted and one planted, the tail keeping its thickness and curl, the same three-toed feet, and a last frame that flows back into the first. Built from raw images 1 to 6 with build_kaiju_anim_sheet.py --align (still's 30-colour palette, alpha 0 or 255, feet on the still's ground point). What changed against v2: six distinct frames, no duplicates; the near leg now clearly lifts (frames 2 to 4, foot off the ground under the body) and plants forward flat (frame 5), while the far foot stays planted ahead; the feet keep three clear toes in every frame; the arms swing. What stays weak, honestly: the tail is thick in frame 0 and slimmer in frames 1 to 5 (the curl stays, smaller than the still's), and the loop's close from frame 5 (near leg planted forward) back to frame 0 (near leg back) is a bigger step than the others. The hide colour is the still's own palette, unchanged. Preview: art-archive/T-613/screenshots/walk_e_v3a; same sheet at art-archive/T-613/kaiju_walk_e_v3a.png.
- Script checks: 31 of 31 pass
- Score: 6/10
- Reason: The script checks pass (rules 1, 3 and 6). The art is clean pixel art with a dark outline and the cyan dorsal plates, and it reads as the same Godzilla-style kaiju. It breaks rule 10 (the kaiju keeps its look) and, to a lesser degree, rule 2.

Rule 10, identity drift between frames:
- The hide reads as teal on the near leg and body, not the still's dark slate-green. The pale grey-green belly strip shows in frames 0-2 and nearly vanishes in frames 3-5.
- The near thigh and calf are rendered as large smooth glossy blobs in frames 3-5. They look like a different body from frames 0-1, where the legs are thin and angular.
- The tail curl, the leg proportions and the arm shape change from frame to frame.
- The far leg and far arm turn into dark, near-black silhouette blobs in frames 1-5, with the foot or hand detail lost.
- The yellow eyes barely read at this size.

Loop and motion:
- The feet do not plant convincingly. Frame 0 has the feet at the lower left and frame 5 has one foot far right, at the bottom edge. Between them the feet jump about 25 px. Check that the last frame leads back into frame 0 without a pop.
- The stride is not a clear lift and plant. Frames 3-5 look almost like the same pose with the foot sliding.

Rule 2, detail and shading:
- The outline breaks where the dark far limbs merge into the body, so the shading there is flat and muddy.

Fixes, free script first: use --pick to take the frames where the near leg keeps the angular shaded look and the belly strip is visible, and choose frames whose feet sit at consistent ground points so the loop closes. If a refine is needed, add to the action file: "keep the pale belly strip and the far leg and arm drawn in the same shading as the near ones, not black".
- Rules broken: 10, 2

### Round 4

- Version 4: `art-archive/T-613/style-loop/v4.png`
- What changed: Version 4: a free script fix, no new PixelLab call (2 of 4 calls used for this animation, 10 generation units). Rebuilt with --pick, joining only the frames from both raw sets where the near leg keeps the still's angular shaded look and the belly strip shows, and dropping every frame with the glossy blob thigh, the stiff straight leg or the foot at the far right. Order: the still itself (v1 raw 0), v2 raw 1 (far foot lifts), v1 raw 2 (far foot planted forward), v1 raw 3 (near foot pushes off on its toes), v2 raw 3 (near foot lifted), v2 raw 2 (near foot coming back down), then back to the still. Six distinct frames, no duplicates; the feet stay at the still's ground point in every frame (no 25 px jump), so the loop closes on the still without a pop. Built without --align this time: these frames already sit where the still sits, and the block shift pushed the head against the right edge of the frame. Palette is the still's own 30 colours, alpha 0 or 255. What stays weak, honestly: the stride is small (a foot lifts and plants in each half, but the legs stay close together); the tail is slimmer with a smaller curl in frames 4 and 5 than in frames 0 to 3; the far leg is still dark in frames 1, 2 and 5 as PixelLab drew it; the hide and eye colours are the still's own. Preview: art-archive/T-613/screenshots/walk_e_v4b_pick; same sheet at art-archive/T-613/kaiju_walk_e_v4b_pick.png (v4a_pick is the rejected aligned build).
- Script checks: 31 of 31 pass
- Score: 7/10
- Reason: The sheet passes the script checks for rules 1, 3 and 6: 224 px frames, 30 colours, hard edges, transparent background, no Greenbull colours. The art reads as pixel art, with a dark outline, detailed segmented shading and glowing cyan dorsal plates, and it is a Godzilla-style monster that is never named (rules 2, 5, 9). Weaknesses, all rule 10 (the kaiju keeps its look): (1) the lighter grey-green belly is mostly missing. Only a thin tan sliver shows, and the body reads as uniformly dark teal, which is more teal than the 'dark slate-green' hide in the brief. Restore the belly's light grey-green band. (2) The glowing yellow eyes are not clearly visible at this size. Make sure the eye pixels are bright yellow with a small stepped halo (rule 5). (3) The walk is hard to read. The second leg is hidden or merged into the first in several frames (2, 3 and 5), so the foot lift and plant is weak, and the stride is mostly the tail and arms moving. Frames 0 and 1 are close to each other. Show two distinct legs, one lifting and one planting, and add a clearer body sway. (4) The frame 5 to 0 loop seam looks fine. A small dark blob near the foot or arm in frames 2 to 4 reads as a stray shadow-like clump. Clean it up.
- Rules broken: 10

**Kept:** version 2, score 7/10 (`art-archive/T-613/style-loop/v2.png`, copied to `art-archive/T-613/final/kaiju_walk_e.png`): still below 8 after 3 refines, so the task is flagged for the board's review.

## Result notes

Step 1, planned PixelLab calls (written before the first call): 15 animations (walk 6 frames, windup 6, death 8; each in e, n, ne, s, se), each from frame 0 of the still sprite (224 x 224) with /animate-with-text-v3, through tools/style_loop/run.py art, one at a time. Minimum 15 calls (1 per animation), at most 4 per animation (1 + 3 refines), at most 60 calls in all; refines only for scores below 8, free script fixes first (game/tools/build_kaiju_anim_sheet.py: palette snap, alpha, feet alignment, hold). Cost: the T-069 kaiju walk calls at this size cost 5.0 PixelLab generation units each (a 6-frame 224 x 224 call), against 1.0 for T-544's 48 x 48 minion; I count the board's 'generation' as one call (4 per animation, 60 in all, as the ticket's 15 x 4) and record the units used. If a call costs 5 units, 15 calls = 75 units and 60 calls = 300 units (balance before: 4882 of 5000). Briefs, action texts and reference frames: art-archive/T-613/.
- 2026-11-09, in-progress → flagged-for-review: the style loop kept version 2 (score 7/10), still below 8 after 3 refines; every version is in its Style review

Step 1 STOPPED after 1 of 15 animations (walk, east), for a cost question. Calls made: 2 (walk_e v1 and v2, 5.0 generation units each = 10 units; balance 4882 -> 4872), both logged. Style loop: 4 rounds, scores 6, 7, 6, 7; kept v2 (7/10, a free ping-pong pick of v1 frames) in art-archive/T-613/final/kaiju_walk_e.png; below 8, so the loop moved the ticket to flagged-for-review (not a goal run). Findings: a 224 x 224 animate-with-text-v3 call costs 5 units, not 1; at that rate the 15 animations need at least 75 units and up to 300, against the ticket's 60. I read 'generation' as one call, but a board that meant units would be over budget already after one animation. Also each loop run takes about 7 minutes and PixelLab drifts the kaiju's identity (teal hide, lost belly and eyes, blob legs), so more animations will likely end near 7 too. Not done: the other 14 animations, contact sheets, GIFs, docs. Tools committed: game/tools/build_kaiju_anim_sheet.py (+ test), make_kaiju_anim_briefs.py; briefs in art-archive/T-613/. Need from the Project Lead: confirm the unit budget (calls vs units), and move the ticket back to in-progress.
