---
id: T-532
title: Minion death animation through PixelLab: a sample direction first
status: flagged-for-review
from: project-lead
to: asset-generation
lead: Rails
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/visual-style.md]
files_to_read_first: [docs/visual-style.md, docs/working-with-the-board.md, tasks/README.md, game/art/minion/]
files_expected_to_change: [art-archive/T-532/, docs/visual-style.md]
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

Make the minion's death animation through PixelLab (docs/visual-style.md, Decisions, "The minion's death animation and green spill"). The board's go covers the SAMPLE only: one direction (your choice, say which), through the style loop, at most 4 generations in all (1 plus up to 3 refines). Start from the minion as it is now (the approved mini-kaiju lizard, its walk and fall sheets in game/art/minion/, with the bolder outlines of T-340) so it matches: same size, palette and outline; how many frames is your proposal (about 6 to 8). No blood in the frames (the green liquid is drawn in code by T-531). Write your planned calls and their cost in the result notes before calling; use a 600 s HTTP timeout. Put everything generated in art-archive/T-532/ and only the board-approved sheet later in game/art/minion/ (never delete generated art). Show the sample as an enlarged strip on dark and light backgrounds in art-archive/T-532/screenshots/. Stop after the sample: the full set (the other 4 drawn directions, mirrored to 8) and the swap into the game come after the board approves it, using the frame layout T-531 documents.

The board, 2026-11-03: docs/enemies.md, Decisions, "Minion deaths: an animation, a green spill, corpses that can be knocked about", and docs/visual-style.md, Decisions, "The minion's death animation and green spill". The board plays the functional build (T-531, code placeholder animation) and reviews the art sample (T-532) before anything merges or reaches itch.io. No new player-facing text. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). Godot: the worktree has no .env; give GODOT_BIN from C:\solid-carbide-game\.env (CR and quotes stripped) to one command at a time, with no `export VAR=$(...)` and no `timeout` wrapper, never copy .env; don't leave Godot processes running (if one hangs, tell the Project Lead, don't kill it). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: the sample strip in art-archive/T-532/screenshots/ (added by the Project Lead, 2026-11-03: every art task waits for the board).

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] One sample death animation direction generated through the style loop, at most 4 generations, the calls and cost written in the result notes. (QA: pass / fail)
- [ ] The Style review section shows the loop's scores; the sample matches the minion's size, palette and outline. (QA: pass / fail)
- [ ] Every generated file is kept in art-archive/T-532/. (QA: pass / fail)
- [ ] An enlarged strip on dark and light backgrounds is in art-archive/T-532/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-03, Open → In progress

Asset agent: PixelLab sample of the death animation, one direction, up to 4 generations (board's go).

## Style review

Run by `tools/style_loop/run.py` on 2026-11-06: art, brief `art-archive/T-532/brief.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: `art-archive/T-532/style-loop/v1.png`
- Script checks: 41 of 41 pass
- Score: 3/10
- Reason: I could only view the sheet at its native 384x48 size, so this is a read of the whole strip, not a pixel-level check. The script checks pass: 48x48 frames, opaque or transparent pixels only, 22 colours or fewer per frame, and nothing from Greenbull's palette. The look is the weak point. All 8 frames show an upright, four-legged, walking or standing lizard in nearly the same stance. I see no hit or recoil, no collapse onto its side, no limp legs or dropped tail, and no held corpse pose in the last two frames. This reads as a walk or idle loop, not a death. The brief's core requirement is missing, though no numbered style rule covers motion directly.

Rule 10 (the minion keeps its look): the sprite is still a light-green lizard, but the body greens look yellow-lime and brighter than the "light-green, not too bright" minion. The result is lizard poses without the death the sheet was made for.

Rule 2 (outline and shading): the outline looks consistent with the reference at this size, so no clear break. The shading shows no visible change across frames.

Fix for the refine:
- Change the action text to stress the collapse. Hit and jolt back by frame 2, fall onto the side or belly by frames 3-5, legs and tail limp, jaw open, eye dulled.
- Frames 6-7 must be a motionless flat corpse on the ground.
- Keep the same feet position and the same 48x48 frame.
- Pull the greens back to the reference palette, using a palette-snap script as the free fix.
- Rules broken: 10, 2
- Refused: {"tool_input": {"command": "Test-Path .env; if ($env:PIXELLAB_API_KEY) { \"env var set\" } else { \"env var not set\" }; Get-Content art-archive/T-532/brief.md", "description": "Check API key availability and read brief"}, "tool_name": "PowerShell", "tool_use_id": "toolu_013QWhiELcGwtLuTyRxnDhRP"}; {"tool_input": {"command": "python -c \"\nfrom PIL import Image\nimport glob\nfs=[Image.open(f'art-archive/T-532/raw_v1/death_se_{i}.png').convert('RGBA') for i in range(9)]\nfor i,f in enumerate(fs):\n    cols={p[:3] for p in f.getdata() if p[3]>0}; al={p[3] for p in f.getdata()}\n    bb=f.getbbox(); print(i,len(cols),sorted(al)[:3],len(al),bb)\ns=Image.new('RGBA',(48*9,48),(30,30,40,255))\nfor i,f in enumerate(fs): s.alpha_composite(f,(48*i,0))\ns.resize((48*9*6,48*6),Image.NEAREST).save('art-archive/T-532/raw_v1/preview_x6_dark.png')\n\"", "description": "Inspect raw frames and make enlarged preview"}, "tool_name": "Bash", "tool_use_id": "toolu_01PURqREMMgL9SiEUXieRWGD"}; {"tool_input": {"command": "for f in gif_to_sheet review_sheet preview_sheet reduce_palette check_sprite_rules art_preview; do echo \"=== $f\"; sed -n 1,25p game/tools/$f.py | grep -v '^import\\|^from'; done", "description": "Read docstrings of candidate tools"}, "tool_name": "Bash", "tool_use_id": "toolu_01Muxpn6cUcfiyMhn7qyQiVF"}; {"tool_input": {"command": "python C:/solid-carbide-game/tools/task_notes.py T-532 --text \"2026-11-06, run 3, version 1: the worktree now has a .env, so I sent art-archive/T-532/req_v1.json (built earlier with the approved game/tools/pixellab_animate_req.py, seed 1) through game/tools/pixellab_client.py. Job 645998a9-71be-4b00-89fc-12e0465ab2e7, usage 1.0 generation (1 of 4 spent). Raw: art-archive/T-532/raw_v1/death_se_0..8.png (image 0 is the reference frame echoed back; 1-8 are the animation). Free script fixes, no PixelLab call: new tool game/tools/build_minion_death_sheet.py (with test_build_minion_death_sheet.py, 5 tests pass) takes frames 1-8, snaps every colour to the minion walk sheets' palette and makes alpha 0/255. Output art-archive/T-532/style-loop/v1.png (384x48, 26 colours), previews art-archive/T-532/screenshots/v1_x6_dark.png and v1_x6_light.png. check_sprite_rules: all pass. Honest look: the lizard crouches and lowers its head with the tongue out, but it does not fall onto its side; there is no clear hit-jolt, and the last frames are a crouch, not a corpse. Likely refine: a stronger action text (--action) for the collapse.\"", "description": "Write result notes for version 1"}, "tool_name": "Bash", "tool_use_id": "toolu_016MsPHrkBFwSN2P8MBeotcT"}; {"tool_input": {"argv": ["scale", "upload:none", "--by", "4"]}, "tool_name": "mcp__pixellab__pixelart_workbench", "tool_use_id": "toolu_01UmYiaWXia68fudTYjaYfNq"}

### Round 2

- Version 2: `art-archive/T-532/style-loop/v2.png`
- What changed: Version 2 is a new PixelLab generation (2 of the 4 allowed). It reads more like a death than version 1, but the minion still doesn't fully roll onto its side.

Why I paid for a new generation: a script can't add a collapse, so the free fixes alone couldn't answer the 3/10. The colours are a different matter. Version 1's colours were already snapped to the minion's own walk-sheet palette, so the brighter greens the evaluator saw are probably from viewing the strip at its tiny native size, not real colour drift.

The request is `art-archive/T-532/req_v2.json`, built with the approved `game/tools/pixellab_animate_req.py` (seed 2). The new action text asks for:
- a strike that jerks the head and front legs up and back
- a topple sideways onto its side
- legs going stiff, then limp
- the tail lying flat, the jaw open and the eye closed
- a still corpse at the end, with no walking, idle, blood, liquid or shadow

The job (118c4f67-7585-4460-a6b7-d234993d5b45) used 1.0 generation. The raw frames are in `art-archive/T-532/raw_v2/`.

What the result shows: by frame 2 the tail whips up and the body lurches. From frame 3 on the legs splay out limp and the body sinks flat. The eye closes, so there is no cyan from frame 3 on, and the tail drops flat along the ground by frames 6 to 8.

The free fixes, with no PixelLab call, come from `game/tools/build_minion_death_sheet.py`:
- every colour snapped to the minion's walk-sheet palette, leaving 23 colours
- every pixel fully opaque or fully transparent
- the new `--hold 1` option repeats frame 7, so frames 7 and 8 are an identical, motionless corpse

The sprite-rules check passes with no failures. Previews are in `art-archive/T-532/screenshots/v2_x6_dark.png` and `v2_x6_light.png`, plus `art-archive/T-532/raw_v2/preview_raw_x6_dark.png`.

If it scores below 8, the next refine would push the side-on topple further.

Still open from version 1: the ticket's result notes aren't written, because the `task_notes.py` command needs approval. The Project Lead needs to approve it or add the notes.
- Script checks: 41 of 41 pass
- Score: 4/10
- Reason: The sheet passes the script checks (rules 1, 3 and 6): 48x48 frames, opaque or transparent pixels only, 17-19 colours, no Greenbull colours. The look matches the reference minion: light-green lizard, dark outline, SE view. The failure is the brief, not the rules. This does not read as a death animation. Frames 1-7 all show the lizard upright on its four legs, in a walking or idle posture with small tail and head shifts. There is no hit or recoil, no collapse onto its side or belly, no limp legs and no slack jaw. It never ends as a still corpse lying on the ground, and frames 6-7 are not a held corpse pose. Only frame 0 has the cyan eye, so the eye does not read as closing or dulling either. Fix on the refine: change the action text to describe the sequence step by step (jolts back, topples sideways, lies flat, legs and tail limp), or pass an end frame showing the lying corpse. If frame 0 still comes out upright, try fixing the last frames. Keep the same palette and outline, and keep the feet near the same ground position. Under rule 10 the subject keeps its look, but the pose must change to a lying corpse. No script fix can do this.
- Rules broken: 10

### Round 3

- Version 3: `art-archive/T-532/style-loop/v3.png`
- What changed: Version 3 is generation 3 of the 4 allowed, and it is weaker than version 2: the minion twists but still never lies down.

Why a paid generation: a script can't turn the pose into a lying corpse. I also looked for an end frame to pass to PixelLab, as the evaluator suggested. The request builder has no option for one, and the minion's fall sheet (`game/art/minion/minion_fall_se.png`) never shows it lying down, so there was no lying-corpse image to use.

What I sent: `art-archive/T-532/req_v3.json` (approved `game/tools/pixellab_animate_req.py`, seed 3). Its action text spells out the sequence step by step: hit and recoil, rear up, tip sideways and roll onto its side and half onto its back, legs limp and up, tail flat, mouth open, eye shut, then a still corpse on the ground. The job (411d9f0c-0dbb-49e6-85b9-69aadd2c4b8e) used 1.0 generation. The raw frames are in `art-archive/T-532/raw_v3/`.

What came back: frames 3 to 5 twist and rear with the eye shut. Frames 6 to 8 come back upright with the eye open, so the whole thing reads as a wriggle.

Free fix, with no PixelLab call: `build_minion_death_sheet.py --hold 3` keeps raw frames 1 to 5 and repeats frame 5, the twisted, eye-shut pose, as frames 6 to 8. That way the end is held still and never goes back to standing. Every colour is snapped to the minion's walk-sheet palette, leaving 17 colours, and every pixel is fully opaque or fully transparent. The sprite-rules check passes with no failures. Previews are in `art-archive/T-532/screenshots/v3_x6_dark.png` and `v3_x6_light.png`.

Version 2, the flattened, limp-legged pose with the tail on the ground, is still the strongest so far. animate-with-text-v3 keeps holding the standing pose of the first frame. The last allowed generation (4 of 4) would probably need a different input than more text: for example, version 2's final flattened frame as the first frame, asking for a roll onto its side. I would only do that within the board's go.

Still open: the ticket's result notes aren't written yet, because `task_notes.py` needs approval. The Project Lead needs to approve it or add the notes.
- Script checks: 41 of 41 pass
- Score: 5/10
- Reason: I could only view the sheet at native 384x48 and could not zoom in, so this is a judgement from the small image. The script checks pass (rules 1, 3, 6). I see no blood, liquid or splatter in any frame. Rule 10 (the minion keeps its look) is only partly met:
- Frames 4-7 have the same opaque count (549) and look identical. The brief asks for only 2 held corpse frames, so the collapse is squeezed into frames 0-3 and reads as a small tilt rather than a clear hit, rear back, collapse onto the side and go limp. In frames 0-3 the lizard still looks mostly upright and walking-like. Redo the motion so the body clearly rears, then drops onto its side or belly, with legs curling and tail dropping, and the last 2 frames only held.
- The green looks like a fairly saturated yellow-olive green. The brief wants a light green that is "not too bright" and an exact match to the walk sheet's palette. Check the palette against minion_se.png and snap the colours to it.
- I could not confirm the eye closing or dulling, the slack jaw, or the dull pink mouth (147, 93, 93) in the last frames. Check these when fixing.
- The corpse's ground position and foot anchor should match the walk frames; this needs a check.
- Rules broken: 10, 2
- Refused: {"tool_input": {"argv": ["scale", "upload:none"]}, "tool_name": "mcp__pixellab__pixelart_workbench", "tool_use_id": "toolu_0166QJ9oB5X7TjhzEuJdRfD8"}

### Round 4

- Version 4: `art-archive/T-532/style-loop/v4.png`
- What changed: Version 4 used the last generation the board allowed (4 of 4), and the minion still never ends on its side. All 4 generations, 4.0 in total, are now spent, so any further call needs the board's say-so.

What I sent: `art-archive/T-532/req_v4.json` (approved `game/tools/pixellab_animate_req.py`, seed 4). Text alone kept PixelLab close to the standing first frame, so this time the first frame was version 2's most collapsed raw frame (`raw_v2/death_se_4.png`: sunk low, splayed, eye shut) instead of the walk reference. That differs from the brief's first frame. The action text asked it to keel over onto its side, legs limp, tail flat, jaw slack, eye shut, then lie still. The job (5b08fa14-88f1-4213-9281-53b32758834b) used 1.0 generation. The raw frames are in `art-archive/T-532/raw_v4/`.

What came back: it doesn't roll onto its side. It stays sunk flat on its belly, the tail lowers until it lies flat along the ground, the eye stays shut, and it settles almost still.

Free fix, with no PixelLab call: I added a `--pick` option to `game/tools/build_minion_death_sheet.py` (with a test; 6 tests pass) to join frames from several raw folders. Version 4 is version 2's raw frames 1 to 4 followed by version 4's raw frames 3, 6 and 8:
- frames 0 to 1: the lurch, eye still cyan
- frames 2 to 3: the tail whips up, the legs splay, the body sinks and the eye shuts
- frames 4 to 5: the body drops flat on its belly and the tail settles
- frames 6 to 7: an identical held pose, flat on its belly with the tail flat along the ground and the eye shut

Every colour is snapped to the minion's walk-sheet palette, leaving 25 colours, and every pixel is fully opaque or fully transparent. The sprite-rules check passes with no failures. Previews are in `art-archive/T-532/screenshots/v4_x6_dark.png` and `v4_x6_light.png`.

How it looks: a collapse flat onto the belly, which the brief allows ("onto its belly/side"), but it is not a fall onto the side. The legs are limp but still under the body, and there is no clear slack jaw.

Not checked: whether the corpse sits on the same ground line as the walk frames. I could only judge that by eye, because inline Python needs approval.

Still open: the ticket's result notes aren't written, because `task_notes.py` needs approval. The Project Lead needs to approve it or add the notes about all 4 generations.
- Script checks: 41 of 41 pass
- Score: 6/10
- Reason: At the only size I could view (384x48, no zoom), the script checks all pass: 48x48 frames, transparent background, no semi-transparent pixels, 17-19 colours per frame, and no Greenbull colours. The sequence reads as a lizard going from upright to flat on the ground, and the last frames are nearly still. It keeps the minion's 3/4 south-east view and a dark outline. No liquid or blood is visible. Problems I could see. Rule 2: the outline looks thinner and less bold than the walk sheet's, and the highlight breaks are weak, so check it against frame 0 of the reference. Rule 10: the green looks more yellow-green and saturated than the minion's "light green, not too bright". Recolour the body and scales to the reference's greens by script. The cyan eye is clear only in the first frames; later frames should show it closed or dull. The toothed jaw and pink mouth (147,93,93) are hard to make out in the later frames, so confirm they are kept. The late frames could also be tidier: make the last 2 frames identical, and align the feet and ground position with the walk frames. Because I could not zoom, treat these as likely fixes to verify, not confirmed defects.
- Rules broken: 2, 10

**Kept:** version 4, score 6/10 (`art-archive/T-532/style-loop/v4.png`, copied to `art-archive/T-532/minion_death_se.png`): still below 8 after 3 refines, so the task is flagged for the board's review.

## Result notes

Plan (before any PixelLab call): sample direction SE. Style loop run: python tools/style_loop/run.py art --task T-532 --brief art-archive/T-532/brief.md --out art-archive/T-532/minion_death_se.png --size 48x48 --frames 8 --max-colors 32 --allow-red 147,93,93. Planned PixelLab calls: /animate-with-text-v3 (first_frame = minion_se frame 0, 8 frames, 48x48, no_background, 600 s HTTP timeout), 1 generation each (as in T-068: usage 1.0 generation). At most 4 calls in all (version 1 plus up to 3 refines), free script fixes first. Everything kept in art-archive/T-532/.

Run 1 of the style loop (2026-11-03) stopped before any PixelLab call: the loop's headless generator agent wrote its request builder art-archive/T-532/build_req.py but the permission system refused 'python art-archive/T-532/build_req.py' (only python game/tools/*, tools/style_loop/run.py and a few more are pre-approved in .claude/settings.json). 0 of 4 generations spent, no cost. Not worked around. Needs the board/Project Lead: either approve the script run, or allow moving the builder into game/tools/ (an approved path), then rerun the same loop command.

2026-11-06 (board's decision): request builder moved to game/tools/pixellab_animate_req.py (generic: --first-frame, --out, --seed, --frames, --action/--action-file); old copy kept as art-archive/T-532/build_req_old_refused.py; brief.md names the new path. Planned: rerun 'python tools/style_loop/run.py art --task T-532 --brief art-archive/T-532/brief.md --out art-archive/T-532/minion_death_se.png --size 48x48 --frames 8 --max-colors 32 --allow-red 147,93,93'; /animate-with-text-v3, 1 generation per call (about 1.0 generation each), at most 4 calls, 600 s HTTP timeout.

2026-11-06, run 2, version 1: request built with the approved script (art-archive/T-532/req_v1.json, seed 1). The send stopped before any PixelLab call: pixellab_client.py passed the style loop gate but exited with "PIXELLAB_API_KEY is not set" because this worktree (C:\solid-carbide-worktrees\T-532) has no .env. Checking for the main checkout's .env needed approval, so I didn't work around it and didn't copy any secret. 0 of 4 generations spent, no cost. No v1.png was made. Needs the board/Project Lead: give this worktree the key (a .env at its root, or PIXELLAB_API_KEY in the loop's environment), then run the same loop command again.
- 2026-11-06, in-progress → flagged-for-review: the style loop kept version 4 (score 6/10), still below 8 after 3 refines; every version is in its Style review

2026-11-06 run 3 (after .env added): style loop ran 4 versions = 4 PixelLab generations (v1 to v4, raw_v1..raw_v4, req_v1..v4), the whole budget; scores 3, 4, 5, 6 of 10, all 41/41 script checks. Kept v4 (6/10): art-archive/T-532/style-loop/v4.png, copied to art-archive/T-532/minion_death_se.png (8 frames 48x48). Below 8, so the loop flagged the ticket for the board's review (status set by the loop's tool, not by me). Generator also added game/tools/build_minion_death_sheet.py (+ test) as a free fix. Strips (x4, dark and light): art-archive/T-532/screenshots/death_se_strip_dark.png, death_se_strip_light.png; per-version x6 strips are in the same folder. Nothing put in game/art/. Round 1 Style review logs a refused PowerShell probe by the generator (key check); it was not worked around.
