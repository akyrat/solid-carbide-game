---
id: T-068
title: Art: the minion (light green lizard), walking
status: in-progress
from: project-lead
to: asset-generation
lead: Enemies
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-044]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-003-pixellab-test-generation.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/enemies.md, tasks/T-044-minions.md]
files_expected_to_change: [art files under game/art/ and their records, the scenes that used the placeholders, game/README.md]
model: sonnet
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

**Blocked until T-044 (the minions, with placeholders) is done.**

**The board's review of the sample (board, 2026-10-14):** the board likes the sample lizard (`art-archive/T-068/raw/minion_se_sample.png`): keep it, colours and all, as the base for everything. It wants it walking on all fours, animated, in 8 directions (5 drawn, 3 mirrored), with **7 walk frames** per direction instead of 4. Next step, with the board's go: the 8 rotations from the sample plus the 7-frame walk in one direction, for the board's review (about 9 generations). Only after the board approves that: the walk in the other 4 drawn directions (about 28 more), then into the game for a playtest. The sample-round "one round only" rule is replaced by these steps; report problems rather than regenerating, unless the board says so.

The MVP minion, as Visual style, Decisions describes it: a light green (not too bright) scaled lizard walking on four legs towards the player. Propose how many directions and walk frames it needs. Swap it in for T-044's placeholder, facing the way it walks.

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. Real-world things are inspiration only: no real logos, no copies of existing characters. Details the docs leave open (directions, frame counts, variants, sizes) are this agent's proposal, written in the result notes for the board to judge (Visual style, Decisions).

Use the existing client, `game/tools/pixellab_client.py`. Record every call with its prompt, settings and cost, and the balance before and after. One round of generation only: don't regenerate; report problems instead. The board judges the result.

This art task swaps its art in for the placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass / fail)
- [ ] A screenshot of a run shows the final minions walking towards the car, facing the way they move (QA: pass / fail)
- [ ] T-044's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the look. One round only, so problems are reported rather than regenerated.

## Result notes

Written by the Asset Generation Agent (2026-10-14). Round 1: SAMPLE ONLY; the board reviews it before the full set.

### Proposal (for the board to judge)

- **Size:** 48 by 48 pixel frames. At 32 art pixels per unit and scale 0.5 the minion is about 1 unit (the car's width) across, so the body is about 30 to 36 art pixels long and fits in 48.
- **Directions:** 8 directions (the 4 screen axes and 4 diagonals) built from **5 drawn** ones: south, south-east, east, north-east, north. The other three (south-west, west, north-west) are mirrors, made by flipping in the game or a free script. A lizard is symmetric, so mirroring is safe.
- **Walk frames:** 4 per direction (two leg-pair swings and two mid-stance frames), looped at about 8 frames per second. 5 x 4 = 20 drawn frames, 32 with mirrors.
- **Method:** the board approves the sample (south-east, one frame). Then one call to /generate-8-rotations-v3 from it gives the other directions of the standing pose; then walk frames per direction by /create-image-pixflux with the approved frame as `color_image`/init image (one call per frame). Check script on each, and free palette reduction if over 30 colours.
- **Planned full set calls and cost (estimate, 1 generation each unless noted):** 1 rotations call (about 2 generations, as the car's was) + 19 pixflux frames (19 generations) = about 21 generations, of the plan's 5000 (usd credits stay 0). Walk-frame consistency may need more; the board decides then.

### Sample: planned call and cost

- 1 call, /create-image-pixflux, 48x48, south-east, view "high top-down" with isometric true, outline "selective outline", shading "detailed shading", detail "highly detailed", no_background, seed 68001. Params file: art-archive/T-068/sample_req.json. Planned cost: 1 generation.

### Sample: result

- Call: /create-image-pixflux, params art-archive/T-068/sample_req.json (prompt and settings inside; record art-archive/T-068/raw/minion_se_sample.json; logged in game/art/pixellab-generation-log.jsonl). Cost 1 generation. Balance before 4919 of 5000, after 4918. One call only.
- File: art-archive/T-068/raw/minion_se_sample.png (48x48). Check script (game/tools/check_sprite_rules.py --size 48): all pass, 21 colours, 0 semi-transparent pixels, transparent corners. No fix needed.
- Review images: art-archive/T-068/sample_review_dark.png, sample_review_light.png, sample_review_dark_light_vs_placeholder.png (8x nearest; the placeholder is cropped from T-044's screenshot, so at the screenshot's scale).
- Problems seen (reported, not regenerated): the green is a saturated yellow-lime, brighter than "light green, not too bright"; it looks like it is rearing on two legs and a front arm, so the four-legged walk does not read; there is no dark selective outline; it faces west-south-west more than south-east. Cheapest next step: a free palette shift towards a softer green, or one more sample with a rewritten prompt, on the board's say-so.

### Round 2 (board go, about 9 generations): plan before calling

- Call A: /generate-8-rotations-v3 from the approved sample (params art-archive/T-068/rot_req.json, seed 68002). About 2 generations (the car's call cost 2).
- Call B: /animate-with-text-v3 (the endpoint made for consistent frames from one reference frame, with colour de-flicker), first_frame = the chosen direction's rotation, action "walking forward on all four legs", frame_count 8. The endpoint only takes even counts of 4 to 16, so 7 is impossible: I ask for 8 and deliver 7 of them (the board can ask for the eighth) or all 8, said in the results. Cost unknown, estimated up to 7 generations. The client got this endpoint added (a table row, game/tools/pixellab_client.py).
- No regeneration. Free script fixes only.

### Round 2: results (2026-10-14)

- **Call A, /generate-8-rotations-v3** (art-archive/T-068/rot_req.json, seed 68002; prompt "a light green scaled lizard walking on four legs, long tail, small head with a glowing cyan eye, lighter green belly, isometric pixel art game sprite, same camera and same size in every direction", no_background). Cost 1 generation (the record says so). Balance before 4917, after 4916 (other agents share the account, so the balance can move for other reasons). Files: art-archive/T-068/rotations/minion_rot8_0..7.png. The call gives the 8 images unlabelled; from the pictures, 0 is the sample's pose, 3 is the side view facing screen-right and 7 the side view facing left. I did not rely on the order beyond that.
- **Call B, /animate-with-text-v3**, first frame rotations/minion_rot8_3.png (the side view: all four legs and the tail show best), action "walking forward on all four legs, a steady lizard walk cycle, legs alternating diagonally, body low, tail swaying", frame_count 8, seed 68003, no_background (art-archive/T-068/walk_req.json). The endpoint only takes even counts (4 to 16), and returned **9 frames** (the first frame plus 8), not 8: art-archive/T-068/walk_side_run1/minion_walk_0..8.png. Cost 1 generation (record). Balance before 4916, after 4915. Review shows frames 0 to 6 as the 7-frame cycle; 7 and 8 are kept.
- **Run problem:** the first launch of call B ran into the shell's 2-minute limit, looked as if it had died (no log line, balance unchanged), so I launched it once more; the first one then turned out to have finished too. The log holds one entry for it and the balance fell by one only, so I believe only one call was charged, but a second submission cannot be fully ruled out. Check the PixelLab usage if it matters.
- **Check script (48x48):** all 8 rotations and all 9 walk frames pass: transparent background, no semi-transparent pixels, 17 to 25 colours. No fixes needed.
- **Review images** (6x or 8x nearest, dark and light, in art-archive/T-068/): review_rotations_row_*.png, review_walk7_row_*.png, review_walk_all9_row_*.png, review_walk7_dark.gif, review_walk7_light.gif (7 frames, 8 per second).
- **Problems:** the half-reared sample pose carries over: in the side view the legs read as short stubs with the front pair tucked, and the walk shows little leg motion (mostly body and tail sway), so it reads as a trot or glide more than a four-legged stride. The 7-frame request cannot be met exactly; the endpoint gave 9 and 7 of them are used for review. Rotation 4 and 5 (back views) are the weakest, with a thin body. Not regenerated.

### Round 2 follow-up: the duplicate walk call (2026-10-14)

- The second launch of call B finished too: job 9af40744-ff4e-4dc7-ab43-bbdfd5dadae5 (the first was 9586d614-d6c7-42be-9f66-68209a824479). **It cost a second generation**: balance 4915 before it finished, **4914 after** (usage 1.0 in its record; both are in the generation log). Total for round 2: 3 generations (rotations 1, walk 2), about the board's 9 budget.
- Same request, same seed (68003). Its 9 frames are identical to the first run's in 2 of 9 files; the second run overwrote the first's files in walk_side, so the first run's were restored from git. Both sets are kept: art-archive/T-068/walk_side_run1/ (first run) and walk_side_run2/ (second run, passes the check script). The records inside each still say out_dir "walk_side". Review image of run 2: review_walk_run2_all9_row_dark.png and _light.png. The earlier review images show the first run.
- Cause: the shell's 2-minute limit moved the call to the background, I took the missing output for a dead call and relaunched. From now on: a shell timeout of 600 s or more, and never relaunch a call that may still run.

### Round 3: one more walk generation (board go, 2026-10-14). Plan before calling

- 1 call, /animate-with-text-v3, same base (rotations/minion_rot8_3.png), frame_count 8 (the endpoint returns 9 frames; the first 8 are the cycle, the 9th is kept), seed 68004, no_background, HTTP timeout 600 s, run in the background and waited for, never relaunched. Params: art-archive/T-068/walk2_req.json; the action text is the new prompt (low stride, belly close to the ground, diagonal gait, legs lifting and planting, no rearing, no gliding). Estimated cost: 1 generation (the earlier two calls each cost 1). Balance before: 4914 as last read.

### Round 3: result

- No other call was running before it (checked). One call, job 616558a6-4fb6-4c48-80e0-a9306504b8cc, seed 68004, params art-archive/T-068/walk2_req.json (prompt = its `action` text), HTTP timeout 600 s, run in the background and waited for. Cost 1 generation. Balance before 4914, after 4913. Logged in game/art/pixellab-generation-log.jsonl.
- Files: art-archive/T-068/walk_low_stride/minion_walk_low_0..8.png (9 frames; frames 0 to 7 are the 8-frame cycle, 8 is kept). Check script: all 9 pass (23 to 26 colours, no semi-transparent pixels).
- Review images (art-archive/T-068/): review_walk_low_vs_previous_dark.png and _light.png (top row the new walk, bottom row the previous walk, run 1) and review_walk_low_vs_previous_dark.gif and _light.gif (new walk on the left, previous on the right, 8 frames per second).
- Honest view: it reads more four-legged than before: the body sits lower and more level, and in most frames all four legs show, with the pairs changing position. But the legs are still short and thin next to the body (the sample's proportions), the lift-and-plant is small (a pixel or two of travel), and it still looks like a trot with a lot of body sway. Two glitches: frames 4 and 5 have the eye going dark and frame 4 has a stray yellow pixel under the head. Not regenerated; the stray pixel and the eye could be fixed by a free script if the board likes the rest.

### Round 4: the board chose the low-stride walk (option 1). Plan before calling

- Base: walk_low_stride frames 0 to 7 for the east-facing direction (rotation 3). Free fixes first (tools/fix_minion_frames.py): the dark eye in frames 4 and 5 and the stray bright pixels under the head in frame 4.
- Rotation order, read from the pictures (the call returns them unlabelled): 0 SW, 1 S, 2 SE, 3 E, 4 NE, 5 N, 6 NW, 7 W (a turn through the compass). Drawn: S, SE, E, NE, N. Mirrored in the game: SW from SE, W from E, NW from NE.
- 4 calls, one at a time, each in the background and waited for, never relaunched: /animate-with-text-v3 with the same `action` text, frame_count 8, no_background and 600 s HTTP timeout as the low-stride walk, only the first_frame changes: rotation 1 (S, seed 68004), rotation 2 (SE), rotation 4 (NE), rotation 5 (N), all with seed 68004. Params: art-archive/T-068/walk_{s,se,ne,n}_req.json. Each returns 9 frames; the first 8 are used. Cost estimate 1 generation each, 4 in all (the earlier walk calls cost 1 each). Balance before: 4913.

### Round 4: results (2026-10-14)

- **Free fixes** (game/tools/fix_minion_frames.py, tested): east walk (walk_low_stride, now walk_e_fixed/): the dark eye in frames 4 and 5 patched from frame 3, the stray bright pixels under the head in frame 4 recoloured. The S, SE, NE and N walks showed no such glitches on inspection and are used as generated (copied to walk_*_fixed/).
- **Calls** (all /animate-with-text-v3, the low-stride action text, frame_count 8, seed 68004, no_background, 600 s timeout, in the background, one at a time): S (rotation 1), job 3dae2a9f, 1 generation, balance 4913 to 4912; SE (rotation 2), job 1b81c2a2, 1 generation, 4912 to 4911 (the session was cut off by a usage limit during these two; both finished and were saved); NE (rotation 4), 1 generation, 4911 to 4910; N (rotation 5), 1 generation, 4910 to 4909. Total round 4: 4 generations. Params walk_{s,se,ne,n}_req.json; records in each walk_* folder and in the generation log. Total T-068 spend: 9 generations (4918 at the start of round 2... 1 sample, 1 rotations, 3 walks, 4 directions; balance 4919 at the very start, 4909 now).
- **Check script:** every frame of every direction passes (transparent, no semi-transparent pixels, 17 to 26 colours); the five game sheets pass with --frames 8.
- **In the game:** game/art/minion/minion_{s,se,e,ne,n}.png and scripts/enemies/minion_sprite.gd (only that script changed among enemy scripts; no behaviour change): direction from the way it walks (compass_index), mirrors for SW, W, NW, 8 frames at 10 per second, scale 0.5, paused with the tree. New tests tests/unit/enemies/test_minion_sprite.gd. T-044's tests pass.
- **Tests:** full GUT suite 584 of 584 passing (before the one-constant LIFT tweak 3 to 5); all Python tool tests 246 OK (1 skipped).
- **Screenshot:** art-archive/T-068/screenshot_minions.png (minions around the car, facing the way they walk). Review images: review_all8_directions_dark/light .gif and .png (all 8 directions animated), and earlier ones.
- **Honest notes:** the walk is a lively trot with short legs; the S view's body turns a little. N view's head turns slightly. Mirrors make the SW/W/NW lizards face the same way light falls reversed; judged in a playtest.
